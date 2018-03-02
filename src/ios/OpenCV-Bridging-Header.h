
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface OpenCV : NSObject

- (UIImage *)Filter:(UIImage *)image;
- (OpenCV *)ChangeImage:(UIImage *)image;
- (OpenCV *)ImageThresholding;
- (UIImage *)ToUIImage;
- (OpenCV *)ToGrayScale;
- (OpenCV *)Threshold:(double)thresh maxval:(double)maxval type:(int)type;
- (OpenCV *)ThresholdBetween;
- (NSMutableArray<NSArray<NSDictionary<NSString*, NSNumber*>*>*>*)FindContours;

@property bool useBlur;
@property int blur0;
@property int blur1;
@property bool useThreshold;
@property bool useAdaptiveThreshold;
@property int adaptiveThreshold0;
@property int adaptiveThreshold1;
@property UIImage* image;


#ifdef __cplusplus
@property cv::Mat mat;
#endif


@end

