Unit testing has always been possible in JavaScript, but early test runners required opening a page in a web
browser that executed the tests.  Because of Node, we now can execute JavaScript on the command-line, without a
browser, and this is how we'd like to work, because it's faster and easier to automate (e.g. in a continuous
integration systems).

Spoiler: we don't get to work this way.

We *can* get close, by executing our tests in PhantomJS, a headless version of WebKit.

Ideally, we want the ability to:

* test our modules in isolation
* execute a single test while we drive functionality in a module.
* run tests without having to pop up a browser.

There are many JavaScript testing frameworks, and even the definition of what a _testing framework_ is is unclear.  We'll start
by finding a reasonably complete library that allows us to write tests and assertions.

[Jasmine][jasmine] fits that bill.  It's reasonably popular and easy to understand.

[jasmine]: https://jasmine.github.io

First, we'll add it to our `package.json`.  We'll use `yarn add` again, but pass `-D` which means "this is a
development dependency".  That's important because when we get around to shipping our awesome Markdown previewer to
production, we don't need our development dependencies to be part of that.

!SH yarn add -D jasmine

This will install Jasmine which includes the command-line app `jasmine`:

!SH $(yarn bin)/jasmine -h

Let's try out that `init` command.

!SH $(yarn bin)/jasmine init

OK, now we have tests?

!SH $(yarn bin)/jasmine

Not quite.  Let's create a simple no-op spec in `spec/canary.spec.js`:

!CREATE_FILE spec/canary.spec.js
describe("canary", function() {
  it("can run a test", function() {
    expect(true).toBe(true);
  });
});
!END CREATE_FILE

Hopefully, Jasmine's syntax and API is clear, but the idea is that we use `describe` to block of a bunch of tests we'll write,
and then `it` for each test.  The idea is that these can be pieced together in some pidgen-like English that developers
convince themselves is a specification.  It's silly, but works.

And now we have a test:

!SH $(yarn bin)/jasmine

OK, what has this to do with Webpack?  Well, we need to actually locate our files to test.

Assuming we could do that, what is the test we'd like to write?

We're testing a function that returns a function, so our tests will be on the function that `attachPreviewer` returns to us.
That function should:

* call `preventDefault` on the given `event`.
* render HTML from the markdown in our source element to our preview element.

Let's write that test first, before we figure out how to get a hold of `attachPreviewer`.  In theory, Webpack should help us
execute tests and not inform the way in which we write them.  In theory.

In a Jasmine test, your top-level `describe` should be for the module being tested, and then you'd have one `describe` each for
the routines you're going to test.  That means our test file will have this form:

```javascript
describe("markdownPreviewer", function() {
  describe("attachPreviewer", function() {
      // A bunch of `it` calls for each tests
      // (but we'll only need one right now )
  });
});
```

To write our test, we need to make some assumptions about some objects that will need to exist.  In particular, we need to have
some sort of object that exposes an `innerHTML` property that we can examine to make sure that we've rendered HTML to it.  We
also need another object that exposes a `value` property we can use to set the markdown being rendered. And, we need something to
stand in for the global `document`, since, as you recall, we're passing that into `attachPreviewer`.  Oh, and an `event`.  Don't
worry, we'll define all these.

Before we see where those come from, let's assume they exist so we can write our test.

