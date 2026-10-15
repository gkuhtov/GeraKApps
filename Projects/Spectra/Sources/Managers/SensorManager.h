#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import <CoreLocation/CoreLocation.h>

@protocol SensorManagerDelegate <NSObject>
- (void)didUpdateEmfValue:(double)microTeslas;
- (void)didUpdateAzimuth:(double)degrees direction:(NSString *)cardinal;
@end

@interface SensorManager : NSObject <CLLocationManagerDelegate>
@property (nonatomic, weak) id<SensorManagerDelegate> delegate;
- (void)startScanning;
- (void)stopScanning;
@end
