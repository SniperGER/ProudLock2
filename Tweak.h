//
// Tweak.xm
// ProudLock2
//
// Copyright © 2019 FESTIVAL Development
// All Rights reserved
//

#import <substrate.h>
#import <stdint.h>

#define CGRectSetY(rect, y) CGRectMake(rect.origin.x, y, rect.size.width, rect.size.height)

#define kBiometricEventMesaMatched 		3
#define kBiometricEventMesaSuccess 		4
#define kBiometricEventMesaFailed 		10
#define kBiometricEventMesaDisabled 	6



@interface SBDashBoardMesaUnlockBehaviorConfiguration : NSObject
- (BOOL)_isAccessibilityRestingUnlockPreferenceEnabled;
@end

@interface SBDashBoardBiometricUnlockController : NSObject
@end

@interface SBLockScreenController : NSObject {
	SBDashBoardMesaUnlockBehaviorConfiguration *_mesaUnlockBehaviorConfiguration;
}
+ (id)sharedInstance;
- (BOOL)_finishUIUnlockFromSource:(int)arg1 withOptions:(id)arg2;
@end

@interface PKGlyphView : UIView
@end