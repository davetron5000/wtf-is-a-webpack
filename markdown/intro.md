# WTF is a Webpack?

Webpack is becoming the standard in bundling JavaScript, but what does that even mean and how does it work?  Let's
find out.

I find the configuration of Webpack hard to understand and derive.  I find the general concept of Webpack very
difficult to grasp, since I don't spend all of my time writing front-end code.  However, I'm very interested in
making that experience good, and relying on it.

As a Rails  developer, I'm accustomed to the Asset Pipeline "just working" for things that are relevant to
maintaining production applications.  Webpack appears to solve these problems, but in a very un-opinionated way.

Meaning: we must understand how it works in order to effectively use it.  That's what we're going to learn
together.

## What Problem Does Webpack Solve?

As programmers, we want to put code in different files for the purposes of organization.  Said another way, we
don't want all our JavaScript in one file.  We may also wish to use third-party JavaScript libraries to help us.

Because JavaScript [fails to meet many programmer's needs][needs], there has always been a requirement to have some
sort of build step between our various file and the thing a browser executes.

The simplest way is to use a `<script>` tag for each file:

```html
<script src="js/main.js"></script>
<script src="js/address.js"></script>
<script src="js/billing.js"></script>
```

The next simplest way is to concat everything together into one file.  This is what [the Rails Asset Pipeline][sprockets] effectively does.

```
> find js -name \*.js -exec cat {} \; >> bundle.js
```

```html
<script src="bundle.js"></script>
```

This is not good enough for many reasons:

* Everything is globally scoped, which means you can get name clashes if you aren't careful (and it's very hard to be careful, especially when there are third-party libraries afoot).

Actually, this is a good enough reason, but other problems:

* You cannot easly use languages that compile down to JavaScript, such as ES6, CoffeeScript, TypeScript or
whatever.
* It's not easy/clear how to use third-party libraries.
* What about unit tests?

It is these problems Webpack exists to solve.  Webpack allows you to structure your JavaScript—and use third party
libraries—the same as just about every other modern programming language.

```javascript
// inside main.js
var address = require("address");
var billing = require("billing");

billing.some_function();
address.some_other_function();
```

Webpack allows you to say "The file `main.js` is where to look, figure out what else is needed from that" and have
that work.

Let's see how it does that.  Along the way, we'll also learn how Webpack is a sophisticated and unfortunately flexible JavaScript toolchain.

## Webpack from First Principles

To install Webpack, you'll need Node, so [go install it][install-node].  You'll need need a JavaScript library
downloader, which used to be only NPM, but now you should use Yarn, so [go install it][install-yarn].

Once you do that, we'll use Yarn to make `package.json` which controls our JavaScript dependencies.  The reason for
this is that we want a written, executable document of the stuff we've downloaded.  You don't want to just run a
bunch of `yarn` or `npm` command-line invocations.

!SH yarn -y init

This will create an empty `package.json` where we can start putting JavaScript libraries we want to download…starting with Webpack!

!SH{quiet} yarn add webpack

You might see warnings, ASCII art or other things, but it should work.

To verify you have it installed, and to demonstrate how to run it:

!SH $(yarn bin)/webpack --version

The `$(yarn bin)` is a shell invocation that knows where `yarn` has installed binaries.  In this case, it's
`node_modules/.bin`.  This ensures you are using what you installed.

You've now taken your first step into a larger world, which is rife with version incompatibilities, masked or incorrect error messages, and inconsistent behavior, all so you can try to make your life easier while using one of the worst programming languages ever designed!  Webpack is one of the least bad things you'll deal with.

With this out of the way, let's see Webpack actually do something.

As we mentioned above, the purpose of Webpack is to take lots of JavaScript modules and produce a bundle that works
in a browser, but allows you to write organized code.

In Webpack's parlance, the _entry_ is the file it will read to find all other files.  The _output_ is the bundle
that Webpack is creating and will be used in our browser.

Let's create our entry point in `js/index.js`:

!SH mkdir js

Now, create `js/index.js` like so:

!ADD_TO js/index.js
console.log("Hello from index.js!");
import address from './address';
import billing from './billing';

address.announce();
billing.announce();
!END ADD_TO

Now, create `js/address.js` like so:

!ADD_TO js/address.js
console.log("Hello from address.js");
export default {
  announce: function() {
    console.log("Announcing address.js");
  }
}
!END ADD_TO

And create `js/billing.js` like so

!ADD_TO js/billing.js
console.log("Hello from billing.js");
export default {
  announce: function() {
    console.log("Announcing billing.js");
  }
}
!END ADD_TO

<aside class="sidebar">
# What the heck are `import` and `export default`

