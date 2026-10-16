#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, SpectraLogEventType) {
    SpectraLogEventTypeNodeDiscovered = 0,
    SpectraLogEventTypeNodeTracked    = 1,
    SpectraLogEventTypeEmfAnomaly     = 2
};

@interface SpectraLogRecord : NSObject
@property (nonatomic, strong) NSDate *timestamp;
@property (nonatomic, assign) SpectraLogEventType type;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *details;
- (NSString *)formattedTimeAndType;
- (NSString *)formattedExportLine;
@end

@interface BlackboxLogManager : NSObject
@property (nonatomic, strong, readonly) NSArray<SpectraLogRecord *> *records;
+ (instancetype)shared;
- (void)logNodeDiscovered:(NSString *)name category:(NSString *)category rssi:(NSInteger)rssi bearing:(double)bearing uuid:(NSString *)uuid;
- (void)logNodeTrackingStarted:(NSString *)name uuid:(NSString *)uuid rssi:(NSInteger)rssi;
- (void)processEmfValue:(double)microTeslas azimuth:(double)azimuth;
- (void)clearLog;
- (NSString *)exportAsPlainText;
@end
