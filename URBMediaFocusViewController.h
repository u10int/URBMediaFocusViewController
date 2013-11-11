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
@optional

/**
 *  Tells the delegate that the controller's view is visisble. This is called after all presentation animations have completed.
 *
 *  @param mediaFocusViewController The instance that triggered the event.
 */
- (void)mediaFocusViewControllerDidAppear:(URBMediaFocusViewController *)mediaFocusViewController;

/**
 *  Tells the delegate that the controller's view has been removed and is no longer visible. This is called after all dismissal animations have completed.
 *
 *  @param mediaFocusViewController The instance the triggered the event.
 */
- (void)mediaFocusViewControllerDidDisappear:(URBMediaFocusViewController *)mediaFocusViewController;

/**
 *  Tells the delegate that the remote image needed for presentation has successfully loaded.
 *
 *  @param mediaFocusViewController The instance that triggered the event.
 *  @param image                    The image that was successfully loaded and used for the focus view.
 */
- (void)mediaFocusViewController:(URBMediaFocusViewController *)mediaFocusViewController didFinishLoadingImage:(UIImage *)image;

/**
 *  Tells the delegate that there was an error when requesting the remote image needed for presentation.
 *
 *  @param mediaFocusViewController The instance that triggered the event.
 *  @param error                    The error returned by the internal request.
 */
- (void)mediaFocusViewController:(URBMediaFocusViewController *)mediaFocusViewController didFailLoadingImageWithError:(NSError *)error;

@end

@interface URBMediaFocusViewController : UIViewController <UIDynamicAnimatorDelegate, UIGestureRecognizerDelegate, NSURLConnectionDataDelegate>

@property (nonatomic, readwrite) id<URBMediaFocusViewControllerDelegate> delegate;
@property (nonatomic, assign) BOOL parallaxMode;

/**
 *  Convenience method for not using a parentViewController.
 *  @see showImage:fromView:inViewController
 */
- (void)showImage:(UIImage *)image fromView:(UIView *)fromView;

/**
 *  Convenience method for not using a parentViewController.
 *  @see showImageFromURL:fromView:inViewController
 */
- (void)showImageFromURL:(NSURL *)url fromView:(UIView *)fromView;

/**
 *  Shows a full size image over the current view or main window. The image should be cached locally on the device, in the app bundle or an image generated from `NSData`.
 *
 *  @param image                The full size image to show, which should be an image already cached on the device or within the app's bundle.
 *  @param fromView             The view from which the presentation animation originates.
 *  @param parentViewController The parent view controller containing the `fromView`. If `parentViewController` is `nil`, then the focus view will be added to the main `UIWindow` instance.
 */
- (void)showImage:(UIImage *)image fromView:(UIView *)fromView inViewController:(UIViewController *)parentViewController;

/**
 *  Shows a full size image over the current view or main window after being requested from the specified URL. The `URBMediaFocusViewController` will only present its view once the image has been successfully loaded.
 *
 *  @param url                  The remote url of the full size image that will be requested and displayed.
 *  @param fromView             The view from which the presentation animation originates.
 *  @param parentViewController The parent view controller containing the `fromView`. If `parentViewController` is `nil`, then the focus view will be added to the main `UIWindow` instance.
 */
- (void)showImageFromURL:(NSURL *)url fromView:(UIView *)fromView inViewController:(UIViewController *)parentViewController;

@end
