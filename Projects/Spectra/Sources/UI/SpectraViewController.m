#import "SpectraViewController.h"
#import "SpectraConfig.h"
#import "RadarLensView.h"
#import "SensorManager.h"
#import "HapticManager.h"

@interface SpectraViewController () <SensorManagerDelegate> {
    RadarLensView *_radarLens;
    UILabel *_azimuthLabel;
    UILabel *_emfLabel;
    UIButton *_helpButton;
    UISegmentedControl *_freqControl;
    SensorManager *_sensorManager;
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
    [_helpButton setTitleColor:newColor forState:UIControlStateNormal];
}

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

- (void)openHelpPopup {
    [[HapticManager shared] triggerWarningPulse];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"СПРАВКА SPECTRA"
                                                                   message:@"• ТЕХНО: Базовый обзор сетки и ориентации.\n• ЭЛЕКТРА: Повышенная тактильная чувствительность к ЭМ-полю.\n• СПЕКТРА: Контрастный янтарный спектр."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Тест Taptic" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[HapticManager shared] triggerCriticalImpact];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Закрыть" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
