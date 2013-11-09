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

/**
 *  dfasfsf
 *
 *  @param mediaFocusViewController The instance that triggered the event.
 *  @param image                    The image that was successfully loaded and used for the focus view.
 */
- (void)mediaFocusViewController:(URBMediaFocusViewController *)mediaFocusViewController didFinishLoadingImage:(UIImage *)image;

/**
 *  dd
 *
 *  @param mediaFocusViewController The instance that triggered the event.
 *  @param error                    The error returned by the internal request.
 */
- (void)mediaFocusViewController:(URBMediaFocusViewController *)mediaFocusViewController didFailLoadingImageWithError:(NSError *)error;

@end

@interface URBMediaFocusViewController : UIViewController <UIDynamicAnimatorDelegate, UIGestureRecognizerDelegate, NSURLConnectionDataDelegate>

@property (nonatomic, readwrite) id<URBMediaFocusViewControllerDelegate> delegate;

/**
 *  Shows a full size image on top of the app's main window.
 *
 *  @param image                The full size image to show, which should be an image already cached on the device or within the app's bundle.
 *  @param fromView             The view from which the presentation animation originates.
 *  @param parentViewController The parent view controller containing the `fromView`. If `parentViewController` is `nil`, then the focus view will be added to the main `UIWindow` instance.
 */
- (void)showImage:(UIImage *)image fromView:(UIView *)fromView inViewController:(UIViewController *)parentViewController;

/**
 *  <#Description#>
 *
 *  @param url                  The remote url of the full size image that will be requested and displayed.
 *  @param fromView             The view from which the presentation animation originates.
 *  @param parentViewController The parent view controller containing the `fromView`. If `parentViewController` is `nil`, then the focus view will be added to the main `UIWindow` instance.
 */
- (void)showImageFromURL:(NSURL *)url fromView:(UIView *)fromView inViewController:(UIViewController *)parentViewController;

@end
