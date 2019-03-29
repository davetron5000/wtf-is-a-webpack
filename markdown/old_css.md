

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
