#import <Preferences/PSViewController.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface PSListController (CSBPGPrivate)
-(void)clearCache;
-(BOOL)containsSpecifier:(id)arg1;
@end

@interface CSBPGradientColorListController : PSListController {
	BOOL _isCurrentlyDisablingSpecifiers;
	PSSpecifier *_gradientLowPowerModeColorSpecifier;
	PSSpecifier *_gradientChargingColorSpecifier;
}
@end