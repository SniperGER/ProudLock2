//
// Tweak.xm
// ProudLock2
//
// Copyright © 2019 FESTIVAL Development
// All Rights reserved
//

#import "Tweak.h"

// This code is taken from tonyk7's MGSpoof, which is a modified patchfinder64 from xerub
// I use this only to prevent hardcoding the address of MGCopyAnswer_internal

typedef unsigned long long addr_t;

static addr_t step64(const uint8_t *buf, addr_t start, size_t length, uint32_t what, uint32_t mask) {
	addr_t end = start + length;
	while (start < end) {
		uint32_t x = *(uint32_t *)(buf + start);
		if ((x & mask) == what) {
			return start;
		}
		start += 4;
	}
	return 0;
}

static addr_t find_branch64(const uint8_t *buf, addr_t start, size_t length) {
	return step64(buf, start, length, 0x14000000, 0xFC000000);
}

static addr_t follow_branch64(const uint8_t *buf, addr_t branch) {
	long long w;
	w = *(uint32_t *)(buf + branch) & 0x3FFFFFF;
	w <<= 64 - 26;
	w >>= 64 - 26 - 2;
	return branch + w;
}

extern "C" CFPropertyListRef MGCopyAnswer(CFStringRef prop);
static CFPropertyListRef (*orig_MGCopyAnswer_internal)(CFStringRef prop, uint32_t* outTypeCode);

CFPropertyListRef new_MGCopyAnswer_internal(CFStringRef key, uint32_t* outTypeCode) {
	
	CFPropertyListRef r = orig_MGCopyAnswer_internal(key, outTypeCode);
#define k(string) CFEqual(key, CFSTR(string))
	
	if (k("z5G/N9jcMdgPm8UegLwbKg") || k("IsEmulatedDevice")) {
		return (__bridge CFPropertyListRef)@YES;
	}
	
	return r;
}



static CGFloat offset = 0;

%hook SBDashBoardViewController
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
-(id)initWithFrame:(CGRect)arg1 {

    if (%c(JPWeatherManager) != nil) {
		%orig;
		return;
    }
    
    CGFloat const screenWidth = UIScreen.mainScreen.bounds.size.width;
	if (screenWidth <= 320) {
		offset = 20;
	} else if (screenWidth <= 375) {
		offset = 35;
	} else if (screenWidth <= 414) {
		offset = 28;
	}

    return %orig;

}
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


%group iOS13
%hook SBDashBoardLockScreenEnvironment
- (void)handleBiometricEvent:(unsigned long long)arg1 {
	%orig;

	if (arg1 == kBiometricEventMesaSuccess) {
		SBDashBoardBiometricUnlockController* biometricUnlockController = MSHookIvar<SBDashBoardBiometricUnlockController*>(self, "_biometricUnlockController");
		SBDashBoardMesaUnlockBehaviorConfiguration* unlockBehavior = MSHookIvar<SBDashBoardMesaUnlockBehaviorConfiguration*>(biometricUnlockController, "_biometricUnlockBehaviorConfiguration");
		
		if ([unlockBehavior _isAccessibilityRestingUnlockPreferenceEnabled]) {
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
				[[%c(SBLockScreenManager) sharedInstance] _finishUIUnlockFromSource:12 withOptions:nil];
			});
		}
	}
}
%end	/// %hook SBDashBoardLockScreenEnvironment

%hook BSUICAPackageView
- (id)initWithPackageName:(id)arg1 inBundle:(id)arg2 {
	if (![arg1 hasPrefix:@"lock"]) return %orig;
	
	NSString* packageName = nil;
	
	if ([arg1 hasPrefix:@"lock@2x-120fps~ipad"]) {
		packageName = @"lock@2x-j3xx";
	} else if ([arg1 hasPrefix:@"lock@2x-812h"]) {
		packageName = @"lock@2x-812h-n84";
	} else if ([arg1 hasPrefix:@"lock@2x-896h"]) {
		packageName = @"lock@2x-896h-n84";
	} else if ([arg1 hasPrefix:@"lock@3x-812h"]) {
		packageName = arg1;
	} else if ([arg1 hasPrefix:@"lock@3x-896h"]) {
		packageName = @"lock@3x-896h-d33";
	} else {
		packageName = @"lock@2x-812h-n84";
	}

	return %orig(packageName, [NSBundle bundleWithPath:@"/Library/Application Support/ProudLock2"]);
}
%end	// %hook BSUICAPackageView

%hook CSCombinedListViewController
- (UIEdgeInsets)_listViewDefaultContentInsets {
    UIEdgeInsets const orig = %orig;

    orig.top += offset;
    return orig;
}
%end	// %hook CSCombinedListViewController
%end	// %group iOS13



%ctor {
	MSImageRef libGestalt = MSGetImageByName("/usr/lib/libMobileGestalt.dylib");
	if (libGestalt) {
		void *MGCopyAnswerFn = MSFindSymbol(libGestalt, "_MGCopyAnswer");
		const uint8_t *MGCopyAnswer_ptr = (const uint8_t *)MGCopyAnswer;
		addr_t branch = find_branch64(MGCopyAnswer_ptr, 0, 8);
		addr_t branch_offset = follow_branch64(MGCopyAnswer_ptr, branch);
		MSHookFunction(((void *)((const uint8_t *)MGCopyAnswerFn + branch_offset)), (void *)new_MGCopyAnswer_internal, (void **)&orig_MGCopyAnswer_internal);
		
		%init();
		
		if (kCFCoreFoundationVersionNumber >= 1665.15) {
			%init(iOS13);
		}
	}
}
