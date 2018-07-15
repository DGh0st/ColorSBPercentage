#include "CSBPRootListController.h"

@implementation CSBPRootListController

- (id)initForContentSize:(CGSize)size {
	self = [super initForContentSize:size];
	if (self != nil) {
		UIImageView *iconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon" inBundle:[self bundle] compatibleWithTraitCollection:nil]];
		iconView.contentMode = UIViewContentModeScaleAspectFit;
		iconView.frame = CGRectMake(0, 0, 29, 29);
		[self.navigationItem setTitleView:iconView];
		[iconView release];
		UIBarButtonItem *respringItem = [[UIBarButtonItem alloc] initWithTitle:@"Respring" style:UIBarButtonItemStyleDone target:self action:@selector(respring)];
		[self.navigationItem setRightBarButtonItem:respringItem animated:NO];
		self.navigationItem.rightBarButtonItem.enabled = NO;
		[respringItem release];

		_isCurrentlyDisablingSpecifiers = NO;
	}
	return self;
}

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];
	}

	return _specifiers;
}

- (void)email {
	if ([MFMailComposeViewController canSendMail]) {
		MFMailComposeViewController *email = [[MFMailComposeViewController alloc] initWithNibName:nil bundle:nil];
		[email setSubject:@"ColorSBPercentage Support"];
		[email setToRecipients:[NSArray arrayWithObjects:@"deeppwnage@yahoo.com", nil]];
		[email addAttachmentData:[NSData dataWithContentsOfFile:@"/var/mobile/Library/Preferences/com.dgh0st.colorsbpercentage.plist"] mimeType:@"application/xml" fileName:@"Prefs.plist"];
		[email addAttachmentData:[NSData dataWithContentsOfFile:@"/var/mobile/Library/Preferences/com.dgh0st.colorsbpercentage.color.plist"] mimeType:@"application/xml" fileName:@"Colors.plist"];
		#pragma GCC diagnostic push
		#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
		system("/usr/bin/dpkg -l > /tmp/dpkgl.log");
		#pragma GCC diagnostic pop
		[email addAttachmentData:[NSData dataWithContentsOfFile:@"/tmp/dpkgl.log"] mimeType:@"text/plain" fileName:@"dpkgl.txt"];
		[self.navigationController presentViewController:email animated:YES completion:nil];
		[email setMailComposeDelegate:self];
		[email release];
	}
}

- (void)mailComposeController:(id)controller didFinishWithResult:(MFMailComposeResult)result error:(id)error {
    [self dismissViewControllerAnimated:YES completion: nil];
}

- (void)donate {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://paypal.me/DGhost"]];
}

- (void)follow {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://mobile.twitter.com/D_Gh0st"]];
}

- (void)respring {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"ColorSBPercentage" message:@"Are you sure you want to respring?" preferredStyle:UIAlertControllerStyleAlert];

	UIAlertAction *respringAction = [UIAlertAction actionWithTitle:@"Yes, Respring" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.dgh0st.colorsbpercentage/respring"), NULL, NULL, YES);
	}];

	UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
		[self dismissViewControllerAnimated:YES completion:nil];
	}];

	[alert addAction:respringAction];
	[alert addAction:cancelAction];

	[self presentViewController:alert animated:YES completion:nil];
}

- (void)setPreferenceValue:(id)value specifier:(id)specifier {
	[super setPreferenceValue:value specifier:specifier];

	if (!_isCurrentlyDisablingSpecifiers) {
		[self removeSpecifiersIfNeededAnimated:[NSNumber numberWithBool:YES]];
		self.navigationItem.rightBarButtonItem.enabled = YES;
	}
}

- (void)viewDidLoad {
	[super viewDidLoad];

	[self removeSpecifiersIfNeededAnimated:[NSNumber numberWithBool:NO]];
}

-(void)dealloc {
	[self clearPreviousSpecifiers];

	[super dealloc];
}

- (void)reloadSpecifiers {
	[super reloadSpecifiers];

	[self removeSpecifiersIfNeededAnimated:[NSNumber numberWithBool:NO]];
}

