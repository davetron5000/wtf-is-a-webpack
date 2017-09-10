We can write JavaScript code in modules and bring in third party libraries, and we can write unit tests.  That's pretty darn good for a language that doesn't suport literally any of that in any way.  Thank Zod for Webpack!

But, we need to go to production.  Code that's not live and solving user problems might as well not exist.

Given that our amazing Markdown previewer totally works statically in a browser on localhost, it's just a matter of dumping files up onto some server, right?

Not exactly.  It's true that *would* work, but for any reasonable application we're going to want a bit more. At the very least
we want to:

* minify/gzip/de-biggen the JavaScript we make the user download.
* create a unique name for our bundle so it works with CDNs, AKA "hashing".

Why?

## Minification Saves Time and Money

Our Markdown app is small now, but it could become the world's foremost way of rendering markdown in a browser.  We've got VC's knocking at our door, and we need to be web scale.

Uncompressed assets like JavaScript waste bandwidth.  The downstream user doesn't care about whitespace or
code comments, and we don't need to pay for bandwidth that's ferrying bytes that won't be used.  There's literally no reason to send uncompressed JavaScript to a user other than laziness (or, in our case, the lack of wherewithal to configure our awful toolchain to do it as part of our build pipeline).

If you aren't exactly sure what I mean, consider that this JavaScript works the same way as our existing `markdownPreviewer.js`:

```javascript
import{m}from "markdown";
var a=function(d,s,p){
return function(e){
var t=d.getElementById(i).value,
q=d.getElementById(p);
q.innerHTML=m.toHTML(t);
e.preventDefault();};}
```

This takes up less space than our version, but is terrible code.  We can use tools to turn our nice code into crappy but small code that works the same way.

This, plus the use of a content-delivery network will make our application performant and fast without a ton of effort.  To use a CDN, however, we need to be mindful about how we manage changes.

## Unique Names for Each Version of our `bundle.js`

If we deployed our code to a content delivery network (which we are likely going to want to do at some point), and we used the name `bundle.js` it will be pretty hard to update it.  Some CDNs don't let you update assets (meaning people would use the original version of `bundle.js` forever, never getting our updates or bugfixes), and others require you to wait for caches to expire, which can be hours or even days.  The standard practice to deal with this is that each new version of your code has a unique name.

So, we want to generate a file like `924giuwergoihq3rofdfg-bundle.js`, where `924giuwergoihq3rofdfg` changes each time our code changes.

This, along with minification, are basic needs for web development, and since Webpack is a monolithic system, we'd expect it to be able to do this for us.  Turns out, it can.

## Something Automatic!

