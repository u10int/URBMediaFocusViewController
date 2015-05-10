//
//  ViewController.swift
//  URBMediaFocusViewControllerDemo-Swift
//
//  Created by Nicholas Shipes on 4/12/15.
//  Copyright (c) 2015 Urban10 Interactive, LLC. All rights reserved.
//

import UIKit

class ViewController: UIViewController, URBMediaFocusViewControllerDelegate, NSURLConnectionDataDelegate {
	
	var mediaFocusController: URBMediaFocusViewController?
	
	var thumbnailView: UIImageView?
	var remoteThumbnailView: UIImageView?
	var localThumbnailView: UIImageView?
	var panoramaThumbnailView: UIImageView?
	var verticalPanoramaThumbnailView: UIImageView?
	var animatedThumbnailView: UIImageView?
	
	var remoteData: NSMutableData?
	var connection: NSURLConnection?

	override func viewDidLoad() {
		super.viewDidLoad()
		
		if (self.respondsToSelector(Selector("edgesForExtendedLayout"))) {
			self.edgesForExtendedLayout = UIRectEdge.None
		}
		
		if (self.respondsToSelector(Selector("extendedLayoutIncludesOpaqueBars"))) {
			self.extendedLayoutIncludesOpaqueBars = true
		}
		
		self.mediaFocusController = URBMediaFocusViewController()
		if let focusController = self.mediaFocusController {
			focusController.delegate = self
//			focusController.shouldBlurBackground = false
//			focusController.parallaxEnabled = false
//			focusController.shouldDismissOnTap = false
//			focusController.shouldDismissOnImageTap = true
//			focusController.allowSwipeOnBackgroundView = false
		}

		self.thumbnailView = self.thumbnailViewWithOrigin(CGPointMake(20, 20))
		self.thumbnailView!.image = UIImage(named: "seattle01.jpg")
		
		var thumbView: UIImageView = self.thumbnailView!
		self.remoteThumbnailView = self.thumbnailViewWithOrigin(CGPointMake(CGRectGetMinX(thumbView.frame), CGRectGetMaxY(thumbView.frame) + 20))
		
		self.localThumbnailView = self.thumbnailViewWithOrigin(CGPointMake(CGRectGetMinX(thumbView.frame), CGRectGetMaxY(self.remoteThumbnailView!.frame) + 20))
		self.localThumbnailView!.image = UIImage(named: "raceforfood.jpg")
		
		self.panoramaThumbnailView = self.thumbnailViewWithOrigin(CGPointMake(CGRectGetMinX(thumbView.frame), CGRectGetMaxY(self.localThumbnailView!.frame) + 20))
		self.panoramaThumbnailView!.image = UIImage(named: "panorama.jpg")
		
		self.verticalPanoramaThumbnailView = self.thumbnailViewWithOrigin(CGPointMake(CGRectGetMaxX(thumbView.frame) + 30, CGRectGetMinY(thumbView.frame)))
		self.verticalPanoramaThumbnailView!.image = UIImage(named: "panorama_vert.jpg")
		
		self.animatedThumbnailView = self.thumbnailViewWithOrigin(CGPointMake(CGRectGetMaxX(thumbView.frame) + 30, CGRectGetMaxY(self.verticalPanoramaThumbnailView!.frame) + 30))
		self.animatedThumbnailView!.image = UIImage(named: "animated_thumb.jpg")
		
	}
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		
		if (self.remoteThumbnailView!.image == nil) {
			var remoteImageURL: NSURL = NSURL(string: "http://apollo.urban10.net/random/oiab/01_thumb.jpg")!
			var request: NSURLRequest = NSURLRequest(URL: remoteImageURL, cachePolicy: NSURLRequestCachePolicy.ReturnCacheDataElseLoad, timeoutInterval: 10)
			
			if (self.connection == nil) {
				self.connection = NSURLConnection(request: request, delegate: self, startImmediately: false)
			}
			self.remoteData = NSMutableData()
			self.connection!.start();
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	private func thumbnailViewWithOrigin(origin: CGPoint) -> UIImageView? {
		var imageView: UIImageView = UIImageView(frame: CGRectMake(origin.x, origin.y, 100.0, 100.0))
		imageView.backgroundColor = UIColor.darkGrayColor()
		imageView.contentMode = UIViewContentMode.ScaleAspectFill
		imageView.clipsToBounds = true
		imageView.userInteractionEnabled = true
		self.view.addSubview(imageView)
		
		self.addTapGestureToView(imageView)
		
		return imageView;
	}
	
	private func addTapGestureToView(view: UIView) {
		var tapRecognizer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "showFocusView:")
		tapRecognizer.numberOfTapsRequired = 1
		tapRecognizer.numberOfTouchesRequired = 1
		view.addGestureRecognizer(tapRecognizer)
	}
	
