# S5M2 官方源碼：啟動／更新消费者核查（2026-10-14）

本輪直接取得並核查 Panasonic **DC-S5M2 Ver1／Ver2 頁面實際連結的六份源碼包**，補足先前主要引用 S1M2／Leica 資料的型號證據。已定位、閱讀每版 14 個指定 C 函式的源码處理路徑，完成全常規檔案字節掃描及版本差分。**尚未找到接受現代 UPD revision 0x200、selector 3、92-byte 目錄的實際消費者，沒有取得 S5M2 受保護元件明文。**

這是一項新的同型號源碼核查，不是重跑密鑰枚舉或宣稱完整逆向。原廠程式、固件及相機均未執行／操作。

## 來源與身份

官方頁面：[DC-S5M2 Ver1](https://ospo.panasonic.com/oss/dsc/DC-S5M2.html)、[DC-S5M2 Ver2](https://ospo.panasonic.com/oss/dsc/DC-S5M2%28Ver2%29.html)。頁面上的 Ver1／Ver2 是源碼分發標籤，**沒有證據把它們指定為 S5M2 V3.1 的精確構建版本**。所有摘要是本輪從官方下載內容計算的固定快照，不是廠商公布的簽署校驗值。

| 本地輸入名稱 | bytes | 完整 SHA-256 |
| --- | ---: | --- |
| S5M2_Ver1_uboot.tar.gz | 18797603 | e7d301fb8b2cc509d7d5d42b53c13a61e6c21d5792804b314927b2f6cd2b40d3 |
| S5M2_Ver2_uboot.tar.gz | 18794907 | c27cf53af6d8e3a18af0455fe7841c8db955bb58c5943ef94a3a6632439ad692 |
| S5M2_Ver1_linux.tar.gz | 165739116 | 617c2712db38aed13cd5b6e96890d759d1b215ad20768dddd716b8ceaebc7811 |
| S5M2_Ver2_linux.tar.gz | 165783865 | 2468af4cfb8fa6e22cca5d2660ea270e14e1cceaa1c63359756aab396b791d67 |
| S5M2_Ver1_FreeRTOS.tar.gz | 68566076 | 2078beb8ec3714b4a0a7e9d51456674eac5d0c7ee1d922f88e59493e28c43f97 |
| S5M2_Ver2_FreeRTOS.tar.gz | 68566076 | 2078beb8ec3714b4a0a7e9d51456674eac5d0c7ee1d922f88e59493e28c43f97 |

各包的直接下載 URL、常規檔案內容目錄摘要、逐項命中、相關源码檔案完整摘要／行號／函式範圍摘要均保存在[机器結果](results_checked/source_audit.json)。未上傳原廠包或大批轉載其源碼；短小證據摘錄不變更原來源的授權。

倉庫參照基線：Siegfried82/lumix-s1m2-research@86cb4e819f2fb86b6e4a83d168853be40acf1dc6。此前 S5M2 V3.1 容器[基線 PR #10](https://github.com/Siegfried82/lumix-s1m2-research/pull/10)核到型號 MC8223、54 項、40 項 flags=3；本輪源碼資料不能代替那份實際固件或證明二者精確構建相同。

## 新增／糾正的型號證據

- Ver1 的 U-Boot 配置及 Linux DTS／defconfig 實際標為 **MC8223**，與 S5M2 V3.1 型號字串一致；仍缺對應構建識別與實機驗證。
- **Ver2 頁面實際下載的 U-Boot／Linux 檔案標為 MC8223X**。記錄的是包內事實，不推斷網站誤放、S5M2X 獨占、兩機完全相同或已獲新解碼器。
- U-Boot：每包 15,224 個常規檔案；15,221 個相同路徑內容一致；3 個 MC8223 路徑移除、3 個 MC8223X 路徑新增。
- Linux：每包 61,995 個常規檔案；61,990 個相同路徑內容一致；5 個板級路徑移除、5 個新增。
- 上述「同路徑相同」不代表更名檔案內容也相同；新增／移除項的大小與完整摘要全部單列，未自動建立語義等價。
- FreeRTOS：兩份原始 tar.gz 完整摘要相同；16,274 個常規檔案逐項大小／摘要也相同。不能把它們算成兩個獨立解碼實作。
- 這兩份 S5M2 Linux 的 socionext/Makefile:17–18 僅列參數化的基本 DTB 構建目標，包內没有 -shell.dts。**不能照搬 S1M2 材料的 -shell.dtb 缺失論證當作 S5M2 的構建缺口。**

## 直接讀取的消费者鏈與停止位置

以下位置以 Ver1 包內原始檔案行號為準；Ver2 同路徑 C 源碼字節相同。函式位置／完整範圍摘要可由工具重算；lexical_call_tokens 只是詞法呼叫候選，並非完整 AST、連結結果或動態追蹤。

| 源碼位置 | 實際輸入與處理 | 尚未接上的一段 |
| --- | --- | --- |
| u-boot/configs/pvc04v_MC8223_defconfig:32、43；cmd/unzip.c:10；lib/gunzip.c:72、275 | 源码配置 RAM 起點 0x400200000，do_unzip 把 src/dst 轉成指標交給 gunzip → gzip_parse_header／zunzip → inflate，輸出位置配置為 0x403700000 | 從儲存體取得／認證／解碼並填充這段 RAM 的實際生产者 |
| u-boot/cmd/booti.c:19、63 | booti_start 使用記憶體中的 Image 地址，呼叫 booti_setup，必要時 memmove，再經 do_bootm_states 處理啟動 | 實際 Image／DTB、前級寫入者及相機執行紀錄 |
| linux-4.19.124/drivers/mtd/devices/slram.c:128、106 | register_device 以 memremap 包裝指定記憶體；slram_read 用 memcpy 讀取，沒有此處的 UPD 取檔／解碼步驟 | RAM 中塊鏡像來源、可驗證的內容及實機映射 |
| linux-4.19.124/fs/ipcufs.c:1084、473 | readpage 填 IFSA_READPAGE、檔案句柄、共享頁地址、長度與檔案偏移，經 ipcufs_transfer → sni_ipcu_send_msg_kernel 請求，再 memcpy_fromio 取回頁面 | 遠端服務端的動作分發實作、實際掛載點與盤號／分區關係 |

MC8223 DTS:30 配置 root=/dev/mtdblock0、slram0 起點 0x4012A0000／長 0x00400000、slram1 起點 0x4016A0000／長 0x02060000。它沒有同處的 rootfstype=ext2，故本輪不宣稱已確認實際文件系統格式。這些是源碼配置地址，**不是授權或已驗證的實機讀取範圍**；也沒有把固件目錄 u32 欄位自動加基址配成 RAM 地址。

board_init:6–13 是 return 0 空桩；dram_init:65–77 呼叫 FDT 記憶體配置助手。這兩個已讀函式沒有建立原始 UPD → 啟動 RAM 的生產链。這不排除其他未追蹤函式、版本或環境。

init/main.c:1335／1389 也已定位。rdinit=/sbin/finit 在 early rootfs 中會被 ksys_access 檢查；不在時才清空並 prepare_namespace，後续还有 init 候選。重複 defconfig 行、源码順序均不能代替相機最終 .config／真實根文件系統，故不聲稱首個程序必為 finit 或 init。

同理，gunzip 名稱／壓縮方法檢查不證明完整 gzip 格式驗收、AES 解碼或 UPD 認證；沒有將其當作現代固件解密函式。

## 真實掃描：保留陽性字串與陰性邊界

[audit_sources.py](audit_sources.py)先驗收整包 SHA-256，再流式讀取每個常規 tar 成員的完整字節，記錄大小、SHA-256，拒絕重複／危險路徑或短讀。沒有抽樣前幾 KiB，也沒有硬編碼空結果。

| 包類型（每版） | 常規檔案 | 全部常規 bytes | UPD 字樣／55504400 模式命中 | 指定元件名稱模式命中 |
| --- | ---: | ---: | ---: | ---: |
| U-Boot | 15224 | Ver1 83214904／Ver2 83214911 | 65 | 5 |
| Linux | 61995 | Ver1 794233051／Ver2 794233064 | 37 | 0 |
| FreeRTOS | 16274 | 262854751 | 3 | 0 |

**不是全掃描「零命中」**。U-Boot 的命中包括其他板卡、Intel FSP／UPD、構建狀態字樣、Rockchip／sunxi／測試中的 loader1；Linux 包括快取統計、網路／硬體暫存器、構建腳本等。FreeRTOS 的3個字節命中位於2份 STM32 .chm 文件的原始字節，不是定位到程序中接受 UPD 目錄的函式。本輪按上下文未建立它們與 S5M2 更新格式的消费者關係，亦沒有解壓 CHM 後宣稱其完整語義。

modern_field_names 指定模式在六包均0命中。每份 FreeRTOS 全部常規字節對 panasonic|socionext|milbeaut|ipcu（獨立詞）|pvc04|sc2006|slram|beefcafe|mc8223 模式0命中。後者**只表示這組具體模式未命中**，不是已證明「純淨上游」、所有專有代码缺失或所有静态路线不可行。

JSON 留下精確 byte regex、每項 byte offset／行號／token hex／ASCII轉義上下文。輸入含非 UTF-8 原始字節；掃描不依賴解碼，函式定位以Latin-1保持一字節一位置，顯示摘錄另轉義。未掃描非普通成員的目標內容；不遞迴解開包內 zip／CHM 等文件，不涵蓋其他命名、間接計算、已編譯指令、未取得專有使用者態或硬體模块。詞法陰性不能替代消费者語義驗證。

## 實際測試與重現

9項[回歸測試](test_audit.py)涵蓋陽性／陰性掃描、詞邊界、非UTF-8、函式中的字串／註解／嵌套括號、呼叫不冒充定義、缺少／未閉合函式、危險路徑、版本差分，以及真實合成tar與錯誤整包摘要拒絕。

[測試日誌](results_checked/unit_tests.log)、[全包掃描日誌](results_checked/source_audit.log)、[實際起訖／退出碼](results_checked/execution.json)由[執行入口](run_checks.py)生成。Python 3.12.14；全部通過。首次掃描因詞法定位器把 if (ipcufs_transfer(...)) 誤視為定義而停止；修正為行首帶型別宣告後新增回歸測試。原始失敗日志在本地 results/ 保留，不覆寫、不計為成功；中間成功版在 results_verified/，公開採附命中上下文的最終 results_checked/。

只需 Python 標準庫。將六份官方包按表中本地名稱保存於 INPUTS；不執行源碼包中的工具、makefile 或二進位檔：

~~~sh
python -X utf8 run_checks.py --inputs /path/to/INPUTS --output replay_new
python verify_delivery.py
~~~

output 必須為新目錄。[交付清單](delivery_manifest.json)核對新增工具、文檔與本次機器結果；不更改父庫的既有歸檔清單。

## 具體下一段

目前缺的是**處理現代 UPD 的實際可讀程式**，或者能把同型號啟動資料與實際儲存／RAM 內容聯繫起來的新材料。這次源碼核查把已知 consumer 停止位置具體化，但沒有替代解碼突破。

優先接受使用者已合法持有的 MC8223／S5M2 啟動日誌、儲存晶片／主板識別照片、帶來源與版本的 flash／RAM dump、實際 DTB／根文件系統或前級更新器程式。先核來源、完整摘要、格式與分段映射，再找 revision／selector／92-byte 目錄的實際讀取、認證與輸出函式。只有容器或更多同內容 OSS 包時，不繼續擴大無新依据的密鑰枚舉。

不要求現在拆機、刷機或猜測地址讀出；任何新設備通訊／寫入均另需明確授權。
