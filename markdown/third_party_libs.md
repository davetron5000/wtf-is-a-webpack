This should be easy!  We have JavaScript code that we're going to write, but we want to use some existing libraries to help us do that.

In the World Before WebPack™, you'd often add the library's CDN-hosted URL to a `<script>` tag and be on your way.

That would work because the library would dump itself into the global namespace.  That's not what we want to do for a few reasons.

First, this means that every library everywhere has to agree on a unique set of names so as to not squash each other.  That is difficult.

Secondly, it means that we have no control over when or how these libraries are loaded, which becomes important for writing tests.

Thirdly, this isn't how third-party JavaScript libraries are built - they kindof assume you are using a package manager like
Webpack.


Point is, dumping into global namespace bad.  I promise not to get on my soapbox about this again, so let's get to it.  Let's add a library to our project!

But wait, we don't really *have* a project, yet.  Let's make one real quick.

## Our Project Isn't Very Exciting

Despite how awesome our `console.log`'ing supersystem is, we should work on something more interesting.  The simplest thing I
could think of is a markdown previewer.  There's a [markdown] module we can use, so that will be our third-party library!

[markdown]: https://github.com/evilstreak/markdown-js

First, we'll add it to our `package.json` file using `yarn add`:

!SH yarn add markdown

This will also run `yarn install` which will download the markdown package to `node_modules`.

Let's create our HTML first by replacing `dist/index.html` with the following:

!CREATE_FILE dist/index.html
<!DOCTYPE html>
<html>
  <head>
    <script src="bundle.js"></script>
  </head>
  <body>
    <h1>Markdown Preview-o-tron 7000!</h1>
    <form id="editor">
      <textarea id="source" rows="10" cols="80"></textarea>
      <br>
      <input type="submit" value="Preview!">
    </form>
    <hr>
    <section id="preview">
    </section>
  </body>
</html>
!END CREATE_FILE

Here's how our amazing app will work:

* We'll create a function that listens for submit events on forms and renders markdown
* That function is created by *another* function that will accept as input: the document, the id of the source text area and the
ed of the preview area.
* When the form is submitted, we use the `markdown` library to render markdown from the source text area into the preview area.

Our entry point is `js/index.js`, so let's create that like so:

!CREATE_FILE js/index.js
import markdownPreviewer from "./markdownPreviewer";

window.onload = function() {
  document.getElementById("editor").addEventListener(
      "submit",
      markdownPreviewer.attachPreviewer(
        document,    // pass in document
        "source",    // id of source textarea
        "preview")); // id of preview DOM element
};
!END CREATE_FILE

`markdownPreviewer` is a file we'll create in a moment.  Hopefully you know enough JavaScript to see what's going on.  We're
passing in `document` so that our code doesn't have to depend on global state.  That'll come in handy when writing tests.

Now, let's create `js/markdownPreviewer.js`, which does all the work.

We need to import our markdown library, however it's in `node_modules`, so how does that work?

The answer is: it just does.  One of the scant defaults Webpack provides is to look in `node_modules` for files you import.

Now, before we write `import markdown from "markdown";` we need to learn a bit more about how `import` works.

The markdown package exports a structure like so;

```json
{
  "markdown": {
    "toHTML": function() { ... }
  }
}
```

Meaning, we'd need to write `markdown.markdown.toHTML`.  Yuck.  `import` allows you to pluck symbols out of the exported object
by using curly braces:

```javascript
import { markdown } from "markdown"; // yo dawg
```

This allows us to write `markdown.toHTML`, which is better.

With that said, here's how `js/markdownPreviewer.js` should look:

!CREATE_FILE js/markdownPreviewer.js
import { markdown } from "markdown";

var attachPreviewer = function($document,sourceId,previewId) {
  return function(event) {
    var text    = $document.getElementById(sourceId).value,
        preview = $document.getElementById(previewId);

    preview.innerHTML = markdown.toHTML(text);
    event.preventDefault();
  };
}

export default {
  attachPreviewer: attachPreviewer
}
!END CREATE_FILE

Now, what's up with `export default`? Writing `import attachPreviewer from "./markdownPreviewer";` is asking Webpack (or whoever)
to import the default exported thing.  Handy when you are just exporting one function.  Actualy, it's not handy, it's a confusing
pain in the ass, but this is what you must do.

<aside class="sidebar">
<h1>Why do some imports have <code>./</code> and some don't?</h1>
<p>
Remove the leading <code>./</code> from your import in <code>js/index.js</code>, then run <code>yarn webpack</code>.  I'll wait.
</p>
<p>
Isn't that an <strong>amazing</strong> amount of useless output?  What is even going on?
</p>
<p>
First, you should be thanking me for telling you to use <code>--display-error-details</code>, because without that, you would not
be given any real error and would have no idea why things aren't working.  I can't explain to you why installing a package vomits
an endless stream of output by default, but making an error doesn't, but I <strong>can</strong> tell you what's going on here.
</p>
<p>
When you ask to import a string that doesn't have a leading <code>./</code>, it tells Webpack: “Look for the file everywhere on
my hard drive <strong>except</strong> the current directory”.  I'm not kidding.  You can see the output desperately climbing up
your directory hierarchy looking for a directory called <code>node_modules</code> in which it hopes to find
<code>index.js</code>.
</p>
<p>
When you precede the module name with a <code>./</code>, it tells Webpack to look in the current directory for the file.
</p>
<p>
So, the rule of thumb is: your code usually has a <code>./<code> and third-party libraries don't.
</aside>

Let's package everything up and see if it works.

!SH yarn webpack

If we open up `dist/index.html`, we should see our UI:

!SCREENSHOT dist/index.html markdown_screen.png

And, if you type in some markdown and hit the submit button, voila it's rendered inline by our markdown library:

!SCREENSHOT dist/index.html markdown_screen2.png

Who would've thought it takes 1,000 words to talk about using third party libraries, but this is JavaScript and we
should be thankful Webpack exists to make up for the language's deficiencies.

We mentioned earlier that we passed `document` into our `attachPreviewer` function to facilitate testing.  We
should probably look into testing at this point because a) I get nervous writing untested code and b) things we'll
learn later, like CSS and ES6, will definitely break things and we want to make sure we can continue to run tests
as we use more sophisticated features of Webpack.
