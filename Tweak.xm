//
// Tweak.xm
// ProudLock2
//
// Copyright © 2019 FESTIVAL Development
// All Rights reserved
//

#import <substrate.h>
#import <stdint.h>

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



#define CGRectSetY(rect, y) CGRectMake(rect.origin.x, y, rect.size.width, rect.size.height)
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
%end    // %hook SBDashBoardViewController

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


@interface PKGlyphView : UIView
@end

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



%ctor {
	MSImageRef libGestalt = MSGetImageByName("/usr/lib/libMobileGestalt.dylib");
	if (libGestalt) {
		void *MGCopyAnswerFn = MSFindSymbol(libGestalt, "_MGCopyAnswer");
		const uint8_t *MGCopyAnswer_ptr = (const uint8_t *)MGCopyAnswer;
		addr_t branch = find_branch64(MGCopyAnswer_ptr, 0, 8);
		addr_t branch_offset = follow_branch64(MGCopyAnswer_ptr, branch);
		MSHookFunction(((void *)((const uint8_t *)MGCopyAnswerFn + branch_offset)), (void *)new_MGCopyAnswer_internal, (void **)&orig_MGCopyAnswer_internal);
		
		%init();
	}
}
