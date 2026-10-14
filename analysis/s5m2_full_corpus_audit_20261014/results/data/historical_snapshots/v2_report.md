# Panasonic LUMIX S5M2 韌體解析 V2

日期：2026-10-10  
方法：離線、只讀靜態分析；未安裝 APK、未連接相機、未修改或重封裝韌體。

## 執行摘要

本輪重新驗證了目前磁碟上兩個 Panasonic 官方更新包：S5M2 V3.7 與 S5M2X V2.7。兩者都包含一個 179,207,168-byte 的 `UPD\0` 容器，外層 CRC32 正確、產品識別碼分別為 `MC8223` 與 `MC8223X`、各有 58 個目錄項，所有非空載荷都在檔案範圍內且連續排列。

最可信的 92-byte 目錄項結構是：

```text
name[12]
relative_offset[4]
size[4]
destination[4]
flags[4]
stored_sha256[32]
iv[16]
reserved[16]
```

目前證據強烈支持 `flags=3` 項目經過加密或另一種帶 IV 的轉換，而 `stored_sha256` 是轉換後明文或中間表示的 SHA-256；但尚未取得金鑰、解密器或相機端驗證程式碼，因此不能把演算法定名為 AES-CBC、CTR、XTS 或任何特定構造。

外層 `0x220–0x25f` 的 64-byte 高熵欄位是簽章／帶密鑰認證值的強候選，但目前沒有公鑰驗證結果，不能稱為「已證實簽章」。修改 CRC32 與目錄雜湊也不代表更新包會被相機接受。

## 原始資料盤點

目前 V2 工作目錄起初只有空的 `work/` 與 `outputs/`。既有研究與原始樣本位於相鄰工作目錄；本輪沒有搬動或覆寫它們。

| 樣本 | ZIP 大小 | ZIP SHA-256 | BIN 大小 | BIN SHA-256 |
|---|---:|---|---:|---|
| S5M2 V3.7 | 157,761,949 | `5e92c6adc967159369937c0313beefdfd9934ff365663b70ade4b906400f2774` | 179,207,168 | `99180a1738d74d0d0062e146dd0f239f65cb5bca6b49a8d2a1a94a8018d93ffa` |
| S5M2X V2.7 | 157,760,717 | `363b2cda212706e9f6c63cabbfcdace41fb3428283dfa9f657854bedba284b50` | 179,207,168 | `58603257c06c35da637af82f4a433faeaf82aaefc58021658d23ceb81721474a` |

可用既有資料還包括：

- S5M2 V2.0→V2.2、V2.0→V3.1、V3.1→V3.2 的完整 JSON 差分。
- 既有報告記錄的 V1.1、V2.0、V2.2、V3.1、V3.2、V3.4 六版結果；但本輪磁碟盤點只找到兩個最新版 ZIP，舊版結論應以保留的 JSON／報告視為二手可重查證據，而非本輪重新讀取原始 BIN。
- LUMIX Lab 3.1.0（versionCode 22）的 APK、splits、JADX 與 Androguard 輸出。
- 只讀解析器 `inspect_upd.py`，可讀單一 BIN 或只含一個 BIN 的 ZIP，不解密、不修改、不重簽、不刷機。

## 可驗證的封裝結構

### 外層與目錄

| 偏移／欄位 | 本輪觀察 |
|---|---|
| `0x000` | `UPD\0` magic |
| `0x00c` 起的 16 bytes | NUL 結尾產品識別碼；S5M2=`MC8223`、S5M2X=`MC8223X` |
| `0x040` | little-endian CRC32；計算範圍為檔案 `0x200` 至 EOF，本輪兩包皆匹配 |
| `0x200` | NUL 補齊的 `panasonic` 廠商標記 |
| `0x220` | 64-byte、每包不同、非零的高熵認證候選欄位 |
| `0x2e8` | 32-bit little-endian 目錄項數，本輪為 58 |
| `0x2ec` | 92-byte 目錄項陣列起點 |

V3.7 的目錄結束於 decimal 6084（`0x17c4`），第一個實際載荷從 `0x1800` 開始。解析器以 `absolute_offset = relative_offset + 0x200` 計算載荷位置。

### `flags` 與資料特徵

- `flags=2`：目前非空項目的原始 payload SHA-256 與目錄 `stored_sha256` 相符，IV 為零；最新版可讀項目實際上是全 `0x00` 或全 `0xff` 填充。
- `flags=3`：原始 payload SHA-256 不等於 `stored_sha256`，IV 為非零，前 64 KiB 樣本熵約接近 8 bits/byte，符合加密或強壓縮資料的外觀。
- 所有檢查到的 `reserved[16]` 都為零。
- `eep_ow_a/b`、`eep_act_a/b`、`eep_exp_a/b` 在同一包內可出現「相同大小、相同 stored SHA-256、不同 IV、不同密文 SHA-256」；這是 `stored_sha256` 指向明文／中間表示，而非密文的強證據。

## S5M2 V3.7 與 S5M2X V2.7 的重驗結果

