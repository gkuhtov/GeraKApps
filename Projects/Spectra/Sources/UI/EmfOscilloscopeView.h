#import <UIKit/UIKit.h>

@interface EmfOscilloscopeView : UIView
@property (nonatomic, strong) UIColor *themeColor;
- (void)pushValue:(double)value;
@end
