#import "SpectraViewController.h"
#import "SpectraConfig.h"
#import "RadarLensView.h"
#import "SensorManager.h"
#import "BluetoothManager.h"
#import "HapticManager.h"
#import "TargetDetailsCard.h"
#import "EmfOscilloscopeView.h"
#import "AudioPulseManager.h"
#import "BlackboxLogManager.h"
#import "BlackboxViewController.h"

@interface SpectraViewController () <SensorManagerDelegate, BluetoothManagerDelegate, RadarLensViewDelegate, TargetDetailsCardDelegate> {
    RadarLensView *_radarLens;
    EmfOscilloscopeView *_oscilloscope;
    UILabel *_azimuthLabel;
    UILabel *_emfLabel;
    UILabel *_nodesCountLabel;
    UIButton *_helpButton;
    UIButton *_muteButton;
    UIButton *_logButton;
    UISegmentedControl *_freqControl;
    SensorManager *_sensorManager;
    BluetoothManager *_bluetoothManager;
    SpectraFrequencyMode _currentMode;
    TargetDetailsCard *_detailsCard;
    SpectraRadarNode *_trackedNode;
    double _currentHeadingDeg;
}
@end

@implementation SpectraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = SpectraBackgroundColor();
    _currentMode = SpectraFrequencyModeTechno;
    _currentHeadingDeg = 0.0;
    
    [self setupInterface];
    
    _sensorManager = [[SensorManager alloc] init];
    _sensorManager.delegate = self;
    [_sensorManager startScanning];
    
    _bluetoothManager = [[BluetoothManager alloc] init];
    _bluetoothManager.delegate = self;
    [_bluetoothManager startScanning];
}

- (void)setupInterface {
    CGFloat width = self.view.bounds.size.width - (kRadarHorizontalMargin * 2);
    
    _radarLens = [[RadarLensView alloc] initWithFrame:CGRectMake(kRadarHorizontalMargin, kRadarTopOffset, width, kRadarHeight)];
    _radarLens.delegate = self;
    [self.view addSubview:_radarLens];
    [_radarLens startSweepAnimation];
    
    UIColor *initialColor = SpectraPrimaryColorForMode(_currentMode);
    
    _azimuthLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 12, 160, 24)];
    _azimuthLabel.font = [UIFont fontWithName:@"Courier-Bold" size:14];
    _azimuthLabel.textColor = initialColor;
    _azimuthLabel.text = @"AZ: 000° N";
    [_radarLens addSubview:_azimuthLabel];
    
    _emfLabel = [[UILabel alloc] initWithFrame:CGRectMake(width - 136, 12, 120, 24)];
    _emfLabel.font = [UIFont fontWithName:@"Courier-Bold" size:14];
    _emfLabel.textColor = initialColor;
    _emfLabel.textAlignment = NSTextAlignmentRight;
    _emfLabel.text = @"0.0 µT";
    [_radarLens addSubview:_emfLabel];
    
    _nodesCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, kRadarHeight - 36, 150, 24)];
    _nodesCountLabel.font = [UIFont fontWithName:@"Courier-Bold" size:13];
    _nodesCountLabel.textColor = initialColor;
    _nodesCountLabel.text = @"NODES: 0 SCANNING...";
    [_radarLens addSubview:_nodesCountLabel];
    
    // Кнопка открытия журнала BLACKBOX [LOG]
    _logButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _logButton.frame = CGRectMake(width - 165, kRadarHeight - 44, 55, 34);
    [_logButton setTitle:@"[LOG]" forState:UIControlStateNormal];
    [_logButton setTitleColor:initialColor forState:UIControlStateNormal];
    _logButton.titleLabel.font = [UIFont fontWithName:@"Courier-Bold" size:12];
    [_logButton addTarget:self action:@selector(openLogViewer) forControlEvents:UIControlEventTouchUpInside];
    [_radarLens addSubview:_logButton];
    
    _muteButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _muteButton.frame = CGRectMake(width - 105, kRadarHeight - 44, 66, 34);
    [_muteButton setTitle:@"[MUTE]" forState:UIControlStateNormal];
    [_muteButton setTitleColor:initialColor forState:UIControlStateNormal];
    _muteButton.titleLabel.font = [UIFont fontWithName:@"Courier-Bold" size:12];
    [_muteButton addTarget:self action:@selector(toggleMute) forControlEvents:UIControlEventTouchUpInside];
    [_radarLens addSubview:_muteButton];
    
    _helpButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _helpButton.frame = CGRectMake(width - 36, kRadarHeight - 44, 28, 34);
    [_helpButton setTitle:@"[?]" forState:UIControlStateNormal];
    [_helpButton setTitleColor:initialColor forState:UIControlStateNormal];
    _helpButton.titleLabel.font = [UIFont fontWithName:@"Courier-Bold" size:14];
    [_helpButton addTarget:self action:@selector(openHelpPopup) forControlEvents:UIControlEventTouchUpInside];
    [_radarLens addSubview:_helpButton];
    
    CGFloat oscY = CGRectGetMaxY(_radarLens.frame) + 10;
    _oscilloscope = [[EmfOscilloscopeView alloc] initWithFrame:CGRectMake(kRadarHorizontalMargin, oscY, width, 55)];
    [self.view addSubview:_oscilloscope];
    
    _detailsCard = [[TargetDetailsCard alloc] initWithFrame:CGRectMake(kRadarHorizontalMargin, oscY - 4, width, 115)];
    _detailsCard.delegate = self;
    _detailsCard.alpha = 0.0;
    _detailsCard.hidden = YES;
    [self.view addSubview:_detailsCard];
    
    _freqControl = [[UISegmentedControl alloc] initWithItems:@[@"ТЕХНО", @"ЭЛЕКТРА", @"СПЕКТРА"]];
    _freqControl.frame = CGRectMake(kRadarHorizontalMargin, self.view.bounds.size.height - 110, width, 42);
    _freqControl.selectedSegmentIndex = 0;
    [_freqControl addTarget:self action:@selector(frequencyModeChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_freqControl];
}

