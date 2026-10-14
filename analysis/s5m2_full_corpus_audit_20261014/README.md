# S5M2 全版本核驗（A＋B）

先看 [A＋B核驗報告](A＋B核驗報告.md)與[舊結果更正清單](舊結果更正清單.md)。

本輪：25個本機BIN／ZIP → 10個不同固件身份；542項全範圍核查、14組版本／機型差分、四方bytes重算、28項回歸測試。原始25個資產與19份舊成果完整摘要不變，4份較早正確JSON逐項吻合，8963份既有公開歸檔核驗通過。

- [解析、資產與差分工具](corpus_audit.py)
- [固定十份樣本清單](corpus_profiles.json)
- [測試](test_corpus.py)、[執行入口](run_checks.py)
- [独立結果與原檔核验](verify_results.py)、[交付核验](verify_delivery.py)
- [資料清單](results/data/inventory.json)、[逐項固件基線](results/data/corpus.json)
- [14組差分](results/data/comparisons.json)、[四方差分](results/data/fourway.json)
- [旧結果逐项核对](results/data/legacy_audit.json)、[原稿快照索引](results/data/historical_sources.json)
- [實際執行紀錄](results/execution.json)、[交付摘要](delivery_manifest.json)

没有下载或提取新原廠包，没有解码／執行固件、相機通讯、刷写、GitHub寫入。C与新PR均待使用者确认。local_roots.json是仅本机使用的路径配置，results_dev1/是保留的開發期成功重跑結果，两者不列入交付清單。原稿快照是审查证据，不执行、不自动采信其旧结论。

仅需Python标准库。复算需十份对应身份的原始BIN、清单中的本机ZIP副本及旧成果原始相对目录树。查看总报告的重现说明；输出必须使用新目录，避免覆盖此前证据。
