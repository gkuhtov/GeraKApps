#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface AudioPulseManager : NSObject
@property (nonatomic, assign) BOOL isMuted;
+ (instancetype)shared;
- (void)updateWithEmf:(double)microTeslas;
- (void)updateWithTrackingRssi:(NSInteger)rssi;
- (void)stop;
@end
