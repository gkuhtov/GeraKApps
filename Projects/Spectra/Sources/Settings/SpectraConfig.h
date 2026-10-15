#import <UIKit/UIKit.h>

#pragma mark - 📡 Настройки датчиков (Магнитометр и Компас)
static const NSTimeInterval kSensorUpdateInterval = 0.08;
static const double kSensorSmoothingFactor        = 0.25;

static const double kEmfNormalMax      = 50.0;
static const double kEmfWarningLevel   = 65.0;
static const double kEmfCriticalLevel  = 85.0;

#pragma mark - 📶 Настройки Bluetooth-сканера (BLE Radar)
// Минимальный порог сигнала в dBm (всё, что слабее -92 dBm, отсекается как шум)
static const NSInteger kBleMinRssiThreshold       = -92;
// Сигнал вплотную к устройству (центр радара)
static const NSInteger kBleMaxRssiThreshold       = -35;
// Время жизни метки без сигнала (в секундах), после чего она гаснет
static const NSTimeInterval kBleNodeStaleTimeout  = 10.0;
// Частота обновления позиций на экране
static const NSTimeInterval kRadarTargetRefresh   = 0.1;

#pragma mark - 🖥 Геометрия и сетка радара
static const CGFloat kRadarHorizontalMargin = 16.0;
static const CGFloat kRadarTopOffset        = 70.0;
static const CGFloat kRadarHeight           = 380.0;
static const CGFloat kRadarCornerRadius     = 18.0;
static const CGFloat kRadarBorderWidth      = 2.0;

static const NSInteger kRadarRingsCount     = 4;
static const CGFloat kRadarSweepDuration    = 3.0;
static const CGFloat kTargetDotSize         = 8.0;

#pragma mark - 🎨 Палитры частотных режимов (Chameleon CRT)
typedef NS_ENUM(NSInteger, SpectraFrequencyMode) {
    SpectraFrequencyModeTechno  = 0,
    SpectraFrequencyModeElectra = 1,
    SpectraFrequencyModeSpectra = 2
};

static inline UIColor* SpectraPrimaryColorForMode(SpectraFrequencyMode mode) {
    switch (mode) {
        case SpectraFrequencyModeTechno:
            return [UIColor colorWithRed:0.00 green:1.00 blue:0.61 alpha:1.0];
        case SpectraFrequencyModeElectra:
            return [UIColor colorWithRed:0.00 green:0.82 blue:1.00 alpha:1.0];
        case SpectraFrequencyModeSpectra:
            return [UIColor colorWithRed:1.00 green:0.55 blue:0.00 alpha:1.0];
    }
}

static inline UIColor* SpectraBackgroundColor(void) {
    return [UIColor colorWithRed:0.04 green:0.05 blue:0.07 alpha:1.0];
}

static inline UIColor* SpectraLensBackgroundColor(void) {
    return [UIColor colorWithRed:0.02 green:0.04 blue:0.03 alpha:1.0];
}
