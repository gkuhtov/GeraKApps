#import "RadarLensView.h"
#import "SpectraConfig.h"
#import "HapticManager.h"

@implementation RadarLensView {
    CAShapeLayer *_gridLayer;
    CAShapeLayer *_sweepLayer;
    UIView *_nodesContainer;
    NSMutableDictionary<NSString *, UIButton *> *_nodeButtons;
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
        
        _nodesContainer = [[UIView alloc] initWithFrame:self.bounds];
        _nodesContainer.userInteractionEnabled = YES;
        [self addSubview:_nodesContainer];
        
        _sweepLayer = [CAShapeLayer layer];
        _sweepLayer.frame = self.bounds;
        [self.layer addSublayer:_sweepLayer];
        
        _lockReticle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 26, 26)];
        _lockReticle.layer.borderWidth = 1.5;
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
    _lockReticle.layer.borderColor = themeColor.CGColor;
    
    for (UIButton *btn in _nodeButtons.allValues) {
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
    
    for (SpectraRadarNode *node in nodes) {
        [activeIDs addObject:node.identifier];
        UIButton *btn = _nodeButtons[node.identifier];
        
        if (!btn) {
            btn = [UIButton buttonWithType:UIButtonTypeCustom];
            btn.frame = CGRectMake(0, 0, 120, 32);
            [btn addTarget:self action:@selector(nodeTapped:) forControlEvents:UIControlEventTouchUpInside];
            
            UIView *dot = [[UIView alloc] initWithFrame:CGRectMake(4, 12, kTargetDotSize, kTargetDotSize)];
            dot.tag = 101;
            dot.userInteractionEnabled = NO;
            dot.backgroundColor = _themeColor;
            dot.layer.cornerRadius = kTargetDotSize / 2.0;
            [btn addSubview:dot];
            
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(kTargetDotSize + 8, 6, 95, 20)];
            label.tag = 102;
            label.userInteractionEnabled = NO;
            label.font = [UIFont fontWithName:@"Courier-Bold" size:10];
            label.textColor = _themeColor;
            [btn addSubview:label];
            
            btn.alpha = 0.45;
            [_nodesContainer addSubview:btn];
            _nodeButtons[node.identifier] = btn;
        }
        
        UILabel *label = [btn viewWithTag:102];
        NSString *shortName = (node.displayName && node.displayName.length > 9) ? [node.displayName substringToIndex:9] : (node.displayName ?: @"NODE");
        label.text = [NSString stringWithFormat:@"%@ [%ld]", shortName, (long)node.rssi];
        
        CGFloat radius = node.normalizedDistance * maxRadius;
        CGFloat x = center.x + sin(node.angleRadians) * radius;
        CGFloat y = center.y - cos(node.angleRadians) * radius;
        
        [UIView animateWithDuration:0.25 animations:^{
            btn.center = CGPointMake(x + 50, y);
            if ([node.identifier isEqualToString:self->_selectedNodeID]) {
                self->_lockReticle.center = CGPointMake(x + 8, y);
            }
        }];
    }
    
    NSArray *allKeys = [_nodeButtons allKeys];
    for (NSString *key in allKeys) {
        if (![activeIDs containsObject:key]) {
            UIButton *oldBtn = _nodeButtons[key];
            [oldBtn removeFromSuperview];
            [_nodeButtons removeObjectForKey:key];
            if ([key isEqualToString:_selectedNodeID]) {
                [self clearSelection];
            }
        }
    }
}

- (void)nodeTapped:(UIButton *)sender {
    for (NSString *key in _nodeButtons) {
        if (_nodeButtons[key] == sender) {
            _selectedNodeID = key;
            for (SpectraRadarNode *node in _currentNodes) {
                if ([node.identifier isEqualToString:key]) {
                    UIView *dot = [sender viewWithTag:101];
                    _lockReticle.center = [sender convertPoint:dot.center toView:_nodesContainer];
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
                UIButton *btn = _nodeButtons[node.identifier];
                if (btn) {
                    btn.alpha = 1.0;
                    [[HapticManager shared] triggerRadarPing];
                    [UIView animateWithDuration:kRadarSweepDuration * 0.85 animations:^{
                        btn.alpha = 0.40;
                    }];
                }
            }
        }
    }
}

@end
