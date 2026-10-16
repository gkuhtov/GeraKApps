#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import "BluetoothManager.h"

@protocol TargetDetailsCardDelegate <NSObject>
- (void)targetDetailsDidRequestDismiss;
- (void)targetDetailsDidToggleTracking:(BOOL)isTracking;
@end

@interface TargetDetailsCard : UIView
@property (nonatomic, weak) id<TargetDetailsCardDelegate> delegate;
@property (nonatomic, strong) UIColor *themeColor;
@property (nonatomic, assign, readonly) BOOL isTrackingActive;
- (void)configureWithNode:(SpectraRadarNode *)node;
- (void)resetTrackingState;
@end
