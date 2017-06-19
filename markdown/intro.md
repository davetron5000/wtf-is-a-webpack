Webpack is becoming the standard in bundling JavaScript, but what does that even mean and how does it work?  Let's
find out.

I find the configuration of Webpack hard to understand and derive.  I find the general concept of Webpack very
difficult to grasp, especially when reading the myriad blogs documenting the way to set it up—they are all different!

The source of this is that Webpack is a monolithic system that does many unrelated things in an opaque way, while also being
designed around extreme flexibility.  Unlike a monolithic system such as Ruby on Rails, nothing in  Webpack “just works”—you
have to configure even basic things.

This is part of JavaScript's culture—each new problem in your development environment is viewed as a chance to invent a
solution from first principles and no particular opinion on this is viewed as canonical or idiomatic.  This means we'll be
spending a lot of time in documentation and a lot of time making decisions that have nothing to do with our users or the
problems we're trying to solve for them.

So, let's figure out what even is a Webpack together by starting from nothing.  You'll be amazed at how little JSON you need to
throw at this problem, Medium blog posts be damned!

## What Problem Does Webpack Solve?

Webpack exists to give us a feature of JavaScript that exists in every other language by default - modularization.

As programmers, we want to put code in different files for the purposes of organization.  Said another way, we
don't want all our JavaScript in one file.  We may also wish to use third-party JavaScript libraries to help us.

