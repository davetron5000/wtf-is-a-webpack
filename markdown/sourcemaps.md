We're getting a better and better setup for developing and deploying our applications.  We can organize our JavaScript and CSS,
we can use third party libraries for both, can deploy to production in a proper way, and run tests.  But we're still missing
something every other programming language has: stack traces.

Stack traces tell us where in our code errors are happening.  In most programming languages, when an uncaught error happens, we
see some information about what line of code raised the error, as well as the path through the code that led to that error.  Even
in a language like C, we can do this.  Not so in JavaScript.

The reason is that the file we're editing is not the file that's being served.  Webpack is compiling all of our files together,
as well as minifying them and including our third party libraries.

Let's see the problem in action.

Add a `throw` to the function in `markdownPreviewer.js`, after `event.preventDefault()`.

Re-run Webpack and open up `dist/index.html`, then open the JavaScript console, and then click the “Preview” button:

![Image of a useless stack trace](images/nosourcemaps.png)

The error came from line 1 of our bundle.  This is technically true, since our bundle is minified and all the code is on one
line.  Since we aren't editing this file directly, we have no idea where this error came from.

The solution to this is a feature that most browsers support called _sourcemaps_.

## Sourcemaps

If a sourcemap file exists, browsers know to look at it when giving you a stack trace (though you may need to [enable this feature](https://gist.github.com/jakebellacera/336c4982194bcb02ef8a) in your browser).  The sourcemap lets the browser tell us
that the problem wasn't in line 1 of our bundle, but on line 10 of `markdownPreviewer.js`.

Webpack can produce sourcemaps.  The configuration option is, of course, not called something intuitive like `sourceMap`, but
instead is called [`devtool`](https://webpack.js.org/configuration/devtool/).

The possible values for `devtool:` are many, and poorly documented.  We'll use the one called `inline-source-map` as this is the
simplest one that works for most situations (it also works with CSS, which we'll deal with later).

We also need to tell `UglifyJSPlugin` that we are using sourcemaps.  I won't bore you with going through this exercise and
watching it fail and then having to Google around for the problem.  If you look at the docs for `UglifyJSPlugin`, you'll see that
there's an option called `sourceMap` (*those* developers know how to name a configuration option :). There's also a 
lovely warning that gives you a clue as to just how much of a house of cards this stuff is:

>  **Important!** `cheap` sourcemap options don't work with the plugin!

Another reason to stick with the standard, production-ready `inline-source-map` configuration option for Webpack.

OK, so we'll add `devtool:` to the top level of our Webpack config, and we'll also add `sourceMap: true` to our `UglifyJSPlugin`
configuration, which is given to its constructor.

Here's the entire file:

!CREATE_FILE webpack.config.js
const path           = require('path');
const UglifyJSPlugin = require('uglifyjs-webpack-plugin');
const HtmlPlugin     = require('html-webpack-plugin');
const ExtractTextPlugin = require('extract-text-webpack-plugin');


module.exports = {
  entry: './js/index.js',
  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: '[chunkhash]-bundle.js'
  },
  module: {
    rules: [
      {
        test: /\.css$/,
        use: ExtractTextPlugin.extract({
          use: {
            loader: "css-loader",
            options: {
              minimize: true
            }
          }
        })
      }
    ]
  },
  plugins: [
    new UglifyJSPlugin({
      sourceMap: true // <-------
    }),
    new ExtractTextPlugin('[chunkhash]-styles.css'),
    new HtmlPlugin({
      inject: false,
      template: "html/index.html"
    })
  ],
  devtool: "inline-source-map" // <------
};
!END CREATE_FILE

Run Webpack:

!SH yarn webpack

And, if we follow the same steps in the browser, we'll see that we can now see the line number where our error is coming from!

![Image of a useful stack trace](images/sourcemaps_stack.png)

If you are in Chrome and click the stack, it even shows you the code where the error came from!

![Image of code where the error originated](images/sourcemaps_code.png)

Nice!  We can even include these files when going to production so if there are errors there, we can get a real stack trace.

What about our CSS?  Sometimes it's nice to know where certain styles are defined or where they came from.

## Sourcemaps for CSS

To see what I mean, open up your app, and inspect an element.  Your browser should show you the CSS of the element in question
and should show you where those classes are defined.  They will all be line 1 of your `.css` bundle.

Making this work is pretty simple, since we've set up the machinery for source maps already.  We need to tell the `css-loader`
that we want sourcemaps. Since that configuration is being passed to the `ExtractTextPlugin`, we'll put it right alongside our
`minmize: true` configuration.  The option is to set `sourceMap: true`.

Here's what our entire Webpack configuration should look like:

!CREATE_FILE webpack.config.js
const path           = require('path');
const UglifyJSPlugin = require('uglifyjs-webpack-plugin');
const HtmlPlugin     = require('html-webpack-plugin');
const ExtractTextPlugin = require('extract-text-webpack-plugin');


module.exports = {
  entry: './js/index.js',
  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: '[chunkhash]-bundle.js'
  },
  module: {
    rules: [
      {
        test: /\.css$/,
        use: ExtractTextPlugin.extract({
          use: {
            loader: "css-loader",
            options: {
              sourceMap: true, // <------
              minimize: true
            }
          }
        })
      }
    ]
  },
  plugins: [
    new UglifyJSPlugin({
      sourceMap: true
    }),
    new ExtractTextPlugin('[chunkhash]-styles.css'),
    new HtmlPlugin({
      inject: false,
      template: "html/index.html"
    })
  ],
  devtool: "inline-source-map"
};
!END CREATE_FILE

If you run Webpack:

!SH yarn webpack

And repeat the steps to inspect an element, you'll now see the correct line numbers in the files where the classes are defined.

Nice!

What about tests?

## Stack Traces in Tests

If we introduce a failure into our tests, we'll see a stack trace, but the line number is useless, as before.

First, remove the `throw` we added before from `js/markdownPreviewer.js`.  Next, let's introduce a test failure in our test.

Here's our entire test file with a failure introduced:

!CREATE_FILE spec/markdownPreview.spec.js
import markdownPreviewer from "../js/markdownPreviewer"

var event = {
  preventDefaultCalled: false,
  preventDefault: function() { this.preventDefaultCalled = true; }
};
var source = {
  value: "This is _some markdown_"
};
var preview = {
  innerHTML: ""
};

var document = {
  getElementById: function(id) {
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

describe("markdownPreviewer", function() {
  describe("attachPreviewer", function() {
    it("renders markdown to the preview element", function() {
      var submitHandler = markdownPreviewer.attachPreviewer(document,"source","preview");
      source.value = "This is _some markdown_";

      submitHandler(event);
      expect(preview.innerHTML).toBe("<p>This is <i>some markdown</em></p>");
      //--FAILURE--------------------------------^^^
      //
      expect(event.preventDefaultCalled).toBe(true);
    });
  });
});
!END CREATE_FILE

!SH{nonzero} yarn karma

Although it seems like our Webpack configuration should include the sourcemaps, even for the test code, for whatever reason it doesn't, and we have to set up an additional preprocessor for Karma to include them.

That preprocessor is `karma-sourcemap-loader`, which we can install thusly:

!SH yarn add karma-sourcemap-loader -D

We configure it *after* the Webpack preprocessor, like so:

!CREATE_FILE spec/karma.conf.js
module.exports = function(config) {
  config.set({
    frameworks: ['jasmine'],
    files: [
      '**/*.spec.js'
    ],
    preprocessors: {
      '**/*.spec.js': [ 'webpack', 'sourcemap' ]
    },
    webpack: require("../webpack.config.js"),
    browsers: ['PhantomJS']
  })
}
!END CREATE_FILE

Now, when we run karma, we should see the stack trace reference a line in our test file:

!SH{nonzero} yarn karma

It does reference a line, which is great, but it's not the correct one, which is not great.

As of this writing, PhantomJS does not properly read the sourcemap and reports the wrong line number.  This sucks, but all is not
lost!

If you recall, we've been using the command line switch `--single-run` to run our tests.  If we omit that, Karma will run our
tests and then sit there, waiting.

```
> $(yarn bin)/karma start spec/karma.conf.js
```

If you look at the output, it will show something like this:

```
22 04 2017 14:36:17.997:INFO [karma]: Karma v1.6.0 server started at http://0.0.0.0:9876/
```

If you navigate to that url and port in your web browser, Karma will run your tests in that browser!  If we do this in Chrome,
the stack trace is correct:

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

It's hard to make out, but you can see that the Chrome run of the test is pointing to line 40, which is where the failing
expectation is.

It's not ideal, but it *is* a way to get stack traces for your tests.

You can hit Ctrl-C to exit Karma.

Not the greatest conclusion to our journey to have a sane development environment, but given what the language gives us—pretty
much nothing—we've made the best of it.

We can also see the tension between monolithic everything-is-included systems like Webpack, and the attempts at modularity and
flexibility.  Because neither Webpack nor Karma were designed to work together, and because each tool has a completer proprietary
plugin/extension mechanism, we have to jump through a lot of hoops to get things working together.  I'll touch on this later
toward the end of our journey, but suffice it to say, the design of these tools seems to have the worst of both being monolithic
and being modular.

So, what's next?  You've probably noticed that running Webpack is slow.  Even if we adopted a full-blown TDD way of working,
we're still going to be running Webpack a lot, and spending most of our time waiting on it.  Can we make that faster?