- (void)clearPreviousSpecifiers {
	if (_customSolidColor != nil)
		[_customSolidColor release];
	_customSolidColor = nil;
	if (_customGradientColor != nil)
		[_customGradientColor release];
	_customGradientColor = nil;
}

- (void)removeSpecifiersIfNeededAnimated:(NSNumber *)animatedObject {
	BOOL animated = [animatedObject boolValue];

	_isCurrentlyDisablingSpecifiers = YES;

	PSSpecifier *customSolidColor = [self specifierForID:@"CustomSolidPercentageColor"];
	PSSpecifier *customGradientColor = [self specifierForID:@"CustomGradientPercentageColor"];

	// Add/Remove the colors sub-preferences
	PSSpecifier *colorSpecifier = [self specifierForID:@"BatteryColor"];
	PSSpecifier *barColor = [self specifierForID:@"BarColor"];
	id colorStyleValue = [self readPreferenceValue:colorSpecifier];
	if ([colorStyleValue intValue] == 0) {
		if (customSolidColor != nil && [self containsSpecifier:customSolidColor]) {
			_customSolidColor = [customSolidColor retain];
			[self removeSpecifier:_customSolidColor animated:animated];
		}
		if (customGradientColor != nil && [self containsSpecifier:customGradientColor]) {
			_customGradientColor = [customGradientColor retain];
			[self removeSpecifier:_customGradientColor animated:animated];
		}
		[barColor setProperty:@"" forKey:@"footerText"];
		[self reloadSpecifier:barColor animated:animated];
	} else if ([colorStyleValue intValue] == 1) {
		if (_customSolidColor != nil && ![self containsSpecifier:_customSolidColor]) {
			if (animated) {
				if (customGradientColor != nil && [self containsSpecifier:customGradientColor]) {
					_customGradientColor = [customGradientColor retain];
					[self replaceContiguousSpecifiers:[NSArray arrayWithObjects:_customGradientColor, nil] withSpecifiers:[NSArray arrayWithObjects:_customSolidColor, nil] animated:YES];
				} else {
					[self insertSpecifier:_customSolidColor afterSpecifier:colorSpecifier animated:YES];
				}
			} else {
				[self insertSpecifier:_customSolidColor afterSpecifier:colorSpecifier animated:animated];
			}
			[_customSolidColor release];
			_customSolidColor = nil;
		} else {
			if (customGradientColor != nil && [self containsSpecifier:customGradientColor]) {
				_customGradientColor = [customGradientColor retain];
				[self removeSpecifier:_customGradientColor animated:animated];
			}
		}
		[barColor setProperty:@"Set the custom solid color for the percentage" forKey:@"footerText"];
		[self reloadSpecifier:barColor animated:animated];
	} else if ([colorStyleValue intValue] == 2) {
		if (_customGradientColor != nil && ![self containsSpecifier:_customGradientColor]) {
			if (animated) {
				if (customSolidColor != nil && [self containsSpecifier:customSolidColor]) {
					_customSolidColor = [customSolidColor retain];
					[self replaceContiguousSpecifiers:[NSArray arrayWithObjects:_customSolidColor, nil] withSpecifiers:[NSArray arrayWithObjects:_customGradientColor, nil] animated:YES];
				} else {
					[self insertSpecifier:_customGradientColor afterSpecifier:colorSpecifier animated:YES];
				}
			} else {
				[self insertSpecifier:_customGradientColor afterSpecifier:colorSpecifier animated:animated];
			}
			[_customGradientColor release];
			_customGradientColor = nil;
		} else {
			if (customSolidColor != nil && [self containsSpecifier:customSolidColor]) {
				_customSolidColor = [customSolidColor retain];
				[self removeSpecifier:_customSolidColor animated:animated];
			}
		}
		[barColor setProperty:@"Set the custom gradient color for the percentage" forKey:@"footerText"];
		[self reloadSpecifier:barColor animated:animated];
	}

	_isCurrentlyDisablingSpecifiers = NO;
}


@end
