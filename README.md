# cordova-plugin-scanner

## test

```
$ cd test
$ cordova platform add ios --nosave --nofetch
$ cordova plugin add --link ../
$ cordova build ios
$ cordova emulate ios
```

## 今できること
現状では、`test/www/js/index.js`に記載されているコードのような感じで動くのみとなります.

paramsの値を変えると、コールバック引数の中身も変わっているかと思います。

```js
Scanner.scan(function(data) {
  //success
  window.alert(JSON.stringify(data));
}, function() {
  //error
}, 'params');

```