

#import <UIKit/UIKit.h>
#import "OpenCV-Bridging-Header.h"
#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>

@implementation OpenCV : NSObject

- (id) init {
    if (self = [super init]) {
        self.adaptiveThreshold0 = 2;
        self.adaptiveThreshold1 = 2;
    }
    return self;
}

-(UIImage *)Filter:(UIImage *)image {
    
    // 方向を修正
    UIGraphicsBeginImageContext(image.size);
    [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //UIImageをcv::Matに変換
    cv::Mat mat;
    UIImageToMat(image, mat);
    cv::cvtColor(mat,mat,CV_BGR2GRAY);
    
    //Blur ぼかし
    if(_useBlur) {
        // kSizeは奇数のみ
        int kSize = _blur0;
        if(kSize % 2 == 0) {
            kSize += 1;
        }
        cv::GaussianBlur(mat, mat, cv::Size(kSize,kSize), _blur1);
    }
    
    // 閾値
    if(_useThreshold) {
        cv::threshold(mat, mat, 0, 255, cv::THRESH_BINARY|cv::THRESH_OTSU);
    }
    
    // 適応閾値
    if(_useAdaptiveThreshold) {
        
        // blockSizeは奇数のみ
        int blockSize = _adaptiveThreshold0;
        if(blockSize % 2 == 0) {
            blockSize += 1;
        }
        cv::adaptiveThreshold(mat, mat, 255, cv::ADAPTIVE_THRESH_GAUSSIAN_C, cv::THRESH_BINARY, blockSize, _adaptiveThreshold1);
    }
    
    return MatToUIImage(mat);
}

-(OpenCV *)ChangeImage:(UIImage *)image {
    // 縦横を修正
    UIGraphicsBeginImageContext(image.size);
    [image drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
    _image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    cv::Mat mat;
    UIImageToMat(_image, mat);
    _mat = mat;
    return self;
}

-(OpenCV *)ImageThresholding {
    cv::Mat gray;
    // _mat を グレースケールにしたやつを gray に出力する
    cv::cvtColor(_mat, gray, CV_BGR2GRAY);
    // 閾値(0, 255)で画像を2値化
    cv::threshold(gray, gray, 0, 255, cv::THRESH_BINARY|cv::THRESH_OTSU);
    
    return self;
}
-(OpenCV *)ThresholdBetween {
    [self Threshold:0 maxval:255 type: cv::THRESH_BINARY|cv::THRESH_OTSU];
    return self;
}

-(UIImage *)ToUIImage {
    return MatToUIImage(_mat);
}

-(OpenCV *)ToGrayScale {
    [OpenCV ToGrayScale:&_mat];
    return self;
}

+(void)ToGrayScale:(cv::Mat*) src {
    // _mat を グレースケールにしたやつを gray に出力する
    cv::cvtColor(*src, *src, CV_BGR2GRAY);
}

-(OpenCV *)Threshold:(double)thresh maxval:(double)maxval type:(int)type {
    cv::threshold(_mat, _mat, thresh, maxval, type);
    return self;
}

@end
