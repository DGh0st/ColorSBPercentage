#import <Preferences/PSViewController.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <MessageUI/MFMailComposeViewController.h>

@interface PSListController (BBRPrivate)
-(BOOL)containsSpecifier:(id)arg1;
@end

@interface CSBPRootListController : PSListController <MFMailComposeViewControllerDelegate> {
	BOOL _isCurrentlyDisablingSpecifiers;
	PSSpecifier *_customSolidColor;
	PSSpecifier *_customGradientColor;
}
@end
