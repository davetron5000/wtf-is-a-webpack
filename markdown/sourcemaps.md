We're getting a better and better setup for developing and deploying our applications.  We can organize our JavaScript and CSS, we can use third party libraries for both, can deploy to production in a proper way, and run tests.  But we're still missing something every other programming language has: stack traces.

Stack traces tell us where in our code errors are happening.  In most programming languages, when an uncaught error happens, we see some information about what line of code raised the error, as well as the path through the code that led to that error.  Even in a language like C, we can do this.  Not so in JavaScript.

The reason is that the file we're editing is not the file that's being executed.  Webpack is compiling all of our files together, as well as minifying them and including our third party libraries.

Let's see the problem in action.

Add a `throw` to the function in `markdownPreviewer.js`, after `event.preventDefault()`.

Re-run Webpack and open up `dev/index.html`, then open the JavaScript console, and then click the “Preview” button:

![Image of a useless stack trace](images/nosourcemaps.png)

The error came from line 1 of our bundle.  This is technically true, since our bundle is minified and all the code is on one line.  Since we aren't editing this file directly, we have no idea where this error came from in our original source code.

The solution to this is a feature that most browsers support called _sourcemaps_.

## Sourcemaps

If a sourcemap file exists, browsers know to look at it when giving you a stack trace (though you may need to [enable this feature](https://gist.github.com/jakebellacera/336c4982194bcb02ef8a) in your browser).  The sourcemap lets the browser tell us
that the problem wasn't in line 1 of our bundle, but on line 10 of `markdownPreviewer.js`.

Webpack can produce sourcemaps.  The configuration option is, of course, not called something intuitive like `sourceMap`, but instead is called [`devtool`](https://webpack.js.org/configuration/devtool/).

<aside class="pullquote">The configuration option is, of course, not called something intuitive like <code>sourceMap</code></aside>

The possible values for `devtool` are many, and poorly documented.  Since we have different configurations
for production and development, we can use different source map strategies.  Let's try dev first as that's where we need the most
help.

The docs' first recommandation is `eval` which, and I'm not making this up, is documented to not work at all:

> This [`eval`] is pretty fast. The main disadvantage is that it doesn't display line numbers correctly

Like…why am I using source maps if I am also OK with the line numbers being wrong?  That's the entire point of source
maps.  Ugh.  Unfortunately, the second choice, `eval-source-map` works for JS and not for CSS. So, we'll go with `inline-source-map` which, so far, works for both.  Add it to `config/webpack.dev.config.js` like so:

!EDIT_FILE config/webpack.dev.config.js /* */
{
  "match": "  },",
  "insert_after": [
    "  devtool: \"inline-source-map\","
  ]
}
!END EDIT_FILE

Run Webpack:

!SH yarn webpack

And, if we follow the same steps in the browser, we'll see that we can now see the line number where our error is coming from!

![Image of a useful stack trace](images/sourcemaps_stack.png)

If you are in Chrome and click the stack, it even shows you the code where the error came from!

![Image of code where the error originated](images/sourcemaps_code.png)

Nice!

Unfortunately, we cannot enable source maps in production.  While it *is* documented to work, it actually doesn't.  The
documentation provides for several different production-quality source map configurations and none of them produce usable source
maps at this time.

The reason this is so bad is that in a real production application, we will have some level of error monitoring.  We need to know
if there are real errors in the front-end and where they are happening.  Without source maps we cannot know that (especially when minifying).

This means that for production we either use a development-style source map (which increases our bundle size), or we don't get
source maps at all.  Welp.

What about our CSS?  Sometimes it's nice to know where certain styles are defined or where they came from.

## Sourcemaps for CSS

If you remove the configuration we just made, reload your app, inspect and element and examine the styles, you'll see they are
all defined somewhere in `styles.css`.  That is obviously not true.  If you restore the use of `inline-source-map` in dev, you
should see that the definition of styles is correctly mapped to where those styles were defined.

As with JS, it's not possible to get this to work in production mode while style hashing and minifying our CSS.  This is less of
an issue because CSS doesn't generate stack traces, but it still sucks that the tool documents a thing that doesn't actually
work.

What about tests?

## Stack Traces in Tests

If we introduce a failure into our tests, we'll see a stack trace, but the line number is useless, as before.

First, remove the `throw` you added before from `js/markdownPreviewer.js`.  Next, let's introduce a test failure in our test.

Since our test isn't a real test, we'll replace the expectation that we've loaded our code with a nonsense test that `undefined` is defined:

!EDIT_FILE test/markdownPreviewer.test.js /* */
{
	"match": "    expect(markdownPreviewer).toBeDefined();",
  "replace_with": [
	  "    expect(undefined).toBeDefined();"
  ]
}
!END EDIT_FILE

!SH{nonzero} yarn test

As you can see, the stack trace Jest generates references a line of code in our bundle and not the test.  Fortunately, we can get this by setting up `devtool` in our test webpack config, which you'll recall is still totally separate.  Let's keep it that way for now and use the `inline-source-map` devtool we use in our dev configuration:

!EDIT_FILE test/webpack.test.config.js /* */
{
	"match": "  entry: testFiles,",
  "insert_after": [
    "  devtool: \"inline-source-map\","
  ]
}
!END EDIT_FILE

Now, when we run our test again, we should see correct line numbers!

!SH rm test/bundle.test.js

!SH{nonzero} yarn test

Amazing, yeah?  Let's now take some time to consolidate our Webpack configurations.

## Consolidate Test Webpack Config

The more we start configuring Webpack, we run a risk of diverging critical things if our test configuration isn't kept up to
date.  Even though it's currently fairly different, let's consolidate it now so when we add more configuration we are forced to
decide if that should apply to testing or not.

Create `config/webpack.test.config.js` like so:

!CREATE_FILE config/webpack.test.config.js
const path         = require('path');
const glob         = require('glob');
const Merge        = require('webpack-merge');
const CommonConfig = require('./webpack.common.config.js');

const testFiles = glob.sync("**/*.test.js").
                       filter(function(element) {
  return element != "test/bundle.test.js";
}).map(function(element) {
  return "./" + element;
});

module.exports = Merge(CommonConfig, {
  entry: testFiles,
  output: {
    path: path.join(__dirname, '../test'),
    filename: 'bundle.test.js'
  },
  devtool: "inline-source-map",
  mode: "none"
});
!END CREATE_FILE

Let's delete the old file to avoid confusion:

!SH rm test/webpack.test.config.js

Now, we'll change our npm script in `package.json`, so the `scripts` section looks like so:

!PACKAGE_JSON
{
  "scripts": {
    "webpack": "webpack $npm_package_config_webpack_args",
    "webpack:production": "webpack $npm_package_config_webpack_args --env=production",
    "webpack:test": "webpack $npm_package_config_webpack_args --env=test",
    "jest": "jest test/bundle.test.js",
    "test": "yarn webpack:test && yarn jest"
  }
}
!END PACKAGE_JSON

And with that, `yarn test` should still run (and fail showing us a good stack trace):

!SH{nonzero} yarn test

Let's go ahead and undo our change to the test before we move on:

!EDIT_FILE test/markdownPreviewer.test.js /* */
{
  "match": "    expect(undefined).toBeDefined();",
  "replace_with": [
		"    expect(markdownPreviewer).toBeDefined();"
	]
}
!END EDIT_FILE

And now our tests are passing again:

!SH yarn test

With what we have now, we can get really far, but let's add one more tweak to our dev environment, and configure auto-reloading
of code as we make changes.

