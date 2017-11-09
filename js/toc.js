document.addEventListener("DOMContentLoaded", function(event) {
  var expanded = false;
    
  document.querySelectorAll("[data-show-hide]")[0].addEventListener("click", function(event) {
    event.preventDefault();
    if (expanded) {
      var nodes = document.querySelectorAll("[data-show='compressed']")
      for (var i = 0; i < nodes.length; i++) {
        nodes[i].style.display = nodes[0].dataset.display;
      }
      var nodes = document.querySelectorAll("[data-show='expanded']")
      for (var i = 0; i < nodes.length; i++) {
        nodes[i].style.display = "none";
      }
      expanded = false;
    }
    else {
      var nodes = document.querySelectorAll("[data-show='compressed']")
      for (var i = 0; i < nodes.length; i++) {
        nodes[i].style.display = "none";
      }
      var nodes = document.querySelectorAll("[data-show='expanded']")
      for (var i = 0; i < nodes.length; i++) {
        nodes[i].style.display = nodes[0].dataset.display;
      }
      expanded = true;
    }
  });
});

