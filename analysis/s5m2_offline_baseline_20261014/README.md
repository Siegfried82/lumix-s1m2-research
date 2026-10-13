# S5M2 V3.1 離線基線與有限 AES 重放（2026-10-14）

本次完成使用者選定的兩項工作：建立 S5M2 固件可重現基線，以及修正、驗證既有密碼實驗方法。既有原稿保留；本目錄提供獨立的嚴格驗證器及可重放替代入口，不執行外部裝置工具。

實際結果：官方 ZIP 與 BIN 完整身份匹配，54 個組件與既有清單逐項一致，既有解包器產生的 54 個檔案也全量匹配。23 項回歸測試、3 組 NIST AES-128 ECB/CBC/CTR 加解密已知答案測試通過；5,044 個去重的文件來源候選，在指定 512-byte 組件上完成 25,220 次有效測試，0 個候選摘要匹配、0 個執行錯誤。未恢復固件明文或密鑰。

## 输入与来源

研究倉庫基線：`Siegfried82/lumix-s1m2-research@86cb4e819f2fb86b6e4a83d168853be40acf1dc6`。

| 輸入 | bytes | 完整 SHA-256 |
| --- | ---: | --- |
| S5m2_V31.zip | 186598983 | `2e3a5ce15e71079a3cba6acf412393fba30270389409bf637f8d285fef7b518a` |
| S5m2_V31.bin | 205683712 | `3ce8a371c2a3c088e573a5716ab92dd6a095a780b1d58420d4d6856ed75afd58` |

