//
//  URBMediaFocusViewController.m
//  URBMediaFocusViewControllerDemo
//
//  Created by Nicholas Shipes on 11/3/13.
//  Copyright (c) 2013 Urban10 Interactive. All rights reserved.
//

#import "URBMediaFocusViewController.h"
#import "UIDeviceHardware.h"
#import "UIView-JTViewToImage.h"
#import "UIImage+ImageEffects.h"

static const CGFloat __shrinkScale = .9f;
static const CGFloat __blurRadius = 2.f;
static const CGFloat __blurSaturationDeltaMask = .8f;
static const CGFloat __blurTintColorAlpha = .2f;
static const CGFloat __overlayAlpha = .7f;

static const CGFloat __animationDuration = 0.25f;				// the base duration for present/dismiss animations (except physics-related ones)
static const CGFloat __velocityFactor = 1.0f;					// affects how quickly the view is pushed out of the view
static const CGFloat __angularVelocityFactor = 15.0f;			// adjusts the amount of spin applied to the view during a push force, increases towards the view bounds
static const CGFloat __minimumVelocityRequiredForPush = 50.0f;	// defines how much velocity is required for the push behavior to be applied

@interface URBMediaFocusViewController ()

@property (nonatomic, strong) UIView *fromView;
@property (nonatomic, weak) UIViewController *targetViewController;

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIDynamicAnimator *animator;
@property (nonatomic, strong) UISnapBehavior *snapBehavior;
@property (nonatomic, strong) UIPushBehavior *pushBehavior;
@property (nonatomic, strong) UIAttachmentBehavior *panAttachmentBehavior;
@property (nonatomic, strong) UIDynamicItemBehavior *itemBehavior;

@property (nonatomic, readonly) UIWindow *keyWindow;
@property (nonatomic, strong) UIPinchGestureRecognizer *pinchRecognizer;
@property (nonatomic, strong) UIPanGestureRecognizer *panRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *dblTapRecognizer;

@property (nonatomic, strong) UIActivityIndicatorView *loadingView;
@property (nonatomic, strong) NSURLConnection *urlConnection;
@property (nonatomic, strong) NSMutableData *urlData;

// parallax
@property(nonatomic, strong) UIView *snapshotViewBelow;
@property(nonatomic, strong) UIView *snapshotViewAbove;

@end

@implementation URBMediaFocusViewController {
	CGRect _originalFrame;
	CGFloat _minScale;
	CGFloat _maxScale;
	CGFloat _lastPinchScale;
	UIInterfaceOrientation _currentOrientation;
	BOOL _hasLaidOut;
}

- (id)init {
	self = [super init];
	if (self) {
		_hasLaidOut = NO;
	}
	return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[self setup];
}

- (void)setup {
	self.view.frame = self.keyWindow.bounds;
	
	self.backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.keyWindow.frame), CGRectGetHeight(self.keyWindow.frame))];
	self.backgroundView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.6f];
	self.backgroundView.alpha = 0.0f;
	self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
	[self.view addSubview:self.backgroundView];
	
	self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 50.0, 50.0)];
	self.imageView.contentMode = UIViewContentModeScaleAspectFit;
	self.imageView.alpha = 0.0f;
	self.imageView.userInteractionEnabled = YES;
	[self.view addSubview:self.imageView];
	
	self.pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
	self.pinchRecognizer.delegate = self;
	self.panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
	self.panRecognizer.delegate = self;
	
	[self.imageView addGestureRecognizer:self.panRecognizer];
	
    // dbl tap to zoom back to original for easier dismisal
    self.dblTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(returnToCenter)];
    self.dblTapRecognizer.delegate = self;
    self.dblTapRecognizer.numberOfTapsRequired = 2;
    self.dblTapRecognizer.numberOfTouchesRequired = 1;
    
    [self.imageView addGestureRecognizer:self.dblTapRecognizer];

    // tap to dismiss
    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissFromTap:)];
    [self.view addGestureRecognizer:tgr];
    
	// UIDynamics stuff
	self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
	self.animator.delegate = self;
	
	// snap behavior to keep image view in the center as needed
	self.snapBehavior = [[UISnapBehavior alloc] initWithItem:self.imageView snapToPoint:self.view.center];
	self.snapBehavior.damping = 1.0f;
	
	self.pushBehavior = [[UIPushBehavior alloc] initWithItems:@[self.imageView] mode:UIPushBehaviorModeInstantaneous];
	self.pushBehavior.angle = 0.0f;
	self.pushBehavior.magnitude = 0.0f;
	
	self.itemBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.imageView]];
	self.itemBehavior.elasticity = 0.0f;
	self.itemBehavior.friction = 0.2f;
	self.itemBehavior.allowsRotation = YES;
	//self.itemBehavior.density = 1.0f;
	//self.itemBehavior.resistance = 0.0f;
}