First thing is to call `attachPreviewer` and get the function we're going to execute. Let's assume (I know, SO MANY assumptions…it'll work out, I promise) that we have `markdownPreviewer` available, which is our code.

```javascript
var submitHandler = markdownPreviewer.attachPreviewer(document,
                                                      "source",
                                                      "preview");
```

`document` is assumed to exist, and we're also assuming that calls to `document.getElementById("source")` and
`document.getElementById("preview")` both work and return objects we can manipulate.

Next, we want to manipulate `source`:

```javascript
source.value = "This is _some markdown_";
```

Now, we can call `submitHandler(event)`;

```javascript
submitHandler(event);
```

The main point of our test is that we rendered markdown, so let's check for that:

```javascript
expect(preview.innerHTML).toBe(
    "<p>This is <em>some markdown</em></p>");
```

We also want to make sure that `preventDefault()` was called on `event`, so let's hand-wave over that like so:

```javascript
expect(event.preventDefaultCalled).toBe(true);
```

This means our entire test is:

```javascript
describe("markdownPreviewer", function() {
  describe("attachPreviewer", function() {
    it("renders markdown to the preview element", function() {
      var submitHandler = markdownPreviewer.attachPreviewer(document,
                                                            "source",
                                                            "preview");
      source.value = "This is _some markdown_";

      submitHandler(event);

      expect(preview.innerHTML).toBe(
          "<p>This is <em>some markdown</em></p>");
      expect(event.preventDefaultCalled).toBe(true);
    });
  });
});
```

We've made a ton of assumptions about objects that exist and have behavior, so let's set that up now.  We could use a mocking
library, but I'm not willing to go to this level of the yak-shaving quite yet, so let's hand-jam these.

First, we'll make `event`:

```javascript
var event = {
  preventDefaultCalled: false,
  preventDefault: function() { this.preventDefaultCalled = true; }
};
```

We know our code should call `preventDefault`, so we implement that to record that it was called in a way we can check in our
test.

Next, we need our DOM elements, `source`, and `preview`:

```javascript
var source = {
  value: ""
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

Again, mocking might be better for a larger project, but this is enough to get us going and our test should work.

Except we still need access to *our* code.

This is JavaScript.  We know this.

```javascript
import markdownPreviewer from "../js/markdownPreviewer"
```

Seems like it should work.  Here's the entire test file:

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
      var submitHandler = markdownPreviewer.attachPreviewer(document,
                                                            "source",
                                                            "preview");
      source.value = "This is _some markdown_";

      submitHandler(event);

      expect(preview.innerHTML).toBe(
        "<p>This is <em>some markdown</em></p>");
      expect(event.preventDefaultCalled).toBe(true);
    });
  });
});
!END CREATE_FILE

Let's run our test and be excited!

!SH{nonzero} $(yarn bin)/jasmine

Welp.  Before I had walked through the previous two sections, I would've been confused and angry about this result.  But, since
we know what problem Webpack solves, and how it solves it in a minimal case, we shouldn't be surprised.  Jasmine has no idea how
to import, because Node doesn't support that syntax.

Since we are using Webpack for our actual code, it should be used to manage our test code as well.  That way all of our code can
be in a single verison of JavaScript that Webpack can compile.

Unfortunately, it isn't that easy.   This won't work:

```
$(yarn bin)/webpack --entry=./spec/markdownPreviewer.spec.js --output-file=spec.js
```

But, even if it did, what do we *do* with `spec.js`?  Jasmine's test runner (the `jasmine` command-line app) is expecting some
JavaScript files that call `describe` and `it`.  We could try doing something like

```javascript
import describe from "jasmine"
```

But you'll get an error about `fs` which you've never heard of and didn't ask to use.  Ugh.

In my experience, when things Completely Fail to Work at Even a Basic Level™, it tells me that I've made the wrong choice at some
level higher than the code.

In this case, it's our choice of test runner.  Note that I didn't say test _framework_, but test _runner_.  Why are these even
different things?  What kind of test framework can't run tests?

In they JavaScript ecosystem: pretty much all of them.

Because each project is a chance to artisnally hand-craft a small batch tool chain, and because the language we're using can't
even agree on something basic like how to modularize code, we end up with lots of tools that cannot interoperate together at all.

In this case, our desire to use `import` conflicts with Jasmine's inability to handle it.

What we need is a test runner that can both use Webpack to assemble our code, but also execute our tests using Jasmine.

That test runner that is [Karma][karma].

[karma]: https://karma-runner.github.io/1.0/index.html

## Karma: What Problem Does it Solve?

Karma executes tests, and is yet another tool where you learn about it by reading blog posts and pasting JSON boilerplate into
your project and praying nothing goes wrong.  As mentioned previously, that's not good enough.

We know that it has the ability to solve our problelm (mostly because I'm telling you in advance that this is the case), so let's
see exactly how.

First, we'll install it

!SH yarn add -D karma

Check that it's installed:

!SH $(yarn bin)/karma --version

Because Karma has no default test framework, we must install one for the framework we're using.  In this case, that's Jasmine:

!SH yarn add -D karma-jasmine

Why not just instal `karma-jasmine` and have that pick up the dependency on `karma`?  No idea.  This is JavaScript, and we don't
get nice things.

OK, now what?  Karma's homepage currently states:

> The main goal for Karma is to bring a productive testing environment to developers. The environment being one where they don't have to set up loads of configurations, but rather a place where developers can just write the code and get instant feedback from their tests.

It's OK to chuckle at their proclaimation that we don't need loads of configuration.  Spoiler: we will.

It's common to use `karma init` to create a config file to start off with but this a) requires interactive input, b) places the file in the current directory, and c) creates a file with way more configuration than is technically needed.  We don't want any of that, so create `spec/karma.conf.js` yourself.  The bare minimum information you have to provide is:

* What testing frameworks are being used (Jasmine, in our case)
* Where the actual test files are (`spec/` in our case)
* What browsers we want to run the code in. (See below for why we have to care about browsers)

There's no technical reason to have to provide any of this information, but JavaScript doesn't want to tell you where to put your files or what testing frameworks to use.  It's cool with anything, so you do you (even though your job is to get things done and not evaluate a bunch of essentially equivalent testing frameworks).

The mimimal configuration would the following, which you should place into `spec/karma.conf.js`:

!CREATE_FILE spec/karma.conf.js
module.exports = function(config) {
  config.set({
    frameworks: ['jasmine'],
    files: [
      '**/*.spec.js'
    ],
    browsers: ['PhantomJS']
  })
}
!END CREATE_FILE

Note that the location of our test files is relative to wherever the config file is.  Since we put it in `spec/`,
`**/*.spec.js` means "all the files in `spec/` that end in `.spec.js`.

But I'm burying the lede.  We had to do something with browsers.  I know and I'm really sorry, but this is how it
has to be.

On the one hand, this is terrible, because anything involving a browser will be incredibly slow and clunky.  But, on the other
hand, our code will only ever run in a browser, so as good developers that's technically the right place to test it.

PhantomJS is a browser that runs headlessly, meaning it's the only way to run our tests, with Karma, on the command line.

I know this sucks, and you should brace yourself for a terrible testing experience that's worse than all other ecosystems, but let's just give thanks that it's possible and that we don't have to pop up Firefox and deal with all that.

So…you'll need to install [PhantomJS][phantomjs] if you haven't.  When you do that, you can test your intall thusly:

[phantomjs]: http://phantomjs.org/download.html

!SH phantomjs --version

You'll also need to install the PhantomJS launcher for Karma so it can execute PhantomJS.  Because again, why would you want your
testing tool telling you how to write tests?  Clearly, what you want is a test runner that by default cannot run any tests in any
browser.  The JavaScript ecosystem is all about choices.  Endless, endless choices.

!SH yarn add -D karma-phantomjs-launcher

With that done, we can now run our tests:

!SH{nonzero} $(yarn bin)/karma start spec/karma.conf.js  --single-run

The `--single-run` means "actually run the tests and report the results".  Without it, Karma sits there waiting for
you to navigate to a web server it starts up that then runs the tests.  Trust me, this is the best it gets for now.

You'll notice it failed with the same error as before. The difference here, is that Karma is sophisticated enough such that we
can throw more JSON at it to fix the problem.

We need to have our tests use Webpack to bundle up our JavaScript so we can access it and run tests against it.

Karma's configuration file has an option called `preprocessors` that allows us to do stuff to our code before it runs the tests.  There is such a preprocessor called `karma-webpack` that we can install and configure.  First, we'll add it:

!SH yarn add -D karma-webpack

Now, we'll add it as a preprocessor and use `require` to bring in our existing Webpack config (not `import`.  Sigh).  Your entire `spec/karma.conf.js` will look like so:

!EDIT_FILE spec/karma.conf.js /* */
{
  "match": "    browsers:",
  "insert_before": [
    "    preprocessors: {",
    "      '**/*.spec.js': [ 'webpack' ]",
    "    },",
    "    webpack: require('../webpack.config.js'),"
  ]
}
!END EDIT_FILE

And wouldn't you know it, it works!

!SH $(yarn bin)/karma start spec/karma.conf.js  --single-run

I'm not going to lie, I was not expecting this to work at all, especially with this fairly minimal amount of configuration.  While it's not ergonomic or developer-friendly, it does work, and it was easy enough to figure out just be reading documentation.  Take that Medium thinkpieces!

Before we move on, let's wrap this up into a script inside `package.json`, because typing all this out sucks.

!PACKAGE_JSON
{
  "scripts": {
    "webpack": "$(yarn bin)/webpack --config webpack.config.js --display-error-details",
    "karma": "$(yarn bin)/karma start spec/karma.conf.js --single-run"
  }
}
!END PACKAGE_JSON

Now, we can run tests with `yarn karma`:

!SH yarn karma

The main thing to note here is the `webpack:` key in our Karma configuration file.  Our use of `require` is
essentially the same as if we copy and pasted our Webpack configuration into our Karma configuration.  Re-using
that config is good, because we don't have two things to keep up, but you can bet your ass that as we do more
sophisticated things in Webpack, especially around production deployments, things are going to go sideways.  We'll
get to that.

In fact, we should push to production.  The only thing that makes me more nervous than code without tests is code that isn't shipped to production.
