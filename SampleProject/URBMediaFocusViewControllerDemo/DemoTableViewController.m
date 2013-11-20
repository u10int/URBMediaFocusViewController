//
//  DemoTableViewController.m
//  URBMediaFocusViewControllerDemo
//
//  Created by Nicholas Shipes on 11/3/13.
//  Copyright (c) 2013 Urban10 Interactive. All rights reserved.
//

#import "DemoTableViewController.h"
#import "DemoTableViewCell.h"

@interface DemoTableViewController ()

@property (nonatomic, strong) URBMediaFocusViewController *mediaFocusController;

@end

static NSString *CellIdentifier = @"Cell";

@implementation DemoTableViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.mediaFocusController = [[URBMediaFocusViewController alloc] initWithNibName:nil bundle:nil];
	
	
	[self.tableView registerClass:[DemoTableViewCell class] forCellReuseIdentifier:CellIdentifier];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
	cell.textLabel.text = [NSString stringWithFormat:@"Test Row %i", indexPath.row];
    
    return cell;
}

@end
