
// for cordova
document.addEventListener('deviceready', function() {
  if (!window.cordova) {
    return;
  }
  var initScanner = function(resolve) {
    // 永遠に許可を促す
    scanner.initDevice(function() {
      resolve && resolve();
    }, function() {
      if (confirm('このアプリを使用するためには、設定画面でカメラを許可してください')) {
        scanner.toSettings();
      }
      else {
        initScanner(resolve);
      }
    });
  };
  var scannerInit = new Promise(initScanner);
  document.addEventListener('resume', function() {
    scannerInit = new Promise(initScanner);
    scannerInit.then(function() {
      scannerInit = Promise.resolve(scanner);
    });
  });

  document.getElementById("start").onclick = function() {
    var now = Date.now();
    scanner.start(function(data) {
      document.getElementById('time').textContent = Date.now() - now + 'ms';
      now = Date.now();
      var elm = document.getElementById('img');
      elm.dataset.isLoaded = '';
      elm.onload = function() {
        elm.dataset.isLoaded = 'ok';
      };
      if (elm.dataset.isLoaded === 'no') {
        console.log('skip');
        return;
      }
      elm.src = data;
      elm.dataset.isLoaded = 'no';
    }, function() {
      alert('失敗');
    });
  };

  // document.getElementById("scan").onclick = function() {
  //   var now = Date.now();
  //   scanner.scan(function(data) {
  //     // console.log(data)
  //     document.getElementById('time').textContent = Date.now() - now + 'ms';
  //     // var elm = document.getElementById('img');
  //     // elm.src = data;
  //   }, function() {
  //     alert('失敗');
  //   }, '');
  // };
  
  document.getElementById("stop").onclick = function() {
    scanner.stop(function(data) {
      console.log(data);
    }, function() {
      alert('失敗');
    });
  };

});
