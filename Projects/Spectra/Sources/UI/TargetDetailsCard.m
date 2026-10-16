#import "TargetDetailsCard.h"
#import "SpectraConfig.h"
#import "HapticManager.h"

@implementation TargetDetailsCard {
    UILabel *_titleLabel;
    UILabel *_categoryLabel;
    UILabel *_uuidLabel;
    UILabel *_signalLabel;
    UILabel *_distanceLabel;
    UILabel *_bearingLabel;
    UIButton *_dismissBtn;
    UIButton *_copyBtn;
    UIButton *_trackBtn;
    NSString *_currentUUID;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor colorWithRed:0.02 green:0.05 blue:0.04 alpha:0.95];
        self.layer.cornerRadius = 14.0;
        self.layer.borderWidth = 1.5;
        self.clipsToBounds = YES;
        _isTrackingActive = NO;
        
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(14, 8, frame.size.width - 28, 20)];
        _titleLabel.font = [UIFont fontWithName:@"Courier-Bold" size:14];
        [self addSubview:_titleLabel];
        
        _categoryLabel = [[UILabel alloc] initWithFrame:CGRectMake(14, 28, frame.size.width - 100, 16)];
        _categoryLabel.font = [UIFont fontWithName:@"Courier-Bold" size:10];
        _categoryLabel.alpha = 0.85;
        [self addSubview:_categoryLabel];
        
        _uuidLabel = [[UILabel alloc] initWithFrame:CGRectMake(14, 44, frame.size.width - 100, 16)];
        _uuidLabel.font = [UIFont fontWithName:@"Courier" size:10];
        _uuidLabel.alpha = 0.6;
        [self addSubview:_uuidLabel];
        
        _copyBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        _copyBtn.frame = CGRectMake(frame.size.width - 92, 28, 80, 22);
        [_copyBtn setTitle:@"[КОПИР]" forState:UIControlStateNormal];
        _copyBtn.titleLabel.font = [UIFont fontWithName:@"Courier-Bold" size:11];
        [_copyBtn addTarget:self action:@selector(copyUUID) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_copyBtn];
        
        _signalLabel = [[UILabel alloc] initWithFrame:CGRectMake(14, 64, 110, 18)];
        _signalLabel.font = [UIFont fontWithName:@"Courier" size:12];
        [self addSubview:_signalLabel];
        
        _distanceLabel = [[UILabel alloc] initWithFrame:CGRectMake(124, 64, 110, 18)];
        _distanceLabel.font = [UIFont fontWithName:@"Courier" size:12];
        [self addSubview:_distanceLabel];
        
        _bearingLabel = [[UILabel alloc] initWithFrame:CGRectMake(14, 84, 150, 18)];
        _bearingLabel.font = [UIFont fontWithName:@"Courier" size:12];
        [self addSubview:_bearingLabel];
        
        _trackBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        _trackBtn.frame = CGRectMake(frame.size.width - 180, 74, 84, 28);
        [_trackBtn setTitle:@"[ПЕЛЕНГ]" forState:UIControlStateNormal];
        _trackBtn.titleLabel.font = [UIFont fontWithName:@"Courier-Bold" size:11];
        [_trackBtn addTarget:self action:@selector(toggleTrackingTapped) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_trackBtn];
        
        _dismissBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        _dismissBtn.frame = CGRectMake(frame.size.width - 92, 74, 80, 28);
        [_dismissBtn setTitle:@"СБРОС [X]" forState:UIControlStateNormal];
        _dismissBtn.titleLabel.font = [UIFont fontWithName:@"Courier-Bold" size:11];
        [_dismissBtn addTarget:self action:@selector(dismissTapped) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_dismissBtn];
        
        [self setThemeColor:SpectraPrimaryColorForMode(SpectraFrequencyModeTechno)];
    }
    return self;
}

- (void)setThemeColor:(UIColor *)themeColor {
    _themeColor = themeColor;
    self.layer.borderColor = [themeColor colorWithAlphaComponent:0.8].CGColor;
    _titleLabel.textColor = themeColor;
    _categoryLabel.textColor = themeColor;
    _uuidLabel.textColor = themeColor;
    _signalLabel.textColor = themeColor;
    _distanceLabel.textColor = themeColor;
    _bearingLabel.textColor = themeColor;
    [_copyBtn setTitleColor:themeColor forState:UIControlStateNormal];
    [_trackBtn setTitleColor:_isTrackingActive ? [UIColor yellowColor] : themeColor forState:UIControlStateNormal];
    [_dismissBtn setTitleColor:[UIColor colorWithRed:1.0 green:0.3 blue:0.3 alpha:1.0] forState:UIControlStateNormal];
}

- (void)configureWithNode:(SpectraRadarNode *)node {
    _currentUUID = node.identifier;
    _titleLabel.text = [NSString stringWithFormat:@"ЦЕЛЬ: %@", [node.displayName uppercaseString]];
    _categoryLabel.text = [NSString stringWithFormat:@"ТИП: %@", node.deviceCategory ?: @"РАДИОУЗЕЛ"];
    _uuidLabel.text = [NSString stringWithFormat:@"ID: %@", node.identifier];
    _signalLabel.text = [NSString stringWithFormat:@"RSSI: %ld dBm", (long)node.rssi];
    
    double ratio = (double)(-40 - node.rssi) / 25.0;
    double approxMeters = pow(10.0, ratio);
    approxMeters = MAX(0.2, MIN(25.0, approxMeters));
    _distanceLabel.text = [NSString stringWithFormat:@"ДИСТ: ~%.1f м", approxMeters];
    
    double bearingDeg = (node.angleRadians * 180.0) / M_PI;
    _bearingLabel.text = [NSString stringWithFormat:@"ПЕЛЕНГ: %03.0f°", bearingDeg];
}

- (void)toggleTrackingTapped {
    _isTrackingActive = !_isTrackingActive;
    [[HapticManager shared] triggerTargetLock];
    [_trackBtn setTitle:_isTrackingActive ? @"[ВЕДЕНИЕ!]" : @"[ПЕЛЕНГ]" forState:UIControlStateNormal];
    [_trackBtn setTitleColor:_isTrackingActive ? [UIColor yellowColor] : _themeColor forState:UIControlStateNormal];
    [self.delegate targetDetailsDidToggleTracking:_isTrackingActive];
}

- (void)resetTrackingState {
    _isTrackingActive = NO;
    [_trackBtn setTitle:@"[ПЕЛЕНГ]" forState:UIControlStateNormal];
    [_trackBtn setTitleColor:_themeColor forState:UIControlStateNormal];
}

- (void)copyUUID {
    if (_currentUUID.length > 0) {
        [UIPasteboard generalPasteboard].string = _currentUUID;
        [[HapticManager shared] triggerSelectionTick];
        [_copyBtn setTitle:@"СКОПИРОВАНО" forState:UIControlStateNormal];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self->_copyBtn setTitle:@"[КОПИР]" forState:UIControlStateNormal];
        });
    }
}

- (void)dismissTapped {
    [self resetTrackingState];
    [[HapticManager shared] triggerSelectionTick];
    [self.delegate targetDetailsDidRequestDismiss];
}

@end
