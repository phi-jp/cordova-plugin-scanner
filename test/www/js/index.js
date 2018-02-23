
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
    var now = Date.now();
    scanner.scan(function(data) {
      document.getElementById('time').textContent = Date.now() - now + 'ms';
      var elm = document.getElementById('img');
      elm.src = data;
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
  document.getElementById("video").onclick = function scan() {
    var now = Date.now();
    scanner.scan(function(data) {
      document.getElementById('time').textContent = Date.now() - now + 'ms';
      var elm = document.getElementById('img');
      elm.src = data;
      setTimeout(scan, 33);
    }, function() {
      alert('失敗');
    }, '');
  };

});
