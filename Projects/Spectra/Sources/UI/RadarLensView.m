#import "RadarLensView.h"
#import "SpectraConfig.h"
#import "HapticManager.h"

@interface TargetTapButton : UIButton
@end

@implementation TargetTapButton
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    CGRect expanded = CGRectInset(self.bounds, -18, -18);
    return CGRectContainsPoint(expanded, point);
}
@end

@implementation RadarLensView {
    CAShapeLayer *_gridLayer;
    CAShapeLayer *_sweepLayer;
    CAShapeLayer *_vectorLayer;
    UIView *_nodesContainer;
    NSMutableDictionary<NSString * *, TargetTapButton> *_nodeButtons;
    NSArray<SpectraRadarNode *> *_currentNodes;
    CADisplayLink *_sweepTracker;
    NSDate *_sweepStartDate;
    UIView *_lockReticle;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = SpectraLensBackgroundColor();
        self.layer.cornerRadius = kRadarCornerRadius;
        self.layer.borderWidth = kRadarBorderWidth;
        self.clipsToBounds = YES;
        
        _nodeButtons = [NSMutableDictionary dictionary];
        
        _gridLayer = [CAShapeLayer layer];
        _gridLayer.fillColor = [UIColor clearColor].CGColor;
        _gridLayer.lineWidth = 1.0;
        [self.layer addSublayer:_gridLayer];
        
        _vectorLayer = [CAShapeLayer layer];
        _vectorLayer.lineWidth = 1.5;
        _vectorLayer.lineDashPattern = @[@4, @2];
        _vectorLayer.fillColor = [UIColor clearColor].CGColor;
        [self.layer addSublayer:_vectorLayer];
        
        _nodesContainer = [[UIView alloc] initWithFrame:self.bounds];
        _nodesContainer.userInteractionEnabled = YES;
        [self addSubview:_nodesContainer];
        
        _sweepLayer = [CAShapeLayer layer];
        _sweepLayer.frame = self.bounds;
        [self.layer addSublayer:_sweepLayer];
        
        _lockReticle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];
        _lockReticle.layer.borderWidth = 1.5;
        _lockReticle.userInteractionEnabled = NO;
        _lockReticle.hidden = YES;
        [_nodesContainer addSubview:_lockReticle];
        
        [self setThemeColor:SpectraPrimaryColorForMode(SpectraFrequencyModeTechno)];
        [self drawRadarGrid];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(startSweepAnimation)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    _vectorLayer.strokeColor = [UIColor yellowColor].CGColor;
    _lockReticle.layer.borderColor = themeColor.CGColor;
    
    for (TargetTapButton *btn in _nodeButtons.allValues) {
        UIView *dot = [btn viewWithTag:101];
        UILabel *lbl = [btn viewWithTag:102];
        dot.backgroundColor = themeColor;
        lbl.textColor = themeColor;
    }
}

