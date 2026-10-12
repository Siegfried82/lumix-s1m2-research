package com.panasonic.jp.flow.wireless.udp;

/* JADX INFO: loaded from: classes4.dex */
public class RemoteUDPPacketManager {
    java.lang.String Av_current_1;
    java.lang.String Av_current_2;
    java.lang.String Av_max_1;
    java.lang.String Av_max_2;
    java.lang.String Av_min_1;
    java.lang.String Av_min_2;
    java.lang.String Shut_state;
    java.lang.String Sv_current_1;
    java.lang.String Sv_current_2;
    java.lang.String Sv_max_1;
    java.lang.String Sv_max_2;
    java.lang.String Sv_min_1;
    java.lang.String Sv_min_2;
    private final java.lang.String TAG;
    java.lang.String Tv_current_1;
    java.lang.String Tv_current_2;
    java.lang.String Tv_max_1;
    java.lang.String Tv_max_2;
    java.lang.String Tv_min_1;
    java.lang.String Tv_min_2;
    java.lang.String assist_ID;
    byte[] bitmapData;
    java.lang.String buff_size;
    java.lang.String camstatus;
    java.lang.String crntEXzoom;
    java.lang.String crntfocaldist;
    java.lang.String crntzoompos;
    java.lang.String crntzoomval;
    java.lang.String currentexposure;
    java.lang.String dataflag;
    java.lang.String dataoffset;
    java.lang.String datatype;
    java.lang.String digitalzoommaxpos;
    java.lang.String exflag;
    java.lang.String exflag2;
    java.lang.String exflag3;
    java.lang.String exflag3_vh;
    java.lang.String exheadersize;
    java.lang.String exheadertype;
    java.lang.String exzoommaxpos;
    java.util.List<com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.FocusFrame> focusFrameList;
    java.lang.String iazoommaxpos;
    java.util.List<com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.IconCont> iconContList;
    java.lang.String interval_state;
    java.lang.String lens_mount;
    java.lang.String noise_reduction_time;
    java.lang.String numIconCont;
    java.lang.String numSettingValue;
    java.lang.String numfocusframe;
    java.lang.String opticalzoommaxpos;
    java.lang.String processingstate;
    java.lang.String pts;
    java.lang.String recmode;
    java.lang.String reserve0C;
    java.lang.String reserve1;
    java.lang.String rotate;
    java.lang.String seqno;
    java.util.List<com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.SettingValue> settingValueList;
    java.lang.String srcid;
    java.lang.String srcsubid;
    java.lang.String totaldatasize;
    java.lang.String totalsize;
    java.lang.String touch_AE_button;
    java.lang.String touchaf_button;
    java.lang.String version;
    java.lang.String zoommaxchgcount;

    public static class BASE_DATA {
        protected static final java.util.Map<java.lang.String, java.lang.Integer> FILED_MAP = null;
        protected static final java.util.Map<java.lang.String, java.lang.Integer> focusframe_MAP = null;
        protected static final java.util.Map<java.lang.String, java.lang.Integer> iconCont_MAP = null;
        protected static final java.util.Map<java.lang.String, java.lang.Integer> settingValue_MAP = null;

        static {
                java.util.LinkedHashMap r0 = new java.util.LinkedHashMap
                r0.<init>()
                com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP = r0
                java.util.LinkedHashMap r0 = new java.util.LinkedHashMap
                r0.<init>()
                com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.focusframe_MAP = r0
                java.util.LinkedHashMap r0 = new java.util.LinkedHashMap
                r0.<init>()
                com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.iconCont_MAP = r0
                java.util.LinkedHashMap r0 = new java.util.LinkedHashMap
                r0.<init>()
                com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.settingValue_MAP = r0
                return
        }

        public BASE_DATA() {
                r0 = this;
                r0.<init>()
                return
        }

        public static void initFILEDMAP() {
                java.util.Map<java.lang.String, java.lang.Integer> r0 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP
                r1 = 2
                java.lang.Integer r1 = java.lang.Integer.valueOf(r1)
                java.lang.String r2 = "totalsize"
                r0.put(r2, r1)
                java.lang.String r2 = "version"
                r0.put(r2, r1)
                r2 = 4
                java.lang.Integer r2 = java.lang.Integer.valueOf(r2)
                java.lang.String r3 = "seqno"
                r0.put(r3, r2)
                r3 = 1
                java.lang.Integer r3 = java.lang.Integer.valueOf(r3)
                java.lang.String r4 = "dataflag"
                r0.put(r4, r3)
                r4 = 6
                java.lang.Integer r4 = java.lang.Integer.valueOf(r4)
                java.lang.String r5 = "srcid"
                r0.put(r5, r4)
                java.lang.String r4 = "srcsubid"
                r0.put(r4, r3)
                java.lang.String r4 = "datatype"
                r0.put(r4, r3)
                java.lang.String r4 = "reserve1"
                r0.put(r4, r3)
                java.lang.String r4 = "pts"
                r0.put(r4, r2)
                java.lang.String r4 = "totaldatasize"
                r0.put(r4, r2)
                java.lang.String r4 = "dataoffset"
                r0.put(r4, r2)
                java.lang.String r2 = "exheadersize"
                r0.put(r2, r1)
                java.lang.String r2 = "exheadertype"
                r0.put(r2, r1)
                java.lang.String r2 = "crntzoomval"
                r0.put(r2, r1)
                java.lang.String r2 = "crntzoompos"
                r0.put(r2, r3)
                java.lang.String r2 = "zoommaxchgcount"
                r0.put(r2, r3)
                java.lang.String r2 = "opticalzoommaxpos"
                r0.put(r2, r3)
                java.lang.String r2 = "exzoommaxpos"
                r0.put(r2, r3)
                java.lang.String r2 = "iazoommaxpos"
                r0.put(r2, r3)
                java.lang.String r2 = "digitalzoommaxpos"
                r0.put(r2, r3)
                java.lang.String r2 = "rotate"
                r0.put(r2, r3)
                java.lang.String r2 = "camstatus"
                r0.put(r2, r3)
                java.lang.String r2 = "recmode"
                r0.put(r2, r3)
                java.lang.String r2 = "exflag"
                r0.put(r2, r3)
                java.lang.String r2 = "exflag2"
                r0.put(r2, r3)
                java.lang.String r2 = "numfocusframe"
                r0.put(r2, r3)
                java.lang.String r2 = "Av_max_1"
                r0.put(r2, r1)
                java.lang.String r2 = "Av_max_2"
                r0.put(r2, r1)
                java.lang.String r2 = "Av_min_1"
                r0.put(r2, r1)
                java.lang.String r2 = "Av_min_2"
                r0.put(r2, r1)
                java.lang.String r2 = "Av_current_1"
                r0.put(r2, r1)
                java.lang.String r2 = "Av_current_2"
                r0.put(r2, r1)
                java.lang.String r2 = "Tv_max_1"
                r0.put(r2, r1)
                java.lang.String r2 = "Tv_max_2"
                r0.put(r2, r1)
                java.lang.String r2 = "Tv_min_1"
                r0.put(r2, r1)
                java.lang.String r2 = "Tv_min_2"
                r0.put(r2, r1)
                java.lang.String r2 = "Tv_current_1"
                r0.put(r2, r1)
                java.lang.String r2 = "Tv_current_2"
                r0.put(r2, r1)
                java.lang.String r2 = "Sv_max_1"
                r0.put(r2, r1)
                java.lang.String r2 = "Sv_max_2"
                r0.put(r2, r1)
                java.lang.String r2 = "Sv_min_1"
                r0.put(r2, r1)
                java.lang.String r2 = "Sv_min_2"
                r0.put(r2, r1)
                java.lang.String r2 = "Sv_current_1"
                r0.put(r2, r1)
                java.lang.String r2 = "Sv_current_2"
                r0.put(r2, r1)
                java.lang.String r2 = "currentexposure"
                r0.put(r2, r3)
                java.lang.String r2 = "crntfocaldist"
                r0.put(r2, r1)
                java.lang.String r2 = "crntEXzoom"
                r0.put(r2, r1)
                java.lang.String r2 = "numIconCont"
                r0.put(r2, r3)
                java.lang.String r2 = "processingstate"
                r0.put(r2, r3)
                java.lang.String r2 = "assist_ID"
                r0.put(r2, r1)
                java.lang.String r2 = "touch_AE_button"
                r0.put(r2, r3)
                java.lang.String r2 = "Shut_state"
                r0.put(r2, r3)
                java.lang.String r2 = "noise_reduction_time"
                r0.put(r2, r1)
                java.lang.String r2 = "exflag3_vh"
                r0.put(r2, r3)
                java.lang.String r2 = "exflag3"
                r0.put(r2, r3)
                java.lang.String r2 = "buff_size"
                r0.put(r2, r1)
                java.lang.String r1 = "touchaf_button"
                r0.put(r1, r3)
                java.lang.String r1 = "interval_state"
                r0.put(r1, r3)
                java.lang.String r1 = "lens_mount"
                r0.put(r1, r3)
                r1 = 14
                java.lang.Integer r1 = java.lang.Integer.valueOf(r1)
                java.lang.String r2 = "reserve0C"
                r0.put(r2, r1)
                java.lang.String r1 = "numSettingValue"
                r0.put(r1, r3)
                return
        }

        public static void initFocusframeMAP() {
                java.util.Map<java.lang.String, java.lang.Integer> r0 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.focusframe_MAP
                r1 = 2
                java.lang.Integer r1 = java.lang.Integer.valueOf(r1)
                java.lang.String r2 = "focusframeleft"
                r0.put(r2, r1)
                java.lang.String r2 = "focusframetop"
                r0.put(r2, r1)
                java.lang.String r2 = "focusframeright"
                r0.put(r2, r1)
                java.lang.String r2 = "focusframebottom"
                r0.put(r2, r1)
                r1 = 1
                java.lang.Integer r1 = java.lang.Integer.valueOf(r1)
                java.lang.String r2 = "focusframecolor_r"
                r0.put(r2, r1)
                java.lang.String r2 = "focusframecolor_g"
                r0.put(r2, r1)
                java.lang.String r2 = "focusframecolor_b"
                r0.put(r2, r1)
                java.lang.String r2 = "focusframeshape"
                r0.put(r2, r1)
                java.lang.String r2 = "focustriangledisp"
                r0.put(r2, r1)
                java.lang.String r2 = "focal_length"
                r0.put(r2, r1)
                java.lang.String r2 = "focasframe_transparency"
                r0.put(r2, r1)
                java.lang.String r2 = "focus_reserve"
                r0.put(r2, r1)
                return
        }

        public static void initIconContMAP() {
                java.util.Map<java.lang.String, java.lang.Integer> r0 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.iconCont_MAP
                r1 = 1
                java.lang.Integer r1 = java.lang.Integer.valueOf(r1)
                java.lang.String r2 = "sdIcon1"
                r0.put(r2, r1)
                java.lang.String r2 = "sdIcon2"
                r0.put(r2, r1)
                java.lang.String r2 = "sdIcon"
                r0.put(r2, r1)
                r2 = 4
                java.lang.Integer r2 = java.lang.Integer.valueOf(r2)
                java.lang.String r3 = "shootNum"
                r0.put(r3, r2)
                java.lang.String r3 = "shootTime"
                r0.put(r3, r2)
                java.lang.String r2 = "battery"
                r0.put(r2, r1)
                java.lang.String r2 = "batteryBase"
                r0.put(r2, r1)
                java.lang.String r2 = "batteryBackgroud"
                r0.put(r2, r1)
                java.lang.String r2 = "shootingIcon"
                r0.put(r2, r1)
                return
        }

        public static void initSettingValueMAP() {
                java.util.Map<java.lang.String, java.lang.Integer> r0 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.settingValue_MAP
                r1 = 2
                java.lang.Integer r1 = java.lang.Integer.valueOf(r1)
                java.lang.String r2 = "exposure"
                r0.put(r2, r1)
                java.lang.String r2 = "ss_angle"
                r0.put(r2, r1)
                r2 = 4
                java.lang.Integer r2 = java.lang.Integer.valueOf(r2)
                java.lang.String r3 = "iso"
                r0.put(r3, r2)
                java.lang.String r2 = "db"
                r0.put(r2, r1)
                java.lang.String r2 = "whitebalance"
                r0.put(r2, r1)
                java.lang.String r2 = "recmode1"
                r0.put(r2, r1)
                java.lang.String r2 = "recmode2"
                r0.put(r2, r1)
                java.lang.String r2 = "recmode2value2"
                r0.put(r2, r1)
                java.lang.String r2 = "photostyle"
                r0.put(r2, r1)
                java.lang.String r2 = "focusmode"
                r0.put(r2, r1)
                java.lang.String r2 = "quality"
                r0.put(r2, r1)
                java.lang.String r2 = "videoformat"
                r0.put(r2, r1)
                java.lang.String r2 = "videoquality"
                r0.put(r2, r1)
                java.lang.String r2 = "aspectratio"
                r0.put(r2, r1)
                java.lang.String r2 = "drivemode"
                r0.put(r2, r1)
                java.lang.String r2 = "selftimer"
                r0.put(r2, r1)
                java.lang.String r2 = "lightmetering"
                r0.put(r2, r1)
                r2 = 1
                java.lang.Integer r2 = java.lang.Integer.valueOf(r2)
                java.lang.String r3 = "liveviewsize"
                r0.put(r3, r2)
                java.lang.String r3 = "realtimelut"
                r0.put(r3, r2)
                java.lang.String r3 = "operatepriority"
                r0.put(r3, r2)
                java.lang.String r3 = "selftimercustom"
                r0.put(r3, r2)
                java.lang.String r2 = "afmode"
                r0.put(r2, r1)
                java.lang.String r2 = "burst1speed"
                r0.put(r2, r1)
                java.lang.String r2 = "burst2speed"
                r0.put(r2, r1)
                java.lang.String r2 = "intervalMotionState"
                r0.put(r2, r1)
                java.lang.String r2 = "sqFPS"
                r0.put(r2, r1)
                java.lang.String r2 = "dualNativeIso"
                r0.put(r2, r1)
                java.lang.String r2 = "hrsMode"
                r0.put(r2, r1)
                return
        }
    }

    public static class FocusFrame {
        java.lang.String focal_length;
        java.lang.String focasframe_transparency;
        java.lang.String focus_reserve;
        java.lang.String focusframebottom;
        java.lang.String focusframecolor_b;
        java.lang.String focusframecolor_g;
        java.lang.String focusframecolor_r;
        java.lang.String focusframeleft;
        java.lang.String focusframeright;
        java.lang.String focusframeshape;
        java.lang.String focusframetop;
        java.lang.String focustriangledisp;

        public FocusFrame() {
                r0 = this;
                r0.<init>()
                return
        }

        public java.lang.String getFocal_length() {
                r0 = this;
                java.lang.String r0 = r0.focal_length
                return r0
        }

        public java.lang.String getFocasframe_transparency() {
                r0 = this;
                java.lang.String r0 = r0.focasframe_transparency
                return r0
        }

        public java.lang.String getFocus_reserve() {
                r0 = this;
                java.lang.String r0 = r0.focus_reserve
                return r0
        }

