We can write JavaScript code in modules and bring in third party libraries, and we can write unit tests.  That's pretty darn good for a language that doesn't suport literally any of that in any way.  Thank  God for Webpack!

But.

We need go to production.  Code that's not live and solving user problems might as well not exist.

Given that our amazing Markdown previewer totally works statically in a browser on localhost, it's just a matter of dumping files up onto some server, right?

Not exactly.  It's true that *would* work, but for any reasonable application we're going to want a bit more. At the very least
we want to:

* minify/gzip/de-biggen the JavaScript we make the user download.
* create a unique name for our bundle so it works with CDNs, AKA "hashing".

Why?

## Minification is Good

Our Markdown app is small now, but it could become the world's foremost way of rendering markdown in a browser.  We've got VC's knocking at our door, and we need to be web scale.

In all seriousness, uncompressed assets like JavaScript waste bandwidth.  The downstream user doesn't care about whitespace or
code comments, and we don't need to pay for bandwidth that's ferrying bytes that won't be used.  There's literally no reason to
send uncompressed JavaScript to a user other than laziness (or, in our case, the lack of wherewithal to configure our awful
toolchain to do it as part of our build pipeline).

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

This takes up less space than our version, but is terrible code.  We can use tools to turn our nice code into crappy but small
code that works the same way.

This, plus the use of a content-delivery network will make our application performant and fast without a ton of effort.  To use a
CDN, however, we need to be mindful about how we manage changes.

## Unique Names for Each Version of our `bundle.js`

If we deployed our code to a content delivery network (which we are likely going to want to do at some point), and we used the name `bundle.js` it will be pretty hard to update it.  Some CDNs don't let you update assets (meaning people would use the original version of `bundle.js` forever, never getting our updates or bugfixes), and others require you to wait for caches to expire, which can be hours or even days.  The standard practice to deal with this is that each new version of your code has a unique name.

So, we want to generate a file like `924giuwergoihq3rofdfg-bundle.js`, where `924giuwergoihq3rofdfg` changes each time our code changes.

This, along with minification, are basic needs for web development, and since Webpack is a monolithic system, we'd expect it to
be able to do this for us.  Turns out, it can.

## Plugins and Loaders

Webpack is built on four basic concepts.  We've already discussed two of them: _entry points_ and _output_.  The other two are
_plugins_ and _loaders_, which affect Webpack's behavior in turning our entry points into outputs.

What we want to do is configure how Webpack produces `bundle.js`.  Reading about loaders leads us to believe they are a feature used to manipulate the entry points to Webpack, not the output (though this isn't technically true, it's true enough for now).

_Plugins_, on the other hand, seem generally flexible and, according to the documentation:

> perform… actions and custom functionality on “compilations” or “chunks” of your bundled modules

That sounds about right.  Going to the [plugins page](https://webpack.js.org/plugins/) on Webpack's website yields a few interesting things, namely `CompressionWebpackPlugin` and `HtmlWebpackPlugin`.  Nothing specifically about minification or hashing.

This is disappointing, because minification and hashing are pretty basic needs and Webpack is an all-inclusive system, or at
least designed to be.

Fortunately, I know that Uglify is a method of minifying JavaScript and a search for Uglify and Webpack yields what we want: the
[uglifyjs-webpack-plugin][uglify-webpack]

[uglify-webpack]: https://github.com/webpack-contrib/uglifyjs-webpack-plugin

And, **of course** the `uglifyjs-webpack-plugin` doesn't have a dependency on `uglify-js`, so we have to install both explicitly:

!SH yarn add uglify-js uglifyjs-webpack-plugin

And yes, they use different naming schemes, for reasons that give me pause as to the care taken in their implementations, but
whatever.  It will work.

Before setting it up, let's record the size of our bundle:

!SH wc -c dist/bundle.js

Now, we'll add a new `plugins:` key to `webpack.config.js` and create a new `UglifyJSPlugin` as well.  Our
entire configuration should look like so:

!CREATE_FILE webpack.config.js
const path           = require('path');
const UglifyJSPlugin = require('uglifyjs-webpack-plugin');

module.exports = {
  entry: './js/index.js',
  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: 'bundle.js'
  },
  plugins: [
    new UglifyJSPlugin()
  ]
};
!END CREATE_FILE

Now, we can re-run Webpack:

!SH yarn webpack

This should work, and our file size should be *way* smaller:

!SH wc -c dist/bundle.js

Nice!  If you open up `dist/index.html`, you should still the app working as before, but with almost a _third_ of
the filesize.  Feel the bandwidth savings!

