
import Foundation
import AVFoundation

protocol AVCaptureDelegate {
    func capture(image: UIImage)
}

class AVCapture:NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var captureSession: AVCaptureSession!
    var delegate: AVCaptureDelegate?
    var isCapturing = true
    var authorized = false
    var initialized = false
    var takingPhoto = false
    var lastBuffer: CMSampleBuffer!
    
    override init(){
        super.init()
        
        captureSession = AVCaptureSession()
        
        // 解像度
        captureSession.sessionPreset = AVCaptureSessionPreset1920x1080
        //AVCaptureSessionPresetMedium
        //AVCaptureSessionPreset1920x1080 1/5
        //AVCaptureSessionPreset1280x720 1/5
        //AVCaptureSessionPreset640x480
        //AVCaptureSessionPresetLow
        
        initDevice()
        
    }
    
    func initDevice() {
        if initialized {
            return
        }
        let status = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        switch status {
        case AVAuthorizationStatus.authorized:
            authorized = true
        case AVAuthorizationStatus.denied:
            fallthrough
        case AVAuthorizationStatus.notDetermined:
            fallthrough

        case AVAuthorizationStatus.restricted:
            authorized = false
            return

        }

        let videoDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo) // カメラ
        do {
            try videoDevice?.lockForConfiguration()
            // FPS
            videoDevice?.activeVideoMaxFrameDuration = CMTimeMake(1, 15)
            videoDevice?.activeVideoMinFrameDuration = CMTimeMake(1, 10)
            videoDevice?.unlockForConfiguration()
        }
        catch {
            print("VIDEO DEVICE ERROR")
        }
        
        
        
        let videoInput = try! AVCaptureDeviceInput.init(device: videoDevice)
        captureSession.addInput(videoInput)
        
        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        // ピクセルフォーマット(32bit BGRA)
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable : Int(kCVPixelFormatType_32BGRA)]
        videoDataOutput.alwaysDiscardsLateVideoFrames = false // 処理中の場合は、フレームを破棄する
        captureSession.addOutput(videoDataOutput)
        
        //let videoConnection:AVCaptureConnection = (videoDataOutput.connection(withMediaType: AVMediaTypeVideo))!
        //videoConnection.videoOrientation = .portrait
        
        initialized = true
    }
    
    func startRunning() {
        if !captureSession.isRunning {
            self.captureSession.startRunning()
        }
    }
    
    func stopRunning() {
        if captureSession.isRunning {
            self.captureSession.stopRunning()
        }
    }
    
    // 新しいキャプチャの追加で呼ばれる(1/30秒に１回)
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        if isCapturing {
            lastBuffer = sampleBuffer
            let image = imageFromSampleBuffer(sampleBuffer: sampleBuffer, scale: 1/3)
            delegate?.capture(image: image)
        }
    }
    
    func getLastImage(scale: CGFloat = 1.0) -> UIImage {
        return imageFromSampleBuffer(sampleBuffer: lastBuffer, scale: scale)
    }
    
    func imageFromSampleBuffer(sampleBuffer :CMSampleBuffer, scale: CGFloat = 1.0) -> UIImage {
        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        
        // イメージバッファのロック
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        // 画像情報を取得
        let base = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)!
        let bytesPerRow = UInt(CVPixelBufferGetBytesPerRow(imageBuffer))
        let width = UInt(CVPixelBufferGetWidth(imageBuffer))
        let height = UInt(CVPixelBufferGetHeight(imageBuffer))
        
        // ビットマップコンテキスト作成
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitsPerCompornent = 8
        let bitmapInfo = CGBitmapInfo(rawValue: (CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue) as UInt32)
        let newContext = CGContext(data: base, width: Int(width), height: Int(height), bitsPerComponent: Int(bitsPerCompornent), bytesPerRow: Int(bytesPerRow), space: colorSpace, bitmapInfo: bitmapInfo.rawValue)! as CGContext
        
        // 画像作成
        let imageRef = newContext.makeImage()!
        var image = UIImage(cgImage: imageRef, scale: 1.0, orientation: UIImageOrientation.right)
        
        if scale != 1.0 {
            let resizedSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            
            UIGraphicsBeginImageContext(resizedSize) // 変更
            image.draw(in: CGRect(origin: .zero, size: resizedSize))
            image = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
        }
        // イメージバッファのアンロック
        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        return image
    }
}
