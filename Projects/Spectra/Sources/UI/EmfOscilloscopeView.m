#import "EmfOscilloscopeView.h"
#import "SpectraConfig.h"

@implementation EmfOscilloscopeView {
    CAShapeLayer *_waveformLayer;
    NSMutableArray<NSNumber *> *_history;
    NSInteger _maxPoints;
    double _runningAverage;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = SpectraLensBackgroundColor();
        self.layer.cornerRadius = 10.0;
        self.layer.borderWidth = 1.2;
        self.clipsToBounds = YES;
        
        _runningAverage = 50.0;
        _maxPoints = (NSInteger)(frame.size.width / 4.0);
        _history = [NSMutableArray arrayWithCapacity:_maxPoints];
        for (NSInteger i = 0; i < _maxPoints; i++) {
            [_history addObject:@(50.0)];
        }
        
        _waveformLayer = [CAShapeLayer layer];
        _waveformLayer.fillColor = [UIColor clearColor].CGColor;
        _waveformLayer.lineWidth = 1.5;
        [self.layer addSublayer:_waveformLayer];
        
        [self setThemeColor:SpectraPrimaryColorForMode(SpectraFrequencyModeTechno)];
    }
    return self;
}

- (void)setThemeColor:(UIColor *)themeColor {
    _themeColor = themeColor;
    self.layer.borderColor = [themeColor colorWithAlphaComponent:0.6].CGColor;
    _waveformLayer.strokeColor = themeColor.CGColor;
}

- (void)pushValue:(double)value {
    [_history removeObjectAtIndex:0];
    [_history addObject:@(value)];
    _runningAverage = (_runningAverage * 0.95) + (value * 0.05);
    [self renderWaveform];
}

- (void)renderWaveform {
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGFloat midY = self.bounds.size.height / 2.0;
    CGFloat stepX = self.bounds.size.width / (CGFloat)(_maxPoints - 1);
    
    // Адаптивное отклонение вокруг скользящего среднего
    for (NSInteger i = 0; i < _history.count; i++) {
        double val = [_history[i] doubleValue];
        double diff = val - _runningAverage;
        
        // Масштабируем колебания в пределах высоты рамки
        CGFloat y = midY - (CGFloat)(diff * 0.7);
        y = MAX(5.0, MIN(self.bounds.size.height - 5.0, y));
        
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
