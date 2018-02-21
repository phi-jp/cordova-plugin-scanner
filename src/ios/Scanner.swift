import Foundation

@objc(Scanner) class Scanner: CDVPlugin {

    // 最初に呼ばれます
    override func pluginInitialize() {
    }


    func scan(_ command: CDVInvokedUrlCommand) {
        
        // 引数で何か渡されたら。
        var someArg = command.argument(at: 0);
        
        if (someArg != nil) {
            someArg = (someArg! as! String) + "+cordova!"
        }
        else {
            someArg = "OK"
        }
        
        // 結果を生成
        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: OpenCVWrapper.openCVVersionString() as! String)
        
        // エラーを送る場合
        // let result = CDVPluginResult(status: CDVCommandStatus_Error, messageAs: "Error")

        // 文字列以外も送れます
        //  let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: self.getSomeDict())

        // 結果を送る
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }


    private func getSomeDict() -> Dictionary<String, Any> {
        var data = ["name":nil, "age": nil] as [String : Any?]

        data.updateValue("simiraaaa", forKey: "name")
        data.updateValue("100000", forKey: "age")

        return data
    }
}
