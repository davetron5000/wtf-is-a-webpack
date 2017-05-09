/*
 * PhantomJS script to open up a page and print out whatever the JavaScript console prints.
 */
var page   = require('webpage').create();
var system = require('system');
var args   = system.args;

page.onConsoleMessage = function(msg) {
  console.log(msg);
};
if (args.length < 1) {
  throw "You must supply the page to load";
}
var html = args[1];
page.open(html, function (status) {
  page.evaluate(function() {
    // ::CUSTOM_CODE::
  });
  setTimeout(function() { phantom.exit(); },200);
});