- (void)showImage:(UIImage *)image fromView:(UIView *)fromView {
	[self showImage:image fromView:fromView inViewController:nil];
}

- (void)showImageFromURL:(NSURL *)url fromView:(UIView *)fromView {
	[self showImageFromURL:url fromView:fromView inViewController:nil];
}

- (void)showImage:(UIImage *)image fromView:(UIView *)fromView inViewController:(UIViewController *)parentViewController {
	
    if (self.parallaxMode) {
        [self _setStatusBarHidden:YES];
        UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
        self.snapshotViewBelow = [self _containerViewForWindow:window];
        self.snapshotViewAbove = [self _borderedSnapshotImageViewForWindow:window];
    }
    
	self.fromView = fromView;
	self.targetViewController = parentViewController;
	
    [self.view setNeedsDisplay];
	CGRect fromRect = [fromView.superview convertRect:fromView.frame toView:nil];
	self.imageView.transform = CGAffineTransformIdentity;
	self.imageView.frame = fromRect;
	self.imageView.image = image;
	self.imageView.alpha = 0.2;
	
	CGSize targetSize = image.size;
	CGFloat scale = 1.0f;
	if (targetSize.width > CGRectGetWidth(self.view.frame)) {
		targetSize.width = CGRectGetWidth(self.view.frame);
		scale = targetSize.width / image.size.width;
		targetSize.height *= scale;
	}
	else if (targetSize.height > CGRectGetHeight(self.view.frame)) {
		targetSize.height = CGRectGetHeight(self.view.frame);
		scale = targetSize.height / image.size.height;
		targetSize.width *= scale;
	}
	
	// image view's destination frame is the size of the image capped to the width/height of the target view
	CGPoint midpoint = CGPointMake(CGRectGetMidX(self.view.frame), CGRectGetMidY(self.view.frame));
	CGRect targetRect = CGRectMake(midpoint.x - targetSize.width / 2.0, midpoint.y - targetSize.height / 2.0, targetSize.width, targetSize.height);
	
	// set initial frame of image view to match that of the presenting image
	//self.imageView.frame = CGRectMake(midpoint.x - image.size.width / 2.0, midpoint.y - image.size.height / 2.0, image.size.width, image.size.height);
	self.imageView.frame = [fromView.superview convertRect:fromView.frame toView:nil];
	_originalFrame = targetRect;
	// rotate imageView based on current device orientation
	[self reposition];
    
	if (scale < 1.0f) {
		_minScale = 1.0f;
		_maxScale = (targetSize.width > targetSize.height) ? image.size.width / targetSize.width : image.size.height / targetSize.height;
	}
	else {
		_minScale = scale;
		_maxScale = 1.0f;
	}
	_lastPinchScale = 1.0f;
	_hasLaidOut = YES;
	
	// register for device orientation changes
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
	// register with the device that we want to know when the device orientation changes
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
	
	if (self.targetViewController) {
		[self willMoveToParentViewController:self.targetViewController];
		self.targetViewController.view.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
		[self.targetViewController.view tintColorDidChange];
		[self.targetViewController addChildViewController:self];

        if (self.parallaxMode) {
            [self.targetViewController.view addSubview:self.snapshotViewBelow];
            [self.targetViewController.view addSubview:self.snapshotViewAbove];
        }
		[self.targetViewController.view addSubview:self.view];
	}
	else {
		// add this view to the main window if no targetViewController was set
		self.keyWindow.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
		[self.keyWindow tintColorDidChange];
        
        if (self.parallaxMode) {
            [self.keyWindow addSubview:self.snapshotViewBelow];
            [self.keyWindow addSubview:self.snapshotViewAbove];
        }
		[self.keyWindow addSubview:self.view];
	}
	
	[UIView animateWithDuration:__animationDuration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
		self.backgroundView.alpha = 1.0f;
		self.imageView.alpha = 1.0f;
		self.imageView.frame = targetRect;
        
        if (self.parallaxMode) {
            self.snapshotViewAbove.alpha = 1.0;
            self.snapshotViewAbove.transform = CGAffineTransformScale(CGAffineTransformIdentity, __shrinkScale, __shrinkScale);
            
            self.snapshotViewBelow.transform = CGAffineTransformScale(CGAffineTransformIdentity, __shrinkScale, __shrinkScale);
        }
	} completion:^(BOOL finished) {
		[self.imageView addGestureRecognizer:self.pinchRecognizer];
		if (self.targetViewController) {
			[self didMoveToParentViewController:self.targetViewController];
		}
		
		if ([self.delegate respondsToSelector:@selector(mediaFocusViewControllerDidAppear:)]) {
			[self.delegate mediaFocusViewControllerDidAppear:self];
		}
	}];
}

