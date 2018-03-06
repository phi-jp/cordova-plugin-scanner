import Foundation
import AVFoundation

@objc(Scanner) class Scanner: CDVPlugin, AVCaptureDelegate {
    var avCapture: AVCapture! = nil
    var openCv: OpenCV! = nil
    var base64 = ""
    var capturedImage: UIImage! = nil
    var lastSendImage: UIImage! = nil
    var lastCallbackId:String! = nil
    var recordingFlag = false
    var lastRects:[[[String: Float]]]! = []
    
    
    // video
    func capture(image: UIImage) {
        capturedImage = image
        openCv
            .changeImage(capturedImage)
            .toGrayScale()
            .thresholdBetween()
        let rects = openCv.findContours()
        lastRects = rects?.map({ points in
            return (points as! NSArray).map({v in
                let d = v as! NSDictionary
                return [
                    "x": (d["x"] as! NSNumber).floatValue,
                    "y": (d["y"] as! NSNumber).floatValue
                ]
            })
        })
        
//        let filteredImage = openCv.toUIImage()
//        let datas:NSData = UIImageJPEGRepresentation(filteredImage!, 0.5)! as NSData
        let datas:NSData = UIImageJPEGRepresentation(capturedImage!, 0.5)! as NSData
        base64 = "data:image/jpeg;base64," + datas.base64EncodedString()
        
        avCapture.isCapturing = false
    }
    
    func sendLastImage(keepCallback: NSNumber) {
        lastSendImage = capturedImage
        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: [
            "base64": base64 as String,
            "rects": lastRects ?? []
        ])
        result?.keepCallback = keepCallback
        commandDelegate.send(result, callbackId: lastCallbackId)
        avCapture.isCapturing = true
    }
    
    // 最初に呼ばれます
    override func pluginInitialize() {
        avCapture = AVCapture()
        initDevice()
        openCv = OpenCV()
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
    
    // 一旦変形画像を取得する関数として定義
    func scan(_ command: CDVInvokedUrlCommand! = nil) {
        if command != nil {
            let cv = OpenCV().changeImage(avCapture.getLastImage()).toGrayScale().thresholdBetween();
            
            let images = cv?.rects(toUIImages: cv?.findContours())
            let base64list = images?.map({ image -> String in
                let datas:NSData = UIImageJPEGRepresentation(image as! UIImage, 1)! as NSData
                return "data:image/jpeg;base64," + datas.base64EncodedString()
            })
            let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: base64list)
            self.commandDelegate.send(result, callbackId: command.callbackId)
        }
        
    }
    
    func startInterval() {
        // FPS
        DispatchQueue.main.asyncAfter(deadline: .now() + 1 / 15) {
            if self.lastCallbackId != nil && self.recordingFlag {
                if self.lastSendImage != self.capturedImage {
                    self.sendLastImage(keepCallback: true)
                }
                self.startInterval()
            }
        }
    }

}
