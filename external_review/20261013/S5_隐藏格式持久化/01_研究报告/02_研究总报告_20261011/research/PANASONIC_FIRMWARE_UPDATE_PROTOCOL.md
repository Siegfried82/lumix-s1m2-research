> **Codex核验评论（2026-10-13）**：以下正文是外部作者材料的公开副本。收录不等于证实；作者说法与本项目核验分开。原稿 SHA-256：`6a835f4d99c6a8c7dd22de58627b6ef291c03a4fcb71512e54647db3c94cd171`。原稿行号仍按未注释原件计算。
> 参见[该包纠错总评](../../../CODEX_REVIEW.md)；未在本轮执行其脚本、设备请求或录像实验。

# Panasonic LUMIX Sync — Firmware Update Protocol (reverse-engineered)

Source: decompiled `com.panasonic.jp.lumixsync` (jadx output under `jadx_out/sources/`).
Class names below are the obfuscated jadx names; paths are relative to `jadx_out/sources/`.

## 1. Endpoints

The camera exposes an HTTP CGI interface on port **80**:

```
http://<camera-ip>/cam.cgi?mode=<mode>[&type=<type>][&value=<value>][&value2=<value2>]
```

Base URL is built in `p168v5/a.java`:

```java
this.f27235n = String.format("http://%s", str);   // str = camera IP
```

URLs are assembled by `p168v5/n.java`:

```java
public static String c(String str, String str2, String str3, String str4) {
    String str5 = "/cam.cgi?";
    if (str != null) str5 = "/cam.cgi?" + String.format("mode=%s", str);
    if (str2 != null) str5 = str5 + String.format("&type=%s", str2);
    if (str3 != null) str5 = str5 + String.format("&value=%s", str3);
    if (str4 == null) return str5;
    return str5 + String.format("&value2=%s", str4);
}
```

A second, separate DLNA endpoint also exists (`p168v5/a.java` line ~882): `http://<camera-ip>:60606/Lumix/Server0/ddd` — used for content browsing (SOAP `ContentDirectory:1#Browse`, User-Agent `Panasonic MIL DLNA CP UPnP/1.0`), **not** part of the firmware-update flow.

## 2. HTTP transport (`p094l5/*`)

Common for all CGI calls:

- `User-Agent: LUMIX Sync`
- Optional `X-SESSION_ID: <session>` header (static `b.f23271h`, set via `b.o(...)`; the value is pushed by `p168v5.m.m(...)` before every request).
- Default connect/read timeout = **10000 ms** (`b(String)`); passing an `int` timeout sets both connect and read timeout to that value (0 = no timeout).

Request classes:

| Class | Method | Verb | Body | Response type |
|---|---|---|---|---|
| `p094l5.g` (string GET) | `e()`→`l()` | GET | — | UTF-8 string |
| `p094l5.a` (binary GET) | `e()`→`l()` | GET | — | raw `byte[]` |
| `p094l5.f` (multipart POST) | `e()`→`l()` | POST | multipart/form-data | UTF-8 string |
| `p094l5.h` (GET + content-type) | `e()`→`l()` | GET | — | string + content-type |

`p168v5/m.java` is the façade used by `a.java`:

- `m.c(url, timeout)` → string GET (`g`)
- `m.b(url, timeout)` → binary GET (`a`)
- `m.h(url, byte[])` → multipart POST of bytes (`f`)
- `m.f(url, sb, timeout)` → GET, records response content type

All execute calls are serialized on a global lock (`m.f27319b`), check the HTTP status is 200, and return `false`/`null` on error.

## 3. Firmware update sequence

Entry point: `com/panasonic/jp/view/setting/FwUpdateActivity.Eb(...)`.

```java
byte[] bArrYb = FwUpdateActivity.this.yb(new File(strB));           // whole FW file into memory
FwUpdateActivity.this.Eb(aVar2, bArrYb);
```

