/*
 * PhantomJS script to take a screenshot
 */
var page   = require('webpage').create();
var system = require('system');
var args   = system.args;

page.onConsoleMessage = function(msg) {
  console.log(msg);
};
if (args.length > 2) {
  page.open(args[1], function () {
    page.clipRect = {
      top: 0,
      left: 0,
      width: 640,
      height: 480
    };
    page.viewportSize = {
      width: 640,
      height: 480
    };
    page.evaluate(function() {
      var e = document.createEvent('Event'); 
      document.getElementById('source').value = "# This is a test\n\n* of\n* some\n* _markdown_"; 
      e.initEvent('submit',true,true); 
      document.getElementById('editor').dispatchEvent(e);
    });
    page.render(args[2]);
    phantom.exit();
  });
}
else {
  phantom.exit();
  throw "You should pass in the web page and the screenshot name"
}