        public java.lang.String getFocusframebottom() {
                r0 = this;
                java.lang.String r0 = r0.focusframebottom
                return r0
        }

        public java.lang.String getFocusframecolor_b() {
                r0 = this;
                java.lang.String r0 = r0.focusframecolor_b
                return r0
        }

        public java.lang.String getFocusframecolor_g() {
                r0 = this;
                java.lang.String r0 = r0.focusframecolor_g
                return r0
        }

        public java.lang.String getFocusframecolor_r() {
                r0 = this;
                java.lang.String r0 = r0.focusframecolor_r
                return r0
        }

        public java.lang.String getFocusframeleft() {
                r0 = this;
                java.lang.String r0 = r0.focusframeleft
                return r0
        }

        public java.lang.String getFocusframeright() {
                r0 = this;
                java.lang.String r0 = r0.focusframeright
                return r0
        }

        public java.lang.String getFocusframeshape() {
                r0 = this;
                java.lang.String r0 = r0.focusframeshape
                return r0
        }

        public java.lang.String getFocusframetop() {
                r0 = this;
                java.lang.String r0 = r0.focusframetop
                return r0
        }

        public java.lang.String getFocustriangledisp() {
                r0 = this;
                java.lang.String r0 = r0.focustriangledisp
                return r0
        }

        public void setFocusframeshape(java.lang.String r1) {
                r0 = this;
                r0.focusframeshape = r1
                return
        }
    }

    public static class IconCont {
        java.lang.String battery;
        java.lang.String batteryBackgroud;
        java.lang.String batteryBase;
        java.lang.String sdIcon;
        java.lang.String sdIcon1;
        java.lang.String sdIcon2;
        java.lang.String shootNum;
        java.lang.String shootTime;
        java.lang.String shootingIcon;

        public IconCont() {
                r0 = this;
                r0.<init>()
                return
        }

        public java.lang.String getBattery() {
                r0 = this;
                java.lang.String r0 = r0.battery
                return r0
        }

        public java.lang.String getBatteryBackgroud() {
                r0 = this;
                java.lang.String r0 = r0.batteryBackgroud
                return r0
        }

        public java.lang.String getBatteryBase() {
                r0 = this;
                java.lang.String r0 = r0.batteryBase
                return r0
        }

        public java.lang.String getSdIcon() {
                r0 = this;
                java.lang.String r0 = r0.sdIcon
                return r0
        }

        public java.lang.String getSdIcon1() {
                r0 = this;
                java.lang.String r0 = r0.sdIcon1
                return r0
        }

        public java.lang.String getSdIcon2() {
                r0 = this;
                java.lang.String r0 = r0.sdIcon2
                return r0
        }

        public java.lang.String getShootNum() {
                r0 = this;
                java.lang.String r0 = r0.shootNum
                return r0
        }

        public java.lang.String getShootTime() {
                r0 = this;
                java.lang.String r0 = r0.shootTime
                return r0
        }

        public java.lang.String getShootingIcon() {
                r0 = this;
                java.lang.String r0 = r0.shootingIcon
                return r0
        }
    }

    public static class SettingValue {
        java.lang.String afmode;
        java.lang.String aspectratio;
        java.lang.String burst1speed;
        java.lang.String burst2speed;
        java.lang.String db;
        java.lang.String drivemode;
        java.lang.String dualNativeIso;
        java.lang.String exposure;
        java.lang.String focusmode;
        java.lang.String hrsMode;
        java.lang.String intervalMotionState;
        java.lang.String iso;
        java.lang.String lightmetering;
        java.lang.String liveviewsize;
        java.lang.String operatepriority;
        java.lang.String photostyle;
        java.lang.String quality;
        java.lang.String realtimelut;
        java.lang.String recmode1;
        java.lang.String recmode2;
        java.lang.String recmode2value2;
        java.lang.String selftimer;
        java.lang.String selftimercustom;
        java.lang.String sqFPS;
        java.lang.String ssAngle;
        java.lang.String videoformat;
        java.lang.String videoquality;
        java.lang.String whitebalance;

        public SettingValue() {
                r0 = this;
                r0.<init>()
                return
        }

        public java.lang.String getAfmode() {
                r0 = this;
                java.lang.String r0 = r0.afmode
                return r0
        }

        public java.lang.String getAspectratio() {
                r0 = this;
                java.lang.String r0 = r0.aspectratio
                return r0
        }

        public java.lang.String getBurst1speed() {
                r0 = this;
                java.lang.String r0 = r0.burst1speed
                return r0
        }

        public java.lang.String getBurst2speed() {
                r0 = this;
                java.lang.String r0 = r0.burst2speed
                return r0
        }

        public java.lang.String getDb() {
                r0 = this;
                java.lang.String r0 = r0.db
                return r0
        }

        public java.lang.String getDrivemode() {
                r0 = this;
                java.lang.String r0 = r0.drivemode
                return r0
        }

        public java.lang.String getDualNativeIso() {
                r0 = this;
                java.lang.String r0 = r0.dualNativeIso
                return r0
        }

        public java.lang.String getExposure() {
                r0 = this;
                java.lang.String r0 = r0.exposure
                return r0
        }

        public java.lang.String getFocusmode() {
                r0 = this;
                java.lang.String r0 = r0.focusmode
                return r0
        }

        public java.lang.String getHrsMode() {
                r0 = this;
                java.lang.String r0 = r0.hrsMode
                return r0
        }

        public java.lang.String getIntervalMotionState() {
                r0 = this;
                java.lang.String r0 = r0.intervalMotionState
                return r0
        }

        public java.lang.String getIso() {
                r0 = this;
                java.lang.String r0 = r0.iso
                return r0
        }

        public java.lang.String getLightmetering() {
                r0 = this;
                java.lang.String r0 = r0.lightmetering
                return r0
        }

        public java.lang.String getLiveviewsize() {
                r0 = this;
                java.lang.String r0 = r0.liveviewsize
                return r0
        }

        public java.lang.String getOperatepriority() {
                r0 = this;
                java.lang.String r0 = r0.operatepriority
                return r0
        }

        public java.lang.String getPhotostyle() {
                r0 = this;
                java.lang.String r0 = r0.photostyle
                return r0
        }

        public java.lang.String getQuality() {
                r0 = this;
                java.lang.String r0 = r0.quality
                return r0
        }

        public java.lang.String getRealtimelut() {
                r0 = this;
                java.lang.String r0 = r0.realtimelut
                return r0
        }

        public java.lang.String getRecmode1() {
                r0 = this;
                java.lang.String r0 = r0.recmode1
                return r0
        }

        public java.lang.String getRecmode2() {
                r0 = this;
                java.lang.String r0 = r0.recmode2
                return r0
        }

        public java.lang.String getRecmode2value2() {
                r0 = this;
                java.lang.String r0 = r0.recmode2value2
                return r0
        }

        public java.lang.String getSelftimer() {
                r0 = this;
                java.lang.String r0 = r0.selftimer
                return r0
        }

        public java.lang.String getSelftimercustom() {
                r0 = this;
                java.lang.String r0 = r0.selftimercustom
                return r0
        }

        public java.lang.String getSqFPS() {
                r0 = this;
                java.lang.String r0 = r0.sqFPS
                return r0
        }

        public java.lang.String getSsAngle() {
                r0 = this;
                java.lang.String r0 = r0.ssAngle
                return r0
        }

        public java.lang.String getVideoformat() {
                r0 = this;
                java.lang.String r0 = r0.videoformat
                return r0
        }

        public java.lang.String getVideoquality() {
                r0 = this;
                java.lang.String r0 = r0.videoquality
                return r0
        }

        public java.lang.String getWhitebalance() {
                r0 = this;
                java.lang.String r0 = r0.whitebalance
                return r0
        }

        public void setAfmode(java.lang.String r1) {
                r0 = this;
                r0.afmode = r1
                return
        }

        public void setAspectratio(java.lang.String r1) {
                r0 = this;
                r0.aspectratio = r1
                return
        }

        public void setBurst1speed(java.lang.String r1) {
                r0 = this;
                r0.burst1speed = r1
                return
        }

        public void setBurst2speed(java.lang.String r1) {
                r0 = this;
                r0.burst2speed = r1
                return
        }

        public void setDb(java.lang.String r1) {
                r0 = this;
                r0.db = r1
                return
        }

        public void setDrivemode(java.lang.String r1) {
                r0 = this;
                r0.drivemode = r1
                return
        }

        public void setDualNativeIso(java.lang.String r1) {
                r0 = this;
                r0.dualNativeIso = r1
                return
        }

        public void setExposure(java.lang.String r1) {
                r0 = this;
                r0.exposure = r1
                return
        }

        public void setFocusmode(java.lang.String r1) {
                r0 = this;
                r0.focusmode = r1
                return
        }

        public void setHrsMode(java.lang.String r1) {
                r0 = this;
                r0.hrsMode = r1
                return
        }

        public void setIntervalMotionState(java.lang.String r1) {
                r0 = this;
                r0.intervalMotionState = r1
                return
        }

        public void setIso(java.lang.String r1) {
                r0 = this;
                r0.iso = r1
                return
        }

        public void setLightmetering(java.lang.String r1) {
                r0 = this;
                r0.lightmetering = r1
                return
        }

        public void setLiveviewsize(java.lang.String r1) {
                r0 = this;
                r0.liveviewsize = r1
                return
        }

        public void setOperatepriority(java.lang.String r1) {
                r0 = this;
                r0.operatepriority = r1
                return
        }

        public void setPhotostyle(java.lang.String r1) {
                r0 = this;
                r0.photostyle = r1
                return
        }

        public void setQuality(java.lang.String r1) {
                r0 = this;
                r0.quality = r1
                return
        }

        public void setRealtimelut(java.lang.String r1) {
                r0 = this;
                r0.realtimelut = r1
                return
        }

        public void setRecmode1(java.lang.String r1) {
                r0 = this;
                r0.recmode1 = r1
                return
        }

        public void setRecmode2(java.lang.String r1) {
                r0 = this;
                r0.recmode2 = r1
                return
        }

        public void setRecmode2value2(java.lang.String r1) {
                r0 = this;
                r0.recmode2value2 = r1
                return
        }

        public void setSelftimer(java.lang.String r1) {
                r0 = this;
                r0.selftimer = r1
                return
        }

        public void setSelftimercustom(java.lang.String r1) {
                r0 = this;
                r0.selftimercustom = r1
                return
        }

        public void setSqFPS(java.lang.String r1) {
                r0 = this;
                r0.sqFPS = r1
                return
        }

        public void setSsAngle(java.lang.String r1) {
                r0 = this;
                r0.ssAngle = r1
                return
        }

        public void setVideoformat(java.lang.String r1) {
                r0 = this;
                r0.videoformat = r1
                return
        }

        public void setVideoquality(java.lang.String r1) {
                r0 = this;
                r0.videoquality = r1
                return
        }

        public void setWhitebalance(java.lang.String r1) {
                r0 = this;
                r0.whitebalance = r1
                return
        }
    }

    public RemoteUDPPacketManager() {
            r1 = this;
            r1.<init>()
            java.lang.String r0 = "RemoteUDPPacketManager"
            r1.TAG = r0
            java.util.ArrayList r0 = new java.util.ArrayList
            r0.<init>()
            r1.focusFrameList = r0
            java.util.ArrayList r0 = new java.util.ArrayList
            r0.<init>()
            r1.iconContList = r0
            java.util.ArrayList r0 = new java.util.ArrayList
            r0.<init>()
            r1.settingValueList = r0
            com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.initFILEDMAP()
            com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.initFocusframeMAP()
            com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.initIconContMAP()
            com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.initSettingValueMAP()
            return
    }

    private java.lang.String D(byte[] r1, int r2, int r3) {
            r0 = this;
            int r3 = r3 + r2
            byte[] r1 = java.util.Arrays.copyOfRange(r1, r2, r3)     // Catch: java.lang.Throwable -> La
            java.lang.String r0 = com.panasonic.jp.flow.wireless.util.AppUtilManager.byteArrayToHexStr(r1)     // Catch: java.lang.Throwable -> La
            return r0
        La:
            r1 = move-exception
            java.lang.String r0 = r0.TAG
            com.panasonic.jp.flow.wireless.util.LogManager.e(r0, r1)
            java.lang.String r0 = ""
            return r0
    }

    private void clearData() {
            r2 = this;
            r0 = 0
            r2.totalsize = r0
            r2.version = r0
            r2.seqno = r0
            r2.dataflag = r0
            r2.srcid = r0
            r2.srcsubid = r0
            r2.datatype = r0
            r2.reserve1 = r0
            r2.pts = r0
            r2.totaldatasize = r0
            r2.dataoffset = r0
            r2.exheadersize = r0
            r2.exheadertype = r0
            r2.crntzoomval = r0
            r2.crntzoompos = r0
            r2.zoommaxchgcount = r0
            r2.opticalzoommaxpos = r0
            r2.exzoommaxpos = r0
            r2.iazoommaxpos = r0
            r2.digitalzoommaxpos = r0
            r2.rotate = r0
            r2.camstatus = r0
            r2.recmode = r0
            r2.exflag = r0
            r2.exflag2 = r0
            r2.numfocusframe = r0
            r2.Av_max_1 = r0
            r2.Av_max_2 = r0
            r2.Av_min_1 = r0
            r2.Av_min_2 = r0
            r2.Av_current_1 = r0
            r2.Av_current_2 = r0
            r2.Tv_max_1 = r0
            r2.Tv_max_2 = r0
            r2.Tv_min_1 = r0
            r2.Tv_min_2 = r0
            r2.Tv_current_1 = r0
            r2.Tv_current_2 = r0
            r2.Sv_max_1 = r0
            r2.Sv_max_2 = r0
            r2.Sv_min_1 = r0
            r2.Sv_min_2 = r0
            r2.Sv_current_1 = r0
            r2.Sv_current_2 = r0
            r2.currentexposure = r0
            r2.crntfocaldist = r0
            r2.crntEXzoom = r0
            r2.numIconCont = r0
            r2.processingstate = r0
            r2.assist_ID = r0
            r2.touch_AE_button = r0
            r2.Shut_state = r0
            r2.noise_reduction_time = r0
            r2.exflag3_vh = r0
            r2.exflag3 = r0
            r2.buff_size = r0
            r2.touchaf_button = r0
            r2.interval_state = r0
            r2.lens_mount = r0
            r2.reserve0C = r0
            r2.numSettingValue = r0
            java.util.ArrayList r1 = new java.util.ArrayList
            r1.<init>()
            r2.focusFrameList = r1
            java.util.ArrayList r1 = new java.util.ArrayList
            r1.<init>()
            r2.iconContList = r1
            java.util.ArrayList r1 = new java.util.ArrayList
            r1.<init>()
            r2.settingValueList = r1
            r2.bitmapData = r0
            return
    }

    public boolean dataflagIsEnd(byte[] r3) {
            r2 = this;
            r0 = 8
            r1 = 1
            java.lang.String r2 = r2.D(r3, r0, r1)
            java.lang.String r3 = "00"
            boolean r2 = r2.equals(r3)
            return r2
    }

