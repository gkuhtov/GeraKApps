#import "HapticManager.h"

@implementation HapticManager {
    UISelectionFeedbackGenerator *_selectionGen;
    UIImpactFeedbackGenerator *_lightGen;
    UIImpactFeedbackGenerator *_mediumGen;
    UIImpactFeedbackGenerator *_rigidGen;
}

+ (instancetype)shared {
    static HapticManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _selectionGen = [[UISelectionFeedbackGenerator alloc] init];
        _lightGen = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        _mediumGen = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
        _rigidGen = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleRigid];
    }
    return self;
}

- (void)triggerSelectionTick {
    [_selectionGen selectionChanged];
}

- (void)triggerRadarPing {
    [_lightGen impactOccurredWithIntensity:0.65];
}

- (void)triggerTargetLock {
    [_rigidGen impactOccurredWithIntensity:0.9];
}

- (void)triggerWarningPulse {
    [_mediumGen impactOccurred];
}

- (void)triggerCriticalImpact {
    [_rigidGen impactOccurred];
}

@end
