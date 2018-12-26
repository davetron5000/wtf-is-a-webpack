We can write JavaScript code in modules and bring in third party libraries, and we can write unit tests.  That's pretty darn good for a language that doesn't support literally any of that in any way.  Thank Zod for Webpack!

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

This, along with minification, are basic needs for web development, and since Webpack is a monolithic system, we'd expect it to be able to do this for us.  Turns out, it can, and we can save some configuration by using the production _mode_.

## Webpack Modes

In our existing Webpack configuration, we saw the `mode` key, and it's set to `"none"`.  Per [Webpack's mode documentation](https://webpack.js.org/concepts/mode/), this disables all optimizations.

Looking at the documentation for what Webpack does when you set the mode to either `"development"` or `"production"`, it says
that it configures different plugins.  Webpack's internals are built on plugins, and presumably there is some internal pipeline
where these plugins are applied to the code from the entry points and produce the output bundle.

Most of the plugins are either entirely undocumented or documented for Webpack *developers*, as opposed to what we are: Webpack
users.

While the thought of a production mode that configures all the stuff we need automatically is nice, Webpack hasn't built much
trust here, and I'm pretty uneasy using a bunch of undocumented plugins, even if they *are* recommended by the Webpack
developers.  Stuff like [NoEmitOnErrorsPlugin](https://webpack.js.org/configuration/optimization/#optimization-noemitonerrors) seem dangerous—why would you want your build tool to swallow errors an exit zero if something went wrong?

Let's not opt into any of this and add configuration explicitly so we know what's going on.  We'll leave the `mode` key as
`"none"` for now.

We're back where we started, still needing minification and bundle hashing.  Let's start with minification.

## Minifying with the `TerserWebpackPlugin`

One of the plugins included by default in production mode is the
[`TerserWebpackPlugin`](https://webpack.js.org/plugins/terser-webpack-plugin/), which is documented as so:

> This plugin uses terser to minify your JavaScript.

[Terser](https://github.com/terser-js/terser) is a JavaScript minifier, so this sounds like what we want.

Before we set it up, let's check the size of our bundle before we minify it:

!SH yarn webpack

!SH wc -c dist/bundle.js

We'll compare this value to the bundle size after we set up minification.

While we could install the plugin and configure it directly, Webpack allows us to use it without being so explicit.  In this
case, we can set the `minimize` key to `true` in the `optimization` key.

We haven't seen the `optimization` key before, and if you look at the documentation for production mode, it shows a lot of
options being set in there.

For our needs, setting [`optimization` to true](https://webpack.js.org/configuration/optimization/#optimization-minimize) will
configure the `TerserWebpackPlugin` for us, so let's try it.

Your `webpack.config.js` should look like so:

!EDIT_FILE webpack.config.js /* */
{
  "match": "  mode: \"none\"",
  "insert_before": [
    "  optimization: {",
    "    minimize: true",
    "  },"
  ]
}
!END EDIT_FILE

Now, when we run Webpack, we should see our bundle side get much smaller.

!SH yarn webpack

!SH wc -c dist/bundle.js

Voila!  On my machine, this reduced the file size by about two-thirds.  Not too bad.

## Creating a Bundle for Long-Term CDN Caching

Creating a hashed filename is called [caching](https://webpack.js.org/guides/caching/), since the filename
allows us to put the bundle in a long-term cache.  Instead of having some sort of plugin to do this, it
turns out the value of the string we give to the `filename` key of `output` isn't just an ordinary
string!  It's a second configuration format (yay) that allows us to put a hashed value into the filename.

We can set the value to `"bundle-[contenthash].js"`, like so:

!EDIT_FILE webpack.config.js /* */
{
  "match": "    filename:",
  "replace_with": [
    "    filename: 'bundle-[contenthash].js'"
  ]
}
!END EDIT_FILE

Let's remove the existing bundle:

!SH rm dist/bundle.js

Now, let's re-run webpack and see what happens:

!SH yarn webpack

!SH ls dist

Nice!  We can minify and hash the filename for long term caching, but this creates a few new problems.  First, since the filename
of our bundle changes every time its contents change, we can't reference it in a static HTML file.  The second problem is that we
likely don't want to doing either minification or hashing when doing local development.

Let's tackle the second problem first and split up our configuration.

## Separating Production and Development Configuration

The way this works is that our main `webpack.config.js` will simply `require` an environment-specific
webpack configuration.  Those environment-specific ones will pull in a common Webpack configuration, then
using the `webpack-merge` module, overwrite or augment anything needed specific to those environments.

!GRAPHVIZ webpack_configs Managing Webpack configs for different environments
digraph webpack_configs {
  rankdir="TD"

  Shared[label="config/webpack.common.config.js" fontname="Courier" shape="tab"]
  Dev[label="config/webpack.dev.config.js" fontname="Courier" shape="tab"]
  Prod[label="config/webpack.production.config.js" fontname="Courier" shape="tab"]
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

* No minification or hashing in development
* Minify **and** hash in production
* Output development files in a different location than production files (so we don't get confused about what's what).
* Avoid duplicating configuration if at-all possible.

Since we don't have much configuration now, this shouldn't be a problem.

First, install webpack-merge:

!SH yarn add webpack-merge

Now, to create our _four_ configuration files.  I'm willing to tolerate one configuration file at the
top-level, but not four.  So, we'll be putting the dev, production, and common in a new directory, called
`config`:

!SH mkdir -p config

Our top-level `webpack.config.js` will reference the environment-specific file in `webpack`:

!CREATE_FILE webpack.config.js
module.exports = function(env) {
  if (env === undefined) {
    env = "dev"
  }
  return require(`./config/webpack.${env}.config.js`)
}
!END CREATE_FILE

Where does that `env` come from?  It comes from us.  We'll need to pass `--env=dev` or `--env=production`
to webpack to tell it which env we're building for.  This is why we've defaulted it to `dev` so we don't have to type that nonsense every time.

<aside class="sidebar">
<h1>What is up with those backticks in <code>require</code>?</h1>
<p>
You may have noticed that the argument to <code>require</code> above is using backticks and not quotes.  You've also noticed that
the backticks contain the expression <code>${env}</code>.  This is a way of doing string interpolation that, while not supported
universally in all browsers and not part of ES5, it <em>is</em> available to us in our Webpack configurations.  The formal name
for this is <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Template_literals">template literals</a>.
</p>
</aside>

Next, we'll create `config/webpack.dev.config.js`.

This file will bring in a common Webpack config, and modify it for development.  This will look very similar
to our original `webpack.config.js`, but our output path is going to be `dev` instead of `dist`, so we don't get
confused about what files are what.

Also remember that since this file is in `config/` and we want to put files in `dev/` (not `config/dev`), we have to use `../dev`.

!CREATE_FILE config/webpack.dev.config.js
const path         = require('path');
const Merge        = require('webpack-merge');
const CommonConfig = require('./webpack.common.config.js');

module.exports = Merge(CommonConfig, {
  output: {
    path: path.join(__dirname, '../dev'),
    filename: 'bundle.js'
  }
});
!END CREATE_FILE

Now, we'll create our production configuration in `config/webpack.production.config.js`:

!CREATE_FILE config/webpack.production.config.js
const path         = require('path');
const Merge        = require('webpack-merge');
const CommonConfig = require('./webpack.common.config.js');

module.exports = Merge(CommonConfig, {
  output: {
    path: path.join(__dirname, '../production'),
    filename: 'bundle-[contenthash].js'
  },
  optimization: {
    minimize: true
  }
});
!END CREATE_FILE

Both files reference `webpack.common.config.js`, we create that next:

!CREATE_FILE config/webpack.common.config.js
module.exports = {
  entry: './js/index.js',
  mode: 'none'
};
!END CREATE_FILE

One confusing thing that is confusing must be pointed out.  All of our calls to `require` use a path
_relative to the file `require` is called from_.  Further, when we call `path.join(__dirname,
    "../production")`, the `../` is because this call, too, is executed relative to the file it's executed
in.  **But**, our entry point is _relative to where Webpack is executed from_, which is to say, the root
directory.

Let that sink in.  As an exercise for later, decide for yourself if any of this is an example of a good
design decision.  Perhaps it's my fault for insisting I tuck away these silly files in `config/`, but I
find all of this unnecessarily arbitrary and confusing.

Anyway, we should be able to run webpack as  before:

!SH yarn webpack

This places our bundle in `dev`, so we'll need to move our HTML file there:

!SH cp dist/index.html dev/index.html

And now, our app should work as before.

!DO_AND_SCREENSHOT "Our app rendering markdown still works" dev/index.html still_working.png
var e = document.createEvent('Event'); 
document.getElementById('source').value = "# This is a test\n\n* of\n* some\n* _markdown_"; 
e.initEvent('submit',true,true); 
document.getElementById('editor').dispatchEvent(e);
!END DO_AND_SCREENSHOT

To build for production, we need to pass the `--env=production` flag to Webpack.  We'll want a Node script to do that, and we'll
also want to consolidate the arguments to Webpack to avoid duplication.  First, we'll add a `config` section, like so:

!PACKAGE_JSON
{
  "config": {
    "webpack_args": " --config webpack.config.js --display-error-details"
  }
}
!END PACKAGE_JSON

We can now use these to create a new task, `webpack:production`, that mirrors our existing `webpack` task, but also passes in
`--env=production`:

!PACKAGE_JSON
{
  "scripts": {
    "webpack": "webpack $npm_package_config_webpack_args",
    "webpack:production": "webpack $npm_package_config_webpack_args --env=production",
    "webpack:test": "webpack --config test/webpack.test.config.js --display-error-details",
    "jest": "jest test/bundle.test.js",
    "test": "yarn webpack:test && yarn jest"
  }
}
!END PACKAGE_JSON

With this in place, we can run `yarn webpack:production` to produce the production bundle:

!SH yarn webpack:production

We can see the production bundle in the `production/` directory:

!SH ls production

That solves one of our problems, now for the second problem: how do we reference this file in our HTML file, given that it's name
will change over time?

## Accessing the Hashed Filename in our HTML

In a more sophisticated application, we would have a web server render our HTML and that server could produce dynamic HTML that
includes our bundle name. Setting that up is a huge digression, so let's try to treat our HTML file as a template that we fill in
with the bundle name for our production build.

The [HtmlWebpackPlugin](https://github.com/jantimon/html-webpack-plugin) was designed to do this!

First, install it (note we have to use master here since a Webpack 5-compatible version hasn't been released yet):

!SH yarn add https://github.com/jantimon/html-webpack-plugin

By default, this plugin will produce an `index.html` file from scratch that brings in our bundle.  Since we have particular markup that we need for our app, we need a way to specify a template.  `HtmlWebpackPlugin` allows us to specify one to use and, if it's just straight-up, normal HTML, the plugin will insert the `<script>` tag in the right place.

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
we'll put this in `config/webpack.common.config.js`:

!EDIT_FILE config/webpack.common.config.js /* */
{
  "match": "module.exports = ",
  "replace_with": [
    "const HtmlPlugin = require(\"html-webpack-plugin\");",
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

Note again the arbitrary nature of relative paths.  The `template` will be accessed from the directory
where we run Webpack, so it's just `./html`, and **not** `../html`.

Let's clean out the existing `dev` directory so we can be sure we did what we think we did:

!SH rm dev/*.*

Now, run Webpack

!SH yarn webpack

If you look at `dev/index.html`, you can see Webpack inserted a `<script>` tag (at the bottom, and messing up our indentation):

!SH cat dev/index.html

**And**, if you run this for production, it works as we'd like!

!SH yarn webpack:production
!SH cat production/index.html

Nice!  And, we can see that the production app works:

!DO_AND_SCREENSHOT "Production version still works" dev/index.html prod_working.png
var e = document.createEvent('Event'); 
document.getElementById('source').value = "# This is a test\n\n* of\n* some\n* _markdown_"; 
e.initEvent('submit',true,true); 
document.getElementById('editor').dispatchEvent(e);
!END DO_AND_SCREENSHOT

This was a bit of a slog, but we now have a decent project structure, and can do useful and basic things
for development.

There's still room for improvement, but before we look at stuff like debugging and general ergonomics, we
should look at how to handle CSS, because our Markdown previewer really could use some pizazz, and the only
way to do that is CSS.