Accoring to [Webpack's documentation](https://webpack.js.org/guides/production/), merely using the `-p`
option when invoking it will perform minification!  Wow!  Let's see if that's true.

First, let's see how big the bundle is:

!SH yarn webpack
!SH wc -c dist/bundle.js

Now, let's try `-p`.  To make sure Yarn doesn't think we're passing **it** `-p`, we use the UNIX special
switch that means “stop parsing command-line switches”, which is `--`:

!SH yarn webpack -- -p
!SH wc -c dist/bundle.js

Not bad!  One third the final size.  And without any configuration!

So, what did `-p` *actually* do?

It configures the `UglifyJsPlugin`, which uses [UglifyJS](http://lisperator.net/uglifyjs/) to minify our
code.  It also sets the `NODE_ENV` environment variable to "production", which allows us to configure
things only for production if we want.  And we will want.

Now, we need to create a hashed bundle to deal with a CDN.  Webpack calls this _caching_.

## Creating a Bundle for Long-Term CDN Caching

Creating a hashed filename is called [caching](https://webpack.js.org/guides/caching/), since the filename
allows us to put the bundle in a long-term cache.  Instead of having some sort of plugin to do this, it
turns out the the value of the string we give to the `filename` key of `output` isn't just an ordinary
string!  It's a second configuration format (yay) that allows us to put a hashed value into the filename.

We can set the value to `"[chunkhash]-bundle.js"`, like so:

!EDIT_FILE webpack.config.js /* */
{
  "match": "    filename:",
  "replace_with": [
    "    filename: '[chunkhash]-bundle.js'"
  ]
}
!END EDIT_FILE

And, it works!

!SH yarn webpack
!SH ls dist

This creates two new problems, however.  First, since the filename will now change whenever our code changes, we can't put a static reference to it into our `index.html` file.  The second problem, though, is that we don't want to do this step in development (note that we got a hashed filename without using the `-p` option).  Webpack's documentation warns us:

> Don’t use `[chunkhash]` in development since this will increase compilation time.

If you recall above, we mentioned that the `-p` option sets the value of `NODE_ENV` to "production".  You
should have every reason to believe that you can access that value inside your Webpack configuration to
create conditional, production-only configuration like so:

```javascript
output: {
  path: path.resolve(__dirname, "dist"),
  filename: process.env.NODE_ENV === "production" ? "[chunkhash]-bundle.js" : "bundle.js"
}
```

Sadly, you would be wrong.

The `-p` flag doesn't actually set an environment variable.  What it really does is to instruct Webpack to
replace code that looks like `process.env.NODE_ENV` _in the code Webpack is bundling_ with the value `"production"`, but **not in `webpack.config.js`**.  Sigh.

If you want to read a long an annoying tale of why this is, please check out [this Webpack issue](https://github.com/webpack/webpack/issues/2537).  Spoiler: there is no solution at the end.

Although it's nice that `-p` exists to do *something* for us for a production build, it's clearly
insufficient.  We've only come to our _second_ production requirement and it won't work.

If you read the docs more, it's clear where this is going - we need one configuration for dev and one for
production.  This is not uncommon amongst web application development tools, however it would nice if
Wepack just supported this directly, since `-p` is essentially unusable for any real project (if it doesn't work for a 10-line markdown processor, it doesn't work).

<aside class="pullquote">
We need one configuration for dev and one for production
</aside>

The good news is, after we set this up, configuring stuff for dev vs. prod will be much simpler.

The trick is to figure out how to avoid duplicating common configuration.  Webpack sort-of supports this
via the [webpack-merge](https://github.com/survivejs/webpack-merge) module, which can smartly merge two
Webpack configurations.

So, we'll need to create a common base configuration, and then one for dev-only and another for prod-only,
merging the proper one at compile time.

### Separating Production and Development Configuration

The way this works is that our main `webpack.config.js` will simply `require` an environment-specific
webpack configuration.  Those environment-specific ones will pull in a common Webpack configuration, then
using the `webpack-merge` module, overwrite or augment anything needed specific to those environments.

!GRAPHVIZ webpack_configs Managing Webpack configs for different environments
digraph webpack_configs {
  rankdir="TD"

  Shared[label="webpack/common.js" fontname="Courier" shape="tab"]
  Dev[label="webpack/dev.js" fontname="Courier" shape="tab"]
  Prod[label="webpack/production.js" fontname="Courier" shape="tab"]
  Main[label="webpack.config.js" fontname="Courier" shape="folder" style="bold"]
  Decision[label="environment?" shape="diamond"]

  Main -> Decision

  Decision -> Dev[label="dev" style="dotted"]
  Decision -> Prod[label="production" style="dotted"]
  Dev -> Shared[label="merge and override"]
  Prod -> Shared[label="merge and override"]

}
!END GRAPHVIZ

Our general requirements at this point are:

* No minifcation or hashing in development
* Minify **and** hash in production
* Output development files in a different location than production files (so we don't get confused about what's what).
* Avoid duplicatng coniguration if at-all possible.

Since we don't have much configuration now, this shouldn't be a problem.

First, install webpack-merge:

!SH yarn add webpack-merge

Now, to create our _four_ configuration files.  I'm willing to tolerate one configuration file at the
top-level, but not four.  So, we'll be putting the dev, production, and common in a new directory, called
`webpack`:

!SH mkdir -p webpack

Our top-level `webpack.config.js` will reference the environment-specific file in `webpack`:

!CREATE_FILE webpack.config.js
module.exports = function(env) {
  if (env === undefined) {
    env = "dev"
  }
  return require(`./webpack/${env}.js`)
}
!END CREATE_FILE

Where does that `env` come from?  It comes from us.  We'll need to pass `--env=dev` or `--env=production`
to webpack to tell it which env we're building for.  This is why we've defaulted it to `dev` so we don't have to type that nonsense every time.  The whole "environment for building" vs "runtime environment" is
confusing and arbitrary, but this is how it is.

<aside class="sidebar">
<h1>What is up with those backticks in <code>require</code>?</h1>
<p>
You may have noticed that the argument to <code>require</code> above is using backticks and not quotes.  You've also noticed that
the backticks contain the expression <code>${env}</code>.  This is a way of doing string interpolation that, while not supported
universally in all browsers and not part of ES5, it <em>is</em> available to us in our Webpack configurations.  The formal name
for this is <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Template_literals">template literals</a>.
</p>
</aside>

Next, we'll create `webpack/dev.js`.

This file will bring in a common Webpack config, and modify it for development.  This will look very similar
to our original `webpack.config.js`, but our output path is going to be `dev` instead of `dist`, so we don't get
confused about what files are what.

Also remember that since this file is in `webpack/` and we want to put files in `dev/` (not `webpack/dev`), we have to use `../dev`.

!CREATE_FILE webpack/dev.js
const path         = require('path');
const Merge        = require('webpack-merge');
const CommonConfig = require('./common.js');

module.exports = Merge(CommonConfig, {
  output: {
    path: path.join(__dirname, '../dev'),
    filename: 'bundle.js'
  }
});
!END CREATE_FILE

Now, we'll create our production configuration in `webpack/production.js`:

!CREATE_FILE webpack/production.js
const path         = require('path');
const Merge        = require('webpack-merge');
const CommonConfig = require('./common.js');

module.exports = Merge(CommonConfig, {
  output: {
    path: path.join(__dirname, '../production'),
    filename: '[chunkhash]-bundle.js'
  }
});
!END CREATE_FILE

Both files reference `common.js`, we create that next:

!CREATE_FILE webpack/common.js
module.exports = {
  entry: './js/index.js'
};
!END CREATE_FILE

One confusing thing that is confusing must be pointed out.  All of our calls to `require` use a path
_relative to the file `require` is called from_.  Further, when we call `path.join(__dirname,
    "../production")`, the `../` is because this call, too, is executed relative to the file it's executed
in.  **But**, our entry point is _relative to where Webpack is executed from_, which is to say, the root
directory.


Let that sink in.  As an exercise for later, decide for yourself if any of this is an example of a good
design decision.  Perhaps it's my fault for insisting I tuck away these silly files in `webpack/`, but I
find all of this unnecessarily arbitrary and confusing.

Anyway, we should be able to run webpack as  before:

!SH yarn webpack

This places our bundle in `dev`, so we'll need to move our HTML file there:

!SH cp dist/index.html dev/index.html

And now, our app should work as before.

!SCREENSHOT "Our app still works" dev/index.html still_working.png

Next, we can build for production:

!SH yarn webpack -- --env=production -p

!SH ls production

Which brings us to our second problem to solve (remember, this was just the _first_ one!), which is how
do we get our `index.html` to reference the file we just built.

### Accessing the Hashed Filename in our HTML

So far, our app doesn't need a server to do anything, but we now need something dynamic.  Rather than go
through *that* pain, let's hold what we've got, and get the generated filename into our HTML.

In the previous section, we copied our HTML around, and that's not good.  We're building a build system
here, and it shouldn't include us typing `cp`!

What we want is to treat our `index.html` as a rudimentary template, and include a reference to our bundle
in there at build time.  The [HtmlWebpackPlugin](https://github.com/jantimon/html-webpack-plugin) was
designed to do this!

First, install it:

!SH yarn add html-webpack-plugin

By default, this plugin will produce an `index.html` file from scratch that brings in our bundle.  Since we have particular markup that we need for our app, we need a way to specify a template.  `HtmlWebpackPlugin` allows us to specify one to use and, if it's just straight-up normal HTML, the plugin will insert the `<script>` tag in the right place.

Let's place that file in a new directory called `html`.  Note that we've omitted the `<script>` tag we had before.

!CREATE_FILE html/index.html
<!DOCTYPE html>
<html>
  <head>
    <!-- script tag is omitted - Webpack will provide -->
  </head>
  <body>
    <h1>Markdown Preview-o-tron 7000!</h1>
    <form id="editor">
      <textarea id="source" rows="10" cols="80"></textarea>
      <br>
      <input type="submit" value="Preview!">
    </form>
    <hr>
    <section id="preview">
    </section>
  </body>
</html>
!END CREATE_FILE

Now, we'll bring in the new plugin and configure it.  This is common to both production and development, so
we'll put this in `webpack/common.js`:

!EDIT_FILE webpack/common.js /* */
{
  "match": "module.exports = ",
  "replace_with": [
    "const HtmlPlugin     = require('html-webpack-plugin');",
    "",
    "module.exports = {",
    "  plugins: [",
    "    new HtmlPlugin({",
    "      template: \"./html/index.html\"",
    "    })",
    "  ],"
  ]
}
!END EDIT_FILE

Note again the arbitrary  nature of relative paths.  The `template` will be accessed from the directory
where we run Webpack, so it's just `./html`, and **not** `../html`.

Let's clean out the existing `dev` directory so we can be sure we did what we think we did:

!SH rm dev/*.*

Now, run Webpack

!SH yarn webpack

If you look at `dev/index.html`, you can see Webpack inserted a `<script>` tag (at the bottom, and messing up our indentation):

!SH cat dev/index.html

**And**, if you run this for production, it works as we'd like!

!SH yarn webpack -- -p --env=production
!SH cat production/index.html

Nice!

As a final step, let's modify `package.json` to handle the production build.

## Scripting the Production Build

Doing this the way we've seen will result in duplicating the command-line arguments common to webpack, so let's set that in [config section](https://docs.npmjs.com/files/package.json#config) of `package.json`.

!PACKAGE_JSON
{
  "config": {
    "webpack_args": " --config webpack.config.js --display-error-details"
  }
}
!END PACKAGE_JSON

Now, we can reference this configuration var by prefixing it with `$npm_package_config_` and save precious
keystrokes:

!PACKAGE_JSON
{
  "scripts": {
    "webpack": "webpack $npm_package_config_webpack_args",
    "prod": "webpack  $npm_package_config_webpack_args -p --env=production",
    "karma": "karma start spec/karma.conf.js --single-run --no-color"
  }
}
!END PACKAGE_JSON

And with that:

!SH yarn prod

(Note that we can't use "production" because it has some special meaning that generates an error that says
"no command specified" rather than, you know, telling us we can't use the reserved word "production")

The good thing about putting this in `"scripts"` , other than scripting away tedious stuff to have to type, is that we now have one command that means "make production happen".  As our application evolves, we can add more features behind the `prod` command.

This was a bit of a slog, but we now have a decent project structure, and can do useful and basic things
for development.

There's still room for improvement, but before we look at stuff like debugging and general ergonomics, we
should look at how to handle CSS, because our Markdown previewer really could use some pizazz, and the only
way to do that is CSS.
