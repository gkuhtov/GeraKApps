#import "EmfOscilloscopeView.h"
#import "SpectraConfig.h"

@implementation EmfOscilloscopeView {
    CAShapeLayer *_gridLayer;
    CAShapeLayer *_waveformLayer;
    NSMutableArray<NSNumber *> *_history;
    NSInteger _maxPoints;
    double _runningAverage;
    
    UILabel *_headerLabel;
    UILabel *_maxScaleLabel;
    UILabel *_minScaleLabel;
    UILabel *_currentValLabel;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = SpectraLensBackgroundColor();
        self.layer.cornerRadius = 10.0;
        self.layer.borderWidth = 1.2;
        self.clipsToBounds = YES;
        
        _runningAverage = 50.0;
        _maxPoints = (NSInteger)(frame.size.width / 3.0);
        _history = [NSMutableArray arrayWithCapacity:_maxPoints];
        for (NSInteger i = 0; i < _maxPoints; i++) {
            [_history addObject:@(50.0)];
        }
        
        // Фоновая центральная линия сетки (пунктир)
        _gridLayer = [CAShapeLayer layer];
        _gridLayer.fillColor = [UIColor clearColor].CGColor;
        _gridLayer.lineWidth = 0.8;
        _gridLayer.lineDashPattern = @[@4, @4];
        [self.layer addSublayer:_gridLayer];
        
        _waveformLayer = [CAShapeLayer layer];
        _waveformLayer.fillColor = [UIColor clearColor].CGColor;
        _waveformLayer.lineWidth = 1.6;
        [self.layer addSublayer:_waveformLayer];
        
        // Разметка без перекрытий
        _headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 3, 150, 12)];
        _headerLabel.font = [UIFont fontWithName:@"Courier-Bold" size:9];
        _headerLabel.text = @"EMF OSCILLOGRAM | 50Hz";
        [self addSubview:_headerLabel];
        
        _currentValLabel = [[UILabel alloc] initWithFrame:CGRectMake(frame.size.width - 130, 3, 122, 12)];
        _currentValLabel.font = [UIFont fontWithName:@"Courier-Bold" size:9];
        _currentValLabel.textAlignment = NSTextAlignmentRight;
        _currentValLabel.text = @"FLUX: 0.0 µT";
        [self addSubview:_currentValLabel];
        
        // Смещаем шкалы ниже строки заголовка
        _maxScaleLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 17, 70, 10)];
        _maxScaleLabel.font = [UIFont fontWithName:@"Courier" size:8];
        _maxScaleLabel.alpha = 0.65;
        _maxScaleLabel.text = @"+10 µT";
        [self addSubview:_maxScaleLabel];
        
        _minScaleLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, frame.size.height - 13, 70, 10)];
        _minScaleLabel.font = [UIFont fontWithName:@"Courier" size:8];
        _minScaleLabel.alpha = 0.65;
        _minScaleLabel.text = @"-10 µT";
        [self addSubview:_minScaleLabel];
        
        [self drawCenterGridLine];
        [self setThemeColor:SpectraPrimaryColorForMode(SpectraFrequencyModeTechno)];
    }
    return self;
}

- (void)drawCenterGridLine {
    CGFloat midY = self.bounds.size.height / 2.0;
    UIBezierPath *gridPath = [UIBezierPath bezierPath];
    [gridPath moveToPoint:CGPointMake(0, midY)];
    [gridPath addLineToPoint:CGPointMake(self.bounds.size.width, midY)];
    _gridLayer.path = gridPath.CGPath;
}

- (void)setThemeColor:(UIColor *)themeColor {
    _themeColor = themeColor;
    self.layer.borderColor = [themeColor colorWithAlphaComponent:0.6].CGColor;
    _gridLayer.strokeColor = [themeColor colorWithAlphaComponent:0.2].CGColor;
    _waveformLayer.strokeColor = themeColor.CGColor;
    _headerLabel.textColor = themeColor;
    _currentValLabel.textColor = themeColor;
    _maxScaleLabel.textColor = themeColor;
    _minScaleLabel.textColor = themeColor;
}

- (void)pushValue:(double)value {
    [_history removeObjectAtIndex:0];
    [_history addObject:@(value)];
    _runningAverage = (_runningAverage * 0.96) + (value * 0.04);
    
    _currentValLabel.text = [NSString stringWithFormat:@"FLUX: %.1f µT", value];
    
    // Динамический диапазон для наглядных колебаний
    double maxDelta = 3.0;
    for (NSNumber *num in _history) {
        double d = fabs([num doubleValue] - _runningAverage);
        if (d > maxDelta) maxDelta = d;
    }
    double range = maxDelta * 1.35;
    
    _maxScaleLabel.text = [NSString stringWithFormat:@"+%.0f µT", _runningAverage + range];
    _minScaleLabel.text = [NSString stringWithFormat:@"-%.0f µT", MAX(0.0, _runningAverage - range)];
    
    [self renderWaveformWithRange:range];
}

- (void)renderWaveformWithRange:(double)range {
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGFloat midY = self.bounds.size.height / 2.0;
    CGFloat stepX = self.bounds.size.width / (CGFloat)(_maxPoints - 1);
    CGFloat usableHeight = (self.bounds.size.height / 2.0) - 10.0;
    
    for (NSInteger i = 0; i < _history.count; i++) {
        double val = [_history[i] doubleValue];
        double diff = val - _runningAverage;
        
        CGFloat normalized = (CGFloat)(diff / range);
        normalized = MAX(-1.0, MIN(1.0, normalized));
        
        CGFloat y = midY - (normalized * usableHeight);
        CGPoint pt = CGPointMake(i * stepX, y);
        
        if (i == 0) {
            [path moveToPoint:pt];
        } else {
            [path addLineToPoint:pt];
        }
    }
    
    _waveformLayer.path = path.CGPath;
}

@end