Now, what about hashing the value?  There's actually two problems we have to deal with.  First is how to generate
the hash and use that as our filename.  The second is that we're bringing in `bundle.js` in our HTML file, and if
we have an ever-changing hash name, we'll need to change that and be able to easily keep it up to date.

Given the resources we've seen, there's no obvious way to do either of these things.  Let's return to the docs for
the `output:` key. Since that is where we've configured the name of our bundle, perhaps there's an option to help
us with the hash there?

Turns out, there is.  The value you give to `filename:` isn't just a string.  It's mini configuration-within-a-configuration that, fortunately, can achieve our goals.  According to the docs, we can use the magic string `"[chunkhash]"`.  Let's try it.

!CREATE_FILE webpack.config.js
const path           = require('path');
const UglifyJSPlugin = require('uglifyjs-webpack-plugin');
module.exports = {
  entry: './js/index.js',
  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: '[chunkhash]-bundle.js'
  },
  plugins: [
    new UglifyJSPlugin()
  ]
};
!END CREATE_FILE

Sure enough, this works:

!SH yarn webpack
!SH ls dist

OK, so how do we get that into our HTML file?  Remember `HtmlWebpackPlugin` from before?  That's how.

Let's install that plugin with Yarn:

!SH yarn add html-webpack-plugin

By default, this plugin will produce an `index.html` file that brings in our bundle.  Since we have particular
markup that we need for our app, we need a way to specify that.  `HtmlWebpackPlugin` allows us to specify a
template to use and, if it's just straight-up normal HTML, the plugin will insert the `<script>` tag in the right
place.

Let's place that file in a new directory called `html`.  Note that we've omitted the `<script>` tag we had before.

!CREATE_FILE html/index.html
<!DOCTYPE html>
<html>
  <head>
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

Now, we'll bring in the new plugin and configure it.  Here's our entire configuration file:

!CREATE_FILE webpack.config.js
const path           = require('path');
const UglifyJSPlugin = require('uglifyjs-webpack-plugin');
const HtmlPlugin     = require('html-webpack-plugin');

module.exports = {
  entry: './js/index.js',
  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: '[chunkhash]-bundle.js'
  },
  plugins: [
    new UglifyJSPlugin(),
    new HtmlPlugin({
      template: "html/index.html"
    }),
  ]
};
!END CREATE_FILE

Now, when we `yarn webpack`, our HTML file should be generated for us:

!SH yarn webpack

That works and our `dist/index.html` now references our hashed filename:

!SH cat dist/index.html

Nice!

What this means is that we can take the contents of `dist`, place it on our web server and serve it up. It also means that we now have the mechanism by which we can serve our JavaScript from a CDN and not worry about cache-busting or any of that.

But wait, we aren't referencing our CDN or don't see how to.  How *would* we do that?

99% of the time, you would not be having Webpack generate your HTML for you, but there's no reason Webpack can't handle this simple case for us.

If you dig into the documentation for html-webpack-templates, you'll find an [example template](https://github.com/jaketrent/html-webpack-template/blob/86f285d5c790a6c15263f5cc50fd666d51f974fd/index.html) that demonstrates how to make our `index.html` *actually* a template.  You'll also see that there's a configuration option called `inject` that we can set to false to prevent the plugin from automatically inserting `<script>` tag.

Let's set that option in `webpack.config.js`:

!CREATE_FILE webpack.config.js
const path           = require('path');
const UglifyJSPlugin = require('uglifyjs-webpack-plugin');
const HtmlPlugin     = require('html-webpack-plugin');

module.exports = {
  entry: './js/index.js',
  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: '[chunkhash]-bundle.js'
  },
  plugins: [
    new UglifyJSPlugin(),
    new HtmlPlugin({
      inject: false,
      template: "html/index.html"
    }),
  ]
};
!END CREATE_FILE

We can now use [EJS](http://www.embeddedjs.com) in our `html/index.html` to pull out the file.  It's a bit weird because Webpack supports mulitple output files (which it called _chunks_) so we have to iterate over those, even though in our case it's just one file.

!CREATE_FILE html/index.html
<!DOCTYPE html>
<html>
  <head>
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
    <% for (var chunk in htmlWebpackPlugin.files.chunks) { %>
      <script src="//cdn.awesome/<%= htmlWebpackPlugin.files.chunks[chunk].entry %>"></script>
    <% } %>
  </body>
</html>
!END CREATE_FILE

When we run `yarn webpack`, it all works and you can see that it properly uses our CDN to serve the file.

!SH yarn webpack

Of course, this creates a *new* problem.  We can't develop locally without getting that file up to our CDN.  That's
not acceptable.

That leads us to the next thing to tackle - improving our development environment.
