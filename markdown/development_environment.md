Let's take a moment here before we move on.

We can manage our JavaScript in a modular way, with separate files and everything.  We can easily
bring in third-party libraries to help us do our work, can write unit tests, and even go to production.  And we've only had to
write about 30 lines of configuration.  It would be nice if it were zero, but given the Culture of Configurability™ in
JavaScript-land, it's not bad!

But, we *do* have a broken development environment.  I'd like to talk about CSS, debugging, and other fancy things, but we gotta
fix what we broke first.

## Making Development Easy Without Breaking Production

The most basic requirement we have for development is to be able to run our app locally.  Just call me Captain Obvious.  We cannot run our app locally in its current state, but restoring it to the pre-production state means we can't go to production.  A common way to solve this is to branch our code or our configuration, based on what environment we are either running in, or building for.

<aside class="pullquote">Every difference between production and development is a chance for bugs to crop up</aside>

Every difference between production and development is a chance for bugs to crop up, so we want to keep the differences minimal
and share as much configuration as we can. In any case, make sure you have a way to easily check your production app to see that
it's correct and working.  Webpack cannot do that for you.

A common way to have alternate behavior or configuration in production is to observe an environment variable that your code can
use to figure out what environment it's in or being built for.  In Node/JavaScript land, that variable is `NODE_ENV` and in JavaScript, you
typically access it via `process.env.NODE_ENV`.

If it's `"production"`, we do one thing, if it's `"development"`, we do another.

Webpack will set this to `"production"` if you use `-p` on the command-line.  Given that, we could enhance our `index.html` to
check `NODE_ENV` and use the CDN or not, depending on the value:

!EDIT_FILE html/index.html <!-- -->
{
  "match": "    </section>",
  "insert_after": [
    "    <% if (process.env.NODE_ENV === 'production') { %>"
  ]
},
{
  "match": "    <% } %>",
  "insert_after": [
    "    <% } else { %>",
    "      <% for (var chunk in htmlWebpackPlugin.files.chunks) { %>",
    "        <script src=\"<%= htmlWebpackPlugin.files.chunks[chunk].entry %>\"></script>",
    "      <% } %>",
    "    <% } %>"
  ]
}
!END EDIT_FILE

Now, when we run `yarn webpack`, it generates our deveopment bundle:

!SH yarn webpack

!SH cat dist/index.html

To generate our production bundle, we pass `-p` to Webpack.  Since we're running Webpack via Yarn out of `package.json`, we have
to pass the special “stop checking command-line args” flag to yarn, which is two dashes (`--`), and *then*  we can pass our
Webpack-specific command-line flag:

!SH yarn webpack -- -p

Now, we can see that it's using our CDN:

!SH cat dist/index.html

We don't want to have to remember this, so let's put this into `package.json` as a script.

## Getting Fancy With `package.json` Scripts

We could just dupe our existing `webpack` script and tack a `-p` on the end, but then we have duplicate configuration, namely the
Webpack command-line arguments.  We can extract those to a configuration variable using the `config` section of `package.json`:

!PACKAGE_JSON
{
  "config": {
    "webpack_args": " --config webpack.config.js --display-error-details"
  }
}
!END PACKAGE_JSON

With that in place, we can modify our `scripts` section to use this new value:

!PACKAGE_JSON
{
  "scripts": {
    "webpack": "$(yarn bin)/webpack $npm_package_config_webpack_args",
    "prod": "$(yarn bin)/webpack  $npm_package_config_webpack_args -p",
    "karma": "$(yarn bin)/karma start spec/karma.conf.js --single-run"
  }
}
!END PACKAGE_JSON

Our entire `package.json` looks like so:

!SH cat package.json

Now, `yarn webpack` works as before, but `yarn prod` will generate our production bundle:

!SH yarn prod

We can't use `yarn production` because that has a special meaning to Yarn and generates this nonsense:

```
> yarn production
yarn production v0.20.3
error No command specified.
info Commands available from binary scripts: jasmine, karma, md2html, uglifyjs, webpack
info Project commands
   - production
      $(yarn bin)/webpack  $npm_package_config_webpack_args -p
   - webpack
      $(yarn bin)/webpack $npm_package_config_webpack_args
question Which command would you like to run?
```

I think I was clear on the command I wanted to run, but whatever.  `prod` is fine.

This more or less solves our immediate problem of not being able to develop.  Our workflow now is pretty straightforward:

1. Write some tests
2. Run our tests via `yarn karma`
3. Write some code
4. Watch our tests pass
5. Build our development bundle via `yarn webpack`
6. Open our app in a browser and see it working/do some exploratory testing.
7. Bundle for production via `yarn prod`
8. Send that code up to our CDN

Not too bad!

Note how absolutely minimal this all is.  You can get really far in life with just this simple workflow.  I'm not kidding at all.
We have the ability to do everything we *need* and have solved our most immediate problems, with *very little* configuration, and
with installing only *three development tools*: Webpack, Jasmine, and Karma.

Think about this the next time you open a blog post from Hacker News about someone's amazing front-end development setup.

That being said, we can do better.

## Improving Your Development Environment

There are a few things we're leaving out that you may want:

* *CSS.* We almost certainly need to manage CSS and likely want to use a third-party CSS framework.
* *Debugging.*  Our only mechanism for debugging is unit tests and `console.log`.  **Those are great debugging tools**, but we
might want to be able to see errors that reference our source code, not the bundle.
* *Ergonomics.* Building a UI sadly does involve a lot of “tweak and reload”, and in our current workflow, that means running
Webpack each time.  It's not super fast, and as our application gets more complex, Webpack will be slower and slower.  It would
be nice if that process could be faster.
* *A more sophisticated way of bundling for production.* The current mechanism just dumps everythning in `dist/`, where
`dist/index.html` is whatever you did last: `yarn webpack` or `yarn prod`.  Kinda gross.

Let's tackle each of these, starting with CSS, because there's just no way your project won't need CSS.


