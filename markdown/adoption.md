You might think from my tone and generic sarcasm I would not ever use Webpack in real life.  While Webpack's design doesn't fit
my mental model of how I think a tool like this should work, it's ubiquity is clear, and that counts for a great deal.  Ruby on Rails bundles Webpack and most modern JavaScript toolchains are going to include Webpack.  It's a fact of life.

So, given that Webpack and its ecosystem are fairly unstable, what are we to do?

It's common advice to not test your framework; to write your applications as if your underlying tools are working.  Within the
JavaScript ecosystem, that is not quite true.  And to make it worse, the failure modes are often unclear—recall we couldn't get a
reliable stack trace without some configuration.

What I would recommend each team do is maintain a very simple baseline application that simply uses the features of Webpack that
your main application uses.  Design this “canary” app for minimal features, but a clear way of demonstrating that the Webpack
configuration and plugins are working as desired.  For example, make sure that your production bundle is smaller in size than
your development bundle.

This book and the app we've built is a great example.  It's so minimal that you can share the entire thing with others to
demonstrate what's not working.  It contains no proprietary information and the source code is minimal, so anyone can understand
it quickly.

I highly recommend you set this up on your team.  That way, when you update Webpack, Babel, or one of its underlying plugins and
something breaks in your main app, you have a simplified app to demonstrate the problem and get help.  As we've mentioned,
Webpack seems to favor speed of development and new features over stability.  There is nothing wrong with this
tradeoff, but it does mean you are more likely to find bugs.  Having a simplified app to demonstrate them can help the
Webpack team fix bugs.  You're using Webpack for free, so it only seems fair to help them understand how their software is
working.

And with that, we are done.  Thanks for reading!
