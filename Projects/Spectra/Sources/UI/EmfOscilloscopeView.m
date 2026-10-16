#import "EmfOscilloscopeView.h"
#import "SpectraConfig.h"

@implementation EmfOscilloscopeView {
    CAShapeLayer *_waveformLayer;
    NSMutableArray<NSNumber *> *_history;
    NSInteger _maxPoints;
    double _runningAverage;
    double _currentPeak;
    
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
        _currentPeak = 50.0;
        _maxPoints = (NSInteger)(frame.size.width / 4.0);
        _history = [NSMutableArray arrayWithCapacity:_maxPoints];
        for (NSInteger i = 0; i < _maxPoints; i++) {
            [_history addObject:@(50.0)];
        }
        
        _waveformLayer = [CAShapeLayer layer];
        _waveformLayer.fillColor = [UIColor clearColor].CGColor;
        _waveformLayer.lineWidth = 1.5;
        [self.layer addSublayer:_waveformLayer];
        
        // Разметка и единицы измерения
        _headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 4, 180, 12)];
        _headerLabel.font = [UIFont fontWithName:@"Courier-Bold" size:9];
        _headerLabel.text = @"EMF OSCILLOGRAM | 50Hz";
        [self addSubview:_headerLabel];
        
        _currentValLabel = [[UILabel alloc] initWithFrame:CGRectMake(frame.size.width - 130, 4, 122, 12)];
        _currentValLabel.font = [UIFont fontWithName:@"Courier-Bold" size:9];
        _currentValLabel.textAlignment = NSTextAlignmentRight;
        _currentValLabel.text = @"FLUX: 0.0 µT";
        [self addSubview:_currentValLabel];
        
        _maxScaleLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 16, 80, 10)];
        _maxScaleLabel.font = [UIFont fontWithName:@"Courier" size:8];
        _maxScaleLabel.alpha = 0.6;
        _maxScaleLabel.text = @"+100 µT";
        [self addSubview:_maxScaleLabel];
        
        _minScaleLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, frame.size.height - 12, 80, 10)];
        _minScaleLabel.font = [UIFont fontWithName:@"Courier" size:8];
        _minScaleLabel.alpha = 0.6;
        _minScaleLabel.text = @"-100 µT";
        [self addSubview:_minScaleLabel];
        
        [self setThemeColor:SpectraPrimaryColorForMode(SpectraFrequencyModeTechno)];
    }
    return self;
}

- (void)setThemeColor:(UIColor *)themeColor {
    _themeColor = themeColor;
    self.layer.borderColor = [themeColor colorWithAlphaComponent:0.6].CGColor;
    _waveformLayer.strokeColor = themeColor.CGColor;
    _headerLabel.textColor = themeColor;
    _currentValLabel.textColor = themeColor;
    _maxScaleLabel.textColor = themeColor;
    _minScaleLabel.textColor = themeColor;
}

- (void)pushValue:(double)value {
    [_history removeObjectAtIndex:0];
    [_history addObject:@(value)];
    _runningAverage = (_runningAverage * 0.95) + (value * 0.05);
    _currentPeak = value;
    
    _currentValLabel.text = [NSString stringWithFormat:@"FLUX: %.1f µT", value];
    
    // Адаптивные метки диапазона
    double range = MAX(30.0, fabs(value - _runningAverage) * 1.6);
    _maxScaleLabel.text = [NSString stringWithFormat:@"+%.0f µT", _runningAverage + range];
    _minScaleLabel.text = [NSString stringWithFormat:@"-%.0f µT", MAX(0.0, _runningAverage - range)];
    
    [self renderWaveformWithRange:range];
}

- (void)renderWaveformWithRange:(double)range {
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGFloat midY = self.bounds.size.height / 2.0;
    CGFloat stepX = self.bounds.size.width / (CGFloat)(_maxPoints - 1);
    CGFloat usableHeight = (self.bounds.size.height / 2.0) - 8.0;
    
    for (NSInteger i = 0; i < _history.count; i++) {
        double val = [_history[i] doubleValue];
        double diff = val - _runningAverage;
        
        // Нормализация в пределах адаптивного диапазона
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
