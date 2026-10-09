#import <Foundation/Foundation.h>
#import <ImageCaptureCore/ImageCaptureCore.h>

// Allowlisted read operations only. No setting changes or shutter release.
@interface BaselineCapture : NSObject <ICDeviceBrowserDelegate, ICCameraDeviceDelegate>
@property(nonatomic,strong) ICDeviceBrowser *browser;
@property(nonatomic,strong) ICCameraDevice *camera;
@property(nonatomic,strong) NSString *directory;
@property(nonatomic,strong) NSMutableArray *events;
@property(nonatomic,assign) BOOL finished;
@property(nonatomic,assign) BOOL failed;
@property(nonatomic,assign) BOOL closing;
@property(nonatomic,assign) uint32_t transaction;
@property(nonatomic,assign) BOOL includeDeviceInfo;
@property(nonatomic,strong) NSArray *readPlan;
@end

@implementation BaselineCapture
- (void)record:(NSDictionary *)event {
    NSMutableDictionary *row = [event mutableCopy];
    row[@"time_utc"] = [[NSISO8601DateFormatter new] stringFromDate:[NSDate date]];
    [self.events addObject:row];
    NSData *json = [NSJSONSerialization dataWithJSONObject:self.events options:NSJSONWritingPrettyPrinted error:nil];
    [json writeToFile:[self.directory stringByAppendingPathComponent:@"capture_log.json"] atomically:YES];
}
- (void)close {
    if (self.closing) return;
    self.closing = YES;
    [self.camera requestCloseSession];
}
- (void)deviceBrowser:(ICDeviceBrowser *)browser didAddDevice:(ICDevice *)device moreComing:(BOOL)moreComing {
    if (!self.camera && [device isKindOfClass:[ICCameraDevice class]] && [device.name containsString:@"S1M2"]) {
        self.camera = (ICCameraDevice *)device;
        self.camera.delegate = self;
        [self record:@{@"event":@"device_found", @"model":device.name}];
        [self.camera requestOpenSession];
    }
}
- (void)deviceBrowser:(ICDeviceBrowser *)browser didRemoveDevice:(ICDevice *)device moreGoing:(BOOL)moreGoing {}
- (void)cameraDevice:(ICCameraDevice *)camera didAddItems:(NSArray *)items {}
- (void)cameraDevice:(ICCameraDevice *)camera didRemoveItems:(NSArray *)items {}
- (void)cameraDevice:(ICCameraDevice *)camera didRenameItems:(NSArray *)items {}
- (void)cameraDevice:(ICCameraDevice *)camera didReceiveThumbnail:(CGImageRef)thumbnail forItem:(ICCameraItem *)item error:(NSError *)error {}
- (void)cameraDevice:(ICCameraDevice *)camera didReceiveMetadata:(NSDictionary *)metadata forItem:(ICCameraItem *)item error:(NSError *)error {}
- (void)cameraDevice:(ICCameraDevice *)camera didReceivePTPEvent:(NSData *)eventData {}
- (void)cameraDeviceDidChangeCapability:(ICCameraDevice *)camera {}
- (void)deviceDidBecomeReadyWithCompleteContentCatalog:(ICCameraDevice *)device {}
- (void)cameraDeviceDidRemoveAccessRestriction:(ICDevice *)device {}
- (void)cameraDeviceDidEnableAccessRestriction:(ICDevice *)device {}
- (void)didRemoveDevice:(ICDevice *)device {
    if (self.closing || self.finished) return;
    self.failed = YES; self.finished = YES;
    [self record:@{@"event":@"device_removed"}];
}
- (void)device:(ICDevice *)device didOpenSessionWithError:(NSError *)error {
    if (error) {
        self.failed = YES; self.finished = YES;
        [self record:@{@"event":@"open_failed", @"error":error.localizedDescription}];
        return;
    }
    [self record:@{@"event":@"session_opened"}];
    if (self.readPlan) [self readPlanIndex:0];
    else if (self.includeDeviceInfo) [self readDeviceInfo];
    else [self readIndex:0];
}
- (void)readPlanIndex:(NSUInteger)index {
    if (self.closing || self.finished) return;
    if (index >= self.readPlan.count) { [self close]; return; }
    NSDictionary *item=self.readPlan[index];
    uint16_t op=[item[@"opcode"] unsignedIntValue];
    NSArray *params=item[@"params"];
    NSSet *allowed=[NSSet setWithArray:@[@0x1004,@0x1005,@0x1014,@0x1015,@0x9108,@0x9402,@0x9408,@0x9414,@0x9114,@0x9115]];
    NSString *name=item[@"name"];
    if (![allowed containsObject:@(op)] || params.count>5 || ![name isKindOfClass:[NSString class]] || [name rangeOfString:@"/"].location!=NSNotFound) {
        self.failed=YES; [self record:@{@"event":@"rejected_plan_item", @"index":@(index)}]; [self close]; return;
    }
    uint32_t packet[8]={0};
    packet[0]=12+4*(uint32_t)params.count;
    uint16_t header[2]={1,op}; memcpy(&packet[1],header,4);
    packet[2]=++self.transaction;
    for (NSUInteger i=0;i<params.count;i++) packet[3+i]=[params[i] unsignedIntValue];
    [self.camera requestSendPTPCommand:[NSData dataWithBytes:packet length:packet[0]] outData:nil completion:^(NSData *data,NSData *response,NSError *error) {
        uint16_t code=0,type=0; uint32_t length=0;
        if (response.length>=12) { memcpy(&length,response.bytes,4); memcpy(&type,(const uint8_t *)response.bytes+4,2); memcpy(&code,(const uint8_t *)response.bytes+6,2); }
        BOOL transportOK=!error && response.length>=12 && length==response.length && type==3;
        [self record:@{@"event":@"plan_read_response",@"index":@(index),@"name":name,@"opcode":[NSString stringWithFormat:@"0x%04x",op],@"params":params,@"response_code":[NSString stringWithFormat:@"0x%04x",code],@"data_bytes":@(data.length),@"transport_ok":@(transportOK),@"ok":@(transportOK && code==0x2001),@"error":error ? error.localizedDescription : @""}];
        if (response) [response writeToFile:[self.directory stringByAppendingPathComponent:[name stringByAppendingString:@".ptp_response.bin"]] atomically:YES];
        if (data) [data writeToFile:[self.directory stringByAppendingPathComponent:[name stringByAppendingString:@".bin"]] atomically:YES];
        if (!transportOK) { self.failed=YES; [self close]; return; }
        [self readPlanIndex:index+1];
    }];
}
- (void)readDeviceInfo {
    uint32_t packet[3] = {12,0,++self.transaction};
    uint16_t header[2] = {1,0x1001};
    memcpy(&packet[1],header,4);
    [self.camera requestSendPTPCommand:[NSData dataWithBytes:packet length:12] outData:nil completion:^(NSData *data, NSData *response, NSError *error) {
        uint16_t code=0,type=0;
        uint32_t length=0;
        if (response.length >= 12) {
            memcpy(&length,response.bytes,4);
            memcpy(&type,(const uint8_t *)response.bytes+4,2);
            memcpy(&code,(const uint8_t *)response.bytes+6,2);
        }
        BOOL ok=!error && length==response.length && response.length>=12 && type==3 && code==0x2001 && data.length>0;
        [self record:@{@"event":@"device_info_response", @"opcode":@"0x1001", @"response_code":[NSString stringWithFormat:@"0x%04x",code], @"data_bytes":@(data.length), @"ok":@(ok), @"error":error ? error.localizedDescription : @""}];
        if (!ok) { self.failed=YES; [self close]; return; }
        NSError *writeError=nil;
        if (![data writeToFile:[self.directory stringByAppendingPathComponent:@"device_info.bin"] options:NSDataWritingAtomic error:&writeError]) {
            self.failed=YES; [self close]; return;
        }
        [self readIndex:0];
    }];
}
- (void)device:(ICDevice *)device didCloseSessionWithError:(NSError *)error {
    [self record:@{@"event":@"session_closed", @"error":error ? error.localizedDescription : @""}];
    self.finished = YES;
}
- (void)readIndex:(NSUInteger)index {
    if (self.closing || self.finished) return;
    // Before/after mode reads surround two identical configuration reads.
    const uint16_t ops[] = {0x9402,0x9421,0x9421,0x9402};
    const uint32_t tags[] = {0x02000080,0x080000a2,0x080000a2,0x02000080};
    NSArray *names = @[@"drive_before.bin", @"config_1.response.bin", @"config_2.response.bin", @"drive_after.bin"];
    if (index >= 4) { [self close]; return; }
    uint16_t op = ops[index];
    uint32_t tag = tags[index];
    uint32_t packet[4] = {16,0,++self.transaction,tags[index]};
    uint16_t header[2] = {1,ops[index]};
    memcpy(&packet[1],header,4);
    NSData *command = [NSData dataWithBytes:packet length:sizeof(packet)];
    [self.camera requestSendPTPCommand:command outData:nil completion:^(NSData *data, NSData *response, NSError *error) {
        uint16_t code=0, type=0;
        uint32_t length=0;
        if (response.length >= 12) {
            memcpy(&length,response.bytes,4);
            memcpy(&type,(const uint8_t *)response.bytes+4,2);
            memcpy(&code,(const uint8_t *)response.bytes+6,2);
        }
        BOOL ok = !error && response.length >= 12 && length == response.length && type == 3 && code == 0x2001 && data.length > 0;
        [self record:@{@"event":@"read_response", @"index":@(index), @"opcode":[NSString stringWithFormat:@"0x%04x",op], @"tag":[NSString stringWithFormat:@"0x%08x",tag], @"response_code":[NSString stringWithFormat:@"0x%04x",code], @"data_bytes":@(data.length), @"response_bytes":@(response.length), @"ok":@(ok), @"error":error ? error.localizedDescription : @""}];
        if (!ok) { self.failed = YES; [self close]; return; }
        NSError *writeError=nil;
        if (![data writeToFile:[self.directory stringByAppendingPathComponent:names[index]] options:NSDataWritingAtomic error:&writeError]) {
            self.failed=YES;
            [self record:@{@"event":@"save_failed", @"error":writeError.localizedDescription}];
            [self close]; return;
        }
        [self readIndex:index+1];
    }];
}
@end

