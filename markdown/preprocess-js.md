JavaScript is not a great programming language.  Even with Webpack giving us the ability to write modular code, JavaScript is still a bit weak.

For example, we have to remember to use `===` everywhere or things get weird.  We also have to type the keyword `function` **a
lot**. Scoping is a mess, we can't make constants, and it would be nice to define a proper class that handles `this`.

[ECMAScript 2015](http://www.ecma-international.org/ecma-262/6.0/) addresses all of these failures in JavaScript, but we can't run
it in a browser.  What we *can* do is translate it *to* JavaScript, allowing us to write modern code that still runs in a
browser.

## Write Modern JavaScript, Ship Compatible JavaScript

To do this with Webpack, we'll need to set up [Babel](https://babeljs.io), which will do the work.  Babel advertises itself as “a
JavaScript compiler” which is also kindof what Webpack is.  The confusion lies around what is meant by the word “JavaScript”.  In
Babel's case, it means “a newer version of JavaScript than your browser can produce”, which is *sort of* what Webpack can do as
well.  Suffice it to say, Babel handles the newest version of JavaScript _most properly_, so we *do* need it to accomplish our
goal of writing entirely in ES2015, but being able to rely on our code working in lots of browsers that don't support it.

Let's write some! Replace `js/markdownPreviewer.js` with this:

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
won't work for all browsers, including ones we want to support.  Let's continue.

First, we'll install babel.  Which, sadly, cannot be accomplished via `yarn add babel`.  Instead we must:

!SH yarn add @babel/core -D

Yes, that is an `@` sign which is a [_scoped package_](https://docs.npmjs.com/misc/scope) and more and more big frameworks are
using it to group their submodules.

We'll also need the Babel loader for Webpack:

!SH yarn add babel-loader -D

Babel should process all JavaScript, so we'll configure the loader in `config/webpack.common.config.js` to handle all `.js` files, save for those in `node_modules`, which are already assumed to be ready for distribution to a browser:

!EDIT_FILE config/webpack.common.config.js /* */
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
presets, but of course, none of them are actually pre-set.  We'll use the recommend “env” preset, which means “generally do the
right thing without having to configure stuff”, which is a godsend, so we'll take it.

!SH yarn add @babel/preset-env -D

Now, create a config file for Babel in the root directory (yup) called `.babelrc` (note that this file is JSON and not JavaScript, so it's far easier to mess up, and you can be sure you won't get a good error message if you do):

!CREATE_FILE{language=json} .babelrc
{
  "presets": ["@babel/preset-env"]
}
!END CREATE_FILE

And now, re-run Webpack:

!SH yarn webpack

If you inspect `dev/bundle.js`, you can see that the fancy arrows and use of `const` is gone, replaced with old school JavaScript.

Now, we can write modern JavaScript and not worry about what browsers actually support it.  What about tests?

## Using Modern JavaScript to Write Tests

Our test files are pretty basic, so there's nothing exciting about using arrows as those will work with the version of Node we
are using.  Instead, let's use an experimental feature called [optional
chaining](https://babeljs.io/docs/en/babel-plugin-proposal-optional-chaining).  As of this writing, it's not supported by many
browser or by Node.  It will also require adding a plugin to Babel to support, so this should be a good learning.

The way optional chaining works is to allow you to safely dereference a deep object without worrying about undefined:

```javascript
const o = {
  foo: {
    bar: "blah"
   }
};

console.log(o?.foo?.bar); # => "blah"
```

We'll add this code as a test:

!CREATE_FILE test/markdownPreviewer.test.js
import markdownPreviewer from "../js/markdownPreviewer"

describe("markdownPreviewer", () => {
  it("should exist", () => {
    expect(markdownPreviewer).toBeDefined();
  });
  it("should allow deep references", () => {
    const o = {
      foo: {
        bar: "blah"
       }
    };

    expect((o?.foo?.bar)).toBe("blah");
  });
});
!END CREATE_FILE

This should fail with a huge stack about the syntax error we created:

!SH{nonzero} yarn test

To allow using this new feature, we'll add the babel plugin `@babel/plugin-proposal-optional-chaining` to our project:

!SH yarn add @babel/plugin-proposal-optional-chaining -D

To use this, we'll add the `plugins:` key in our `.babelrc` file:

!CREATE_FILE{language=json} .babelrc
{
  "presets": ["@babel/preset-env"],
  "plugins": ["@babel/plugin-proposal-optional-chaining"]
}
!END CREATE_FILE

Now, when we re-run our tests, they…still don't pass.

!SH{nonzero} yarn test

Babel 7.4 includes a breaking change, because of course it does.  To be honest, I don't know what the problem
actually is, because the way Babel functions is entirely opaque and unobservable.  There's somethig going on with
polyfills, but when we dig deeper we find that the way we are organizing tests is executing tests in other
packages in `node_modules`.  UGH.

Let's just get through this.  Our `.babelrc` actually requires a bunch of configuration to the preset, thus making
it not very pre-set.

!CREATE_FILE{language=json} .babelrc
{
  "presets": [
    [
      "@babel/preset-env",
      {
        "useBuiltIns": "usage",
        "corejs": { version: 3, proposals: true }
      }
    ]
  ],
  "plugins": ["@babel/plugin-proposal-optional-chaining"]
}
!END CREATE_FILE

We also need to now explicitly add `core-js` as well as a package called `rengerator-runtime`:

!SH yarn add -D core-js@3 regenerator-runtime

And *now* `yarn test` works, and inadvertently runs a bunch of other tests.  But it supports the chaining syntax
at least!

!SH yarn test

From here, you can configure Babel in a ton of ways.  Notably, you will need to use Babel if you want to use React and write JSX
files.

## Where We Are

We started with nothing, and we gradually changed our configuration to solve real problems.  In the end, what we have isn't bad!
We can write modular JavaScript, use third party libraries and CSS, get useful stack traces, run unit tests, and bundle for
production.  We can also use bleeding edge features of JavaScript while ensuring browser compatibility.  That's pretty good!

And, we didn't have to write a ton of configuration:

!SH wc -l webpack.config.js config/webpack.*

That's less than 100 lines total, and we have a completely workable development environment.

My hope is you have taken a few things away from this.  First, I hope you understand Webpack a bit better and can navigate it's
basic features and learn what works and why.  Second, and more important, I hope you feel confident working with tools that just
aren't very well designed for your needs.  I hope you feel validated when you feel frustrated by cryptic error messages that it's
not just you.  I hope you feel like running to Google or browsing GitHub issues to find out how to use your tools is perfectly
normal.

Webpack clearly values moving fast and delivering features over ergonomics and predictability.  There's nothing inherently wrong
with that tradeoff, but it means you have to shoulder the burden when things dont' work the first time, and they rarely do.
Hopefully, you've seen that by taking small steps each time and changing very little in each step will allow you to understand
what has broken this time and how you might fix it.

That said, I want to spend the last chapter discussing the design decisions that I believe make this entire thing so difficult to
deal with and what might make it all work better.  These are ways of thinking that help you build any application, even if it's
not a build tool.