```java
public void Eb(p168v5.a aVar, byte[] bArr) {
    this.f20457d1 = aVar;
    if (aVar.O(this.f20455b1, String.valueOf(bArr.length), null, bArr, bArr.length, new j())) {
        return;   // success
    }
    // ... error dialog (ON_FW_UPDATE_ERR_CRITICAL)
}
```

- `f20455b1` = `"fw"` (camera body) or `"lens_fw"` (lens).
- The whole firmware file is read into a `byte[]` (see `yb()`), then streamed chunk-by-chunk.

The actual transfer is `p168v5/a.O(...)` (and the near-identical `N(...)`):

```java
public boolean O(String str, String str2, String str3, byte[] bArr, long j7, s sVar)
// str  = type   ("fw" | "lens_fw")
// str2 = value  (firmware file size, decimal string)
// str3 = value2 (null)
// bArr = full firmware bytes
// j7   = firmware length
// sVar = progress callback (p168v5.s)
```

### 3.1 `startsenddata`

```
GET http://<ip>/cam.cgi?mode=startsenddata&type=fw&value=<file-size>
```

(sent via `m.c(url, 0)` → `g`, 10000 ms timeout)

The reply is XML, parsed into an `o` object (`p168v5/o.java`). On `<result>ok</result>`:

- `<method>` → `o.h()`:
  - `"once"` → single-shot: one POST carries the whole file, no `endsenddata`.
  - `"separate"` → chunked: chunk payload = `bufsize - V()` (see §5), and `endsenddata` is sent after the last chunk.
  - anything else/absent → `iA = 0` (dead loop; treated as failure in practice).
- `<bufsize>` → `o.a()`: the camera's maximum accepted POST body size.

### 3.2 Chunk loop (`senddata` + `requestsenddata`)

For every chunk:

1. Copy `iA` bytes of the file into a fresh `byte[]`.
2. POST that chunk to `mode=senddata` (see §4).
3. Parse the reply:
   - `"ok"` → continue;
   - any other result → call `sVar.c(result)` and abort with failure.
4. Remaining bytes `j8 -= iA`.
   - If `j8 <= 0`: if mode was `separate` send `endsenddata` (§3.3), then `sVar.b()` (complete) and return `true`.
   - Otherwise: if `j8 < iA`, shrink `iA = j8`; send `requestsenddata` (§3.4); update progress `sVar.d(seconds, percent)`.

### 3.3 `endsenddata`

```
GET http://<ip>/cam.cgi?mode=endsenddata
```

(sent via `m.b(url, 0)` → binary GET `a`, **no** timeout; reply parsed as `o(byte[])`)

### 3.4 `requestsenddata`

```
GET http://<ip>/cam.cgi?mode=requestsenddata
```

(sent via `m.b(url, 0)` → binary GET `a`, no timeout; reply parsed as `o(byte[])`)

Returned `true` if the reply is `ok`.

### 3.5 `abortsenddata`

```
GET http://<ip>/cam.cgi?mode=abortsenddata
```

(`p168v5/a.l()`, binary GET, no timeout). Invoked by the UI cancel path (`FwUpdateActivity$j$a$a$a.run()` → `f20457d1.l()`).

### 3.6 Progress callback `p168v5.s`

```java
void a();                 // transfer started
void b();                 // transfer complete
void c(String result);    // error (result string, e.g. "err_battery", "err_reject", ...)
void d(int seconds, int percent);  // remaining-time estimate, percent done
```

## 4. Multipart `senddata` encoding (`p094l5/f.java`, `p168v5/n.java`)

```
POST http://<ip>/cam.cgi?mode=senddata
Content-Type: multipart/form-data; boundary=<B>
Connection: Keep-Alive
User-Agent: LUMIX Sync
```

Boundary (static final, constant for the whole app process):

```java
String f23305j = "=====" + UUID.randomUUID().toString() + "=====";   // 46 chars
```

One form-data part per POST, built by `n.d(url, chunk)`:

```
--<B>\r\n
Content-Disposition: form-data; name="filename"; filename="send"\r\n
Content-Type: application/octet-stream\r\n
Content-Transfer-Encoding: binary\r\n
Content-Length: <chunk-size>\r\n
\r\n
<chunk bytes>
--<B>--
```

