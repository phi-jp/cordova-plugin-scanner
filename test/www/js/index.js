
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
        drawRects(data.rects);
      };
      if (elm.dataset.isLoaded === 'no') {
        console.log('skip');
        return;
      }
      function drawRects(rects) {
        var canvas = document.getElementById('canvas');
        if (!canvas) {
          document.body.appendChild(canvas = document.createElement('canvas'));
          canvas.id = 'canvas';
        }
        var style = canvas.style;
        style.position = 'absolute';
        canvas.width = elm.naturalWidth;
        canvas.height = elm.naturalHeight;
        style.width = elm.offsetWidth + 'px';
        style.height = elm.offsetHeight + 'px';
        style.left = elm.offsetLeft + 'px';
        style.top = elm.offsetTop + 'px';
        var c = canvas.getContext('2d');
        
        c.clearRect(0, 0, canvas.width, canvas.height);
        if (!rects.length) {
          return;
        }
        c.fillStyle = 'rgba(0, 0, 255, 0.4)';
        rects.forEach(function(rect) {
          c.beginPath();
          c.moveTo(rect[0].x, rect[0].y);
          c.lineTo(rect[1].x, rect[1].y);
          c.lineTo(rect[2].x, rect[2].y);
          c.lineTo(rect[3].x, rect[3].y);
          c.closePath();
          c.fill();
        });

      }
      elm.src = data.base64;
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