    public java.lang.String getAssist_ID() {
            r0 = this;
            java.lang.String r0 = r0.assist_ID
            return r0
    }

    public java.lang.String getAv_current_1() {
            r0 = this;
            java.lang.String r0 = r0.Av_current_1
            return r0
    }

    public java.lang.String getAv_current_2() {
            r0 = this;
            java.lang.String r0 = r0.Av_current_2
            return r0
    }

    public java.lang.String getAv_max_1() {
            r0 = this;
            java.lang.String r0 = r0.Av_max_1
            return r0
    }

    public java.lang.String getAv_max_2() {
            r0 = this;
            java.lang.String r0 = r0.Av_max_2
            return r0
    }

    public java.lang.String getAv_min_1() {
            r0 = this;
            java.lang.String r0 = r0.Av_min_1
            return r0
    }

    public java.lang.String getAv_min_2() {
            r0 = this;
            java.lang.String r0 = r0.Av_min_2
            return r0
    }

    public byte[] getBitmapData() {
            r0 = this;
            byte[] r0 = r0.bitmapData
            return r0
    }

    public java.lang.String getBuff_size() {
            r0 = this;
            java.lang.String r0 = r0.buff_size
            return r0
    }

    public java.lang.String getCamstatus() {
            r0 = this;
            java.lang.String r0 = r0.camstatus
            return r0
    }

    public java.lang.String getCrntEXzoom() {
            r0 = this;
            java.lang.String r0 = r0.crntEXzoom
            return r0
    }

    public java.lang.String getCrntfocaldist() {
            r0 = this;
            java.lang.String r0 = r0.crntfocaldist
            return r0
    }

    public java.lang.String getCrntzoompos() {
            r0 = this;
            java.lang.String r0 = r0.crntzoompos
            return r0
    }

    public java.lang.String getCrntzoomval() {
            r0 = this;
            java.lang.String r0 = r0.crntzoomval
            return r0
    }

    public java.lang.String getCurrentexposure() {
            r0 = this;
            java.lang.String r0 = r0.currentexposure
            return r0
    }

    public java.lang.String getDataflag() {
            r0 = this;
            java.lang.String r0 = r0.dataflag
            return r0
    }

    public java.lang.String getDataoffset() {
            r0 = this;
            java.lang.String r0 = r0.dataoffset
            return r0
    }

    public java.lang.String getDatatype() {
            r0 = this;
            java.lang.String r0 = r0.datatype
            return r0
    }

    public java.lang.String getDigitalzoommaxpos() {
            r0 = this;
            java.lang.String r0 = r0.digitalzoommaxpos
            return r0
    }

    public java.lang.String getExflag() {
            r0 = this;
            java.lang.String r0 = r0.exflag
            return r0
    }

    public java.lang.String getExflag2() {
            r0 = this;
            java.lang.String r0 = r0.exflag2
            return r0
    }

    public java.lang.String getExflag3() {
            r0 = this;
            java.lang.String r0 = r0.exflag3
            return r0
    }

    public java.lang.String getExflag3_vh() {
            r0 = this;
            java.lang.String r0 = r0.exflag3_vh
            return r0
    }

    public java.lang.String getExheadersize() {
            r0 = this;
            java.lang.String r0 = r0.exheadersize
            return r0
    }

    public java.lang.String getExheadertype() {
            r0 = this;
            java.lang.String r0 = r0.exheadertype
            return r0
    }

    public java.lang.String getExzoommaxpos() {
            r0 = this;
            java.lang.String r0 = r0.exzoommaxpos
            return r0
    }

    public java.util.List<com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.FocusFrame> getFocusFrameList() {
            r0 = this;
            java.util.List<com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager$FocusFrame> r0 = r0.focusFrameList
            return r0
    }

    public java.lang.String getIazoommaxpos() {
            r0 = this;
            java.lang.String r0 = r0.iazoommaxpos
            return r0
    }

    public java.util.List<com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.IconCont> getIconContList() {
            r0 = this;
            java.util.List<com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager$IconCont> r0 = r0.iconContList
            return r0
    }

    public java.lang.String getInterval_state() {
            r0 = this;
            java.lang.String r0 = r0.interval_state
            return r0
    }

    public java.lang.String getJson() {
            r1 = this;
            com.google.gson.Gson r0 = new com.google.gson.Gson
            r0.<init>()
            java.lang.String r1 = r0.toJson(r1)
            return r1
    }

    public java.lang.String getLens_mount() {
            r0 = this;
            java.lang.String r0 = r0.lens_mount
            return r0
    }

    public java.lang.String getNoise_reduction_time() {
            r0 = this;
            java.lang.String r0 = r0.noise_reduction_time
            return r0
    }

    public java.lang.String getNumIconCont() {
            r0 = this;
            java.lang.String r0 = r0.numIconCont
            return r0
    }

    public java.lang.String getNumSettingValue() {
            r0 = this;
            java.lang.String r0 = r0.numSettingValue
            return r0
    }

    public java.lang.String getNumfocusframe() {
            r0 = this;
            java.lang.String r0 = r0.numfocusframe
            return r0
    }

    public java.lang.String getOpticalzoommaxpos() {
            r0 = this;
            java.lang.String r0 = r0.opticalzoommaxpos
            return r0
    }

    public java.lang.String getProcessingstate() {
            r0 = this;
            java.lang.String r0 = r0.processingstate
            return r0
    }

    public java.lang.String getPts() {
            r0 = this;
            java.lang.String r0 = r0.pts
            return r0
    }

    public java.lang.String getRecmode() {
            r0 = this;
            java.lang.String r0 = r0.recmode
            return r0
    }

    public java.lang.String getReserve0C() {
            r0 = this;
            java.lang.String r0 = r0.reserve0C
            return r0
    }

    public java.lang.String getReserve1() {
            r0 = this;
            java.lang.String r0 = r0.reserve1
            return r0
    }

    public java.lang.String getRotate() {
            r0 = this;
            java.lang.String r0 = r0.rotate
            return r0
    }

    public java.lang.String getSeqno() {
            r0 = this;
            java.lang.String r0 = r0.seqno
            return r0
    }

    public java.util.List<com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.SettingValue> getSettingValueList() {
            r0 = this;
            java.util.List<com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager$SettingValue> r0 = r0.settingValueList
            return r0
    }

    public java.lang.String getShut_state() {
            r0 = this;
            java.lang.String r0 = r0.Shut_state
            return r0
    }

    public java.lang.String getSrcid() {
            r0 = this;
            java.lang.String r0 = r0.srcid
            return r0
    }

    public java.lang.String getSrcsubid() {
            r0 = this;
            java.lang.String r0 = r0.srcsubid
            return r0
    }

    public java.lang.String getSv_current_1() {
            r0 = this;
            java.lang.String r0 = r0.Sv_current_1
            return r0
    }

    public java.lang.String getSv_current_2() {
            r0 = this;
            java.lang.String r0 = r0.Sv_current_2
            return r0
    }

    public java.lang.String getSv_max_1() {
            r0 = this;
            java.lang.String r0 = r0.Sv_max_1
            return r0
    }

    public java.lang.String getSv_max_2() {
            r0 = this;
            java.lang.String r0 = r0.Sv_max_2
            return r0
    }

    public java.lang.String getSv_min_1() {
            r0 = this;
            java.lang.String r0 = r0.Sv_min_1
            return r0
    }

    public java.lang.String getSv_min_2() {
            r0 = this;
            java.lang.String r0 = r0.Sv_min_2
            return r0
    }

    public java.lang.String getTotaldatasize() {
            r0 = this;
            java.lang.String r0 = r0.totaldatasize
            return r0
    }

    public java.lang.String getTotalsize() {
            r0 = this;
            java.lang.String r0 = r0.totalsize
            return r0
    }

    public java.lang.String getTouch_AE_button() {
            r0 = this;
            java.lang.String r0 = r0.touch_AE_button
            return r0
    }

    public java.lang.String getTouchaf_button() {
            r0 = this;
            java.lang.String r0 = r0.touchaf_button
            return r0
    }

    public java.lang.String getTv_current_1() {
            r0 = this;
            java.lang.String r0 = r0.Tv_current_1
            return r0
    }

    public java.lang.String getTv_current_2() {
            r0 = this;
            java.lang.String r0 = r0.Tv_current_2
            return r0
    }

    public java.lang.String getTv_max_1() {
            r0 = this;
            java.lang.String r0 = r0.Tv_max_1
            return r0
    }

    public java.lang.String getTv_max_2() {
            r0 = this;
            java.lang.String r0 = r0.Tv_max_2
            return r0
    }

    public java.lang.String getTv_min_1() {
            r0 = this;
            java.lang.String r0 = r0.Tv_min_1
            return r0
    }

    public java.lang.String getTv_min_2() {
            r0 = this;
            java.lang.String r0 = r0.Tv_min_2
            return r0
    }

    public java.lang.String getVersion() {
            r0 = this;
            java.lang.String r0 = r0.version
            return r0
    }

    public java.lang.String getZoommaxchgcount() {
            r0 = this;
            java.lang.String r0 = r0.zoommaxchgcount
            return r0
    }

    public byte[] loadBitmap(byte[] r6) {
            r5 = this;
            r0 = 2
            r1 = 0
            r2 = 0
            java.lang.String r3 = r5.D(r6, r1, r0)     // Catch: java.lang.Throwable -> L22
            r4 = 30
            java.lang.String r0 = r5.D(r6, r4, r0)     // Catch: java.lang.Throwable -> L22
            r4 = 16
            int r3 = java.lang.Integer.parseInt(r3, r4)     // Catch: java.lang.Throwable -> L22
            int r0 = java.lang.Integer.parseInt(r0, r4)     // Catch: java.lang.Throwable -> L22
            int r3 = r3 + (-32)
            int r3 = r3 - r0
            byte[] r2 = new byte[r3]     // Catch: java.lang.Throwable -> L22
            int r0 = r6.length     // Catch: java.lang.Throwable -> L22
            int r0 = r0 - r3
            java.lang.System.arraycopy(r6, r0, r2, r1, r3)     // Catch: java.lang.Throwable -> L22
            goto L28
        L22:
            r6 = move-exception
            java.lang.String r5 = r5.TAG
            com.panasonic.jp.flow.wireless.util.LogManager.e(r5, r6)
        L28:
            return r2
    }

    public byte[] loadBitmap(byte[] r3, java.lang.String r4, java.lang.String r5) {
            r2 = this;
            r0 = 0
            boolean r1 = android.text.TextUtils.isEmpty(r4)     // Catch: java.lang.Throwable -> L1f
            if (r1 != 0) goto L25
            boolean r1 = android.text.TextUtils.isEmpty(r5)     // Catch: java.lang.Throwable -> L1f
            if (r1 != 0) goto L25
            r1 = 16
            int r4 = java.lang.Integer.parseInt(r4, r1)     // Catch: java.lang.Throwable -> L1f
            java.lang.Integer.parseInt(r5, r1)     // Catch: java.lang.Throwable -> L1f
            byte[] r0 = new byte[r4]     // Catch: java.lang.Throwable -> L1f
            int r5 = r3.length     // Catch: java.lang.Throwable -> L1f
            int r5 = r5 - r4
            r1 = 0
            java.lang.System.arraycopy(r3, r5, r0, r1, r4)     // Catch: java.lang.Throwable -> L1f
            goto L25
        L1f:
            r3 = move-exception
            java.lang.String r2 = r2.TAG
            com.panasonic.jp.flow.wireless.util.LogManager.e(r2, r3)
        L25:
            return r0
    }

    public java.lang.String loadD(byte[] r1, int r2, int r3) {
            r0 = this;
            java.lang.String r0 = r0.D(r1, r2, r3)
            return r0
    }

    public java.lang.String loadDataflag(byte[] r3) {
            r2 = this;
            r0 = 8
            r1 = 1
            java.lang.String r2 = r2.D(r3, r0, r1)
            return r2
    }

    public byte[] loadExheader(byte[] r4) {
            r3 = this;
            r0 = 30
            r1 = 2
            r2 = 0
            java.lang.String r0 = r3.D(r4, r0, r1)     // Catch: java.lang.Throwable -> L17
            r1 = 16
            int r0 = java.lang.Integer.parseInt(r0, r1)     // Catch: java.lang.Throwable -> L17
            int r0 = r0 + 32
            byte[] r2 = new byte[r0]     // Catch: java.lang.Throwable -> L17
            r1 = 0
            java.lang.System.arraycopy(r4, r1, r2, r1, r0)     // Catch: java.lang.Throwable -> L17
            goto L1d
        L17:
            r4 = move-exception
            java.lang.String r3 = r3.TAG
            com.panasonic.jp.flow.wireless.util.LogManager.e(r3, r4)
        L1d:
            return r2
    }

    public java.lang.String loadPts(byte[] r3) {
            r2 = this;
            r0 = 18
            r1 = 4
            java.lang.String r2 = r2.D(r3, r0, r1)
            return r2
    }

    public java.lang.String loadSeqno(byte[] r2) {
            r1 = this;
            r0 = 4
            java.lang.String r1 = r1.D(r2, r0, r0)
            return r1
    }

