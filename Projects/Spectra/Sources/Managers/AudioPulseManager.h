#import <Foundation/Foundation.h>

@interface AudioPulseManager : NSObject
@property (nonatomic, assign) BOOL isMuted;
+ (instancetype)shared;
- (void)updateWithEmf:(double)microTeslas;
- (void)stop;
@end
