#import "RadarLensView.h"
#import "SpectraConfig.h"
#import "HapticManager.h"

@implementation RadarLensView {
    CAShapeLayer *_gridLayer;
    CAShapeLayer *_sweepLayer;
    UIView *_nodesContainer;
    NSMutableDictionary<NSString *, UIView *> *_nodeViews;
    NSArray<SpectraRadarNode *> *_currentNodes;
    CADisplayLink *_sweepTracker;
    NSDate *_sweepStartDate;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = SpectraLensBackgroundColor();
        self.layer.cornerRadius = kRadarCornerRadius;
        self.layer.borderWidth = kRadarBorderWidth;
        self.clipsToBounds = YES;
        
        _nodeViews = [NSMutableDictionary dictionary];
        
        _gridLayer = [CAShapeLayer layer];
        _gridLayer.fillColor = [UIColor clearColor].CGColor;
        _gridLayer.lineWidth = 1.0;
        [self.layer addSublayer:_gridLayer];
        
        _nodesContainer = [[UIView alloc] initWithFrame:self.bounds];
        _nodesContainer.userInteractionEnabled = NO;
        [self addSubview:_nodesContainer];
        
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
    
    for (UIView *blip in _nodeViews.allValues) {
        UIView *dot = [blip viewWithTag:101];
        UILabel *lbl = [blip viewWithTag:102];
        dot.backgroundColor = themeColor;
        lbl.textColor = themeColor;
    }
}

- (void)startSweepAnimation {
    _sweepStartDate = [NSDate date];
    CABasicAnimation *rotation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotation.toValue = @(M_PI * 2.0);
    rotation.duration = kRadarSweepDuration;
    rotation.cumulative = YES;
    rotation.repeatCount = HUGE_VALF;
    [_sweepLayer addAnimation:rotation forKey:@"radarSweep"];
    
    if (!_sweepTracker) {
        _sweepTracker = [CADisplayLink displayLinkWithTarget:self selector:@selector(checkSweepCollisions)];
        [_sweepTracker addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
}

- (void)updateWithNodes:(NSArray<SpectraRadarNode *> *)nodes {
    _currentNodes = nodes;
    CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    CGFloat maxRadius = MIN(center.x, center.y) - 28.0;
    
    NSMutableSet *activeIDs = [NSMutableSet set];
    
    for (SpectraRadarNode *node in nodes) {
        [activeIDs addObject:node.identifier];
        UIView *blipView = _nodeViews[node.identifier];
        
        if (!blipView) {
            blipView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 110, 24)];
            
            UIView *dot = [[UIView alloc] initWithFrame:CGRectMake(0, 8, kTargetDotSize, kTargetDotSize)];
            dot.tag = 101;
            dot.backgroundColor = _themeColor;
            dot.layer.cornerRadius = kTargetDotSize / 2.0;
            [blipView addSubview:dot];
            
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(kTargetDotSize + 4, 2, 95, 20)];
            label.tag = 102;
            label.font = [UIFont fontWithName:@"Courier-Bold" size:10];
            label.textColor = _themeColor;
            [blipView addSubview:label];
            
            blipView.alpha = 0.45;
            [_nodesContainer addSubview:blipView];
            _nodeViews[node.identifier] = blipView;
        }
        
        UILabel *label = [blipView viewWithTag:102];
        NSString *shortName = (node.displayName && node.displayName.length > 9) ? [node.displayName substringToIndex:9] : (node.displayName ?: @"NODE");
        label.text = [NSString stringWithFormat:@"%@ [%ld]", shortName, (long)node.rssi];
        
        CGFloat radius = node.normalizedDistance * maxRadius;
        // Переводим азимут (0 наверху) в экранные координаты
        CGFloat x = center.x + sin(node.angleRadians) * radius;
        CGFloat y = center.y - cos(node.angleRadians) * radius;
        
        [UIView animateWithDuration:0.25 animations:^{
            blipView.center = CGPointMake(x + 48, y);
        }];
    }
    
    // Удаляем пропавшие из эфира узлы
    NSArray *allKeys = [_nodeViews allKeys];
    for (NSString *key in allKeys) {
        if (![activeIDs containsObject:key]) {
            UIView *oldView = _nodeViews[key];
            [oldView removeFromSuperview];
            [_nodeViews removeObjectForKey:key];
        }
    }
}

- (void)checkSweepCollisions {
    if (_currentNodes.count == 0 || !_sweepStartDate) return;
    
    NSTimeInterval elapsed = [[NSDate date] timeIntervalSinceDate:_sweepStartDate];
    double cycleProgress = fmod(elapsed, kRadarSweepDuration) / kRadarSweepDuration;
    CGFloat currentSweepAngle = cycleProgress * (M_PI * 2.0);
    
    NSDate *now = [NSDate date];
    for (SpectraRadarNode *node in _currentNodes) {
        if (fabs(currentSweepAngle - node.angleRadians) < 0.12) {
            if (!node.lastPingedBySweep || [now timeIntervalSinceDate:node.lastPingedBySweep] > (kRadarSweepDuration * 0.8)) {
                node.lastPingedBySweep = now;
                UIView *blipView = _nodeViews[node.identifier];
                if (blipView) {
                    blipView.alpha = 1.0;
                    [[HapticManager shared] triggerRadarPing];
                    [UIView animateWithDuration:kRadarSweepDuration * 0.85 animations:^{
                        blipView.alpha = 0.35;
                    }];
                }
            }
        }
    }
}

@end
