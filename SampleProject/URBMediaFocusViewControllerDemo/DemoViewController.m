//
//  DemoViewController.m
//  URBMediaFocusViewControllerDemo
//
//  Created by Nicholas Shipes on 11/3/13.
//  Copyright (c) 2013 Urban10 Interactive. All rights reserved.
//

#import "DemoViewController.h"
#import "URBMediaFocusViewController.h"

@interface DemoViewController ()

@property (nonatomic, strong) UIImageView *thumbnailView;
@property (nonatomic, strong) UIImageView *remoteThumbnailView;
@property (nonatomic, strong) UIImageView *localThumbnailView;
@property (nonatomic, strong) UIImageView *panoramaThumbnailView;
@property (nonatomic, strong) UIImageView *verticalPanoramaThumbnailView;
@property (nonatomic, strong) UIImageView *animatedThumbnailView;
@property (nonatomic, strong) NSMutableData *remoteData;
@property (nonatomic, strong) URBMediaFocusViewController *mediaFocusController;
@property (nonatomic, strong) NSURLConnection *connection;

@end

@implementation DemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.title = @"Demo";
	
	if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
		self.edgesForExtendedLayout = UIRectEdgeNone;
	}
	if ([self respondsToSelector:@selector(extendedLayoutIncludesOpaqueBars)]) {
		self.extendedLayoutIncludesOpaqueBars = YES;
	}
	
	self.mediaFocusController = [[URBMediaFocusViewController alloc] init];
	self.mediaFocusController.delegate = self;
    self.mediaFocusController.shouldShowPhotoActions = YES;
	//self.mediaFocusController.shouldBlurBackground = NO;	// uncomment if you don't want the background blurred
	//self.mediaFocusController.parallaxEnabled = NO;	// uncomment if you don't want the parallax (push-back) effect
	//self.mediaFocusController.shouldDismissOnTap = NO; // uncomment if you wish to disable dismissing the view on a single tap outside image bounds
	//self.mediaFocusController.shouldDismissOnImageTap = YES;	// uncomment if you wish to support dismissing view on a single tap on the image itself
	//self.mediaFocusController.allowSwipeOnBackgroundView = NO;
	
	self.thumbnailView = [self thumbnailViewWithOrigin:CGPointMake(20.0, 20.0)];
	self.thumbnailView.image = [UIImage imageNamed:@"seattle01.jpg"];
	
	self.remoteThumbnailView = [self thumbnailViewWithOrigin:CGPointMake(CGRectGetMinX(self.thumbnailView.frame), CGRectGetMaxY(self.thumbnailView.frame) + 20.0)];
	
	self.localThumbnailView = [self thumbnailViewWithOrigin:CGPointMake(CGRectGetMinX(self.thumbnailView.frame),
																		CGRectGetMaxY(self.remoteThumbnailView.frame) + 20.0)];
	self.localThumbnailView.image = [UIImage imageNamed:@"raceforfood.jpg"];
	
	self.panoramaThumbnailView = [self thumbnailViewWithOrigin:CGPointMake(CGRectGetMinX(self.thumbnailView.frame),
																		   CGRectGetMaxY(self.localThumbnailView.frame) + 20.0)];
	self.panoramaThumbnailView.image = [UIImage imageNamed:@"panorama.jpg"];
	
	self.verticalPanoramaThumbnailView = [self thumbnailViewWithOrigin:CGPointMake(CGRectGetMaxX(self.thumbnailView.frame) + 30.0f,
																				   CGRectGetMinY(self.thumbnailView.frame))];
	self.verticalPanoramaThumbnailView.image = [UIImage imageNamed:@"panorama_vert.jpg"];
	
	self.animatedThumbnailView = [self thumbnailViewWithOrigin:CGPointMake(CGRectGetMaxX(self.thumbnailView.frame) + 30.0f,
																		   CGRectGetMaxY(self.verticalPanoramaThumbnailView.frame) + 30.0f)];
	self.animatedThumbnailView.image = [UIImage imageNamed:@"animated_thumb.jpg"];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	if (!self.remoteThumbnailView.image) {
		NSURL *remoteImageURL = [NSURL URLWithString:@"http://apollo.urban10.net/random/oiab/01_thumb.jpg"];
		NSURLRequest *request = [NSURLRequest requestWithURL:remoteImageURL cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:10.0];
		
		if (!self.connection) {
			self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
		}
		self.remoteData = [[NSMutableData alloc] init];
		[self.connection start];
	}
}