    @androidx.annotation.NonNull
    public java.lang.String toString() {
            r3 = this;
            java.lang.StringBuilder r0 = new java.lang.StringBuilder
            java.lang.String r1 = "\n totalsize : "
            r0.<init>(r1)
            java.lang.String r1 = r3.totalsize
            r0.append(r1)
            java.lang.String r1 = "\n version : "
            r0.append(r1)
            java.lang.String r1 = r3.version
            r0.append(r1)
            java.lang.String r1 = "\n seqno : "
            r0.append(r1)
            java.lang.String r1 = r3.seqno
            r0.append(r1)
            java.lang.String r1 = "\n dataflag : "
            r0.append(r1)
            java.lang.String r1 = r3.dataflag
            r0.append(r1)
            java.lang.String r1 = "\n srcid : "
            r0.append(r1)
            java.lang.String r1 = r3.srcid
            r0.append(r1)
            java.lang.String r1 = "\n srcsubid : "
            r0.append(r1)
            java.lang.String r1 = r3.srcsubid
            r0.append(r1)
            java.lang.String r1 = "\n datatype : "
            r0.append(r1)
            java.lang.String r1 = r3.datatype
            r0.append(r1)
            java.lang.String r1 = "\n reserve1 : "
            r0.append(r1)
            java.lang.String r1 = r3.reserve1
            r0.append(r1)
            java.lang.String r1 = "\n pts : "
            r0.append(r1)
            java.lang.String r1 = r3.pts
            r0.append(r1)
            java.lang.String r1 = "\n totaldatasize : "
            r0.append(r1)
            java.lang.String r1 = r3.totaldatasize
            r0.append(r1)
            java.lang.String r1 = "\n dataoffset : "
            r0.append(r1)
            java.lang.String r1 = r3.dataoffset
            r0.append(r1)
            java.lang.String r1 = "\n exheadersize : "
            r0.append(r1)
            java.lang.String r1 = r3.exheadersize
            r0.append(r1)
            java.lang.String r1 = "\n exheadertype : "
            r0.append(r1)
            java.lang.String r1 = r3.exheadertype
            r0.append(r1)
            java.lang.String r1 = "\n crntzoomval : "
            r0.append(r1)
            java.lang.String r1 = r3.crntzoomval
            r0.append(r1)
            java.lang.String r1 = "\n crntzoompos : "
            r0.append(r1)
            java.lang.String r1 = r3.crntzoompos
            r0.append(r1)
            java.lang.String r1 = "\n zoommaxchgcount : "
            r0.append(r1)
            java.lang.String r1 = r3.zoommaxchgcount
            r0.append(r1)
            java.lang.String r1 = "\n opticalzoommaxpos : "
            r0.append(r1)
            java.lang.String r1 = r3.opticalzoommaxpos
            r0.append(r1)
            java.lang.String r1 = "\n exzoommaxpos : "
            r0.append(r1)
            java.lang.String r1 = r3.exzoommaxpos
            r0.append(r1)
            java.lang.String r1 = "\n iazoommaxpos : "
            r0.append(r1)
            java.lang.String r1 = r3.iazoommaxpos
            r0.append(r1)
            java.lang.String r1 = "\n digitalzoommaxpos : "
            r0.append(r1)
            java.lang.String r1 = r3.digitalzoommaxpos
            r0.append(r1)
            java.lang.String r1 = "\n rotate : "
            r0.append(r1)
            java.lang.String r1 = r3.rotate
            r0.append(r1)
            java.lang.String r1 = "\n camstatus : "
            r0.append(r1)
            java.lang.String r1 = r3.camstatus
            r0.append(r1)
            java.lang.String r1 = "\n recmode : "
            r0.append(r1)
            java.lang.String r1 = r3.recmode
            r0.append(r1)
            java.lang.String r1 = "\n exflag : "
            r0.append(r1)
            java.lang.String r1 = r3.exflag
            r0.append(r1)
            java.lang.String r1 = "\n exflag2 : "
            r0.append(r1)
            java.lang.String r1 = r3.exflag2
            r0.append(r1)
            java.lang.String r1 = "\n numfocusframe : "
            r0.append(r1)
            java.lang.String r1 = r3.numfocusframe
            r0.append(r1)
            java.lang.String r1 = "\n Av_max_1 : "
            r0.append(r1)
            java.lang.String r1 = r3.Av_max_1
            r0.append(r1)
            java.lang.String r1 = "\n Av_max_2 : "
            r0.append(r1)
            java.lang.String r1 = r3.Av_max_2
            r0.append(r1)
            java.lang.String r1 = "\n Av_min_1 : "
            r0.append(r1)
            java.lang.String r1 = r3.Av_min_1
            r0.append(r1)
            java.lang.String r1 = "\n Av_min_2 : "
            r0.append(r1)
            java.lang.String r1 = r3.Av_min_2
            r0.append(r1)
            java.lang.String r1 = "\n Av_current_1 : "
            r0.append(r1)
            java.lang.String r1 = r3.Av_current_1
            r0.append(r1)
            java.lang.String r1 = "\n Av_current_2 : "
            r0.append(r1)
            java.lang.String r1 = r3.Av_current_2
            r0.append(r1)
            java.lang.String r1 = "\n Tv_max_1 : "
            r0.append(r1)
            java.lang.String r1 = r3.Tv_max_1
            r0.append(r1)
            java.lang.String r1 = "\n Tv_max_2 : "
            r0.append(r1)
            java.lang.String r1 = r3.Tv_max_2
            r0.append(r1)
            java.lang.String r1 = "\n Tv_min_1 : "
            r0.append(r1)
            java.lang.String r1 = r3.Tv_min_1
            r0.append(r1)
            java.lang.String r1 = "\n Tv_min_2 : "
            r0.append(r1)
            java.lang.String r1 = r3.Tv_min_2
            r0.append(r1)
            java.lang.String r1 = "\n Tv_current_1 : "
            r0.append(r1)
            java.lang.String r1 = r3.Tv_current_1
            r0.append(r1)
            java.lang.String r1 = "\n Tv_current_2 : "
            r0.append(r1)
            java.lang.String r1 = r3.Tv_current_2
            r0.append(r1)
            java.lang.String r1 = "\n Sv_max_1 : "
            r0.append(r1)
            java.lang.String r1 = r3.Sv_max_1
            r0.append(r1)
            java.lang.String r1 = "\n Sv_max_2 : "
            r0.append(r1)
            java.lang.String r1 = r3.Sv_max_2
            r0.append(r1)
            java.lang.String r1 = "\n Sv_min_1 : "
            r0.append(r1)
            java.lang.String r1 = r3.Sv_min_1
            r0.append(r1)
            java.lang.String r1 = "\n Sv_min_2 : "
            r0.append(r1)
            java.lang.String r1 = r3.Sv_min_2
            r0.append(r1)
            java.lang.String r1 = "\n Sv_current_1 : "
            r0.append(r1)
            java.lang.String r1 = r3.Sv_current_1
            r0.append(r1)
            java.lang.String r1 = "\n Sv_current_2 : "
            r0.append(r1)
            java.lang.String r1 = r3.Sv_current_2
            r0.append(r1)
            java.lang.String r1 = "\n currentexposure : "
            r0.append(r1)
            java.lang.String r1 = r3.currentexposure
            r0.append(r1)
            java.lang.String r1 = "\n crntfocaldist : "
            r0.append(r1)
            java.lang.String r1 = r3.crntfocaldist
            r0.append(r1)
            java.lang.String r1 = "\n crntEXzoom : "
            r0.append(r1)
            java.lang.String r1 = r3.crntEXzoom
            r0.append(r1)
            java.lang.String r1 = "\n numIconCont : "
            r0.append(r1)
            java.lang.String r1 = r3.numIconCont
            r0.append(r1)
            java.lang.String r1 = "\n processingstate : "
            r0.append(r1)
            java.lang.String r1 = r3.processingstate
            r0.append(r1)
            java.lang.String r1 = "\n assist_ID : "
            r0.append(r1)
            java.lang.String r1 = r3.assist_ID
            r0.append(r1)
            java.lang.String r1 = "\n touch_AE_button : "
            r0.append(r1)
            java.lang.String r1 = r3.touch_AE_button
            r0.append(r1)
            java.lang.String r1 = "\n Shut_state : "
            r0.append(r1)
            java.lang.String r1 = r3.Shut_state
            r0.append(r1)
            java.lang.String r1 = "\n noise_reduction_time : "
            r0.append(r1)
            java.lang.String r1 = r3.noise_reduction_time
            r0.append(r1)
            java.lang.String r1 = "\n exflag3_vh : "
            r0.append(r1)
            java.lang.String r1 = r3.exflag3_vh
            r0.append(r1)
            java.lang.String r1 = "\n exflag3 : "
            r0.append(r1)
            java.lang.String r1 = r3.exflag3
            r0.append(r1)
            java.lang.String r1 = "\n buff_size : "
            r0.append(r1)
            java.lang.String r1 = r3.buff_size
            r0.append(r1)
            java.lang.String r1 = "\n touchaf_button : "
            r0.append(r1)
            java.lang.String r1 = r3.touchaf_button
            r0.append(r1)
            java.lang.String r1 = "\n interval_state : "
            r0.append(r1)
            java.lang.String r1 = r3.interval_state
            r0.append(r1)
            java.lang.String r1 = "\n lens_mount : "
            r0.append(r1)
            java.lang.String r1 = r3.lens_mount
            r0.append(r1)
            java.lang.String r1 = "\n reserve0C : "
            r0.append(r1)
            java.lang.String r1 = r3.reserve0C
            r0.append(r1)
            java.lang.String r1 = "\n numSettingValue : "
            r0.append(r1)
            java.lang.String r1 = r3.numSettingValue
            r0.append(r1)
            java.lang.String r1 = "\n\n\n focusFrameList : "
            r0.append(r1)
            com.google.gson.Gson r1 = new com.google.gson.Gson
            r1.<init>()
            java.util.List<com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager$FocusFrame> r2 = r3.focusFrameList
            java.lang.String r1 = r1.toJson(r2)
            r0.append(r1)
            java.lang.String r1 = "\n\n\n iconContList : "
            r0.append(r1)
            com.google.gson.Gson r1 = new com.google.gson.Gson
            r1.<init>()
            java.util.List<com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager$IconCont> r2 = r3.iconContList
            java.lang.String r1 = r1.toJson(r2)
            r0.append(r1)
            java.lang.String r1 = "\n\n\n settingValueList : "
            r0.append(r1)
            com.google.gson.Gson r1 = new com.google.gson.Gson
            r1.<init>()
            java.util.List<com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager$SettingValue> r3 = r3.settingValueList
            java.lang.String r3 = r1.toJson(r3)
            r0.append(r3)
            java.lang.String r3 = r0.toString()
            return r3
    }

