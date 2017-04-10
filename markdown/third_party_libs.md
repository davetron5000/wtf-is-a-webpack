This should be easy!  We have JavaScript code that we're going to write, but we want to use some existing libraries to help us do that.

In the World Before WebPack™, you'd often add the library's CDN-hosted URL to a `<script>` tag and be on your way.

That would work because the library would dump itself into the global namespace.  That's not what we want to do for a few reasons.

First, this means that every library everywhere has to agree on a unique set of names so as to not squash each other.  That is difficult.

Secondly, it means that we have no control over when or how these libraries are loaded, which becomes important for writing tests.

There is a third benefit, for super advanced hackers obsessed on performance, which is that by using module imports instead of dump-it-all-into-global-namespace, you can
take the JavaScript of your application and create several differnet bundles, optimized for different use-cases, so your users only download what they need.

For example, suppose you are using all of Angular for a particular page in your site, but your  main landing page doesn't need Angular.  You could create two bundles - one
for your landing page and one for the other page, and users who never navigated to the Angular-powered don't have to download it.  We'll get there (in a while :).

Point is, dumping into global namespace bad.  I promise not to get on my soapbox about this again, so let's get to it.  Let's add a library to our project!

## Our Project Isn't Very Exciting

First, we should have a project that doesn't something remotely interesting.  So, let's change it from a `console.log`ing masterpiece into something more useful.

We'll create a simple markdown previewer using [markdown][npm-markdown] from NPM.

First, we'll add it to our `package.json` file using `yarn add`:

!SH yarn add markdown

This will also download the markdown package.

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

The way our amazing markdown app will work is that we'll create a function that, given some ids, can attach itself to a form to render a preview.  We'll assume that function
creates an event listener we can give to our form.  So, in `index.js`, let's write:

!CREATE_FILE js/index.js
import markdownPreviewer from "./markdownPreviewer";

window.onload = function() {
  document.getElementById("editor").addEventListener(
      "submit",
      markdownPreviewer.attachPreviewer(document,    // pass in document
                                        "source",    // id of source textarea
                                        "preview")); // id of preview DOM element
};
!END CREATE_FILE

The function `attachPreviewer` accepts three arguments: the document (so as not to depend on global state), the ID of a textarea that has our Markdown source, and the id of
another area of the page where we can render the preview.

Now, let's create `js/markdownPreviewer.js`, which does all the work.

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

First, let's call attention to that first `import` call.  It doesn't look like the others, because of those braces.  What is exported from the markdown library has this
structure:

```javascript
{
  markdown: {
    toHTML: function(...) { }
  }
}
```

If we had used our previous `import` syntax:

```javascript
import md from "markdown";
```

We would've had to do `md.markdown.toHTML`.  Yuck.  The braces syntax allows us to import a specifc symbol from the exported object.  If there were multiple keys exported,
we could import them like so:

```javascript
import { markdown, foobar } from "markdown";
```

I mention this because if you get the syntax wrong, you will not get a useful error message.  You will be confused.

Another confusing thing, which produces no useful error message, has to do with the string after `from`.  If you have a careful eye, you'll see that when we import our code,
we precede the string with a `./`, but when we imported this fresh third-party library, we didn't do that.

Try removing the `./` from your `index.js` and running `yarn run webpack`.  I'll wait.

Luckily for you, I told you to use the command-line switch `--display-error-details`.  By default, Webpack swallows errors and leaves you scratching your head as to what
went wrong.  The error details don't exactly paint a clear picture, but if you read them closely, you can see what the deal is.

What you are seeing in that massive amount of output is that Webpack is tryingn to find `markdownPreviewer.js` amidst literally every directory it can finde **except** the
one where `index.js` lives.

And thus, the `./` is special.  It means "don't try to find this in any `node_modules` directory anywhere on my machine, but instead treat this as a relative path from the
file being processed".  That's not the design choice _I_ would've made, but that's how it works.

Meaning: third-party libraries don't get a dot or slash in front, while your code gets both.

Restore your `import` statement and look at the rest of the code.  It's not super interesting as we're just finding some elements based on the IDs given, and calling the `toHTML()` function provided by the markdown library.

Let's package everything up and see if it works.

!SH yarn run webpack

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
