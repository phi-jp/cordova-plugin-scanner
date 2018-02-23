
// for cordova
document.addEventListener('deviceready', function() {
  if (!window.cordova) {
    return;
  }
  document.getElementById("start").onclick = function() {

    scanner.start(function(data) {
      // window.alert('');
    }, function() {
      alert('失敗');
    });
  
  };
  document.getElementById("scan").onclick = function() {
    scanner.scan(function(data) {
      var elm = document.createElement('pre');
      elm.textContent = data;
      document.body.appendChild(elm);
    }, function() {
      alert('失敗');
    }, '');
  };
  document.getElementById("stop").onclick = function() {
    scanner.stop(function(data) {
      // window.alert('');
    }, function() {
      alert('失敗');
    });
  };
});
