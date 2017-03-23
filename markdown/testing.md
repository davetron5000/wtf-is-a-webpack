# Writing and Running Unit Tests

Unit testing has always been possible in JavaScript, but early test runners required opening a page in a web
browser that executed the tests.  Because of Node, we now can execute JavaScript on the command-line, without a
browser, and this is how we'd like to work, because it's faster and easier to automate (e.g. in a continuous
integration systems).

In general, our requirements are:

* We can test our modules in isolation.
* We can execute a single test if we want, or the entire suite.
* We can execute tests without having to run any kind of web browser, even a headless one like PhantomJS.

We're going to use [Jasmine][jasmine] as it's reasonably popular, simple, and works well.

First, we'll add it to our `package.json`.  We'll use `yarn add` again, but pass `-D` which means "this is a
development dependency".  That's important because when we get around to shipping our awesome Markdown converter to
production, we don't need our development dependencies to be part of that.

!SH yarn add -D jasmine

This will install Jasmine which includes the command-line app `jasmine`:

!SH $(yarn bin)/jasmine -h

Let's try out that `init` command.

!SH $(yarn bin)/jasmine init

OK, now we have tests?

!SH $(yarn bin)/jasmine

Not quite.  Let's create a simple no-op spec in `spec/canary.spec.js`:

!ADD_TO spec/canary.spec.js
describe("canary", function() {
  it("can run a test", function() {
    expect(true).toBe(true);
  });
});
!END ADD_TO

And now we have a test:

!SH $(yarn bin)/jasmine

OK, what has this to do with Webpack?  Well, we need to actualy locate our files to test.  Basically, we need to
make sure that the function that `attachPreviewer` returns:

* calls `preventDefault` on the given `event`.
* renders HTML from the markdown in our source element to our preview element.

Let's write that test and then figure out how to run it.  A mocking library would make this easier, but let's not
learn about those yet.  I'm all about first principles, so let's do that.

We have to work a bit backwards, so let's assume we have a mock `document` and we also have access to the source
and preview elements that document will find.  If so, our test will look like this:

```javascript
describe("markdownPreviewer", function() {
  describe("attachPreviewer", function() {
    it("renders markdown to the preview element", function() {
      var submitHandler = markdownPreviewer.attachPreviewer(document,"source","preview");
      source.value = "This is _some markdown_";

      submitHandler(event);

      expect(event.preventDefaultCalled).toBe(true);
      expect(preview.innerHTML).toBe("<p>This is <em>some markdown</em></p>");
    });
  });
});
```

This assumes the following objects exist:

* `attachPreviewer` - the function under test
* `source` - an object with a `value` attribute that we expect `document.getElementById("source")` to return.
* `preview` - an object with an `innerHTML` attribute that we expect `document.getElementById("preview")` to return.
* `event` - an event that knows if `preventDefault` has been called on it.

Let's create those.  Ideally we'd have some mock object library to help us, but let's not get too fancy, as we're
ultimately learning webpack and not testing here.

First, we'll make `event`:

```javascript
var event = {
  preventDefaultCalled: false,
  preventDefault: function() { this.preventDefaultCalled = true; }
};
```

This lets us assert that someone called `preventDefault()`.  Now, let's create our two DOM elements, `source`, and
`preview`:

```javascript
var source = {
  value: "This is _some markdown_"
};
var preview = {
  innerHTML: ""
};
```

Pretty straightforward.  Now, we need a mock `document` implementation that will return them.  All this has to do
is implement `getElementById` and we can hardcode its behavior:

```javascript
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
```

This leaves us with how to access `attachPreviewer`.  We'll use an import, resulting in this entire file for our
test:

!ADD_TO spec/markdownPreview.spec.js
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

      expect(event.preventDefaultCalled).toBe(true);
      expect(preview.innerHTML).toBe("<p>This is <em>some markdown</em></p>");
    });
  });
});
!END ADD_TO

Of course, this doesn't work, because Jasmine has no idea what to do with that `import`:

!SH{nonzero} $(yarn bin)/jasmine

We need Webpack to deal with this for us.  Starting from what we had done before, you might think we could try
something like:

```
$(yarn bin)/webpack --entry=./spec/markdownPreviewer.spec.js --output-file=spec.js
```

We can certainly get that to succeed and produce `spec.js`, but we can't run this file.  It's not even clear what
to *do* with this file.  We can try something like `node spec.js`, but this won't work because our file can't find
`describe`.  We could try something like `import describe from "jasmine"` but this creates a new failure where
Webpack can't find `fs`, which we've never heard of and didn't ask it to find.  Ugh.

This series of failures illustrates yet again the terribleness of JavaScript and the difficulty in understanding what is actually doing what in our 10-line codebase.

In my experience, when failures like this happens, it tells me that I'm doing something terribly wrong.

In our case, we need to use a test runner that knows about Webpack.  Currently, we've been using `jasmine` as our
test runner, but this doesn't work with Webpack as far as I can tell.