Notes:

- The part headers (name/filename/content-type) come from `f.b(...)`'s format string; the two extra headers `Content-Transfer-Encoding` and `Content-Length` are added via `bVar.b("Content-Transfer-Encoding", "binary")` and `bVar.b("Content-Length", Integer.toString(bArr.length))` in `n.d(...)`.
- After the last part, `f.d(...)` writes `--<B>--` with **no** preceding CRLF, so the body ends `...<chunk>--<B>--`. (The length-estimate helper `V()` below assumes a leading `\r\n`, i.e. it over-estimates the closing overhead by 2 bytes — conservative by design.)

## 5. Chunk-size calculation (`p168v5/a.V()`)

For `"separate"` mode the per-POST payload is:

```
iA = bufsize - V()
```

`V()` measures the byte length (UTF-8) of a sample multipart header + closing boundary using a hard-coded `Content-Length: 61460`:

```
--<B>\r\n
Content-Disposition: form-data; name="filename"; filename="send"\r\n
Content-Type: application/octet-stream\r\n
Content-Transfer-Encoding: binary\r\n
Content-Length: 61460\r\n
\r\n
\r\n
--<B>--
```

i.e. the fixed per-chunk overhead is counted so the camera's advertised `bufsize` (whole HTTP body) is never exceeded. The `61460` in the sample is the expected payload, implying a camera `bufsize` ≈ `61460 + V()` (overhead ≈ 270 bytes with the 46-char boundary).

## 6. Response XML parsing (`p168v5/o.java`)

`o` is constructed two ways:

- `o(byte[])` — used for `requestsenddata` / `endsenddata` / `abortsenddata`; always parses XML (`q()`).
- `o(String, j)` — used for `startsenddata` / `senddata`; `Y(str)` sniffs XML vs CSV (`u.a(str)`); if XML, parsed with `q()`, else split on `,`.

The tag dispatcher `q()` skips the root `<camrply>` and handles:

| XML tag | setter | getter | meaning |
|---|---|---|---|
| `<result>` | `S()` → `f27345a` | `g()` | `ok`, `err_busy`, `err_reject`, `error`, … |
| `<method>` | `I()` → `f27336J` | `h()` | `once` / `separate` |
| `<bufsize>` | `v()` → `f27337K` | `a()` | max POST body size (int) |

`o.o()` returns true iff result == `"ok"`. `o.g()` returns `"ok"`-style result strings that the UI maps to error dialogs (`err_battery`, `err_reject`, `err_fw_same`, `err_fw_old`, `err_lens_error`, … — see `FwUpdateActivity$j.c`).

## 7. Retry / error behaviour (`p168v5/a.java`)

- Every command retries up to `f27237p = 5` attempts.
- `"err_busy"` → sleep `f27239r = 1000 ms`, retry.
- `null` response / transport error → sleep `f27238q = 1000 ms`, retry (some paths).
- A global cancel flag `p078j5.b.d().b()` breaks the retry loops (used for the abort path).

## 8. Source map

| Concern | File |
|---|---|
| Firmware transfer flow (`O`, `N`, `I`, `J`, `u`, `l`, `V`) | `jadx_out/sources/p168v5/a.java` |
| URL builder | `jadx_out/sources/p168v5/n.java` |
| Response model / XML parser | `jadx_out/sources/p168v5/o.java` |
| HTTP façade (session serialization) | `jadx_out/sources/p168v5/m.java` |
| Multipart POST | `jadx_out/sources/p094l5/f.java` |
| Base transport / timeout / status | `jadx_out/sources/p094l5/b.java` |
| GET (string / binary) | `jadx_out/sources/p094l5/g.java`, `jadx_out/sources/p094l5/a.java`, `jadx_out/sources/p094l5/e.java` |
| Firmware update UI / callback | `jadx_out/sources/com/panasonic/jp/view/setting/FwUpdateActivity.java` |
