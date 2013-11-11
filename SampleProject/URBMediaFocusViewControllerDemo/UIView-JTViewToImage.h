/*
 * This file is part of the http://ioscodesnippet.com
 * http://ioscodesnippet.com/2011/08/25/rendering-any-uiviews-into-uiimage-in-one-line/
 *
 * (c) Jamz Tang <jamz@jamztang.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <UIKit/UIKit.h>

@interface UIView (JTViewToImage)

// - [UIImage toImage]
//
// Follow device screen scaling. If your view is sized 320 * 480, 
// it renders 320 * 480 on non-retina display devices, 
// and 640 * 960 on retina display devices
// Use this option for making high resolution view elements snapshots to display on retina devices
- (UIImage *)toImage;

// - [UIImage toImageWithScale]
//
// Force rendering in a given scale. Commonly used will be "1".
// Good for output or saving a static image with the exact size of the view element.
- (UIImage *)toImageWithScale:(CGFloat)scale;

// - [UIImage toImageWithScale:legacy:]
//
// Set legacy to YES to force use the old API instead of
// iOS 7's drawViewHierarchyInRect:afterScreenUpdates: API
- (UIImage *)toImageWithScale:(CGFloat)scale legacy:(BOOL)legacy;

@end

