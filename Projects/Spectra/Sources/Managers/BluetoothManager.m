#import "BluetoothManager.h"
#import "SpectraConfig.h"

@implementation SpectraRadarNode
@end

@implementation BluetoothManager {
    CBCentralManager *_centralManager;
    NSMutableDictionary<NSString *, SpectraRadarNode *> *_nodesMap;
    NSTimer *_cleanupTimer;
}

- (instancetype)init {
    if (self = [super init]) {
        _nodesMap = [NSMutableDictionary dictionary];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleAppDidBecomeActive)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)handleAppDidBecomeActive {
    NSDate *now = [NSDate date];
    for (SpectraRadarNode *node in _nodesMap.allValues) {
        node.lastSeen = now;
    }
    [self startScanning];
    [self notifyDelegate];
}

- (void)startScanning {
    if (!_centralManager) {
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
    } else if (_centralManager.state == CBManagerStatePoweredOn) {
        [_centralManager stopScan];
        [_centralManager scanForPeripheralsWithServices:nil
                                                options:@{CBCentralManagerScanOptionAllowDuplicatesKey: @YES}];
    }
    
    if (!_cleanupTimer || !_cleanupTimer.isValid) {
        _cleanupTimer = [NSTimer scheduledTimerWithTimeInterval:1.5
                                                         target:self
                                                       selector:@selector(purgeStaleNodes)
                                                       userInfo:nil
                                                        repeats:YES];
    }
}

- (void)stopScanning {
    if (_centralManager && _centralManager.state == CBManagerStatePoweredOn) {
        [_centralManager stopScan];
    }
    [_cleanupTimer invalidate];
    _cleanupTimer = nil;
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state == CBManagerStatePoweredOn) {
        [self startScanning];
    }
}

