# Codex 静态旁注：s5_ble_pair.ps1

本次未执行PowerShell或设备操作。默认Action=list查询系统设备；pair/watch会调用PairAsync，unpair调用UnpairAsync（原行102–108、120–147），确实可能改变主机/机身绑定状态，不能归类为全部只读。

原行93的Accept与保护等级fallback并不证明配对恢复了属性读取。脚本第7–8行“so camera stops dropping”是未验证因果假说；须有准确状态、原始日志及读回才能确认，当前新增包没有所引Windowswatch日志。

目标Name已替换为占位，原来真实设备标识不再公开。工具与S1M2完整固件逆向间尚无实际解码链，不自动运行pair/unpair/watch。

原稿行号对应接收时未插评论的原始源码。现有纠错：[联合核验结论](../../../../../analysis/s5_toolbox_review_20261013/联合核验结论.md)、[既有S5评审](../../../../../analysis/s5_delivery_review_20261010/评审结论.md)。
