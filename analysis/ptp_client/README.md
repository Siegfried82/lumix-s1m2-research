# 严格 PTP 客户端

client.py为传输可注入的事务核心，read_camera.py为显式只读USB入口。没有导入时连接或写入。默认拒绝数据发送与未列入查询清单的控制操作；只有调用者显式构造allow_writes=True才启用写能力，本项目只读入口不提供此选项。

已修复：数据/响应事务ID检查、数据操作码检查、等待最终OK、分片头及容器拼接、保留合并容器、拒绝截断/超长、记录超时失败、失败后禁止继续。独立线程排空事件端点。不同USB模式、端点或多个匹配设备会拒绝继续，不自动切驱动。

离线验证：

```sh
python3 -m unittest discover -s analysis/ptp_client -v
```

9项测试通过，包括错事务、错操作码、截断、超长、缺最终响应、设备错误、重复数据、合并响应、事件及默认写入阻止。入口语法和帮助已验证；未连接相机，所以没有实机兼容性结论。

准备libusb1及系统libusb后，读时钟示例（PID必须以实际设备为准，0x2382仅来自提供的S1RM2记录）：

```sh
python3 analysis/ptp_client/read_camera.py --pid 0x2382 --query clock --output outputs/clock_read.bin
```

query可选clock/config/usb-speed/wb-adjust。后两项只由Tether静态代码确认，未确认本机支持。输出为原始数据与包含散列/事务记录的JSON，不覆盖已有文件。配置含个人信息，不自动发布。

不会在无明确设备测试安排时自行运行采集命令。无固件修改或解密能力。

## LUT 读取候选路径（尚未实机验证）

依据 Lab 静态代码新增 `--query lut-info` 与 `--query lut-file --lut-index 0..40`。文件读取通过专用方法构造17字节命令，一字节索引不扩展为u32；保存的是完整DATA有效载荷，包含可能的LUT私有头，不自动当成纯文件截取。

必须显式提供实际设备PID与新输出路径；不自动探测后执行。没有加入0x9922/0x9923/0x9924，原有默认禁止写入保持有效。会话建立仍会执行OpenSession与私有OpenSession，这不等于设备侧零副作用保证。当前只通过离线协议测试，未证明型号支持或实际导出成功。

验证：`python3 -m unittest discover -s analysis/ptp_client -p test_client.py`，13项通过。新增用例覆盖17字节封包、非法索引不发送、LUT写控制拒绝及错误DATA操作码。来源和证据见 `analysis/lab_lut_protocol_20261010/结论.md`。