- 58 個目錄項全數可依名稱與同名出現次序對齊。
- 43 個項目為 `flags=3`。
- 其中 33 個項目的 `stored_sha256` 相同，但 IV 與原始密文 SHA-256 不同：最簡潔模型是相同明文以不同 IV 重新加密。
- 僅 10 個加密組件的 `stored_sha256` 跨機型不同：

```text
program
compress_pr
postboot1_r #0
postboot3_r #0
postboot5_r #0
postboot1_r #1
postboot3_r #1
postboot5_r #1
eep_fix
osdover
```

`eep_act_a/b` 與 `eep_ow_a/b` 跨 S5M2／S5M2X 保持相同明文候選，因此不支持「更新包內這些槽位本身就是 S5M2X 或 DMW-SFU2 功能開關」的簡單模型。機型／功能差異的首要靜態候選是 `program` 與 `eep_fix`；`osdover` 可能涉及介面呈現，`compress_pr` 與 `postboot*` 更可能同時承載 S5M2X 額外的編解碼或影像管線能力。這些是依名稱與版本差分做的定位，不是函式級證明。

完整逐項結果已輸出為 `s5m2_v37_vs_s5m2x_v27.json`。

## 簽章與加密線索：證據等級

### 已驗證

- 外層 CRC32 正確，但 CRC32 只提供誤碼檢查，並非密碼學認證。
- 目錄內有 32-byte digest、16-byte IV 與 16-byte zero reserved 欄位。
- 同明文候選可搭配不同 IV 產生不同 payload，且此模式跨版本、跨機型大量重現。
- `0x220` 有 64-byte、每包不同的非零高熵值。

### 強推論

- `flags=3` 表示需解密或解密後再處理。
- 32-byte 欄位是明文或解密後中間表示的 SHA-256，可作為未來解密成功判據。
- 64-byte 外層欄位可能是裸格式橢圓曲線簽章、MAC 或其他帶密鑰認證值。
- 驗證金鑰或裝置秘密更可能位於相機 boot chain、ROM／OTP 或受保護儲存區，而非公開更新包。

### 尚未證實

- 實際加密演算法、模式、金鑰長度與 key derivation。
- `stored_sha256` 是最終明文、解壓前明文或另一中間表示。
- 64-byte 欄位的演算法、覆蓋範圍與驗證公鑰。
- 舊 S5 報告提到的檔尾 RSA-4096 簽章是否也適用於 S5M2；本輪不可直接跨機型沿用該結論。
- 修改過的更新包會在哪一層被拒絕，以及相機回傳的確切錯誤碼。

## App 端更新流程線索

LUMIX Lab 3.1.0 的靜態分析顯示：

- 遠端清單基底為 `https://panasonic.jp/support/share/eww/com/software/lumix_lab/`，App 會請求 `app_version.json` 與 `firmware_list.json`，再依 metadata 取得韌體。
- 相機區網基底為 `https://192.168.54.1/`。
- 更新端點包括 `firmware/send-prepare`、`firmware/send`、`firmware/abort-send`；請求帶 `Authorization`，傳檔含 `Content-Length` 與 `transID`。
- TLS 身份確認依賴由 BLE 讀入的相機憑證 SHA-256 指紋；這條路徑可用於被動記錄更新傳輸與拒絕結果，但不會自然洩露相機內部解密金鑰。

## 建議的後續安全分析順序

1. **固定證據與可重現性**：保留官方 ZIP、來源 URL、下載時間與 SHA-256；每次分析只讀 ZIP，衍生檔寫到獨立工作目錄。
2. **補回舊版原始包**：若能合法取得 V3.4 與更舊版本，重新跑同一解析器，使六版結果不只依賴舊 JSON／筆記。
3. **確認認證欄位**：針對 `0x220` 64-byte 欄位建立差分矩陣，系統性測試覆蓋範圍與常見編碼；優先從相機 bootloader／更新載入器找驗證常數、公鑰與錯誤字串。
4. **先找 verifier，再猜 cipher**：從韌體載入鏈或可合法取得的裝置映像定位 SHA-256、64-byte signature/MAC、目錄解析與 IV 使用處；避免繼續無界弱口令或任意 AES 組合窮舉。
5. **被動抓取官方更新流程**：在隔離測試手機、專用網路與自有相機上記錄 BLE 配對、憑證指紋、`send-prepare` metadata、transID、傳輸順序與相機回覆；不注入、不修改更新檔。
6. **最小化負向測試**：只有建立可恢復方案並接受變磚風險後，才考慮在自有測試機對單一非關鍵位元變更做拒絕階段辨識；不要先碰 bootloader、分割表或 EEPROM 寫入。
7. **成功判據**：任何候選解密必須同時通過目錄 SHA-256、合理 magic／檔案結構、跨版本相同 digest 導出相同內容三項檢查。

## 風險界線

目前成果可安全用於格式研究、差分與被動協定觀察，不能支持刷入修改包。未掌握簽章驗證、回復模式與完整備份前，不建議對相機做任何寫入實驗；尤其不要把「CRC32 可重算」誤認為「可繞過簽章」。

