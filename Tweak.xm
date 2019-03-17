#import "UIImage+Tint.h"
#import "PercentageColorPrefs.h"
#import <libcolorpicker.h>

// http://developer.limneos.net/index.php?ios=10.2&framework=UIKit.framework&header=UIKit-Structs.h
typedef struct {
	BOOL itemIsEnabled[34];
	char timeString[64];
	int gsmSignalStrengthRaw;
	int gsmSignalStrengthBars;
	char serviceString[100];
	char serviceCrossfadeString[100];
	char serviceImages[2][100];
	char operatorDirectory[1024];
	unsigned serviceContentType;
	int wifiSignalStrengthRaw;
	int wifiSignalStrengthBars;
	unsigned dataNetworkType;
	int batteryCapacity;
	unsigned batteryState;
	char batteryDetailString[150];
	int bluetoothBatteryCapacity;
	int thermalColor;
	unsigned thermalSunlightMode : 1;
	unsigned slowActivity : 1;
	unsigned syncActivity : 1;
	char activityDisplayId[256];
	unsigned bluetoothConnected : 1;
	unsigned displayRawGSMSignal : 1;
	unsigned displayRawWifiSignal : 1;
	unsigned locationIconType : 1;
	unsigned quietModeInactive : 1;
	unsigned tetheringConnectionCount;
	unsigned batterySaverModeActive : 1;
	unsigned deviceIsRTL : 1;
	unsigned lock : 1;
	char breadcrumbTitle[256];
	char breadcrumbSecondaryTitle[256];
	char personName[100];
	char returnToAppBundleIdentifier[100];
	unsigned electronicTollCollectionAvailable : 1;
	unsigned wifiLinkWarning : 1;
} SCD_Struct_UI72;

@interface UIStatusBarComposedData : NSObject
@property (nonatomic,readonly) SCD_Struct_UI72 *rawData;
@end

@interface UIStatusBarForegroundStyleAttributes : NSObject
-(id)_batteryColorForCapacity:(NSInteger)arg1 lowCapacity:(NSInteger)arg2 style:(NSUInteger)arg3;
@end

@interface UIStatusBarBatteryPercentItemView : UIView
@property (nonatomic, retain) UIStatusBarComposedData *rawData;
-(CGFloat)updateContentsAndWidth;
-(UIStatusBarForegroundStyleAttributes *)foregroundStyle;
@end

@interface _UILegibilityImageSet : NSObject
@property (nonatomic, retain) UIImage *image;
@end

@interface UIStatusBar : UIView
+(NSInteger)lowBatteryLevel;
@end

@interface FBSystemService
+(id)sharedInstance;
-(void)exitAndRelaunch:(BOOL)arg1;
@end

// battery styles used by apple
#define kNormalBatteryStyle 0
#define kChargingBatteryStyle 1
#define kLowPowerModeBatteryStyle 2
#define kLowPowerModeAndChargingStyle 3

#define kIdentifier @"com.dgh0st.colorsbpercentage"
#define kSettingsPath @"/var/mobile/Library/Preferences/com.dgh0st.colorsbpercentage.plist"
#define kSettingsChangedNotification (CFStringRef)@"com.dgh0st.colorsbpercentage/settingschanged"
#define kColorChangedNotification (CFStringRef)@"com.dgh0st.colorsbpercentage/colorchanged"
#define kRespringNotification (CFStringRef)@"com.dgh0st.colorsbpercentage/respring"

typedef enum BatteryColorStyle : NSInteger {
	kMatchBatteryColor = 0,
	kSolid,
	kGradient
} BatteryColorStyle;

static BOOL isEnabled = YES;
static BatteryColorStyle batteryColorStyle = kSolid;
static BOOL isGradientLowPowerEnabled = NO;
static BOOL isGradientChargingEnabled = NO;

%hook UIStatusBarBatteryPercentItemView
%property (nonatomic, retain) UIStatusBarComposedData *rawData;

-(BOOL)updateForNewData:(UIStatusBarComposedData *)arg1 actions:(NSInteger)arg2 {
	BOOL shouldUpdate = NO;
	if (batteryColorStyle == kGradient && !isGradientLowPowerEnabled && !isGradientChargingEnabled)
		shouldUpdate = NO; // don't need to force update because user doesn't care
	else if (self.rawData == nil || self.rawData.rawData->batteryState != arg1.rawData->batteryState || self.rawData.rawData->batterySaverModeActive != arg1.rawData->batterySaverModeActive)
		shouldUpdate = YES;
	self.rawData = arg1;
	BOOL result = %orig;
	if (shouldUpdate && !result)
		[self updateContentsAndWidth]; // force update the view
	return result;
}

