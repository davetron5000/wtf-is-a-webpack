We've got all the right tools in places to build, manage, test, deploy, and debug our application.  But it's all really really slow.  We can make this faster by using Webpack's _dev server_.  But first, a word on workflow.

## A Reliable Development Workflow

We've been talking about JavaScript and CSS, but at the end of the day, you are building a web application, and that means there is some logic and code that must exist.  This logic and code is likely the biggest source of complexity in your application.  While CSS and UI is certainly complex, it pales in comparison to what is typically required to build an actual web application.

Because of this, your default workflow should be a test-driven one.  You should not run your application to verify that its underlying logic is working correctly—you should run a test of that logic.

Granted, our markdown previewer doesn't have a lot of such logic, but it *is* important to understand that
a “tweak and reload” style of development is the slowest style of development.

Unfortunately, for UI work, there isn't a great substitute, so let's see how Webpack helps.

## Auto-reloading On Changes

Webpack is super slow:

!SH time yarn webpack

When designing a UI, you need to change markup, CSS, and JavaScript.  It's often not possible to assure that JavaScript is providing the UI interactions you want without trying it, and that's lots of small changes that you reload in the browser.  Having to wait 3+ seconds each time sucks.

We can make this a bit better by using `webpack-dev-server`, which we can install with yarn:

!SH yarn add webpack-dev-server -D

Once this is done, run it with the `--open` flag, and your application will pop up in your favorite browser:

```
> $(yarn bin)/webpack-dev-server --open
```

This will compile your app and load it, so it will take the same 4+ seconds as before.

Next, open up `css/styles.css` in your editor, and arrange your windows so that you can see both your editor *and* your browser.  Make a change to the CSS, and viola, your browser refreshes with that change. Repeat with `html/index.html` and `js/index.js`.  Not too bad.

The refresh isn't as fast as we'd like, but it's still not too bad.  You could easily open up your code editor on one side of the screen, and your browser on the other, and get to work.

Part of the reason is that we split our code into dev and production.  To re-run Webpack in dev, we aren't minifying, hashing, or generating a slow source map.  That helps.

What about tests?

## Auto-reloading in Tests

When we learned about Karma, we gave it the `--single-run` flag.  We later saw that omitting this starts up a server you can use
to run your tests in any  browser.  This server also watches for changes in our code and tests and re-runs them automatically.

```shell
> $(yarn bin)/karma start spec/karma.conf.js
Hash: e0bdc8cc97632b01d813
Version: webpack 3.0.0
Time: 40ms
webpack: Compiled successfully.
webpack: Compiling...
webpack: wait until bundle finished:
Hash: 45c62a5c6505ba4e17fb
Version: webpack 3.0.0
Time: 176ms
                  Asset     Size  Chunks             Chunk Names
         canary.spec.js   2.6 kB       0  [emitted]  canary.spec.js
markdownPreview.spec.js  78.8 kB       1  [emitted]  markdownPreview.spec.js
   [0] ./spec/canary.spec.js 107 bytes {0} [built]
   [1] ./spec/markdownPreview.spec.js 1.23 kB {1} [built]
   [2] ./js/markdownPreviewer.js 381 bytes {1} [built]
   [3] ./node_modules/markdown/lib/index.js 143 bytes {1} [built]
   [4] ./node_modules/markdown/lib/markdown.js 51 kB {1} [built]
   [5] ./node_modules/util/util.js 15.6 kB {1} [built]
   [6] (webpack)/buildin/global.js 509 bytes {1} [built]
   [7] ./node_modules/process/browser.js 5.42 kB {1} [built]
   [8] ./node_modules/util/support/isBufferBrowser.js 203 bytes {1} [built]
   [9] ./node_modules/util/node_modules/inherits/inherits_browser.js 672 bytes {1} [built]
webpack: Compiled successfully.
25 06 2017 11:32:38.096:WARN [karma]: No captured browser, open http://localhost:9876/
25 06 2017 11:32:38.103:INFO [karma]: Karma v1.7.0 server started at http://0.0.0.0:9876/
25 06 2017 11:32:38.104:INFO [launcher]: Launching browser PhantomJS with unlimited concurrency
25 06 2017 11:32:38.108:INFO [launcher]: Starting browser PhantomJS
25 06 2017 11:32:38.928:INFO [PhantomJS 2.1.1 (Mac OS X 0.0.0)]: Connected on socket l1dBRG0VGQoUpBORAAAA with id 2070764
PhantomJS 2.1.1 (Mac OS X 0.0.0): Executed 2 of 2 SUCCESS (0.012 secs / 0.008 secs)
```

Your tests might still be broken from the last chapter, so, without stopping Karma, fix the tests.  They should automatically
re-run without doing anything.  Nice!

What this means is that by running Karma all the time, you can work quickly with a TDD flow, and when you need to switch to
in-browser design or tweaking, running the Webpack dev server lets you work quickly there, too.

There's one last thing we need to look into, and that's the ability to use a better language than JavaScript Since Webpack is essentially compiling our JavaScript and CSS, it stands to reason that if we wanted to use something like TypeScript or ES2015, it should be able to handle that.
