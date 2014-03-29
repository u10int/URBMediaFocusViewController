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
	//self.mediaFocusController.shouldBlurBackground = NO;	// uncomment if you don't want the background blurred
	//self.mediaFocusController.parallaxEnabled = NO;	// uncomment if you don't want the parallax (push-back) effect
	//self.mediaFocusController.shouldDismissOnTap = NO; // uncomment if you wish to disable dismissing the view on a single tap outside image bounds
	//self.mediaFocusController.shouldDismissOnImageTap = YES;	// uncomment if you wish to support dismissing view on a single tap on the image itself
	
	self.thumbnailView = [[UIImageView alloc] initWithFrame:CGRectMake(20.0, 20.0, 100.0, 100.0)];
	self.thumbnailView.backgroundColor = [UIColor darkGrayColor];
	self.thumbnailView.contentMode = UIViewContentModeScaleAspectFill;
	self.thumbnailView.clipsToBounds = YES;
	self.thumbnailView.userInteractionEnabled = YES;
	self.thumbnailView.image = [UIImage imageNamed:@"seattle01.jpg"];
	[self.view addSubview:self.thumbnailView];
	[self addTapGestureToView:self.thumbnailView];
	
	self.remoteThumbnailView = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetMinX(self.thumbnailView.frame), CGRectGetMaxY(self.thumbnailView.frame) + 20.0, 100.0, 100.0)];
	self.remoteThumbnailView.backgroundColor = [UIColor darkGrayColor];
	self.remoteThumbnailView.contentMode = UIViewContentModeScaleAspectFill;
	self.remoteThumbnailView.clipsToBounds = YES;
	self.remoteThumbnailView.userInteractionEnabled = YES;
	[self.view addSubview:self.remoteThumbnailView];
	[self addTapGestureToView:self.remoteThumbnailView];
	
	self.localThumbnailView = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetMinX(self.thumbnailView.frame), CGRectGetMaxY(self.remoteThumbnailView.frame) + 20.0, 100.0, 100.0)];
	self.localThumbnailView.backgroundColor = [UIColor darkGrayColor];
	self.localThumbnailView.contentMode = UIViewContentModeScaleAspectFill;
	self.localThumbnailView.clipsToBounds = YES;
	self.localThumbnailView.userInteractionEnabled = YES;
	self.localThumbnailView.image = [UIImage imageNamed:@"raceforfood.jpg"];
	[self.view addSubview:self.localThumbnailView];
	[self addTapGestureToView:self.localThumbnailView];
	
	self.panoramaThumbnailView = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetMinX(self.thumbnailView.frame), CGRectGetMaxY(self.localThumbnailView.frame) + 20.0, 100.0, 100.0)];
	self.panoramaThumbnailView.backgroundColor = [UIColor darkGrayColor];
	self.panoramaThumbnailView.contentMode = UIViewContentModeScaleAspectFill;
	self.panoramaThumbnailView.clipsToBounds = YES;
	self.panoramaThumbnailView.userInteractionEnabled = YES;
	self.panoramaThumbnailView.image = [UIImage imageNamed:@"panorama.jpg"];
	[self.view addSubview:self.panoramaThumbnailView];
	[self addTapGestureToView:self.panoramaThumbnailView];
	
	self.verticalPanoramaThumbnailView = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.thumbnailView.frame) + 30.0f, CGRectGetMinY(self.thumbnailView.frame), 100.0, 100.0)];
	self.verticalPanoramaThumbnailView.backgroundColor = [UIColor darkGrayColor];
	self.verticalPanoramaThumbnailView.contentMode = UIViewContentModeScaleAspectFill;
	self.verticalPanoramaThumbnailView.clipsToBounds = YES;
	self.verticalPanoramaThumbnailView.userInteractionEnabled = YES;
	self.verticalPanoramaThumbnailView.image = [UIImage imageNamed:@"panorama_vert.jpg"];
	[self.view addSubview:self.verticalPanoramaThumbnailView];
	[self addTapGestureToView:self.verticalPanoramaThumbnailView];
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

@end
