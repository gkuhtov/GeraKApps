#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "BluetoothManager.h"

typedef NS_ENUM(NSInteger, SpectraRangeFilterMode) {
    SpectraRangeFilterAll = 0,   // Все сигналы (до -95 dBm)
    SpectraRangeFilterMedium,    // Комната / Средний (до -80 dBm)
    SpectraRangeFilterClose      // Ближний бой / CQB (до -65 dBm)
};

@protocol RadarLensViewDelegate <NSObject>
- (void)radarDidSelectNode:(SpectraRadarNode *)node;
@end

@interface RadarLensView : UIView
@property (nonatomic, weak) id<RadarLensViewDelegate> delegate;
@property (nonatomic, strong) UIColor *themeColor;
@property (nonatomic, copy) NSString *selectedNodeID;
@property (nonatomic, assign) BOOL isTrackingMode;
@property (nonatomic, assign) SpectraRangeFilterMode rangeFilter;
- (void)startSweepAnimation;
- (void)updateWithNodes:(NSArray<SpectraRadarNode *> *)nodes;
- (void)updateCompassHeading:(double)headingDegrees;
- (void)clearSelection;
@end