- (void)openLogViewer {
    [[HapticManager shared] triggerSelectionTick];
    BlackboxViewController *logVC = [[BlackboxViewController alloc] init];
    logVC.themeColor = SpectraPrimaryColorForMode(_currentMode);
    logVC.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:logVC animated:YES completion:nil];
}

- (void)toggleMute {
    AudioPulseManager *audio = [AudioPulseManager shared];
    audio.isMuted = !audio.isMuted;
    [[HapticManager shared] triggerSelectionTick];
    
    if (audio.isMuted) {
        [_muteButton setTitle:@"[UNMUTE]" forState:UIControlStateNormal];
        _muteButton.alpha = 0.55;
    } else {
        [_muteButton setTitle:@"[MUTE]" forState:UIControlStateNormal];
        _muteButton.alpha = 1.0;
    }
}

- (void)frequencyModeChanged:(UISegmentedControl *)sender {
    _currentMode = (SpectraFrequencyMode)sender.selectedSegmentIndex;
    [[HapticManager shared] triggerSelectionTick];
    
    UIColor *newColor = SpectraPrimaryColorForMode(_currentMode);
    _radarLens.themeColor = newColor;
    _oscilloscope.themeColor = newColor;
    _detailsCard.themeColor = newColor;
    _azimuthLabel.textColor = newColor;
    _emfLabel.textColor = newColor;
    _nodesCountLabel.textColor = newColor;
    [_logButton setTitleColor:newColor forState:UIControlStateNormal];
    [_muteButton setTitleColor:newColor forState:UIControlStateNormal];
    [_helpButton setTitleColor:newColor forState:UIControlStateNormal];
}

#pragma mark - RadarLensViewDelegate

