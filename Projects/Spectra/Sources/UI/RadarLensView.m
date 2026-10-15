#import "RadarLensView.h"
#import "SpectraConfig.h"

@implementation RadarLensView {
    CAShapeLayer *_gridLayer;
    CAShapeLayer *_sweepLayer;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = SpectraLensBackgroundColor();
        self.layer.cornerRadius = kRadarCornerRadius;
        self.layer.borderWidth = kRadarBorderWidth;
        self.clipsToBounds = YES;
        
        _gridLayer = [CAShapeLayer layer];
        _gridLayer.fillColor = [UIColor clearColor].CGColor;
        _gridLayer.lineWidth = 1.0;
        [self.layer addSublayer:_gridLayer];
        
        _sweepLayer = [CAShapeLayer layer];
        _sweepLayer.frame = self.bounds;
        [self.layer addSublayer:_sweepLayer];
        
        [self setThemeColor:SpectraPrimaryColorForMode(SpectraFrequencyModeTechno)];
        [self drawRadarGrid];
    }
    return self;
}

- (void)drawRadarGrid {
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    CGFloat maxRadius = MIN(center.x, center.y) - 24.0;
    
    for (NSInteger i = 1; i <= kRadarRingsCount; i++) {
        CGFloat radius = (maxRadius / kRadarRingsCount) * i;
        [path moveToPoint:CGPointMake(center.x + radius, center.y)];
        [path addArcWithCenter:center radius:radius startAngle:0 endAngle:M_PI * 2 clockwise:YES];
    }
    
    [path moveToPoint:CGPointMake(center.x - maxRadius, center.y)];
    [path addLineToPoint:CGPointMake(center.x + maxRadius, center.y)];
    [path moveToPoint:CGPointMake(center.x, center.y - maxRadius)];
    [path addLineToPoint:CGPointMake(center.x, center.y + maxRadius)];
    
    _gridLayer.path = path.CGPath;
    
    UIBezierPath *sweepPath = [UIBezierPath bezierPath];
    [sweepPath moveToPoint:center];
    [sweepPath addLineToPoint:CGPointMake(center.x, center.y - maxRadius)];
    _sweepLayer.path = sweepPath.CGPath;
    _sweepLayer.lineWidth = 2.0;
}

- (void)setThemeColor:(UIColor *)themeColor {
    _themeColor = themeColor;
    self.layer.borderColor = [themeColor colorWithAlphaComponent:0.85].CGColor;
    _gridLayer.strokeColor = [themeColor colorWithAlphaComponent:0.25].CGColor;
    _sweepLayer.strokeColor = themeColor.CGColor;
}

- (void)startSweepAnimation {
    CABasicAnimation *rotation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotation.toValue = @(M_PI * 2.0);
    rotation.duration = kRadarSweepDuration;
    rotation.cumulative = YES;
    rotation.repeatCount = HUGE_VALF;
    [_sweepLayer addAnimation:rotation forKey:@"radarSweep"];
}

@end
