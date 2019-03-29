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

There are many JavaScript testing frameworks, though even the definition of what a _testing framework_ is is unclear.  According
to the [State of JavaScript 2018 testing results](https://2018.stateofjs.com/testing/overview/), Jest and Mocha are the top
contenders for most popular.  We'll go with [Jest][jest] since it just eeks out Mocha and has higher growth, so likely to be a solid contender.

First, we'll add it to our `package.json`.  We'll use `yarn add` again.

!SH yarn add -D jest

This will install Jest which includes the command-line app `jest`:

!SH $(yarn bin)/jest -h

Much to my surprise, Jest works on a minimal test with no setup.  Let's see that by creating a basic test in
`test/canary.test.js`:

!CREATE_FILE test/canary.test.js
describe("canary", function() {
  it("can run a test", function() {
    expect(true).toBe(true);
  });
});
!END CREATE_FILE

Hopefully, Jest's syntax and API is clear, but the idea is that we use `describe` to block off a bunch of tests we'll write,
and then `it` for each test.  The idea is that these can be pieced together in some pidgen-like English that developers
convince themselves is a specification.  It's silly, but works.

And now we have a test:

!SH $(yarn bin)/jest test/

This validates that we can run a test, but where is Webpack in all this?  It's absence is felt if we try to access our code.

Let's modify our canary test to load our markdown previewer and assert that it's defined:

!EDIT_FILE test/canary.test.js /* */
{
  "match": "describe(\"canary\", function() {",
  "insert_before": [
    "import markdownPreviewer from \"../js/markdownPreviewer\"",
    ""
  ]
},
{
  "match": "    expect(true).toBe(true);",
  "replace_with": [
    "    expect(markdownPreviewer).toBeDefined();"
  ]
}
!END EDIT_FILE

Now, when we run Jest again, we see the problem:

!SH{nonzero} $(yarn bin)/jest test/

Jest doesn't understand import, since Jest is running via Node and Node doesn't understand import.  While Node understands
`require`, our code uses `import`, so using `require` in our test won't work.  The entire reason we are using Webpack is to
assemble our bundle of JavaScript code, so it stands to reason we need to use Webpack with our tests as well.

Let's create a second Webpack configuration that will produce a test-only bundle that we can feed to Jest.  We'll place this in
`test/webpack.test.config.js`:

!CREATE_FILE test/webpack.test.config.js
const path = require('path');

module.exports = {
  entry: "./test/canary.test.js",
  output: {
    path: path.resolve(__dirname, "."),
    filename: "bundle.test.js"
  },
  mode: "none"
};
!END CREATE_FILE 

This is similar to our existing config with a few differences.  First, our entry point is our test file instead of `js/index.js`.
Second, our `output` goes to the test directory and uses `bundle.test.js` as the output name.  None of this is required, but it
helps immensely when we see files in our project to know what they are for without having to refer to configuration.  It's pretty
obvious that the file `bundle.test.js` is not for public consumption and that the file `webpack.test.config.js` is a Webpack
configuration for testing.

Also, please note the very confusing file paths.  Our entry point's path is relative to where we are running Webpack, but our
output path is relative to where the Webpack configuration lives.  I can't explain why this is, and it's very confusing, but just
keep a note of it.

Let's run Webpack using this new configuration:

!SH $(yarn bin)/webpack --config test/webpack.test.config.js --display-error-details

We can see that produced the desired file:

!SH ls test/

Now, we can run Jest, telling it to run the tests in the bundle, since that contains all of our tests:

!SH $(yarn bin)/jest test/bundle.test.js

Nice!  This means that we can access our production code in unit tests by using Webpack to bundle it all app for us. It also
means that as we write more complex tests, we can extract shared testing code and use `import` to bring it in, just like in any
other programming environment.

Next, let's wrap all this up into a script in `package.json`:

!PACKAGE_JSON
{
  "scripts": {
    "webpack": "webpack --config webpack.config.js --display-error-details",
    "webpack:test": "webpack --config test/webpack.test.config.js --display-error-details",
    "jest": "jest test/bundle.test.js",
    "test": "yarn webpack:test && yarn jest"
  }
}
!END PACKAGE_JSON

Now, we can run the entire thing with `yarn test`:

!SH yarn test

There's one thing left we need to learn about before moving on.  Our current entry point is a single test file, but it's likely
we'll have many different test files as our application grows.  Let's create `test/markdownPreviewer.test.js` so that it has our
simple test-for-existence, and we'll leave `test/canary.test.js` as simply asserting the truth.

!CREATE_FILE test/markdownPreviewer.test.js
import markdownPreviewer from "../js/markdownPreviewer"

describe("markdownPreviewer", function() {
  it("should exist", function() {
    expect(markdownPreviewer).toBeDefined();
  });
});
!END CREATE_FILE

`test/canary.test.js` should look like so:

!CREATE_FILE test/canary.test.js
describe("canary", function() {
  it("can run a test", function() {
    expect(true).toBe(true);
  });
});
!END CREATE_FILE

If we run `yarn test` again, however, we'll only run the test in `canary.test.js`, because that's the file defined as our entry
point for our Webpack test configuration.  Webpack's `entry` key can take an array of files.  In this case, Webpack essentially
concatenates them all together.  For running tests, this is what we want (for our production bundle, you'll recall we have to
attach our code to the DOM—that's not something we need to do in unit tests).

While we could itemize out the files in the Webpack config, we'd have to change it every time we added a file, and that's a pain.
Instead, we'll use the [glob module](https://github.com/isaacs/node-glob) included by Webpack, which gives us the function `sync` that will return all files matching a regular expression (it's called `sync` because it does so synchronously without a callback, which is the right behavior for configuration files).  Note that we want to be careful *not* to include a previous `bundle.test.js` file, so we'll need to first use `glob` to get all files matching `*.test.js` and then remove `bundle.test.js` from that list.  And, because of the weird way Webpack resolves paths, we'll need to prepend each file with `./` so Webpack can find it.

Here's how `test/webpack.test.config.js` should look:

!EDIT_FILE test/webpack.test.config.js /* */
{
  "match": "const path = require('path');",
  "insert_after": [
    "const glob = require('glob');",
    "",
    "const testFiles = glob.sync(\"**/*.test.js\").",
    "                       filter(function(element) {",
    "  return element != \"test/bundle.test.js\";",
    "}).map(function(element) {",
    "  return \"./\" + element;",
    "});"
  ]
},
{
  "match": "  entry: \"./test/canary.test.js\",",
  "replace_with": [
    "  entry: testFiles,"
  ]
}
!END EDIT_FILE

Now, when we run `yarn test`, we should see two tests running from our two files:

!SH yarn test

We should now write a real test for `markdownPreviewer`, but that's outside the scope of learning about Webpack, so we'll leave
that as an exercise for you.

There are two potential problems with this setup that we aren't going to worry about.  The first is that we have to run webpack
and then jest every time we change any file.  While we've wrapped that in a convenient alias in `package.json`, it could be slow
as our project grows.  Because of Webpack's design, we can't really do much about this other than hope a module is created to
address the issue, or learn essentially of all Webpack's internals.  Both of those options suck, so let's revisit this issue if
it becomes a real problem.

The second problem we're going to ignore for now is that we have two Webpack configurations with some shared similarities.  The
two configuration files are tiny, and there isn't much duplication, so we'll live with it for now.  As we'll see when we
configure Webpack for a production deployment, we'll have a way to share common configuration should we need it.

And speaking of production, it's time to sort that out.  The only thing worse than code without tests is code that's not in
production meeting a real user need, so let's get to it.
