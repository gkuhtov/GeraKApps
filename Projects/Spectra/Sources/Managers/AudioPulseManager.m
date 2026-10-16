#import "AudioPulseManager.h"
#import "SpectraConfig.h"

@implementation AudioPulseManager {
    NSTimer *_pulseTimer;
    AVAudioPlayer *_player;
    NSData *_clickAudioData;
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
        _isMuted = NO;
        [self configureAudioSession];
        [self generateTacticalClickPCM];
    }
    return self;
}

- (void)configureAudioSession {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback
             withOptions:AVAudioSessionCategoryOptionMixWithOthers
                   error:nil];
    [session setActive:YES error:nil];
}

- (void)generateTacticalClickPCM {
    const int sampleRate = 44100;
    const double duration = 0.012;
    const int numSamples = (int)(sampleRate * duration);
    
    NSMutableData *pcm = [NSMutableData data];
    for (int i = 0; i < numSamples; i++) {
        double t = (double)i / sampleRate;
        double decay = exp(-t * 400.0);
        double sample = sin(2.0 * M_PI * 2200.0 * t) * decay;
        int16_t intSample = (int16_t)(sample * 31000.0);
        [pcm appendBytes:&intSample length:sizeof(int16_t)];
    }
    
    NSMutableData *wav = [NSMutableData data];
    int32_t dataSize = (int32_t)pcm.length;
    int32_t chunkSize = 36 + dataSize;
    
    [wav appendBytes:"RIFF" length:4];
    [wav appendBytes:&chunkSize length:4];
    [wav appendBytes:"WAVE" length:4];
    [wav appendBytes:"fmt " length:4];
    int32_t subchunk1Size = 16;
    int16_t audioFormat = 1;
    int16_t numChannels = 1;
    int32_t sRate = sampleRate;
    int32_t byteRate = sampleRate * sizeof(int16_t);
    int16_t blockAlign = sizeof(int16_t);
    int16_t bitsPerSample = 16;
    
    [wav appendBytes:&subchunk1Size length:4];
    [wav appendBytes:&audioFormat length:2];
    [wav appendBytes:&numChannels length:2];
    [wav appendBytes:&sRate length:4];
    [wav appendBytes:&byteRate length:4];
    [wav appendBytes:&blockAlign length:2];
    [wav appendBytes:&bitsPerSample length:2];
    
    [wav appendBytes:"data" length:4];
    [wav appendBytes:&dataSize length:4];
    [wav appendData:pcm];
    
    _clickAudioData = wav;
    _player = [[AVAudioPlayer alloc] initWithData:_clickAudioData error:nil];
    _player.pan = 0.0;
    [_player prepareToPlay];
}

- (void)updateWithEmf:(double)microTeslas {
    if (_isMuted) {
        [self stop];
        return;
    }
    _player.pan = 0.0;
    
    double clamped = MAX(20.0, MIN(350.0, microTeslas));
    double factor = (clamped - 20.0) / 330.0;
    NSTimeInterval interval = 0.85 - (factor * 0.77);
    [self scheduleTimerWithInterval:interval];
}

- (void)updateWithTrackingRssi:(NSInteger)rssi relativeAngle:(double)angleRadians {
    if (_isMuted) {
        [self stop];
        return;
    }
    
    // Пространственная стерео-панорама (-1.0 лево, +1.0 право)
    double panVal = sin(angleRadians);
    _player.pan = (float)MAX(-1.0, MIN(1.0, panVal));
    
    double clamped = MAX((double)kBleMinRssiThreshold, MIN((double)kBleMaxRssiThreshold, (double)rssi));
    double factor = (clamped - (double)kBleMinRssiThreshold) / (double)(kBleMaxRssiThreshold - kBleMinRssiThreshold);
    NSTimeInterval interval = 0.90 - (factor * 0.84);
    [self scheduleTimerWithInterval:interval];
}

- (void)scheduleTimerWithInterval:(NSTimeInterval)interval {
    if (!_pulseTimer || fabs(_pulseTimer.timeInterval - interval) > 0.08) {
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
    if (_player.isPlaying) {
        [_player stop];
        _player.currentTime = 0;
    }
    [_player play];
}

- (void)stop {
    [_pulseTimer invalidate];
    _pulseTimer = nil;
}

@end