Because JavaScript [fails to meet many programmer's needs][needs], there has always been a requirement to have some
sort of way to deploy code organized in multiple files to a user's web browser. 

[needs]: http://naildrivin5.com/blog/2016/01/13/hierarchy-of-software-needs.html

The simplest way is to use a `<script>` tag for each file:

```html
<script src="js/main.js"></script>
<script src="js/address.js"></script>
<script src="js/billing.js"></script>
```

This is hard to maintain, so another way is to concatenate all the files together into one bundle during the build of your
application, and deploy just that bundle to the user's browser.

```
> find js -name \*.js \
          -exec cat {} \; >> bundle.js
```

```html
<script src="bundle.js"></script>
```

This is what [the Rails Asset Pipeline][sprockets] effectively does.

[sprockets]: http://guides.rubyonrails.org/asset_pipeline.html

This is not good enough for many reasons:

* Everything must be globally scoped, meaning name clashes are hard to avoid, especially when third-party code is involved.
* In fact, it's not clear how to use third-party libraries - are they in your bundle, or separate `<script>` tags?
* You cannot easly use languages that compile down to JavaScript, such as ES6, CoffeeScript, TypeScript or whatever.
* Good luck writing unit tests.

If only JavaScript had a module system like every other language.  It [sorta does][spec], but not in any useful way, because no
browser supports the latest version of JavaScript.  And no browser ever will (since “the latest version of JavaScript“ is a
moving target).

[spec]: http://www.ecma-international.org/ecma-262/6.0/#sec-modules
<aside class="sidebar">
<h1>But, but JavaScript <em>does</em> support that feature!</h1>
<p>
Because the JavaScript ecosystem can't even agree on the name of the language or how its versions are to be referred to,
throughout this book, I'll be using the word “JavaScript” to mean “the version of javaScript that runs in all
reasonable browsers”.  I realize this definition if vague and changes over time.
</p>
<p>
The main point is that there will <em>always</em> be a newer version of JavaScript than what works in a browser, so as a
developer, it's in your best interest to simply accept this fact, and plan your development workflow such that the language
you write will not be directly sent to a browser.  Call the former what you will, but the latter is called “JavaScript”.
</p>
</aside>

Webpack implements a module system as well as a way to translate JavaScript code that doesn't work in any web browser to
JavaScript code that works in most web browsers.  It's like a C compiler.

It allows you to write code like this, which is remedial in most other modern languages:

```javascript
// inside main.js
import address from "address";
import billing from "billing";

billing.some_function();
address.some_other_function();
```

Webpack allows you to specify that `main.js` is your main file, and that `main.js` might contain instructions for locating other files, which Webpack should do, recursively until all needed files have been located. All those files should then be brought together and translated into a single file, suitable for use in a web browser.

Surprisingly, `webpack -o bundle.js *.js` does not do this.  Because the JavaScript ecosystem favors monolithic, do-everything tools, Webpack, in fact, does everything (except what it doesn't—we'll get to that).  It's super flexible, which means it's hard to use, hard to understand, and hard to learn.

I'm going to try to correct that by starting from a very simple case, and building things up, one step at a time, until we have a reasonable development and production environment, while only adding configuration when **there is a problem that needs solving**.

## Webpack from First Principles

To install Webpack, you'll need Node, so [go install it][install-node] (you might want to [use a package manager][node-from-package]).  You'll need need a JavaScript library downloader, which used to be only NPM, but now you should use Yarn, so [go install it][install-yarn].

[install-node]: https://nodejs.org/en/download/
[node-from-package]: https://nodejs.org/en/download/package-manager/
[install-yarn]: https://yarnpkg.com/en/docs/install

Many tutorials and READMEs have you just install JavaScript packages willy-nilly.  We aren't going to do that.  We're going to
have a file to keep track of all the stuff our project needs.  That file is `package.json` and Yarn can create one for us.  This
allows us to recreate our system whenever we want without having to re-execute a bunch of commands.

!SH yarn -y init

This will create an empty `package.json` for us.  Now, let's install Webpack!

!SH{quiet} yarn add webpack

Holy moly is that a lot of stuff!  I find it anxiety-inducing to watch the sheer volume of code being downloaded, and often
wonder what problem *that* solves, but nevertheless, it should work.  There will be ASCII art.  There will be warnings that you
have to ignore.  But it should work, and you can verify it like so:

!SH $(yarn bin)/webpack --version

<aside class="sidebar">
<h1>What is <code>$(yarn bin)</code?</h1>
<p>
The `$(yarn bin)` bit is a shell invocation that knows where `yarn` has installed binaries (In UNIX shells `$(some_command)` runs `some_command` and puts its output on the command line—try `yarn bin` and you'll see what I mean).  In this case, the path is `node_modules/.bin`, which you don't want to ever have to type, but you definitely want to run things out of there. 
</p>
<p>
If you just start typing <code>yarn</code>, your system might have some older, more busted version of Webpack installed in a path outside your project, and you'll get strange failures.  Because the JavaScript ecosystem favors silent failures and obfuscated error messages, you need to take extra care to know what you are executing.  Thus, <code>$(yarn bin)</code>
</p>
</aside>

<aside class="pullquote">You've now taken your first step into a larger world, which is rife with version incompatibilities, masked or incorrect error messages, and inconsistent behavior.</aside>

You've now taken your first step into a larger world, which is rife with version incompatibilities, masked or incorrect error messages, and inconsistent behavior, all so you can try to make your life easier while using one of the worst programming languages ever designed!  Webpack is one of the least bad things you'll deal with.

With this out of the way, let's see Webpack actually do something.

## A Very Simple Project

As we mentioned above, the purpose of Webpack is to take lots of JavaScript modules and produce a bundle that works
in a browser, thus allowing you to write organized code.

In Webpack's parlance, the _entry_ is the file it will read to find all other files.  The _output_ is the bundle
that Webpack is creating and will be used in our browser.

Let's make a directory for our code called `js`:

!SH mkdir js

Now, we'll make our entry point in `js/index.js` like so:

!CREATE_FILE js/index.js
console.log("Hello from index.js!");
import address from './address';
import billing from './billing';

address.announce();
billing.announce();
!END CREATE_FILE

This is referencing two modules, address and billing.  We'll create both of those in `js/`.

This is `js/address.js`:

!CREATE_FILE js/address.js
console.log("Hello from address.js");
export default {
  announce: function() {
    console.log("Announcing address.js");
  }
}
!END CREATE_FILE

And this is `js/billing.js`:

!CREATE_FILE js/billing.js
console.log("Hello from billing.js");
export default {
  announce: function() {
    console.log("Announcing billing.js");
  }
}
!END CREATE_FILE

<aside class="sidebar">
<h1>What the heck are <code>import</code> and <code>export default</code>?</h1>
<p>
The whole reason we are using Webpack is because JavaScript has no way to compose source files or package code in any useful way.  A consequence of this is that there is also no syntax in the language to compose code or package files. Nope, not even something as dead simple as Ruby's <code>require</code> or C's <code>#include</code>. Node invented a way to do this now called CommonJS (though Node's is slightly different).  There is also one called Asynchronous Module Definition or AMD or RequireJS.  So, that's three ways to do it, none standard.
</p>
<p>
ES6 (or ES2015?) introduced a standard way of bringing in modules.  This is what we're using here, but of course it doesn't work in a browser which is why Webpack exists. Webpack translates our use of <code>import</code> and <code>export</code> so that things work in a browser.
</p>
<p>
This means we need a way to indicate what is being exported from a file.  That is done with the <code>export</code> keyword:
</p>
<pre><code class="javascript">export default {
  foo: function() {},
  bar: 42
}
</code></pre>
<p>
We are exporting <code>foo</code> and <code>bar</code>, which can be imported like so:
</p>
<pre><code class="javascript">import my_lib from './file'
my_lib.foo(); // calls the function foo above
my_lib.bar;   // 42
</code></pre>
</aside>

What we want is to produce a singe file called `bundle.js` that uses all this code.

We can do this without configuration per se, and just use CLI options:

!SH $(yarn bin)/webpack  --entry ./js/index.js  --output-filename=bundle.js

Now, let's load this in a browser.  Create `index.html` like so:

!CREATE_FILE index.html
<!DOCTYPE html>
<html>
  <head>
    <script src="bundle.js"></script>
  </head>
  <h1>Open the Web Inspector</h1>
</html>
!END CREATE_FILE

Open this in a browser, then open the JavaScript console.  You should see all our messages:

!DUMP_CONSOLE index.html

Ok then!  That was neat!

<aside class="sidebar">
<h1>What's in <code>bundle.js</code> anyway?</h1>
<p>
Beware.  Here be dragons!
</p>
<p>
As mentioned, Webpack makes <code>import</code> and <code>export</code> work.  It does this by creating a somewhat small JavaScript-based implementation of them, and translates the code in our various <code>.js</code> files such that it uses this <em>shim</em>.  If you look at <code>bundle.js</code> you can see it.  It's nasty—as all generated code is—but you can see your code somewhere near the bottom.
</p>
<p>
In this tiny example, the shim is larger than the code, but in a real application, this shim won't add much overhead to what you are making the user download.
</p>
</aside>

We don't want to be building our JavaScript bundle from an ever-increasingly-complex command-line invocation.  We also don't want the generated code being dumped in our root directory either, so let's set-up a tiny project structure to keep things organized.

Make `webpack.config.js` look like so:

!CREATE_FILE webpack.config.js
const path = require('path');

module.exports = {
  entry: './js/index.js',
  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: 'bundle.js'
  }
};
!END CREATE_FILE

This will do what we did before with Webpack, *except* it will place `bundle.js` inside `dist/` instead of the current directory.  This path must be absolute for reasons that are uninteresting and arbitrary.  To satisfy this unnecessary requirement, we use the Node module `path`, which has a function `resolve` which will take our intention to use `dist/` and specify the full path for Webpack.

Also, yes, this file is in the root directory of our project, which is unfortunate, but it'll make things easier
for us for the time being, so just get used to it and be glad it's not called `WebpackFile`.

With this configuration in place, we can run it like so:

!SH $(yarn bin)/webpack
!SH ls dist

Woot!

If we move our `index.html` into the newly-created `dist`:

!SH mv index.html dist

We can open that in a browser, open the JavaScript console, and see the same messages as before.

!DUMP_CONSOLE dist/index.html

The configuration file saves us some keystrokes, but even typing our `$(yarn bin)/webpack etc etc` is a bit cumbersome.  We'll use a handy feature of `package.json` to create an alias for running webpack so we can just type `yarn webpack`.

We'll add a `"scripts"` key to `package.json`:

!PACKAGE_JSON
{
  "scripts": {
    "webpack": "$(yarn bin)/webpack --config webpack.config.js --display-error-details"
  }
}
!END PACKAGE_JSON

Your entire `package.json` looks like so:

!SH cat package.json

And now:

!SH yarn webpack

This is slightly better than a shell alias, because you can check it into source control.

## Now What?

We're not even getting started—this was just an overview of what Webpack even is and why it exists.  I found it personally helpful to go through this so I could see a very minimal use-case and learn the basic concepts, namely `entry` and `output`.

And just think how much we can accomplish with just eight lines of configuration.  We can write JavaScript in a controlled way, putting code in files, and being organized.

So, what's next?

There's a lot we aren't doing, that we need to do on any real project, such as:

* Bringing in third-party libraries
* Writing and running unit-tests
* Packaging for production
* Using ES6/ES2015/ESWhatever features
* Managing CSS using SASS
* Dealing with Webfonts

These are all possible with Webpack and also happen to be intended use-cases, however it's extremely hard to figure out how to do these things without someone just showing you the magical configuration needed to make them happen.  

I don't like that.  Boilerplate is just as tedious as “magic” and is just as intention-unrevealing.  So, we're going to start
with a problem to solve, and figure out together how to solve that with Webpack.  There wil be digressions, yak shaving, and a
few bumps in the road, but we'll get there.

The two next obvious things we might want to do are using third party libraries and unit testing.  Since unit testing requires
third party libraries, let's tackle third party libraries first by creating a more realistic application and bringing in some
open source code to help write it.
