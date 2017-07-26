Everything you've read up to now was learned by me as I was writing this.  I didn't start this with *any* of the information in
here.  I was surprised at how counter-intuitive each step ended up being—I can totally see why there are so many blog posts
describing how to set it up.  From a test runner that can't run tests, to a system that supports presets, but includes none of
them, I was faced with many choices along the way, but also faced with completely opaque systems whose behavior and failure modes
were unpredictable.

Nevertheless, we got it all working and the amount of configuration wasn't that bad.  Still, each step felt like a battle, because the tools weren't designed to interoperate, each with its own ecosystem of plugins, and nothing exposed how it was working.

I also don't like aimless criticism without alternatives.  This final page is about that, and it's going to be about _interoperability_ and _developer ergonimics_.

## Interoperabilty

Two pieces of software interoperate when they can work together to solve a larger problem that neither can solve on their own. We
saw this time and time again in our journey.  We saw that Jasmine provided a library to write tests, but lacked the ability to load and execute our code.  Karma could load our code, but provides no way to write tests.  Webpack provides the ability to load CSS, but only with the  `ExtractTextPlugin` could we write it to a file.

Webpack and Karma's interoperability is completely opaque to the user.  This means that you have *no* way to know how the tools
are working or even observe them working together without debugging into the source code.  As a tool developer, the situation is difficult, because everything is very custom.  In Webpack's case, each type of integration is different.  To write your own loader, you [implement a nebulous interface](https://webpack.js.org/development/how-to-write-a-loader/).  Writing a plugin is [highly complex](https://webpack.js.org/development/how-to-write-a-plugin/).  Any tool that must be a part of Webpack or Karma, must have a plugin for each.

