CSS is great for writing term papers, not great for writing web apps, but it's what we've got, and we need to deal with it.

For our simple app, we *could* inline our CSS into the `<head>`, but the second we need another template, that ceases to work, and we'd like to manage CSS in separate files, the same as our JavaScript.

Webpack can totally handle this, even though it feels way outside its wheelhouse, since it's not JavaScript.  I'm not even sure *why* Webpack has features to support this, but it does, and it keeps us from having to find another tool to manage CSS.

We talked before about _plugins_, but we didn't talk about _loaders_.  Loaders are the fourth core concept in Webpack and they have to do with the way in which `import` behaves on files that aren't JavaScript.

First, let's write some CSS for our app so we have something real to work with.

## Styling our App

We're going to use a third-party CSS library later on, so let's use a light touch here.  Let's make our text a bit lighter, make the background a bit darker, but keep our `<textarea>` black on white.  We'll also change to one of those sans-serif fonts the kids like so much.

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

!EDIT_FILE html/index.html <!-- -->
{
  "match": "  <head>",
  "insert_after": [
    "    <link rel=\"stylesheet\" href=\"styles.css\">"
  ]
}
!END EDIT_FILE

Run Webpack:

!SH yarn webpack

And then manually copy our stylesheet into `dev/`:

!SH cp css/styles.css dev/

Now, our app looks a bit nicer:

!SCREENSHOT "Our app with some styling" dev/index.html styled_and_profiled.png

This has the same problems with `bundle.js`.  We want it minified and we want it hashed and we generally don't want to deal with it.  We know Webpack can do those things for JavaScript, and it can do them for CSS.

Surprisingly, we make this happen by importing our CSS into `js/index.js`!

## Loaders Can Load Anything

When you write an `import` statement, and Webpack compiles your code, it _loads_ the file referenced in the `import`.  By default, Webpack assumes that file is JavaScript and that you are trying to write modular code. Cool.

But, you can change that default, basically controlling Webpack's internal machinery to do things _other_ than create JavaScript bundles.  To do that, you tell Webpack to use a specific loader.

To load CSS, we'll install `css-loader`:

!SH yarn add css-loader -D

(This is an amazing amount of code to do what will ultimately be concatenating some CSS files together)

To use this loader, we'll add a new section to our Webpack configuration, called `module`.  This gives us a peek into how Webpack views itsef.  The `modules` section controls how Webpack treats different types of modules we might import.  This statement implies that there *are* types other than just JavaScript.  It's starting to make sense.

Inside `module:`, we create a `rules:` array, which will itemize out all the rules for handling modules that aren't JavaScript.  Each rule has a test, and a loader to use.  This goes in `webpack/common.js`, since we need it for dev and prod:

!EDIT_FILE webpack/common.js /* */
{
  "match": "  plugins: ",
  "insert_before": [
    "  module: {",
    "    rules: [",
    "      {",
    "        test: /\.css$/,",
    "        use: 'css-loader'",
    "      }",
    "    ]",
    "  },"
  ]
}
!END EDIT_FILE

With this in place, we can modify `js/index.js` to import our CSS:

!EDIT_FILE js/index.js /* */
{
  "match": "import",
  "insert_before": [
    "import \"../css/styles.css\";"
  ]
}
!END EDIT_FILE

Note that we're importing `"../css/styles.css"`, because imports that have dots in front of them are relative to the directory where the file being processed is located.

Let's clean up after our test so we can be sure what's happening:

!SH rm dev/*.*

Now, we can run Webpack:

!SH yarn webpack

If we open up `dev/index.html` in your browser, the CSS isn't being applied.  BUT, if you look inside the bundle `.js` file, you can see our CSS in there:

!SH grep textarea dev/bundle.js

There is a loader called the style-loader that would dynamically create a `<style>` tag in our DOM and put the CSS in there, but that's no good.  We want the browser to load CSS separately, so it can download both the CSS *and* the JS in parallel.

We need to tell Webpack that our CSS that gets loaded should be placed into a separate output file.  This can be done with the [MiniCssExtractPlugin](https://github.com/webpack-contrib/mini-css-extract-plugin).  It appears created to solve this specific problem.

!SH yarn add mini-css-extract-plugin  -D

`MiniCssExtractPlugin` provides the function `loader` which will create a custom loader that, when we also use `MiniCssExtractPlugin` as a _plugin_, will write out our CSS to a file.  We can even use the magic `"[chunkhash]"` inside the filename to get the hash in there!

Here's what our common Webpack configuration now looks like:

!EDIT_FILE webpack/common.js /* */
{
  "match": "const HtmlPlugin",
  "insert_after": [
    "const MiniCssExtractPlugin = require("mini-css-extract-plugin");"
  ]
},
{
  "match": "        use: 'css-loader'",
  "replace_with": [
    "        use: ["
    "          {"
    "            loader: MiniCssExtractPlugin.loader"
    "          },"
    "          'css-loader'",
    "        ]"
  ]
}
!END EDIT_FILE

We also need to tell `MiniCssExtractPlugin` what name to use.  Because we want this file hashed, the same as
our JavaScript, we'll need to specify some configuration in `webpack/dev.js` and `webpack/production.js`.
Here's what `webpack/dev.js` will look like

!EDIT_FILE webpack/dev.js /* */
{
  "match": "const CommonConfig",
  "insert_after": [
    "const MiniCssExtractPlugin = require("mini-css-extract-plugin");"
  ]
},
{
  "match": "  }",
  "replace_with": [
    "  },",
    "  plugins: [",
    "    new MiniCssExtractPlugin({ filename: 'styles.css' })",
    "  ]"
  ]
}
!END EDIT_FILE

