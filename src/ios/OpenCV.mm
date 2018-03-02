

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
    // TODO: 白いところをカット、黒いところをカットを変数化する
    
    // 200以上の白いところをカット (黒になる)
//    cv::threshold(_mat, _mat, 200, 255, CV_THRESH_TOZERO_INV );
    // 白黒の反転 (さっき黒くしたところも白くなる)
//    cv::bitwise_not(_mat, _mat);
    
    // 220以下の黒いところをカット
    cv::threshold(_mat, _mat, 0, 220, CV_THRESH_TOZERO );
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

-(NSMutableArray<NSArray<NSDictionary<NSString*, NSNumber*>*>*>*)FindContours {
    std::vector< std::vector<cv::Point> > contours;
    std::vector<cv::Vec4i> hierarchy;
    cv::findContours(_mat, contours, hierarchy, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);
    NSMutableArray *rects = [[NSMutableArray alloc] init];
    int max_level = 0;
    for(int i = 0; i < contours.size(); i++){
        // ある程度の面積が有るものだけに絞る
        double a = contourArea(contours[i],false);
        if(a > 10000 && a < 300000) {
            //輪郭を直線近似する
            std::vector<cv::Point> approx;
            
            // TODO: epsilonを感度として引数からも変えられるようにする
            double epsilon = 0.04 * cv::arcLength(contours[i], true);
            
            cv::approxPolyDP(cv::Mat(contours[i]), approx, epsilon, true);
            
            // 矩形のみ取得
//            if (approx.size() < 8 && approx.size() >= 4) {
            
//            NSLog(@"appr=%lu", approx.size());
            if (approx.size() == 4) {
//                [rects addObject:@[[NSValue valueWithCGPoint:CGPointMake(approx[0].x, approx[0].y)]]];
                [rects addObject:@[
                                   @{
                                       @"x":[NSNumber numberWithFloat:approx[0].x],
                                       @"y": [NSNumber numberWithFloat:approx[0].y]
                                       },
                                   @{
                                       @"x":[NSNumber numberWithFloat:approx[1].x],
                                       @"y": [NSNumber numberWithFloat:approx[1].y]
                                       },
                                   @{
                                       @"x":[NSNumber numberWithFloat:approx[2].x],
                                       @"y": [NSNumber numberWithFloat:approx[2].y]
                                       },
                                   @{
                                       @"x":[NSNumber numberWithFloat:approx[3].x],
                                       @"y": [NSNumber numberWithFloat:approx[3].y]
                                       }
                                   ]
                 ];
                cv::drawContours(_mat, contours, i, cv::Scalar(255, 255, 255, 255), 20, CV_AA, hierarchy, max_level);
            }
        }
    }
    return rects;
}
@end