The JavaScript ecosystem is rife with this sort of opaque interoperability.  Each tool has its own created-from-first-principles plugin system.  This leads to meta-plugins like [gulp-grunt](https://www.npmjs.com/package/gulp-grunt) that allows plugins written for Gulp to be used in Grunt (or vice versa—it doesn't matter).

As a plugin or tool developer, no lessons learned working with one tool can be applied to another.  Worse, though, is for users
of these tools.  Because the behavior of these tools is totally opaque, and any extension points must be explicitly provided by
the tool creator, it's difficult to figure out how to use them solve the problem in front of you.  Most people resort to just
being told the answer, because figuring it out is difficult.

<aside class="pullquote">No lessons learned working with one tool can be applied to another</aside>

To make matters more confusing, tools often provide built-in functions for some common things, but not others.  In Webpack, we
can configure source maps without a plugin, we can configure minification with a built-in plugin, but we cannot process CSS
without a manually-installed loader.  And then there's Karma, which, as mentioned, is a test runner that cannot run tests by
default.

These tools all seem to be confused about their scope.  Are they small, single-purpose tools, or monolithic integrated systems?
They are almost all hybrids.  They attempt to be extensible, but in opaque, inconsistent, or undocumented ways, while also being monolithic, but with terrible _developer erogonomics_.

## Developer Ergonomics

[_Ergonomics_](https://www.merriam-webster.com/dictionary/ergonomics) is “an applied science concerned with designing and arranging things people use so that the people and things interact most efficiently and safely”.

If we apply this to software development, what are _efficiency_ and _safety_?  Efficiency can apply to three things:

* Ease of getting started
* Ease of working with the tool
* Ease of upkeep of the tool

[Ruby on Rails](http://rubyonrails.org) has great efficiency for getting started: `rails new my_blog`, and you have a website.
Tachyons, which we saw earlier, has great efficiency when working with it—each class it provides is dead simple and obvious in
its behavior, with no interdependencies.  [RSpec](https://rspec.info) is an example of a tool with amazing ergonomics around
upkeep.  They created major breaking changes going from version 2 to 3, but provided a tool called `transpec` that would fix all
the breaking changes for you in a one-time pass.

What about safety?  In software tools, safety means how easy it is to do the correct thing, or how hard it is to do the wrong
thing or break your environment. [Django's schema migrations](https://docs.djangoproject.com/en/1.11/topics/migrations/) is an
example of ergonomic safety—it automatically adds foreign key constraints to your database (which, if you aren't familiar, is
a simple and accepted way to ensure your database has correct data in it).

Thinking back on the tools we've used, have any of them been particularly ergonomic?  Even our most basic need for Webpack to
compile two files doesn't work without specifying a lot of complex command-line parameters.  When we introduced ES2015 to our
tests, we lost source maps (not that they worked in PhantomJS in the first place).  If you'll recall setting up CSS, the default
behavior of using the css loader was to put all the CSS into a string which didn't get rendered anywhere.

There are countless boilerplate starter packs for JavaScript, and they all suffer some form of ergonomic failure.  They might get
you started, but break down as you update dependencies.  I believe it is because of poorly-designed interoperability that these tools cannot be made that ergonomic.

## What's a Better Way?

There are two approaches to making ergonomic, interoperable systems.  The first is creating many single-purpose tools that have
an open and common means of interoperating.  I'll call this the “UNIX Way”, because this is how most UNIX systems are designed.
The second approach is to have a tightly integrated monolithic system that sacrifices flexibility for ergonomics, providing a
complete end-to-end experience for a complete use case.  I'll call this the “Rails Way”, because Ruby on Rails popularized this
approach (often called _opinionated software_).

I hope it's obvious that Webpack and friends don't fit either of these categories.  Neither provides an end-to-end solution, but
neither is special purpose and focused enough to integrate into an arbitrary workflkow.

Let's explore how we might solve our problems with tools designed around either of these approaches.

### The UNIX Way

The UNIX way is to have many small single-purpose tools that interoperate openly and transparently.  For example, if you want to
search a file for a string, you'd use `grep`.  `grep` outputs lines that match a string.  If you then want to extract data from
those lines, you'd use `cut` or `sed`.  What you _wouldn't_ do is add a feature to `grep` that does this.  And you _definitely_ would not add a plugin system to `grep`, because it already has one via text.

UNIX command-line tools'  plugin system is text: each line is a record, and all tools operate on lines of text.  The creator of
`sort` did not have to think about how one might determine the most frequently-repeated line in a file; instead they just needed
to allow sorting by numbers.  `cut` and `uniq` can take care of the rest.

Another simple means of interoperation is a _file_.  We've seen this countless times in our journey, where we have source files
that are processed to produce output files.  This sort of pipeline has existed for decades.  C compilers work this way, with each
tool taking one format as input, and producing another as output.  C source code is pre-processed to execute all the `#if` and
`#include` statements.  This processed source is compiled down to assembly, into what is called an _object file_.  Several object
files are then collected and linked together to produce a final executable.

Each file output by one part of the pipeline feeds the next.

!GRAPHVIZ cc C Compiler Build Pipeline
digraph c_toolchain {
  OneH [ label="src/foo.h" ]
  One  [ label="src/foo.c" ]
  Two  [ label="src/main.c" ]
  OneP [ label="pp/foo.c" ]
  TwoP [ label="pp/main.c" ]
  OneO [ label="out/foo.o" ]
  TwoO [ label="out/main.o" ]
  Exe  [ label="main" ]
  cpp  [ shape="rect" ]
  cc  [ shape="rect" ]
  ld  [ shape="rect" ]

  One  -> cpp
  cpp -> OneP
  OneH -> cpp
  Two  -> cpp -> TwoP

  OneP -> cc -> OneO
  TwoP -> cc -> TwoO

  OneO -> ld
  TwoO -> ld
  ld -> Exe
}
!END GRAPHVIZ

Each tool, `cpp`, `cc`, and `ld` do one thing and one thing only.  When C++ was being developed, an early version of the language
was created by replace `cpp` with a different program that pre-processed a C++ file and produced a C file:

!GRAPHVIZ cpp C++ Compiler Build Pipeline
digraph cpp_toolchain {
  OneH [ label="src/foo.h" ]
  One  [ label="src/foo.cxx" ]
  Two  [ label="src/main.cxx" ]
  OneP [ label="pp/foo.c" ]
  TwoP [ label="pp/main.c" ]
  OneO [ label="out/foo.o" ]
  TwoO [ label="out/main.o" ]
  Exe  [ label="main" ]
  cpp  [ shape="rect", label="c++" ]
  cc  [ shape="rect" ]
  ld  [ shape="rect" ]

  One  -> cpp
  cpp -> OneP
  OneH -> cpp
  Two  -> cpp -> TwoP

  OneP -> cc -> OneO
  TwoP -> cc -> TwoO

  OneO -> ld
  TwoO -> ld
  ld -> Exe
}

!END GRAPHVIZ

The `cc` program didn't need a plugin system because it interoperated in a clean and transparent way.  In fact, the designers of
`cc` didn't have to be consulted in order to try out C++.

What's more of a benefit to this approach is that each of these tools can be more easily maintained because they do fewer things.
The maintainers of `ld` only need to be worry about taking in object files and producing an executable.  It doesn't need to worry
about the intricacies of the C language. Conversely, the compiler, `cc` doesn't have to worry about how to create executable
files.  Being separate _applications_ means that integration points must be well-defined, forcing good design.

When you look at this ancient toolchain above, you should see a lot of analogs to our modern JavaScript-based setup.  Imagine if
each step was its own program:

!GRAPHVIZ js Imagined JS build pipeline
digraph js_toolchain {

  Preview     [ label="js/markdownPreviewer.js"]
  MD          [ label="node_modules/markdown/index.js"]
  LocalBundle [ label="work/bundle.js" ]
  Main        [ label="js/index.js"]
  CSS         [ label="css/styles.css" ]
  TY          [ label="node_modules/tachyons/index.css" ]
  HTML        [ label="html/index.html"]

  BundleJS [label="bundle_js" shape="rect"]
  PackJS   [label="pack_js" shape="rect"]
  PackCSS   [label="pack_css" shape="rect"]
  PackHTML   [label="pack_html" shape="rect"]

  Bundle    [ label="site/bundle.js" ]
  CSSBundle [ label="site/css.css" ]
  Index     [ label="site/index.html"]

  Preview     -> BundleJS
  Main        -> BundleJS
  BundleJS -> LocalBundle

  LocalBundle -> PackJS
  MD          -> PackJS
  PackJS -> Bundle

  CSS         -> PackCSS
  TY          -> PackCSS
  PackCSS -> CSSBundle

  HTML        -> PackHTML
  CSSBundle   -> PackHTML
  Bundle      -> PackHTML
  PackHTML -> Index
}

!END GRAPHVIZ

None of these tools exist, but imagine how they might work and what they might do:

* `bundle_js` takes JS code we've written, and follows local `import` statements to produce a file called the local bundle.  This
file still has imports for third party libraries.
* `pack_js` brings in those third party libraries to create our final bundle
* `pack_css` does the same thing with CSS
* `pack_html` takes an HTML template as input, as well as a CSS and JS bundle, and produces a shippable `.html` files we can
serve up.

Think back to the various problems we were solving.  If we want to write ES2015 instead of regular JavaScript, we just need a compiler that takes ES2015 as input and produces JavaScript as output.

!GRAPHVIZ js2015 Adding ES2015 Support to JS Build Pipeline
digraph es6_toolchain {

  PreviewSrc  [ label="es6/markdownPreviewer.es6"]
  Preview     [ label="js/markdownPreviewer.js"]
  MD          [ label="node_modules/markdown/index.js"]
  LocalBundle [ label="work/bundle.js" ]
  MainSrc     [ label="js/index.es6"]
  Main        [ label="es6/index.js"]
  CSS         [ label="css/styles.css" ]
  TY          [ label="node_modules/tachyons/index.css" ]
  HTML        [ label="html/index.html"]

  BundleJS [label="bundle_js" shape="rect"]
  PackJS   [label="pack_js" shape="rect"]
  PackCSS   [label="pack_css" shape="rect"]
  PackHTML   [label="pack_html" shape="rect"]
  ES6   [label="es2015c" shape="rect"]

  Bundle    [ label="site/bundle.js" ]
  CSSBundle [ label="site/css.css" ]
  Index     [ label="site/index.html"]

  PreviewSrc  -> ES6
  MainSrc     -> ES6
  ES6 -> Preview
  ES6 -> Main
  Preview     -> BundleJS
  Main        -> BundleJS
  BundleJS -> LocalBundle

  LocalBundle -> PackJS
  MD          -> PackJS
  PackJS -> Bundle

  CSS         -> PackCSS
  TY          -> PackCSS
  PackCSS -> CSSBundle

  HTML        -> PackHTML
  CSSBundle   -> PackHTML
  Bundle      -> PackHTML
  PackHTML -> Index
}
!END GRAPHVIZ

Notice how almost nothing upstream changed—we simply fed generated input to the toolchain from the output of another tool, and
that tool's function is dead simple - turn ES2015 into vanilla JS.

Think about how we added support for ES2015 with Webpack. We inserted something inside Webpack's configuration and had to make a
similar (but different) change to our testing setup.  In the UNIX world, it's much simpler:

!GRAPHVIZ jstest Adding testing support to JS Build Pipeline
digraph js_toolchain {

  PreviewSrc  [ label="es6/markdownPreviewer.es6"]
  Preview     [ label="js/markdownPreviewer.js"]
  MD          [ label="node_modules/markdown/index.js"]
  LocalBundle [ label="work/bundle.js" ]
  MainSrc     [ label="js/index.es6"]
  Main        [ label="es6/index.js"]
  CSS         [ label="css/styles.css" ]
  TY          [ label="node_modules/tachyons/index.css" ]
  HTML        [ label="html/index.html"]
  Tests [label="spec/markdownPreviewer.spec.js" penwidth=2]

  BundleJS [label="bundle_js" shape="rect"]
  PackJS   [label="pack_js" shape="rect"]
  PackCSS   [label="pack_css" shape="rect"]
  PackHTML   [label="pack_html" shape="rect"]
  ES6   [label="es2015c" shape="rect"]
  ES62  [label="es2015c" shape="rect"]
  TestRun [label="testrun" shape="rect" penwidth=2]
  Results [label="Test Results" shape="note" penwidth=2]

  Bundle    [ label="site/bundle.js" ]
  CSSBundle [ label="site/css.css" ]
  Index     [ label="site/index.html"]

  PreviewSrc  -> ES6
  MainSrc     -> ES6
  ES6 -> Preview
  ES6 -> Main
  Preview     -> BundleJS
  Main        -> BundleJS
  BundleJS -> LocalBundle

  LocalBundle -> TestRun[ penwidth=2]
  Tests -> ES62[ penwidth=2 ]
  ES62 -> TestRun[ penwidth=2]

  TestRun -> Results

  LocalBundle -> PackJS
  MD          -> PackJS
  PackJS -> Bundle

  CSS         -> PackCSS
  TY          -> PackCSS
  PackCSS -> CSSBundle

  HTML        -> PackHTML
  CSSBundle   -> PackHTML
  Bundle      -> PackHTML
  PackHTML -> Index
}
!END GRAPHVIZ

Notice again that we don't change that much. Notice that we can remove ES2015, and the entire downstream
toolchain still works properly.  You can start to imagine how we might extend this.  Source Maps could be produced by another
tool and consumed by `pack_html`.  Minification could be added later in the toolchain.

As a tool developer, this is much simpler - you take files as input, and produce files as output.  The file types are your
contract. The scope of any one tool is also small, meaning its easier to understand and maintain.  You avoid all sorts of weird
interactions because the contract between steps is well-defined and simple.

As a developer, this is also much easier to understand. Each thing feeds the next in an obvious way. If one part of the toolchain is buggy, it's immediately obvious which one, **and** you have an artifact it produced to share with the developers to figure out what went wrong—you don't have to put your entire project up on GitHub.

There are other benefits to this approach.  For example, there's no need to recompile CSS if JS has changed.  There's no need to
minify JS if just running tests.  By smartly managing the dependencies, our build pipeline can be fast, but also transparent.

Of course, you would need something to orchestrate this pipeline, but there are many many tools that do this already, including the venerable `make`. This additionally separates concerns by isolating small bits of functionality.  The orchestration system only has to worry about orchestration and not what is being orchestrated.

The main downside to the Unix Way is that you must cobble together your own toolchain every time (of course, this is how it is in JS-land already, but you *don't* get the benefits of small, self-contained tools).  You also have to make a lot of uninteresting decisions, such as where files should go.

The counter to this, which addresses this specific tradeoff, is to do the things The Rails Way.

### The Rails Way

The Rails Way is to provide a tightly integrated, end-to-end solution that has little flexibility, but produces a highly
ergonomic result.  You don't have to (or get to) choose the location of files.  You don't have to (or get to) decide what
processes what.  Anything you should do, you get for free and can't easily opt-out.

For example, we discussed minifying and hash-ing files for production.  In a Rails Way setup, that is configured for you and just
happens.  Webpack's  `-p` is kinda like this, but still requires you to decide to use it.  The more stuff is included and set up, the easier it is to get started.  And because all of the parts are tightly integrated, they can capitalize on this.

For example, it might be that all files must export exactly one class.  The downstream test-running subsystem can take advantage
of this and know this, simplifying its job by making assumptions about conventions.  This also enables ergonomic tooling to be
created.  We could decide that all files in `js/foo/Bar.js` are tested by `spec/foo/Bar.spec.js`.  We could include a script that
makes a new class:

```
> new_class foo/Blah
js/foo/Blah.js created
spec/foo/Blah.spec.js created
```

And, because the integrated system would choose your test framework for you, you just need to write your code.

Suppose the system we set up worked this way?  What would that look like?

```
> wp new markdown-previewer
js/index.es6 created
js/markdownPreviewer.es6 created
html/index.html created
css/styles.css created
spec/markdownPreviewer.spec.es6 created
> wp serve # index.es6 compiled, 
           # shoved into index.html 
           # with styles.css and 
           # avalable on port 8080
           # Stuff also recompiles as it changes

> wp test  # runs all the tests
```

Many existing boilerplates work like this, but the difference here is:

```
> ls config
ls: config: No such file or directory
```

Other behind-the-scenes stuff that would happen in such a system:

* source maps in dev mode, appropriate for dev mode
* source maps for prod mode
* minification, gzip, hashing, all set up for prod
* test running automatically set up with no configuration
* Source is ES2015 by default
* `package.json` created sensibly

The benefits to such a framework are many:

* Because the framework is integrated, and not cobbling together existing tools (as most JS boilerplates do), it can be tested,
  designed, and evolved as one unit.  No oddball interactions from disparate dev teams working on incompatible tools.
* Developers can go from 0 to running code in no time, with guarantees that everything works.  Remember how we essentially had to
install and set up everything twice, once for Webpack and once for Karma?
* You can immediately start writing code and don't have to make decisions about where files should go or what sort of configuration you need.
* Every project using this framework has the same shape, meaning you can jump into existing projects with a lot of context learned
from the last one. Things learned from one project apply to the next.

The downsides are flexibility.  If the defaults that are set up don't work for your use-case, it's hard to change them. This also
suffers the same problem as Webpack when there are internal failures—they are opaque and essentially impossible to debug.  But,
because the end-to-end system is designed together, by one team, this is less likely to happen.

Webpack, Karma, Babel, etc. are all a hybrid of these two approaches.  They have all of the downsides and few of the upsides.
Each new project is a snowflake that must be hand-crafted.  Each minor update to underlying libraries has a high chance of
breaking things, because nothing was designed to interoperate in a good way, nor designed together.  You also have a pretty high
bar to getting a workable setup going—look how long it took us, and we aren't even using a front-end view framework like React or
Angular.  Trust me, it's even worse as you add those libraries.

## Where To Go From Here?

I believe the reason the JS ecosystem is like this is because it is an amalgam of many back-end ecosystem and framework cultures.
Some developers believe very strongly in the UNIX way and eschew the Rails Way aggressively.  Others are the opposite.  There are
many more in between, so no way of designing these tools will satisfy everyone, but *everyone* ends up in the JS ecosystem,
because no matter what your back-end technology, you are very likely to need to serve up a web page.  And that means CSS and JS.

For me, the UNIX Way is the approach this ecosystem should take.  The flexibility and maintainability allow the community to be
agile with respect to workflows and best practices.  It seems highly unlikely that any focused group or individual could create a
universally applicable Rails Way of working with JS.  The UNIX Way also satisfies all the boilerplate fans and would result in an
ecosystem where many could contribute, and tools would be easy to understand.

Take these lessons with you as you design software.  If you aren't committed to developer or user ergonomics, if you aren't
committed to making a fully integrated system that “just works”, design your system around small, single-function tools that have
a clear means of interoperation.  You can always bring them together, but you can never tear them apart.