- (NSString *)identifyDeviceWithPeripheral:(CBPeripheral *)peripheral
                                   advData:(NSDictionary<NSString *,id> *)advData
                                  category:(NSString **)outCategory {
    
    NSString *localName = advData[CBAdvertisementDataLocalNameKey] ?: peripheral.name;
    NSData *mfgData = advData[CBAdvertisementDataManufacturerDataKey];
    NSArray<CBUUID *> *services = advData[CBAdvertisementDataServiceUUIDsKey];
    
    NSString *detectedName = nil;
    NSString *detectedCategory = @"НЕИЗВЕСТНО";

    if (mfgData.length >= 2) {
        const uint8_t *bytes = (const uint8_t *)mfgData.bytes;
        uint16_t companyID = bytes[0] | (bytes[1] << 8);
        
        switch (companyID) {
            case 0x004C: {
                detectedCategory = @"APPLE ЭКОСИСТЕМА";
                if (mfgData.length >= 3) {
                    uint8_t appleType = bytes[2];
                    if (appleType == 0x07) {
                        detectedName = @"AIRPODS";
                        detectedCategory = @"АУДИОСИСТЕМА";
                    } else if (appleType == 0x12) {
                        detectedName = @"AIRTAG / ТРЕКЕР";
                        detectedCategory = @"МЕТКА FIND MY";
                    } else if (appleType == 0x10) {
                        detectedName = @"APPLE-DEVICE";
                        detectedCategory = @"IPHONE / MAC";
                    } else {
                        detectedName = @"APPLE-NODE";
                    }
                } else {
                    detectedName = @"APPLE-NODE";
                }
                break;
            }
            case 0x0075:
                detectedName = @"SAMSUNG-NODE";
                detectedCategory = @"GALAXY DEVICE";
                break;
            case 0x038F:
                detectedName = @"XIAOMI-IOT";
                detectedCategory = @"SMART HOME";
                break;
            case 0x0157:
                detectedName = @"AMAZFIT-WATCH";
                detectedCategory = @"НОСИМОЕ УСТРОЙСТВО";
                break;
            case 0x0006:
                detectedName = @"MS-PC/CONSOLE";
                detectedCategory = @"ВЫЧИСЛИТЕЛЬ";
                break;
            case 0x000A:
            case 0x00E0:
                detectedName = (companyID == 0x00E0) ? @"GOOGLE-DEVICE" : @"BT-AUDIO";
                detectedCategory = @"РАДИОУЗЕЛ";
                break;
            case 0x0059:
                detectedName = @"NORDIC-BEACON";
                detectedCategory = @"ТЕЛЕМЕТРИЯ / ДАТЧИК";
                break;
        }
    }
    
    if (!detectedName && services.count > 0) {
        for (CBUUID *uuid in services) {
            NSString *uuidStr = [uuid.UUIDString uppercaseString];
            if ([uuidStr containsString:@"180D"]) {
                detectedName = @"PULSE-METER";
                detectedCategory = @"МЕДИЦИНА / СПОРТ";
                break;
            } else if ([uuidStr containsString:@"1812"]) {
                detectedName = @"HID-DEVICE";
                detectedCategory = @"КЛАВИАТУРА / МЫШЬ";
                break;
            } else if ([uuidStr containsString:@"180F"]) {
                detectedName = @"PWR-SENSOR";
                detectedCategory = @"МОНИТОР ПИТАНИЯ";
                break;
            } else if ([uuidStr containsString:@"FE95"]) {
                detectedName = @"MI-HOME-NODE";
                detectedCategory = @"УМНЫЙ ДОМ";
                break;
            }
        }
    }
    
    if (localName.length > 0) {
        detectedName = [localName uppercaseString];
        if ([detectedCategory isEqualToString:@"НЕИЗВЕСТНО"]) {
            detectedCategory = @"ИМЕНОВАННЫЙ УЗЕЛ";
        }
    }
    
    if (!detectedName) {
        NSString *uuid = peripheral.identifier.UUIDString;
        NSString *prefix = uuid.length >= 4 ? [uuid substringToIndex:4] : uuid;
        detectedName = [NSString stringWithFormat:@"BEACON-%@", prefix];
        detectedCategory = @"РАДИОМАЯК";
    }
    
    if (outCategory) {
        *outCategory = detectedCategory;
    }
    return detectedName;
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary<NSString *,id> *)advertisementData
                  RSSI:(NSNumber *)RSSI {
    
    if (!peripheral || !peripheral.identifier || !RSSI) return;
    
    NSInteger rssiValue = [RSSI integerValue];
    if (rssiValue == 127 || rssiValue < kBleMinRssiThreshold) return;
    
    NSString *uuid = peripheral.identifier.UUIDString;
    if (uuid.length == 0) return;
    
    SpectraRadarNode *node = _nodesMap[uuid];
    
    if (!node) {
        node = [[SpectraRadarNode alloc] init];
        node.identifier = uuid;
        NSUInteger hashVal = [uuid hash];
        node.angleRadians = ((hashVal % 360) * M_PI) / 180.0;
        node.rssi = rssiValue;
        _nodesMap[uuid] = node;
    } else {
        node.rssi = (NSInteger)((node.rssi * 0.7) + (rssiValue * 0.3));
    }
    
    NSString *category = nil;
    NSString *name = [self identifyDeviceWithPeripheral:peripheral advData:advertisementData category:&category];
    node.displayName = name;
    node.deviceCategory = category;
    
    double clampedRssi = MAX((double)kBleMinRssiThreshold, MIN((double)kBleMaxRssiThreshold, (double)node.rssi));
    double ratio = ((double)kBleMaxRssiThreshold - clampedRssi) / (double)(kBleMaxRssiThreshold - kBleMinRssiThreshold);
    node.normalizedDistance = 0.12 + (ratio * 0.80);
    node.lastSeen = [NSDate date];
    
    [self notifyDelegate];
}

- (void)purgeStaleNodes {
    NSDate *now = [NSDate date];
    NSMutableArray *keysToRemove = [NSMutableArray array];
    
    for (NSString *key in _nodesMap) {
        SpectraRadarNode *node = _nodesMap[key];
        if (node.lastSeen && [now timeIntervalSinceDate:node.lastSeen] > 18.0) {
            [keysToRemove addObject:key];
        }
    }
    
    if (keysToRemove.count > 0) {
        [_nodesMap removeObjectsForKeys:keysToRemove];
        [self notifyDelegate];
    }
}

- (void)notifyDelegate {
    if (self.delegate) {
        [self.delegate didUpdateRadarNodes:[_nodesMap allValues]];
    }
}

@end