And, for `production.js`:

!EDIT_FILE webpack/production.js /* */
{
  "match": "const CommonConfig",
  "insert_after": [
    "const MiniCssExtractPlugin = require("mini-css-extract-plugin");"
  ]
},
{
  "match": "  }",
  "replace_with": [
    "  },",
    "  plugins: [",
    "    new MiniCssExtractPlugin({ filename: '[chunkhash]-styles.css' })",
    "  ]"
  ]
}
!END EDIT_FILE

With this in place, we can remove the `<link>` tag we put in:

!EDIT_FILE html/index.html <!-- -->
{
  "match": "    <link rel=\"stylesheet\" href=\"styles.css\">",
  "replace_with": [
    "    <!-- css will be inserted by webpack -->"
  ]
}
!END EDIT_FILE

Now, when we run Webpack, our CSS file is being created separately and is available in `dev/`:

!SH yarn webpack
!SH ls dev/*.css
!SH cat dev/index.html

**And**, when we build for production, it uses the hashed name:

!SH yarn prod
!SH ls production/*.css
!SH cat production/index.html



Sure enough, if we open up either `dev/index.html` or `production/index.html`, the CSS is working:

!SCREENSHOT "Our app with CSS managed by Webpack" dev/index.html css_works.png

Nice!

And, since we're using `-p` for our production build, the CSS is being minified automatically.

Let's bring in a third-party CSS library to make sure that works as expected.

## Third-party CSS Libraries

I don't like writing CSS.  I *do* like using re-usable/functional CSS and not snowflake/“semantic” CSS, which is why we're going to use [Tachyons](http://tachyons.io/). If I were to write a “What problem does it solve?” for functional CSS like Tachyons, I'd just point you to [this article by Tachyons' author Adam Morse](http://mrmrs.github.io/writing/2016/03/24/scalable-css/), which explains it.

First, let's bring in tachyons:

!SH yarn add tachyons

(Refreshingly free of dependencies)

Much of the styling we've added is pretty simple stuff, so we'll let Tachyons handle all that for us. We'll leave the font setting in `css/styles.css` just to demonstrate that we can merge our styles with Tachyons'.  Replace all of `css/styles.css` with:

!CREATE_FILE css/styles.css
html {
  font-family: avenir next, avenir, helvetica, sans-serif;
}
!END CREATE_FILE

To bring in Tachyons to our CSS bundle we `import` it just like anything else:

!EDIT_FILE js/index.js /* */
{
  "match": "import",
  "insert_before": [
    "import \"tachyons\";"
  ]
}
!END EDIT_FILE

If you run Webpack now, you'll see the size of our CSS bundle increase, due to the inclusion of Tachyons.  But, let's actually use it so we can see it working.

We'll use some of Tachyons' styles on `<body>` to set the colors, as well as pad the UI a bit (since Tachyons includes a reset):

```html
<body class="dark-gray bg-light-gray ph4">
```

We'd like our text area to look a bit nicer, so let's set it to fill the width of the body, have a 30% black border, with a slight border radius, and a bit of padding inside:

```html
<textarea 
  id="source" 
  rows="10" 
  cols="80" 
  class="w-100 ba br2 pa2 b--black-30"></textarea>
```

We'd also like our preview button to be a bit fancier, so let's set that to be in a slightly washed-out green, and give it some padding and borders so it looks like a button.  We'll also set it to zoom on hover, so it feels like a real app:

```html
<input 
  type="submit" 
  value="Preview!" 
  class="grow pointer ba br3 bg-washed-green ph3 pv2">
```

(If you are incredulous at all this “mixing” of presentation and markup, please do read the linked article above.  Trust me, this way of writing CSS is *soooooo* much better than snowflaking every single thing.  But, this isn't the point.  The point is we are using third party CSS with Webpack.)

All told, our template looks like so:

!EDIT_FILE html/index.html <!-- -->
{
  "match": "  <body>",
  "replace_with": [
    "  <body class=\"dark-gray bg-light-gray ph4\">"
  ]
},
{
  "match": "      <textarea id=",
  "replace_with": [
"      <textarea",
"        id=\"source\"",
"        rows=\"10\"",
"        cols=\"80\"",
"        class=\"w-100 ba br2 pa2 b--black-30\"></textarea>"
  ]
},
{
  "match": "      <input type=\"submit\" value=\"Preview!\">",
  "replace_with": [
"      <input", 
"        type=\"submit\"", 
"        value=\"Preview!\"",
"        class=\"grow pointer ba br3 bg-washed-green ph3 pv2\">"
  ]
}
!END EDIT_FILE

OK, now we can run Webpack:

!SH rm dev/*.*
!SH yarn webpack

If we open up `dev/index.html`, we'll see our nicely styled app, courtesy of Tachyons!

!SCREENSHOT "Our app styled by Tachyons" dev/index.html styled_by_tachyons.png

Don't get too wrapped up in a) Tachyons or b) how we've styled our app  The point is that we can mix a third-party CSS framework, along with our own CSS, just like we are doing with JavaScript.  This demonstrates that Webpack is a full-fledged asset pipeline.

And *this* meets our needs as web developers.

But, our workflow is kinda slow, and we don't have sophisticated debugging tools available.  Let's look at that next.
