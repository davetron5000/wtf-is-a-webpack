We're getting a better and better setup for developing and deploying our applications.  We can organize our JavaScript and CSS, we can use third party libraries for both, can deploy to production in a proper way, and run tests.  But we're still missing something every other programming language has: stack traces.

Stack traces tell us where in our code errors are happening.  In most programming languages, when an uncaught error happens, we see some information about what line of code raised the error, as well as the path through the code that led to that error.  Even in a language like C, we can do this.  Not so in JavaScript.

The reason is that the file we're editing is not the file that's being served.  Webpack is compiling all of our files together, as well as minifying them and including our third party libraries.

Let's see the problem in action.

Add a `throw` to the function in `markdownPreviewer.js`, after `event.preventDefault()`.

Re-run Webpack and open up `dev/index.html`, then open the JavaScript console, and then click the “Preview” button:

![Image of a useless stack trace](images/nosourcemaps.png)

The error came from line 1 of our bundle.  This is technically true, since our bundle is minified and all the code is on one line.  Since we aren't editing this file directly, we have no idea where this error came from.

The solution to this is a feature that most browsers support called _sourcemaps_.

## Sourcemaps

If a sourcemap file exists, browsers know to look at it when giving you a stack trace (though you may need to [enable this feature](https://gist.github.com/jakebellacera/336c4982194bcb02ef8a) in your browser).  The sourcemap lets the browser tell us
that the problem wasn't in line 1 of our bundle, but on line 10 of `markdownPreviewer.js`.

Webpack can produce sourcemaps.  The configuration option is, of course, not called something intuitive like `sourceMap`, but instead is called [`devtool`](https://webpack.js.org/configuration/devtool/).

The possible values for `devtool:` are many, and poorly documented.  Since we have different configurations
for production and developoment, we can use different source map strategies.  For production, we'll use
`source-map` as that contains the most information and is designed for production.

In `webpack/production.js`:

!EDIT_FILE webpack/production.js /* */
{
  "match": "  },",
  "insert_after": [
    "  devtool: \"source-map\","
  ]
}
!END EDIT_FILE

For deveopment, we want the fastest thing possible that shows the most information.  I *think* that's
`inline-source-map`, but the docs are unclear.  It works, so we'll use it:

!EDIT_FILE webpack/dev.js /* */
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

Let's check our production configuration to make sure there's no issue:

!SH yarn prod


What about our CSS?  Sometimes it's nice to know where certain styles are defined or where they came from.

## Sourcemaps for CSS

To see what I mean, open up your app, and inspect an element.  Your browser should show you the CSS of the element in question and should show you where those classes are defined.  They will all be line 1 of your `.css` bundle.

Making this work is slightly tricky, because we have to expand the configuration given to `ExtractTextPlugin`.  The way it's design is that it takes the exact same options as `use:`, which are currently:

```javascript
{
  use: "css-loader"
}
```

We need to pass `sourceMap: true` (**not** `devtool`—go figure) as an option, but there is no place to add options.  The syntax we are using is a short-form of this syntax:

```javascript
{
  use: {
    loader: "css-loader",
    options: {}
  }
}
```

And *there* is a place to add options.  We want to pass a structure like that to `ExtractTextPlugin`, so the full change in `webpack/common.js` is:


!EDIT_FILE webpack/common.js /* */
{
  "match": "          use: 'css-loader'",
  "replace_with": [
		"          use: {",
		"            loader: \"css-loader\",",
		"            options: {",
		"              sourceMap: true",
		"            }",
		"          }"
  ]
}
!END EDIT_FILE

If you run Webpack:

!SH yarn webpack

And repeat the steps to inspect an element, you'll now see the correct line numbers in the files where the classes are defined.

Don't forget to try with production:

!SH yarn prod

Nice!

What about tests?

## Stack Traces in Tests

If we introduce a failure into our tests, we'll see a stack trace, but the line number is useless, as before.

First, remove the `throw` you added before from `js/markdownPreviewer.js`.  Next, let's introduce a test failure in our test.

Here's our entire test file with a failure introduced:

!EDIT_FILE spec/markdownPreview.spec.js /* */
{
  "match": "      expect(preview.innerHTML).toBe",
  "replace_with": [
    "        expect(preview.innerHTML).toBe(\"<p>This is <i>some markdown</em></p>\");",
    "        // --FAILURE--------------------------------^^^",
    "        //"
  ]
},
{
  "match": "        \"<p>This is <em>some markdown</em></p>\");",
  "replace_with": [ "" ]
}
!END EDIT_FILE

!SH{nonzero} yarn karma

Although it seems like our Webpack configuration should include the sourcemaps, even for the test code, for whatever reason it doesn't, and we have to set up an additional preprocessor for Karma to include them.

That preprocessor is `karma-sourcemap-loader`, which we can install thusly:

!SH yarn add karma-sourcemap-loader -D

We configure it *after* the Webpack preprocessor, like so:

!EDIT_FILE spec/karma.conf.js /* */
{
  "match": "      '**/*.spec.js': [ 'webpack'",
  "replace_with": [
    "      '**/*.spec.js': [ 'webpack', 'sourcemap' ]"
  ]
}
!END EDIT_FILE

Now, when we run karma, we should see the stack trace reference a line in our test file:

!SH{nonzero} yarn karma

It does reference a line, which is great, but it's not the correct one, which is not great.

As of this writing, PhantomJS does not properly read the sourcemap and reports the wrong line number.  This sucks, but all is not lost!

If you recall, we've been using the command line switch `--single-run` to run our tests.  If we omit that, Karma will run our tests and then sit there, waiting.

```
> $(yarn bin)/karma start spec/karma.conf.js
```

If you look at the output, it will show something like this:

```
22 04 2017 14:36:17.997:INFO [karma]: Karma v1.6.0 server started at http://0.0.0.0:9876/
```

If you navigate to that url and port in your web browser, Karma will run your tests in that browser!  If we do this in Chrome, the stack trace is correct:

```
22 04 2017 14:37:02.819:INFO [Chrome 57.0.2987 (Mac OS X 10.12.4)]: Connected on socket 7nP6V7W0YsH5C0f4AAAB with id manual-9961
PhantomJS 2.1.1 (Mac OS X 0.0.0) markdownPreviewer attachPreviewer renders markdown to the preview element FAILED
	Expected '<p>This is <em>some markdown</em></p>' to be '<p>This is <i>some markdown</em></p>'.
	webpack:///spec/markdownPreview.spec.js:44:0 <- markdownPreview.spec.js:1:77552
	loaded@http://localhost:9876/context.js:162:17
Chrome 57.0.2987 (Mac OS X 10.12.4) markdownPreviewer attachPreviewer renders markdown to the preview element FAILED
	Expected '<p>This is <em>some markdown</em></p>' to be '<p>This is <i>some markdown</em></p>'.
	    at Object.<anonymous> (http://0.0.0.0:9876webpack:///spec/markdownPreview.spec.js:40:0 <- markdownPreview.spec.js:1:26111)
PhantomJS 2.1.1 (Mac OS X 0.0.0): Executed 3 of 3 (1 FAILED) (0.005 secs / 0.006 secs)
Chrome 57.0.2987 (Mac OS X 10.12.4): Executed 3 of 3 (1 FAILED) (0.045 secs / 0.008 secs)
TOTAL: 2 FAILED, 4 SUCCESS
```

It's hard to make out, but you can see that the Chrome run of the test is pointing to line 40, which is where the failing expectation is.

It's not ideal, but it *is* a way to get stack traces for your tests.

You can hit Ctrl-C to exit Karma.

This isn't the greatest ending to our desire to have stack traces, but at least it's something, and at least it's possible.

We can also start to see the tension between monolithic everything-is-included systems like Webpack, and its attempts at modularity and flexibility.  Because neither Webpack nor Karma were designed to work together, and because each tool has a completely proprietary plugin/extension mechanism, we have to jump through a lot of hoops to get them to cooperate.  I'll touch on this later toward the end of our journey, but suffice it to say, the design of these tools seems to have the worst of being monolithic and being modular.

So, what's next?

Our setup is pretty good so far, and we haven't written that much configuration—less than 100 lines!

With what we have now, we can get really far, and there are many places we could go from here:

* Speeding up our design-in-the-browser cycle with some automatic reloading (_Hot module reloading_).
* Improving our production deploy by splitting code (_Code splitting_).
* Reducing the size of our production deploy by removing un-used code (_Tree-shaking_).
* Using pre-processesors like SAAS, ES2015, or TypeScript.

For me, the developer experience is paramount.  When we, as developers, feel productive and efficient, it opens up many more possibilities than if we are constantly fighting our tools.  And, the number one issue right now is that we have to run Webpack manually…_a lot_.  Let's fix that.
