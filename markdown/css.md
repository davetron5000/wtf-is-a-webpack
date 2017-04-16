CSS is great for writing term papers, not great for writing web apps, but it's what we've got, and we need to deal with it.

For our simple app, we *could* inline our CSS into the `<head>`, but the second we need another template, that ceases to work,
and we'd like to manage CSS in separate files, the same as our JavaScript.

Webpack can totally handle this, even though it feels way outside its wheelhouse, since it's not JavaScript.  I'm not even sure
*why* Webpack has features to support this, but it does, and it prevents us finding another tool to do this.

We talked before about _plugins_, but we didn't talk about _loaders_.  Loaders are the fourth core concept in Webpack and they
have to do with the way in which `import` behaves on files that aren't JavaScript.

First, let's write some CSS for our app so we have something real to work with.

## Styling our App

We're going to use a third-party CSS library later on, so let's use a light touch here.  Let's make our text a bit lighter, make
the background a bit darker, but keep our `<textarea>` black on white.  We'll also change to one of those sans-serif fonts the kids like so much.

We'll put this in `css/styles.css`:

!CREATE_FILE css/styles.css
html {
  color: #111111;
  background-color: #EEEEEE;
  font-family: avenir next, avenir, helvetica, sans-serif;
}

textarea {
  color: black;
  background-color: white;
}
!END CREATE_FILE

We can now reference this in `html/index.html`:

!CREATE_FILE html/index.html
<!DOCTYPE html>
<html>
  <head>
    <link rel="stylesheet" href="styles.css">
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
    <% if (process.env.NODE_ENV === 'production') { %>
      <% for (var chunk in htmlWebpackPlugin.files.chunks) { %>
        <script src="//cdn.awesome/<%= htmlWebpackPlugin.files.chunks[chunk].entry %>"></script>
      <% } %>
    <% } else { %>
      <% for (var chunk in htmlWebpackPlugin.files.chunks) { %>
        <script src="<%= htmlWebpackPlugin.files.chunks[chunk].entry %>"></script>
      <% } %>
    <% } %>
  </body>
</html>
!END CREATE_FILE

Run Webpack:

!SH yarn webpack

And then manually copy our stylesheet into `dist/`:

!SH cp css/styles.css dist/

Now, our app looks a bit nicer:

!SCREENSHOT "Our app with some styling" dist/index.html styled_and_profiled.png

This has the same problems with `bundle.js`.  We want it minified and we want it hashed and we generally don't want to deal with
it.  We know Webpack can do those things for JavaScript, and it can do them for CSS.

Surprisingly, we make this happen by importing our CSS into `js/index.js`!

## Loaders Can Load Anything

When you write an `import` statement, and Webpack compiles your code, it _loads_ the file referenced in the `import`.  By
default, Webpack assumes that file is JavaScript and that you are trying to write modular code. Cool.

But, you can change that default, basically controlling Webpack's internal machinery to do things _other_ than create JavaScript
bundles.  To do that, you tell Webpack to use a specific loader.

To load CSS, we'll install `css-loader`:

!SH yarn add css-loader -D

