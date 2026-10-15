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
    }
    return self;
}

- (void)startScanning {
    if (!_centralManager) {
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
    } else if (_centralManager.state == CBManagerStatePoweredOn) {
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
    if (_centralManager.state == CBManagerStatePoweredOn) {
        [_centralManager stopScan];
    }
    [_cleanupTimer invalidate];
    _cleanupTimer = nil;
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state == CBManagerStatePoweredOn) {
        [_centralManager scanForPeripheralsWithServices:nil
                                                options:@{CBCentralManagerScanOptionAllowDuplicatesKey: @YES}];
    }
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
    
    NSString *localName = advertisementData[CBAdvertisementDataLocalNameKey] ?: peripheral.name;
    if (localName.length > 0) {
        node.displayName = localName;
    } else if (!node.displayName) {
        NSString *prefix = uuid.length >= 4 ? [uuid substringToIndex:4] : uuid;
        node.displayName = [NSString stringWithFormat:@"BLE-%@", prefix];
    }
    
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
        if (node.lastSeen && [now timeIntervalSinceDate:node.lastSeen] > kBleNodeStaleTimeout) {
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
