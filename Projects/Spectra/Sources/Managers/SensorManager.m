#import "SensorManager.h"
#import "SpectraConfig.h"

@implementation SensorManager {
    CMMotionManager *_motionManager;
    CLLocationManager *_locationManager;
    double _filteredEmf;
}

- (instancetype)init {
    if (self = [super init]) {
        _motionManager = [[CMMotionManager alloc] init];
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _filteredEmf = 0.0;
    }
    return self;
}

- (void)startScanning {
    if (_motionManager.isMagnetometerAvailable) {
        _motionManager.magnetometerUpdateInterval = kSensorUpdateInterval;
        [_motionManager startMagnetometerUpdatesToQueue:[NSOperationQueue mainQueue]
                                            withHandler:^(CMMagnetometerData *data, NSError *error) {
            if (error || !data) return;
            double rawEmf = sqrt(pow(data.magneticField.x, 2) +
                                 pow(data.magneticField.y, 2) +
                                 pow(data.magneticField.z, 2));
            
            if (self->_filteredEmf == 0.0) {
                self->_filteredEmf = rawEmf;
            } else {
                self->_filteredEmf = (rawEmf * kSensorSmoothingFactor) +
                                     (self->_filteredEmf * (1.0 - kSensorSmoothingFactor));
            }
            [self.delegate didUpdateEmfValue:self->_filteredEmf];
        }];
    }
    
    if ([CLLocationManager headingAvailable]) {
        _locationManager.headingFilter = 1.0;
        [_locationManager startUpdatingHeading];
    }
}

- (void)stopScanning {
    [_motionManager stopMagnetometerUpdates];
    [_locationManager stopUpdatingHeading];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
    double heading = newHeading.magneticHeading;
    if (heading < 0) return;
    
    NSArray *directions = @[@"N", @"NE", @"E", @"SE", @"S", @"SW", @"W", @"NW"];
    int index = (int)floor(((heading + 22.5) / 45.0)) % 8;
    [self.delegate didUpdateAzimuth:heading direction:directions[index]];
}

@end
