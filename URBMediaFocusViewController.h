//
//  URBMediaFocusViewController.h
//  URBMediaFocusViewControllerDemo
//
//  Created by Nicholas Shipes on 11/3/13.
//  Copyright (c) 2013 Urban10 Interactive. All rights reserved.
//

#import <UIKit/UIKit.h>

@class URBMediaFocusViewController;

@protocol URBMediaFocusViewControllerDelegate <NSObject>

- (void)mediaFocusViewController:(URBMediaFocusViewController *)mediaFocusViewController didFinishLoadingImage:(UIImage *)image;
- (void)mediaFocusViewController:(URBMediaFocusViewController *)mediaFocusViewController didFailLoadingImageWithError:(NSError *)error;

@end

@interface URBMediaFocusViewController : UIViewController <UIGestureRecognizerDelegate, NSURLConnectionDataDelegate>

@property (nonatomic, strong) UIImage *thumbnail;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, readwrite) id<URBMediaFocusViewControllerDelegate> delegate;

- (void)showImage:(UIImage *)image fromView:(UIView *)fromView inView:(UIView *)targetView;
- (void)showImageFromURL:(NSURL *)url fromView:(UIView *)fromView inView:(UIView *)targetView;

@end
