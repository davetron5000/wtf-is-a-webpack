JavaScript is not a great programming language.  Even with Webpack giving us the ability to write modular code, JavaScript is still a bit weak.

For example, we have to remember to use `===` everywhere or things get weird.  We also have to type the keyword `function` **a
lot**. Scoping is a mess, we can't make constants, and it would be nice to define a proper class that handles `this`.

[ECMAScript 2015](http://www.ecma-international.org/ecma-262/6.0/) addresses all of this failures in JavaScript, but we can't run
it in a browser.  What we *can* do is translate it *to* JavaScript, allowing us to write modern code that still runs in a
browser.

## Write Modern JavaScript, Ship Compatible JavaScript

To do this with Webpack, we'll need to set up [Babel](https://babeljs.io), which will do the work.

First, though, let's write some ES2015.  Replace `js/markdownPreviewer.js` with this:

!CREATE_FILE js/markdownPreviewer.js
import { markdown } from "markdown";

const attachPreviewer = ($document,sourceId,previewId) => {
  return (event) => {
    const text    = $document.getElementById(sourceId).value,
          preview = $document.getElementById(previewId);

    preview.innerHTML = markdown.toHTML(text);
    event.preventDefault();
  };
}

export default {
  attachPreviewer: attachPreviewer
}
!END CREATE_FILE

It's fairly similar, because we don't have that much, but note that we've changed from `function` to using [arrows](https://github.com/lukehoban/es6features#arrows) and we've changed our use of `var` to [`const`](https://github.com/lukehoban/es6features#let--const), since the variables never get assigned more than once.

Also note that if you run Webpack now, and you are using a modern browser, this code has a good chance of working.  But, it
won't work for all browser, including ones we want to support.  Let's continue.

First, we'll install babel.  Which, sadly, cannot be accomplished via `yarn add babel`.  Instead we must:

!SH yarn add babel-core

We'll also need the Babel loader for Webpack:

!SH yarn add babel-loader

Configure the loader in `webpack/common.js`:

!EDIT_FILE webpack/common.js /* */
{
  "match": "    rules: [",
  "insert_after": [
    "      {",
    "        test: /\.js$/,",
    "        exclude: /node_modules/,",
    "        loader: \"babel-loader\"",
    "      },"
  ]
}
!END EDIT_FILE

Of course, Babel doesn't automatically do anything, so we need more configuration and more modules.  Babel has the concept of
presets, but of course, none of them are actually preset.  We'll use the recommend “env” preset, which means “generally do the
right thing without having to configure stuff”, which is a godsend, so we'll take it.

!SH yarn add babel-preset-env

Now, create a config file for Babel in the root directory (yup) called `.babelrc`:

!CREATE_FILE{language=json} .babelrc
{
  "presets": ["env"]
}
!END CREATE_FILE

And now, re-run Webpack:

!SH yarn webpack

If you inspect `dev/bundle.js`, you can see that the fancy arrows and use of `const` is gone, replaced with old school JavaScript.

Now, we can write modern JavaScript and not worry about what browsers actually support it.  What about tests?

## Using Modern JavaScript to Write Tests

First, let's rewrite our test using ES2015:

!CREATE_FILE spec/markdownPreviewer.spec.js
import markdownPreviewer from "../js/markdownPreviewer"

const event = {
  preventDefaultCalled: false,
  preventDefault: function() { this.preventDefaultCalled = true; }
};
const source = {
  value: "This is _some markdown_"
};
const preview = {
  innerHTML: ""
};

const document = {
  getElementById: (id) => {
    if (id === "source") {
      return source;
    }
    else if (id === "preview") {
      return preview;
    }
    else {
      throw "Don't know how to get " + id;
    }
  }
}

describe("markdownPreviewer", => {
  describe("attachPreviewer", => {
    it("renders markdown to the preview element", => {
      const submitHandler = markdownPreviewer.attachPreviewer(document,
                                                            "source",
                                                            "preview");
      source.value = "This is _some markdown_";

      submitHandler(event);

      expect(preview.innerHTML).toBe("<p>This is <em>some markdown</em></p>");
      expect(event.preventDefaultCalled).toBe(true);
    });
  });
});
!END CREATE_FILE

If you run Karma now, you'll get an error on the new syntax.  Although Karma is using Babel to transpile our production code,
   it's not doing that for the test code.  We'll need another preprocessor, `karma-babel-preprocessor`.

!SH yarn add karma-babel-preprocessor

Now, configure it in `spec/karma.conf.js`:

!EDIT_FILE spec/karma.conf.js /* */
{
  "match": "      '**/*.spec.js': [ 'webpack', 'sourcemap' ]",
  "replace_with": [
    "          '**/*.spec.js': [ 'webpack', 'sourcemap', 'babel' ]"
  ]
}
!END EDIT_FILE

Note that the addition of `'babel'` to the preprocessors must come *at the end* or it doesn't work.  Why?  Who knows?

If your test file still has the error form before, or if you introduce one, you'll get a lovely new surprise - source maps no
longer work.

While they do work in our production code, we no longer get the ability to see where in our test something failed.  Them's the
breaks and it's currently not fixable in this setup.  Changing the order of the preprocessors doesn't work, nor does explicitly
setting options for babel.  Even debugging this is difficult, because of how poorly all these tools are designed and how opaque
their interoperability is.

Such a letdown.  And it seems like a pretty fitting end to our journey.

## Where We Are

It's not all bleak.  We started with some basic needs to manage JavaScript and Webpack has met them, and more.  We can write
modular JavaScript, handle both development and production, run tests, and even use a new language.  What's better, the amount of
configuration we had to add wasn't that great.

! SH wc -l webpack.config.js webpack/*.js spec/karma.conf.js

That's less than 100 lines total, and we have a completely workable development environment.

Hopefully, you've learned a bit about why Webpack exists, and what it can (and can't) do.  I also hope you've learned to feel
confident in your needs as a developer and comfortable pointing out when available tools aren't meeting those needs.  It doesn't
mean the people that put their blood, sweat, and tears into them are bad people, but designing build tools is hard, and the
JavaScript ecosystem has the widest variety of developers ever, so it's hard to please everyone.

That said, I want to spend the last chapter discussing the design decisions that I believe make this entire thing do difficult to
deal with and what might make it all work better.  These are ways of thinking that help you build any application, even if it's
not as build tool.
