
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface OpenCv : NSObject

- (UIImage *)Filter:(UIImage *)image;

@property bool useBlur;
@property int blur0;
@property int blur1;
@property bool useThreshold;
@property bool useAdaptiveThreshold;
@property int adaptiveThreshold0;
@property int adaptiveThreshold1;

@end
