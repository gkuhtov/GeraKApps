#import <UIKit/UIKit.h>
#import "BluetoothManager.h"

@protocol RadarLensViewDelegate <NSObject>
- (void)radarDidSelectNode:(SpectraRadarNode *)node;
@end

@interface RadarLensView : UIView
@property (nonatomic, weak) id<RadarLensViewDelegate> delegate;
@property (nonatomic, strong) UIColor *themeColor;
@property (nonatomic, copy) NSString *selectedNodeID;
- (void)startSweepAnimation;
- (void)updateWithNodes:(NSArray<SpectraRadarNode *> *)nodes;
- (void)clearSelection;
@end
