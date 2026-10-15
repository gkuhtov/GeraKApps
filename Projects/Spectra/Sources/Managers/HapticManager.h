#import <UIKit/UIKit.h>

@interface HapticManager : NSObject
+ (instancetype)shared;
- (void)triggerSelectionTick;
- (void)triggerRadarPing;
- (void)triggerWarningPulse;
- (void)triggerCriticalImpact;
@end
