//
//  DemoTableViewCell.m
//  URBMediaFocusViewControllerDemo
//
//  Created by Nicholas Shipes on 11/3/13.
//  Copyright (c) 2013 Urban10 Interactive. All rights reserved.
//

#import "DemoTableViewCell.h"

@interface DemoTableViewCell ()

@property (nonatomic, strong) UIImageView *thumbnailView;

@end

@implementation DemoTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
		self.thumbnailView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 40.0, 40.0)];
		self.thumbnailView.backgroundColor = [UIColor darkGrayColor];
		[self addSubview:self.thumbnailView];
		
		//UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleThumbnailTap:)];
		
    }
    return self;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	self.thumbnailView.frame = CGRectMake(CGRectGetWidth(self.frame) - CGRectGetWidth(self.thumbnailView.frame) - 5.0f,
										  CGRectGetMidY(self.bounds) - CGRectGetHeight(self.thumbnailView.frame) / 2.0,
										  CGRectGetWidth(self.thumbnailView.frame), CGRectGetHeight(self.thumbnailView.frame));
}

@end
