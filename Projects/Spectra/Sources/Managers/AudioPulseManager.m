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
        _isMuted = YES; // По умолчанию тихий режим
        _currentEmf = 0.0;
    }
    return self;
}

- (void)updateWithEmf:(double)microTeslas {
    _currentEmf = microTeslas;
    if (_isMuted) {
        [self stop];
        return;
    }
    
    // Рассчитываем интервал щелчков: от 1.2 сек (фон) до 0.08 сек (высокое поле)
    double clamped = MAX(20.0, MIN(120.0, microTeslas));
    double factor = (clamped - 20.0) / 100.0;
    NSTimeInterval interval = 1.2 - (factor * 1.12);
    
    if (!_pulseTimer || fabs(_pulseTimer.timeInterval - interval) > 0.15) {
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
    // Аппаратный короткий системный клик
    AudioServicesPlaySystemSound(1104);
}

- (void)stop {
    [_pulseTimer invalidate];
    _pulseTimer = nil;
}

@end
