#import "AudioPulseManager.h"
#import <AudioToolbox/AudioToolbox.h>
#import "SpectraConfig.h"

@implementation AudioPulseManager {
    NSTimer *_pulseTimer;
    double _currentEmf;
}

+ (instancetype)shared {
    static AudioPulseManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _isMuted = YES;
        _currentEmf = 0.0;
        
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
                                         withOptions:AVAudioSessionCategoryOptionMixWithOthers
                                               error:nil];
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
    }
    return self;
}

- (void)updateWithEmf:(double)microTeslas {
    _currentEmf = microTeslas;
    if (_isMuted) {
        [self stop];
        return;
    }
    
    double clamped = MAX(20.0, MIN(300.0, microTeslas));
    double factor = (clamped - 20.0) / 280.0;
    NSTimeInterval interval = 0.9 - (factor * 0.81);
    
    if (!_pulseTimer || fabs(_pulseTimer.timeInterval - interval) > 0.12) {
        [_pulseTimer invalidate];
        _pulseTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                       target:self
                                                     selector:@selector(playTick)
                                                     userInfo:nil
                                                      repeats:YES];
    }
}

- (void)playTick {
    if (_isMuted) return;
    AudioServicesPlayAlertSound(1104);
}

- (void)stop {
    [_pulseTimer invalidate];
    _pulseTimer = nil;
}

@end
