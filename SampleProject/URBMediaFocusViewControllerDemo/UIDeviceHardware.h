//
//  UIDeviceHardware.h
//
//  Used to determine EXACT version of device software is running on.

#import <Foundation/Foundation.h>

@interface UIDeviceHardware : NSObject 

+ (NSString *) platform;
+ (NSString *) platformString;

+ (BOOL)supportsBlur;

@end