(I still can't get over the sheer number of modules required to do this)

To use this loader, we'll add a new section to our Webpack configuration, called `modules`.  This gives us a peek into how Webpack
views itsef.  The `modules` section controls how Webpack treats different types of modules we might import.  This statement implies that there *are* types other than just JavaScript.  It's starting to make sense.

Inside `modules:`, we create a `rules:` array, which will itemize out all the rules for handling modules that aren't JavaScript.
Each rule has a test, and a loader to use:

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
  module: {
    rules: [
      {
        test: /\.css$/,
        use: 'css-loader'
      }
    ]
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

With this in place, we can modify `js/index.js` to import our CSS:

!CREATE_FILE js/index.js
import "../css/styles.css";
import markdownPreviewer from "./markdownPreviewer";

window.onload = function() {
  document.getElementById("editor").addEventListener(
      "submit",
      markdownPreviewer.attachPreviewer(
        document,    // pass in document
        "source",    // id of source textarea
        "preview")); // id of preview DOM element
};
!END CREATE_FILE

Note that we're importing `"../css/styles.css"`, because imports that have dots in front of them are relative to the directory
where the file being processed is located.

Let's clean up after our test so we can be sure what's happening:

!SH rm dist/*.*

Now, we can run Webpack:

!SH yarn webpack

If we open up `dist/index.html` our CSS isn't being applied.  BUT, if you look inside our bundle file, you can see our CSS in
there (it's hard to see because it's minified, but you can find a string that contains our CSS).

There is a loader called the style-loader that would dynamically create a `<style>` tag in our DOM and put the CSS in there, but
that's no good.  We want the browser to load it separately, so it can download both the CSS *and* the JS in parallel.

We need to tell Webpack that our CSS that gets loaded should be placed into a separate output file.  This can be done with the
[ExtractTextPlugin](https://webpack.js.org/plugins/extract-text-webpack-plugin/).  Despite it's generic name, it appears created
to solve this specific problem.

!SH yarn add extract-text-webpack-plugin  -D

`ExtractTextPlugin` provides the function `extract` which will create a custom loader that, when we use `ExtractTextPlugin` as a
_plugin_, will write out our CSS file.  We can even use the magic `"[chunkhash]"` inside the filename to get the hash in there!

Here's what our Webpack configuration now looks like:

!CREATE_FILE webpack.config.js
const path           = require('path');
const UglifyJSPlugin = require('uglifyjs-webpack-plugin');
const HtmlPlugin     = require('html-webpack-plugin');
const ExtractTextPlugin = require('extract-text-webpack-plugin');


module.exports = {
  entry: './js/index.js',
  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: '[chunkhash]-bundle.js'
  },
  module: {
    rules: [{
      test: /\.css$/,
      use: ExtractTextPlugin.extract({
        use: 'css-loader'
      })
    }]
  },
  plugins: [
    new UglifyJSPlugin(),
    new ExtractTextPlugin('[chunkhash]-styles.css'),
    new HtmlPlugin({
      inject: false,
      template: "html/index.html"
    })
  ]
};
!END CREATE_FILE

Now, when we run Webpack, our CSS file is being created separately and is available in `dist/`:

!SH yarn webpack
!SH ls dist/*.css

Cool.  But it's *still*  not being used in our HTML.  The `HtmlPlugin` we are using is capable of inserting the CSS into our
template.  To access our JavaScript files, we used the code `htmlWebpackPlugin.files.chunks[chunk].entry`.  I didn't explain what
that was or how I figured that out, so now is a good time.

When executing the template, `HtmlPlugin` makes the variable `htmlWebpackPlugin` available, and it has a structure like so:

```json
"htmlWebpackPlugin": {
  "files": {
    "css": [ "main.css" ],
    "js": [ "assets/head_bundle.js", "assets/main_bundle.js"],
    "chunks": {
      "head": {
        "entry": "assets/head_bundle.js",
        "css": [ "main.css" ]
      },
      "main": {
        "entry": "assets/main_bundle.js",
        "css": []
      },
    }
  }
}
```

We can see what's in `entry`: the JS output files.  Why this is called _entry_, when it's clearly vending the _output_ is a
mystery to me.  Nevertheless, we can see in the structure that alongside `entry`, we have `css`.  And, it turns out, this has the value of our hashed stylesheet, so we can use code just like we did to handle our JavaScript to handle our CSS (as well as checking `process.env.NODE_ENV` to know when to use our CDN):

!CREATE_FILE html/index.html
<!DOCTYPE html>
<html>
  <head>
    <% if (process.env.NODE_ENV === 'production') { %>
      <% for (var chunk in htmlWebpackPlugin.files.chunks) { %>
        <link rel="stylesheet" href="//cdn.awesome/<%= htmlWebpackPlugin.files.chunks[chunk].css %>"/>
      <% } %>
    <% } else { %>
      <% for (var chunk in htmlWebpackPlugin.files.chunks) { %>
        <link rel="stylesheet" href="<%= htmlWebpackPlugin.files.chunks[chunk].css %>" />
      <% } %>
    <% } %>
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
    <% if (process.env.NODE_ENV === 'production') { %>
      <% for (var chunk in htmlWebpackPlugin.files.chunks) { %>
        <script src="//cdn.awesome/<%= htmlWebpackPlugin.files.chunks[chunk].entry %>"></script>
      <% } %>
    <% } else { %>
      <% for (var chunk in htmlWebpackPlugin.files.chunks) { %>
        <script src="<%= htmlWebpackPlugin.files.chunks[chunk].entry %>"></script>
      <% } %>
    <% } %>
  </body>
</html>
!END CREATE_FILE

Now, for the moment of truth.  Let's again clear out `dist/` just to be sure what we are about to do has the right effect:

!SH rm dist/*.*

Now to run Webpack:

!SH yarn webpack

If we look at our `dist/index.html` file, we can see it's good, but the proof is in the pudding.  Open up `dist/index.html` in
your browser and prepare to be amazed:

!SCREENSHOT "Our app with CSS managed by Webpack" dist/index.html css_works.png

Nice!

We still aren't minifying our CSS, however.

## Minify CSS

Wepack loaders often take options, which `css-loader` does.  One of the options is `minimize:` which is documented to minify our
CSS (which not call it `minify:`?!).  Normaly, options are set inside the `use:` configuration like so:

```javascript
use : {
  loader: "css-loader",
  options: {
    minimize: true
  }
}
```

Since we are using `ExtractTextPlugin`, it's a bit different.  The way `ExtractTextPlugin` works is that its argument is of the
form the configuration expects if we weren't using it.  It's hard to explain.  Here's what you have to do:

```javascript
use: ExtractTextPlugin.extract({
  use: {
    loader: "css-loader",
    options: {
      minimize: true
    }
  }
})
```

The value for `use:` can just be a string—the name of the loader.  If we want to do anything else, such as configure it, we have
to use an object that has the key `loader` in it.  That's the form we're using inside `ExtractTextPlugin.extract` and is also why
the previous configuration of `use: "css-loader"` worked.  See, Webpack *does* have some ergonomics!

OK, this means our entire Webpack config looks like so:

!CREATE_FILE webpack.config.js
const path           = require('path');
const UglifyJSPlugin = require('uglifyjs-webpack-plugin');
const HtmlPlugin     = require('html-webpack-plugin');
const ExtractTextPlugin = require('extract-text-webpack-plugin');


module.exports = {
  entry: './js/index.js',
  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: '[chunkhash]-bundle.js'
  },
  module: {
    rules: [
      {
        test: /\.css$/,
        use: ExtractTextPlugin.extract({
          use: {
            loader: "css-loader",
            options: {
              minimize: true
            }
          }
        })
      }
    ]
  },
  plugins: [
    new UglifyJSPlugin(),
    new ExtractTextPlugin('[chunkhash]-styles.css'),
    new HtmlPlugin({
      inject: false,
      template: "html/index.html"
    })
  ]
};
!END CREATE_FILE

And *now*, we have minified CSS, with a hash, ready for our CDN.

But wait, what about third party CSS?  There is no reason to write our own when so many have given so much to keep us from having
to do it!

## Third-party CSS Libraries

I don't like writing CSS.  I *do* like using re-usable CSS and not snowflake CSS, which is why we're going to use [Tachyons](http://tachyons.io/). If I were to write a “What problem does it solve?” for single-purpose CSS like Tachyons, I'd just point you to [this article by Adam Morse](http://mrmrs.io/writing/2016/03/24/scalable-css/), which explains it.

First, let's bring in tachyons:

!SH yarn add tachyons

(Refreshingly free of dependencies)

Much of the styling we've added is pretty simple stuff, so we'll let Tachyons handle all that for us. We'll leave the font
setting in `css/styles.css` just to demonstrate that we can merge our styles with Tachyons'.  Replace all of `css/styles.css`
with:

!CREATE_FILE css/styles.css
html {
  font-family: avenir next, avenir, helvetica, sans-serif;
}
!END CREATE_FILE

To bring in Tachyons to our CSS bundle we `import` it just like anything else:

!CREATE_FILE js/index.js
import "tachyons";
import "../css/styles.css";
import markdownPreviewer from "./markdownPreviewer";

window.onload = function() {
  document.getElementById("editor").addEventListener(
      "submit",
      markdownPreviewer.attachPreviewer(
        document,    // pass in document
        "source",    // id of source textarea
        "preview")); // id of preview DOM element
};
!END CREATE_FILE

If you run Webpack now, you'll see the size of our CSS bundle increase, due to the inclusion of Tachyons.  But, let's actually
use it so we can see it working.

We'll use some of Tachyons' styles on `<body>` to set the colors, as well as pad the UI a bit (since Tachyons includes a reset):

```html
<body class="dark-gray bg-light-gray ph4">
```

We'd like our text area to look a bit nicer, so let's set it to fill the width of the body (800px, per `css/styles.css`), have a
30% black border, with a slight border radius, and a bit of padding inside:

```html
<textarea 
  id="source" 
  rows="10" 
  cols="80" 
  class="w-100 ba br2 pa2 b--black-30"></textarea>
```

We'd also like our preview button to be a bit fancier, so let's set that to be in a slightly washed-out green, and give it some
padding and borders so it looks like a button.  We'll also set it to zoom on hover, so it feels like a real app:

```html
<input 
  type="submit" 
  value="Preview!" 
  class="grow pointer ba br3 bg-washed-green ph3 pv2">
```

(If you are incredulous at all this “mixing” of presentation and markup, please do read the linked article above.  Trust me, this
 way of writing CSS is *soooooo* much better than snowflaking every single thing.  But, this isn't the point.  The point is we
 are using third party CSS with Webpack.)

All told, our template looks like so:

!CREATE_FILE html/index.html
<!DOCTYPE html>
<html>
  <head>
    <% if (process.env.NODE_ENV === 'production') { %>
      <% for (var chunk in htmlWebpackPlugin.files.chunks) { %>
        <link rel="stylesheet" href="//cdn.awesome/<%= htmlWebpackPlugin.files.chunks[chunk].css %>"/>
      <% } %>
    <% } else { %>
      <% for (var chunk in htmlWebpackPlugin.files.chunks) { %>
        <link rel="stylesheet" href="<%= htmlWebpackPlugin.files.chunks[chunk].css %>" />
      <% } %>
    <% } %>
  </head>
  <body class="dark-gray bg-light-gray ph4">
    <h1>Markdown Preview-o-tron 7000!</h1>
    <form id="editor">
      <textarea 
        id="source" 
        rows="10" 
        cols="80" 
        class="w-100 ba br2 pa2 b--black-30"></textarea>
      <br>
      <input 
        type="submit" 
        value="Preview!" 
        class="grow pointer ba br3 bg-washed-green ph3 pv2">
    </form>
    <hr>
    <section id="preview">
    </section>
    <% if (process.env.NODE_ENV === 'production') { %>
      <% for (var chunk in htmlWebpackPlugin.files.chunks) { %>
        <script src="//cdn.awesome/<%= htmlWebpackPlugin.files.chunks[chunk].entry %>"></script>
      <% } %>
    <% } else { %>
      <% for (var chunk in htmlWebpackPlugin.files.chunks) { %>
        <script src="<%= htmlWebpackPlugin.files.chunks[chunk].entry %>"></script>
      <% } %>
    <% } %>
  </body>
</html>
!END CREATE_FILE

OK, now we can run Webpack:

!SH rm dist/*.*
!SH yarn webpack

If we open up `dist/index.html`, we'll see our nicely styled app, courtesy of Tachyons!

!SCREENSHOT "Our app styled by Tachyons" dist/index.html styled_by_tachyons.png

Don't get too wrapped up in a) Tachyons or b) how we've styled our app  The point is that we can mix a third-party CSS framework,
along with our own CSS, just like we are doing with JavaScript.  This demonstrates that Webpack is a full-fledged asset pipeline.

And *this* meets our needs as web developers.

But, our workflow is kinda slow, and we don't have sophisticated debugging tools available.  Let's look at that next.
