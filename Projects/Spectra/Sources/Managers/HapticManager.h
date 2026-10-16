#import <UIKit/UIKit.h>

@interface HapticManager : NSObject
+ (instancetype)shared;
- (void)triggerSelectionTick;
- (void)triggerRadarPing;
- (void)triggerTargetLock;
- (void)triggerWarningPulse;
- (void)triggerCriticalImpact;
@end
