#import <UIKit/UIKit.h>
#import "BluetoothManager.h"

@interface RadarLensView : UIView
@property (nonatomic, strong) UIColor *themeColor;
- (void)startSweepAnimation;
- (void)updateWithNodes:(NSArray<SpectraRadarNode *> *)nodes;
@end
