#import "SpectraViewController.h"
#import "SpectraConfig.h"
#import "RadarLensView.h"
#import "SensorManager.h"
#import "BluetoothManager.h"
#import "HapticManager.h"

@interface SpectraViewController () <SensorManagerDelegate, BluetoothManagerDelegate> {
    RadarLensView *_radarLens;
    UILabel *_azimuthLabel;
    UILabel *_emfLabel;
    UILabel *_nodesCountLabel;
    UIButton *_helpButton;
    UISegmentedControl *_freqControl;
    SensorManager *_sensorManager;
    BluetoothManager *_bluetoothManager;
    SpectraFrequencyMode _currentMode;
}
@end

@implementation SpectraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = SpectraBackgroundColor();
    _currentMode = SpectraFrequencyModeTechno;
    
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
    
    _nodesCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, kRadarHeight - 36, 180, 24)];
    _nodesCountLabel.font = [UIFont fontWithName:@"Courier-Bold" size:13];
    _nodesCountLabel.textColor = initialColor;
    _nodesCountLabel.text = @"NODES: 0 SCANNING...";
    [_radarLens addSubview:_nodesCountLabel];
    
    _helpButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _helpButton.frame = CGRectMake(width - 44, kRadarHeight - 44, 34, 34);
    [_helpButton setTitle:@"[?]" forState:UIControlStateNormal];
    [_helpButton setTitleColor:initialColor forState:UIControlStateNormal];
    _helpButton.titleLabel.font = [UIFont fontWithName:@"Courier-Bold" size:14];
    [_helpButton addTarget:self action:@selector(openHelpPopup) forControlEvents:UIControlEventTouchUpInside];
    [_radarLens addSubview:_helpButton];
    
    _freqControl = [[UISegmentedControl alloc] initWithItems:@[@"ТЕХНО", @"ЭЛЕКТРА", @"СПЕКТРА"]];
    _freqControl.frame = CGRectMake(kRadarHorizontalMargin, self.view.bounds.size.height - 110, width, 42);
    _freqControl.selectedSegmentIndex = 0;
    [_freqControl addTarget:self action:@selector(frequencyModeChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_freqControl];
}

- (void)frequencyModeChanged:(UISegmentedControl *)sender {
    _currentMode = (SpectraFrequencyMode)sender.selectedSegmentIndex;
    [[HapticManager shared] triggerSelectionTick];
    
    UIColor *newColor = SpectraPrimaryColorForMode(_currentMode);
    _radarLens.themeColor = newColor;
    _azimuthLabel.textColor = newColor;
    _emfLabel.textColor = newColor;
    _nodesCountLabel.textColor = newColor;
    [_helpButton setTitleColor:newColor forState:UIControlStateNormal];
}

#pragma mark - Делегаты датчиков и Bluetooth

- (void)didUpdateEmfValue:(double)microTeslas {
    _emfLabel.text = [NSString stringWithFormat:@"%.1f µT", microTeslas];
    
    if (microTeslas >= kEmfCriticalLevel) {
        [[HapticManager shared] triggerCriticalImpact];
    } else if (microTeslas >= kEmfWarningLevel && _currentMode == SpectraFrequencyModeElectra) {
        [[HapticManager shared] triggerWarningPulse];
    }
}

- (void)didUpdateAzimuth:(double)degrees direction:(NSString *)cardinal {
    _azimuthLabel.text = [NSString stringWithFormat:@"AZ: %03.0f° %@", degrees, cardinal];
}

- (void)didUpdateRadarNodes:(NSArray<SpectraRadarNode *> *)nodes {
    _nodesCountLabel.text = [NSString stringWithFormat:@"NODES: %lu ACTIVE", (unsigned long)nodes.count];
    [_radarLens updateWithNodes:nodes];
}

#pragma mark - Справка

- (void)openHelpPopup {
    [[HapticManager shared] triggerWarningPulse];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"СПРАВКА SPECTRA"
                                                                   message:@"• NODES: Активные BLE-узлы вокруг устройства. Чем ближе точка к центру, тем выше мощность сигнала (dBm).\n• При прохождении сканирующего луча через цель срабатывает импульс Taptic Engine."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Тест Taptic" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[HapticManager shared] triggerCriticalImpact];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Закрыть" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
