//
//  URBMediaFocusViewController.m
//  URBMediaFocusViewControllerDemo
//
//  Created by Nicholas Shipes on 11/3/13.
//  Copyright (c) 2013 Urban10 Interactive. All rights reserved.
//

#import "URBMediaFocusViewController.h"

static const CGFloat __animationDuration = 0.25f;		// the base duration for present/dismiss animations (except physics-related ones)
static const CGFloat __velocityFactor = 1.0f;			// affects how quickly the view is pushed out of the view
static const CGFloat __angularVelocityFactor = 15.0f;	// adjusts the amount of spin applied to the view during a push force, increases towards the view bounds

@interface URBMediaFocusViewController ()

@property (nonatomic, strong) UIView *targetView;
@property (nonatomic, strong) UIView *fromView;

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

@property (nonatomic, strong) UIActivityIndicatorView *loadingView;
@property (nonatomic, strong) NSURLConnection *urlConnection;
@property (nonatomic, strong) NSMutableData *urlData;

@end

@implementation URBMediaFocusViewController {
	CGRect _originalFrame;
	CGFloat _minScale;
	CGFloat _maxScale;
	CGFloat _lastPinchScale;
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
	
	// UIDynamics stuff
	self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
	
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

- (void)showImage:(UIImage *)image fromView:(UIView *)fromView inView:(UIView *)targetView {
	self.keyWindow.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
	[self.keyWindow tintColorDidChange];
	[self.keyWindow addSubview:self.view];
	
	self.targetView = targetView;
	self.fromView = fromView;
	
	CGRect fromRect = [self.view convertRect:fromView.frame fromView:targetView];
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
	self.imageView.frame = [self.view convertRect:fromView.frame fromView:nil];
	_originalFrame = targetRect;
		
	if (scale < 1.0f) {
		_minScale = 1.0f;
		_maxScale = (targetSize.width > targetSize.height) ? image.size.width / targetSize.width : image.size.height / targetSize.height;
	}
	else {
		_minScale = scale;
		_maxScale = 1.0f;
	}
	_lastPinchScale = 1.0f;
	
	[UIView animateWithDuration:__animationDuration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
		self.backgroundView.alpha = 1.0f;
		self.imageView.alpha = 1.0f;
		self.imageView.frame = targetRect;
	} completion:^(BOOL finished) {
		[self.imageView addGestureRecognizer:self.pinchRecognizer];
	}];
}

- (void)showImageFromURL:(NSURL *)url fromView:(UIView *)fromView inView:(UIView *)targetView {
	self.targetView = targetView;
	self.fromView = fromView;
	
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

- (void)dismiss:(BOOL)animated {
	[UIView animateWithDuration:__animationDuration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
		self.backgroundView.alpha = 0.0f;
	} completion:^(BOOL finished) {
		self.keyWindow.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
		[self.keyWindow tintColorDidChange];
		[self.view removeFromSuperview];
		
		[self cleanup];
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
	[self.animator removeAllBehaviors];
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
			CGPoint velocity = [gestureRecognizer velocityInView:self.view];
			//NSLog(@"gesture ended: velocity = (%f, %f)... vector: (%f, %f)", velocity.x, velocity.y, velocity.x / 20.0f, velocity.y / 20.0f);
			
			CGFloat velocityAdjust = 12.0f;
			CGFloat minVelocityForFlick = 50.0f;
			if (fabs(velocity.x / velocityAdjust) > minVelocityForFlick || fabs(velocity.y / velocityAdjust) > minVelocityForFlick) {
				//CGFloat angle = atan2f(velocity.y, velocity.x) * 180.0f / M_PI;
				
				// when velocity value is position, gesture went right
				// for angular velocity: positive = clockwise, negative = counterclockwise
				CGFloat direction = (velocity.x > 0) ? -1.0f : 1.0f;
				if (velocity.y < 0 && direction > 0) {
					direction = -1.0f;
				}
				else if (velocity.y < 0 && direction < 0) {
					direction = 1.0f;
				}
				//NSLog(@"velocity.x=%f, velocity.y=%f: (%@, %@) - direction=%f", velocity.x, velocity.y, (velocity.x < 0 ? @"-" : @"+"), (velocity.y < 0 ? @"-" : @"+"), direction);
				//NSLog(@"angle=%f", angle);
				// amount of angular velocity should be relative to how close to the edge of the view the force originated
				// angular velocity is reduced the closer to the center the force is applied
				CGFloat angularVelocity = __angularVelocityFactor * (fabsf(CGRectGetWidth(self.imageView.frame) / 2.0 - boxLocation.x)) / (CGRectGetWidth(self.imageView.frame) / 2.0);
				
				[self.itemBehavior addAngularVelocity:angularVelocity * direction forItem:self.imageView];
				[self.animator addBehavior:self.pushBehavior];
				self.pushBehavior.pushDirection = CGVectorMake((velocity.x / velocityAdjust) * __velocityFactor, (velocity.y / velocityAdjust) * __velocityFactor);
				self.pushBehavior.active = YES;
				
				[self performSelector:@selector(dismiss:) withObject:nil afterDelay:(0.5 * __velocityFactor)];
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
		[self showImage:image fromView:self.fromView inView:self.targetView];
		
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

@end
