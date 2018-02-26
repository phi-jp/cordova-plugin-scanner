'use strict';

var exec = require('cordova/exec');

var Scanner = {
  defineMethod: function(method) {
    //第３引数にクラス名、第４引数に使いたいメソッド名を指定
    this[method] = function(onSuccess, onFail, param) {
      return exec(onSuccess, onFail, 'Scanner', method, [param]);
    };
  },
};

[
  'scan',
  'start',
  'stop',
  'toSettings',
  'initDevice',
].forEach(function(method) {
  Scanner.defineMethod(method)
});
module.exports = Scanner;