- (void)showImageFromURL:(NSURL *)url fromView:(UIView *)fromView inViewController:(UIViewController *)parentViewController {
	self.fromView = fromView;
	self.targetViewController = parentViewController;
	
	NSURLRequest *request = [NSURLRequest requestWithURL:url];
	NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	self.urlConnection = connection;
	
	// stores data as it's loaded from the request
	self.urlData = [[NSMutableData alloc] init];
	
	// show loading indicator on fromView
	if (!self.loadingView) {
		self.loadingView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 30.0, 30.0)];
	}
	[fromView addSubview:self.loadingView];
	self.loadingView.center = CGPointMake(CGRectGetWidth(fromView.frame) / 2.0, CGRectGetHeight(fromView.frame) / 2.0);
	
	[self.loadingView startAnimating];
	[self.urlConnection start];
}

- (void)dismissFromTap:(id)sender
{
    [self dismiss:YES shrinkingImageView:YES];
}

- (void)dismissFromSwipeAway
{
    [self dismiss:YES shrinkingImageView:NO];
}

- (void)dismiss:(BOOL)animated shrinkingImageView:(BOOL)shrinkImageView {
	[UIView animateWithDuration:__animationDuration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{

		self.backgroundView.alpha = 0.0f;
        
        if (shrinkImageView) {
            CGRect fromRect = [self.fromView.superview convertRect:self.fromView.frame toView:nil];
            self.imageView.frame = fromRect;
            self.imageView.alpha = 0.0f;
        }
        
        if (self.parallaxMode) {
            self.snapshotViewAbove.alpha = 0.f;
            self.snapshotViewAbove.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1., 1.);
            self.snapshotViewBelow.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1., 1.);
        }
        
	} completion:^(BOOL finished) {
		[self cleanup];
        
        if (self.parallaxMode) {
            [self.snapshotViewAbove removeFromSuperview];
            [self.snapshotViewBelow removeFromSuperview];
            [self _setStatusBarHidden:NO];
        }
	}];
}

#pragma mark - Private Methods

- (UIWindow *)keyWindow {
	return [UIApplication sharedApplication].keyWindow;
}

- (void)adjustFrame {
	CGRect imageFrame = self.imageView.frame;
	
	// snap x sides
	if (CGRectGetWidth(imageFrame) > CGRectGetWidth(self.view.frame)) {
		if (CGRectGetMinX(imageFrame) > 0) {
			imageFrame.origin.x = 0;
		}
		else if (CGRectGetMaxX(imageFrame) < CGRectGetWidth(self.view.frame)) {
			imageFrame.origin.x = CGRectGetWidth(self.view.frame) - CGRectGetWidth(imageFrame);
		}
	}
	else if (self.imageView.center.x != CGRectGetMidX(self.view.frame)) {
		imageFrame.origin.x = CGRectGetMidX(self.view.frame) - CGRectGetWidth(imageFrame) / 2.0f;
	}
	
	// snap y sides
	if (CGRectGetHeight(imageFrame) > CGRectGetHeight(self.view.frame)) {
		if (CGRectGetMinY(imageFrame) > 0) {
			imageFrame.origin.y = 0;
		}
		else if (CGRectGetMaxY(imageFrame) < CGRectGetHeight(self.view.frame)) {
			imageFrame.origin.y = CGRectGetHeight(self.view.frame) - CGRectGetHeight(imageFrame);
		}
	}
	else if (self.imageView.center.y != CGRectGetMidY(self.view.frame)) {
		imageFrame.origin.y = CGRectGetMidY(self.view.frame) - CGRectGetHeight(imageFrame) / 2.0f;
	}
	
	[UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
		self.imageView.frame = imageFrame;
	} completion:^(BOOL finished) {
		
	}];
}

