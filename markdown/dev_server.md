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

Next, open up `css/styles.css` in your editor, and arrange your windows so that you can see both your editor *and* your browser.  Make a change to the CSS, and viola, your browser refreshes with that change. Repeat with `html/index.html` and `js/index.js`.  To too bad.

The refresh isn't as fast as we'd like, but it's still not too bad.  You could easily open up your code editor on one side of the screen, and your browser on the other, and get to work.

Part of the reason is that we split our code into dev and production.  To re-run Webpack in dev, we aren't minifying, hashing, or generating a slow source map.  That helps.
