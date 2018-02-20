import Foundation

@objc(Scanner) class Scanner: CDVPlugin {


    // 最初に呼ばれます
    override func pluginInitialize() {
    }


    func scan(_ command: CDVInvokedUrlCommand) {

        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "OK")

        // エラーを送る場合
        // let result = CDVPluginResult(status: CDVCommandStatus_Error, messageAs: "Error")

        // 文字列以外も送れます
        // let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: self.getSomeDict())

        self.commandDelegate.send(result, callbackId: command.callbackId)
    }


    private func getSomeDict() -> Dictionary<String, Any> {
        var data = ["name":nil, "age": nil] as [String : Any?]

        data.updateValue("simiraaaa", forKey: "name")
        data.updateValue("100000", forKey: "age")

        return data
    }
}