- (void)startSweepAnimation {
    _sweepStartDate = [NSDate date];
    [_sweepLayer removeAnimationForKey:@"radarSweep"];
    
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
    CGPoint trackedPoint = CGPointZero;
    BOOL hasTrackedPoint = NO;
    
    NSArray<SpectraRadarNode *> *sortedNodes = [nodes sortedArrayUsingComparator:^NSComparisonResult(SpectraRadarNode *n1, SpectraRadarNode *n2) {
        if (n1.angleRadians < n2.angleRadians) return NSOrderedAscending;
        if (n1.angleRadians > n2.angleRadians) return NSOrderedDescending;
        return NSOrderedSame;
    }];
    
    CGFloat lastCalculatedY = -999.0;
    
    for (SpectraRadarNode *node in sortedNodes) {
        [activeIDs addObject:node.identifier];
        TargetTapButton *btn = _nodeButtons[node.identifier];
        
        if (!btn) {
            btn = [TargetTapButton buttonWithType:UIButtonTypeCustom];
            btn.frame = CGRectMake(0, 0, 110, 18);
            [btn addTarget:self action:@selector(nodeTapped:) forControlEvents:UIControlEventTouchUpInside];
            
            UIView *dot = [[UIView alloc] initWithFrame:CGRectMake(0, 5, kTargetDotSize, kTargetDotSize)];
            dot.tag = 101;
            dot.userInteractionEnabled = NO;
            dot.backgroundColor = _themeColor;
            dot.layer.cornerRadius = kTargetDotSize / 2.0;
            [btn addSubview:dot];
            
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(kTargetDotSize + 4, 0, 95, 18)];
            label.tag = 102;
            label.userInteractionEnabled = NO;
            label.font = [UIFont fontWithName:@"Courier-Bold" size:9];
            label.textColor = _themeColor;
            [btn addSubview:label];
            
            btn.alpha = 0.50;
            [_nodesContainer addSubview:btn];
            _nodeButtons[node.identifier] = btn;
        }
        
        UILabel *label = [btn viewWithTag:102];
        NSString *shortName = (node.displayName && node.displayName.length > 8) ? [node.displayName substringToIndex:8] : (node.displayName ?: @"NODE");
        label.text = [NSString stringWithFormat:@"%@ [%ld]", shortName, (long)node.rssi];
        
        CGFloat radius = node.normalizedDistance * maxRadius;
        CGFloat targetDotX = center.x + sin(node.angleRadians) * radius;
        CGFloat targetDotY = center.y - cos(node.angleRadians) * radius;
        
        CGFloat adjustedY = targetDotY;
        if (fabs(targetDotY - lastCalculatedY) < 14.0 && targetDotX > center.x - 40) {
            adjustedY += (targetDotY >= lastCalculatedY) ? 12.0 : -12.0;
        }
        lastCalculatedY = adjustedY;
        
        BOOL isRightHalf = (targetDotX >= center.x);
        UIView *dot = [btn viewWithTag:101];
        if (isRightHalf) {
            dot.frame = CGRectMake(0, 5, kTargetDotSize, kTargetDotSize);
            label.frame = CGRectMake(kTargetDotSize + 4, 0, 95, 18);
            label.textAlignment = NSTextAlignmentLeft;
            btn.center = CGPointMake(targetDotX + (btn.bounds.size.width / 2.0) - (kTargetDotSize / 2.0), adjustedY);
        } else {
            dot.frame = CGRectMake(btn.bounds.size.width - kTargetDotSize, 5, kTargetDotSize, kTargetDotSize);
            label.frame = CGRectMake(0, 0, btn.bounds.size.width - kTargetDotSize - 4, 18);
            label.textAlignment = NSTextAlignmentRight;
            btn.center = CGPointMake(targetDotX - (btn.bounds.size.width / 2.0) + (kTargetDotSize / 2.0), adjustedY);
        }
        
        BOOL isTarget = [node.identifier isEqualToString:self->_selectedNodeID];
        if (isTarget) {
            self->_lockReticle.center = CGPointMake(targetDotX, targetDotY);
            trackedPoint = CGPointMake(targetDotX, targetDotY);
            hasTrackedPoint = YES;
            btn.alpha = 1.0;
        } else {
            btn.alpha = self.isTrackingMode ? 0.15 : 0.50;
        }
    }
    
    // Вектор слежения от центра
    if (self.isTrackingMode && hasTrackedPoint) {
        UIBezierPath *vPath = [UIBezierPath bezierPath];
        [vPath moveToPoint:center];
        [vPath addLineToPoint:trackedPoint];
        _vectorLayer.path = vPath.CGPath;
        _vectorLayer.hidden = NO;
    } else {
        _vectorLayer.hidden = YES;
    }
    
    NSArray *allKeys = [_nodeButtons allKeys];
    for (NSString *key in allKeys) {
        if (![activeIDs containsObject:key]) {
            TargetTapButton *oldBtn = _nodeButtons[key];
            [oldBtn removeFromSuperview];
            [_nodeButtons removeObjectForKey:key];
            if ([key isEqualToString:_selectedNodeID]) {
                [self clearSelection];
            }
        }
    }
}

- (void)nodeTapped:(TargetTapButton *)sender {
    for (NSString *key in _nodeButtons) {
        if (_nodeButtons[key] == sender) {
            _selectedNodeID = key;
            for (SpectraRadarNode *node in _currentNodes) {
                if ([node.identifier isEqualToString:key]) {
                    UIView *dot = [sender viewWithTag:101];
                    CGPoint dotCenterInContainer = [sender convertPoint:dot.center toView:_nodesContainer];
                    
                    _lockReticle.center = dotCenterInContainer;
                    _lockReticle.hidden = NO;
                    
                    _lockReticle.transform = CGAffineTransformMakeScale(1.8, 1.8);
                    [UIView animateWithDuration:0.2 animations:^{
                        self->_lockReticle.transform = CGAffineTransformIdentity;
                    }];
                    
                    [[HapticManager shared] triggerTargetLock];
                    [self.delegate radarDidSelectNode:node];
                    return;
                }
            }
        }
    }
}

- (void)clearSelection {
    _selectedNodeID = nil;
    _lockReticle.hidden = YES;
    _vectorLayer.hidden = YES;
    self.isTrackingMode = NO;
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
                TargetTapButton *btn = _nodeButtons[node.identifier];
                if (btn) {
                    btn.alpha = 1.0;
                    [[HapticManager shared] triggerRadarPing];
                    [UIView animateWithDuration:kRadarSweepDuration * 0.85 animations:^{
                        btn.alpha = (self.isTrackingMode && ![node.identifier isEqualToString:self->_selectedNodeID]) ? 0.15 : 0.50;
                    }];
                }
            }
        }
    }
}

@end
