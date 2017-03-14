/*
 * PhantomJS script to open up a page and print out whatever the JavaScript console prints.
 */
var page   = require('webpage').create();
var system = require('system');
var args   = system.args;

page.onConsoleMessage = function(msg) {
  console.log(msg);
};
if (args.length > 1) {
  args.forEach(function(arg, i) {
    if (i > 0) {
      page.open(arg, function () {
        phantom.exit();
      });
    }
  });
}
