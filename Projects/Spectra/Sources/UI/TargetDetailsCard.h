#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import "BluetoothManager.h"

@protocol TargetDetailsCardDelegate <NSObject>
- (void)targetDetailsDidRequestDismiss;
@end

@interface TargetDetailsCard : UIView
@property (nonatomic, weak) id<TargetDetailsCardDelegate> delegate;
@property (nonatomic, strong) UIColor *themeColor;
- (void)configureWithNode:(SpectraRadarNode *)node;
@end
