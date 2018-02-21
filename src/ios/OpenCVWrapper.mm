//
//  OpenCVWrapper.m
//  cordova-plugin-scanner-test
//
//  Created by shogo on 2018/02/20.
//

#import "OpenCVWrapper.h"
#import <opencv2/opencv.hpp>
@implementation OpenCVWrapper

+(NSString*)openCVVersionString {
    return [NSString stringWithFormat:@"OpenCV Version %s", CV_VERSION];
}

@end