    public synchronized void updateData(byte[] r31) {
            r30 = this;
            r1 = r30
            r2 = r31
            monitor-enter(r30)
            if (r2 == 0) goto Lc44
            int r3 = r2.length     // Catch: java.lang.Throwable -> L57
            if (r3 != 0) goto Lc
            goto Lc44
        Lc:
            java.util.Map<java.lang.String, java.lang.Integer> r3 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.util.Set r3 = r3.keySet()     // Catch: java.lang.Throwable -> L57
            java.util.Iterator r3 = r3.iterator()     // Catch: java.lang.Throwable -> L57
            r5 = 0
        L17:
            boolean r6 = r3.hasNext()     // Catch: java.lang.Throwable -> L57
            if (r6 == 0) goto Lc1a
            java.lang.Object r6 = r3.next()     // Catch: java.lang.Throwable -> L57
            java.lang.String r6 = (java.lang.String) r6     // Catch: java.lang.Throwable -> L57
            int r7 = r6.hashCode()     // Catch: java.lang.Throwable -> L57
            r13 = 12
            r14 = 26
            r15 = 27
            r4 = 16
            r16 = 11
            r17 = 9
            r18 = 10
            r19 = 5
            r20 = 7
            r21 = 8
            r22 = 2
            r23 = 4
            r24 = 3
            r25 = 6
            r26 = -1
            r8 = 1
            switch(r7) {
                case -1971304346: goto L311;
                case -1937708121: goto L306;
                case -1813389642: goto L2fb;
                case -1799099973: goto L2f0;
                case -1754682597: goto L2e5;
                case -1750738722: goto L2da;
                case -1731222287: goto L2cf;
                case -1669723752: goto L2c4;
                case -1518515173: goto L2b9;
                case -1318397581: goto L2ad;
                case -1318397580: goto L2a1;
                case -1289454945: goto L295;
                case -1200937126: goto L289;
                case -1200937125: goto L27d;
                case -1200708408: goto L271;
                case -1200708407: goto L265;
                case -1162313043: goto L259;
                case -925180581: goto L24d;
                case -782785385: goto L241;
                case -651221770: goto L235;
                case -576358075: goto L22a;
                case -399995913: goto L21e;
                case -350385419: goto L212;
                case -294237137: goto L206;
                case -294237136: goto L1fa;
                case -165154418: goto L1ee;
                case -165154417: goto L1e2;
                case -88150995: goto L1d6;
                case 111343: goto L1ca;
                case 20438523: goto L1bf;
                case 56001645: goto L1b3;
                case 60684417: goto L1a7;
                case 109325920: goto L19b;
                case 109699583: goto L18f;
                case 262844800: goto L183;
                case 351608024: goto L178;
                case 503783820: goto L16c;
                case 503789145: goto L160;
                case 541873209: goto L154;
                case 541873210: goto L148;
                case 542101927: goto L13c;
                case 542101928: goto L130;
                case 673847195: goto L124;
                case 1082534451: goto L118;
                case 1093711197: goto L10c;
                case 1199386974: goto L100;
                case 1245101313: goto Lf4;
                case 1245146170: goto Le9;
                case 1429825201: goto Ldd;
                case 1677241217: goto Ld1;
                case 1677241218: goto Lc5;
                case 1751794159: goto Lb9;
                case 1788215212: goto Lae;
                case 1788215213: goto La3;
                case 1788443930: goto L97;
                case 1788443931: goto L8b;
                case 1789594134: goto L7f;
                case 1790024164: goto L73;
                case 1808927070: goto L67;
                case 2022953935: goto L5b;
                case 2065329341: goto L4b;
                default: goto L49;
            }     // Catch: java.lang.Throwable -> L57
        L49:
            goto L31c
        L4b:
            java.lang.String r7 = "dataoffset"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = r18
            goto L31e
        L57:
            r0 = move-exception
            r2 = r0
            goto Lc36
        L5b:
            java.lang.String r7 = "reserve0C"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = 59
            goto L31e
        L67:
            java.lang.String r7 = "processingstate"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = 48
            goto L31e
        L73:
            java.lang.String r7 = "datatype"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = r25
            goto L31e
        L7f:
            java.lang.String r7 = "dataflag"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = r24
            goto L31e
        L8b:
            java.lang.String r7 = "Av_min_2"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = 29
            goto L31e
        L97:
            java.lang.String r7 = "Av_min_1"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = 28
            goto L31e
        La3:
            java.lang.String r7 = "Av_max_2"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = r15
            goto L31e
        Lae:
            java.lang.String r7 = "Av_max_1"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = r14
            goto L31e
        Lb9:
            java.lang.String r7 = "totaldatasize"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = r17
            goto L31e
        Lc5:
            java.lang.String r7 = "Av_current_2"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = 31
            goto L31e
        Ld1:
            java.lang.String r7 = "Av_current_1"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = 30
            goto L31e
        Ldd:
            java.lang.String r7 = "assist_ID"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = 49
            goto L31e
        Le9:
            java.lang.String r7 = "exheadertype"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = r13
            goto L31e
        Lf4:
            java.lang.String r7 = "exheadersize"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = r16
            goto L31e
        L100:
            java.lang.String r7 = "zoommaxchgcount"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = 15
            goto L31e
        L10c:
            java.lang.String r7 = "exflag3_vh"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = 53
            goto L31e
        L118:
            java.lang.String r7 = "recmode"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = 22
            goto L31e
        L124:
            java.lang.String r7 = "numfocusframe"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = 25
            goto L31e
        L130:
            java.lang.String r7 = "Tv_min_2"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = 35
            goto L31e
        L13c:
            java.lang.String r7 = "Tv_min_1"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = 34
            goto L31e
        L148:
            java.lang.String r7 = "Tv_max_2"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = 33
            goto L31e
        L154:
            java.lang.String r7 = "Tv_max_1"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = 32
            goto L31e
        L160:
            java.lang.String r7 = "crntzoomval"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = 13
            goto L31e
        L16c:
            java.lang.String r7 = "crntzoompos"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = 14
            goto L31e
        L178:
            java.lang.String r7 = "version"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = r8
            goto L31e
        L183:
            java.lang.String r7 = "currentexposure"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = 44
            goto L31e
        L18f:
            java.lang.String r7 = "srcid"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = r23
            goto L31e
        L19b:
            java.lang.String r7 = "seqno"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = r22
            goto L31e
        L1a7:
            java.lang.String r7 = "camstatus"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = 21
            goto L31e
        L1b3:
            java.lang.String r7 = "buff_size"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = 55
            goto L31e
        L1bf:
            java.lang.String r7 = "opticalzoommaxpos"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = r4
            goto L31e
        L1ca:
            java.lang.String r7 = "pts"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = r21
            goto L31e
        L1d6:
            java.lang.String r7 = "touchaf_button"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = 56
            goto L31e
        L1e2:
            java.lang.String r7 = "Tv_current_2"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = 37
            goto L31e
        L1ee:
            java.lang.String r7 = "Tv_current_1"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = 36
            goto L31e
        L1fa:
            java.lang.String r7 = "Sv_current_2"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = 43
            goto L31e
        L206:
            java.lang.String r7 = "Sv_current_1"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = 42
            goto L31e
        L212:
            java.lang.String r7 = "reserve1"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = r20
            goto L31e
        L21e:
            java.lang.String r7 = "srcsubid"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = r19
            goto L31e
        L22a:
            java.lang.String r7 = "totalsize"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = 0
            goto L31e
        L235:
            java.lang.String r7 = "exzoommaxpos"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = 17
            goto L31e
        L241:
            java.lang.String r7 = "interval_state"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = 57
            goto L31e
        L24d:
            java.lang.String r7 = "rotate"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = 20
            goto L31e
        L259:
            java.lang.String r7 = "touch_AE_button"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = 50
            goto L31e
        L265:
            java.lang.String r7 = "Sv_min_2"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = 41
            goto L31e
        L271:
            java.lang.String r7 = "Sv_min_1"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = 40
            goto L31e
        L27d:
            java.lang.String r7 = "Sv_max_2"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = 39
            goto L31e
        L289:
            java.lang.String r7 = "Sv_max_1"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = 38
            goto L31e
        L295:
            java.lang.String r7 = "exflag"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = 23
            goto L31e
        L2a1:
            java.lang.String r7 = "exflag3"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = 54
            goto L31e
        L2ad:
            java.lang.String r7 = "exflag2"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = 24
            goto L31e
        L2b9:
            java.lang.String r7 = "digitalzoommaxpos"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = 19
            goto L31e
        L2c4:
            java.lang.String r7 = "lens_mount"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = 58
            goto L31e
        L2cf:
            java.lang.String r7 = "numIconCont"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = 47
            goto L31e
        L2da:
            java.lang.String r7 = "noise_reduction_time"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = 52
            goto L31e
        L2e5:
            java.lang.String r7 = "iazoommaxpos"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = 18
            goto L31e
        L2f0:
            java.lang.String r7 = "crntEXzoom"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = 46
            goto L31e
        L2fb:
            java.lang.String r7 = "crntfocaldist"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = 45
            goto L31e
        L306:
            java.lang.String r7 = "numSettingValue"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = 60
            goto L31e
        L311:
            java.lang.String r7 = "Shut_state"
            boolean r7 = r6.equals(r7)     // Catch: java.lang.Throwable -> L57
            if (r7 == 0) goto L31c
            r7 = 51
            goto L31e
        L31c:
            r7 = r26
        L31e:
            switch(r7) {
                case 0: goto L323;
                case 1: goto L336;
                case 2: goto L349;
                case 3: goto L35c;
                case 4: goto L36f;
                case 5: goto L382;
                case 6: goto L395;
                case 7: goto L3a8;
                case 8: goto L3bb;
                case 9: goto L3ce;
                case 10: goto L3e1;
                case 11: goto L3f4;
                case 12: goto L407;
                case 13: goto L41a;
                case 14: goto L42d;
                case 15: goto L440;
                case 16: goto L453;
                case 17: goto L466;
                case 18: goto L479;
                case 19: goto L48c;
                case 20: goto L49f;
                case 21: goto L4b2;
                case 22: goto L4c5;
                case 23: goto L4d8;
                case 24: goto L4eb;
                case 25: goto L4fe;
                case 26: goto L63b;
                case 27: goto L64e;
                case 28: goto L661;
                case 29: goto L674;
                case 30: goto L687;
                case 31: goto L69a;
                case 32: goto L6ad;
                case 33: goto L6c0;
                case 34: goto L6d3;
                case 35: goto L6e6;
                case 36: goto L6f9;
                case 37: goto L70c;
                case 38: goto L71f;
                case 39: goto L732;
                case 40: goto L745;
                case 41: goto L758;
                case 42: goto L76b;
                case 43: goto L77e;
                case 44: goto L791;
                case 45: goto L7a4;
                case 46: goto L7b7;
                case 47: goto L7ca;
                case 48: goto L8c6;
                case 49: goto L8d9;
                case 50: goto L8ec;
                case 51: goto L8ff;
                case 52: goto L912;
                case 53: goto L925;
                case 54: goto L938;
                case 55: goto L94b;
                case 56: goto L95e;
                case 57: goto L971;
                case 58: goto L984;
                case 59: goto L997;
                case 60: goto L9aa;
                default: goto L321;
            }     // Catch: java.lang.Throwable -> L57
        L321:
            goto L17
        L323:
            java.util.Map<java.lang.String, java.lang.Integer> r7 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r7 = r7.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r7 = (java.lang.Integer) r7     // Catch: java.lang.Throwable -> L57
            int r7 = r7.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r9 = r1.D(r2, r5, r7)     // Catch: java.lang.Throwable -> L57
            r1.totalsize = r9     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r7
        L336:
            java.util.Map<java.lang.String, java.lang.Integer> r7 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r7 = r7.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r7 = (java.lang.Integer) r7     // Catch: java.lang.Throwable -> L57
            int r7 = r7.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r9 = r1.D(r2, r5, r7)     // Catch: java.lang.Throwable -> L57
            r1.version = r9     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r7
        L349:
            java.util.Map<java.lang.String, java.lang.Integer> r7 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r7 = r7.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r7 = (java.lang.Integer) r7     // Catch: java.lang.Throwable -> L57
            int r7 = r7.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r9 = r1.D(r2, r5, r7)     // Catch: java.lang.Throwable -> L57
            r1.seqno = r9     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r7
        L35c:
            java.util.Map<java.lang.String, java.lang.Integer> r7 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r7 = r7.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r7 = (java.lang.Integer) r7     // Catch: java.lang.Throwable -> L57
            int r7 = r7.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r9 = r1.D(r2, r5, r7)     // Catch: java.lang.Throwable -> L57
            r1.dataflag = r9     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r7
        L36f:
            java.util.Map<java.lang.String, java.lang.Integer> r7 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r7 = r7.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r7 = (java.lang.Integer) r7     // Catch: java.lang.Throwable -> L57
            int r7 = r7.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r9 = r1.D(r2, r5, r7)     // Catch: java.lang.Throwable -> L57
            r1.srcid = r9     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r7
        L382:
            java.util.Map<java.lang.String, java.lang.Integer> r7 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r7 = r7.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r7 = (java.lang.Integer) r7     // Catch: java.lang.Throwable -> L57
            int r7 = r7.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r9 = r1.D(r2, r5, r7)     // Catch: java.lang.Throwable -> L57
            r1.srcsubid = r9     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r7
        L395:
            java.util.Map<java.lang.String, java.lang.Integer> r7 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r7 = r7.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r7 = (java.lang.Integer) r7     // Catch: java.lang.Throwable -> L57
            int r7 = r7.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r9 = r1.D(r2, r5, r7)     // Catch: java.lang.Throwable -> L57
            r1.datatype = r9     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r7
        L3a8:
            java.util.Map<java.lang.String, java.lang.Integer> r7 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r7 = r7.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r7 = (java.lang.Integer) r7     // Catch: java.lang.Throwable -> L57
            int r7 = r7.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r9 = r1.D(r2, r5, r7)     // Catch: java.lang.Throwable -> L57
            r1.reserve1 = r9     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r7
        L3bb:
            java.util.Map<java.lang.String, java.lang.Integer> r7 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r7 = r7.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r7 = (java.lang.Integer) r7     // Catch: java.lang.Throwable -> L57
            int r7 = r7.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r9 = r1.D(r2, r5, r7)     // Catch: java.lang.Throwable -> L57
            r1.pts = r9     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r7
        L3ce:
            java.util.Map<java.lang.String, java.lang.Integer> r7 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r7 = r7.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r7 = (java.lang.Integer) r7     // Catch: java.lang.Throwable -> L57
            int r7 = r7.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r9 = r1.D(r2, r5, r7)     // Catch: java.lang.Throwable -> L57
            r1.totaldatasize = r9     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r7
        L3e1:
            java.util.Map<java.lang.String, java.lang.Integer> r7 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r7 = r7.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r7 = (java.lang.Integer) r7     // Catch: java.lang.Throwable -> L57
            int r7 = r7.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r9 = r1.D(r2, r5, r7)     // Catch: java.lang.Throwable -> L57
            r1.dataoffset = r9     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r7
        L3f4:
            java.util.Map<java.lang.String, java.lang.Integer> r7 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r7 = r7.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r7 = (java.lang.Integer) r7     // Catch: java.lang.Throwable -> L57
            int r7 = r7.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r9 = r1.D(r2, r5, r7)     // Catch: java.lang.Throwable -> L57
            r1.exheadersize = r9     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r7
        L407:
            java.util.Map<java.lang.String, java.lang.Integer> r7 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r7 = r7.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r7 = (java.lang.Integer) r7     // Catch: java.lang.Throwable -> L57
            int r7 = r7.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r9 = r1.D(r2, r5, r7)     // Catch: java.lang.Throwable -> L57
            r1.exheadertype = r9     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r7
        L41a:
            java.util.Map<java.lang.String, java.lang.Integer> r7 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r7 = r7.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r7 = (java.lang.Integer) r7     // Catch: java.lang.Throwable -> L57
            int r7 = r7.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r9 = r1.D(r2, r5, r7)     // Catch: java.lang.Throwable -> L57
            r1.crntzoomval = r9     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r7
        L42d:
            java.util.Map<java.lang.String, java.lang.Integer> r7 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r7 = r7.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r7 = (java.lang.Integer) r7     // Catch: java.lang.Throwable -> L57
            int r7 = r7.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r9 = r1.D(r2, r5, r7)     // Catch: java.lang.Throwable -> L57
            r1.crntzoompos = r9     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r7
        L440:
            java.util.Map<java.lang.String, java.lang.Integer> r7 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r7 = r7.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r7 = (java.lang.Integer) r7     // Catch: java.lang.Throwable -> L57
            int r7 = r7.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r9 = r1.D(r2, r5, r7)     // Catch: java.lang.Throwable -> L57
            r1.zoommaxchgcount = r9     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r7
        L453:
            java.util.Map<java.lang.String, java.lang.Integer> r7 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r7 = r7.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r7 = (java.lang.Integer) r7     // Catch: java.lang.Throwable -> L57
            int r7 = r7.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r9 = r1.D(r2, r5, r7)     // Catch: java.lang.Throwable -> L57
            r1.opticalzoommaxpos = r9     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r7
        L466:
            java.util.Map<java.lang.String, java.lang.Integer> r7 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r7 = r7.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r7 = (java.lang.Integer) r7     // Catch: java.lang.Throwable -> L57
            int r7 = r7.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r9 = r1.D(r2, r5, r7)     // Catch: java.lang.Throwable -> L57
            r1.exzoommaxpos = r9     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r7
        L479:
            java.util.Map<java.lang.String, java.lang.Integer> r7 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r7 = r7.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r7 = (java.lang.Integer) r7     // Catch: java.lang.Throwable -> L57
            int r7 = r7.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r9 = r1.D(r2, r5, r7)     // Catch: java.lang.Throwable -> L57
            r1.iazoommaxpos = r9     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r7
        L48c:
            java.util.Map<java.lang.String, java.lang.Integer> r7 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r7 = r7.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r7 = (java.lang.Integer) r7     // Catch: java.lang.Throwable -> L57
            int r7 = r7.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r9 = r1.D(r2, r5, r7)     // Catch: java.lang.Throwable -> L57
            r1.digitalzoommaxpos = r9     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r7
        L49f:
            java.util.Map<java.lang.String, java.lang.Integer> r7 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r7 = r7.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r7 = (java.lang.Integer) r7     // Catch: java.lang.Throwable -> L57
            int r7 = r7.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r9 = r1.D(r2, r5, r7)     // Catch: java.lang.Throwable -> L57
            r1.rotate = r9     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r7
        L4b2:
            java.util.Map<java.lang.String, java.lang.Integer> r7 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r7 = r7.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r7 = (java.lang.Integer) r7     // Catch: java.lang.Throwable -> L57
            int r7 = r7.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r9 = r1.D(r2, r5, r7)     // Catch: java.lang.Throwable -> L57
            r1.camstatus = r9     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r7
        L4c5:
            java.util.Map<java.lang.String, java.lang.Integer> r7 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r7 = r7.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r7 = (java.lang.Integer) r7     // Catch: java.lang.Throwable -> L57
            int r7 = r7.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r9 = r1.D(r2, r5, r7)     // Catch: java.lang.Throwable -> L57
            r1.recmode = r9     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r7
        L4d8:
            java.util.Map<java.lang.String, java.lang.Integer> r7 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r7 = r7.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r7 = (java.lang.Integer) r7     // Catch: java.lang.Throwable -> L57
            int r7 = r7.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r9 = r1.D(r2, r5, r7)     // Catch: java.lang.Throwable -> L57
            r1.exflag = r9     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r7
        L4eb:
            java.util.Map<java.lang.String, java.lang.Integer> r7 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r7 = r7.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r7 = (java.lang.Integer) r7     // Catch: java.lang.Throwable -> L57
            int r7 = r7.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r9 = r1.D(r2, r5, r7)     // Catch: java.lang.Throwable -> L57
            r1.exflag2 = r9     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r7
        L4fe:
            java.util.Map<java.lang.String, java.lang.Integer> r7 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r7 = r7.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r7 = (java.lang.Integer) r7     // Catch: java.lang.Throwable -> L57
            int r7 = r7.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r9 = r1.D(r2, r5, r7)     // Catch: java.lang.Throwable -> L57
            r1.numfocusframe = r9     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r7
            int r7 = java.lang.Integer.parseInt(r9, r4)     // Catch: java.lang.Throwable -> L57
            java.util.List<com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager$FocusFrame> r9 = r1.focusFrameList     // Catch: java.lang.Throwable -> L57
            r9.clear()     // Catch: java.lang.Throwable -> L57
            r9 = 0
        L51b:
            if (r9 >= r7) goto L63b
            com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager$FocusFrame r4 = new com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager$FocusFrame     // Catch: java.lang.Throwable -> L57
            r4.<init>()     // Catch: java.lang.Throwable -> L57
            java.util.Map<java.lang.String, java.lang.Integer> r27 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.focusframe_MAP     // Catch: java.lang.Throwable -> L57
            java.util.Set r27 = r27.keySet()     // Catch: java.lang.Throwable -> L57
            java.util.Iterator r27 = r27.iterator()     // Catch: java.lang.Throwable -> L57
        L52c:
            boolean r28 = r27.hasNext()     // Catch: java.lang.Throwable -> L57
            if (r28 == 0) goto L630
            java.lang.Object r28 = r27.next()     // Catch: java.lang.Throwable -> L57
            r10 = r28
            java.lang.String r10 = (java.lang.String) r10     // Catch: java.lang.Throwable -> L57
            java.util.Map<java.lang.String, java.lang.Integer> r11 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.focusframe_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r11 = r11.get(r10)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r11 = (java.lang.Integer) r11     // Catch: java.lang.Throwable -> L57
            int r11 = r11.intValue()     // Catch: java.lang.Throwable -> L57
            int r29 = r10.hashCode()     // Catch: java.lang.Throwable -> L57
            switch(r29) {
                case -1229295104: goto L5c9;
                case -789642848: goto L5bf;
                case -456022910: goto L5b4;
                case 15642709: goto L5a9;
                case 214406230: goto L59e;
                case 1290627356: goto L594;
                case 1360403367: goto L589;
                case 1361291564: goto L57e;
                case 1426526545: goto L573;
                case 1426526550: goto L567;
                case 1426526561: goto L55b;
                case 2026068480: goto L54f;
                default: goto L54d;
            }     // Catch: java.lang.Throwable -> L57
        L54d:
            goto L5d4
        L54f:
            java.lang.String r12 = "focal_length"
            boolean r10 = r10.equals(r12)     // Catch: java.lang.Throwable -> L57
            if (r10 == 0) goto L5d4
            r10 = r17
            goto L5d6
        L55b:
            java.lang.String r12 = "focusframecolor_r"
            boolean r10 = r10.equals(r12)     // Catch: java.lang.Throwable -> L57
            if (r10 == 0) goto L5d4
            r10 = r23
            goto L5d6
        L567:
            java.lang.String r12 = "focusframecolor_g"
            boolean r10 = r10.equals(r12)     // Catch: java.lang.Throwable -> L57
            if (r10 == 0) goto L5d4
            r10 = r19
            goto L5d6
        L573:
            java.lang.String r12 = "focusframecolor_b"
            boolean r10 = r10.equals(r12)     // Catch: java.lang.Throwable -> L57
            if (r10 == 0) goto L5d4
            r10 = r25
            goto L5d6
        L57e:
            java.lang.String r12 = "focusframeshape"
            boolean r10 = r10.equals(r12)     // Catch: java.lang.Throwable -> L57
            if (r10 == 0) goto L5d4
            r10 = r20
            goto L5d6
        L589:
            java.lang.String r12 = "focusframeright"
            boolean r10 = r10.equals(r12)     // Catch: java.lang.Throwable -> L57
            if (r10 == 0) goto L5d4
            r10 = r22
            goto L5d6
        L594:
            java.lang.String r12 = "focusframeleft"
            boolean r10 = r10.equals(r12)     // Catch: java.lang.Throwable -> L57
            if (r10 == 0) goto L5d4
            r10 = 0
            goto L5d6
        L59e:
            java.lang.String r12 = "focasframe_transparency"
            boolean r10 = r10.equals(r12)     // Catch: java.lang.Throwable -> L57
            if (r10 == 0) goto L5d4
            r10 = r18
            goto L5d6
        L5a9:
            java.lang.String r12 = "focus_reserve"
            boolean r10 = r10.equals(r12)     // Catch: java.lang.Throwable -> L57
            if (r10 == 0) goto L5d4
            r10 = r16
            goto L5d6
        L5b4:
            java.lang.String r12 = "focustriangledisp"
            boolean r10 = r10.equals(r12)     // Catch: java.lang.Throwable -> L57
            if (r10 == 0) goto L5d4
            r10 = r21
            goto L5d6
        L5bf:
            java.lang.String r12 = "focusframetop"
            boolean r10 = r10.equals(r12)     // Catch: java.lang.Throwable -> L57
            if (r10 == 0) goto L5d4
            r10 = r8
            goto L5d6
        L5c9:
            java.lang.String r12 = "focusframebottom"
            boolean r10 = r10.equals(r12)     // Catch: java.lang.Throwable -> L57
            if (r10 == 0) goto L5d4
            r10 = r24
            goto L5d6
        L5d4:
            r10 = r26
        L5d6:
            switch(r10) {
                case 0: goto L627;
                case 1: goto L620;
                case 2: goto L619;
                case 3: goto L612;
                case 4: goto L60b;
                case 5: goto L604;
                case 6: goto L5fd;
                case 7: goto L5f6;
                case 8: goto L5ef;
                case 9: goto L5e8;
                case 10: goto L5e1;
                case 11: goto L5da;
                default: goto L5d9;
            }     // Catch: java.lang.Throwable -> L57
        L5d9:
            goto L62d
        L5da:
            java.lang.String r10 = r1.D(r2, r5, r11)     // Catch: java.lang.Throwable -> L57
            r4.focus_reserve = r10     // Catch: java.lang.Throwable -> L57
            goto L62d
        L5e1:
            java.lang.String r10 = r1.D(r2, r5, r11)     // Catch: java.lang.Throwable -> L57
            r4.focasframe_transparency = r10     // Catch: java.lang.Throwable -> L57
            goto L62d
        L5e8:
            java.lang.String r10 = r1.D(r2, r5, r11)     // Catch: java.lang.Throwable -> L57
            r4.focal_length = r10     // Catch: java.lang.Throwable -> L57
            goto L62d
        L5ef:
            java.lang.String r10 = r1.D(r2, r5, r11)     // Catch: java.lang.Throwable -> L57
            r4.focustriangledisp = r10     // Catch: java.lang.Throwable -> L57
            goto L62d
        L5f6:
            java.lang.String r10 = r1.D(r2, r5, r11)     // Catch: java.lang.Throwable -> L57
            r4.focusframeshape = r10     // Catch: java.lang.Throwable -> L57
            goto L62d
        L5fd:
            java.lang.String r10 = r1.D(r2, r5, r11)     // Catch: java.lang.Throwable -> L57
            r4.focusframecolor_b = r10     // Catch: java.lang.Throwable -> L57
            goto L62d
        L604:
            java.lang.String r10 = r1.D(r2, r5, r11)     // Catch: java.lang.Throwable -> L57
            r4.focusframecolor_g = r10     // Catch: java.lang.Throwable -> L57
            goto L62d
        L60b:
            java.lang.String r10 = r1.D(r2, r5, r11)     // Catch: java.lang.Throwable -> L57
            r4.focusframecolor_r = r10     // Catch: java.lang.Throwable -> L57
            goto L62d
        L612:
            java.lang.String r10 = r1.D(r2, r5, r11)     // Catch: java.lang.Throwable -> L57
            r4.focusframebottom = r10     // Catch: java.lang.Throwable -> L57
            goto L62d
        L619:
            java.lang.String r10 = r1.D(r2, r5, r11)     // Catch: java.lang.Throwable -> L57
            r4.focusframeright = r10     // Catch: java.lang.Throwable -> L57
            goto L62d
        L620:
            java.lang.String r10 = r1.D(r2, r5, r11)     // Catch: java.lang.Throwable -> L57
            r4.focusframetop = r10     // Catch: java.lang.Throwable -> L57
            goto L62d
        L627:
            java.lang.String r10 = r1.D(r2, r5, r11)     // Catch: java.lang.Throwable -> L57
            r4.focusframeleft = r10     // Catch: java.lang.Throwable -> L57
        L62d:
            int r5 = r5 + r11
            goto L52c
        L630:
            java.util.List<com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager$FocusFrame> r10 = r1.focusFrameList     // Catch: java.lang.Throwable -> L57
            r10.add(r4)     // Catch: java.lang.Throwable -> L57
            int r9 = r9 + 1
            r4 = 16
            goto L51b
        L63b:
            java.util.Map<java.lang.String, java.lang.Integer> r4 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r4 = r4.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r4 = (java.lang.Integer) r4     // Catch: java.lang.Throwable -> L57
            int r4 = r4.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r7 = r1.D(r2, r5, r4)     // Catch: java.lang.Throwable -> L57
            r1.Av_max_1 = r7     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r4
        L64e:
            java.util.Map<java.lang.String, java.lang.Integer> r4 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r4 = r4.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r4 = (java.lang.Integer) r4     // Catch: java.lang.Throwable -> L57
            int r4 = r4.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r7 = r1.D(r2, r5, r4)     // Catch: java.lang.Throwable -> L57
            r1.Av_max_2 = r7     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r4
        L661:
            java.util.Map<java.lang.String, java.lang.Integer> r4 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r4 = r4.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r4 = (java.lang.Integer) r4     // Catch: java.lang.Throwable -> L57
            int r4 = r4.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r7 = r1.D(r2, r5, r4)     // Catch: java.lang.Throwable -> L57
            r1.Av_min_1 = r7     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r4
        L674:
            java.util.Map<java.lang.String, java.lang.Integer> r4 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r4 = r4.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r4 = (java.lang.Integer) r4     // Catch: java.lang.Throwable -> L57
            int r4 = r4.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r7 = r1.D(r2, r5, r4)     // Catch: java.lang.Throwable -> L57
            r1.Av_min_2 = r7     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r4
        L687:
            java.util.Map<java.lang.String, java.lang.Integer> r4 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r4 = r4.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r4 = (java.lang.Integer) r4     // Catch: java.lang.Throwable -> L57
            int r4 = r4.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r7 = r1.D(r2, r5, r4)     // Catch: java.lang.Throwable -> L57
            r1.Av_current_1 = r7     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r4
        L69a:
            java.util.Map<java.lang.String, java.lang.Integer> r4 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r4 = r4.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r4 = (java.lang.Integer) r4     // Catch: java.lang.Throwable -> L57
            int r4 = r4.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r7 = r1.D(r2, r5, r4)     // Catch: java.lang.Throwable -> L57
            r1.Av_current_2 = r7     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r4
        L6ad:
            java.util.Map<java.lang.String, java.lang.Integer> r4 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r4 = r4.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r4 = (java.lang.Integer) r4     // Catch: java.lang.Throwable -> L57
            int r4 = r4.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r7 = r1.D(r2, r5, r4)     // Catch: java.lang.Throwable -> L57
            r1.Tv_max_1 = r7     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r4
        L6c0:
            java.util.Map<java.lang.String, java.lang.Integer> r4 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r4 = r4.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r4 = (java.lang.Integer) r4     // Catch: java.lang.Throwable -> L57
            int r4 = r4.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r7 = r1.D(r2, r5, r4)     // Catch: java.lang.Throwable -> L57
            r1.Tv_max_2 = r7     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r4
        L6d3:
            java.util.Map<java.lang.String, java.lang.Integer> r4 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r4 = r4.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r4 = (java.lang.Integer) r4     // Catch: java.lang.Throwable -> L57
            int r4 = r4.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r7 = r1.D(r2, r5, r4)     // Catch: java.lang.Throwable -> L57
            r1.Tv_min_1 = r7     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r4
        L6e6:
            java.util.Map<java.lang.String, java.lang.Integer> r4 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r4 = r4.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r4 = (java.lang.Integer) r4     // Catch: java.lang.Throwable -> L57
            int r4 = r4.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r7 = r1.D(r2, r5, r4)     // Catch: java.lang.Throwable -> L57
            r1.Tv_min_2 = r7     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r4
        L6f9:
            java.util.Map<java.lang.String, java.lang.Integer> r4 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r4 = r4.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r4 = (java.lang.Integer) r4     // Catch: java.lang.Throwable -> L57
            int r4 = r4.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r7 = r1.D(r2, r5, r4)     // Catch: java.lang.Throwable -> L57
            r1.Tv_current_1 = r7     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r4
        L70c:
            java.util.Map<java.lang.String, java.lang.Integer> r4 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r4 = r4.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r4 = (java.lang.Integer) r4     // Catch: java.lang.Throwable -> L57
            int r4 = r4.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r7 = r1.D(r2, r5, r4)     // Catch: java.lang.Throwable -> L57
            r1.Tv_current_2 = r7     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r4
        L71f:
            java.util.Map<java.lang.String, java.lang.Integer> r4 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r4 = r4.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r4 = (java.lang.Integer) r4     // Catch: java.lang.Throwable -> L57
            int r4 = r4.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r7 = r1.D(r2, r5, r4)     // Catch: java.lang.Throwable -> L57
            r1.Sv_max_1 = r7     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r4
        L732:
            java.util.Map<java.lang.String, java.lang.Integer> r4 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r4 = r4.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r4 = (java.lang.Integer) r4     // Catch: java.lang.Throwable -> L57
            int r4 = r4.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r7 = r1.D(r2, r5, r4)     // Catch: java.lang.Throwable -> L57
            r1.Sv_max_2 = r7     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r4
        L745:
            java.util.Map<java.lang.String, java.lang.Integer> r4 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r4 = r4.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r4 = (java.lang.Integer) r4     // Catch: java.lang.Throwable -> L57
            int r4 = r4.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r7 = r1.D(r2, r5, r4)     // Catch: java.lang.Throwable -> L57
            r1.Sv_min_1 = r7     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r4
        L758:
            java.util.Map<java.lang.String, java.lang.Integer> r4 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r4 = r4.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r4 = (java.lang.Integer) r4     // Catch: java.lang.Throwable -> L57
            int r4 = r4.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r7 = r1.D(r2, r5, r4)     // Catch: java.lang.Throwable -> L57
            r1.Sv_min_2 = r7     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r4
        L76b:
            java.util.Map<java.lang.String, java.lang.Integer> r4 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r4 = r4.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r4 = (java.lang.Integer) r4     // Catch: java.lang.Throwable -> L57
            int r4 = r4.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r7 = r1.D(r2, r5, r4)     // Catch: java.lang.Throwable -> L57
            r1.Sv_current_1 = r7     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r4
        L77e:
            java.util.Map<java.lang.String, java.lang.Integer> r4 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r4 = r4.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r4 = (java.lang.Integer) r4     // Catch: java.lang.Throwable -> L57
            int r4 = r4.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r7 = r1.D(r2, r5, r4)     // Catch: java.lang.Throwable -> L57
            r1.Sv_current_2 = r7     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r4
        L791:
            java.util.Map<java.lang.String, java.lang.Integer> r4 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r4 = r4.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r4 = (java.lang.Integer) r4     // Catch: java.lang.Throwable -> L57
            int r4 = r4.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r7 = r1.D(r2, r5, r4)     // Catch: java.lang.Throwable -> L57
            r1.currentexposure = r7     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r4
        L7a4:
            java.util.Map<java.lang.String, java.lang.Integer> r4 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r4 = r4.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r4 = (java.lang.Integer) r4     // Catch: java.lang.Throwable -> L57
            int r4 = r4.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r7 = r1.D(r2, r5, r4)     // Catch: java.lang.Throwable -> L57
            r1.crntfocaldist = r7     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r4
        L7b7:
            java.util.Map<java.lang.String, java.lang.Integer> r4 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r4 = r4.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r4 = (java.lang.Integer) r4     // Catch: java.lang.Throwable -> L57
            int r4 = r4.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r7 = r1.D(r2, r5, r4)     // Catch: java.lang.Throwable -> L57
            r1.crntEXzoom = r7     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r4
        L7ca:
            java.util.Map<java.lang.String, java.lang.Integer> r4 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r4 = r4.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r4 = (java.lang.Integer) r4     // Catch: java.lang.Throwable -> L57
            int r4 = r4.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r7 = r1.D(r2, r5, r4)     // Catch: java.lang.Throwable -> L57
            r1.numIconCont = r7     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r4
            java.util.List<com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager$IconCont> r4 = r1.iconContList     // Catch: java.lang.Throwable -> L57
            r4.clear()     // Catch: java.lang.Throwable -> L57
            r4 = 0
        L7e3:
            if (r4 >= r8) goto L8c6
            com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager$IconCont r7 = new com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager$IconCont     // Catch: java.lang.Throwable -> L57
            r7.<init>()     // Catch: java.lang.Throwable -> L57
            java.util.Map<java.lang.String, java.lang.Integer> r9 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.iconCont_MAP     // Catch: java.lang.Throwable -> L57
            java.util.Set r9 = r9.keySet()     // Catch: java.lang.Throwable -> L57
            java.util.Iterator r9 = r9.iterator()     // Catch: java.lang.Throwable -> L57
        L7f4:
            boolean r10 = r9.hasNext()     // Catch: java.lang.Throwable -> L57
            if (r10 == 0) goto L8bd
            java.lang.Object r10 = r9.next()     // Catch: java.lang.Throwable -> L57
            java.lang.String r10 = (java.lang.String) r10     // Catch: java.lang.Throwable -> L57
            java.util.Map<java.lang.String, java.lang.Integer> r11 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.iconCont_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r11 = r11.get(r10)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r11 = (java.lang.Integer) r11     // Catch: java.lang.Throwable -> L57
            int r11 = r11.intValue()     // Catch: java.lang.Throwable -> L57
            int r12 = r10.hashCode()     // Catch: java.lang.Throwable -> L57
            switch(r12) {
                case -2113920116: goto L86b;
                case -1389104516: goto L860;
                case -907989398: goto L855;
                case -345291033: goto L84a;
                case -331239923: goto L83f;
                case 1727257183: goto L834;
                case 1917099783: goto L82a;
                case 1917099784: goto L820;
                case 2022791806: goto L815;
                default: goto L813;
            }     // Catch: java.lang.Throwable -> L57
        L813:
            goto L876
        L815:
            java.lang.String r12 = "batteryBase"
            boolean r10 = r10.equals(r12)     // Catch: java.lang.Throwable -> L57
            if (r10 == 0) goto L876
            r10 = r25
            goto L878
        L820:
            java.lang.String r12 = "sdIcon2"
            boolean r10 = r10.equals(r12)     // Catch: java.lang.Throwable -> L57
            if (r10 == 0) goto L876
            r10 = r8
            goto L878
        L82a:
            java.lang.String r12 = "sdIcon1"
            boolean r10 = r10.equals(r12)     // Catch: java.lang.Throwable -> L57
            if (r10 == 0) goto L876
            r10 = 0
            goto L878
        L834:
            java.lang.String r12 = "batteryBackgroud"
            boolean r10 = r10.equals(r12)     // Catch: java.lang.Throwable -> L57
            if (r10 == 0) goto L876
            r10 = r20
            goto L878
        L83f:
            java.lang.String r12 = "battery"
            boolean r10 = r10.equals(r12)     // Catch: java.lang.Throwable -> L57
            if (r10 == 0) goto L876
            r10 = r19
            goto L878
        L84a:
            java.lang.String r12 = "shootNum"
            boolean r10 = r10.equals(r12)     // Catch: java.lang.Throwable -> L57
            if (r10 == 0) goto L876
            r10 = r24
            goto L878
        L855:
            java.lang.String r12 = "sdIcon"
            boolean r10 = r10.equals(r12)     // Catch: java.lang.Throwable -> L57
            if (r10 == 0) goto L876
            r10 = r22
            goto L878
        L860:
            java.lang.String r12 = "shootingIcon"
            boolean r10 = r10.equals(r12)     // Catch: java.lang.Throwable -> L57
            if (r10 == 0) goto L876
            r10 = r21
            goto L878
        L86b:
            java.lang.String r12 = "shootTime"
            boolean r10 = r10.equals(r12)     // Catch: java.lang.Throwable -> L57
            if (r10 == 0) goto L876
            r10 = r23
            goto L878
        L876:
            r10 = r26
        L878:
            switch(r10) {
                case 0: goto L8b4;
                case 1: goto L8ad;
                case 2: goto L8a6;
                case 3: goto L89f;
                case 4: goto L898;
                case 5: goto L891;
                case 6: goto L88a;
                case 7: goto L883;
                case 8: goto L87c;
                default: goto L87b;
            }     // Catch: java.lang.Throwable -> L57
        L87b:
            goto L8ba
        L87c:
            java.lang.String r10 = r1.D(r2, r5, r11)     // Catch: java.lang.Throwable -> L57
            r7.shootingIcon = r10     // Catch: java.lang.Throwable -> L57
            goto L8ba
        L883:
            java.lang.String r10 = r1.D(r2, r5, r11)     // Catch: java.lang.Throwable -> L57
            r7.batteryBackgroud = r10     // Catch: java.lang.Throwable -> L57
            goto L8ba
        L88a:
            java.lang.String r10 = r1.D(r2, r5, r11)     // Catch: java.lang.Throwable -> L57
            r7.batteryBase = r10     // Catch: java.lang.Throwable -> L57
            goto L8ba
        L891:
            java.lang.String r10 = r1.D(r2, r5, r11)     // Catch: java.lang.Throwable -> L57
            r7.battery = r10     // Catch: java.lang.Throwable -> L57
            goto L8ba
        L898:
            java.lang.String r10 = r1.D(r2, r5, r11)     // Catch: java.lang.Throwable -> L57
            r7.shootTime = r10     // Catch: java.lang.Throwable -> L57
            goto L8ba
        L89f:
            java.lang.String r10 = r1.D(r2, r5, r11)     // Catch: java.lang.Throwable -> L57
            r7.shootNum = r10     // Catch: java.lang.Throwable -> L57
            goto L8ba
        L8a6:
            java.lang.String r10 = r1.D(r2, r5, r11)     // Catch: java.lang.Throwable -> L57
            r7.sdIcon = r10     // Catch: java.lang.Throwable -> L57
            goto L8ba
        L8ad:
            java.lang.String r10 = r1.D(r2, r5, r11)     // Catch: java.lang.Throwable -> L57
            r7.sdIcon2 = r10     // Catch: java.lang.Throwable -> L57
            goto L8ba
        L8b4:
            java.lang.String r10 = r1.D(r2, r5, r11)     // Catch: java.lang.Throwable -> L57
            r7.sdIcon1 = r10     // Catch: java.lang.Throwable -> L57
        L8ba:
            int r5 = r5 + r11
            goto L7f4
        L8bd:
            java.util.List<com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager$IconCont> r9 = r1.iconContList     // Catch: java.lang.Throwable -> L57
            r9.add(r7)     // Catch: java.lang.Throwable -> L57
            int r4 = r4 + 1
            goto L7e3
        L8c6:
            java.util.Map<java.lang.String, java.lang.Integer> r4 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r4 = r4.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r4 = (java.lang.Integer) r4     // Catch: java.lang.Throwable -> L57
            int r4 = r4.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r7 = r1.D(r2, r5, r4)     // Catch: java.lang.Throwable -> L57
            r1.processingstate = r7     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r4
        L8d9:
            java.util.Map<java.lang.String, java.lang.Integer> r4 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r4 = r4.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r4 = (java.lang.Integer) r4     // Catch: java.lang.Throwable -> L57
            int r4 = r4.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r7 = r1.D(r2, r5, r4)     // Catch: java.lang.Throwable -> L57
            r1.assist_ID = r7     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r4
        L8ec:
            java.util.Map<java.lang.String, java.lang.Integer> r4 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r4 = r4.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r4 = (java.lang.Integer) r4     // Catch: java.lang.Throwable -> L57
            int r4 = r4.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r7 = r1.D(r2, r5, r4)     // Catch: java.lang.Throwable -> L57
            r1.touch_AE_button = r7     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r4
        L8ff:
            java.util.Map<java.lang.String, java.lang.Integer> r4 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r4 = r4.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r4 = (java.lang.Integer) r4     // Catch: java.lang.Throwable -> L57
            int r4 = r4.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r7 = r1.D(r2, r5, r4)     // Catch: java.lang.Throwable -> L57
            r1.Shut_state = r7     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r4
        L912:
            java.util.Map<java.lang.String, java.lang.Integer> r4 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r4 = r4.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r4 = (java.lang.Integer) r4     // Catch: java.lang.Throwable -> L57
            int r4 = r4.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r7 = r1.D(r2, r5, r4)     // Catch: java.lang.Throwable -> L57
            r1.noise_reduction_time = r7     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r4
        L925:
            java.util.Map<java.lang.String, java.lang.Integer> r4 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r4 = r4.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r4 = (java.lang.Integer) r4     // Catch: java.lang.Throwable -> L57
            int r4 = r4.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r7 = r1.D(r2, r5, r4)     // Catch: java.lang.Throwable -> L57
            r1.exflag3_vh = r7     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r4
        L938:
            java.util.Map<java.lang.String, java.lang.Integer> r4 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r4 = r4.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r4 = (java.lang.Integer) r4     // Catch: java.lang.Throwable -> L57
            int r4 = r4.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r7 = r1.D(r2, r5, r4)     // Catch: java.lang.Throwable -> L57
            r1.exflag3 = r7     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r4
        L94b:
            java.util.Map<java.lang.String, java.lang.Integer> r4 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r4 = r4.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r4 = (java.lang.Integer) r4     // Catch: java.lang.Throwable -> L57
            int r4 = r4.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r7 = r1.D(r2, r5, r4)     // Catch: java.lang.Throwable -> L57
            r1.buff_size = r7     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r4
        L95e:
            java.util.Map<java.lang.String, java.lang.Integer> r4 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r4 = r4.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r4 = (java.lang.Integer) r4     // Catch: java.lang.Throwable -> L57
            int r4 = r4.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r7 = r1.D(r2, r5, r4)     // Catch: java.lang.Throwable -> L57
            r1.touchaf_button = r7     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r4
        L971:
            java.util.Map<java.lang.String, java.lang.Integer> r4 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r4 = r4.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r4 = (java.lang.Integer) r4     // Catch: java.lang.Throwable -> L57
            int r4 = r4.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r7 = r1.D(r2, r5, r4)     // Catch: java.lang.Throwable -> L57
            r1.interval_state = r7     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r4
        L984:
            java.util.Map<java.lang.String, java.lang.Integer> r4 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r4 = r4.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r4 = (java.lang.Integer) r4     // Catch: java.lang.Throwable -> L57
            int r4 = r4.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r7 = r1.D(r2, r5, r4)     // Catch: java.lang.Throwable -> L57
            r1.lens_mount = r7     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r4
        L997:
            java.util.Map<java.lang.String, java.lang.Integer> r4 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r4 = r4.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r4 = (java.lang.Integer) r4     // Catch: java.lang.Throwable -> L57
            int r4 = r4.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r7 = r1.D(r2, r5, r4)     // Catch: java.lang.Throwable -> L57
            r1.reserve0C = r7     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r4
        L9aa:
            java.util.Map<java.lang.String, java.lang.Integer> r4 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.FILED_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r4 = r4.get(r6)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r4 = (java.lang.Integer) r4     // Catch: java.lang.Throwable -> L57
            int r4 = r4.intValue()     // Catch: java.lang.Throwable -> L57
            java.lang.String r6 = r1.D(r2, r5, r4)     // Catch: java.lang.Throwable -> L57
            r1.numSettingValue = r6     // Catch: java.lang.Throwable -> L57
            int r5 = r5 + r4
            java.util.List<com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager$SettingValue> r4 = r1.settingValueList     // Catch: java.lang.Throwable -> L57
            r4.clear()     // Catch: java.lang.Throwable -> L57
            r4 = 0
        L9c3:
            if (r4 >= r8) goto L17
            com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager$SettingValue r6 = new com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager$SettingValue     // Catch: java.lang.Throwable -> L57
            r6.<init>()     // Catch: java.lang.Throwable -> L57
            java.util.Map<java.lang.String, java.lang.Integer> r7 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.settingValue_MAP     // Catch: java.lang.Throwable -> L57
            java.util.Set r7 = r7.keySet()     // Catch: java.lang.Throwable -> L57
            java.util.Iterator r7 = r7.iterator()     // Catch: java.lang.Throwable -> L57
        L9d4:
            boolean r9 = r7.hasNext()     // Catch: java.lang.Throwable -> L57
            if (r9 == 0) goto Lc11
            java.lang.Object r9 = r7.next()     // Catch: java.lang.Throwable -> L57
            java.lang.String r9 = (java.lang.String) r9     // Catch: java.lang.Throwable -> L57
            java.util.Map<java.lang.String, java.lang.Integer> r10 = com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager.BASE_DATA.settingValue_MAP     // Catch: java.lang.Throwable -> L57
            java.lang.Object r10 = r10.get(r9)     // Catch: java.lang.Throwable -> L57
            java.lang.Integer r10 = (java.lang.Integer) r10     // Catch: java.lang.Throwable -> L57
            int r10 = r10.intValue()     // Catch: java.lang.Throwable -> L57
            int r11 = r9.hashCode()     // Catch: java.lang.Throwable -> L57
            switch(r11) {
                case -1926005497: goto Lb2d;
                case -1671960711: goto Lb22;
                case -1552957656: goto Lb17;
                case -1472788522: goto Lb0c;
                case -1444159371: goto Lb01;
                case -1420383416: goto Laf6;
                case -1366426067: goto Laeb;
                case -1326562030: goto Lae0;
                case -1160594396: goto Lad6;
                case -801170338: goto Laca;
                case -801170337: goto Labe;
                case -489099585: goto Lab2;
                case 3198: goto Laa6;
                case 104581: goto La9a;
                case 23859919: goto La8e;
                case 63944192: goto La82;
                case 109641131: goto La76;
                case 356164148: goto La6b;
                case 651215103: goto La5f;
                case 787952682: goto La53;
                case 1121727155: goto La47;
                case 1183434220: goto La3c;
                case 1257110646: goto La30;
                case 1497191059: goto La24;
                case 1582269490: goto La18;
                case 1629381243: goto La0c;
                case 1634564800: goto La00;
                case 1683748818: goto L9f5;
                default: goto L9f3;
            }     // Catch: java.lang.Throwable -> L57
        L9f3:
            goto Lb37
        L9f5:
            java.lang.String r11 = "dualNativeIso"
            boolean r9 = r9.equals(r11)     // Catch: java.lang.Throwable -> L57
            if (r9 == 0) goto Lb37
            r9 = r14
            goto Lb39
        La00:
            java.lang.String r11 = "realtimelut"
            boolean r9 = r9.equals(r11)     // Catch: java.lang.Throwable -> L57
            if (r9 == 0) goto Lb37
            r9 = 18
            goto Lb39
        La0c:
            java.lang.String r11 = "focusmode"
            boolean r9 = r9.equals(r11)     // Catch: java.lang.Throwable -> L57
            if (r9 == 0) goto Lb37
            r9 = r17
            goto Lb39
        La18:
            java.lang.String r11 = "videoformat"
            boolean r9 = r9.equals(r11)     // Catch: java.lang.Throwable -> L57
            if (r9 == 0) goto Lb37
            r9 = r16
            goto Lb39
        La24:
            java.lang.String r11 = "whitebalance"
            boolean r9 = r9.equals(r11)     // Catch: java.lang.Throwable -> L57
            if (r9 == 0) goto Lb37
            r9 = r23
            goto Lb39
        La30:
            java.lang.String r11 = "intervalMotionState"
            boolean r9 = r9.equals(r11)     // Catch: java.lang.Throwable -> L57
            if (r9 == 0) goto Lb37
            r9 = 24
            goto Lb39
        La3c:
            java.lang.String r11 = "hrsMode"
            boolean r9 = r9.equals(r11)     // Catch: java.lang.Throwable -> L57
            if (r9 == 0) goto Lb37
            r9 = r15
            goto Lb39
        La47:
            java.lang.String r11 = "aspectratio"
            boolean r9 = r9.equals(r11)     // Catch: java.lang.Throwable -> L57
            if (r9 == 0) goto Lb37
            r9 = 13
            goto Lb39
        La53:
            java.lang.String r11 = "selftimercustom"
            boolean r9 = r9.equals(r11)     // Catch: java.lang.Throwable -> L57
            if (r9 == 0) goto Lb37
            r9 = 20
            goto Lb39
        La5f:
            java.lang.String r11 = "quality"
            boolean r9 = r9.equals(r11)     // Catch: java.lang.Throwable -> L57
            if (r9 == 0) goto Lb37
            r9 = r18
            goto Lb39
        La6b:
            java.lang.String r11 = "ss_angle"
            boolean r9 = r9.equals(r11)     // Catch: java.lang.Throwable -> L57
            if (r9 == 0) goto Lb37
            r9 = r8
            goto Lb39
        La76:
            java.lang.String r11 = "sqFPS"
            boolean r9 = r9.equals(r11)     // Catch: java.lang.Throwable -> L57
            if (r9 == 0) goto Lb37
            r9 = 25
            goto Lb39
        La82:
            java.lang.String r11 = "recmode2value2"
            boolean r9 = r9.equals(r11)     // Catch: java.lang.Throwable -> L57
            if (r9 == 0) goto Lb37
            r9 = r20
            goto Lb39
        La8e:
            java.lang.String r11 = "lightmetering"
            boolean r9 = r9.equals(r11)     // Catch: java.lang.Throwable -> L57
            if (r9 == 0) goto Lb37
            r9 = 16
            goto Lb39
        La9a:
            java.lang.String r11 = "iso"
            boolean r9 = r9.equals(r11)     // Catch: java.lang.Throwable -> L57
            if (r9 == 0) goto Lb37
            r9 = r22
            goto Lb39
        Laa6:
            java.lang.String r11 = "db"
            boolean r9 = r9.equals(r11)     // Catch: java.lang.Throwable -> L57
            if (r9 == 0) goto Lb37
            r9 = r24
            goto Lb39
        Lab2:
            java.lang.String r11 = "photostyle"
            boolean r9 = r9.equals(r11)     // Catch: java.lang.Throwable -> L57
            if (r9 == 0) goto Lb37
            r9 = r21
            goto Lb39
        Labe:
            java.lang.String r11 = "recmode2"
            boolean r9 = r9.equals(r11)     // Catch: java.lang.Throwable -> L57
            if (r9 == 0) goto Lb37
            r9 = r25
            goto Lb39
        Laca:
            java.lang.String r11 = "recmode1"
            boolean r9 = r9.equals(r11)     // Catch: java.lang.Throwable -> L57
            if (r9 == 0) goto Lb37
            r9 = r19
            goto Lb39
        Lad6:
            java.lang.String r11 = "videoquality"
            boolean r9 = r9.equals(r11)     // Catch: java.lang.Throwable -> L57
            if (r9 == 0) goto Lb37
            r9 = r13
            goto Lb39
        Lae0:
            java.lang.String r11 = "liveviewsize"
            boolean r9 = r9.equals(r11)     // Catch: java.lang.Throwable -> L57
            if (r9 == 0) goto Lb37
            r9 = 17
            goto Lb39
        Laeb:
            java.lang.String r11 = "drivemode"
            boolean r9 = r9.equals(r11)     // Catch: java.lang.Throwable -> L57
            if (r9 == 0) goto Lb37
            r9 = 14
            goto Lb39
        Laf6:
            java.lang.String r11 = "afmode"
            boolean r9 = r9.equals(r11)     // Catch: java.lang.Throwable -> L57
            if (r9 == 0) goto Lb37
            r9 = 21
            goto Lb39
        Lb01:
            java.lang.String r11 = "burst2speed"
            boolean r9 = r9.equals(r11)     // Catch: java.lang.Throwable -> L57
            if (r9 == 0) goto Lb37
            r9 = 23
            goto Lb39
        Lb0c:
            java.lang.String r11 = "burst1speed"
            boolean r9 = r9.equals(r11)     // Catch: java.lang.Throwable -> L57
            if (r9 == 0) goto Lb37
            r9 = 22
            goto Lb39
        Lb17:
            java.lang.String r11 = "operatepriority"
            boolean r9 = r9.equals(r11)     // Catch: java.lang.Throwable -> L57
            if (r9 == 0) goto Lb37
            r9 = 19
            goto Lb39
        Lb22:
            java.lang.String r11 = "selftimer"
            boolean r9 = r9.equals(r11)     // Catch: java.lang.Throwable -> L57
            if (r9 == 0) goto Lb37
            r9 = 15
            goto Lb39
        Lb2d:
            java.lang.String r11 = "exposure"
            boolean r9 = r9.equals(r11)     // Catch: java.lang.Throwable -> L57
            if (r9 == 0) goto Lb37
            r9 = 0
            goto Lb39
        Lb37:
            r9 = r26
        Lb39:
            switch(r9) {
                case 0: goto Lc08;
                case 1: goto Lc01;
                case 2: goto Lbfa;
                case 3: goto Lbf3;
                case 4: goto Lbec;
                case 5: goto Lbe5;
                case 6: goto Lbde;
                case 7: goto Lbd7;
                case 8: goto Lbd0;
                case 9: goto Lbc9;
                case 10: goto Lbc2;
                case 11: goto Lbbb;
                case 12: goto Lbb4;
                case 13: goto Lbad;
                case 14: goto Lba6;
                case 15: goto Lb9e;
                case 16: goto Lb96;
                case 17: goto Lb8e;
                case 18: goto Lb86;
                case 19: goto Lb7e;
                case 20: goto Lb76;
                case 21: goto Lb6e;
                case 22: goto Lb66;
                case 23: goto Lb5e;
                case 24: goto Lb56;
                case 25: goto Lb4e;
                case 26: goto Lb46;
                case 27: goto Lb3e;
                default: goto Lb3c;
            }     // Catch: java.lang.Throwable -> L57
        Lb3c:
            goto Lc0e
        Lb3e:
            java.lang.String r9 = r1.D(r2, r5, r10)     // Catch: java.lang.Throwable -> L57
            r6.hrsMode = r9     // Catch: java.lang.Throwable -> L57
            goto Lc0e
        Lb46:
            java.lang.String r9 = r1.D(r2, r5, r10)     // Catch: java.lang.Throwable -> L57
            r6.dualNativeIso = r9     // Catch: java.lang.Throwable -> L57
            goto Lc0e
        Lb4e:
            java.lang.String r9 = r1.D(r2, r5, r10)     // Catch: java.lang.Throwable -> L57
            r6.sqFPS = r9     // Catch: java.lang.Throwable -> L57
            goto Lc0e
        Lb56:
            java.lang.String r9 = r1.D(r2, r5, r10)     // Catch: java.lang.Throwable -> L57
            r6.intervalMotionState = r9     // Catch: java.lang.Throwable -> L57
            goto Lc0e
        Lb5e:
            java.lang.String r9 = r1.D(r2, r5, r10)     // Catch: java.lang.Throwable -> L57
            r6.burst2speed = r9     // Catch: java.lang.Throwable -> L57
            goto Lc0e
        Lb66:
            java.lang.String r9 = r1.D(r2, r5, r10)     // Catch: java.lang.Throwable -> L57
            r6.burst1speed = r9     // Catch: java.lang.Throwable -> L57
            goto Lc0e
        Lb6e:
            java.lang.String r9 = r1.D(r2, r5, r10)     // Catch: java.lang.Throwable -> L57
            r6.afmode = r9     // Catch: java.lang.Throwable -> L57
            goto Lc0e
        Lb76:
            java.lang.String r9 = r1.D(r2, r5, r10)     // Catch: java.lang.Throwable -> L57
            r6.selftimercustom = r9     // Catch: java.lang.Throwable -> L57
            goto Lc0e
        Lb7e:
            java.lang.String r9 = r1.D(r2, r5, r10)     // Catch: java.lang.Throwable -> L57
            r6.operatepriority = r9     // Catch: java.lang.Throwable -> L57
            goto Lc0e
        Lb86:
            java.lang.String r9 = r1.D(r2, r5, r10)     // Catch: java.lang.Throwable -> L57
            r6.realtimelut = r9     // Catch: java.lang.Throwable -> L57
            goto Lc0e
        Lb8e:
            java.lang.String r9 = r1.D(r2, r5, r10)     // Catch: java.lang.Throwable -> L57
            r6.liveviewsize = r9     // Catch: java.lang.Throwable -> L57
            goto Lc0e
        Lb96:
            java.lang.String r9 = r1.D(r2, r5, r10)     // Catch: java.lang.Throwable -> L57
            r6.lightmetering = r9     // Catch: java.lang.Throwable -> L57
            goto Lc0e
        Lb9e:
            java.lang.String r9 = r1.D(r2, r5, r10)     // Catch: java.lang.Throwable -> L57
            r6.selftimer = r9     // Catch: java.lang.Throwable -> L57
            goto Lc0e
        Lba6:
            java.lang.String r9 = r1.D(r2, r5, r10)     // Catch: java.lang.Throwable -> L57
            r6.drivemode = r9     // Catch: java.lang.Throwable -> L57
            goto Lc0e
        Lbad:
            java.lang.String r9 = r1.D(r2, r5, r10)     // Catch: java.lang.Throwable -> L57
            r6.aspectratio = r9     // Catch: java.lang.Throwable -> L57
            goto Lc0e
        Lbb4:
            java.lang.String r9 = r1.D(r2, r5, r10)     // Catch: java.lang.Throwable -> L57
            r6.videoquality = r9     // Catch: java.lang.Throwable -> L57
            goto Lc0e
        Lbbb:
            java.lang.String r9 = r1.D(r2, r5, r10)     // Catch: java.lang.Throwable -> L57
            r6.videoformat = r9     // Catch: java.lang.Throwable -> L57
            goto Lc0e
        Lbc2:
            java.lang.String r9 = r1.D(r2, r5, r10)     // Catch: java.lang.Throwable -> L57
            r6.quality = r9     // Catch: java.lang.Throwable -> L57
            goto Lc0e
        Lbc9:
            java.lang.String r9 = r1.D(r2, r5, r10)     // Catch: java.lang.Throwable -> L57
            r6.focusmode = r9     // Catch: java.lang.Throwable -> L57
            goto Lc0e
        Lbd0:
            java.lang.String r9 = r1.D(r2, r5, r10)     // Catch: java.lang.Throwable -> L57
            r6.photostyle = r9     // Catch: java.lang.Throwable -> L57
            goto Lc0e
        Lbd7:
            java.lang.String r9 = r1.D(r2, r5, r10)     // Catch: java.lang.Throwable -> L57
            r6.recmode2value2 = r9     // Catch: java.lang.Throwable -> L57
            goto Lc0e
        Lbde:
            java.lang.String r9 = r1.D(r2, r5, r10)     // Catch: java.lang.Throwable -> L57
            r6.recmode2 = r9     // Catch: java.lang.Throwable -> L57
            goto Lc0e
        Lbe5:
            java.lang.String r9 = r1.D(r2, r5, r10)     // Catch: java.lang.Throwable -> L57
            r6.recmode1 = r9     // Catch: java.lang.Throwable -> L57
            goto Lc0e
        Lbec:
            java.lang.String r9 = r1.D(r2, r5, r10)     // Catch: java.lang.Throwable -> L57
            r6.whitebalance = r9     // Catch: java.lang.Throwable -> L57
            goto Lc0e
        Lbf3:
            java.lang.String r9 = r1.D(r2, r5, r10)     // Catch: java.lang.Throwable -> L57
            r6.db = r9     // Catch: java.lang.Throwable -> L57
            goto Lc0e
        Lbfa:
            java.lang.String r9 = r1.D(r2, r5, r10)     // Catch: java.lang.Throwable -> L57
            r6.iso = r9     // Catch: java.lang.Throwable -> L57
            goto Lc0e
        Lc01:
            java.lang.String r9 = r1.D(r2, r5, r10)     // Catch: java.lang.Throwable -> L57
            r6.ssAngle = r9     // Catch: java.lang.Throwable -> L57
            goto Lc0e
        Lc08:
            java.lang.String r9 = r1.D(r2, r5, r10)     // Catch: java.lang.Throwable -> L57
            r6.exposure = r9     // Catch: java.lang.Throwable -> L57
        Lc0e:
            int r5 = r5 + r10
            goto L9d4
        Lc11:
            java.util.List<com.panasonic.jp.flow.wireless.udp.RemoteUDPPacketManager$SettingValue> r7 = r1.settingValueList     // Catch: java.lang.Throwable -> L57
            r7.add(r6)     // Catch: java.lang.Throwable -> L57
            int r4 = r4 + 1
            goto L9c3
        Lc1a:
            java.lang.String r3 = r1.totaldatasize     // Catch: java.lang.Throwable -> L57
            java.lang.String r4 = "ffffffff"
            boolean r3 = com.panasonic.jp.flow.wireless.util.AppUtilManager.isHexStringEqual(r3, r4)     // Catch: java.lang.Throwable -> L57
            if (r3 == 0) goto Lc2b
            byte[] r2 = r30.loadBitmap(r31)     // Catch: java.lang.Throwable -> L57
            r1.bitmapData = r2     // Catch: java.lang.Throwable -> L57
            goto Lc3e
        Lc2b:
            java.lang.String r3 = r1.totaldatasize     // Catch: java.lang.Throwable -> L57
            java.lang.String r4 = r1.exheadersize     // Catch: java.lang.Throwable -> L57
            byte[] r2 = r1.loadBitmap(r2, r3, r4)     // Catch: java.lang.Throwable -> L57
            r1.bitmapData = r2     // Catch: java.lang.Throwable -> L57
            goto Lc3e
        Lc36:
            java.lang.String r3 = r1.TAG     // Catch: java.lang.Throwable -> Lc40
            com.panasonic.jp.flow.wireless.util.LogManager.e(r3, r2)     // Catch: java.lang.Throwable -> Lc40
            r30.clearData()     // Catch: java.lang.Throwable -> Lc40
        Lc3e:
            monitor-exit(r30)
            return
        Lc40:
            r0 = move-exception
            r2 = r0
            monitor-exit(r30)     // Catch: java.lang.Throwable -> Lc40
            throw r2
        Lc44:
            monitor-exit(r30)
            return
    }
}
