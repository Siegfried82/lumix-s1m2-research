# 本次采样状态与旧样本关联纠正


已核对的原始证据：

- `drive_before.bin` 与 `drive_after.bin` 均为 80 字节且完全相同；8 条记录可按 uint32 标签、uint32 字节长度、对应载荷连续解析至文件末尾。
- 本次响应标签 `0x02000081` 的 uint16 值为 `0x0000`。
- 旧 `analysis/live_drivemode_highres.bin` 的同标签值为 `0x000a`；其余七条记录与本次响应相同。
- 本次两份 `config_*.DAT` 与旧 `analysis/S1M2_LIVE_HIGHRES.DAT` 字节完全相同，SHA-256 均为 `ca848c6889b222a2d7e0039aee945e9afe522cda0997e8053b1a3537820304e2`。
- 客户端 GetCameraModeInfo 在反汇编第 31825 行起分发响应标签，并从 +8 读取 uint16 值；Get_DriveMode 从结构体 +8 取值（第 31474 行附近）。


本次未发送设置写入、拍摄、菜单触控或升级命令。
