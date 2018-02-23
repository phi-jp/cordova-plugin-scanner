import Foundation

@objc(Scanner) class Scanner: CDVPlugin, AVCaptureDelegate {
    var avCapture: AVCapture! = nil
    var openCv: OpenCv! = nil
    var base64 = ""
    var capturedImage: UIImage! = nil
    func capture(image: UIImage) {
        capturedImage = image
    }
    
    // 最初に呼ばれます
    override func pluginInitialize() {
        avCapture = AVCapture()
        openCv = OpenCv()
        avCapture.delegate = self
    }

    func start(_ command: CDVInvokedUrlCommand) {
        avCapture.startRunning()
        print("START!")
        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: base64 as String)
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }
    func stop(_ command: CDVInvokedUrlCommand) {
        print("STOP!")
        avCapture.stopRunning()
        
        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: base64 as String)
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }
    func scan(_ command: CDVInvokedUrlCommand) {
        print("SCAN!")
        
        let filteredImage = capturedImage//openCv.filter(capturedImage)
        let datas:NSData = UIImageJPEGRepresentation(filteredImage!, 0.5)! as NSData
        base64 = "data:image/jpeg;base64," + datas.base64EncodedString()
        // 引数で何か渡されたら。
        var someArg = command.argument(at: 0);
        
        if (someArg != nil) {
            someArg = (someArg! as! String) + "+cordova!"
        }
        else {
            someArg = "OK"
        }
        
        // 結果を生成
        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: base64 as String)
        
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
