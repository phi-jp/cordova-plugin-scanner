
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
    var counter = 0 //更に処理を少なくする
    
    override init(){
        super.init()
        
        captureSession = AVCaptureSession()
        
        // 解像度
        captureSession.sessionPreset = AVCaptureSessionPreset640x480
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
            print("OKOKOK")
            authorized = true
        case AVAuthorizationStatus.denied:
            print("denied")
            fallthrough
        case AVAuthorizationStatus.notDetermined:
            print("notdeterminbed")
            fallthrough

        case AVAuthorizationStatus.restricted:
            print("restricted")
            authorized = false
            return

        }

        let videoDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo) // カメラ
        do {
            try videoDevice?.lockForConfiguration()
            // FPS
            videoDevice?.activeVideoMaxFrameDuration = CMTimeMake(1, 30)
            videoDevice?.activeVideoMinFrameDuration = CMTimeMake(1, 30)
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
        self.captureSession.startRunning()
    }
    
    func stopRunning() {
        self.captureSession.stopRunning()
    }
    
    // 新しいキャプチャの追加で呼ばれる(1/30秒に１回)
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        if isCapturing {
            let image = imageFromSampleBuffer(sampleBuffer: sampleBuffer)
            delegate?.capture(image: image)
        }
    }
    
    func imageFromSampleBuffer(sampleBuffer :CMSampleBuffer) -> UIImage {
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
        let image = UIImage(cgImage: imageRef, scale: 1.0, orientation: UIImageOrientation.right)
        
        // イメージバッファのアンロック
        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        return image
    }
}
