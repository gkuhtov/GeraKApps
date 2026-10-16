#import "BlackboxLogManager.h"

@implementation SpectraLogRecord

- (NSString *)formattedTimeAndType {
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"HH:mm:ss.SS";
    NSString *timeStr = [df stringFromDate:self.timestamp];
    
    NSString *tag = @"[INFO]";
    switch (self.type) {
        case SpectraLogEventTypeNodeDiscovered: tag = @"[NODE]"; break;
        case SpectraLogEventTypeNodeTracked:    tag = @"[LOCK]"; break;
        case SpectraLogEventTypeEmfAnomaly:     tag = @"[WARN]"; break;
    }
    return [NSString stringWithFormat:@"%@ %@ %@", timeStr, tag, self.title];
}

- (NSString *)formattedExportLine {
    return [NSString stringWithFormat:@"%@ | %@", [self formattedTimeAndType], self.details];
}

@end

@implementation BlackboxLogManager {
    NSMutableArray<SpectraLogRecord *> *_logStore;
    NSMutableSet<NSString *> *_loggedUUIDs;
    double _runningEmfAverage;
    NSDate *_lastEmfAnomalyTime;
}

+ (instancetype)shared {
    static BlackboxLogManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _logStore = [NSMutableArray array];
        _loggedUUIDs = [NSMutableSet set];
        _runningEmfAverage = 0.0;
    }
    return self;
}

- (NSArray<SpectraLogRecord *> *)records {
    return [_logStore copy];
}

- (void)logNodeDiscovered:(NSString *)name category:(NSString *)category rssi:(NSInteger)rssi bearing:(double)bearing uuid:(NSString *)uuid {
    if (!uuid || [_loggedUUIDs containsObject:uuid]) return;
    [_loggedUUIDs addObject:uuid];
    
    SpectraLogRecord *rec = [[SpectraLogRecord alloc] init];
    rec.timestamp = [NSDate date];
    rec.type = SpectraLogEventTypeNodeDiscovered;
    rec.title = [name uppercaseString];
    rec.details = [NSString stringWithFormat:@"TYPE: %@ | RSSI: %ld dBm | BRG: %03.0f° | ID: %@", category ?: @"RAW", (long)rssi, bearing, uuid];
    
    [_logStore insertObject:rec atIndex:0];
}

- (void)logNodeTrackingStarted:(NSString *)name uuid:(NSString *)uuid rssi:(NSInteger)rssi {
    SpectraLogRecord *rec = [[SpectraLogRecord alloc] init];
    rec.timestamp = [NSDate date];
    rec.type = SpectraLogEventTypeNodeTracked;
    rec.title = [NSString stringWithFormat:@"TARGET LOCK: %@", [name uppercaseString]];
    rec.details = [NSString stringWithFormat:@"LOCKED AT: %ld dBm | ID: %@", (long)rssi, uuid];
    
    [_logStore insertObject:rec atIndex:0];
}

- (void)processEmfValue:(double)microTeslas azimuth:(double)azimuth {
    if (_runningEmfAverage <= 0.1) {
        _runningEmfAverage = microTeslas;
        return;
    }
    
    double delta = microTeslas - _runningEmfAverage;
    _runningEmfAverage = (_runningEmfAverage * 0.98) + (microTeslas * 0.02);
    
    if (delta > 40.0) {
        NSDate *now = [NSDate date];
        if (_lastEmfAnomalyTime && [now timeIntervalSinceDate:_lastEmfAnomalyTime] < 6.0) {
            return;
        }
        _lastEmfAnomalyTime = now;
        
        SpectraLogRecord *rec = [[SpectraLogRecord alloc] init];
        rec.timestamp = now;
        rec.type = SpectraLogEventTypeEmfAnomaly;
        rec.title = [NSString stringWithFormat:@"EMF SPIKE (+%.0f µT)", delta];
        rec.details = [NSString stringWithFormat:@"FLUX: %.1f µT | AZ: %03.0f°", microTeslas, azimuth];
        
        [_logStore insertObject:rec atIndex:0];
    }
}

- (void)clearLog {
    [_logStore removeAllObjects];
    [_loggedUUIDs removeAllObjects];
}

- (NSString *)exportAsPlainText {
    NSMutableString *outStr = [NSMutableString string];
    [outStr appendString:@"=== SPECTRA BLACKBOX TACTICAL LOG ===\n"];
    [outStr appendFormat:@"GENERATED: %@\n", [NSDate date]];
    [outStr appendFormat:@"TOTAL RECORDS: %lu\n", (unsigned long)_logStore.count];
    [outStr appendString:@"=====================================\n\n"];
    
    for (SpectraLogRecord *rec in [_logStore reverseObjectEnumerator]) {
        [outStr appendFormat:@"%@\n", [rec formattedExportLine]];
    }
    return [outStr copy];
}

@end
