// S5 / LUMIX S 只读 PTP 客户端（macOS 原生 ImageCaptureCore 路径）
// =============================================================
// 基于已验证可用的 S1M2 baseline 客户端改写（该路径已实测 dump 出 9.2 MiB 的 0x9421）。
//
// 只读，安全。只发送：
//   0x1001 GetDeviceInfo
//   (requestOpenSession)
//   0x1004 GetStorageIDs
//   0x9104  GetSyncList
//   0x9421  LmxExt_Get_SetupFilesConfigSet_Info  (全量配置 dump, tag=0x080000a2)
//   0x9605  LmxExt_Get_Event_Info               (FW 升级状态机只读查询, mode=fwup)
//   (requestCloseSession)
//
// 绝不发送 0x9406(任意子码)/0x9422/0x9423/0x940d/格式化/升级/关机/快门。
//   说明：0x9406 的 8 个已知子码（0x11~0x18）经 Tether 反汇编全部为"动作/状态切换"，
//         没有只读查询子码，因此本工具绝不发 0x9406。FW 升级状态机的只读查询
//         走 0x9605 Get_Event_Info（纯 Get，不改状态）。
//
// 编译（macOS）：
//   clang -framework Foundation -framework ImageCaptureCore -o s5_ptp_dump s5_ptp_dump.m
// 运行（相机 Tether 模式 + USB 连上后）：
//   ./s5_ptp_dump <输出目录> [型号子串] [mode]
//     mode=dump  (默认)  0x9421 全量配置 dump
//     mode=fwup          0x9605 FW 升级状态机只读查询
//   例：
//     ./s5_ptp_dump ./ptp_out S5 dump
//     ./s5_ptp_dump ./ptp_out S5 fwup
//
// 为什么走 ImageCaptureCore 而不是 libusb：
//   macOS 上 PTP 设备常被系统相机栈占用，libusb 抢接口易失败。ImageCaptureCore
//   是 Apple 原生框架，自动处理驱动占用，且 S1M2 项目已用同一路径成功 dump 0x9421。

#import <Foundation/Foundation.h>
#import <ImageCaptureCore/ImageCaptureCore.h>

@interface Capture : NSObject <ICDeviceBrowserDelegate, ICCameraDeviceDelegate>
@property (nonatomic, strong) ICDeviceBrowser *browser;
@property (nonatomic, strong) ICCameraDevice *camera;
@property (nonatomic, strong) NSString *outDir;
@property (nonatomic, copy, nullable) NSString *modelFilter;   // nil = 任意相机
@property (nonatomic, copy) NSString *mode;                    // "dump" | "fwup"
@property (nonatomic, assign) uint32_t tid;
@property (nonatomic, assign) BOOL done;
@property (nonatomic, assign) BOOL failed;
@property (nonatomic, assign) BOOL closing;
@property (nonatomic, strong) NSMutableArray<NSMutableDictionary *> *log;
@end

@implementation Capture

- (void)logEvent:(NSDictionary *)ev {
    NSMutableDictionary *row = [ev mutableCopy];
    row[@"time_utc"] = [[NSISO8601DateFormatter new] stringFromDate:[NSDate date]];
    [self.log addObject:row];
    NSData *json = [NSJSONSerialization dataWithJSONObject:self.log options:NSJSONWritingPrettyPrinted error:nil];
    [json writeToFile:[self.outDir stringByAppendingPathComponent:@"capture_log.json"] atomically:YES];
}

- (uint32_t)u32at:(NSData *)d idx:(NSUInteger)i {
    const uint8_t *b = d.bytes;
    return b[i] | (b[i+1]<<8) | (b[i+2]<<16) | ((uint32_t)b[i+3]<<24);
}
- (uint16_t)u16at:(NSData *)d idx:(NSUInteger)i {
    const uint8_t *b = d.bytes;
    return (uint16_t)(b[i] | (b[i+1]<<8));
}

- (void)close {
    if (self.closing) return;
    self.closing = YES;
    [self.camera requestCloseSession];
}

