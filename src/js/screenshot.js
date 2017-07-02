/*
 * PhantomJS script to take a screenshot
 */
var page   = require("webpage").create();
var system = require("system");
var args   = system.args;

page.onConsoleMessage = function(msg) {
  console.log(msg);
};

if (args.length < 3) {
  phantom.exit();
  throw "You should pass in the web page and the screenshot name";
}

var file = args[1];
var image = args[2];
var width = +(args[3] || 640);
var height = +(args[4] || 480);
var retinaFactor = 2;

page.open(file, function () {
  page.viewportSize = {
    width: width *  retinaFactor,
    height: height *  retinaFactor
  };
  page.evaluate(function() {
    // ::CUSTOM_CODE::
  });
  page.evaluate(function() {
    document.body.style.webkitTransform = "scale(2)";
    document.body.style.webkitTransformOrigin = "0% 0%";
    document.body.style.width = "50%";
  });
  page.render(image);
  phantom.exit();
});
