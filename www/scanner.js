'use strict';

var exec = require('cordova/exec');

var Scanner = {
  scan: function(onSuccess, onFail, param) {
    //第３引数にクラス名、第４引数に使いたいメソッド名を指定
    return exec(onSuccess, onFail, 'Scanner', 'scan', [param]);
  },
  start: function(onSuccess, onFail, param) {
    //第３引数にクラス名、第４引数に使いたいメソッド名を指定
    return exec(onSuccess, onFail, 'Scanner', 'start', []);
  },
  stop: function(onSuccess, onFail, param) {
    //第３引数にクラス名、第４引数に使いたいメソッド名を指定
    return exec(onSuccess, onFail, 'Scanner', 'stop', []);
  },
};
module.exports = Scanner;