// 构造并发送一个精确长度的 PTP 命令容器
- (void)sendCmd:(uint16_t)op params:(NSArray<NSNumber *> *)params name:(NSString *)name next:(void (^)(BOOL))next {
    NSUInteger np = params.count;
    uint32_t len = 12 + (uint32_t)(4 * np);
    NSMutableData *packet = [NSMutableData dataWithLength:len];
    uint8_t *p = packet.mutableBytes;
    p[0] = len & 0xff; p[1] = (len>>8) & 0xff; p[2] = (len>>16) & 0xff; p[3] = (len>>24) & 0xff;
    p[4] = 1; p[5] = 0;                       // type = 0x0001 (command)
    p[6] = op & 0xff; p[7] = (op>>8) & 0xff;  // opcode
    uint32_t t = ++self.tid;
    p[8] = t & 0xff; p[9] = (t>>8) & 0xff; p[10] = (t>>16) & 0xff; p[11] = (t>>24) & 0xff;
    for (NSUInteger i = 0; i < np; i++) {
        uint32_t v = [params[i] unsignedIntValue];
        p[12+i*4] = v & 0xff; p[13+i*4] = (v>>8) & 0xff;
        p[14+i*4] = (v>>16) & 0xff; p[15+i*4] = (v>>24) & 0xff;
    }

    [self.camera requestSendPTPCommand:packet outData:nil completion:^(NSData *data, NSData *response, NSError *error) {
        uint32_t rlen = 0; uint16_t rtype = 0, rcode = 0;
        if (response.length >= 12) {
            rlen  = [self u32at:response idx:0];
            rtype = [self u16at:response idx:4];
            rcode = [self u16at:response idx:6];
        }
        BOOL transportOK = !error && response.length >= 12 && rlen == response.length && rtype == 3;
        BOOL ok = transportOK && rcode == 0x2001;
        [self logEvent:@{
            @"event": @"read_response",
            @"name": name,
            @"opcode": [NSString stringWithFormat:@"0x%04x", op],
            @"response_code": [NSString stringWithFormat:@"0x%04x", rcode],
            @"data_bytes": @(data.length),
            @"response_bytes": @(response.length),
            @"transport_ok": @(transportOK),
            @"ok": @(ok),
            @"error": error ? error.localizedDescription : @"",
        }];
        if (data.length > 0) {
            [data writeToFile:[self.outDir stringByAppendingPathComponent:[name stringByAppendingString:@".bin"]] atomically:YES];
        }
        if (response.length > 0) {
            [response writeToFile:[self.outDir stringByAppendingPathComponent:[name stringByAppendingString:@".resp.bin"]] atomically:YES];
        }
        if (next) next(ok);
    }];
}

// 只读序列：GetDeviceInfo -> GetStorageIDs -> 0x9104 -> 0x9421 -> close
- (void)runReadOnlySequence {
    [self sendCmd:0x1001 params:@[] name:@"device_info" next:^(BOOL ok){
        if (!ok) { self.failed = YES; [self close]; return; }
        [self sendCmd:0x1004 params:@[] name:@"storage_ids" next:^(BOOL ok){
            // GetStorageIDs 失败不致命，继续
            [self sendCmd:0x9104 params:@[] name:@"sync_list" next:^(BOOL ok){
                if (!ok) { /* 0x9104 可选，失败继续 */ }
                // 核心：0x9421 全量配置 dump
                [self sendCmd:0x9421 params:@[@0x080000a2] name:@"config_0x9421" next:^(BOOL ok){
                    if (ok) {
                        printf("[OK] 0x9421 dump 完成，输出目录：%s\n",
                               [self.outDir UTF8String]);
                    } else {
                        // 备用：试 name tag
                        [self sendCmd:0x9421 params:@[@0x080000a1] name:@"config_0x9421_altname" next:^(BOOL ok2){
                            if (!ok2) { self.failed = YES; }
                            [self close];
                        }];
                        return;
                    }
                    [self close];
                }];
            }];
        }];
    }];
}

// FW 升级状态机只读查询：0x9605 Get_Event_Info
// 每个事件类型一次纯 Get 查询，绝不触发任何动作。
// 字段语义已对照 Tether 2.12 反汇编（Lmx_func_api_fwup_Get_Event_Info）核实：
//   0x41000013 -> Ready:      提取 Address(u64)，日志 "RedyInfo:Address : 0x%016llx"
//   0x41000014 -> 完成态(=0x13+1): 读完成 Status
//   0x41000015 -> CmpInfo(=0x13+2): 提取 Status(u32)，日志 "CmpInfo :Status : 0x%08x"
// 其余（0x41000012/16/17）为相邻事件类型探测（映射事件空间）。
// 相机空闲时多数返回 InvalidParam/GeneralError，属正常。
// 地址由机身返回（Tether 存于 0x260498/0x2604ac 后原样填入 0x9606），主机不可自填 → 无任意地址写。
- (void)runFWUPSequence {
    NSArray<NSNumber *> *evts = @[@0x41000012, @0x41000013, @0x41000014,
                                  @0x41000015, @0x41000016, @0x41000017];
    printf("[*] 开始 0x9605 FW 升级状态机只读查询（%lu 个事件类型）...\n",
           (unsigned long)evts.count);
    fflush(stdout);
    [self fwupQueryEvts:evts index:0];
}

