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
@property (nonatomic, strong) UIImageView *parallaxThumbnailView;
@property (nonatomic, strong) UIImageView *remoteThumbnailView;
@property (nonatomic, strong) NSMutableData *remoteData;
@property (nonatomic, strong) URBMediaFocusViewController *mediaFocusController;
@property (nonatomic, strong) NSURLConnection *connection;

@end

@implementation DemoViewController {
	NSString *_remoteImageURL;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.mediaFocusController = [[URBMediaFocusViewController alloc] init];
	self.mediaFocusController.delegate = self;
	
	self.thumbnailView = [[UIImageView alloc] initWithFrame:CGRectMake(50.0, 50.0, 100.0, 100.0)];
	self.thumbnailView.backgroundColor = [UIColor darkGrayColor];
	self.thumbnailView.contentMode = UIViewContentModeScaleAspectFill;
	self.thumbnailView.clipsToBounds = YES;
	self.thumbnailView.userInteractionEnabled = YES;
	self.thumbnailView.image = [UIImage imageNamed:@"seattle01.jpg"];
	[self.view addSubview:self.thumbnailView];
	
	// add tap gesture on thumbnail view to show focus view
	UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showFocusView:)];
	tapRecognizer.numberOfTapsRequired = 1;
	tapRecognizer.numberOfTouchesRequired = 1;
	[self.thumbnailView addGestureRecognizer:tapRecognizer];
	

	self.remoteThumbnailView = [[UIImageView alloc] initWithFrame:CGRectMake(50.0, CGRectGetMaxY(self.thumbnailView.frame) + 50.0, 100.0, 100.0)];
	self.remoteThumbnailView.backgroundColor = [UIColor darkGrayColor];
	self.remoteThumbnailView.contentMode = UIViewContentModeScaleAspectFill;
	self.remoteThumbnailView.clipsToBounds = YES;
	self.remoteThumbnailView.userInteractionEnabled = YES;
	[self.view addSubview:self.remoteThumbnailView];
	
	// add tap gesture on thumbnail view to show focus view
	UITapGestureRecognizer *remoteTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showFocusView:)];
	remoteTapRecognizer.numberOfTapsRequired = 1;
	remoteTapRecognizer.numberOfTouchesRequired = 1;
	[self.remoteThumbnailView addGestureRecognizer:remoteTapRecognizer];

	
    

    self.parallaxThumbnailView = [[UIImageView alloc] initWithFrame:CGRectMake(50.0, CGRectGetMaxY(self.remoteThumbnailView.frame) + 50.0,
                                                                               100.0, 100.0)];
	self.parallaxThumbnailView.backgroundColor = [UIColor darkGrayColor];
	self.parallaxThumbnailView.contentMode = UIViewContentModeScaleAspectFill;
	self.parallaxThumbnailView.clipsToBounds = YES;
	self.parallaxThumbnailView.userInteractionEnabled = YES;
	self.parallaxThumbnailView.image = [UIImage imageNamed:@"perth01"];
	[self.view addSubview:self.parallaxThumbnailView];
	
	// add tap gesture on thumbnail view to show focus view
	UITapGestureRecognizer *parallaxTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showFocusView:)];
	parallaxTapRecognizer.numberOfTapsRequired = 1;
	parallaxTapRecognizer.numberOfTouchesRequired = 1;
	[self.parallaxThumbnailView addGestureRecognizer:parallaxTapRecognizer];
    
    

	_remoteImageURL = @"http://apollo.urban10.net/random/oiab/01.jpg";
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

- (void)showFocusView:(UITapGestureRecognizer *)gestureRecognizer {
	NSURL *url;
	if (gestureRecognizer.view == self.remoteThumbnailView) {
		url = [NSURL URLWithString:_remoteImageURL];
        self.mediaFocusController.parallaxMode = NO;
        [self.mediaFocusController showImageFromURL:url
                                           fromView:gestureRecognizer.view];
	} else if (gestureRecognizer.view == self.thumbnailView) {
		url = [NSURL URLWithString:@"http://farm3.staticflickr.com/2109/5763011359_f371b21fc9_b.jpg"];
        self.mediaFocusController.parallaxMode = NO;
        [self.mediaFocusController showImageFromURL:url fromView:gestureRecognizer.view];
	} else if (gestureRecognizer.view == self.parallaxThumbnailView) {
        self.mediaFocusController.parallaxMode = YES;
        [self.mediaFocusController showImage:[UIImage imageNamed:@"perthpano3.jpg"]
                                    fromView:self.parallaxThumbnailView
                            inViewController:self];
    }
	
	// alternative method adding the focus view to this controller's view
	//[self.mediaFocusController showImageFromURL:url fromView:gestureRecognizer.view inViewController:self];
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
