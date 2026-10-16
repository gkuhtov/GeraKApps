#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <UIKit/UIKit.h>

@interface SpectraRadarNode : NSObject
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *displayName;
@property (nonatomic, copy) NSString *deviceCategory;
@property (nonatomic, assign) NSInteger rssi;
@property (nonatomic, assign) CGFloat angleRadians;
@property (nonatomic, assign) CGFloat normalizedDistance;
@property (nonatomic, strong) NSDate *lastSeen;
@property (nonatomic, strong) NSDate *lastPingedBySweep;
@end

@protocol BluetoothManagerDelegate <NSObject>
- (void)didUpdateRadarNodes:(NSArray<SpectraRadarNode *> *)nodes;
@end

@interface BluetoothManager : NSObject <CBCentralManagerDelegate>
@property (nonatomic, weak) id<BluetoothManagerDelegate> delegate;
- (void)startScanning;
- (void)stopScanning;
@end
