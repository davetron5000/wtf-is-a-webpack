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

When designing a UI, you need to change markup, CSS, and JavaScript.  It's often not possible to assure that JavaScript is providing the UI interactions you want without trying it, and that's lots of small changes that you reload in the browser.  Having to wait a few seconds or more each time sucks.

We can make this a bit better by using `webpack-dev-server`, which we can install with yarn:

!SH yarn add webpack-dev-server -D

Once this is done, run it with the `--open` flag, and your application will pop up in your favorite browser:

```
> $(yarn bin)/webpack-dev-server --open
```

This will compile your app and load it, so it will take the same time as before.

Next, open up `css/styles.css` in your editor, and arrange your windows so that you can see both your editor *and* your browser.  Make a change to the CSS, and viola, your browser refreshes with that change. Repeat with `html/index.html` and `js/index.js`.  Not too bad.

The refresh isn't as fast as we'd like, but it's still not too bad.  You could easily open up your code editor on one side of the screen, and your browser on the other, and get to work.

Part of the reason is that we split our code into dev and production.  To re-run Webpack in dev, we aren't minifying, hashing, or generating a slow source map.  That helps.

What about tests?

## Auto-reloading in Tests

Since our testing workflow is to build the bundle with our tests, then point Jest at that bundle, we can't really use the webpack
dev server for this.  The dev server expects to send code to the browser directly, and there's no browser for tests.

What we *can* do is use the `--watch` flag of Webpack to have it auto-rebuild the bundle when files it depends on change.  We can
also test Jest to re-run tests when the bundle changes.  Let's add two new npm scripts, one called `webpack:test:server` and the
other called `jest:server`, like so:

!PACKAGE_JSON
{
  "scripts": {
    "webpack": "webpack $npm_package_config_webpack_args",
    "webpack:production": "webpack $npm_package_config_webpack_args --env=production",
    "webpack:test": "webpack $npm_package_config_webpack_args --env=test",
    "jest": "jest test/bundle.test.js",
    "test": "yarn webpack:test && yarn jest",
    "webpack:test:server": "webpack $npm_package_config_webpack_args --env=test --watch",
    "jest:server": "jest test/bundle.test.js --watch"
  }
}
!END PACKAGE_JSON

Now, open three terminals.  In one, start webpack:

```
> yarn webpack:test:server

« standard massive webpack output»

```

In the other, start Jest:

```
> yarn jest:server

«test runs»

```

In the third, edit one of your test to add a new `it`.  You should see your new test get auto-run by Jest.

Both Webpack and Jest are re-running themselves when files change.  This isn't bad.  It's not *great* because we have to create
our bundle each time, but it's not bad.  If our project gets very large, this situation might not work, and then we're into a
strange and painful world of getting Jest to work more directly with Webpack, which seems to not be well supported.

There's one last thing we need to look into, and that's the ability to use a better language than JavaScript Since Webpack is essentially compiling our JavaScript and CSS, it stands to reason that if we wanted to use something like TypeScript or ES2015, it should be able to handle that.
