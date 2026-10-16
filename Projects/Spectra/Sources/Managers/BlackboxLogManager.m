#import "BlackboxLogManager.h"

@implementation SpectraLogRecord

- (NSString *)formattedLogLine {
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"HH:mm:ss.SS";
    NSString *timeStr = [df stringFromDate:self.timestamp];
    
    NSString *tag = @"[INFO]";
    switch (self.type) {
        case SpectraLogEventTypeNodeDiscovered: tag = @"[NODE]"; break;
        case SpectraLogEventTypeNodeTracked:    tag = @"[LOCK]"; break;
        case SpectraLogEventTypeEmfAnomaly:     tag = @"[WARN]"; break;
    }
    return [NSString stringWithFormat:@"%@ %@ %@ :: %@", timeStr, tag, self.title, self.details];
}

@end

@implementation BlackboxLogManager {
    NSMutableArray<SpectraLogRecord *> *_logStore;
    NSMutableSet<NSString *> *_loggedUUIDs;
    NSDate *_lastEmfLogTime;
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
    rec.title = [NSString stringWithFormat:@"NEW NODE: %@", [name uppercaseString]];
    rec.details = [NSString stringWithFormat:@"TYPE: %@ | RSSI: %ld dBm | BRG: %03.0f° | ID: %@", category ?: @"RAW", (long)rssi, bearing, uuid];
    
    [_logStore insertObject:rec atIndex:0];
}

- (void)logNodeTrackingStarted:(NSString *)name uuid:(NSString *)uuid rssi:(NSInteger)rssi {
    SpectraLogRecord *rec = [[SpectraLogRecord alloc] init];
    rec.timestamp = [NSDate date];
    rec.type = SpectraLogEventTypeNodeTracked;
    rec.title = [NSString stringWithFormat:@"TRACKING: %@", [name uppercaseString]];
    rec.details = [NSString stringWithFormat:@"LOCKED AT: %ld dBm | TARGET: %@", (long)rssi, uuid];
    
    [_logStore insertObject:rec atIndex:0];
}

- (void)logEmfAnomaly:(double)microTeslas azimuth:(double)azimuth {
    NSDate *now = [NSDate date];
    if (_lastEmfLogTime && [now timeIntervalSinceDate:_lastEmfLogTime] < 4.0) {
        return; // Антиспам повторных логов всплеска поля
    }
    _lastEmfLogTime = now;
    
    SpectraLogRecord *rec = [[SpectraLogRecord alloc] init];
    rec.timestamp = now;
    rec.type = SpectraLogEventTypeEmfAnomaly;
    rec.title = @"EMF FLUX SPIKE";
    rec.details = [NSString stringWithFormat:@"MAGNITUDE: %.1f µT | AZ: %03.0f°", microTeslas, azimuth];
    
    [_logStore insertObject:rec atIndex:0];
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
        [outStr appendFormat:@"%@\n", [rec formattedLogLine]];
    }
    return [outStr copy];
}

@end