- (void)radarDidSelectNode:(SpectraRadarNode *)node {
    _trackedNode = node;
    [_detailsCard configureWithNode:node];
    _detailsCard.hidden = NO;
    [UIView animateWithDuration:0.25 animations:^{
        self->_detailsCard.alpha = 1.0;
        self->_oscilloscope.alpha = 0.15;
    }];
}

#pragma mark - TargetDetailsCardDelegate

- (void)targetDetailsDidToggleTracking:(BOOL)isTracking {
    _radarLens.isTrackingMode = isTracking;
    if (isTracking && _trackedNode) {
        [[BlackboxLogManager shared] logNodeTrackingStarted:_trackedNode.displayName uuid:_trackedNode.identifier rssi:_trackedNode.rssi];
        [[AudioPulseManager shared] updateWithTrackingRssi:_trackedNode.rssi];
    }
}

- (void)targetDetailsDidRequestDismiss {
    _trackedNode = nil;
    _radarLens.isTrackingMode = NO;
    [UIView animateWithDuration:0.2 animations:^{
        self->_detailsCard.alpha = 0.0;
        self->_oscilloscope.alpha = 1.0;
    } completion:^(BOOL finished) {
        self->_detailsCard.hidden = YES;
        [self->_radarLens clearSelection];
    }];
}

#pragma mark - Делегаты датчиков и Bluetooth

- (void)didUpdateEmfValue:(double)microTeslas {
    _emfLabel.text = [NSString stringWithFormat:@"%.1f µT", microTeslas];
    [_oscilloscope pushValue:microTeslas];
    
    if (microTeslas >= 120.0) {
        [[BlackboxLogManager shared] logEmfAnomaly:microTeslas azimuth:_currentHeadingDeg];
    }
    
    if (!_radarLens.isTrackingMode) {
        [[AudioPulseManager shared] updateWithEmf:microTeslas];
    }
    
    if (microTeslas >= kEmfCriticalLevel) {
        [[HapticManager shared] triggerCriticalImpact];
    } else if (microTeslas >= kEmfWarningLevel && _currentMode == SpectraFrequencyModeElectra) {
        [[HapticManager shared] triggerWarningPulse];
    }
}

- (void)didUpdateAzimuth:(double)degrees direction:(NSString *)cardinal {
    _currentHeadingDeg = degrees;
    _azimuthLabel.text = [NSString stringWithFormat:@"AZ: %03.0f° %@", degrees, cardinal];
    [_radarLens updateCompassHeading:degrees];
    [_bluetoothManager updateCurrentDeviceAzimuth:degrees];
}

- (void)didUpdateRadarNodes:(NSArray<SpectraRadarNode *> *)nodes {
    _nodesCountLabel.text = [NSString stringWithFormat:@"NODES: %lu ACTIVE", (unsigned long)nodes.count];
    [_radarLens updateWithNodes:nodes];
    
    for (SpectraRadarNode *node in nodes) {
        double bearingDeg = (node.angleRadians * 180.0) / M_PI;
        [[BlackboxLogManager shared] logNodeDiscovered:node.displayName category:node.deviceCategory rssi:node.rssi bearing:bearingDeg uuid:node.identifier];
    }
    
    if (_radarLens.isTrackingMode && _trackedNode) {
        for (SpectraRadarNode *n in nodes) {
            if ([n.identifier isEqualToString:_trackedNode.identifier]) {
                _trackedNode = n;
                [_detailsCard configureWithNode:n];
                [[AudioPulseManager shared] updateWithTrackingRssi:n.rssi];
                break;
            }
        }
    }
}

#pragma mark - Справка

- (void)openHelpPopup {
    [[HapticManager shared] triggerWarningPulse];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"СПРАВКА SPECTRA"
                                                                   message:@"• [LOG]: Открытие тактического бортового журнала сессии (Blackbox) с фиксацией найденных устройств, всплесков поля и возможностью экспорта в TXT.\n• [ПЕЛЕНГ]: Наведение вектора на цель с привязкой к компасу."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Тест Taptic" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[HapticManager shared] triggerCriticalImpact];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Закрыть" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
