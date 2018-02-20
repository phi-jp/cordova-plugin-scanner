
// for cordova
document.addEventListener('deviceready', function() {
  document.getElementById("button").onclick = function() {
    if (window.cordova) {
      scanner.scan(function(data) {
        window.alert(JSON.stringify(data));
      }, function() {}, 'foooo');
    }
  };
});
