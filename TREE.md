# 项目文件树与说明

> 项目根：`com.panasonic.jp.lumixsync_b0834c31/`（LUMIX Sync APK 解包 + 逆向产物）
> 约定：`#` 后为说明；大目录只列有研究价值的子项，括号内为文件数/大小。

```
com.panasonic.jp.lumixsync_b0834c31/
├── README.md                              # 项目总览：目标/结论/成果分述/文件索引/遗留路径
├── PANASONIC_FIRMWARE_UPDATE_PROTOCOL.md  # 固件上传协议逆向（时序/chunk/multipart/响应解析）
│
├── app.apk (32MB)                         # 原始 APK
├── AndroidManifest.xml                    # 应用清单
├── classes.dex / classes2.dex             # dex 字节码（主/第二）
├── resources.arsc (4MB)                   # 资源表
│
├── lumix_sync.pcap (1MB)                  # 相机↔app 网络抓包（协议逆向依据）
├── capture_lumix.sh                       # 抓包脚本
├── lumix_handshake.py                     # 相机握手/命令测试脚本（自动发现+发 cam.cgi 命令）
├── camera_api.zip                         # camera_api/ 目录打包
├── *.properties (30+ 个)                  # Play Services/Firebase 依赖元数据（无研究价值）
│
├── camera_api/                            # 相机接口实测存档与解析
│   ├── lumix_key_method.md                # 会话/鉴权研究（结论：本机不签发令牌、读写免鉴权）
│   ├── lumix_allmenu.xml                  # getinfo&type=allmenu 菜单树转储
│   ├── lumix_allmenu_analysis.md          # 菜单树解析
│   ├── lumix_capability.xml               # getinfo&type=capability 能力声明
│   ├── lumix_capability_analysis.md       # 能力解析
│   ├── lumix_curmenu.xml                  # 当前菜单存档
│   ├── lumix_lens.xml                     # 镜头参数 CSV 存档
│   └── lumix_state.xml                    # 相机状态存档
│
├── fw_fetch/ (109 文件, 87MB)             # 固件下载 / 格式逆向 / 解密尝试
│   ├── README.txt                         # 固件目录、URL 模板、各机型固件清单
│   ├── FIRMWARE_FORMAT.md                 # UPD 容器格式逆向（含 48 分区表、各字段定义）
│   ├── S5___V29.bin (90MB)                # DC-S5 完整固件（加密）
│   ├── S5___V29.sig (512B)                # RSA-4096 签名（= .bin 末尾 512 字节）
│   ├── fw_sample.bin (64KB)               # S5m2 固件 ZIP 前 64KB 样本（跨机型对比用）
│   ├── firm_list.xml                      # Panasonic 固件目录原始 XML
│   ├── firm_info_s5m2.xml                 # S5m2 固件信息 XML
│   ├── apli_list.xml                      # app 目录 XML
│   ├── decrypt_attempt.py                 # 解密尝试 1（XOR/AES/SHA-384，负结果）
│   ├── decrypt_attempt2.py                # 解密尝试 2（48 字节字段=密钥+IV 假设，负结果）
│   ├── cross_model.py                     # S5 vs S5m2 对比（64 字节块、unk 字段）
│   ├── probe_results.md                   # 相机活体只读探测报告
│   └── probe_results/ (97 份响应)         # 每个被探测命令/type 一份 XML 存档
│
├── jadx_out/ (16,721 文件, 124MB)         # jadx 反编译产物
│   ├── sources/ (42MB)                    # Java 源码；核心包 p168v5/* = 相机 HTTP API
│   │   ├── p168v5/a.java                  #   相机 API 门面（所有 cam.cgi 命令）
│   │   ├── p168v5/n.java                  #   URL 构建器
│   │   ├── p168v5/m.java                  #   HTTP 门面
│   │   ├── p168v5/o.java                  #   响应 XML/CSV 解析
│   │   └── com/panasonic/jp/...           #   业务层（设置/固件更新 UI 等）
│   └── resources/ (82MB)                  # 反编译资源
│
├── res/ (9,767 文件, 58MB)                # APK 资源（图片/布局/字符串/菜单定义）
├── assets/ (301 文件, 2.3MB)              # 隐私声明 HTML、license、dexopt 基线 profile
├── lib/ (14 文件, 15MB)                   # native .so，4 个 ABI
│   └── *.{so}                             #   libdlnaCore / libg711Codec / libimage_processing_util_jni
│                                          #   / libsurface_util_jni / libpacketLossConcealer
├── com/ (9 文件)                          # 反编译第三方库：com.google.auth / com.google.api
├── org/ (128 文件)                        # 反编译第三方库：org.apache.commons 等
├── kotlin/ (7 文件)                       # Kotlin 标准库类
└── META-INF/ (12 文件)                    # version-control-info、native-image、services 注册
```

## 阅读路径建议

1. 想了解「结论」：读 `README.md`。
2. 想了解「相机协议」：`PANASONIC_FIRMWARE_UPDATE_PROTOCOL.md` → `camera_api/lumix_key_method.md` → `jadx_out/sources/p168v5/`。
3. 想了解「固件格式」：`fw_fetch/FIRMWARE_FORMAT.md` → `fw_fetch/S5___V29.bin`。
4. 想了解「解密/读密钥尝试」：`fw_fetch/decrypt_attempt*.py` → `fw_fetch/probe_results.md`。
