/*
 * This file is part of the http://ioscodesnippet.com
 * http://ioscodesnippet.com/2011/08/25/rendering-any-uiviews-into-uiimage-in-one-line/
 *
 * (c) Jamz Tang <jamz@jamztang.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIView-JTViewToImage.h"
#import <QuartzCore/QuartzCore.h>

@implementation UIView (JTViewToImage)

static BOOL _supportDrawViewHierarchyInRect;

+ (void)load {
    if ([self instancesRespondToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
        _supportDrawViewHierarchyInRect = YES;
    } else {
        _supportDrawViewHierarchyInRect = NO;
    }
}

- (UIImage *)toImage {
    return [self toImageWithScale:0];
}

- (UIImage *)toImageWithScale:(CGFloat)scale {
    UIImage *copied = [self toImageWithScale:scale legacy:NO];
    return copied;
}

- (UIImage *)toImageWithScale:(CGFloat)scale legacy:(BOOL)legacy {
    // If scale is 0, it'll follows the screen scale for creating the bounds
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, scale);
    
    if (legacy || ! _supportDrawViewHierarchyInRect) {
        // - [CALayer renderInContext:] also renders subviews
        [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    } else {
        [self drawViewHierarchyInRect:self.bounds
                   afterScreenUpdates:YES];
    }
    
    // Get the image out of the context
    UIImage *copied = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    // Return the result
    return copied;
}

@end