-(_UILegibilityImageSet *)contentsImage {
	NSInteger capacity = self.rawData.rawData->batteryCapacity;
	NSInteger lowCapacity = [%c(UIStatusBar) lowBatteryLevel];
	NSInteger state = self.rawData.rawData->batteryState;
	BOOL isBatterySaverModeActive = self.rawData.rawData->batterySaverModeActive;
	NSUInteger style = isBatterySaverModeActive ? kLowPowerModeBatteryStyle : state;
	_UILegibilityImageSet *result = %orig;
	if (result != nil && result.image != nil) {
		UIColor *newColor;
		if (batteryColorStyle == kMatchBatteryColor) {
			UIStatusBarForegroundStyleAttributes *foregroundStyle = [self foregroundStyle];
			newColor = [foregroundStyle _batteryColorForCapacity:capacity lowCapacity:lowCapacity style:style];
		} else {
			NSString *color;
			PercentageColorPrefs *colorPrefs = [PercentageColorPrefs sharedInstance];
			if (batteryColorStyle == kSolid) {
				if (isBatterySaverModeActive) {
					color = colorPrefs.solidLowPowerModeColor;
				} else if (state == kChargingBatteryStyle) {
					color = colorPrefs.solidChargingColor;
				} else if (capacity <= lowCapacity) {
					color = colorPrefs.solidLessThan20Color;
				} else {
					color = colorPrefs.solidGreaterThan20Color;
				}
			} else {
				if (isGradientLowPowerEnabled && isBatterySaverModeActive) {
					color = colorPrefs.gradientLowPowerModeColor;
				} else if (isGradientChargingEnabled && state == kChargingBatteryStyle) {
					color = colorPrefs.gradientChargingColor;
				} else  {
					NSInteger offset = capacity / 5;
					if (offset < 0)
						offset = 0;
					else if (offset > [colorPrefs.gradientColor count])
						offset = [colorPrefs.gradientColor count] - 1;
					color = [colorPrefs.gradientColor objectAtIndex:offset];
				}
			}
			newColor = [LCPParseColorString(color, color) retain];
		}
		result.image = [result.image tintedImageWithColor:newColor];
		[newColor release];
	}
	return result;
}
%end

static void reloadPrefs() {
	CFPreferencesAppSynchronize((CFStringRef)kIdentifier);

	NSDictionary *prefs = nil;
	if ([NSHomeDirectory() isEqualToString:@"/var/mobile"]) {
		CFArrayRef keyList = CFPreferencesCopyKeyList((CFStringRef)kIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		if (keyList != nil) {
			prefs = (NSDictionary *)CFPreferencesCopyMultiple(keyList, (CFStringRef)kIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
			if (prefs == nil)
				prefs = [NSDictionary dictionary];
			CFRelease(keyList);
		}
	}

	// needed to do this for photos app (it doesn't seem to create a copy of prefs)
	if (prefs == nil) {
		prefs = [[NSDictionary alloc] initWithContentsOfFile:kSettingsPath];
	}

	isEnabled = [prefs objectForKey:@"isEnabled"] ? [[prefs objectForKey:@"isEnabled"] boolValue] : YES;

	batteryColorStyle = [prefs objectForKey:@"batteryColorStyle"] ? (BatteryColorStyle)[[prefs objectForKey:@"batteryColorStyle"] intValue] : kSolid;
	isGradientLowPowerEnabled = [prefs objectForKey:@"isGradientLowPowerEnabled"] ? [[prefs objectForKey:@"isGradientLowPowerEnabled"] boolValue] : NO;
	isGradientChargingEnabled = [prefs objectForKey:@"isGradientChargingEnabled"] ? [[prefs objectForKey:@"isGradientChargingEnabled"] boolValue] : NO;

	[prefs release];
}

static void reloadColorPrefs() {
	[[PercentageColorPrefs sharedInstance] updatePreferences];
}

static void respringDevice() {
	[[%c(FBSystemService) sharedInstance] exitAndRelaunch:YES];
}

%dtor {
	// becauses Amazon app generates crashes for some reason when launching
	if (![[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.amazon.Amazon"]) {
		CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, kSettingsChangedNotification, NULL);
		CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, kColorChangedNotification, NULL);
		CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, kRespringNotification, NULL);
	}
}

%ctor {
	reloadPrefs();
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reloadPrefs, kSettingsChangedNotification, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reloadColorPrefs, kColorChangedNotification, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);

	NSArray *args = [[NSProcessInfo processInfo] arguments];
	if (args != nil && args.count != 0) {
		NSString *execPath = args[0];
		if (execPath != nil) {
			BOOL isSpringBoard = [[execPath lastPathComponent] isEqualToString:@"SpringBoard"];
			BOOL isApplication = [execPath rangeOfString:@"/Application"].location != NSNotFound;
			if (isSpringBoard || isApplication)
				%init();
			if (isSpringBoard)
				CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)respringDevice, kRespringNotification, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
		}
	}
}