int main(int argc,const char **argv) {
    @autoreleasepool {
        if (argc != 2 && argc != 3 && argc != 4) return 2;
        BaselineCapture *probe = [BaselineCapture new];
        probe.directory = [NSString stringWithUTF8String:argv[1]];
        probe.includeDeviceInfo = argc == 3 && strcmp(argv[2],"--device-info")==0;
        if (argc==4) {
            if (strcmp(argv[2],"--read-plan")!=0) return 2;
            NSData *planData=[NSData dataWithContentsOfFile:[NSString stringWithUTF8String:argv[3]]];
            id plan=[NSJSONSerialization JSONObjectWithData:planData options:0 error:nil];
            if (![plan isKindOfClass:[NSArray class]] || [plan count]>100) return 2;
            probe.readPlan=plan;
        }
        probe.events = [NSMutableArray new];
        NSError *error=nil;
        if (![[NSFileManager defaultManager] createDirectoryAtPath:probe.directory withIntermediateDirectories:YES attributes:nil error:&error]) return 2;
        probe.browser = [ICDeviceBrowser new];
        probe.browser.delegate=probe;
        probe.browser.browsedDeviceTypeMask=ICDeviceTypeMaskCamera|ICDeviceLocationTypeMaskLocal;
        [probe record:@{@"event":@"started", @"purpose":probe.readPlan ? @"allowlisted_read_inventory" : @"unchanged_settings_baseline", @"read_count":@(probe.readPlan ? probe.readPlan.count : (probe.includeDeviceInfo ? 5 : 4))}];
        [probe.browser start];
        NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:probe.readPlan ? 240 : 90];
        while (!probe.finished && deadline.timeIntervalSinceNow > 0) [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        if (!probe.finished) {
            probe.failed=YES;
            [probe record:@{@"event":@"timeout"}];
            if (probe.camera) [probe close];
            NSDate *closeDeadline=[NSDate dateWithTimeIntervalSinceNow:5];
            while (!probe.finished && closeDeadline.timeIntervalSinceNow > 0) [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        }
        [probe.browser stop];
        printf("Baseline capture %s; log saved.\n",probe.failed ? "failed" : "completed");
        return probe.failed ? 1 : 0;
    }
}
