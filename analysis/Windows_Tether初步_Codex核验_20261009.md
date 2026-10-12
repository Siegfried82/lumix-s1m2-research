# Windows Tether 初步样本核验

任务0f6ffc98-ab92-44aa-bafe-e3dee1f5e289已结束，finished/model_verified均true。独立检查安装包63475696字节、DLL2573824字节，SHA256与报告一致，文件实际存在。安装包来源报告为松下公开CDN，未执行安装包/DLL。

任务仅初筛前三接口（维护USB模式、取景控制、固件推送）。“整个平台完全同构，不存在任何读取/解码入口”超过初筛覆盖范围，不采纳。

下一步扩大到全导出表和Mac函数差异，仅对未覆盖的返回数据/诊断候选定位代码。另需核对报告export/import序号相差50是否源于PE ordinal base与table index混淆。原包不变，不发送设备命令。
