//
// Tweak.xm
// ProudLock2
//
// Copyright © 2019 FESTIVAL Development
// All Rights reserved
//

#import "Tweak.h"

%group MGGetBoolAnswer
extern "C" Boolean MGGetBoolAnswer(CFStringRef);
%hookf(Boolean, MGGetBoolAnswer, CFStringRef key) {
#define keyy(key_) CFEqual(key, CFSTR(key_))
    if (keyy("z5G/N9jcMdgPm8UegLwbKg") || keyy("IsEmulatedDevice"))
        return YES;
    return %orig;
}
%end

static CGFloat offset = 0;

%hook SBDashBoardViewController
- (void)loadView {
	if (%c(JPWeatherManager) != nil) {
		%orig;
		return;
	}
	
	CGFloat screenWidth = UIScreen.mainScreen.bounds.size.width;
	if (screenWidth <= 320) {
		offset = 20;
	} else if (screenWidth <= 375) {
		offset = 35;
	} else if (screenWidth <= 414) {
		offset = 28;
	}
	
	%orig;
}

- (void)handleBiometricEvent:(unsigned long long)arg1 {
	%orig;

	if (arg1 == kBiometricEventMesaSuccess) {
		SBDashBoardMesaUnlockBehaviorConfiguration* unlockBehavior = MSHookIvar<SBDashBoardMesaUnlockBehaviorConfiguration*>(self, "_mesaUnlockBehaviorConfiguration");
		if ([unlockBehavior _isAccessibilityRestingUnlockPreferenceEnabled]) {
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
				[[%c(SBLockScreenManager) sharedInstance] _finishUIUnlockFromSource:12 withOptions:nil];
			});
		}
	}
}
%end    // %hook SBDashBoardViewController

%hook SBUIProudLockIconView
- (void)setFrame:(CGRect)frame {
	if (!%c(NotchWindow)) {
		%orig;
		return;
	}

	%orig(CGRectSetY(frame, frame.origin.y + offset));
}
%end

%hook SBUICAPackageView
- (id)initWithPackageName:(id)arg1 inBundle:(id)arg2 {
	return %orig(arg1, [NSBundle bundleWithPath:@"/Library/Application Support/ProudLock2"]);
}
%end	// %hook SBUICAPackageView

%hook SBFLockScreenDateView
- (void)layoutSubviews {
	%orig;
	
	if (%c(JPWeatherManager) != nil) {
		return;
	}

	UIView* timeView = MSHookIvar<UIView*>(self, "_timeLabel");
	UIView* dateSubtitleView = MSHookIvar<UIView*>(self, "_dateSubtitleView");
	UIView* customSubtitleView = MSHookIvar<UIView*>(self, "_customSubtitleView");
	
	[timeView setFrame:CGRectSetY(timeView.frame, timeView.frame.origin.y + offset)];
	[dateSubtitleView setFrame:CGRectSetY(dateSubtitleView.frame, dateSubtitleView.frame.origin.y + offset)];
	[customSubtitleView setFrame:CGRectSetY(customSubtitleView.frame, customSubtitleView.frame.origin.y + offset)];
}
%end	// %hook SBFLockScreenDateView

%hook SBUIBiometricResource
- (id)init {
	id r = %orig;
	
	MSHookIvar<BOOL>(r, "_hasMesaHardware") = NO;
	MSHookIvar<BOOL>(r, "_hasPearlHardware") = YES;
	
	return r;
}
%end	// %hook SBUIBiometricResource

%hook PKGlyphView
- (void)setHidden:(BOOL)arg1 {
	if ([self.superview isKindOfClass:%c(SBUIPasscodeBiometricAuthenticationView)]) {
		%orig(NO);
		return;
	}
	
	%orig;
}

- (BOOL)hidden {
	if ([self.superview isKindOfClass:%c(SBUIPasscodeBiometricAuthenticationView)]) {
		return NO;
	}
	
	return %orig;
}
%end	// %hook PKGlyphView

%hook NCNotificationListCollectionView
- (void)setFrame:(CGRect)frame {
	%orig(CGRectSetY(frame, frame.origin.y + offset));
}
%end	// %hook NCNotificationListCollectionView

%hook SBDashBoardAdjunctListView
- (void)setFrame:(CGRect)frame {
	%orig(CGRectSetY(frame, frame.origin.y + offset));
}
%end	// %hook SBDashBoardAdjunctListView



%ctor {
		%init(MGGetBoolAnswer);
		%init();
	}