The whole reason we are using Webpack is because JavaScript has no way to compose source files or package code in any useful way.  A consequence of this is that there is
also no syntax or library to compose code or package files.  Node invented a way to do this now called CommonJS (though Node's is slightly different).  There is also one
called Asynchronous Module Definition or AMD or RequireJS.  So, that's three ways to do it, none standard.

ES6 (or ES2015?) introduced a standard way of bringing in modules.  This is what we're using here, but of course it doesn't work in a browser which is why Webpack exists. Webpack translates our use of `import` and `export` so that things work in a browser.

So, in this code in `file.js`:

```javascript
export default {
  foo: function() {},
  bar: 42
}
```

We are exporting `foo` and `bar`, which can be imported like so:

```javascript
import my_lib from './file'
my_lib.foo(); // calls the function foo above
my_lib.bar;   // 42
```
</aside>

What we want is to produce a singe file called `bundle.js` that uses all this code.

We can do this without configuration per se, and just use CLI options:

!SH $(yarn bin)/webpack  --entry ./js/index.js  --output-filename=bundle.js

Now, let's load this in a browser.  Create `index.html` like so:

!ADD_TO index.html
<!DOCTYPE html>
<html>
  <head>
    <script src="bundle.js"></script>
  </head>
  <h1>Open the Web Inspector</h1>
</html>
!END ADD_TO

Open this in a browser, then open the JavaScript console.  You should see all our messages:

!DUMP_CONSOLE index.html

Ok then!  That was neat!

<aside class="sidebar">
# What's in `bundle.js` anyway?

Beware.  Here be dragons!

As mentioned, Webpack makes `import` and `export` work.  It does this by creating a somewhat small JavaScript-based implementation of them, and translates the code in our
various `.js` files such that it uses this _shim_.  If you look at `bundle js` you can see it.  It's nasty—as all generated code is—but you can see your code somewhere near
the bottom.

In this tiny example, the shim is larger than the code, but in a real application, this shim won't add much overhead to what you are making the user download.
</aside>

We don't want to be building our JavaScript bundle from an ever-increasingly-complex command-line invocation.  We also don't want the generated code being dumped in our root
directory either, so let's set-up a tiny project structure to keep things organized.

First, create a `config` directory, where our Webpack configuration file will go.

!SH mkdir config

Now, make `config/webpack.config.js` look like so:

!ADD_TO config/webpack.config.js
module.exports = {
  entry: './js/index.js',
  output: {
    path: './dist',
    filename: 'bundle.js'
  }
};
!END ADD_TO

This will do what we did before with Webpack, *except* it will place `bundle.js` inside `dist/` instead of the current directory.  We can run it like so:

!SH $(yarn bin)/webpack  --config config/webpack.config.js
!SH ls dist

Woot!

If we move `index.html` into the newly-created `dist`:

!SH mv index.html dist

We can open that in a browser, open the JavaScript console and see the same messages as before.

!DUMP_CONSOLE dist/index.html

The configuration file saves us some keystrokes, but even typing our `$(yarn bin)/webpack etc etc` is a bit cumbersome.  We'll use a handy feature of `package.json` to
create an alias for running webpack so we can just type `yarn run webpack`.

We'll add a `"scripts"` key to `package.json` so the entire thing should now look like so:

!PACKAGE_JSON
{
  "scripts": {
    "webpack": "$(yarn bin)/webpack --config config/webpack.config.js --display-error-details"
  }
}
!END PACKAGE_JSON

And now:

!SH yarn run webpack

It's a convoluted shell alias, but it's how things work in JavaScript-land, so when in Rome and all that.

## Now What?

We're not even getting started—this was just an overview of what Webpack even is and why it exists.  I found it personally helpful to go through this so I could see a very
minimal use-case and learn the basic concepts, namely `entry` and `output`.

Where do we go from here?  We're going to build on our fledgling codebase to learn more sophisticated things about working with Webpack that are all real-life issues you
will have to deal with, including:

* Bringing in third-party libraries
* Writing and running unit-tests (without a browser)
* Packaging for production
* Using ES6
* Managing CSS using SASS
* Dealing with Webfonts

These are all possible with Webpack and also happen to be intended use-cases, however it's extremely hard to figure out how to do these things without someone just showing
you the magical configuration needed to make them happen.  I don't like that—I need to know how my tools work so I can have a chance in hell of diagnosing problems they will
inevitably cause.

So that's where we're going from here.  Baby steps so that by the end, we can understand exactly what Webpack is actually doing and why.

The next simplest thing we could do is to pull in some third-party libraries, so let's do it!