// 用递归对象方法驱动查询链，避免自引用 block（在 XPC 回复线程回调时更稳）。
- (void)fwupQueryEvts:(NSArray<NSNumber *> *)evts index:(NSUInteger)idx {
    if (idx >= evts.count) { [self close]; return; }
    NSNumber *ev = evts[idx];
    NSString *name = [NSString stringWithFormat:@"fwup_ev_0x%08x", ev.unsignedIntValue];
    [self sendCmd:0x9605 params:@[ev] name:name next:^(BOOL ok){
        printf("    [%s] 0x9605 evt=0x%08x\n", ok ? "OK" : "ERR", ev.unsignedIntValue);
        fflush(stdout);
        [self fwupQueryEvts:evts index:idx + 1];
    }];
}

#pragma mark - ICDeviceBrowserDelegate

- (void)deviceBrowser:(ICDeviceBrowser *)browser didAddDevice:(ICDevice *)device moreComing:(BOOL)moreComing {
    if (self.camera || !device) return;
    if (![device isKindOfClass:[ICCameraDevice class]]) return;
    NSString *nm = device.name ?: @"";
    if (self.modelFilter && ![nm containsString:self.modelFilter]) return;
    self.camera = (ICCameraDevice *)device;
    self.camera.delegate = self;
    [self logEvent:@{@"event": @"device_found", @"model": nm}];
    printf("[*] 发现相机：%s，打开会话...\n", [nm UTF8String]);
    [self.camera requestOpenSession];
}

- (void)deviceBrowser:(ICDeviceBrowser *)browser didRemoveDevice:(ICDevice *)device moreGoing:(BOOL)moreGoing {}

#pragma mark - ICCameraDeviceDelegate

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
    if (self.closing || self.done) return;
    self.failed = YES; self.done = YES;
    [self logEvent:@{@"event": @"device_removed"}];
}

- (void)device:(ICDevice *)device didOpenSessionWithError:(NSError *)error {
    if (error) {
        self.failed = YES; self.done = YES;
        [self logEvent:@{@"event": @"open_failed", @"error": error.localizedDescription}];
        printf("[!] 打开会话失败：%s\n", [error.localizedDescription UTF8String]);
        return;
    }
    [self logEvent:@{@"event": @"session_opened"}];
    printf("[*] 会话已建立，开始只读取序列...\n");
    if ([self.mode isEqualToString:@"fwup"]) {
        [self runFWUPSequence];
    } else {
        [self runReadOnlySequence];
    }
}

- (void)device:(ICDevice *)device didCloseSessionWithError:(NSError *)error {
    [self logEvent:@{@"event": @"session_closed",
                     @"error": error ? error.localizedDescription : @""}];
    self.done = YES;
}

@end

int main(int argc, const char **argv) {
    @autoreleasepool {
        if (argc < 2) {
            fprintf(stderr, "用法：\n  ./s5_ptp_dump <输出目录> [型号子串] [mode]\n"
                            "  mode: dump(默认) | fwup\n");
            return 2;
        }
        Capture *c = [Capture new];
        c.outDir = [NSString stringWithUTF8String: argv[1]];
        if (argc >= 3) c.modelFilter = [NSString stringWithUTF8String: argv[2]];
        c.mode = (argc >= 4) ? [NSString stringWithUTF8String: argv[3]] : @"dump";
        c.log = [NSMutableArray array];
        c.browser = [ICDeviceBrowser new];
        c.browser.delegate = c;
        c.browser.browsedDeviceTypeMask = ICDeviceTypeMaskCamera | ICDeviceLocationTypeMaskLocal;
        [c logEvent:@{@"event": @"started", @"purpose": @"readonly_0x9421_dump",
                      @"model_filter": c.modelFilter ?: @"(any)",
                      @"mode": c.mode}];

        NSError *err = nil;
        if (![[NSFileManager defaultManager] createDirectoryAtPath:c.outDir
                          withIntermediateDirectories:YES attributes:nil error:&err]) {
            fprintf(stderr, "无法创建输出目录：%s\n", err.localizedDescription.UTF8String);
            return 2;
        }

        [c.browser start];
        NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:180];
        while (!c.done && deadline.timeIntervalSinceNow > 0) {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        }
        if (!c.done) {
            c.failed = YES;
            [c logEvent:@{@"event": @"timeout"}];
            [c close];
            NSDate *cd = [NSDate dateWithTimeIntervalSinceNow:5];
            while (!c.done && cd.timeIntervalSinceNow > 0) {
                [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
            }
        }
        [c.browser stop];
        printf("只读 dump %s；日志已保存到 %s/capture_log.json\n",
               c.failed ? "失败" : "完成", [c.outDir UTF8String]);
        return c.failed ? 1 : 0;
    }
}