- (void)returnToCenter {
	[self.animator removeAllBehaviors];
	[UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
		self.imageView.transform = CGAffineTransformIdentity;
		self.imageView.frame = _originalFrame;
	} completion:nil];
}

- (void)cleanup {
	[self.view removeFromSuperview];
	
	if (self.targetViewController) {
		self.targetViewController.view.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
		[self.targetViewController.view tintColorDidChange];
		[self willMoveToParentViewController:nil];
		[self removeFromParentViewController];
	}
	else {
		self.keyWindow.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
		[self.keyWindow tintColorDidChange];
	}
	[self.animator removeAllBehaviors];
	[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	if ([self.delegate respondsToSelector:@selector(mediaFocusViewControllerDidDisappear:)]) {
		[self.delegate mediaFocusViewControllerDidDisappear:self];
	}
}

#pragma mark - Gesture Methods

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)gestureRecognizer {
	
	CGFloat pinchScale = gestureRecognizer.scale;
	//CGFloat scaleDiff = pinchScale - _lastPinchScale;
	CGFloat scale = 1.0f - (_lastPinchScale - pinchScale);
	
	if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
		_lastPinchScale = 1.0f;
	}
	else if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
		self.imageView.transform = CGAffineTransformScale(self.imageView.transform, scale, scale);
		_lastPinchScale = pinchScale;
	}
	else if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
		CGFloat transformScale = self.imageView.transform.a;
		if (transformScale > _maxScale) {
			[UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
				self.imageView.transform = CGAffineTransformMakeScale(_maxScale, _maxScale);
			} completion:nil];
		}
		else if (transformScale < _minScale) {
			[UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
				self.imageView.transform = CGAffineTransformMakeScale(_minScale, _minScale);
			} completion:nil];
		}
        
		// adjust frame position if we need to
		[self adjustFrame];
		
		_lastPinchScale = 1.0f;
	}
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)gestureRecognizer {
	
	UIView *view = gestureRecognizer.view;
	CGPoint translation = [gestureRecognizer translationInView:self.view];
	CGPoint location = [gestureRecognizer locationInView:self.view];
	CGPoint boxLocation = [gestureRecognizer locationInView:self.imageView];
	CGFloat transformScale = self.imageView.transform.a;
	
	if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
		[self.animator removeBehavior:self.snapBehavior];
		[self.animator removeBehavior:self.pushBehavior];
		
		if (transformScale == _minScale) {
			UIOffset centerOffset = UIOffsetMake(boxLocation.x - CGRectGetMidX(self.imageView.bounds), boxLocation.y - CGRectGetMidY(self.imageView.bounds));
			self.panAttachmentBehavior = [[UIAttachmentBehavior alloc] initWithItem:self.imageView offsetFromCenter:centerOffset attachedToAnchor:location];
			//self.panAttachmentBehavior.frequency = 0.0f;
			[self.animator addBehavior:self.panAttachmentBehavior];
			
			[self.animator addBehavior:self.itemBehavior];
		}
	}
	else if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
		if (transformScale > _minScale) {
			self.imageView.center = CGPointMake(view.center.x + translation.x, view.center.y + translation.y);
			[gestureRecognizer setTranslation:CGPointZero inView:self.view];
		}
		else {
			self.panAttachmentBehavior.anchorPoint = location;
		}
	}
	else if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
		[self.animator removeBehavior:self.panAttachmentBehavior];
		
		if (transformScale > _minScale) {
			[self adjustFrame];
		}
		else {
			// need to scale velocity values to tame down physics on the iPad
			CGFloat deviceScale = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 0.25f : 1.0f;
			CGPoint velocity = [gestureRecognizer velocityInView:self.view];
			CGFloat velocityAdjust = 10.0f * deviceScale;
			
			if (fabs(velocity.x / velocityAdjust) > __minimumVelocityRequiredForPush || fabs(velocity.y / velocityAdjust) > __minimumVelocityRequiredForPush) {
				//CGFloat angle = atan2f(velocity.y, velocity.x) * 180.0f / M_PI;
				
				// rotation direction is dependent upon which corner was pushed relative to the center of the view
				// when velocity.y is positive, pushes to the right of center rotate clockwise, left is counterclockwise
				CGFloat direction = (location.x < view.center.x) ? -1.0f : 1.0f;
				
				// when y component of velocity is negative, reverse direction
				if (velocity.y < 0) { direction *= -1; }
				
				// amount of angular velocity should be relative to how close to the edge of the view the force originated
				// angular velocity is reduced the closer to the center the force is applied
				// for angular velocity: positive = clockwise, negative = counterclockwise
				CGFloat angularVelocity = __angularVelocityFactor * (fabsf(CGRectGetWidth(self.imageView.frame) / 2.0 - boxLocation.x)) / (CGRectGetWidth(self.imageView.frame) / 2.0);
				
				// amount of angular velocity should also be relative to the push velocity, faster velocity gives more spin
				CGFloat pushVelocity = sqrtf(powf(velocity.x, 2.0f) + powf(velocity.y, 2.0f));
				angularVelocity *= (pushVelocity / 1000.0f);
				// apply device scale to angular velocity
				angularVelocity *= deviceScale;
                
				[self.itemBehavior addAngularVelocity:angularVelocity * direction forItem:self.imageView];
				[self.animator addBehavior:self.pushBehavior];
				self.pushBehavior.pushDirection = CGVectorMake((velocity.x / velocityAdjust) * __velocityFactor, (velocity.y / velocityAdjust) * __velocityFactor);
				self.pushBehavior.active = YES;
				
				// delay for dismissing is based on push velocity also
				CGFloat delay = 0.75f - (pushVelocity / 10000.0f);
				[self performSelector:@selector(dismissFromSwipeAway) withObject:nil afterDelay:delay * __velocityFactor];
			}
			else {
				[self returnToCenter];
			}
		}
	}
}

