#import <UIKit/UIKit.h>

@interface HapticManager : NSObject
+ (instancetype)shared;
- (void)triggerSelectionTick;
- (void)triggerWarningPulse;
- (void)triggerCriticalImpact;
@end
