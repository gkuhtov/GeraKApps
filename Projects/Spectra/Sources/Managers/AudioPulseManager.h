#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface AudioPulseManager : NSObject
@property (nonatomic, assign) BOOL isMuted;
@property (nonatomic, assign) BOOL isTrackingTarget;
+ (instancetype)shared;
- (void)updateWithEmf:(double)microTeslas;
- (void)updateWithTargetRssi:(NSInteger)rssi;
- (void)stop;
@end