- (BOOL)shouldAutorotate {
	return NO;
}

- (void)showFocusView:(UITapGestureRecognizer *)gestureRecognizer {	
	if (gestureRecognizer.view == self.localThumbnailView) {
		[self.mediaFocusController showImage:[UIImage imageNamed:@"raceforfood.jpg"] fromView:gestureRecognizer.view];
	}
	else if (gestureRecognizer.view == self.panoramaThumbnailView) {
		[self.mediaFocusController showImage:[UIImage imageNamed:@"panorama.jpg"] fromView:gestureRecognizer.view];
	}
	else if (gestureRecognizer.view == self.verticalPanoramaThumbnailView) {
		[self.mediaFocusController showImage:[UIImage imageNamed:@"panorama_vert.jpg"] fromView:gestureRecognizer.view];
	}
	else {
		NSURL *url;
		if (gestureRecognizer.view == self.remoteThumbnailView) {
			url = [NSURL URLWithString:@"http://apollo.urban10.net/random/oiab/01.jpg"];
		}
		else if (gestureRecognizer.view == self.localThumbnailView) {
			url = [NSURL URLWithString:@"http://farm3.staticflickr.com/2109/5763011359_f371b21fc9_b.jpg"];
		}
		else if (gestureRecognizer.view == self.animatedThumbnailView) {
			url = [NSURL URLWithString:@"http://s3-ec.buzzfed.com/static/enhanced/webdr02/2012/12/19/13/anigif_enhanced-buzz-8195-1355941233-2.gif"];
		}
		else {
			url = [NSURL URLWithString:@"http://farm3.staticflickr.com/2109/5763011359_f371b21fc9_b.jpg"];
		}
		[self.mediaFocusController showImageFromURL:url fromView:gestureRecognizer.view];
		
		// alternative method adding the focus view to this controller's view
		//[self.mediaFocusController showImageFromURL:url fromView:gestureRecognizer.view inViewController:self];
	}
}

- (void)addTapGestureToView:(UIView *)view {
	UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showFocusView:)];
	tapRecognizer.numberOfTapsRequired = 1;
	tapRecognizer.numberOfTouchesRequired = 1;
	[view addGestureRecognizer:tapRecognizer];
}

#pragma mark - URBMediaFocusViewControllerDelegate Methods

- (void)mediaFocusViewControllerDidAppear:(URBMediaFocusViewController *)mediaFocusViewController {
	NSLog(@"focus view appeared");
}

- (void)mediaFocusViewControllerDidDisappear:(URBMediaFocusViewController *)mediaFocusViewController {
	NSLog(@"focus view disappeared");
}

- (void)mediaFocusViewController:(URBMediaFocusViewController *)mediaFocusViewController didFinishLoadingImage:(UIImage *)image {
	NSLog(@"focus view finished loading image");
}

- (void)mediaFocusViewController:(URBMediaFocusViewController *)mediaFocusViewController didFailLoadingImageWithError:(NSError *)error {
	NSLog(@"focus view failed loading image: %@", error);
}

#pragma mark - NSURLConnectionDataDelegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[self.remoteData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	if (self.remoteData) {
		self.remoteThumbnailView.image = [UIImage imageWithData:self.remoteData];
		
	}
}

#pragma mark - Private Methods

- (UIImageView *)thumbnailViewWithOrigin:(CGPoint)origin {
	UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(origin.x, origin.y, 100.0, 100.0)];
	imageView.backgroundColor = [UIColor darkGrayColor];
	imageView.contentMode = UIViewContentModeScaleAspectFill;
	imageView.clipsToBounds = YES;
	imageView.userInteractionEnabled = YES;
	[self.view addSubview:imageView];
	[self addTapGestureToView:imageView];
	
	return imageView;
}

@end