[官方下載來源](https://panasonic.jp/support/share/eww/com/software/lumix_sync/dsc/ff/zip/S5m2_V31.zip)由已歸檔的 DC-S5M2 官方固件 XML 指向。ZIP 只有指定 BIN；首次完整讀取另核 ZIP CRC。

參照[既有逐項清單](../sources/lumix_sync_static/official_firmware_list/S5M2_full_inventory.json)，其文件完整 SHA-256 為 `4eed9d1511fd4905acb892694498ca9f6c4a9f4f1acf0b2f5e77d06563d08e47`。本次重新從原始 BIN 計算全部物件，不只複製清單。

密碼重放參考先前指出問題的 `williamwu1234/S5-reverse-engineering@872b9bc83e1f2ba8e291c07fe28da6f1de8382cb` 的 `firmware_crypto/parse_upd.py` 與 `keyhunt.py`。沿用有限文件候選家族作基線；不是重跑所有舊腳本或 S5 V2.9 的全部歷史試驗。[既有腳本審查](../s5_github_review_20261013/delta_review/DELTA_FINDINGS.md)。

## 1. 嚴格的容器基線

[upd_baseline.py](upd_baseline.py)先核對外／內層 UPD magic、完整輸入摘要、外層 CRC32、動態目錄數、每項範圍及非空項重疊，再以目錄索引核對全部 54 項。每個文件起點使用 `0x200 + relative_offset`，同名項保留索引。

| 實際檢查 | 結果 |
| --- | --- |
| 型號欄位 | MC8223 |
| 外層 CRC32 | 頭部／計算均 `beee6883` |
| 目錄 | 54×92 bytes；結束於 5716 |
| flags | 40 項 flags=3、14 項 flags=2 |
| 原始完整摘要等於目錄欄位 | 14 項，均 flags=2；含4個空物件 |
| 實際非空物件 | 50 項 |
| 舊清單的名稱／大小／flags／偏移／完整摘要／全部尾欄位 | 54／54 完全一致 |
| 既有解包器輸出檔案 | 54／54 大小及完整 SHA-256 一致 |

[新基線](results_verified/baseline.json)、[解出檔案的獨立核對](results_verified/extraction_audit.json)。flags、目錄摘要及尾欄位保持中性命名，不自動稱為加密算法、明文摘要或 IV。既有解包器日志中的「signature/encrypted」是舊工具標籤，本次不驗證該語義。

本次沒有執行既有 S1M2 重打包器：其固定 `0x1A00` payload 開始位置不能直接當作 S5M2 正確重建基線。本次驗收的是提取範圍與資料身份，不是可安裝包、驗簽或機身支援。

## 2. 密碼實驗修正与实际覆盖

[cipher_replay.py](cipher_replay.py)的修正：

- 一律從嚴格解析後的絕對範圍取完整 payload，不直接使用目錄相對偏移。
- CTR 明確採用 `nonce=b""`、128-bit 大端初始計數區塊；這是一種指定假設，沒有把目錄尾欄位確認為真 IV。
- 先以[NIST SP 800-38A Appendix F](https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-38a.pdf)的多區塊已知答案驗證 ECB、CBC、CTR 加密及解密，失敗就停止真實試驗。
- 實際重現舊 `AES.MODE_CTR, iv=...` 呼叫的 TypeError，記在 controls；不計入真實試驗。
- 錯誤、完整執行未匹配、候選完整摘要匹配三類分开；任何真實試驗錯誤使 CLI 以非零退出。
- 不去除 padding、不解壓、不做額外 XOR 或變換；以完整輸出 SHA-256 比較目錄候選欄位。

CTR API 依[PyCryptodome 官方文件](https://www.pycryptodome.org/src/cipher/classic#ctr-mode)設定。實際環境：Python 3.12.14、PyCryptodome 3.23.0；依賴在[requirements.txt](requirements.txt)固定。

本輪自動選取最小非空 flags=3（<=64 KiB），以索引破除同大小平手：

| 物件 | 值 |
| --- | --- |
| 索引／名稱 | 18／eep_act_a |
| 相對／絕對偏移 | 134747648／134748160 |
| 完整測試範圍 | 512 bytes |
| 原始 SHA-256 | `3394612e87638ffc27a25266ffaa74ba52e664865641400c5924e122ba7a4cbe` |
| 目錄候選摘要 | `3bdcb4d0d03318c64c76be1f413395e666aec061f62236ebe6f757cac84a88d0` |

候選來源為前8 KiB附近、4-byte對齊起點的16／24／32-byte窗口、模型欄位、目錄尾候選與反轉、頭部窗口及6個舊PTool表取樣假設。不扩展密鑰空間；PTool取樣位置由其表與基址另行界定，不能把所有讀取範圍稱為僅前8 KiB。6-byte去尾模型文字被明確記作不合法AES長度，不投入試驗。

| key bytes | 去重候選 | ECB | CBC | CTR128_BE |
| --- | ---: | ---: | ---: | ---: |
| 16 | 1594 | 1594 | 3188 | 3188 |
| 24 | 1695 | 1695 | 3390 | 3390 |
| 32 | 1755 | 1755 | 3510 | 3510 |
| 合計 | 5044 | 5044 | 10088 | 10088 |

CBC／CTR用目錄尾候選與全零區塊兩種初始化值；header[0x80:0x90]也全零，去重後保留其来源。ECB不重複測試無用的 IV。

[完整結果](results_verified/cipher_replay.json)保留每個候選的SHA-256身份、長度、生成來源、全部參數家族、分模式計數、錯誤與匹配紀錄。未記錄所有未匹配輸出的摘要；要逐次重算，使用相同原始固件和腳本。沒有公開候選密鑰字節或原始載荷。

**有效陰性的範圍：這5044個候選、這3個模式／2個初始化假設、索引18的全部512 bytes，沒有產生等於目錄欄位的輸出摘要。** 未測其他組件、其他計數布局、層次、衍生算法、padding／解壓。目錄摘要覆蓋明文、尾欄位為IV及算法是AES也尚未證實。不能因此定位OTP／eFuse或證明離線解碼不可能。

## 實際驗證與歷史失敗

[run_stage12.py](run_stage12.py)保留每步開始時間、退出碼、完整stdout/stderr、日誌摘要；目前全部步驟通過：

- [23項回歸測試](results_verified/01_unit_tests.log)：CRC、目錄與payload越界、重名索引、空摘要、錯位陽性／陰性、完整輸出摘要、標準模式、錯誤與未匹配區分。
- [官方樣本驗收](results_verified/02_real_baseline.log)及[既有解包器](results_verified/03_existing_extractor.log)。
- [有限重放](results_verified/04_bounded_cipher_replay.log)：25220有效試驗、0錯誤、0匹配。
- [倉庫要求的verify_public.py](results_verified/05_archive_integrity.log)：8963份既有歸檔散列匹配，真實PTP屬性與合成dump解析測試通過。
- [執行總紀錄](results_verified/execution.json)。

第一次完整流程的歸檔检查因Windows cp950讀取UTF-8 CSV失敗，並非檔案散列不符。[原始失敗日誌](development_history/05_archive_integrity.log)及[當次步驟](development_history/failed_execution.json)保留。執行入口後來明確設定PYTHONUTF8=1；以新輸出目錄重跑通過。開發期已知答案測試另抓到ECB向量抄錄多一碼，修正後才執行真實試驗。

新增交付檔案用[delivery_manifest.json](delivery_manifest.json)和[verify_delivery.py](verify_delivery.py)核对；父庫FILE_MANIFEST.csv继续覆盖原歸檔，沒有將舊公開摘要重寫成「通過」。

## 從乾淨副本重現

以下從本目錄執行；INPUTS與新結果目錄均使用使用者指定的實際位置。整個入口只讀原廠內容，寫本地派生檔案。取得官方 ZIP 後核对上述完整摘要，不使用其他版本替代。

```sh
python -m pip install -r requirements.txt
python -m unittest -v test_baseline
python run_stage12.py --inputs /path/to/INPUTS --output replay_new
python verify_delivery.py
```

INPUTS裡放 `S5m2_V31.zip`。若指定BIN尚不存在，工具只解出固定文件名並驗收；若BIN已存在，仍以profile完整摘要核对。所有结果目录必須為新目錄，不能覆寫以往紀錄。

Windows執行入口會為子程序啟用UTF-8；單獨執行父庫核驗可用 `python -X utf8 ../../evidence/verify_public.py`。依賴與原廠ZIP/BIN、54個原始組件均不隨GitHub交付；它們在本地INPUTS保留。

本次推進的是可信解析、有效試驗與陰性覆蓋；下一段仍須定位現代UPD真正的認證／解碼／裝載處理程式。沒有裝置通訊、設定寫入、刷寫或真機RAM讀出。
