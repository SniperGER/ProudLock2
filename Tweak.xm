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
	
	// Apparently, only the 'IsEmulatedDevice' key is needed to add the Face ID latch to the lockscreen
	// However, it doesn't fully work as expected, but this is a challenge for someone else
	if (k("z5G/N9jcMdgPm8UegLwbKg") || k("IsEmulatedDevice")) {
		return (__bridge CFPropertyListRef)@YES;
	}
	
	return r;
}



%hook SBUICAPackageView
- (id)initWithPackageName:(id)arg1 inBundle:(id)arg2 {
	NSLog(@"[ProudLock2] -[SBUICAPackageView initWithPackageName:inBundle] = %@, %@", arg1, arg2);
	return %orig(arg1, [NSBundle bundleWithPath:@"/Library/Application Support/ProudLock2"]);
}
%end	// %hook SBUICAPackageView



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