#pragma mark - UIGestureRecognizerDelegate Methods

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
	CGFloat transformScale = self.imageView.transform.a;
	return (transformScale > _minScale);
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[self.urlData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	[self.loadingView stopAnimating];
	[self.loadingView removeFromSuperview];
	
	if (self.urlData) {
		UIImage *image = [UIImage imageWithData:self.urlData];
		[self showImage:image fromView:self.fromView inViewController:self.targetViewController];
		
		if ([self.delegate respondsToSelector:@selector(mediaFocusViewController:didFinishLoadingImage:)]) {
			[self.delegate mediaFocusViewController:self didFinishLoadingImage:image];
		}
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	if ([self.delegate respondsToSelector:@selector(mediaFocusViewController:didFailLoadingImageWithError:)]) {
		[self.delegate mediaFocusViewController:self didFailLoadingImageWithError:error];
	}
}

#pragma mark - Orientation Helpers

- (void)deviceOrientationChanged:(NSNotification *)notification {
	NSLog(@"device orientation changed");
	UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
	if (_currentOrientation != orientation) {
		_currentOrientation = orientation;
		[self reposition];
	}
}

- (CGAffineTransform)transformForOrientation:(UIInterfaceOrientation)orientation {
	CGAffineTransform transform = CGAffineTransformIdentity;
	
	// calculate a rotation transform that matches the required orientation
	if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
		transform = CGAffineTransformMakeRotation(M_PI);
	}
	else if (orientation == UIInterfaceOrientationLandscapeLeft) {
		transform = CGAffineTransformMakeRotation(-M_PI_2);
	}
	else if (orientation == UIInterfaceOrientationLandscapeRight) {
		transform = CGAffineTransformMakeRotation(M_PI_2);
	}
	
	return transform;
}

