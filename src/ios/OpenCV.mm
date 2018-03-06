

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
    int matAreaSize = _mat.size().width * _mat.size().height;
    double minAreaSize = matAreaSize * 0.05;
    double maxAreaSize = matAreaSize * 0.9;
    for(int i = 0; i < contours.size(); i++){
        // ある程度の面積が有るものだけに絞る
        double a = contourArea(contours[i],false);
        if(a > minAreaSize && a < maxAreaSize) {
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
                
                // デバッグ用の描画
//                cv::drawContours(_mat, contours, i, cv::Scalar(255, 255, 255, 255), 20, CV_AA, hierarchy, max_level);
            }
        }
    }
    return rects;
}

- (NSMutableArray<UIImage*>*)RectsToUIImages:(NSMutableArray<NSArray<NSDictionary<NSString*, NSNumber*>*>*>*)rects {
    NSMutableArray<UIImage*>* images = [[NSMutableArray alloc] init];
    cv::Mat image;
    UIImageToMat(_image, image);
    for (int i = 0; i < [rects count]; ++i) {
        NSArray<NSDictionary<NSString*, NSNumber*>*>* rect = rects[i];
        
        cv::Point2f src[4]; // 変換元
        cv::Point2f dst[4]; // 変換先
        
        // 0y が一番上の点で、左回りの想定
        for (int i = 0; i < 4; ++i) {
            src[i].x = [[rect objectAtIndex: i] objectForKey:@"x"].floatValue;
            src[i].y = [[rect objectAtIndex: i] objectForKey:@"y"].floatValue;
        }
        // top left bottom right は ひし形 ◇ で考えたときの頂点の位置
        double topLength = 0;
        double bottomLength = 0;
        double leftLength = 0;
        double rightLength = 0;
        
        // 左上の辺が上のとき
        int top = 0;
        if (src[1].y > src[3].y) {
            // 右上の辺が上の時
            top = 3;
        }
        int left = (top + 1) % 4;
        int bottom = (top + 2) % 4;
        int right = (top + 3) % 4;
        
        topLength = sqrt(pow(src[top].x - src[left].x ,2) + pow(src[top].y - src[left].y ,2));
        leftLength = sqrt(pow(src[left].x - src[bottom].x ,2) + pow(src[left].y - src[bottom].y ,2));
        bottomLength = sqrt(pow(src[bottom].x - src[right].x ,2) + pow(src[bottom].y - src[right].y ,2));
        rightLength = sqrt(pow(src[right].x - src[top].x ,2) + pow(src[right].y - src[top].y ,2));
        double rate = 1;
        
        // サイズが大きい方に合わせる
        if (topLength < bottomLength) {
            rate = bottomLength / topLength;
            topLength = bottomLength;
        }
        else {
            rate = topLength / bottomLength;
            bottomLength = topLength;
        }
        // 底辺と上の辺の斜め具合をかける
        rightLength *= rate;
        leftLength *= rate;
        
        if (rightLength < leftLength) {
            rightLength = leftLength;
        }
        else {
            leftLength = rightLength;
        }
        double width = topLength;
        double height = leftLength;
        
        dst[left].x = 0;
        dst[left].y = 0;
        
        dst[bottom].x = 0;
        dst[bottom].y = height;
        
        dst[right].y = height;
        dst[right].x = width;
        
        dst[top].x = width;
        dst[top].y = 0;
        
        
        cv::Mat mat;
        // 透視変換行列を取得
        cv::Mat perspective_matrix = cv::getPerspectiveTransform(src, dst);
        // 変換
        cv::warpPerspective(image, mat, perspective_matrix, cv::Size(width, height), cv::INTER_LINEAR);
        [images addObject: MatToUIImage(mat)];
    }
    return images;
}

@end
