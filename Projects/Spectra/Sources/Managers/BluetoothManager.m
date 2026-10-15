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
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
    }
    return self;
}

- (void)startScanning {
    if (_centralManager.state == CBManagerStatePoweredOn) {
        [_centralManager scanForPeripheralsWithServices:nil
                                                options:@{CBCentralManagerScanOptionAllowDuplicatesKey: @YES}];
    }
    if (!_cleanupTimer) {
        _cleanupTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                         target:self
                                                       selector:@selector(purgeStaleNodes)
                                                       userInfo:nil
                                                        repeats:YES];
    }
}

- (void)stopScanning {
    [_centralManager stopScan];
    [_cleanupTimer invalidate];
    _cleanupTimer = nil;
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state == CBManagerStatePoweredOn) {
        [self startScanning];
    }
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary<NSString *,id> *)advertisementData
                  RSSI:(NSNumber *)RSSI {
    
    NSInteger rssiValue = [RSSI integerValue];
    // Отсекаем ошибочный статус 127 и слишком слабый сигнал
    if (rssiValue == 127 || rssiValue < kBleMinRssiThreshold) return;
    
    NSString *uuid = peripheral.identifier.UUIDString;
    SpectraRadarNode *node = _nodesMap[uuid];
    
    if (!node) {
        node = [[SpectraRadarNode alloc] init];
        node.identifier = uuid;
        
        // Стабильный угол на основе хэша UUID, чтобы устройство держало свой сектор на радаре
        NSUInteger hashVal = [uuid hash];
        node.angleRadians = ((hashVal % 360) * M_PI) / 180.0;
        node.rssi = rssiValue;
        _nodesMap[uuid] = node;
    } else {
        // Плавное сглаживание скачков сигнала RSSI
        node.rssi = (NSInteger)((node.rssi * 0.7) + (rssiValue * 0.3));
    }
    
    NSString *localName = advertisementData[CBAdvertisementDataLocalNameKey] ?: peripheral.name;
    if (localName.length > 0) {
        node.displayName = localName;
    } else if (!node.displayName) {
        node.displayName = [NSString stringWithFormat:@"BLE-%@", [uuid substringToIndex:4]];
    }
    
    // Нормализация дистанции от 0.12 (вплотную) до 0.92 (на краю сетки)
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
        if ([now timeIntervalSinceDate:node.lastSeen] > kBleNodeStaleTimeout) {
            [keysToRemove addObject:key];
        }
    }
    
    if (keysToRemove.count > 0) {
        [_nodesMap removeObjectsForKeys:keysToRemove];
        [self notifyDelegate];
    }
}

- (void)notifyDelegate {
    [self.delegate didUpdateRadarNodes:[_nodesMap allValues]];
}

@end