A test runner that *does* work is [Karma][karma].

## Karma from First Principles

Karma is yet another tool where you are assaulted with a blob of magic JSON and told it'll just work.  You can also
find *many* blog posts about using it, but they often require you to have a zillion other tools installed, and
there's not a good explanation of what it does or how it works.

So, we start shaving yaks and we'll find out ourselves.

!SH yarn add -D karma
!SH yarn add -D karma-jasmine

And yes, there will be warnings.  And no, `karma-jasmine` does not depend on `karma` for some reason so we have to
explicitly install both.  We don't get to work in a world of nice things, but the install should work.

We can verify that it's at least installed:

!SH $(yarn bin)/karma --version

OK, now what?

Karma's homepage currently states:

> The main goal for Karma is to bring a productive testing environment to developers. The environment being one where they don't have to set up loads of configurations, but rather a place where developers can just write the code and get instant feedback from their tests.

It's OK to chuckle at their proclaimation that we don't need loads of configuration.  Spoiler: we will.

It's common to use `karma init` to create a config file to start off with but this a) requires interactive input
and b) places the file in the current directory.  We don't want either of those, so create `spec/karma.conf.js`
like so:

!ADD_TO spec/karma.conf.js
module.exports = function(config) {
  config.set({
    basePath: '',
    frameworks: ['jasmine'],
    files: [
      '**/*.spec.js'
    ],
    exclude: [
    ],
    preprocessors: {
    },
    reporters: ['progress'],
    port: 9876,
    colors: true,
    logLevel: config.LOG_INFO,
    autoWatch: true,
    browsers: ['PhantomJS'],
    singleRun: true,
    concurrency: Infinity
  })
}
!END ADD_TO

The configuration is an exported function that's given an object that we set some values on.  These keys are [all
documented](https://karma-runner.github.io/1.0/config/configuration-file.html) if you want to know what they do,
but basically we are telling Karma:

* Where are test files are (`**/*.spec.js`, noting that this is relative to where the config file is.)
* What testing framework we are using (`jasmine`)
* What browsers to run our code under (`PhantomJS`)

"Wait, browsers?  PhantomJS?".  Sorry about that.  Karma is for testing front-end code, which is what we are
writing, and that code should be tested in a browser.  PhantomJS is a browser that runs headlessly, meaning it's
the only way to run our tests, with Karma, on the command line.

This seems like it sucks, and it does in many ways, however it *is* a good idea to test our code in the runtime
it'll be used in, and that's a browser.

You'll need to install [PhantomJS][phantomjs] if you haven't.

!SH phantomjs --version

You'll also need to install the launcher for Karma so it can execute PhantomJS.  Karma is a test runner that, by
default, cannot run any tests in any browser.  The JavaScript ecosystem is all about choices.  Endless, endless
choices.

!SH yarn add -D karma-phantomjs-launcher

With that done, we can now run our tests:

!SH{nonzero} $(yarn bin)/karma start spec/karma.conf.js  --single-run

The `--single-run` means "actually run the tests and report the results".  Without it, Karma sits there waiting for
you to navigate to a web server it starts up that then runs the tests.

You'll notice it failed withi the same error as before.  Not to fear…we can fix this.  You'll notice that
configuration key, `preprocessors`.  This allows us to process our code before sending it to Karma to execute.
This sounds like what we want.

There is such a thing called `karma-webpack` that we can install and configure.  First, we'll add it:

!SH yarn add -D karma-webpack

Now, we'll add it as a preprocessor and use `require` to bring in our existing Webpack config.  Your entire
`spec/karma.conf.js` will look like so:

!SH rm spec/karma.conf.js

!ADD_TO spec/karma.conf.js
module.exports = function(config) {
  config.set({

    basePath: '',
    frameworks: ['jasmine'],
    files: [
      '**/*.spec.js'
    ],
    exclude: [
    ],
    preprocessors: {
      '**/*.spec.js': [ 'webpack' ]
    },
    webpack: require('../webpack.config.js'),
    reporters: ['progress'],
    port: 9876,
    colors: true,
    logLevel: config.LOG_INFO,
    autoWatch: true,
    browsers: ['PhantomJS'],
    singleRun: false,
    concurrency: Infinity
  })
}
!END ADD_TO

And wouldn't you know it, it works!

!SH $(yarn bin)/karma start spec/karma.conf.js  --single-run

To be honest, I'm fairly amazed that this actually worked, but we can now run unit tests, which is great.

The main thing to note here is the `webpack:` key in our Karma configuration file.  Our use of `require` is
essentially the same as if we copy and pasted our Webpack configuration into our Karma configuration.  Re-using
that config is good, because we don't have two things to keep up, but you can bet your ass that as we do more
sophisticated things in Webpack, especially around production deployments, things are going to go sideways.  We'll
get to that.

In fact, we should push to production.  The only thing that makes me more nervous than code without tests is code
that isn't shipped to production.
