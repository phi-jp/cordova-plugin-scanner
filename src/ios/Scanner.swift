import Foundation
import AVFoundation

@objc(Scanner) class Scanner: CDVPlugin, AVCaptureDelegate {
    var avCapture: AVCapture! = nil
    var openCv: OpenCv! = nil
    var base64 = ""
    var capturedImage: UIImage! = nil
    var lastSendImage: UIImage! = nil
    var lastCallbackId:String! = nil
    var recordingFlag = false
    
    func capture(image: UIImage) {
        capturedImage = image
        let datas:NSData = UIImageJPEGRepresentation(capturedImage!, 0.5)! as NSData
        base64 = "data:image/jpeg;base64," + datas.base64EncodedString()
        
        avCapture.isCapturing = false
    }
    
    func sendLastImage(keepCallback: NSNumber) {
        lastSendImage = capturedImage
        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: base64 as String)
        result?.keepCallback = keepCallback
        commandDelegate.send(result, callbackId: lastCallbackId)
        avCapture.isCapturing = true
    }
    
    // 最初に呼ばれます
    override func pluginInitialize() {
        avCapture = AVCapture()
        initDevice()
        openCv = OpenCv()
    }
    
    func initDevice(_ command: CDVInvokedUrlCommand! = nil) {
        avCapture.initDevice()
        if avCapture.authorized {
            avCapture.delegate = self
            let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "authorized")
            
            if command != nil {
                self.commandDelegate.send(result, callbackId: command.callbackId)
            }
        }
        else {
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: {status in
                var result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "authorized")
                if status {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                        self.initDevice()
                    }
                }
                else {
                    result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "unauthorized")
                }
                if command != nil {
                    self.commandDelegate.send(result, callbackId: command.callbackId)
                }
                
            })
        }
    }
    
    func toSettings(_ command: CDVInvokedUrlCommand! = nil) {
        let settingUrl = URL(string: UIApplicationOpenSettingsURLString)
        UIApplication.shared.openURL(settingUrl!)
        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "open settings")
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }

    func start(_ command: CDVInvokedUrlCommand) {
        print("START!")
        
        avCapture.startRunning()
        avCapture.isCapturing = true
        recordingFlag = true
        
        if lastCallbackId != nil {
            sendLastImage(keepCallback: false)
        }
        lastCallbackId = command.callbackId
        startInterval()
    }
    func stop(_ command: CDVInvokedUrlCommand) {
        print("STOP!")
        
        avCapture.stopRunning()
        
        if lastCallbackId != nil {
            sendLastImage(keepCallback: false)
        }
        
        lastCallbackId = nil
        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: "stoped")
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }
    
    func scan(_ command: CDVInvokedUrlCommand) {
        print("SCAN!")
        
        let filteredImage = capturedImage//openCv.filter(capturedImage)
        //        let datas:NSData = UIImageJPEGRepresentation(filteredImage!, 0.5)! as NSData
        
        let datas:NSData = UIImagePNGRepresentation(filteredImage!)! as NSData
        base64 = "data:image/jpeg;base64," + datas.base64EncodedString()
        // 引数で何か渡されたら。
        var someArg = command.argument(at: 0);
        
        if (someArg != nil) {
            someArg = (someArg! as! String) + "+cordova!"
        }
        else {
            someArg = "OK"
        }
        
        // 結果を生成 (String)
        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: base64 as String)
        // 結果を生成 (ArrayBuffer)
//        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAsArrayBuffer: datas as Data!)
        
        // エラーを送る場合
        // let result = CDVPluginResult(status: CDVCommandStatus_Error, messageAs: "Error")

        // 文字列以外も送れます
        //  let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: self.getSomeDict())

        // 結果を送る
        self.commandDelegate.send(result, callbackId: command.callbackId)
    }
    
    func startInterval() {
        // 30 FPS
        DispatchQueue.main.asyncAfter(deadline: .now() + 1 / 30) {
            if self.lastCallbackId != nil && self.recordingFlag {
                if self.lastSendImage != self.capturedImage {
                    self.sendLastImage(keepCallback: true)
                }
                self.startInterval()
            }
        }
    }

}
