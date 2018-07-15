#include "CSBPSolidColorListController.h"

@implementation CSBPSolidColorListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"SolidColor" target:self] retain];
	}
	return _specifiers;
}

- (void)viewWillAppear:(BOOL)animated {
	[self clearCache];
	[self reload];
	[super viewWillAppear:animated];
}

@end