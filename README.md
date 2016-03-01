URBMediaFocusViewController
============
[![Build Status](https://travis-ci.org/u10int/URBMediaFocusViewController.svg)](https://travis-ci.org/u10int/URBMediaFocusViewController)

## Overview

`URBMediaFocusViewController` is an experiment to recreate the view used to enlarge photos and videos from their thumbnail previews as seen in [Tweetbot 3](https://itunes.apple.com/app/id722294701) using the UIDynamics API available starting with iOS 7.

![Basic example](https://dl.dropboxusercontent.com/u/197980/Screenshots/URBMediaFocusViewController03.gif)

## Requirements

- iOS 8.0+

## Usage

To run the example project, clone the repo, open the `URBMediaFocusViewControllerDemo.xcodeproject` and run the *URBMediaFocusViewControllerDemo* target.

## Installation

URBMediaFocusViewController is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "URBMediaFocusViewController"
```

## Usage Examples

To create an instance of `URBMediaFocusViewController`, just instantiate it the same way you would `UIViewController`, or by simply using `init`:

	self.mediaFocusController = [[URBMediaFocusViewController alloc] init];
	
	/* ...or... */
	self.mediaFocusController = [[URBMediaFocusViewController alloc] initWithNibName:nil bundle:nil];

The standard usage of `URBMediaFocusViewController` is to use it for displaying full-size photos over an existing view. In most cases, you would use it from a smaller thumbnail view of the photo you wish to show an enlarged version for. You can either display a photo that already exists locally within your project, or load the full-size image from a remote URL asynchronously using `NSURLConnection`.

The standard method would be to load your thumbnail images first, then request their full sizes when displaying the media focus view:
	
	NSURL *url = [NSURL URLWithString:@"http://apollo.urban10.net/random/oiab/01.jpg"];
	[self.mediaFocusController showImageFromURL:url fromView:self.thumbnailView];

The following is a basic example of showing an image that is linked into your project locally:

	[self.mediaFocusController showImage:[UIImage imageNamed:@"seattle01.jpg"] fromView:self.thumbnailView];
	
In most cases, you would present `URBMediaFocusViewController` from your app's key window, which is the default implementation. However, in some cases you may want to present your `URBMediaFocusViewController` view from a specific view controller. You can provide a parent view controller in those cases, and the `URBMediaFocusViewController` instance will be added on top of that controller's view:

	[self.mediaFocusController showImageFromURL:url fromView:self.thubmnailView inViewController:self];
	
The component will automatically detect if a loaded remote image is a GIF and properly animate it once it appears if so. You can also use the following built-in category methods to provide your own animated GIF image when displaying images that are local to your project:

	+ (UIImage *)urb_animatedImageWithAnimatedGIFData:(NSData *)data;
	+ (UIImage *)urb_animatedImageWithAnimatedGIFURL:(NSURL *)url;

## Customization

Most of the customization options included within this component are related to animation and physics, all of which are stored as static variables in `URBMediaFocusViewController.m` and can be quickly edited to achieve your desired effect.

By default, parallax and blur effects are enabled. To disable one or both effects, just set the following properties on your instance:

	self.parallaxEnabled = NO;				// default YES
	self.shouldBlurBackground = NO;			// default YES

By default, tapping on the image will not dismiss the focus view (as controlled by `shouldDismissOnTap`), but tapping outside of the image bounds will. You can change this by setting `shouldDismissOnImageTap` to `YES` on your `URBMediaFocusViewController` instance, which will allow tapping directly on the image to dismiss:

	self.shouldDismissOnImageTap = YES;	// default NO
	
If you wish to only dismiss using UIDynamics, you can also dismiss the default tap gesture used to dismiss (not recommended for iOS 6 since UIDynamics isn't available):

	self.shouldDismissOnTap = NO;			// default YES
	
You can also provide copy and save actions for the presented photo from an action sheet when the image receives a long press gesture. By default this feature is disabled, so just control this using the `shouldShowPhotoActions` property:

	self.shouldShowPhotoActions = YES;		// default NO

## License

This code is distributed under the terms and conditions of the MIT license.