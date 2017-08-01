//
//  FYPlaybackViewController+NavigationBar.m
//  FYCachedURLAssetExample
//
//  Created by Viktor Naryshkin on 7/28/17.
//  Copyright © 2017 Viktor Naryshkin. All rights reserved.
//

#import "FYPlaybackViewController+NavigationBar.h"

@implementation FYPlaybackViewController (NavigationBar)

- (void)navigationBarStyleForPlayback {
	[self.navigationController.navigationBar setBackgroundImage:[UIImage new]
												  forBarMetrics:UIBarMetricsDefault];
	
	self.navigationController.navigationBar.shadowImage = [UIImage new];
	self.navigationController.navigationBar.backgroundColor = [UIColor clearColor];
	
	UIImage* backImage = [UIImage imageNamed:@"back_icon"];
	
	UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithImage:backImage
																   style:UIBarButtonItemStylePlain
																  target:self.navigationController
																  action:@selector(popViewControllerAnimated:)];
	
	UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
																					target:nil
																					action:nil];
	negativeSpacer.width = -15;
	[self.navigationItem setLeftBarButtonItems:[NSArray arrayWithObjects:negativeSpacer, backButton, nil] animated:NO];
}

@end