	func showFocusView(gestureRecognizer: UITapGestureRecognizer) {
		if (gestureRecognizer.view == self.localThumbnailView) {
			self.mediaFocusController?.showImage(UIImage(named: "raceforfood.jpg"), fromView: gestureRecognizer.view)
		}
		else if (gestureRecognizer.view == self.panoramaThumbnailView) {
			self.mediaFocusController?.showImage(UIImage(named: "panorama.jpg"), fromView: gestureRecognizer.view)
		}
		else if (gestureRecognizer.view == self.verticalPanoramaThumbnailView) {
			self.mediaFocusController?.showImage(UIImage(named: "panorama_vert.jpg"), fromView: gestureRecognizer.view)
		}
		else {
			var url: NSURL?;
			if (gestureRecognizer.view == self.remoteThumbnailView) {
				url = NSURL(string: "http://apollo.urban10.net/random/oiab/01.jpg")
			}
			else if (gestureRecognizer.view == self.localThumbnailView) {
				url = NSURL(string: "http://farm3.staticflickr.com/2109/5763011359_f371b21fc9_b.jpg")
			}
			else if (gestureRecognizer.view == self.animatedThumbnailView) {
				url = NSURL(string: "http://s3-ec.buzzfed.com/static/enhanced/webdr02/2012/12/19/13/anigif_enhanced-buzz-8195-1355941233-2.gif")
			}
			else {
				url = NSURL(string: "http://farm3.staticflickr.com/2109/5763011359_f371b21fc9_b.jpg")
			}
			
			self.mediaFocusController?.showImageFromURL(url, fromView: gestureRecognizer.view)
			
			// alternative method adding the focus view to this controller's view
			//self.mediaFocusController?.showImageFromURL(url, fromView: gestureRecognizer.view, inViewController: self)
		}
	}
	
	// URBMediaFocusViewControllerDelegate
	
	func mediaFocusViewControllerDidAppear(mediaFocusViewController: URBMediaFocusViewController!) {
		println("focus view appeared")
	}
	
	func mediaFocusViewControllerDidDisappear(mediaFocusViewController: URBMediaFocusViewController!) {
		println("focus view disappeared")
	}
	
	func mediaFocusViewController(mediaFocusViewController: URBMediaFocusViewController!, didFinishLoadingImage image: UIImage!) {
		println("focus view finished loading image")
	}
	
	func mediaFocusViewController(mediaFocusViewController: URBMediaFocusViewController!, didFailLoadingImageWithError error: NSError!) {
		println("focus view failed loading image: \(error)")
	}
	
	// NSURLConnectionDelegate
	
	func connection(connection: NSURLConnection, didReceiveData data: NSData) {
		self.remoteData?.appendData(data)
	}
	
	func connectionDidFinishLoading(connection: NSURLConnection) {
		if let imageData = self.remoteData {
			self.remoteThumbnailView?.image = UIImage(data: imageData)
		}
	}

}

