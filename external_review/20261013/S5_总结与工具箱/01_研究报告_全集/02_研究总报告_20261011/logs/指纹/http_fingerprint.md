> **Codex核验评论（2026-10-13）**：以下正文是外部作者材料的公开副本。收录不等于证实；作者说法与本项目核验分开。原稿 SHA-256：`eeb8b38c4d8c968a41990ea0dcbe0b41244675072ef61efba85cc8862c76bd22`。原稿行号仍按未注释原件计算。
> 参见[该包纠错总评](../../../../CODEX_REVIEW.md)；未在本轮执行其脚本、设备请求或录像实验。

[18:51:21] # S5 cam.cgi HTTP server fingerprint  (session start 2026-10-11 18:51:21)
[18:51:21] Target: 192.168.1.131:80
[18:51:22] Camera ready: ok
[18:51:22] 
########## A. baseline response headers ##########
[18:51:22] 
[18:51:22] == GET /cam.cgi?mode=getstate (full header) ==
[18:51:22]    status : HTTP/1.1 200 OK
Content-Type: text/xml
Content-Length: 622
Date: Sun, 11 Oct 2026 10:51:20 GMT
Server: Panasonic
[18:51:22]    hdr    : HTTP/1.1 200 OK
Content-Type: text/xml
Content-Length: 622
Date: Sun, 11 Oct 2026 10:51:20 GMT
Server: Panasonic
[18:51:22]    body   : b'<?xml version="1.0" encoding="UTF-8"?>\r\n<camrply><result>ok</result><state><batt>5/5</batt><batt_per>-1</batt_per><cammode>play</cammode><sdcardstatus>write_enable</sdcardstatus><sd_memory>unset</sd_memory><version>VD4.30</version><play>stop</play><temperature'
[18:51:22]    bodylen: 622
[18:51:22] 
########## B. method / path matrix ##########
[18:51:22] 
[18:51:22] == OPTIONS /cam.cgi?mode=getstate ==
[18:51:22]    status : HTTP/1.1 500 Internal Server Error
Content-Type: text/html
Content-Length: 369
Date: Sun, 11 Oct 2026 10:51:20 GMT
Server: Panasonic
[18:51:22]    hdr    : HTTP/1.1 500 Internal Server Error
Content-Type: text/html
Content-Length: 369
Date: Sun, 11 Oct 2026 10:51:20 GMT
Server: Panasonic
[18:51:22]    body   : b'<?xml version="1.0" encoding="iso-8859-1"?>\n<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"\n         "htt'
[18:51:22]    bodylen: 369
[18:51:22] 
[18:51:22] == GET /cam.cgi?mode=getstate ==
[18:51:22]    status : HTTP/1.1 200 OK
Content-Type: text/xml
Content-Length: 622
Date: Sun, 11 Oct 2026 10:51:20 GMT
Server: Panasonic
[18:51:22]    hdr    : HTTP/1.1 200 OK
Content-Type: text/xml
Content-Length: 622
Date: Sun, 11 Oct 2026 10:51:20 GMT
Server: Panasonic
[18:51:22]    body   : b'<?xml version="1.0" encoding="UTF-8"?>\r\n<camrply><result>ok</result><state><batt>5/5</batt><batt_per>-1</batt_per><cammo'
[18:51:22]    bodylen: 622
[18:51:29] 
[18:51:29] == HEAD /cam.cgi?mode=getstate ==
[18:51:29]    status : EXC
[18:51:29]    body   : b"FileNotFoundError: [Errno 2] No such file or directory: '/tmp/_s5_cb_40681.bin'"
[18:51:29]    bodylen: 79
[18:51:29] 
[18:51:29] == PUT /cam.cgi?mode=getstate ==
[18:51:29]    status : HTTP/1.1 500 Internal Server Error
Content-Type: text/html
Content-Length: 369
Date: Sun, 11 Oct 2026 10:51:27 GMT
Server: Panasonic
[18:51:29]    hdr    : HTTP/1.1 500 Internal Server Error
Content-Type: text/html
Content-Length: 369
Date: Sun, 11 Oct 2026 10:51:27 GMT
Server: Panasonic
[18:51:29]    body   : b'<?xml version="1.0" encoding="iso-8859-1"?>\n<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"\n         "htt'
[18:51:29]    bodylen: 369
[18:51:29] 
[18:51:29] == DELETE /cam.cgi?mode=getstate ==
[18:51:29]    status : HTTP/1.1 500 Internal Server Error
Content-Type: text/html
Content-Length: 369
Date: Sun, 11 Oct 2026 10:51:28 GMT
Server: Panasonic
[18:51:29]    hdr    : HTTP/1.1 500 Internal Server Error
Content-Type: text/html
Content-Length: 369
Date: Sun, 11 Oct 2026 10:51:28 GMT
Server: Panasonic
[18:51:29]    body   : b'<?xml version="1.0" encoding="iso-8859-1"?>\n<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"\n         "htt'
[18:51:29]    bodylen: 369
[18:51:30] 
[18:51:30] == TRACE /cam.cgi?mode=getstate ==
[18:51:30]    status : HTTP/1.1 500 Internal Server Error
Content-Type: text/html
Content-Length: 369
Date: Sun, 11 Oct 2026 10:51:28 GMT
Server: Panasonic
[18:51:30]    hdr    : HTTP/1.1 500 Internal Server Error
Content-Type: text/html
Content-Length: 369
Date: Sun, 11 Oct 2026 10:51:28 GMT
Server: Panasonic
[18:51:30]    body   : b'<?xml version="1.0" encoding="iso-8859-1"?>\n<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"\n         "htt'
[18:51:30]    bodylen: 369
[18:51:30] 
[18:51:30] == POST /cam.cgi?mode=getstate ==
[18:51:30]    status : HTTP/1.1 411 Length Required
Content-Type: text/html
Content-Length: 357
Connection: close
Date: Sun, 11 Oct 2026 10:51:28 GMT
Server: Panasonic
[18:51:30]    hdr    : HTTP/1.1 411 Length Required
Content-Type: text/html
Content-Length: 357
Connection: close
Date: Sun, 11 Oct 2026 10:51:28 GMT
Server: Panasonic
[18:51:30]    body   : b'<?xml version="1.0" encoding="iso-8859-1"?>\n<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"\n         "htt'
[18:51:30]    bodylen: 357
[18:51:31] 
[18:51:31] == PATCH /cam.cgi?mode=getstate ==
[18:51:31]    status : HTTP/1.1 500 Internal Server Error
Content-Type: text/html
Content-Length: 369
Date: Sun, 11 Oct 2026 10:51:29 GMT
Server: Panasonic
[18:51:31]    hdr    : HTTP/1.1 500 Internal Server Error
Content-Type: text/html
Content-Length: 369
Date: Sun, 11 Oct 2026 10:51:29 GMT
Server: Panasonic
[18:51:31]    body   : b'<?xml version="1.0" encoding="iso-8859-1"?>\n<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"\n         "htt'
[18:51:31]    bodylen: 369
[18:51:31] 
[18:51:31] == GET /cam.cgi?mode=getstate ==
[18:51:31]    status : HTTP/1.1 200 OK
Content-Type: text/xml
Content-Length: 622
Date: Sun, 11 Oct 2026 10:51:30 GMT
Server: Panasonic
[18:51:31]    hdr    : HTTP/1.1 200 OK
Content-Type: text/xml
Content-Length: 622
Date: Sun, 11 Oct 2026 10:51:30 GMT
Server: Panasonic
[18:51:31]    body   : b'<?xml version="1.0" encoding="UTF-8"?>\r\n<camrply><result>ok</result><state><batt>5/5</batt><batt_per'
[18:51:31]    bodylen: 622
[18:51:32] 
[18:51:32] == GET /cam.cgi ==
[18:51:32]    status : HTTP/1.1 200 OK
Content-Type: text/xml
Content-Length: 85
Date: Sun, 11 Oct 2026 10:51:30 GMT
Server: Panasonic
[18:51:32]    hdr    : HTTP/1.1 200 OK
Content-Type: text/xml
Content-Length: 85
Date: Sun, 11 Oct 2026 10:51:30 GMT
Server: Panasonic
[18:51:32]    body   : b'<?xml version="1.0" encoding="UTF-8"?>\r\n<camrply><result>err_param</result></camrply>'
[18:51:32]    bodylen: 85
[18:51:32] 
[18:51:32] == GET /cam.cgi? ==
[18:51:32]    status : HTTP/1.1 200 OK
Content-Type: text/xml
Content-Length: 85
Date: Sun, 11 Oct 2026 10:51:30 GMT
Server: Panasonic
[18:51:32]    hdr    : HTTP/1.1 200 OK
Content-Type: text/xml
Content-Length: 85
Date: Sun, 11 Oct 2026 10:51:30 GMT
Server: Panasonic
[18:51:32]    body   : b'<?xml version="1.0" encoding="UTF-8"?>\r\n<camrply><result>err_param</result></camrply>'
[18:51:32]    bodylen: 85
[18:51:32] 
[18:51:32] == GET /cam.cgi?mode= ==
[18:51:32]    status : HTTP/1.1 200 OK
Content-Type: text/xml
Content-Length: 85
Date: Sun, 11 Oct 2026 10:51:31 GMT
Server: Panasonic
[18:51:32]    hdr    : HTTP/1.1 200 OK
Content-Type: text/xml
Content-Length: 85
Date: Sun, 11 Oct 2026 10:51:31 GMT
Server: Panasonic
[18:51:32]    body   : b'<?xml version="1.0" encoding="UTF-8"?>\r\n<camrply><result>err_param</result></camrply>'
[18:51:32]    bodylen: 85
[18:51:33] 
[18:51:33] == GET /cam.cgi?mode=NOPE ==
[18:51:33]    status : HTTP/1.1 200 OK
Content-Type: text/xml
Content-Length: 85
Date: Sun, 11 Oct 2026 10:51:31 GMT
Server: Panasonic
[18:51:33]    hdr    : HTTP/1.1 200 OK
Content-Type: text/xml
Content-Length: 85
Date: Sun, 11 Oct 2026 10:51:31 GMT
Server: Panasonic
[18:51:33]    body   : b'<?xml version="1.0" encoding="UTF-8"?>\r\n<camrply><result>err_param</result></camrply>'
[18:51:33]    bodylen: 85
[18:51:33] 
[18:51:33] == GET / ==
[18:51:33]    status : HTTP/1.1 403 Forbidden
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:31 GMT
Server: Panasonic
[18:51:33]    hdr    : HTTP/1.1 403 Forbidden
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:31 GMT
Server: Panasonic
[18:51:33]    body   : b'<?xml version="1.0" encoding="iso-8859-1"?>\n<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitiona'
[18:51:33]    bodylen: 345
[18:51:33] 
[18:51:33] == GET /index.html ==
[18:51:33]    status : HTTP/1.1 404 Not Found
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:31 GMT
Server: Panasonic
[18:51:33]    hdr    : HTTP/1.1 404 Not Found
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:31 GMT
Server: Panasonic
[18:51:33]    body   : b'<?xml version="1.0" encoding="iso-8859-1"?>\n<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitiona'
[18:51:33]    bodylen: 345
[18:51:34] 
[18:51:34] == GET /index.htm ==
[18:51:34]    status : HTTP/1.1 404 Not Found
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:32 GMT
Server: Panasonic
[18:51:34]    hdr    : HTTP/1.1 404 Not Found
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:32 GMT
Server: Panasonic
[18:51:34]    body   : b'<?xml version="1.0" encoding="iso-8859-1"?>\n<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitiona'
[18:51:34]    bodylen: 345
[18:51:34] 
[18:51:34] == GET /default.htm ==
[18:51:34]    status : HTTP/1.1 404 Not Found
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:32 GMT
Server: Panasonic
[18:51:34]    hdr    : HTTP/1.1 404 Not Found
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:32 GMT
Server: Panasonic
[18:51:34]    body   : b'<?xml version="1.0" encoding="iso-8859-1"?>\n<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitiona'
[18:51:34]    bodylen: 345
[18:51:34] 
[18:51:34] == GET /cgi-bin/ ==
[18:51:34]    status : HTTP/1.1 404 Not Found
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:32 GMT
Server: Panasonic
[18:51:34]    hdr    : HTTP/1.1 404 Not Found
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:32 GMT
Server: Panasonic
[18:51:34]    body   : b'<?xml version="1.0" encoding="iso-8859-1"?>\n<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitiona'
[18:51:34]    bodylen: 345
[18:51:35] 
[18:51:35] == GET /cgi-bin/cam.cgi ==
[18:51:35]    status : HTTP/1.1 404 Not Found
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:33 GMT
Server: Panasonic
[18:51:35]    hdr    : HTTP/1.1 404 Not Found
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:33 GMT
Server: Panasonic
[18:51:35]    body   : b'<?xml version="1.0" encoding="iso-8859-1"?>\n<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitiona'
[18:51:35]    bodylen: 345
[18:51:35] 
[18:51:35] == GET /www/ ==
[18:51:35]    status : HTTP/1.1 404 Not Found
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:33 GMT
Server: Panasonic
[18:51:35]    hdr    : HTTP/1.1 404 Not Found
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:33 GMT
Server: Panasonic
[18:51:35]    body   : b'<?xml version="1.0" encoding="iso-8859-1"?>\n<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitiona'
[18:51:35]    bodylen: 345
[18:51:35] 
[18:51:35] == GET /web/ ==
[18:51:35]    status : HTTP/1.1 404 Not Found
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:33 GMT
Server: Panasonic
[18:51:35]    hdr    : HTTP/1.1 404 Not Found
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:33 GMT
Server: Panasonic
[18:51:35]    body   : b'<?xml version="1.0" encoding="iso-8859-1"?>\n<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitiona'
[18:51:35]    bodylen: 345
[18:51:36] 
[18:51:36] == GET / ==
[18:51:36]    status : HTTP/1.1 403 Forbidden
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:34 GMT
Server: Panasonic
[18:51:36]    hdr    : HTTP/1.1 403 Forbidden
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:34 GMT
Server: Panasonic
[18:51:36]    body   : b'<?xml version="1.0" encoding="iso-8859-1"?>\n<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitiona'
[18:51:36]    bodylen: 345
[18:51:36] 
[18:51:36] == GET /robots.txt ==
[18:51:36]    status : HTTP/1.1 404 Not Found
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:34 GMT
Server: Panasonic
[18:51:36]    hdr    : HTTP/1.1 404 Not Found
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:34 GMT
Server: Panasonic
[18:51:36]    body   : b'<?xml version="1.0" encoding="iso-8859-1"?>\n<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitiona'
[18:51:36]    bodylen: 345
[18:51:36] 
[18:51:36] == GET /favicon.ico ==
[18:51:36]    status : HTTP/1.1 404 Not Found
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:34 GMT
Server: Panasonic
[18:51:36]    hdr    : HTTP/1.1 404 Not Found
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:34 GMT
Server: Panasonic
[18:51:36]    body   : b'<?xml version="1.0" encoding="iso-8859-1"?>\n<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitiona'
[18:51:36]    bodylen: 345
[18:51:37] 
[18:51:37] == GET /cam.cgi?mode=getstate&x=1 ==
[18:51:37]    status : HTTP/1.1 200 OK
Content-Type: text/xml
Content-Length: 622
Date: Sun, 11 Oct 2026 10:51:35 GMT
Server: Panasonic
[18:51:37]    hdr    : HTTP/1.1 200 OK
Content-Type: text/xml
Content-Length: 622
Date: Sun, 11 Oct 2026 10:51:35 GMT
Server: Panasonic
[18:51:37]    body   : b'<?xml version="1.0" encoding="UTF-8"?>\r\n<camrply><result>ok</result><state><batt>5/5</batt><batt_per'
[18:51:37]    bodylen: 622
[18:51:37] 
[18:51:37] == GET /?mode=getstate ==
[18:51:37]    status : HTTP/1.1 403 Forbidden
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:35 GMT
Server: Panasonic
[18:51:37]    hdr    : HTTP/1.1 403 Forbidden
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:35 GMT
Server: Panasonic
[18:51:37]    body   : b'<?xml version="1.0" encoding="iso-8859-1"?>\n<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitiona'
[18:51:37]    bodylen: 345
[18:51:37] 
[18:51:37] == GET /cam.cgi/?mode=getstate ==
[18:51:37]    status : HTTP/1.1 200 OK
Content-Type: text/xml
Content-Length: 622
Date: Sun, 11 Oct 2026 10:51:36 GMT
Server: Panasonic
[18:51:37]    hdr    : HTTP/1.1 200 OK
Content-Type: text/xml
Content-Length: 622
Date: Sun, 11 Oct 2026 10:51:36 GMT
Server: Panasonic
[18:51:37]    body   : b'<?xml version="1.0" encoding="UTF-8"?>\r\n<camrply><result>ok</result><state><batt>5/5</batt><batt_per'
[18:51:37]    bodylen: 622
[18:51:38] 
[18:51:38] == GET /%63am.cgi?mode=getstate ==
[18:51:38]    status : HTTP/1.1 200 OK
Content-Type: text/xml
Content-Length: 622
Date: Sun, 11 Oct 2026 10:51:36 GMT
Server: Panasonic
[18:51:38]    hdr    : HTTP/1.1 200 OK
Content-Type: text/xml
Content-Length: 622
Date: Sun, 11 Oct 2026 10:51:36 GMT
Server: Panasonic
[18:51:38]    body   : b'<?xml version="1.0" encoding="UTF-8"?>\r\n<camrply><result>ok</result><state><batt>5/5</batt><batt_per'
[18:51:38]    bodylen: 622
[18:51:38] 
[18:51:38] == GET /Cam.CGI?mode=getstate ==
[18:51:38]    status : HTTP/1.1 404 Not Found
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:36 GMT
Server: Panasonic
[18:51:38]    hdr    : HTTP/1.1 404 Not Found
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:36 GMT
Server: Panasonic
[18:51:38]    body   : b'<?xml version="1.0" encoding="iso-8859-1"?>\n<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitiona'
[18:51:38]    bodylen: 345
[18:51:39] 
[18:51:39] == GET /cam.cgi%20?mode=getstate ==
[18:51:39]    status : HTTP/1.1 200 OK
Content-Type: text/xml
Content-Length: 622
Date: Sun, 11 Oct 2026 10:51:37 GMT
Server: Panasonic
[18:51:39]    hdr    : HTTP/1.1 200 OK
Content-Type: text/xml
Content-Length: 622
Date: Sun, 11 Oct 2026 10:51:37 GMT
Server: Panasonic
[18:51:39]    body   : b'<?xml version="1.0" encoding="UTF-8"?>\r\n<camrply><result>ok</result><state><batt>5/5</batt><batt_per'
[18:51:39]    bodylen: 622
[18:51:39] 
[18:51:39] == GET //cam.cgi?mode=getstate ==
[18:51:39]    status : HTTP/1.1 200 OK
Content-Type: text/xml
Content-Length: 622
Date: Sun, 11 Oct 2026 10:51:37 GMT
Server: Panasonic
[18:51:39]    hdr    : HTTP/1.1 200 OK
Content-Type: text/xml
Content-Length: 622
Date: Sun, 11 Oct 2026 10:51:37 GMT
Server: Panasonic
[18:51:39]    body   : b'<?xml version="1.0" encoding="UTF-8"?>\r\n<camrply><result>ok</result><state><batt>5/5</batt><batt_per'
[18:51:39]    bodylen: 622
[18:51:39] 
########## C. HTTP version handling ##########
[18:51:39] 
[18:51:39] == HTTP/1.0 request ==
[18:51:39]    status : HTTP/1.0 200 OK
Content-Type: text/xml
Content-Length: 622
Connection: close
Date: Sun, 11 Oct 2026 10:51:37 GMT
Server: Panasonic
[18:51:39]    hdr    : HTTP/1.0 200 OK
Content-Type: text/xml
Content-Length: 622
Connection: close
Date: Sun, 11 Oct 2026 10:51:37 GMT
Server: Panasonic
[18:51:39]    body   : b'<?xml version="1.0" encoding="UTF-8"?>\r\n<camrply><result>ok</result><state><batt>5/5</batt><batt_per>-1</batt_per><cammo'
[18:51:39]    bodylen: 622
[18:51:39] 
[18:51:39] == raw HTTP/2.0 request line ==
[18:51:39]    status : open=True
[18:51:39]    body   : b'HTTP/1.0 505 HTTP Version Not Supported\r\nContent-Type: text/html\r\nContent-Length: 379\r\nConnection: close\r\nDate: Sun, 11 Oct 2026 10:51:37 GMT\r\nServer: Panasonic\r\n\r\n<?xml version="1.0" encoding="iso-8859-1"?>\n<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transit'
[18:51:39]    bodylen: 260
[18:51:40] 
[18:51:40] == raw no-version request line ==
[18:51:40]    status : open=True
[18:51:40]    body   : b'HTTP/1.0 400 Bad Request\r\nContent-Type: text/html\r\nContent-Length: 349\r\nConnection: close\r\nDate: Sun, 11 Oct 2026 10:51:38 GMT\r\nServer: Panasonic\r\n\r\n<?xml version="1.0" encoding="iso-8859-1"?>\n<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"\n    '
[18:51:40]    bodylen: 260
[18:51:40] 
[18:51:40] == raw 'GET<path>' (no space) ==
[18:51:40]    status : open=True
[18:51:40]    body   : b'HTTP/1.0 400 Bad Request\r\nContent-Type: text/html\r\nContent-Length: 349\r\nConnection: close\r\nDate: Sun, 11 Oct 2026 10:51:38 GMT\r\nServer: Panasonic\r\n\r\n<?xml version="1.0" encoding="iso-8859-1"?>\n<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"\n    '
[18:51:40]    bodylen: 260
[18:51:40] 
########## D. error pages / status codes ##########
[18:51:40] 
[18:51:40] == 404 page (GET /nonexistent-xyz) ==
[18:51:40]    status : HTTP/1.1 404 Not Found
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:38 GMT
Server: Panasonic
[18:51:40]    hdr    : HTTP/1.1 404 Not Found
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:38 GMT
Server: Panasonic
[18:51:40]    body   : b'<?xml version="1.0" encoding="iso-8859-1"?>\n<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"\n         "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">\n<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">\n <head>\n  <title>404 - Not Found</title>\n </head>\n <body>\n  <h1>404 - Not Found</h1>\n </body>\n</html>\n'
[18:51:40]    bodylen: 345
[18:51:40] 
[18:51:40] == raw invalid method BOGUS ==
[18:51:40]    status : open=True
[18:51:40]    body   : b'HTTP/1.0 501 Not Implemented\r\nContent-Type: text/html\r\nContent-Length: 357\r\nConnection: close\r\nDate: Sun, 11 Oct 2026 10:51:38 GMT\r\nServer: Panasonic\r\n\r\n<?xml version="1.0" encoding="iso-8859-1"?>\n<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"\n         "http://www.w3.org/TR/xhtml1/DT'
[18:51:40]    bodylen: 300
[18:51:40] 
[18:51:40] == raw empty request ==
[18:51:40]    status : open=True
[18:51:40]    body   : b'HTTP/1.0 400 Bad Request\r\nContent-Type: text/html\r\nContent-Length: 349\r\nConnection: close\r\nDate: Sun, 11 Oct 2026 10:51:38 GMT\r\nServer: Panasonic\r\n\r\n<?xml version="1.0" encoding="iso-8859-1"?>\n<!DOCTY'
[18:51:40]    bodylen: 200
[18:51:40] 
[18:51:40] == raw null byte in path ==
[18:51:40]    status : open=True
[18:51:40]    body   : b'HTTP/1.1 400 Bad Request\r\nContent-Type: text/html\r\nContent-Length: 349\r\nConnection: close\r\nDate: Sun, 11 Oct 2026 10:51:38 GMT\r\nServer: Panasonic\r\n\r\n<?xml version="1.0" encoding="iso-8859-1"?>\n<!DOCTY'
[18:51:40]    bodylen: 200
[18:51:40] 
########## E. path traversal ##########
[18:51:40] 
[18:51:40] == GET /cam.cgi/../  [INTERESTING] ==
[18:51:40]    status : HTTP/1.1 403 Forbidden
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:39 GMT
Server: Panasonic
[18:51:40]    hdr    : HTTP/1.1 403 Forbidden
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:39 GMT
Server: Panasonic
[18:51:40]    body   : b'<?xml version="1.0" encoding="iso-8859-1"?>\n<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"\n         "http://www.w3.org/TR/xhtml1/DTD/xhtml1-tran'
[18:51:40]    bodylen: 345
[18:51:41] 
[18:51:41] == GET /cam.cgi/../../etc/passwd  [INTERESTING] ==
[18:51:41]    status : HTTP/1.1 404 Not Found
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:39 GMT
Server: Panasonic
[18:51:41]    hdr    : HTTP/1.1 404 Not Found
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:39 GMT
Server: Panasonic
[18:51:41]    body   : b'<?xml version="1.0" encoding="iso-8859-1"?>\n<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"\n         "http://www.w3.org/TR/xhtml1/DTD/xhtml1-tran'
[18:51:41]    bodylen: 345
[18:51:41] 
[18:51:41] == GET /cam.cgi/..%2f..%2fetc%2fpasswd  [INTERESTING] ==
[18:51:41]    status : HTTP/1.1 404 Not Found
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:39 GMT
Server: Panasonic
[18:51:41]    hdr    : HTTP/1.1 404 Not Found
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:39 GMT
Server: Panasonic
[18:51:41]    body   : b'<?xml version="1.0" encoding="iso-8859-1"?>\n<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"\n         "http://www.w3.org/TR/xhtml1/DTD/xhtml1-tran'
[18:51:41]    bodylen: 345
[18:51:41] 
[18:51:41] == GET /..%2f..%2fetc%2fpasswd  [INTERESTING] ==
[18:51:41]    status : HTTP/1.1 404 Not Found
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:39 GMT
Server: Panasonic
[18:51:41]    hdr    : HTTP/1.1 404 Not Found
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:39 GMT
Server: Panasonic
[18:51:41]    body   : b'<?xml version="1.0" encoding="iso-8859-1"?>\n<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"\n         "http://www.w3.org/TR/xhtml1/DTD/xhtml1-tran'
[18:51:41]    bodylen: 345
[18:51:42] 
[18:51:42] == GET /%2e%2e/%2e%2e/etc/passwd  [INTERESTING] ==
[18:51:42]    status : HTTP/1.1 404 Not Found
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:40 GMT
Server: Panasonic
[18:51:42]    hdr    : HTTP/1.1 404 Not Found
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:40 GMT
Server: Panasonic
[18:51:42]    body   : b'<?xml version="1.0" encoding="iso-8859-1"?>\n<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"\n         "http://www.w3.org/TR/xhtml1/DTD/xhtml1-tran'
[18:51:42]    bodylen: 345
[18:51:42] 
[18:51:42] == GET /..%252f..%252fetc%252fpasswd  [INTERESTING] ==
[18:51:42]    status : HTTP/1.1 404 Not Found
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:40 GMT
Server: Panasonic
[18:51:42]    hdr    : HTTP/1.1 404 Not Found
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:40 GMT
Server: Panasonic
[18:51:42]    body   : b'<?xml version="1.0" encoding="iso-8859-1"?>\n<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"\n         "http://www.w3.org/TR/xhtml1/DTD/xhtml1-tran'
[18:51:42]    bodylen: 345
[18:51:42] 
[18:51:42] == GET /cam.cgi%00 ==
[18:51:42]    status : HTTP/1.1 200 OK
Content-Type: text/xml
Content-Length: 85
Date: Sun, 11 Oct 2026 10:51:41 GMT
Server: Panasonic
[18:51:42]    hdr    : HTTP/1.1 200 OK
Content-Type: text/xml
Content-Length: 85
Date: Sun, 11 Oct 2026 10:51:41 GMT
Server: Panasonic
[18:51:42]    body   : b'<?xml version="1.0" encoding="UTF-8"?>\r\n<camrply><result>err_param</result></camrply>'
[18:51:42]    bodylen: 85
[18:51:43] 
[18:51:43] == GET /cam.cgi%00?mode=getstate ==
[18:51:43]    status : HTTP/1.1 200 OK
Content-Type: text/xml
Content-Length: 622
Date: Sun, 11 Oct 2026 10:51:41 GMT
Server: Panasonic
[18:51:43]    hdr    : HTTP/1.1 200 OK
Content-Type: text/xml
Content-Length: 622
Date: Sun, 11 Oct 2026 10:51:41 GMT
Server: Panasonic
[18:51:43]    body   : b'<?xml version="1.0" encoding="UTF-8"?>\r\n<camrply><result>ok</result><state><batt>5/5</batt><batt_per>-1</batt_per><cammode>play</cammode><sdcardstatus>write_ena'
[18:51:43]    bodylen: 622
[18:51:43] 
[18:51:43] == GET //etc/passwd  [INTERESTING] ==
[18:51:43]    status : HTTP/1.1 404 Not Found
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:41 GMT
Server: Panasonic
[18:51:43]    hdr    : HTTP/1.1 404 Not Found
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:41 GMT
Server: Panasonic
[18:51:43]    body   : b'<?xml version="1.0" encoding="iso-8859-1"?>\n<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"\n         "http://www.w3.org/TR/xhtml1/DTD/xhtml1-tran'
[18:51:43]    bodylen: 345
[18:51:44] 
[18:51:44] == GET /etc/passwd  [INTERESTING] ==
[18:51:44]    status : HTTP/1.1 404 Not Found
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:41 GMT
Server: Panasonic
[18:51:44]    hdr    : HTTP/1.1 404 Not Found
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:41 GMT
Server: Panasonic
[18:51:44]    body   : b'<?xml version="1.0" encoding="iso-8859-1"?>\n<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"\n         "http://www.w3.org/TR/xhtml1/DTD/xhtml1-tran'
[18:51:44]    bodylen: 345
[18:51:44] 
[18:51:44] == GET /etc/  [INTERESTING] ==
[18:51:44]    status : HTTP/1.1 404 Not Found
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:42 GMT
Server: Panasonic
[18:51:44]    hdr    : HTTP/1.1 404 Not Found
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:42 GMT
Server: Panasonic
[18:51:44]    body   : b'<?xml version="1.0" encoding="iso-8859-1"?>\n<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"\n         "http://www.w3.org/TR/xhtml1/DTD/xhtml1-tran'
[18:51:44]    bodylen: 345
[18:51:44] 
[18:51:44] == GET /var/  [INTERESTING] ==
[18:51:44]    status : HTTP/1.1 404 Not Found
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:42 GMT
Server: Panasonic
[18:51:44]    hdr    : HTTP/1.1 404 Not Found
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:42 GMT
Server: Panasonic
[18:51:44]    body   : b'<?xml version="1.0" encoding="iso-8859-1"?>\n<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"\n         "http://www.w3.org/TR/xhtml1/DTD/xhtml1-tran'
[18:51:44]    bodylen: 345
[18:51:45] 
[18:51:45] == GET /tmp/  [INTERESTING] ==
[18:51:45]    status : HTTP/1.1 404 Not Found
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:43 GMT
Server: Panasonic
[18:51:45]    hdr    : HTTP/1.1 404 Not Found
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:43 GMT
Server: Panasonic
[18:51:45]    body   : b'<?xml version="1.0" encoding="iso-8859-1"?>\n<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"\n         "http://www.w3.org/TR/xhtml1/DTD/xhtml1-tran'
[18:51:45]    bodylen: 345
[18:51:45] 
[18:51:45] == GET /root/  [INTERESTING] ==
[18:51:45]    status : HTTP/1.1 404 Not Found
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:43 GMT
Server: Panasonic
[18:51:45]    hdr    : HTTP/1.1 404 Not Found
Content-Type: text/html
Content-Length: 345
Date: Sun, 11 Oct 2026 10:51:43 GMT
Server: Panasonic
[18:51:45]    body   : b'<?xml version="1.0" encoding="iso-8859-1"?>\n<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"\n         "http://www.w3.org/TR/xhtml1/DTD/xhtml1-tran'
[18:51:45]    bodylen: 345
[18:51:45] 
[18:51:45] == GET /cam.cgi?mode=getstate&value=../../etc/passwd ==
[18:51:45]    status : HTTP/1.1 200 OK
Content-Type: text/xml
Content-Length: 622
Date: Sun, 11 Oct 2026 10:51:44 GMT
Server: Panasonic
[18:51:45]    hdr    : HTTP/1.1 200 OK
Content-Type: text/xml
Content-Length: 622
Date: Sun, 11 Oct 2026 10:51:44 GMT
Server: Panasonic
[18:51:45]    body   : b'<?xml version="1.0" encoding="UTF-8"?>\r\n<camrply><result>ok</result><state><batt>5/5</batt><batt_per>-1</batt_per><cammode>play</cammode><sdcardstatus>write_ena'
[18:51:45]    bodylen: 622
[18:51:46] 
########## FINGERPRINT COMPLETE ##########
[18:51:46] final health: ok