- (void)reposition {
	CGAffineTransform baseTransform = [self transformForOrientation:_currentOrientation];
	
	// determine if the rotation we're about to undergo is 90 or 180 degrees
	CGAffineTransform t1 = self.imageView.transform;
	CGAffineTransform t2 = baseTransform;
	CGFloat dot = t1.a * t2.a + t1.c * t2.c;
	CGFloat n1 = sqrtf(t1.a * t1.a + t1.c * t1.c);
	CGFloat n2 = sqrtf(t2.a * t2.a + t2.c * t2.c);
	CGFloat rotationDelta = acosf(dot / (n1 * n2));
	BOOL isDoubleRotation = (rotationDelta > M_PI_2);
	
	// use the system rotation duration
	CGFloat duration = [UIApplication sharedApplication].statusBarOrientationAnimationDuration;
	// iPad lies about its rotation duration
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) { duration = 0.4; }
	
	// double the animation duration if we're rotation 180 degrees
	if (isDoubleRotation) { duration *= 2; }
	
	// if we haven't laid out the subviews yet, we don't want to animate rotation and position transforms
	if (_hasLaidOut) {
		[UIView animateWithDuration:duration animations:^{
			self.imageView.transform = CGAffineTransformConcat(self.imageView.transform, baseTransform);
		}];
	}
	else {
		self.imageView.transform = CGAffineTransformConcat(self.imageView.transform, baseTransform);
	}
}

#pragma mark -
#pragma mark Parallax Helpers

- (void)_setStatusBarHidden:(BOOL)hidden
{
    [[UIApplication sharedApplication] setStatusBarHidden:hidden withAnimation:UIStatusBarAnimationFade];
}

- (UIView *)_containerViewForWindow:(UIWindow *)window
{
    CGFloat extraWidth = window.frame.size.width - (window.frame.size.width * __shrinkScale) + 10.f;
    CGFloat extraHeight = window.frame.size.height - (window.frame.size.height * __shrinkScale) + 10.f;
    CGRect containerFrame = CGRectMake(0, 0, window.frame.size.width + extraWidth, window.frame.size.height + extraHeight);
    
    //create the container
    UIView *containerView = [[UIView alloc] initWithFrame:containerFrame];
    containerView.backgroundColor = [UIColor blackColor];
    
    //place the snapshot of the window on the container
    UIImage *snapshotImage = [window toImage];
    UIImageView *snapshotImageView = [[UIImageView alloc] initWithImage:snapshotImage];
    snapshotImageView.center = containerView.center;
    [containerView addSubview:snapshotImageView];
    
    containerView.center = window.center;
    
    return containerView;
}

- (UIImage *)_snapshotImageWithView:(UIView *)view;
{
    UIImage *snapshotImage;
    
    //take another snapshot of the result and either ...
    if ([UIDeviceHardware supportsBlur]) {
        //blur it (if supported)
        snapshotImage = [view toImage];
        snapshotImage = [snapshotImage applyBlurWithRadius:__blurRadius
                                                 tintColor:[UIColor colorWithWhite:0.f alpha:__blurTintColorAlpha]
                                     saturationDeltaFactor:__blurSaturationDeltaMask
                                                 maskImage:nil];
    } else {
        //darken it
        UIView *overlay = [[UIView alloc] initWithFrame:view.frame];
        overlay.backgroundColor = [UIColor colorWithWhite:0.f alpha:__overlayAlpha];
        [view addSubview:overlay];
        snapshotImage = [view toImage];
    }
    return snapshotImage;
}

- (UIImageView *)_snapshotImageViewWithSnapshotImage:(UIImage *)image withCenter:(CGPoint)center
{
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.center = center;
    imageView.alpha = 0.0;
    imageView.userInteractionEnabled = YES;
    return imageView;
}

- (UIImageView *)_borderedSnapshotImageViewForWindow:(UIWindow *)window
{
    UIView *containerView = [self _containerViewForWindow:window];
    UIImage *snapshotImage = [self _snapshotImageWithView:containerView];
    UIImageView *snapshotImageView = [self _snapshotImageViewWithSnapshotImage:snapshotImage withCenter:window.center];
    
    return snapshotImageView;
}

@end