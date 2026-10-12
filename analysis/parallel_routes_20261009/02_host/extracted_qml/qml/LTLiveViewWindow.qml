import QtQuick 2.6
import QtQuick.Window 2.3
import QtMultimedia
import LT 1.0 as LT
import "qrc:/qml"
import "LTSubFunction.js" as LTSubFunction

/*! \qmltype LTLiveViewWindow
    \inqmlmodule LT

    \brief
    LiveView ウィンドウです
 */
Window {
    id: root

    property alias imageFrameWidth: imageLV.width
    property alias imageFrameHeight: imageLV.height

    ///*LiveView画面状態
    //  1=ホワイトバランスクリック待ち
    //  2=AF枠表示中
    //  3=ワンショットAFクリック待ち
    //  4=グリッド設定中
    //  5=ガイドライン設定中
    //  6=MF拡大表示中
    //  7=MF調整中
    //  8=予備
    //*/
    property bool lv_wbset_mode : applicationSettings.lvWbSetMode                   // WB設定中モード
    property bool lv_level_indicator_on_off: applicationSettings.lvLevelIndicator
    property bool lv_grid_indicator_on_off: applicationSettings.lvGridIndicator
    property bool lv_gline_indicator_on_off: applicationSettings.lvGLineIndicator
    property bool lv_histogram_indicator_on_off: applicationSettings.lvHistogramIndicator
    // ivc >> start >> No.1
    property bool lv_overlay_indicator_on_off: false
    // ivc << end << No.1

    property int lv_rotation: applicationSettings.lvRotation                        //ライブビュー回転角度
    property int lv_rotation_auto: applicationSettings.lvRotationAuto               //ライブビュー回転角度
    property bool lv_rotation_mode: applicationSettings.lvRotationMode              //ライブビュー回転モード　0=0ff　　0/=AUTO

    /*グリッド表示に使う変数  */
    property bool lvGDraw_horizontal_on_off: applicationSettings.gridHorizon        //1.描画 縦グリッド  ON/OFF		初期値 OFF
    property bool lvGDraw_Vertical_on_off: applicationSettings.gridVertical         //2.描画 横グリッド  ON/OFF		初期値 OFF
    property bool lvGDraw_Diagonal_on_off: applicationSettings.gridDiagonal         //3.描画 斜めグリッド  ON/OFF		初期値 OFF
    property int lvGDraw_horizontal_Num: applicationSettings.gridHorNum             //4.縦本数 0～99(0は使わない）	初期値 2
    property int lvGDraw_Vertical_Num: applicationSettings.gridVerNum               //5.横本数 0～99(0は使わない）	初期値 2
    property int lvGDraw_thickness: applicationSettings.gridThickness               //6.太さ   0～10(0は使わない）	初期値 2
    property color lvGDraw_color: applicationSettings.gridColor                     //7.色     000000～ffffff	初期値 808080
    property bool lvGDraw_custom_on_off: applicationSettings.gridCustom             //8.カスタマイズメニューON/OFF     初期値 OFF
    property bool lvGDraw_3_3_on_off: applicationSettings.grid3x3
    property bool lvGDraw_2_2_diagonal_on_off: applicationSettings.grid2x2Diagonal

    /*ガイドライン表示に使う変数  */
    property bool lvGuideLine_horizontal1_on_off: applicationSettings.gLineHor1     //1.描画 縦グリッド  ON/OFF        初期値 OFF
    property bool lvGuideLine_horizontal2_on_off: applicationSettings.gLineHor2     //2.描画 縦グリッド  ON/OFF        初期値 OFF
    property bool lvGuideLine_Vertical1_on_off: applicationSettings.gLineVer1       //3.描画 横グリッド  ON/OFF        初期値 OFF
    property bool lvGuideLine_Vertical2_on_off: applicationSettings.gLineVer2       //4.描画 横グリッド  ON/OFF        初期値 OFF
    property int lvGuideLine_horizontal1_pos: applicationSettings.gLineHor1Pos      //5.縦１本目位置　0～99％          初期値 25
    property int lvGuideLine_horizontal2_pos: applicationSettings.gLineHor2Pos      //6.縦2本目位置 0～99％        初期値 75
    property int lvGuideLine_Vertical1_pos: applicationSettings.gLineVer1Pos        //7.横１本目位置　0～99％        初期値 25
    property int lvGuideLine_Vertical2_pos: applicationSettings.gLineVer2Pos        //8.横2本目位置 0～99％        初期値 75
    property int lvGuideLine_thickness: applicationSettings.gLineThickness          //9.太さ   0～10(0は使わない）   初期値 2
    property color lvGuideLine_color: applicationSettings.gLineColor                //10.色   000000～ffffff	初期値 0080ff

    // ivc >> start >> No.1
    /* Overlay photo function */
    property double lvOverlayPhotoPosX: 0
    property double lvOverlayPhotoPosY: 0
    property int    lvOverlayPhotoScaling: 100
    property double lvOverlayPhotoRotation: 0
    property double lvOverlayPhotoAspectRatio: 0.5
    property string lvOverSelectedFile: ""
    // ivc >> start >> #7614
    property int lvOverlayPhotoScalingDefault: 100
    // ivc >> start >> #7614

    property double lvOverlayPhotoSavedPosX: 0
    property double lvOverlayPhotoSavedPosY: 0
    property double lvOverlayPhotoSavedScaling: 0
    property double lvOverlayPhotoSavedRotation: 0
    property double lvOverlayPhotoSavedAspectRatio: 0

    property bool   lvOverlayPhotoFlagSubmit: false
    property alias  lvOverlayPhotoPopupAlias: overlayPhotoPopup
    property alias  lvOverlayPhotoFrameAlias: overlayPhotoFrame
    property double lvOverlayPhotoFrameOldHeight: overlayPhotoFrame.height
    property double lvOverlayPhotoFrameOldWidth: overlayPhotoFrame.width
    property double lvOverlayPhotoFrameOldPosX: overlayPhotoFrame.x
    property double lvOverlayPhotoFrameOldPosY: overlayPhotoFrame.y
    // ivc >> start >> USBTHRV140-35
//    property double lvOverlayPhotoSliderOldPosX: 0
//    property double lvOverlayPhotoSliderOldPosY: 0
    property double lvOverlayPhotoSpinBoxOldPosX: 0
    property double lvOverlayPhotoSpinBoxOldPosY: 0
    // ivc << end << USBTHRV140-35
    property double lvOverlayPhotoFlagChangeXY: 0
    property int    lvOverlayPhotoFlagChangeRotation: 0
    property double lvOverlayPhotoOldPaintedWidth: 0
    property double lvOverlayPhotoOldPaintedHeight: 0
    property real   lvOverlayPhotoScalePhoto: Math.min(imageLV.paintedHeight / overlayPhotoFrame.overlayImagealias.sourceSize.height, imageLV.paintedWidth /overlayPhotoFrame.overlayImagealias.sourceSize.width) / 100 * lvOverlayPhotoScalingDefault
    property bool   lvOverlayPhotoEnabledSettingButton: true
    property double lvOverlayPhotoOldAspectRatio: 0
    // ivc << end << No.1

    ///*AF枠表示に使う変数 */
    property bool afFrame_Pinpoint_visible:false   // ピンポイント 表示非表示
    property real afFrame_magnification:0           //拡大率

    property bool afaeStartFlg: false

    // ivc >> start >> USBTHRV140-105
    property bool afAreaOldStatus: false
    // ivc << end << USBTHRV140-105

    property int timevalue: 0

    property bool isErrorStop: false

    property var afFrame_Aspect_Width:4            //アスペクト比　画像から求めるか　AspectRatioから求める
    property var afFrame_Aspect_Height:3

// ivc >> start >> No.8
    property double  startTime: 0
// ivc << end << No.8

    //for Streaming対応
    // 2020/05/16 Panasonic Nakano
    property bool afframeVisible: true
    property bool availableAFFrame: true    // if false, force AFrame hidden
    property bool showControlPanel: true    // if false, don't show Control Panel

    property bool affOffVisible: false //AF OFFボタンの表示/非表示
    property bool bulbTimerVisible: false// バルブ撮影のタイマーカウント表示/非表示

    property bool lastMaximised: windowState.curMaximised

    /*!
        各部の描画色を定義するパレットです
     */
    readonly property var palette: {
        "backgroundDark": "#07090d",
        "backgroundLight": "#292b2d",
        "foregroundDark": "#808080",
        "foregroundLight": "#c6c6c6",
        "hovered": "#434343",
        "pressed": "#5c5c5c",
        "checked": "#ffbf1f"
    }

    onLv_wbset_modeChanged: {
        applicationSettings.lvWbSetMode = lv_wbset_mode
    }

    onLv_level_indicator_on_offChanged: {
        applicationSettings.lvLevelIndicator = lv_level_indicator_on_off
    }

    onLv_grid_indicator_on_offChanged: {
        applicationSettings.lvGridIndicator = lv_grid_indicator_on_off
    }

    onLv_gline_indicator_on_offChanged: {
        applicationSettings.lvGLineIndicator = lv_gline_indicator_on_off
    }

    onLv_histogram_indicator_on_offChanged: {
        applicationSettings.lvHistogramIndicator = lv_histogram_indicator_on_off
    }

    onLv_rotationChanged: {
        applicationSettings.lvRotation = lv_rotation
    }

    onLv_rotation_autoChanged: {
        applicationSettings.lvRotationAuto = lv_rotation_auto
    }

    onLv_rotation_modeChanged: {
        applicationSettings.lvRotationMode = lv_rotation_mode
    }

    onLvGDraw_horizontal_on_offChanged: {
        applicationSettings.gridHorizon = lvGDraw_horizontal_on_off
    }

    onLvGDraw_Vertical_on_offChanged: {
        applicationSettings.gridVertical = lvGDraw_Vertical_on_off
    }

    onLvGDraw_Diagonal_on_offChanged: {
        applicationSettings.gridDiagonal = lvGDraw_Diagonal_on_off
    }

    onLvGDraw_horizontal_NumChanged: {
        applicationSettings.gridHorNum = lvGDraw_horizontal_Num
    }

    onLvGDraw_Vertical_NumChanged: {
        applicationSettings.gridVerNum = lvGDraw_Vertical_Num
    }

    onLvGDraw_thicknessChanged: {
        applicationSettings.gridThickness = lvGDraw_thickness
    }

    onLvGDraw_colorChanged: {
        applicationSettings.gridColor = lvGDraw_color
    }

    onLvGDraw_custom_on_offChanged: {
        applicationSettings.gridCustom = lvGDraw_custom_on_off
    }

    onLvGDraw_3_3_on_offChanged: {
        applicationSettings.grid3x3 = lvGDraw_3_3_on_off
    }

    onLvGDraw_2_2_diagonal_on_offChanged: {
        applicationSettings.grid2x2Diagonal = lvGDraw_2_2_diagonal_on_off
    }

    onLvGuideLine_horizontal1_on_offChanged: {
        applicationSettings.gLineHor1 = lvGuideLine_horizontal1_on_off
    }

    onLvGuideLine_horizontal2_on_offChanged: {
        applicationSettings.gLineHor2 = lvGuideLine_horizontal2_on_off
    }

    onLvGuideLine_Vertical1_on_offChanged: {
        applicationSettings.gLineVer1 = lvGuideLine_Vertical1_on_off
    }

    onLvGuideLine_Vertical2_on_offChanged: {
        applicationSettings.gLineVer2 = lvGuideLine_Vertical2_on_off
    }

    onLvGuideLine_horizontal1_posChanged: {
        applicationSettings.gLineHor1Pos = lvGuideLine_horizontal1_pos
    }

    onLvGuideLine_horizontal2_posChanged: {
        applicationSettings.gLineHor2Pos = lvGuideLine_horizontal2_pos
    }

    onLvGuideLine_Vertical1_posChanged: {
        applicationSettings.gLineVer1Pos = lvGuideLine_Vertical1_pos
    }

    onLvGuideLine_Vertical2_posChanged: {
        applicationSettings.gLineVer2Pos = lvGuideLine_Vertical2_pos
    }

    onLvGuideLine_thicknessChanged: {
        applicationSettings.gLineThickness = lvGuideLine_thickness
    }

    onLvGuideLine_colorChanged: {
        applicationSettings.gLineColor = lvGuideLine_color
    }

    // ivc >> start >> No.1
    function submitValueOverlaySetting()
    {
        lvOverlayPhotoSavedPosX = lvOverlayPhotoPosX
        lvOverlayPhotoSavedPosY = lvOverlayPhotoPosY
        lvOverlayPhotoSavedRotation = lvOverlayPhotoRotation
        lvOverlayPhotoSavedScaling = lvOverlayPhotoScaling
        lvOverlayPhotoSavedAspectRatio = lvOverlayPhotoAspectRatio
        lvOverlayPhotoFlagSubmit = true
    }
    function updateRotaOverlayPhoto() {
        if(lv_rotation == 180) {
            if(lvOverlayPhotoRotation > 0) {
                overlayPhotoPopup.sliderRotation1.value = -(180 - lvOverlayPhotoRotation)
            } else{
                overlayPhotoPopup.sliderRotation1.value = (180 + lvOverlayPhotoRotation)
            }
        } else if(lv_rotation == 270) {
            // ivc >> start >> USBTHRV140-27
            //if(lvOverlayPhotoRotation < -90 && lvOverlayPhotoRotation > -180 || lvOverlayPhotoRotation > 90 && lvOverlayPhotoRotation < 180) {
            if(lvOverlayPhotoRotation < -90 && lvOverlayPhotoRotation > -180 || lvOverlayPhotoRotation > 90 && lvOverlayPhotoRotation <= 180) {
            // ivc << end << USBTHRV140-27
                if(lvOverlayPhotoRotation < -90 && lvOverlayPhotoRotation > -180) {
                    overlayPhotoPopup.sliderRotation1.value = (lvOverlayPhotoRotation + 90)
                }
                // ivc >> start >> USBTHRV140-27
                //else if(lvOverlayPhotoRotation > 90 && lvOverlayPhotoRotation < 180) {
                else if(lvOverlayPhotoRotation > 90 && lvOverlayPhotoRotation <= 180) {
                // ivc << end << USBTHRV140-27
                    overlayPhotoPopup.sliderRotation1.value = -(270 - lvOverlayPhotoRotation)
                }
            }else{
                overlayPhotoPopup.sliderRotation1.value = (lvOverlayPhotoRotation + 90)
            }
        }else if(lv_rotation == 90){
            // ivc >> start >> USBTHRV140-27
            //if(lvOverlayPhotoRotation < -90 && lvOverlayPhotoRotation > -180 || lvOverlayPhotoRotation > 90 && lvOverlayPhotoRotation < 180) {
            //    if(lvOverlayPhotoRotation < -90 && lvOverlayPhotoRotation > -180){
            if(lvOverlayPhotoRotation < -90 && lvOverlayPhotoRotation >= -180 || lvOverlayPhotoRotation > 90 && lvOverlayPhotoRotation < 180) {
                if(lvOverlayPhotoRotation < -90 && lvOverlayPhotoRotation >= -180){
            // ivc << end << USBTHRV140-27
                    overlayPhotoPopup.sliderRotation1.value = (270 + lvOverlayPhotoRotation)
                }
                else if(lvOverlayPhotoRotation > 90 && lvOverlayPhotoRotation < 180){
                    overlayPhotoPopup.sliderRotation1.value = (lvOverlayPhotoRotation - 90)
                }
            }else{
                overlayPhotoPopup.sliderRotation1.value = -(90 - lvOverlayPhotoRotation)
            }

        }else if(lv_rotation == 0){
            overlayPhotoPopup.sliderRotation1.value = lvOverlayPhotoRotation
        }

    }

    // Update shape of cursor
    function updateCursorScale() {
        if((overlayPhotoFrame.rotation < -25 && overlayPhotoFrame.rotation > -165) == true
            || (overlayPhotoFrame.rotation < 165 && overlayPhotoFrame.rotation > 25) == true) {
            if((overlayPhotoFrame.rotation > -75 && overlayPhotoFrame.rotation < -25) == true
                ||(overlayPhotoFrame.rotation > 115 && overlayPhotoFrame.rotation < 165) == true) {
                lvOverlayPhotoFrameAlias.mousescale02.cursorShape = Qt.SizeVerCursor
                lvOverlayPhotoFrameAlias.mousescale03.cursorShape = Qt.SizeVerCursor
                lvOverlayPhotoFrameAlias.mousescale01.cursorShape = Qt.SizeHorCursor
                lvOverlayPhotoFrameAlias.mousescale04.cursorShape = Qt.SizeHorCursor
            } else if((overlayPhotoFrame.rotation > -165 && overlayPhotoFrame.rotation < -115) == true
                || (overlayPhotoFrame.rotation > 25 && overlayPhotoFrame.rotation < 75) == true) {
                lvOverlayPhotoFrameAlias.mousescale01.cursorShape = Qt.SizeVerCursor
                lvOverlayPhotoFrameAlias.mousescale02.cursorShape = Qt.SizeHorCursor
                lvOverlayPhotoFrameAlias.mousescale03.cursorShape = Qt.SizeHorCursor
                lvOverlayPhotoFrameAlias.mousescale04.cursorShape = Qt.SizeVerCursor
            } else {
                lvOverlayPhotoFrameAlias.mousescale01.cursorShape = Qt.SizeBDiagCursor
                lvOverlayPhotoFrameAlias.mousescale02.cursorShape = Qt.SizeFDiagCursor
                lvOverlayPhotoFrameAlias.mousescale03.cursorShape = Qt.SizeFDiagCursor
                lvOverlayPhotoFrameAlias.mousescale04.cursorShape = Qt.SizeBDiagCursor
            }
        } else {
            lvOverlayPhotoFrameAlias.mousescale01.cursorShape = Qt.SizeFDiagCursor
            lvOverlayPhotoFrameAlias.mousescale02.cursorShape = Qt.SizeBDiagCursor
            lvOverlayPhotoFrameAlias.mousescale03.cursorShape = Qt.SizeBDiagCursor
            lvOverlayPhotoFrameAlias.mousescale04.cursorShape = Qt.SizeFDiagCursor
        }
    }

    function calcuratio() {
        if(overlayPhotoFrame.overlayImagealias.source != "") {
            var ratio = Math.max(imageLV.paintedHeight, imageLV.paintedWidth) / 2 / 500
            return ratio
        }
        return 0
    }
    // ivc << end << No.1

    function activateWindowNotify() {
        if(root.visibility == Window.Minimized) {
            root.visibility = Window.Windowed
        }
        root.active = true
    }

    function usbEventCameraChanged() {
        LTSubFunction.console_debug.out("usbEventCameraChanged")
        if(deviceAdapter.isCamerasConnected ) {
            if (root.visible) {
                liveViewUpdateForce(true)
            }
        } else {
            liveViewUpdateForce(false)
        }
    }

    function mfAssistStartError() {
        LTSubFunction.console_debug.out("liveview: mfAssistStartError")
//        control.mfZoomEnabled = false
        control.setMFText()
        control.setMFZoom(false)
    }
    //function guidelinePopupCancel(){}
    //function gridPopupCancel(){}

    function pinpAspectRatioSetting(){
        afframe.initFrame()
    }

    function afStateSetting() {
        // AF/AE OFF ボタン表示切り替え、AFモード切り替え
        LTSubFunction.console_debug.out("afStateSetting afState="+deviceAdapter.afState+" afaeState="+deviceAdapter.afaeState)
        if((deviceAdapter.afState == LT.Utilities.AfAeDispStatus_Hide)
           &&(deviceAdapter.afaeState == LT.Utilities.AfAeDispStatus_Hide)) {
            afoff.visible = (affOffVisible = false ) && (!deviceAdapter.isMultiviewMode)
            if(afframe.mode == afframe.afmode_point225_af) {
                LTSubFunction.console_debug.out("afmode_point225_af to afmode_point225")
                afframe.changeMode(afframe.afmode_point225)
                afframe.dispValue225()

                if (deviceAdapter.meteringMode == LT.Utilities.MM_Spot) {
                    root.af_info_point225_Changed()
                }
            } else if(afframe.mode == afframe.afmode_point225f_af) {
                LTSubFunction.console_debug.out("afmode_point225f_af to afmode_point225f")
                afframe.changeMode(afframe.afmode_point225f)
                afframe.dispValue225()
            } else if(afframe.mode == afframe.afmode_point225sf_af) {
                LTSubFunction.console_debug.out("afmode_point225sf_af to afmode_point225sf")
                afframe.changeMode(afframe.afmode_point225sf)
                afframe.dispValue225()
            } else if(afframe.mode == afframe.afmode_face_af) {
                LTSubFunction.console_debug.out("afmode_face_af to afmode_face")
                afframe.changeMode(afframe.afmode_face)
            } else if(afframe.mode == afframe.afmode_face_225_af) {
                LTSubFunction.console_debug.out("afmode_face_225_af to afmode_face_225")
                afframe.changeMode(afframe.afmode_face_225)
                afframe.dispValue225()
            } else if(afframe.mode == afframe.afmode_face_225f_af) {
                LTSubFunction.console_debug.out("afmode_face_225f_af to afmode_face_225f")
                afframe.changeMode(afframe.afmode_face_225f)
                afframe.dispValue225()
            } else if(afframe.mode == afframe.afmode_chase_af) {
                LTSubFunction.console_debug.out("afmode_chase_af to afmode_chase")
                afframe.changeMode(afframe.afmode_chase)
            } else if(afframe.mode == afframe.afmode_fullarea_af) {
                LTSubFunction.console_debug.out("afmode_fullarea_af to afmode_fullarea")
                afframe.changeMode(afframe.afmode_fullarea)
                afframe.dispValue225()
            } else if(afframe.mode == afframe.afmode_fullareaf_af) {
                LTSubFunction.console_debug.out("afmode_fullareaf_af to afmode_fullareaf")
                afframe.changeMode(afframe.afmode_fullareaf)
                afframe.dispValue225()
            }
        } else if((deviceAdapter.afState == LT.Utilities.AfAeDispStatus_Show)
                  ||(deviceAdapter.afaeState == LT.Utilities.AfAeDispStatus_Show)) {
            afoff.visible = (affOffVisible = true ) && (!deviceAdapter.isMultiviewMode)
            if(afframe.mode == afframe.afmode_point225) {
                LTSubFunction.console_debug.out("afmode_point225 to afmode_point225_af")
                afframe.changeMode(afframe.afmode_point225_af)
                afframe.dispValue225()
            } else if(afframe.mode == afframe.afmode_point225f) {
                LTSubFunction.console_debug.out("afmode_point225f to afmode_point225f_af")
                afframe.changeMode(afframe.afmode_point225f_af)
                afframe.dispValue225()
            } else if(afframe.mode == afframe.afmode_point225sf) {
                LTSubFunction.console_debug.out("afmode_point225sf to afmode_point225sf_af")
                afframe.changeMode(afframe.afmode_point225sf_af)
                afframe.dispValue225()
            } else if(afframe.mode == afframe.afmode_face) {
                LTSubFunction.console_debug.out("afmode_face to afmode_face_af")
                afframe.changeMode(afframe.afmode_face_af)
            } else if(afframe.mode == afframe.afmode_face_225) {
                LTSubFunction.console_debug.out("afmode_face_225 to afmode_face_225_af")
                afframe.changeMode(afframe.afmode_face_225_af)
                afframe.dispValue225()
            } else if(afframe.mode == afframe.afmode_face_225f) {
                LTSubFunction.console_debug.out("afmode_face_225f to afmode_face_225f_af")
                afframe.changeMode(afframe.afmode_face_225f_af)
                afframe.dispValue225()
            } else if(afframe.mode == afframe.afmode_chase) {
                LTSubFunction.console_debug.out("afmode_chase to afmode_chase_af")
                afframe.changeMode(afframe.afmode_chase_af)
            } else if(afframe.mode == afframe.afmode_fullarea) {
                LTSubFunction.console_debug.out("afmode_fullarea to afmode_fullarea_af")
                afframe.changeMode(afframe.afmode_fullarea_af)
                afframe.dispValue225()
            } else if(afframe.mode == afframe.afmode_fullareaf) {
                LTSubFunction.console_debug.out("afmode_fullareaf to afmode_fullareaf_af")
                afframe.changeMode(afframe.afmode_fullareaf_af)
                afframe.dispValue225()
            }
        }
    }
    function driveModeSetting() {
        LTSubFunction.console_debug.out("driveModeSetting start mode:" + deviceAdapter.driveMode);

        switch(deviceAdapter.driveMode) {
        case LT.Utilities.DM_Unknown:// = -1,
        case LT.Utilities.DM_Single://,              //単写
        case LT.Utilities.DM_Burst://,               //連写
        case LT.Utilities.DM_Burst1://,              //連写1
        case LT.Utilities.DM_Burst2://,              //連写2
        case LT.Utilities.DM_Bracket://,             //ブラケット
        case LT.Utilities.DM_SelfTimer://,           //セルフタイマー
        case LT.Utilities.DM_Interval://,            //インターバル
        case LT.Utilities.DM_Komadori://,            //コマ撮りアニメ
        case LT.Utilities.DM_4K6K://,                //6Kフォト・4Kフォト（連写 / 連写（S/S） / プリ連写） / フォーカスセレクト / セルフタイマー / インターバル・コマ撮りアニメ
        case LT.Utilities.DM_HRS://,                 //ハイレゾショット
        case LT.Utilities.DM_HANDHELD_HRS://,        //手持ちハイレゾショット
            break;
        case LT.Utilities.DM_Focus://,               //フォーカスセレクト
            afframe.changeMode(afframe.afmode_focusselect)
            break;
        default:
            break;
        }
    }

    function recordingModeSetting() {
        // 動画LV拡大有効時の拡大倍率ボタン設定
        if(deviceAdapter.lvMagEnable) {
//            if (deviceAdapter.recordingMode === LT.Utilities.RM_CreativeVideo || deviceAdapter.recordingMode === LT.Utilities.RM_SQMotion) {
            if (deviceAdapter.isExpMovieMode()) {
                if(deviceAdapter.mfa_mode == LT.Utilities.AsModCur_Off) {
                    control.setMFZoom(false)
                }else {
                    control.setMFZoom(true)
                }
            } else {
                control.setMFZoom(false)
            }
        }
    }

    function dispMovieTime() {
        var disp = ""
        var hour = parseInt(root.timevalue / 3600);
        var min = parseInt((root.timevalue%3600) / 60);
        var sec = root.timevalue % 60

        //SDカード無しでも録画状態にできるようになるため、SDカードに録画中か判断する手段がない現状では、値が0以上なら数値を表示するように変更
        //Tether後から接続時、カメラ選択の変更時にSDカードに録画中か判断不能（SD無しで本体側で録画開始し後からSD刺された場合など、カードステータスのみで判断することはできない）
        if( root.timevalue > 0)
        {
            disptime.visible = true
        }

        // 時
        if(hour > 0){
            disp += hour
            disp += "h"
        }
        // 分
        if(min > 0 || disp.length > 0) {
            if(disp.length > 0 && min < 10){
                disp += "0"
            }
            disp += min
            disp += "m"
        }
        // 秒
        if(disp.length > 0 && sec < 10){
            disp += "0"
        }
        disp += sec
        disp += "s"
        disptime.text = disp
    }

    function recStart() {
        LTSubFunction.console_debug.out("liveview::recStart")
        root.timevalue = 0
        disptime.text = "0s"
        //SDカード無しでも録画状態にできるようになるため、SDカードに録画中か判断する手段がない現状では、値が0以上なら数値を表示するように変更
        //Tether後から接続時、カメラ選択の変更時にSDカードに録画中か判断不能（SD無しで本体側で録画開始し後からSD刺された場合など、カードステータスのみで判断することはできない）
        disptime.visible = false
        //disptimer.repeat = true
        //disptimer.running = true
        disptimegroup.visible = true
    }

    function recStop() {
        LTSubFunction.console_debug.out("liveview::recStop")
        disptimegroup.visible = false
    }

// ivc >> start >> No.8
    function recBulbStart() {
        LTSubFunction.console_debug.out("liveview::recBulbStart")
        disptimeBuld.text = "0"
        startTime =  Math.round(Date.now() / 1000) // get second only
        bulbTimer.running = true
        disptimeBulbGroup.visible = (bulbTimerVisible = true) && (!deviceAdapter.isMultiviewMode)
    }

    function recBulbStop() {
        LTSubFunction.console_debug.out("liveview::recBulbStop")
        bulbTimer.running = false
        disptimeBulbGroup.visible = (bulbTimerVisible = false) && (!deviceAdapter.isMultiviewMode)
    }

    function bulbTimeFormat(time)   {
        // Hours, minutes and seconds
        var hrs = Math.floor(time / 3600);
        var mins = Math.floor((time % 3600) / 60);
        var secs = time % 60;

        // Output like "1:01" or "4:03:59" or "123:03:59"
        var ret = "";

        if (hrs > 0) {
            ret += "" + hrs + ":" ;
            if(mins == 0){
                 ret += "00:";
            }
        }

        if(mins > 0){
            ret += "" + (mins < 10 ? "0" : "") + mins + ":";
        }

        ret +=  (secs < 10 ? "0" : "") + secs;

        return ret;
    }
// ivc << end << No.8

    function afaeStart() {
        LTSubFunction.console_debug.out("liveview::afaeStart afframe.mode="+afframe.mode)
        afaeStartFlg = true

        if (!(deviceAdapter.afPointScopeEnable && deviceAdapter.sFrame_info)) {
            control.setMFText()
            control.setMFZoom(false)
        }

        if(afframe.mode == afframe.afmode_point225s) {
            afframe.changeMode(afframe.afmode_point225s_af)
            afframe.dispValue225()
            if(afaeStartFlg) {
                afframe.dispValue225Focus()
            }
        } else if(afframe.mode == afframe.afmode_point225sf) {
            afframe.changeMode(afframe.afmode_point225sf_af)
            afframe.dispValue225()
            if(afaeStartFlg) {
                afframe.dispValue225Focus()
            }
        } else if(afframe.mode == afframe.afmode_customs) {
            afframe.changeMode(afframe.afmode_customs_af)
        } else if(afframe.mode == afframe.afmode_customsf) {
            afframe.changeMode(afframe.afmode_customsf_af)
            afframe.dispValueCustom()
        }
    }

    function afaeStop() {
        LTSubFunction.console_debug.out("liveview::afaeStop")
        afaeStartFlg = false

        if (!(deviceAdapter.afPointScopeEnable && deviceAdapter.sFrame_info)) {
            control.setMFText()
            autoFocusModeSetting()
        }

        if(afframe.mode == afframe.afmode_point225s_af) {
            afframe.changeMode(afframe.afmode_point225s)
            afframe.dispValue225()
            if(afaeStartFlg) {
                afframe.dispValue225Focus()
            }
        } else if(afframe.mode == afframe.afmode_point225sf_af) {
            afframe.changeMode(afframe.afmode_point225sf)
            afframe.dispValue225()
            if(afaeStartFlg) {
                afframe.dispValue225Focus()
            }
        } else if(afframe.mode == afframe.afmode_customs_af) {
            afframe.changeMode(afframe.afmode_customs)
        } else if(afframe.mode == afframe.afmode_customsf_af) {
            afframe.changeMode(afframe.afmode_customsf)
            afframe.dispValueCustom()
        }
    }

    //function mfAssistModeSetting() {
    //    LTSubFunction.console_debug.out("liveview::mfAssistModeSetting mfAssistMode="+deviceAdapter.mfAssistMode)
    //    if(deviceAdapter.mfAssistMode == LT.Utilities.MFASTM_Normal) {
    //        LTSubFunction.console_debug.out("liveview::mfAssistModeSetting normal")
    //        afframe.mfAssistModeSetting(afframe.mfzoom_mode_normal)
    //    } else if(deviceAdapter.mfAssistMode == LT.Utilities.MFASTM_Pinp) {
    //        LTSubFunction.console_debug.out("liveview::mfAssistModeSetting pinp")
    //        afframe.mfAssistModeSetting(afframe.mfzoom_mode_pinp)
    //    } else {
    //        LTSubFunction.console_debug.out("liveview::mfAssistModeSetting unknown")
    //        afframe.mfAssistModeSetting(afframe.mfzoom_mode_unknown)
    //    }
    //}

    //function pinpointModeSetting() {
    //    LTSubFunction.console_debug.out("liveview::pinpointModeSetting pinpointMode="+deviceAdapter.pinpointMode)
    //    if(deviceAdapter.pinpointMode == LT.Utilities.PINPM_Normal) {
    //        LTSubFunction.console_debug.out("liveview::pinpointModeSetting normal")
    //        afframe.mfAssistModeSetting(afframe.mfzoom_mode_normal)
    //    } else if(deviceAdapter.pinpointMode == LT.Utilities.PINPM_Pinp) {
    //        LTSubFunction.console_debug.out("liveview::pinpointModeSetting pinp")
    //        afframe.mfAssistModeSetting(afframe.mfzoom_mode_pinp)
    //    } else {
    //        LTSubFunction.console_debug.out("liveview::pinpointModeSetting unknown")
    //        afframe.mfAssistModeSetting(afframe.mfzoom_mode_unknown)
    //    }
    //}

    function recPreviewSetting() {
        //console.log("liveview::recPreviewSetting")
        control.recPreviewSetting()
    }

    function whiteBalanceSetting() {
        //console.log("liveview::whiteBalanceSetting =" + deviceAdapter.whiteBalance)
        control.whiteBalanceSetting()
    }

    function af_magnifySetting() {
        //console.log("liveview::af_magnify =" + deviceAdapter.af_magnify)
        control.setMFScale()
    }

    function mf_magnifySetting() {
        //console.log("liveview::mf_magnify =" + deviceAdapter.mf_magnify)
        control.setMFScale()
    }

    function mfa_modeSetting() {
        LTSubFunction.console_debug.out("liveview::mfa_modeSetting =" + deviceAdapter.mfa_mode)
        var flg = true

        if(deviceAdapter.mfa_mode == LT.Utilities.AsModCur_Zoom) {
            var cx = deviceAdapter.af_pinpoin_frame_centerX();
            var cy = deviceAdapter.af_pinpoin_frame_centerY();
            var aw = deviceAdapter.af_pinpoin_frame_area_width();
            var ah = deviceAdapter.af_pinpoin_frame_area_height();

            var minx = deviceAdapter.af_pinpoin_frame_upper_leftX();
            var maxx = deviceAdapter.af_pinpoin_frame_lower_rightX();
            var miny = deviceAdapter.af_pinpoin_frame_upper_leftY();
            var maxy = deviceAdapter.af_pinpoin_frame_lower_rightY();

            LTSubFunction.console_debug.out("liveview::mfa_modeSetting normal cx="+cx+" cy="+cy+" aw="+aw+" ah="+ah)
            afframe.mfAssistZoomSetting(cx, cy, aw, ah, minx, maxx, miny, maxy)

            afframe.mfAssistModeSetting(afframe.mfzoom_mode_normal)
        } else if(deviceAdapter.mfa_mode == LT.Utilities.AsModCur_Pinp) {
            LTSubFunction.console_debug.out("liveview::mfa_modeSetting pinp")
            afframe.mfAssistModeSetting(afframe.mfzoom_mode_pinp)
        } else if(deviceAdapter.mfa_mode == LT.Utilities.AsModCur_Move) {
            LTSubFunction.console_debug.out("liveview::mfa_modeSetting move")
            afframe.mfAssistModeSetting(afframe.mfzoom_mode_move)
            flg = false
        } else {
            LTSubFunction.console_debug.out("liveview::mfa_modeSetting unknown")
            if(deviceAdapter.assistType === LT.Utilities.AFFrameAssistType_LVMAG)
            {
                // 動画LV拡大モード終了の場合
                autoFocusModeSetting()
            }
            else
            {
                afframe.mfAssistModeSetting(afframe.mfzoom_mode_unknown)
            }
            flg = false
        }

        afframe.mfAssistDragFrameSetting()

        control.setMFText()
        control.setMFZoom(flg)
    }

    function cameraValueGetComplete() {
        //LTSubFunction.console_debug.out("liveview::cameraValueGetComplete start")
        autoFocusModeSetting()
        driveModeSetting()
        recordingModeSetting()
        meteringModeSetting()
        elapsedInMovieRecSetting();
        cameraStatusSetting();
        control.cameraValueGetComplete()
        whiteBalanceSetting()
        aspectRatioSetting()

        afStateSetting()

        //mfAssistModeSetting();
        mfa_modeSetting();

        af_frame_sframe_Changed()
        af_frame_info_Changed()
        //LTSubFunction.console_debug.out("liveview::cameraValueGetComplete end")
    }

    function aspectRatioSetting() {
        LTSubFunction.console_debug.out("liveview::aspectRatioSetting aspectRatio=" + deviceAdapter.aspectRatio)
        afframe.initFrame()
    }

    function meteringModeSetting() {
        //LTSubFunction.console_debug.out("meteringModeSetting meteringMode" + deviceAdapter.meteringMode)
        afframe.center_keep = false
        if(deviceAdapter.meteringMode == LT.Utilities.MM_Spot) {
            switch(afframe.mode) {
            case afframe.afmode_pointone://
            // ivc >> start >> No.3 -> nakhuong
            case afframe.afmode_pointone_aux://
            // ivc << end << No.3 -> nakhuong
                break;
            case afframe.afmode_point225://
            case afframe.afmode_point225s://
            case afframe.afmode_point225f://
            case afframe.afmode_point225sf://
                afframe.center_keep = true
                LTSubFunction.console_debug.out("meteringModeSetting 225 center_keep")
                break;
            case afframe.afmode_point225_af://
            case afframe.afmode_point225f_af://
            case afframe.afmode_point225s_af://
            case afframe.afmode_point225sf_af://
                break;
            case afframe.afmode_face://
            case afframe.afmode_face_eye://
            case afframe.afmode_face_af://
            case afframe.afmode_face_225://
                afframe.center_keep = true
                LTSubFunction.console_debug.out("meteringModeSetting face center_keep")
                break;
            case afframe.afmode_face_225f://
            case afframe.afmode_face_225_af://
            case afframe.afmode_face_225f_af://
                break;
            case afframe.afmode_chase://
            case afframe.afmode_chase_af://
                afframe.center_keep = true
                LTSubFunction.console_debug.out("meteringModeSetting chase center_keep")
                break;
            case afframe.afmode_pinpoint://
            case afframe.afmode_pinpointf://
            case afframe.afmode_pinpointz://
            case afframe.afmode_pinpointp://
                break;
            case afframe.afmode_custom://
            case afframe.afmode_customs://
            case afframe.afmode_custom_af://
            case afframe.afmode_customs_af://
            case afframe.afmode_customf://
            case afframe.afmode_customsf://
            case afframe.afmode_customf_af://
            case afframe.afmode_customsf_af://
                afframe.center_keep = true
                LTSubFunction.console_debug.out("meteringModeSetting custom center_keep")
                break;
            case afframe.afmode_mf://
            case afframe.afmode_mff://
            case afframe.afmode_mfz://
            case afframe.afmode_mfp://
                break;
            case afframe.afmode_focusselect://
                afframe.center_keep = true
                LTSubFunction.console_debug.out("meteringModeSetting focusselect center_keep")
                break;
            default:
                // ここでは何もしない
                break;
            }
            afframe.setMeteringSpot(true)
        } else {
            afframe.setMeteringSpot(false)
        }
    }

    function elapsedInMovieRecSetting() {
        //console.log("elapsedInMovieRecSetting start" + deviceAdapter.elapsedInMovieRec);
        //> PTPタグ仕様では、65535(-1)は「時間未定」という意味です。
        //> パラメータの型はINT32型(signed)ですのでご注意ください
        if(deviceAdapter.elapsedInMovieRec < 0) {//65535) {
            root.timevalue = 0
        } else {
            root.timevalue = deviceAdapter.elapsedInMovieRec
        }
        dispMovieTime()
    }

    function cameraStatusSetting() {
        var flg = false
        //---------------------------------
        //撮影スタンバイ 　　　→0
        //動画記録中(4K/6Kフォト含む) →1
        //動画再生中（4K/6Kフォト除く） →2
        //その他処理中 →3
        //動画以外再生中 →4
        //---------------------------------
        //テザー側で、カメラの状態が{ 2, 3, 4 }の時に操作中を表示するように
        //ご対応をお願いいたします
        LTSubFunction.console_debug.out("LiveView::cameraStatusSetting cameraStatus " + deviceAdapter.cameraStatus)
        if((deviceAdapter.cameraStatus == LT.Utilities.CamStatus_MovRec_Others) ||
           (deviceAdapter.cameraStatus == LT.Utilities.CamStatus_Playing) ||
           (deviceAdapter.cameraStatus == LT.Utilities.CamStatus_Processing) ){
            maskpanel.mode &= ~maskpanel.mode_streaming
            maskpanel.mode |= maskpanel.mode_camera
            //imageLV.source = "image://liveViewCapture/black"
            updateMaskPanel()
            // IVC >> Ver.1.9 >> start >> [THRBOXV100-126]
            if (deviceAdapter.camSupportPowerSaving && deviceAdapter.pwTetherConnectMode == LT.Utilities.PwTether_OFF) {
                cameraOperating.visible = false
            }
            // IVC << Ver.1.9 << end << [THRBOXV100-126]
            LTSubFunction.console_debug.out("LiveView::cameraStatusSetting call1 liveViewUpdate flg=" + flg)
            liveViewUpdate(flg)
        } else if(deviceAdapter.cameraStatus == LT.Utilities.CamStatus_MovRec_4k ||
                  deviceAdapter.cameraStatus == LT.Utilities.CamStatus_RemoteRec ||
                  deviceAdapter.cameraStatus == LT.Utilities.CamStatus_MovRemoteRec ||
                  deviceAdapter.cameraStatus == LT.Utilities.CamStatus_RemoteRecRawHDMI
                  ) {
            //録画状態の時はストリーミングは終わってるはず(優先度としてストリーミング＞録画)
            //再生モードも終わってるはず
            maskpanel.mode &= ~maskpanel.mode_streaming
            maskpanel.mode &= ~maskpanel.mode_camera
            updateMaskPanel()

            if(maskpanel.visible) {
                //状態存在する？
                cameraOperating.text = qsTr("camera_get_capability")
            }
            if(root.visible) {
                flg = true
            }
            recStart()
            LTSubFunction.console_debug.out("LiveView::cameraStatusSetting call2 liveViewUpdate flg=" + flg)
            //MacのUSBでライブ画面がマウス動かさないと再描画されない問題の回避策
            if( utilities.isMac() ){
                delayAfter(10, function() {
                    liveViewUpdate(flg)
                })
            }else{
                liveViewUpdate(flg)
            }
        } else if(deviceAdapter.cameraStatus == LT.Utilities.CamStatus_IP_LiveStreaming ||
                  deviceAdapter.cameraStatus == LT.Utilities.CamStatus_LiveStreamingRemoteRec){
            //ライブストリーミング開始されたら本体の再生モードは解除されてるはず
            maskpanel.mode &= ~maskpanel.mode_camera
            maskpanel.mode |= maskpanel.mode_streaming
            //imageLV.source = "image://liveViewCapture/black"
            updateMaskPanel()
            LTSubFunction.console_debug.out("LiveView::cameraStatusSetting call3 liveViewUpdate flg=" + flg)
            liveViewUpdate(false)
        } else {
            if(deviceAdapter.cameraStatus == LT.Utilities.CamStatus_Standby)
            {
                //カメラの状態フラグはOFFへ
                maskpanel.mode &= ~maskpanel.mode_camera
                maskpanel.mode &= ~maskpanel.mode_streaming
                updateMaskPanel()
            }

            if(maskpanel.visible) {
                cameraOperating.text = qsTr("camera_get_capability")
            }
            if(root.visible) {
                flg = true
            }
            if(disptimegroup.visible) {
                recStop()
            }
            LTSubFunction.console_debug.out("LiveView::cameraStatusSetting call3 liveViewUpdate flg=" + flg)
            //MacのUSBでライブ画面がマウス動かさないと再描画されない問題の回避策
            if( utilities.isMac() ){
                delayAfter(10, function() {
                    liveViewUpdate(flg)
                })
            }else{
                liveViewUpdate(flg)
            }
        }
// IVC >> Ver.1.9 >> start >> No.2
        if(deviceAdapter.cameraStatus == LT.Utilities.CamStatus_Menu_Displayed) {
            //for Streaming対応
            afframe.visible = (afframeVisible = false) && availableAFFrame && (!deviceAdapter.isMultiviewMode)
        } else {
            //for Streaming対応
            afframe.visible = deviceAdapter.lvcShowLvControlItem && (afframeVisible = true) && availableAFFrame && (!deviceAdapter.isMultiviewMode)
        }
// IVC << Ver.1.9 << end << No.2
    }

    function delayAfter(delay, trigger) {
        var delayTimer = Qt.createQmlObject("import QtQuick 2.0; Timer {}", root);

        delayTimer.interval = delay
        delayTimer.repeat = false
        delayTimer.triggered.connect(function () {
            trigger()
        })
        delayTimer.start()
    }

    function cameraStatusCompleteNotify() {
        LTSubFunction.console_debug.out("LiveView::cameraStatusCompleteNotify")
        if((deviceAdapter.cameraStatus != LT.Utilities.CamStatus_MovRec_Others) &&
           (deviceAdapter.cameraStatus != LT.Utilities.CamStatus_Playing) &&
           (deviceAdapter.cameraStatus != LT.Utilities.CamStatus_Processing) &&
           (deviceAdapter.cameraStatus != LT.Utilities.CamStatus_IP_LiveStreaming) &&
           (deviceAdapter.cameraStatus != LT.Utilities.CamStatus_LiveStreamingRemoteRec) ){
            if(maskpanel.visible) {
                //カメラの状態フラグはOFFへ
                maskpanel.mode &= ~maskpanel.mode_camera
                maskpanel.mode &= ~maskpanel.mode_streaming
                updateMaskPanel()
            }
        }
    }

    function preferenceWindowVisibleSetting(flg) {
        LTSubFunction.console_debug.out("LiveView::preferenceWindowVisibleSetting flg=" + flg)
        if(flg) {
            maskpanel.mode |= maskpanel.mode_pref
        } else {
            maskpanel.mode &= ~maskpanel.mode_pref
        }
        updateMaskPanel()
    }

    function searchCamWindowVisibleSetting(flg){
        if(flg) {
            maskpanel.mode |= maskpanel.mode_searchWindow
        } else {
            maskpanel.mode &= ~maskpanel.mode_searchWindow
        }
        updateMaskPanel()
    }

    function updateMaskPanel()
    {
        if(maskpanel.mode == maskpanel.mode_init )
        {
            maskpanel.controlAreaOnly = false
            cameraOperating.visible = false
            maskpanel.visible = false
        }else if(maskpanel.mode & maskpanel.mode_streaming){
            maskpanel.controlAreaOnly = false
            cameraOperating.visible = true
            if( deviceAdapter.isMultiviewMode === false){
                //シングルの時はマスクかける
                maskpanel.visible = true
            }
            cameraOperating.text = qsTr("camera_ip_live_streaming")
        }else if(maskpanel.mode & maskpanel.mode_camera){
            if( deviceAdapter.isMultiviewMode === false){
                //全体マスク
                cameraOperating.visible = true
                maskpanel.controlAreaOnly = false
            }else{
                //操作パネル部分のみマスク
                cameraOperating.visible = false
                maskpanel.controlAreaOnly = true
            }
            maskpanel.visible = true
            cameraOperating.text = qsTr("camera_operating")
        }else{
            //解除
            maskpanel.controlAreaOnly = false
            cameraOperating.visible = false
            maskpanel.visible = true
        }
    }

// IVC >> Ver.1.9 >> start >> [THRBOXV100-116]
    function liveviewForceClose() {
        LTSubFunction.console_debug.out("liveviewForceClose status = " + videoImageInfo.videoImageStatus)
        // すでに停止していたら何もしない
        if(videoImageInfo.videoImageStatus === LT.VideoImageInfo.VIS_Stop ) {
            return;
        } else {
            LTSubFunction.console_debug.out("liveviewForceClose not VIS_Start")
            afframe.visible = false
            //imageTimer.running = false
            //videoImageInfo.stopVideoImage();
            deviceAdapter.adp_LMX_func_api_Ctrl_LiveView_Stop()
        }
    }
// IVC << Ver.1.9 << end << [THRBOXV100-116]

    function liveViewUpdate(flg) {
        LTSubFunction.console_debug.out("liveViewUpdate start flg=" + flg + " status " + videoImageInfo.videoImageStatus)

        //ストリーミング中はコマンドは投げない
        //videoImageInfoは開始していないといけないような挙動になっている
        var noCommand = false
        if( deviceAdapter.cameraStatus == LT.Utilities.CamStatus_IP_LiveStreaming ||
            deviceAdapter.cameraStatus == LT.Utilities.CamStatus_LiveStreamingRemoteRec)
        {
            noCommand = true
        }
        //テザーモードOFFの場合はコマンドは投げない
        //deviceAdapter.pwTetherConnectModeはこの時点で更新されてないので利用できない
        //ライブの開始、停止コマンドのみ、cameralistの方で行っているので、フラグ的にライブ開始状態にはしておくような挙動になっている
        var uuid = deviceAdapter.camera_list_get_selected_camera_uuid()
        var camPowerOnMode = deviceAdapter.camera_list_get_camera_power_mode_DisplayList(uuid);
        if (camPowerOnMode === false) {
            noCommand = true
        }

        // ライブビューを開始
        if(flg) {
            // すでに開始していたら何もしない
            if(videoImageInfo.videoImageStatus === LT.VideoImageInfo.VIS_Start) {
                return;
            } else {
                if( deviceAdapter.isMultiviewMode === false){
                    LTSubFunction.console_debug.out("liveViewUpdate VIS_Start")
                    deviceAdapter.adp_LMX_func_api_Ctrl_LiveView_Stop()
                    deviceAdapter.adp_LMX_func_api_Ctrl_LiveView_Start()
                    if( noCommand == false){
                        // IVC >> Ver.1.7 >> start >> No.1
                        deviceAdapter.adp_LMX_func_api_LiveView_Str_Get_Recom_Img_Start()
                        deviceAdapter.adp_LMX_func_api_LiveView_Str_Get_Trans_Img_Start()
                    }
                }

                //取り込みダイアログが非表示なった時などでライブ表示が復活した時、MENU表示中はAF枠表示しないようにする
                if(deviceAdapter.cameraStatus == LT.Utilities.CamStatus_Menu_Displayed) {
                    afframe.visible = (afframeVisible = false) && availableAFFrame && (!deviceAdapter.isMultiviewMode)
                } else {
                    afframe.visible = deviceAdapter.lvcShowLvControlItem && (afframeVisible = true) && availableAFFrame && (!deviceAdapter.isMultiviewMode)
                }
            }
        // ライブビューを停止
        } else {
            //黒画面のPause状態へ
            if(videoImageInfo.videoImageStatus === LT.VideoImageInfo.VIS_Pause) {
                return;
            } else {
                //for Streaming対応
                afframe.visible = (afframeVisible = false) && availableAFFrame && (!deviceAdapter.isMultiviewMode) // 2020/05/16 Panasonic Nakano
                //imageTimer.running = false
                //videoImageInfo.videoImageStatus = LT.VideoImageInfo.VIS_Stop
                //videoImageInfo.stopVideoImage();
                //deviceAdapter.adp_LMX_func_api_Mnt_Ctrl_LiveView_Stop()
                //deviceAdapter.adp_LMX_func_api_Ctrl_LiveView_Stop()
                if( deviceAdapter.isMultiviewMode === false){
                    deviceAdapter.adp_LMX_func_api_Ctrl_LiveView_Stop()
                    deviceAdapter.setLiveviewPause()
                }
                //// IVC >> Ver.1.9 >> start >> No.1
                //connectionEvent.setEvent()
                //// IVC << Ver.1.9 << end << No.1
            }
        }
        isErrorStop = false
    }

    function liveViewUpdateForce(flg) {
        //ストリーミング中はコマンドは投げない
        var noCommand = false
        if( deviceAdapter.cameraStatus == LT.Utilities.CamStatus_IP_LiveStreaming ||
            deviceAdapter.cameraStatus == LT.Utilities.CamStatus_LiveStreamingRemoteRec)
        {
            noCommand = true
        }
        //テザーモードOFFの場合はコマンドは投げない
        //deviceAdapter.pwTetherConnectModeはこの時点で更新されてないので利用できない
        var uuid = deviceAdapter.camera_list_get_selected_camera_uuid()
        var camPowerOnMode = deviceAdapter.camera_list_get_camera_power_mode_DisplayList(uuid);
        if (camPowerOnMode === false) {
            noCommand = true
        }

        // ライブビューを開始
        if(flg) {
            if (isErrorStop) {
                LTSubFunction.console_debug.out("liveViewUpdateForce VIS_Start")
                // IVC >> Ver.1.9 >> start >> [THRBOXV100-181]
                deviceAdapter.adp_LMX_func_api_Ctrl_LiveView_Stop_Start()
                deviceAdapter.adp_LMX_func_api_Ctrl_LiveView_Start_Start()
                // IVC << Ver.1.9 << end << [THRBOXV100-181]
                if( noCommand == false){
                    // IVC >> Ver.1.7 >> start >> No.1
                    deviceAdapter.adp_LMX_func_api_LiveView_Str_Get_Recom_Img_Start()
                    deviceAdapter.adp_LMX_func_api_LiveView_Str_Get_Trans_Img_Start()
                    // IVC << Ver.1.7 << end << No.1
                }
                //for Streaming対応
                afframe.visible = (afframeVisible = true) && availableAFFrame && (!deviceAdapter.isMultiviewMode) // 2020/05/16 Panasonic Nakano
                //imageTimer.start_timer()
                //videoImageInfo.startVideoImage();
                isErrorStop = false
            }
        // ライブビューを停止
        } else {
            LTSubFunction.console_debug.out("liveViewUpdateForce VIS_Stop")
            isErrorStop = true
            //for Streaming対応
            afframe.visible = (afframeVisible = false) && availableAFFrame && (!deviceAdapter.isMultiviewMode) // 2020/05/16 Panasonic Nakano
            //imageTimer.running = false
            //videoImageInfo.stopVideoImage();
            deviceAdapter.adp_LMX_func_api_Ctrl_LiveView_Stop_Start()
        }
    }

    function autoFocusModeSetting() {
        LTSubFunction.console_debug.out("liveview::autoFocusModeSetting focus="+deviceAdapter.focusMode+" autofocus="+deviceAdapter.autoFocusMode+" afmode="+afframe.mode)

        //afFrame_pos_visible=false
        //afFrame_255point_visible=false
        afFrame_Pinpoint_visible=false
        //afFrame_Face_visible=false          // 表示非表示
        //afFrame_Tracking_visible=false      // 表示非表示
        //afFrame_CustomMulti_visible=false   // 表示非表示
        if(deviceAdapter.focusMode == LT.Utilities.FM_MF) {
            control.setAfAreaButtonCheck(false)
            control.setAfAreaButtonEnable(false)
            control.setOneShotAFButtonEnable(true)
            // 拡大倍率チェック状態
            if(control.mfZoomChecked) {
                // 動画LV拡大
                if(deviceAdapter.lvMagEnable &&
//                   (deviceAdapter.recordingMode === LT.Utilities.RM_CreativeVideo || deviceAdapter.recordingMode === LT.Utilities.RM_SQMotion) &&
                   deviceAdapter.isExpMovieMode() &&
                   (deviceAdapter.assistType === LT.Utilities.AFFrameAssistType_LVMAG) &&
                   (deviceAdapter.mfa_mode === LT.Utilities.AsModCur_Zoom)) {
                        afframe.changeMode(afframe.afmode_lvmag_z)
                }else if(deviceAdapter.lvMagEnable &&
//                          (deviceAdapter.recordingMode === LT.Utilities.RM_CreativeVideo || deviceAdapter.recordingMode === LT.Utilities.RM_SQMotion) &&
                          deviceAdapter.isExpMovieMode() &&
                          (deviceAdapter.assistType === LT.Utilities.AFFrameAssistType_LVMAG) &&
                          (deviceAdapter.mfa_mode === LT.Utilities.AsModCur_Pinp)) {
                              afframe.changeMode(afframe.afmode_lvmag_p)
                // MF
                } else {
                    if(afframe.mfzoom_mode == afframe.mfzoom_mode_normal) {
                        //root.mf_x = -1
                        //root.mf_y = -1
                        afframe.changeMode(afframe.afmode_mfz)
                    } else if(afframe.mfzoom_mode == afframe.mfzoom_mode_pinp) {
                        afframe.changeMode(afframe.afmode_mfp)
                    }
                }
            // MF
            } else {
                if(afframe.mfzoom_mode == afframe.mfzoom_mode_move){
                    afframe.changeMode(afframe.afmode_mff)
                }else{
                    afframe.changeMode(afframe.afmode_mf)
                }
            }
        }
        else {
            //if(afaeStartFlg) {
            //    control.setOneShotAFButtonEnable(true)
            //} else {
                control.setOneShotAFButtonCheck(false)
                control.setOneShotAFButtonEnable(false)
            //}
            // 動画LV拡大
            if(deviceAdapter.lvMagEnable &&
//                (deviceAdapter.recordingMode === LT.Utilities.RM_CreativeVideo || deviceAdapter.recordingMode === LT.Utilities.RM_SQMotion) &&
                deviceAdapter.isExpMovieMode() &&
                (deviceAdapter.assistType === LT.Utilities.AFFrameAssistType_LVMAG) &&
                (deviceAdapter.mfa_mode === LT.Utilities.AsModCur_Zoom)) {
                    afframe.changeMode(afframe.afmode_lvmag_z)
            }else if(deviceAdapter.lvMagEnable &&
//                      (deviceAdapter.recordingMode === LT.Utilities.RM_CreativeVideo || deviceAdapter.recordingMode === LT.Utilities.RM_SQMotion) &&
                      deviceAdapter.isExpMovieMode() &&
                      (deviceAdapter.assistType === LT.Utilities.AFFrameAssistType_LVMAG) &&
                      (deviceAdapter.mfa_mode === LT.Utilities.AsModCur_Pinp)) {
                          afframe.changeMode(afframe.afmode_lvmag_p)
            // AF
            } else {
                switch(deviceAdapter.autoFocusMode) {
                case LT.DeviceAdapter.AFM_1Point:
                    //afFrame_pos_visible=true;
                    control.setAfAreaButtonCheck(false)
                    control.setAfAreaButtonEnable(false)
                    if (afframe.mode != afframe.afmode_pscope
                        && afframe.mode != afframe.afmode_pscope_p
                        && afframe.mode != afframe.afmode_pscope_z) {
                        afframe.changeMode(afframe.afmode_pointone)
                    }
                    // AF合焦情報、AF枠設定更新
                    af_info_pointone_Changed()
                    break;
                // ivc >> start >> No.3 -> nakhuong
                case LT.DeviceAdapter.AFM_1PointAux:
                    control.setAfAreaButtonCheck(false)
                    control.setAfAreaButtonEnable(false)
                    if (afframe.mode != afframe.afmode_pscope
                        && afframe.mode != afframe.afmode_pscope_p
                        && afframe.mode != afframe.afmode_pscope_z) {
                        afframe.changeMode(afframe.afmode_pointone_aux)
                    }
                    // AF合焦情報、AF枠設定更新
                    af_info_pointone_aux_Changed()
                    break;
                // ivc << end << No.3 -> nakhuong
                case LT.DeviceAdapter.AFM_Face:
                    //afFrame_Face_visible=true   // 表示非表示
                    control.setAfAreaButtonCheck(false)
                    control.setAfAreaButtonEnable(false)
                    if(deviceAdapter.afState == LT.Utilities.AfAeDispStatus_Hide) {
                        afframe.changeMode(afframe.afmode_face)
                    } else {
                        afframe.changeMode(afframe.afmode_face_af)
                    }
                    break;
                case LT.DeviceAdapter.AFM_Tracking:
                    //afFrame_Tracking_visible=true;
                    control.setAfAreaButtonCheck(false)
                    control.setAfAreaButtonEnable(false)
                    if(deviceAdapter.afState == LT.Utilities.AfAeDispStatus_Hide) {
                        afframe.changeMode(afframe.afmode_chase)
                    } else {
                        afframe.changeMode(afframe.afmode_chase_af)
                    }
                    break;
                case LT.DeviceAdapter.AFM_Pinpoint:
                    afFrame_Pinpoint_visible=true
                    control.setAfAreaButtonCheck(false)
                    control.setAfAreaButtonEnable(false)
                    if(control.mfZoomChecked) {
                        if(afframe.mfzoom_mode == afframe.mfzoom_mode_normal) {
                            //root.mf_x = -1
                            //root.mf_y = -1
                            afframe.changeMode(afframe.afmode_pinpointz)
                        } else if(afframe.mfzoom_mode == afframe.mfzoom_mode_pinp) {
                            afframe.changeMode(afframe.afmode_pinpointp)
                        }
                    } else {
                        if(afframe.mfzoom_mode == afframe.mfzoom_mode_move){
                            afframe.changeMode(afframe.afmode_pinpointf)
                        }else{
                            afframe.changeMode(afframe.afmode_pinpoint)
                        }
                    }
                    break;
                case LT.DeviceAdapter.AFM_225Point:
                    //afFrame_255point_visible=true;
                    control.setAfAreaButtonEnable(true)
                    //GH5/G9/GH5Sの処理とミックスすると、白＋マークの表示処理は以下のフローで良いでしょうか？
                    //(1) AF OFFボタンの表示/非表示情報(PTPのサブタグID=0x12000017)が「表示」であれば＋を表示。
                    //(2) (1)が非表示だった場合、「AFCの開始位置指定情報(PTPのサブタグID=0x12000018)がON」かつ「AF情報のSTATUS(PTPのサブタグID=0x01000011)が0、1、2、3、5以外 」であれば＋を表示。
                    var s = deviceAdapter.af_status_ulAFStatus();
                    LTSubFunction.console_debug.out("liveview::autoFocusModeSetting 225 afstate="+deviceAdapter.afState+" afcstartposstate="+deviceAdapter.afcStartPosState+" s="+s)
                    if((deviceAdapter.afState == LT.Utilities.AfAeDispStatus_Hide)
                    && (deviceAdapter.afcStartPosState == LT.Utilities.AfcStartPosStatus_ON)
                    && (s != LT.Utilities.LMX_DEF_AFINFO_STATUS_FOCUS_OK)
                    && (s != LT.Utilities.LMX_DEF_AFINFO_STATUS_FOCUS_OK_NODISP)
                    && (s != LT.Utilities.LMX_DEF_AFINFO_STATUS_FOCUS_NOT_AF)
                    && (s != LT.Utilities.LMX_DEF_AFINFO_STATUS_FOCUS_CANCEL)
                    && (s != LT.Utilities.LMX_DEF_AFINFO_STATUS_FOCUS_STRRIGHT)) {
                        if(control.afAreaChecked) {
                            if(afframe.mode == afframe.afmode_point225s_af) {
                                LTSubFunction.console_debug.out("liveview::autoFocusModeSetting 225 type1")
                                afframe.changeMode(afframe.afmode_point225sf_af)
                            } else {
                                LTSubFunction.console_debug.out("liveview::autoFocusModeSetting 225 type2")
                                afframe.changeMode(afframe.afmode_point225sf)
                            }
                        } else {
                            if(afframe.mode == afframe.afmode_point225sf_af) {
                                LTSubFunction.console_debug.out("liveview::autoFocusModeSetting 225 type3")
                                afframe.changeMode(afframe.afmode_point225s_af)
                            } else {
                                LTSubFunction.console_debug.out("liveview::autoFocusModeSetting 225 type4")
                                afframe.changeMode(afframe.afmode_point225s)
                            }
                        }
                    } else if(control.afAreaChecked) {
                        if(deviceAdapter.afState == LT.Utilities.AfAeDispStatus_Hide) {
                            LTSubFunction.console_debug.out("liveview::autoFocusModeSetting 225 type5")
                            afframe.changeMode(afframe.afmode_point225f)
                        } else {
                            LTSubFunction.console_debug.out("liveview::autoFocusModeSetting 225 type6")
                            afframe.changeMode(afframe.afmode_point225f_af)
                        }
                    } else {
                        if(deviceAdapter.afState == LT.Utilities.AfAeDispStatus_Hide) {
                            LTSubFunction.console_debug.out("liveview::autoFocusModeSetting 225 type7")
                            afframe.changeMode(afframe.afmode_point225)
                        } else {
                            LTSubFunction.console_debug.out("liveview::autoFocusModeSetting 225 type8")
                            afframe.changeMode(afframe.afmode_point225_af)
                        }
                    }
                    afframe.dispValue225()
                    if(afaeStartFlg) {
                        afframe.dispValue225Focus()
                    }
                    break;
                case LT.DeviceAdapter.AFM_Square:
                    control.setAfAreaButtonEnable(true)
                    if(control.afAreaChecked) {
                        if(afframe.mode == afframe.afmode_point225s_af) {
                            LTSubFunction.console_debug.out("liveview::autoFocusModeSetting 225 type9")
                            afframe.changeMode(afframe.afmode_point225sf_af)
                        } else {
                            LTSubFunction.console_debug.out("liveview::autoFocusModeSetting 225 type10")
                            afframe.changeMode(afframe.afmode_point225sf)
                        }
                    } else {
                        if(afframe.mode == afframe.afmode_point225sf_af) {
                            LTSubFunction.console_debug.out("liveview::autoFocusModeSetting 225 type11")
                            afframe.changeMode(afframe.afmode_point225s_af)
                        } else {
                            LTSubFunction.console_debug.out("liveview::autoFocusModeSetting 225 type12")
                            afframe.changeMode(afframe.afmode_point225s)
                        }
                    }
                    afframe.dispValue225()
                    if(afaeStartFlg) {
                        afframe.dispValue225Focus()
                    }
                    break;
                case LT.DeviceAdapter.AFM_CustomVertical:
                case LT.DeviceAdapter.AFM_CustomHorizon:
                case LT.DeviceAdapter.AFM_CustomCenter:
                case LT.DeviceAdapter.AFM_CustomC1:
                case LT.DeviceAdapter.AFM_CustomC2:
                case LT.DeviceAdapter.AFM_CustomC3:
                    //afFrame_CustomMulti_visible=true;
                    control.setAfAreaButtonEnable(true)
                    if(control.afAreaChecked) {
                        LTSubFunction.console_debug.out("liveview::autoFocusModeSetting custom type1")
                        afframe.changeMode(afframe.afmode_customf)
                        afframe.dispValueCustom()
                    } else {
                        LTSubFunction.console_debug.out("liveview::autoFocusModeSetting custom type2")
                        afframe.changeMode(afframe.afmode_custom)
                    }
                    break;
                case LT.DeviceAdapter.AFM_VertHori:
                case LT.DeviceAdapter.AFM_Ellipse:
                    //afFrame_CustomMulti_visible=true;
                    // ゾーンの外枠表示の場合
                    if(afframe.zone_outer_flg) {
                        control.setAfAreaButtonCheck(false)
                        control.setAfAreaButtonEnable(false)
                        // AF枠行列数設定
                        afInfoFrameNumSetting()
                        if(deviceAdapter.afPDAFEnable){
                            // PDAF設定
                            afframe.pdafTableTypeSetting()
                        }
                        if(afframe.mode == afframe.afmode_customo_af) {
                            LTSubFunction.console_debug.out("liveview::autoFocusModeSetting custom type1")
                            afframe.changeMode(afframe.afmode_customof_af)
                        } else {
                            LTSubFunction.console_debug.out("liveview::autoFocusModeSetting custom type2")
                            afframe.changeMode(afframe.afmode_customof)
                        }
                        // ivc >> start >> USBTHRV140-105
                        // afframe.dispValueCustom()
                        if ( afAreaOldStatus != control.afAreaChecked) {
                            afframe.dispValueCustom()
                            afAreaOldStatus = true;
                        }
                        // ivc << end << USBTHRV140-105
                    } else {
                        control.setAfAreaButtonEnable(true)
                        if(control.afAreaChecked) {
                            if(afframe.mode == afframe.afmode_customs_af) {
                                LTSubFunction.console_debug.out("liveview::autoFocusModeSetting custom type1")
                                afframe.changeMode(afframe.afmode_customsf_af)
                            } else {
                                LTSubFunction.console_debug.out("liveview::autoFocusModeSetting custom type2")
                                afframe.changeMode(afframe.afmode_customsf)
                            }
                            // ivc >> start >> USBTHRV140-105
                            // afframe.dispValueCustom()
                            if ( afAreaOldStatus != control.afAreaChecked) {
                                afframe.dispValueCustom()
                                afAreaOldStatus = true;
                            }
                            // ivc << end << USBTHRV140-105
                        } else {
                            if(afframe.mode == afframe.afmode_customsf_af) {
                                LTSubFunction.console_debug.out("liveview::autoFocusModeSetting custom type3")
                                afframe.changeMode(afframe.afmode_customs_af)
                            } else {
                                LTSubFunction.console_debug.out("liveview::autoFocusModeSetting custom type4")
                                afframe.changeMode(afframe.afmode_customs)
                            }
                            // ivc >> start >> USBTHRV140-105
                            afAreaOldStatus = false;
                            // ivc << end << USBTHRV140-105
                        }
                    }
                    break;
                case LT.DeviceAdapter.AFM_Custom1:
                case LT.DeviceAdapter.AFM_Custom2:
                case LT.DeviceAdapter.AFM_Custom3:
                    //afFrame_CustomMulti_visible=true;
                    control.setAfAreaButtonEnable(true)
                    if(control.afAreaChecked) {
                        LTSubFunction.console_debug.out("liveview::autoFocusModeSetting custom type3")
                        afframe.changeMode(afframe.afmode_customf_af)
                        afframe.dispValueCustom()
                    } else {
                        LTSubFunction.console_debug.out("liveview::autoFocusModeSetting custom type4")
                        afframe.changeMode(afframe.afmode_custom_af)
                    }
                    break;
                case LT.DeviceAdapter.AFM_FullArea:
                    control.setAfAreaButtonCheck(false)
                    control.setAfAreaButtonEnable(false)
                    // AF枠行列数設定
                    afInfoFrameNumSetting()
                    if(deviceAdapter.afPDAFEnable){
                        // PDAF設定
                        afframe.pdafTableTypeSetting()
                    }
                    if(control.afAreaChecked) {
                        if(deviceAdapter.afState == LT.Utilities.AfAeDispStatus_Hide) {
                            LTSubFunction.console_debug.out("liveview::autoFocusModeSetting fullarea type5")
                            afframe.changeMode(afframe.afmode_fullareaf)
                        } else {
                            LTSubFunction.console_debug.out("liveview::autoFocusModeSetting fullarea type6")
                            afframe.changeMode(afframe.afmode_fullareaf_af)
                        }
                    } else {
                        if(deviceAdapter.afState == LT.Utilities.AfAeDispStatus_Hide) {
                            LTSubFunction.console_debug.out("liveview::autoFocusModeSetting fullarea type7")
                            afframe.changeMode(afframe.afmode_fullarea)
                        } else {
                            LTSubFunction.console_debug.out("liveview::autoFocusModeSetting fullarea type8")
                            afframe.changeMode(afframe.afmode_fullarea_af)
                        }
                    }
                    afframe.dispValue225()
                    if(afaeStartFlg) {
                        afframe.dispValue225Focus()
                    }
                    break;
                case LT.DeviceAdapter.AFM_Unknown:
                default:
                    control.setAfAreaButtonCheck(false)
                    control.setAfAreaButtonEnable(false)
                    if(deviceAdapter.driveMode == LT.Utilities.DM_Focus) {
                        afframe.changeMode(afframe.afmode_focusselect)
                    } else {
                        afframe.changeMode(afframe.afmode_init)
                    }
                    break;
                }
            }
        }

        if (afframe.mode != afframe.afmode_pscope
            && afframe.mode != afframe.afmode_pscope_p
            && afframe.mode != afframe.afmode_pscope_z) {
            control.setMFText()
            control.setMFZoom(false)
        }
    }

    function postureSetting(){
        switch(videoImageInfo.posture) {
        case LT.Utilities.LvInfoPosture_0:
            lv_rotation_auto=0;
            break;
        case LT.Utilities.LvInfoPosture_90:
            lv_rotation_auto=90;
            break;
        case LT.Utilities.LvInfoPosture_180:
            lv_rotation_auto=180
            break;
        case LT.Utilities.LvInfoPosture_270:
            lv_rotation_auto=-90;
            break;
        default:
            lv_rotation_auto=0;
            break;
        }
    }
    function rollSetting(){
        var posval= videoImageInfo.posture;
        var rollval= videoImageInfo.roll*(-1);
        postureSetting();
        //LTSubFunction.console_debug.out("rollSetting p="+posval+" r="+rollval)
        switch(posval) {
        //カメラの向き0　 -> angle = rollSetting / 10
        case LT.Utilities.LvInfoPosture_0:
            levelIndicator.rollingDegrees = parseInt(rollval/10)
            break;
        //カメラの向き90　-> angle = (rollSetting - 900) / 10
        case LT.Utilities.LvInfoPosture_90:
            levelIndicator.rollingDegrees = parseInt((rollval + 900)/10)
            break;
        //カメラの向き180　-> (rollSetting >= 0) angle = (rollSetting - 1800) / 10
        //               (rollSetting < 0) angle = (rollSetting + 1800) / 10
        case LT.Utilities.LvInfoPosture_180:
            if(rollval < 0) {
                levelIndicator.rollingDegrees = parseInt((rollval + 1800) / 10)
            }
            else if (rollval >= 0) {
                levelIndicator.rollingDegrees = parseInt((rollval - 1800) / 10)
            }
            break;
        //カメラの向き270　-> angle = (rollSetting + 900) / 10
        case LT.Utilities.LvInfoPosture_270:
            levelIndicator.rollingDegrees = parseInt((rollval - 900)/10)
            break;
        default:
            break;
        }
    }
    function pitchSetting(){
        //LTSubFunction.console_debug.out("pitchSetting value = " + videoImageInfo.pitch)
        var pitch = videoImageInfo.pitch
        if(pitch > 100){
            levelIndicator.pitchingDegrees=10;                       //リミッター 補正前の10度
        }
        else if(pitch < -100){
            levelIndicator.pitchingDegrees = -10;                     //リミッター 補正前の-10度
        } else {
            levelIndicator.pitchingDegrees = parseInt(pitch/10);
        }
    }
    function af_frame_info_Changed() {
        LTSubFunction.console_debug.out("liveview::af_frame_info_Changed: " + afframe.mode)

        switch(afframe.mode) {
        case afframe.afmode_pointone://
            LTSubFunction.console_debug.out("liveview::af_frame_info_Changed afmode_pointone")
            root.af_info_pointone_Changed()
            break;
        // ivc >> start >> No.3 -> nakhuong
        case afframe.afmode_pointone_aux://
            LTSubFunction.console_debug.out("liveview::af_frame_info_Changed afmode_pointone_aux")
            root.af_info_pointone_aux_Changed()
            break;
        // ivc << end << No.3 -> nakhuong
        case afframe.afmode_point225://
        case afframe.afmode_point225s://
        case afframe.afmode_point225f://
        case afframe.afmode_point225sf://
        case afframe.afmode_point225_af://
        case afframe.afmode_point225f_af://
        case afframe.afmode_point225s_af://
        case afframe.afmode_point225sf_af://
        case afframe.afmode_fullarea://
        case afframe.afmode_fullareaf://
        case afframe.afmode_fullarea_af://
        case afframe.afmode_fullareaf_af://
            LTSubFunction.console_debug.out("liveview::af_frame_info_Changed afmode_point225")
            root.af_info_point225_Changed()
            break;
        case afframe.afmode_face://
        case afframe.afmode_face_eye://
        case afframe.afmode_face_af://
        case afframe.afmode_face_225://
        case afframe.afmode_face_225f://
        case afframe.afmode_face_225_af://
        case afframe.afmode_face_225f_af://
            LTSubFunction.console_debug.out("liveview::af_frame_info_Changed afmode_face")
            root.af_info_face_Changed()
            break;
        case afframe.afmode_chase://
        case afframe.afmode_chase_af://
            LTSubFunction.console_debug.out("liveview::af_frame_info_Changed afmode_chase")
            root.af_info_chase_Changed()
            break;
        case afframe.afmode_pinpoint://
        case afframe.afmode_pinpointf://
        case afframe.afmode_pinpointz://
        case afframe.afmode_pinpointp://
            LTSubFunction.console_debug.out("liveview::af_frame_info_Changed afmode_pinpoint")
            root.af_info_pinpoint_Changed()
            root.af_magnifySetting()
            root.mfa_modeSetting()
            break;
        case afframe.afmode_custom://
        case afframe.afmode_customs://
        case afframe.afmode_custom_af://
        case afframe.afmode_customs_af://
        case afframe.afmode_customf://
        case afframe.afmode_customsf://
        case afframe.afmode_customf_af://
        case afframe.afmode_customsf_af://
        case afframe.afmode_customo://
        case afframe.afmode_customo_af://
        case afframe.afmode_customof://
        case afframe.afmode_customof_af://
            LTSubFunction.console_debug.out("liveview::af_frame_info_Changed afmode_custom")
            root.af_info_custom_Changed()
            break;
        case afframe.afmode_mf://
        case afframe.afmode_mff://
            LTSubFunction.console_debug.out("liveview::af_frame_info_Changed afmode_mf or afmode_mff")
            root.af_info_mf_Changed()
            break;
        case afframe.afmode_mfz://
        case afframe.afmode_mfp://
            LTSubFunction.console_debug.out("liveview::af_frame_info_Changed afmode_mfz or afmode_mfp")
            root.af_info_mfz_Changed()
            root.mf_magnifySetting()
            //root.mfAssistModeSetting()
            root.mfa_modeSetting();
            break;
        case afframe.afmode_pscope:
        case afframe.afmode_pscope_z:
        case afframe.afmode_pscope_p:
            LTSubFunction.console_debug.out("liveview::af_frame_info_Changed afmode_pscope")
            root.af_info_pscope_Changed()
            break;
        case afframe.afmode_lvmag_z:
        case afframe.afmode_lvmag_p:
            // MFアシストと同じ
            root.af_info_mfz_Changed()
            root.mf_magnifySetting()
            root.mfa_modeSetting();
            break;
        default:
            // ここでは何もしない
            break;
        }
        if((afaeStartFlg)&&(afframe.mfzoom_mode == afframe.mfzoom_mode_normal)) {
            LTSubFunction.console_debug.out("liveview::af_frame_info_Changed afae zoom")
            root.af_info_mfz_Changed()
        }
    }

    function liveview_size_Changed() {
        LTSubFunction.console_debug.out("liveview::liveview_size_Changed")
        af_frame_info_Changed()
    }
    //function afoff_position_change() {
    //    var w = deviceAdapter.liveview_size_width;
    //    var h = deviceAdapter.liveview_size_height;
    //    console.debug("liveview::afoff_position_change w = " + w + " h = " + h)
    //    var x_conv = 10
    //    var y_conv = h - 96
    //    afframe.afoff_position(x_conv, y_conv)
    //}
    function af_info_pointone_Changed() {
        var s = deviceAdapter.af_status_ulAFStatus();
        var f = 0
        if(deviceAdapter.af_pdaf_info() === LT.Utilities.AfInfoPDAFInfo_ON){
            f = deviceAdapter.af_pdaf_display_DispInfo(0)
        }else{
            f = deviceAdapter.af_display_DispInfo(0);
        }
        var x = deviceAdapter.af_onepoin_frame_pos_X();
        var y = deviceAdapter.af_onepoin_frame_pos_Y();
        var w = deviceAdapter.af_onepoin_frame_width();
        var h = deviceAdapter.af_onepoin_frame_height();
        var d = deviceAdapter.af_faceinfo_face_detect_status(0);
        var human = deviceAdapter.af_human_detect_info_status(0);
        var mini = false;
        if(deviceAdapter.af_onepoin_frame_minimum() === LT.Utilities.AFFrameSimpleState_On){
            mini = true
        }else{
            mini = false
        }

        LTSubFunction.console_debug.out("af_info_pointone_Changed s="+s+" f="+f+" x="+x+" y="+y+" w="+w+" h="+h)

        if (deviceAdapter.meteringMode == LT.Utilities.MM_Spot
            && (afframe.mode == afframe.afmode_chase || afframe.mode == afframe.afmode_chase_af)) {
            afframe.center_keep = true
        } else {
            afframe.center_keep = false
        }

        LTSubFunction.console_debug.out("af_info_pointone_Changed center_keep = " + afframe.center_keep)

        //AF情報ステータス 0x9401 0x01000011 AFステータス関連する情報
        //パラメータ１：ＡＦステータス
        //0 AF合焦OK
        //1 AF合焦OK：AF合焦枠表示なし
        //2 AF合焦NG
        //3 AFキャンセル
        //4 ローライトAF中
        //5 スターライトAF完了
        //0x0000FFFF 非合焦

        //合焦枠情報 0x9401 0x01000012 AF合焦枠に関する情報 パラメータ２：AF合焦枠情報
        //0 AF枠表示：なし
        //1 AF枠表示：緑枠
        //2 AF枠表示：赤枠
        //3 AF枠表示：緑枠（大）
        //4 AF枠表示：赤枠（大）
        //5 AF枠表示：スポット
        //6 AF枠表示：白枠（大）
        //7 AF枠表示：星空

        //簡易1点AF状態 0x9402 0x020001D1 1点・顔AF枠設定に関連する情報 パラメータ５：簡易１点AF状態
        //0 簡易1点AF OFF
        //1 簡易1点AF ON

        // 顔未検出
        if(d === 0){
            for(var i = 0; i < 15; i ++) {
                afframe.changeValueFaceDetect(i,0,0,0,0,0,0,0,0)
            }
        }
        
        //・AF情報ステータスが、「スターライトAF完了」の場合
        // AF枠を表示しない
        if(s == LT.Utilities.AfInfoStatus_StrRight) {
            afframe.changeValuePointOneCenter(afframe.afcv_1p_cen_no_disp, x, y, w, h, false)
        }
        // 自動認識ONの場合
        else if(d !== 0 &&
                deviceAdapter.automaticRecoEnable && 
                deviceAdapter.automaticReco &&
                deviceAdapter.autoRecognizeGeneralEnable &&
                deviceAdapter.autoRecognizeGeneral !== LT.Utilities.AR_GENERAL_OFF) {
            // 顔枠表示
            afframe.changeValuePointOneCenter(afframe.afcv_1p_cen_unfoc_prog, x, y, w, h, mini)
            root.af_info_face_simple()
        }
        else if(human !== 0 &&
                deviceAdapter.automaticRecoEnable && 
                deviceAdapter.automaticReco &&
                deviceAdapter.autoRecognizeGeneralEnable &&
                deviceAdapter.autoRecognizeGeneral !== LT.Utilities.AR_GENERAL_OFF) {
            // 人体検出は表示未対応
            afframe.changeValuePointOneCenter(afframe.afcv_1p_cen_unfoc_prog, x, y, w, h, mini)
        }
        // 認識切替有効の場合
        else if(d !== 0 &&
                deviceAdapter.autoRecognizeGeneralEnable &&
                deviceAdapter.autoRecognizeGeneral !== LT.Utilities.AR_GENERAL_OFF) {
            // 顔枠表示
            afframe.changeValuePointOneCenter(afframe.afcv_1p_cen_unfoc_prog, x, y, w, h, mini)
            root.af_info_face_simple()
        }
        else if(human !== 0 &&
                deviceAdapter.autoRecognizeGeneralEnable &&
                deviceAdapter.autoRecognizeGeneral !== LT.Utilities.AR_GENERAL_OFF) {
            // 人体検出は表示未対応
            afframe.changeValuePointOneCenter(afframe.afcv_1p_cen_unfoc_prog, x, y, w, h, mini)
        }
        else {
            //・上記条件に当てはまらない場合
            // １点表示
            af_info_pointone_simple(mini)
        }
    }

    function af_info_pointone_simple(mini) {
        var s = deviceAdapter.af_status_ulAFStatus();
        var f = 0
        if(deviceAdapter.af_pdaf_info() === LT.Utilities.AfInfoPDAFInfo_ON){
            f = deviceAdapter.af_pdaf_display_DispInfo(0)
        }else{
            f = deviceAdapter.af_display_DispInfo(0);
        }
        var x = deviceAdapter.af_onepoin_frame_pos_X();
        var y = deviceAdapter.af_onepoin_frame_pos_Y();
        var w = deviceAdapter.af_onepoin_frame_width();
        var h = deviceAdapter.af_onepoin_frame_height();
        
        if (deviceAdapter.meteringMode == LT.Utilities.MM_Spot
            && (afframe.mode == afframe.afmode_chase || afframe.mode == afframe.afmode_chase_af)) {
            afframe.center_keep = true
        } else {
            afframe.center_keep = false
        }

        //・AF情報ステータスが、「非合焦」または、「ローライトAF中」の場合
        // １点白表示
        if ((s == LT.Utilities.AfInfoStatus_InProgress)
                 || (s == LT.Utilities.AfInfoStatus_Unfocused)
                 || (s == LT.Utilities.AfInfoStatus_LowRight)) {
            afframe.changeValuePointOneCenter(afframe.afcv_1p_cen_unfoc_prog, x, y, w, h, mini)
        }
        //合焦枠情報の０番目の値が「AF枠表示：緑枠(大)」の場合、緑で表示。
        // 枠（大）表示
        else if (f == LT.Utilities.AfInfoDispFrame_Green_Big) {
            afframe.changeValuePointOneCenter(afframe.afcv_1p_cen_big_green, x, y, w, h, mini)
        }
        //合焦枠情報の０番目の値が「AF枠表示：赤枠(大)」の場合、赤で表示。
        // 枠（大）表示
        else if (f == LT.Utilities.AfInfoDispFrame_Red_Big) {
            afframe.changeValuePointOneCenter(afframe.afcv_1p_cen_big_red, x, y, w, h, mini)
        }
        //合焦枠情報の０番目の値が「AF枠表示：白枠(大)」の場合、白で表示。
        // 枠（大）表示
        else if (f == LT.Utilities.AfInfoDispFrame_White) {
            afframe.changeValuePointOneCenter(afframe.afcv_1p_cen_white, x, y, w, h, mini)
        }
        //・上記条件に当てはまらない場合
        // １点表示
        //AF情報ステータスが、「非合焦」、「ローライトAF中」の場合、白で表示
        else if ((s == LT.Utilities.AfInfoStatus_InProgress)
                 || (s == LT.Utilities.AfInfoStatus_Unfocused)
                 || (s == LT.Utilities.AfInfoStatus_LowRight)) {
            afframe.changeValuePointOneCenter(afframe.afcv_1p_cen_other, x, y, w, h, mini)
        }
        //合焦枠情報の０番目の値が「AF枠表示：緑枠」の場合、緑で表示。
        else if (f == LT.Utilities.AfInfoDispFrame_Green) {
            afframe.changeValuePointOneCenter(afframe.afcv_1p_cen_green, x, y, w, h, mini)
        }
        //合焦枠情報の０番目の値が「AF枠表示：赤枠」の場合、赤で表示。
        else if (f == LT.Utilities.AfInfoDispFrame_Red) {
            afframe.changeValuePointOneCenter(afframe.afcv_1p_cen_red, x, y, w, h, mini)
        }
        //合焦枠情報の０番目の値が上記以外の場合、白で表示。
        else {
            afframe.changeValuePointOneCenter(afframe.afcv_1p_cen_default, x, y, w, h, mini)
        }
    }

    // ivc >> start >> No.3 -> nakhuong
    function af_info_pointone_aux_Changed() {
        var s = deviceAdapter.af_status_ulAFStatus();
        var f = 0
        if(deviceAdapter.af_pdaf_info() === LT.Utilities.AfInfoPDAFInfo_ON){
            f = deviceAdapter.af_pdaf_display_DispInfo(0)
        }else{
            f = deviceAdapter.af_display_DispInfo(0);
        }
        var x = deviceAdapter.af_onepoin_frame_pos_X();
        var y = deviceAdapter.af_onepoin_frame_pos_Y();
        var w = deviceAdapter.af_onepoin_frame_width();
        var h = deviceAdapter.af_onepoin_frame_height();
        var v = deviceAdapter.af_onepoin_frame_val();
        var d = deviceAdapter.af_faceinfo_face_detect_status(0);
        var human = deviceAdapter.af_human_detect_info_status(0);
        var mini = false;
        if(deviceAdapter.af_onepoin_frame_minimum() === LT.Utilities.AFFrameSimpleState_On){
            mini = true
        }else{
            mini = false
        }

        LTSubFunction.console_debug.out("af_info_pointone_aux_Changed s="+s+" f="+f+" x="+x+" y="+y+" w="+w+" h="+h +" v="+v)

        if (deviceAdapter.meteringMode == LT.Utilities.MM_Spot
            && (afframe.mode == afframe.afmode_chase || afframe.mode == afframe.afmode_chase_af)) {
            afframe.center_keep = true
        } else {
            afframe.center_keep = false
        }

        LTSubFunction.console_debug.out("af_info_pointone_aux_Changed center_keep = " + afframe.center_keep)

        //AF情報ステータス 0x9401 0x01000011 AFステータス関連する情報
        //パラメータ１：ＡＦステータス
        //0 AF合焦OK
        //1 AF合焦OK：AF合焦枠表示なし
        //2 AF合焦NG
        //3 AFキャンセル
        //4 ローライトAF中
        //5 スターライトAF完了
        //0x0000FFFF 非合焦

        //合焦枠情報 0x9401 0x01000012 AF合焦枠に関する情報 パラメータ２：AF合焦枠情報
        //0 AF枠表示：なし
        //1 AF枠表示：緑枠
        //2 AF枠表示：赤枠
        //3 AF枠表示：緑枠（大）
        //4 AF枠表示：赤枠（大）
        //5 AF枠表示：スポット
        //6 AF枠表示：白枠（大）
        //7 AF枠表示：星空

        //簡易1点AF状態 0x9402 0x020001D1 1点・顔AF枠設定に関連する情報 パラメータ５：簡易１点AF状態
        //0 簡易1点AF OFF
        //1 簡易1点AF ON

        // 顔未検出
        if(d === 0){
            for(var i = 0; i < 15; i ++) {
                afframe.changeValueFaceDetect(i,0,0,0,0,0,0,0,0)
            }
        }
        
        //・AF情報ステータスが、「スターライトAF完了」の場合
        // AF枠を表示しない
        if(s == LT.Utilities.AfInfoStatus_StrRight) {
            afframe.changeValuePointOneAuxCenter(afframe.afcv_1p_cen_no_disp, x, y, w, h, false)
        }
        // 自動認識ONの場合
        else if(d !== 0 &&
                deviceAdapter.automaticRecoEnable && 
                deviceAdapter.automaticReco &&
                deviceAdapter.autoRecognizeGeneralEnable &&
                deviceAdapter.autoRecognizeGeneral !== LT.Utilities.AR_GENERAL_OFF) {
            // 顔枠表示
            afframe.changeValuePointOneAuxCenter(afframe.afcv_1p_cen_unfoc_prog, x, y, w, h, mini)
            root.af_info_face_simple()
        }
        else if(human !== 0 &&
                deviceAdapter.automaticRecoEnable && 
                deviceAdapter.automaticReco &&
                deviceAdapter.autoRecognizeGeneralEnable &&
                deviceAdapter.autoRecognizeGeneral !== LT.Utilities.AR_GENERAL_OFF) {
            // 人体検出は表示未対応
            afframe.changeValuePointOneAuxCenter(afframe.afcv_1p_cen_unfoc_prog, x, y, w, h, mini)
        }
        // 認識切替有効の場合
        else if(d !== 0 &&
                deviceAdapter.autoRecognizeGeneralEnable &&
                deviceAdapter.autoRecognizeGeneral !== LT.Utilities.AR_GENERAL_OFF) {
            // 顔枠表示
            afframe.changeValuePointOneAuxCenter(afframe.afcv_1p_cen_unfoc_prog, x, y, w, h, mini)
            root.af_info_face_simple()
        }
        else if(human !== 0 &&
                deviceAdapter.autoRecognizeGeneralEnable &&
                deviceAdapter.autoRecognizeGeneral !== LT.Utilities.AR_GENERAL_OFF) {
            // 人体検出は表示未対応
            afframe.changeValuePointOneAuxCenter(afframe.afcv_1p_cen_unfoc_prog, x, y, w, h, mini)
        }
        //・AF情報ステータスが、「非合焦」または、「ローライトAF中」の場合
        // １点白表示
        else if ((s == LT.Utilities.AfInfoStatus_InProgress)
                 || (s == LT.Utilities.AfInfoStatus_Unfocused)
                 || (s == LT.Utilities.AfInfoStatus_LowRight)) {
            afframe.changeValuePointOneAuxCenter(afframe.afcv_1p_cen_unfoc_prog, x, y, w, h, mini)
        }
        //合焦枠情報の０番目の値が「AF枠表示：緑枠(大)」の場合、緑で表示。
        // 枠（大）表示
        else if (f == LT.Utilities.AfInfoDispFrame_Green_Big) {
            afframe.changeValuePointOneAuxCenter(afframe.afcv_1p_cen_big_green, x, y, w, h, mini)
        }
        //合焦枠情報の０番目の値が「AF枠表示：赤枠(大)」の場合、赤で表示。
        // 枠（大）表示
        else if (f == LT.Utilities.AfInfoDispFrame_Red_Big) {
            afframe.changeValuePointOneAuxCenter(afframe.afcv_1p_cen_big_red, x, y, w, h, mini)
        }
        //合焦枠情報の０番目の値が「AF枠表示：白枠(大)」の場合、白で表示。
        // 枠（大）表示
        else if (f == LT.Utilities.AfInfoDispFrame_White) {
            afframe.changeValuePointOneAuxCenter(afframe.afcv_1p_cen_white, x, y, w, h, mini)
        }
        //・上記条件に当てはまらない場合
        // １点表示
        //AF情報ステータスが、「非合焦」、「ローライトAF中」の場合、白で表示
        else if ((s == LT.Utilities.AfInfoStatus_InProgress)
                 || (s == LT.Utilities.AfInfoStatus_Unfocused)
                 || (s == LT.Utilities.AfInfoStatus_LowRight)) {
            afframe.changeValuePointOneAuxCenter(afframe.afcv_1p_cen_other, x, y, w, h, mini)
        }
        //合焦枠情報の０番目の値が「AF枠表示：緑枠」の場合、緑で表示。
        else if (f == LT.Utilities.AfInfoDispFrame_Green) {
            afframe.changeValuePointOneAuxCenter(afframe.afcv_1p_cen_green, x, y, w, h, mini)
        }
        //合焦枠情報の０番目の値が「AF枠表示：赤枠」の場合、赤で表示。
        else if (f == LT.Utilities.AfInfoDispFrame_Red) {
            afframe.changeValuePointOneAuxCenter(afframe.afcv_1p_cen_red, x, y, w, h, mini)
        }
        //合焦枠情報の０番目の値が上記以外の場合、白で表示。
        else {
            afframe.changeValuePointOneAuxCenter(afframe.afcv_1p_cen_default, x, y, w, h, mini)
        }
    }
    // ivc << end << No.3 -> nakhuong

    function af_info_point225_Changed() {
        LTSubFunction.console_debug.out("af_info_point225_Changed start")
        var s = deviceAdapter.af_status_ulAFStatus();
        var dn = 0
        var f = 0
        if(deviceAdapter.af_pdaf_info() === LT.Utilities.AfInfoPDAFInfo_ON){
            dn = deviceAdapter.af_pdaf_display_DispNum();
            f = deviceAdapter.af_pdaf_display_DispInfo(0)
        }else{
            dn = deviceAdapter.af_display_DispNum();
            f = deviceAdapter.af_display_DispInfo(0);
        }
        var x = deviceAdapter.af_onepoin_frame_pos_X();
        var y = deviceAdapter.af_onepoin_frame_pos_Y();
        var w = deviceAdapter.af_onepoin_frame_width();
        var h = deviceAdapter.af_onepoin_frame_height();
        var v = deviceAdapter.af_onepoin_frame_val();
        var d = deviceAdapter.af_faceinfo_face_detect_status(0);
        var human = deviceAdapter.af_human_detect_info_status(0);
        var mi = deviceAdapter.af_afmulti_pos_index();
        var ms = deviceAdapter.af_afmulti_pos_size();
        var mini = false;
        if(deviceAdapter.af_onepoin_frame_minimum() === LT.Utilities.AFFrameSimpleState_On){
            mini = true
        }else{
            mini = false
        }
        LTSubFunction.console_debug.out("af_info_point225_Changed s="+s+" f="+f+" x="+x+" y="+y+" w="+w+" h="+h+" v="+v+" mi="+mi+" ms="+ms+" dn="+dn)

        afframe.center_keep = false
        if(deviceAdapter.meteringMode == LT.Utilities.MM_Spot) {
            switch(afframe.mode) {
            case afframe.afmode_point225://
            case afframe.afmode_point225f://
            case afframe.afmode_fullarea://
            case afframe.afmode_fullareaf://
            case afframe.afmode_fullarea_af://
            case afframe.afmode_fullareaf_af://
                if(!afaeStartFlg) {
                    afframe.center_keep = true
                }
                break;
            }
        }

        // 顔未検出
        if(d === 0){
            for(var i = 0; i < 15; i ++) {
                afframe.changeValueFaceDetect(i,0,0,0,0,0,0,0,0)
            }
        }
        
        // PDAF表示設定
        afframe.pdafInfoSetting()
        // AF枠行列数設定
        afInfoFrameNumSetting()
        
        //表示が不要な場合はpos_indexに0xFFFFを渡すように修正します。
        //テザーアプリで0xFFFFのときには枠を表示しない対応をお願いいたします。
        if ( (mi == LT.Utilities.AFFrameMultiAfPos_Unknown)
              || (mi == LT.Utilities.AFFrameMultiAfPos_Invalid) ) {
            afframe.changeValuePoint225(afframe.afcv_225p_no_disp, x, y, w, h, mi, ms, dn)
        }
        //・AF情報ステータスが、「スターライトAF完了」の場合
        // AF枠を表示しない
        if(s == LT.Utilities.AfInfoStatus_StrRight) {
            afframe.changeValuePoint225(afframe.afcv_225p_no_disp, x, y, w, h, mi, ms, dn)
        }
        // 自動認識ONの場合
        else if(d !== 0 &&
                deviceAdapter.automaticRecoEnable && 
                deviceAdapter.automaticReco &&
                deviceAdapter.autoRecognizeGeneralEnable &&
                deviceAdapter.autoRecognizeGeneral !== LT.Utilities.AR_GENERAL_OFF) {
            // 顔枠表示
            root.af_info_face_simple()
        }
        else if(human !== 0 &&
                deviceAdapter.automaticRecoEnable && 
                deviceAdapter.automaticReco &&
                deviceAdapter.autoRecognizeGeneralEnable &&
                deviceAdapter.autoRecognizeGeneral !== LT.Utilities.AR_GENERAL_OFF) {
            // 人体検出は表示未対応
        }
        //・簡易１点AF状態が、「簡易1点AF ON」の場合
        // １点処理を行う
        else if(v == LT.Utilities.AFFrameSimpleState_On) {
            //afframe.changeValuePointOneCenter(1, x, y, w, h)
            af_info_pointone_simple(mini)
        }
        //・AF情報ステータスが、「非合焦」または、「ローライトAF中」の場合
        // テザーアプリのAF枠表示がONの場合はAF枠表示
        else if ((s == LT.Utilities.AfInfoStatus_InProgress)
                 || (s == LT.Utilities.AfInfoStatus_Unfocused)
                 || (s == LT.Utilities.AfInfoStatus_LowRight)) {
            afframe.changeValuePoint225(afframe.afcv_225p_unfoc_prog, x, y, w, h, mi, ms, dn)
        }
        //・合焦枠情報の0番目の値が、「AF枠表示：緑枠（大）」、「AF枠表示：赤枠（大）」、「AF枠表示：白枠（大）」のいずれかの場合
        // 枠（大）表示
        else if (f == LT.Utilities.AfInfoDispFrame_White) {
            afframe.changeValuePoint225(afframe.afcv_225p_big_green, x, y, w, h, mi, ms, dn)
        }
        else if (f == LT.Utilities.AfInfoDispFrame_Green_Big) {
            afframe.changeValuePoint225(afframe.afcv_225p_big_red, x, y, w, h, mi, ms, dn)
        }
        else if (f == LT.Utilities.AfInfoDispFrame_Red_Big) {
            afframe.changeValuePoint225(afframe.afcv_225p_white, x, y, w, h, mi, ms, dn)
        }
        //・上記条件に当てはまらない場合
        // 225点表示
        else {
            afframe.changeValuePoint225(afframe.afcv_225p_default, x, y, w, h, mi, ms, dn)
        }
    }
    function af_info_custom_Changed() {
        LTSubFunction.console_debug.out("af_info_custom_Changed start")
        var s = deviceAdapter.af_status_ulAFStatus();
        var dn = 0
        var f = 0
        var isPDAF = false
        if(deviceAdapter.af_pdaf_info() === LT.Utilities.AfInfoPDAFInfo_ON){
            isPDAF = true
            dn = deviceAdapter.af_pdaf_display_DispNum();
            f = deviceAdapter.af_pdaf_display_DispInfo(0)
        }else{
            isPDAF = false
            dn = deviceAdapter.af_display_DispNum();
            f = deviceAdapter.af_display_DispInfo(0);
        }
        var x = deviceAdapter.af_onepoin_frame_pos_X();
        var y = deviceAdapter.af_onepoin_frame_pos_Y();
        var w = deviceAdapter.af_onepoin_frame_width();
        var h = deviceAdapter.af_onepoin_frame_height();
        var v = deviceAdapter.af_onepoin_frame_val();
        var d = deviceAdapter.af_faceinfo_face_detect_status(0);
        var human = deviceAdapter.af_human_detect_info_status(0);
        var mi = deviceAdapter.af_afmulti_pos_index();
        var ms = deviceAdapter.af_afmulti_pos_size();
        var ci = deviceAdapter.af_cmulti_table_cur_index();
        LTSubFunction.console_debug.out("af_info_custom_Changed s="+s+" f="+f+" x="+x+" y="+y+" w="+w+" h="+h+" v="+v+" mi="+mi+" ms="+ms+" dn="+dn+" ci="+ci)

        afframe.center_keep = false
        switch(deviceAdapter.autoFocusMode) {
        case LT.DeviceAdapter.AFM_CustomVertical:
        case LT.DeviceAdapter.AFM_CustomHorizon:
        case LT.DeviceAdapter.AFM_CustomCenter:
        case LT.DeviceAdapter.AFM_CustomC1:
        case LT.DeviceAdapter.AFM_CustomC2:
        case LT.DeviceAdapter.AFM_CustomC3:
            if(deviceAdapter.meteringMode == LT.Utilities.MM_Spot) {
                switch(afframe.mode) {
                case afframe.afmode_custom://
                case afframe.afmode_customf://
                    afframe.center_keep = true
                    LTSubFunction.console_debug.out("af_info_custom_Changed custom center_keep 1")
                    break;
                default:
                    // ここでは何もしない
                    LTSubFunction.console_debug.out("af_info_custom_Changed custom not center_keep 2")
                    break;
                }
            } else {
                LTSubFunction.console_debug.out("af_info_custom_Changed custom not center_keep 3")
            }
            break;
        case LT.DeviceAdapter.AFM_VertHori:
        case LT.DeviceAdapter.AFM_Ellipse:
            LTSubFunction.console_debug.out("af_info_custom_Changed custom not center_keep 4")
            break;
        case LT.DeviceAdapter.AFM_Custom1:
        case LT.DeviceAdapter.AFM_Custom2:
        case LT.DeviceAdapter.AFM_Custom3:
            if(deviceAdapter.meteringMode == LT.Utilities.MM_Spot) {
                switch(afframe.mode) {
                case afframe.afmode_custom://
                case afframe.afmode_customf://
                case afframe.afmode_custom_af://
                case afframe.afmode_customf_af://
                    afframe.center_keep = true
                    LTSubFunction.console_debug.out("af_info_custom_Changed custom center_keep 5")
                    break;
                default:
                    // ここでは何もしない
                    LTSubFunction.console_debug.out("af_info_custom_Changed custom not center_keep 6")
                    break;
                }
            } else {
                LTSubFunction.console_debug.out("af_info_custom_Changed custom not center_keep 7")
            }
            break;
        }

        // 顔未検出
        if(d === 0){
            for(var i = 0; i < 15; i ++) {
                afframe.changeValueFaceDetect(i,0,0,0,0,0,0,0,0)
            }
        }
        
        // PDAF表示設定
        afframe.pdafInfoSetting()
        // AF枠行列数設定
        afInfoFrameNumSetting()
        
        //・AF情報ステータスが、「スターライトAF完了」の場合
        // AF枠を表示しない
        if(s == LT.Utilities.AfInfoStatus_StrRight) {
            LTSubFunction.console_debug.out("af_info_custom_Changed 1")
            afframe.changeValueCustom(afframe.afcv_225p_no_disp, ci, ms, dn)
            afframe.changeValuePointOneCenter(afframe.afcv_1p_cen_no_disp, x, y, w, h, false)
        }
        // 自動認識ONの場合
        else if(d !== 0 &&
                deviceAdapter.automaticRecoEnable && 
                deviceAdapter.automaticReco &&
                deviceAdapter.autoRecognizeGeneralEnable &&
                deviceAdapter.autoRecognizeGeneral !== LT.Utilities.AR_GENERAL_OFF) {
            //・簡易１点AF状態が、「簡易1点AF OFF」の場合
            // AF枠を表示しない
            if(v == LT.Utilities.AFFrameSimpleState_Off) {
                afframe.changeValuePointOneCenter(afframe.afcv_1p_cen_no_disp, x, y, w, h, false)
            }
            // AF枠表示
            afframe.changeValueCustom(afframe.afcv_225p_unfoc_prog, ci, ms, dn)
            // 顔枠表示
            LTSubFunction.console_debug.out("af_info_custom_Changed face")
            root.af_info_face_simple()
        }
        else if(human !== 0 &&
                deviceAdapter.automaticRecoEnable && 
                deviceAdapter.automaticReco &&
                deviceAdapter.autoRecognizeGeneralEnable &&
                deviceAdapter.autoRecognizeGeneral !== LT.Utilities.AR_GENERAL_OFF) {
            //・簡易１点AF状態が、「簡易1点AF OFF」の場合
            // AF枠を表示しない
            if(v == LT.Utilities.AFFrameSimpleState_Off) {
                afframe.changeValuePointOneCenter(afframe.afcv_1p_cen_no_disp, x, y, w, h, false)
            }
            // AF枠表示
            afframe.changeValueCustom(afframe.afcv_225p_unfoc_prog, ci, ms, dn)
            // 人体検出は表示未対応
        }
        //・簡易１点AF状態が、「簡易1点AF ON」の場合
        // １点白表示
        else if(v == LT.Utilities.AFFrameSimpleState_On) {
            LTSubFunction.console_debug.out("af_info_custom_Changed 2")
            afframe.changeValuePointOneCenter(afframe.afcv_1p_cen_unfoc_prog, x, y, w, h, false)
        }
        //・AF情報ステータスが、「非合焦」または、「ローライトAF中」の場合
        // テザーアプリのAF枠表示がONの場合はAF枠表示
        else if ((s == LT.Utilities.AfInfoStatus_InProgress)
                 || (s == LT.Utilities.AfInfoStatus_Unfocused)
                 || (s == LT.Utilities.AfInfoStatus_LowRight)) {
            LTSubFunction.console_debug.out("af_info_custom_Changed 3")
            //・簡易１点AF状態が、「簡易1点AF OFF」の場合
            // AF枠を表示しない
            if(v == LT.Utilities.AFFrameSimpleState_Off) {
                afframe.changeValuePointOneCenter(afframe.afcv_1p_cen_no_disp, x, y, w, h, false)
            }
            // AF枠表示
            afframe.changeValueCustom(afframe.afcv_225p_default, ci, ms, dn)
        }
        //・合焦枠情報の0番目の値が、「AF枠表示：緑枠（大）」、「AF枠表示：赤枠（大）」、「AF枠表示：白枠（大）」のいずれかの場合
        // 枠（大）表示
        else if (f == LT.Utilities.AfInfoDispFrame_White) {
            LTSubFunction.console_debug.out("af_info_custom_Changed 4")
            afframe.changeValueCustom(afframe.afcv_225p_big_green, ci, ms, dn)
            afframe.changeValuePointOneCenter(afframe.afcv_1p_cen_no_disp, x, y, w, h, false)
        }
        else if (f == LT.Utilities.AfInfoDispFrame_Green_Big) {
            LTSubFunction.console_debug.out("af_info_custom_Changed 5")
            afframe.changeValueCustom(afframe.afcv_225p_big_red, ci, ms, dn)
            afframe.changeValuePointOneCenter(afframe.afcv_1p_cen_no_disp, x, y, w, h, false)
        }
        else if (f == LT.Utilities.AfInfoDispFrame_Red_Big) {
            LTSubFunction.console_debug.out("af_info_custom_Changed 6")
            afframe.changeValueCustom(afframe.afcv_225p_white, ci, ms, dn)
            afframe.changeValuePointOneCenter(afframe.afcv_1p_cen_no_disp, x, y, w, h, false)
        }
        //・上記条件に当てはまらない場合
        // 225点表示
        else {
            LTSubFunction.console_debug.out("af_info_custom_Changed 7")
            //・簡易１点AF状態が、「簡易1点AF OFF」の場合
            // AF枠を表示しない
            if(v == LT.Utilities.AFFrameSimpleState_Off) {
                afframe.changeValuePointOneCenter(afframe.afcv_1p_cen_no_disp, x, y, w, h, false)
            }
            // AF枠表示
            afframe.changeValueCustom(afframe.afcv_225p_default, ci, ms, dn)
        }
    }
    function af_info_face_Changed() {
        LTSubFunction.console_debug.out("af_info_face_Changed start")
        var s = deviceAdapter.af_status_ulAFStatus();
        var f = 0
        if(deviceAdapter.af_pdaf_info() === LT.Utilities.AfInfoPDAFInfo_ON){
            f = deviceAdapter.af_pdaf_display_DispInfo(0)
        }else{
            f = deviceAdapter.af_display_DispInfo(0);
        }
        var x = deviceAdapter.af_onepoin_frame_pos_X();
        var y = deviceAdapter.af_onepoin_frame_pos_Y();
        var w = deviceAdapter.af_onepoin_frame_width();
        var h = deviceAdapter.af_onepoin_frame_height();
        var d = deviceAdapter.af_faceinfo_face_detect_status(0);
        var human = deviceAdapter.af_human_detect_info_status(0);
        var v = deviceAdapter.af_onepoin_frame_val();
        var mi = deviceAdapter.af_afmulti_pos_index();
        var ms = deviceAdapter.af_afmulti_pos_size();
        var dn = deviceAdapter.af_display_DispNum();
        LTSubFunction.console_debug.out("af_info_face_Changed s="+s+" f="+f+" x="+x+" y="+y+" w="+w+" h="+h+" d="+d+" v="+v+" mi="+mi+" ms="+ms+" dn="+dn)

        switch(afframe.mode) {
        case afframe.afmode_face://
        case afframe.afmode_face_eye://
        case afframe.afmode_face_af://
        case afframe.afmode_face_225://
            afframe.center_keep = true
            break;
        default:
            afframe.center_keep = false
            break;
        }
        //AF情報ステータス 0x9401 0x01000011 AFステータス関連する情報
        //パラメータ１：ＡＦステータス
        //0 AF合焦OK
        //1 AF合焦OK：AF合焦枠表示なし
        //2 AF合焦NG
        //3 AFキャンセル
        //4 ローライトAF中
        //5 スターライトAF完了
        //0x0000FFFF 非合焦
        //合焦枠情報 0x9401 0x01000012 AF合焦枠に関する情報 パラメータ２：AF合焦枠情報
        //0 AF枠表示：なし
        //1 AF枠表示：緑枠
        //2 AF枠表示：赤枠
        //3 AF枠表示：緑枠（大）
        //4 AF枠表示：赤枠（大）
        //5 AF枠表示：スポット
        //6 AF枠表示：白枠（大）
        //7 AF枠表示：星空
        //LMX_DEF_AFINFO_FACEDETECT_STATUS_NOT_DETECT 0x00 AF情報：顔検出ステータス：未検出
        //LMX_DEF_AFINFO_FACEDETECT_STATUS_DETECT 0x01 AF情報：顔検出ステータス：検出
        //LMX_DEF_AFINFO_FACEDETECT_STATUS_IMPORTANT 0x02 AF情報：顔検出ステータス：重要顔

        // PDAF表示設定
        afframe.pdafInfoSetting()
        
        //・AF情報ステータスが、「スターライトAF完了」の場合
        //  AF枠を表示しない
        if(s == LT.Utilities.AfInfoStatus_StrRight) {
            //LTSubFunction.console_debug.out("af_info_face_Changed 2")
            afframe.changeValuePointOneCenter(afframe.afcv_1p_cen_no_disp, x, y, w, h, false)
            for(var i = 0; i < 15; i ++) {
                afframe.changeValueFaceDetect(i,0,0,0,0,0,0,0,0)
            }
            afframe.changeValuePoint225(afframe.afcv_1p_cen_no_disp, 0, 0, 0, 0, 0, 0, 0)
        }
        //・顔検出情報の０番目のパラメータ：検出顔ステータスが「未検出」の場合
        //・人体検出情報の０番目のパラメータ：人体検出ステータスが「未検出」の場合
        //  ・AF情報ステータスが、「非合焦」、「ローライトAF中」以外の場合
        //    2.1の処理で225点表示する
        else if ( ((s != LT.Utilities.AfInfoStatus_Unfocused)
                   && (s != LT.Utilities.AfInfoStatus_InProgress)
                   && (s != LT.Utilities.AfInfoStatus_LowRight))
                 && (d == 0) && (human == 0) ) {
            if( (afframe.mode == afframe.afmode_face) || (afframe.mode == afframe.afmode_face_af) ) {
                //LTSubFunction.console_debug.out("af_info_face_Changed 3")
                //afframe.changeMode(afframe.afmode_face_225)
            }
            //LTSubFunction.console_debug.out("af_info_face_Changed 4")
            for(var i = 0; i < 15; i ++) {
                afframe.changeValueFaceDetect(i,0,0,0,0,0,0,0,0)
            }
            af_info_point225_Changed()
            //afframe.changeValuePoint225(7, x, y, w, h, mi, ms, dn)
        }
        //・合焦枠情報の0番目の値が、「AF枠表示：緑枠（大）」、「AF枠表示：赤枠（大）」、「AF枠表示：白枠（大）」のいずれかの場合
        //  枠（大）表示
        else if (f == LT.Utilities.AfInfoDispFrame_White) {
            if( (afframe.mode == afframe.afmode_face_af) || (afframe.mode == afframe.afmode_face_225) ) {
                //LTSubFunction.console_debug.out("af_info_face_Changed 5")
                afframe.changeMode(afframe.afmode_face)
            }
            //LTSubFunction.console_debug.out("af_info_face_Changed 6")
            afframe.changeValuePointOneCenter(afframe.afcv_1p_cen_big_green, x, y, w, h, false)
            for(var i = 0; i < 15; i ++) {
                afframe.changeValueFaceDetect(i,0,0,0,0,0,0,0,0)
            }
            afframe.changeValuePoint225(afframe.afcv_1p_cen_no_disp, 0, 0, 0, 0, 0, 0, 0)
        }
        else if (f == LT.Utilities.AfInfoDispFrame_Green_Big) {
            if( (afframe.mode == afframe.afmode_face_af) || (afframe.mode == afframe.afmode_face_225) ) {
                //LTSubFunction.console_debug.out("af_info_face_Changed 7")
                afframe.changeMode(afframe.afmode_face)
            }
            //LTSubFunction.console_debug.out("af_info_face_Changed 8")
            afframe.changeValuePointOneCenter(afframe.afcv_1p_cen_big_red, x, y, w, h, false)
            for(var i = 0; i < 15; i ++) {
                afframe.changeValueFaceDetect(i,0,0,0,0,0,0,0,0)
            }
            afframe.changeValuePoint225(afframe.afcv_1p_cen_no_disp, 0, 0, 0, 0, 0, 0, 0)
        }
        else if (f == LT.Utilities.AfInfoDispFrame_Red_Big) {
            if( (afframe.mode == afframe.afmode_face_af) || (afframe.mode == afframe.afmode_face_225) ) {
                //LTSubFunction.console_debug.out("af_info_face_Changed 9")
                afframe.changeMode(afframe.afmode_face)
            }
            //LTSubFunction.console_debug.out("af_info_face_Changed 10")
            afframe.changeValuePointOneCenter(afframe.afcv_1p_cen_white, x, y, w, h, false)
            for(var i = 0; i < 15; i ++) {
                afframe.changeValueFaceDetect(i,0,0,0,0,0,0,0,0)
            }
            afframe.changeValuePoint225(afframe.afcv_1p_cen_no_disp, 0, 0, 0, 0, 0, 0, 0)
        }
        //・上記条件に当てはまらない場合
        //  顔枠表示
        else {
            //if( (afframe.mode == afframe.afmode_face) || (afframe.mode == afframe.afmode_face_225) ) {
            if( afframe.mode == afframe.afmode_face_225 ) {
                //LTSubFunction.console_debug.out("af_info_face_Changed 11")
                afframe.changeMode(afframe.afmode_face_af)
            }
            LTSubFunction.console_debug.out("af_info_face_Changed 12")
            var faceinfo_face_detect_num = deviceAdapter.af_faceinfo_face_detect_num();
            var start_index = 0
            var end_index = 15
            for(var i = start_index; i < end_index; i ++) {
                var dx = deviceAdapter.af_faceinfo_face_detect_face_pos_pos_X(i);
                var dy = deviceAdapter.af_faceinfo_face_detect_face_pos_pos_Y(i);
                var dlx = deviceAdapter.af_faceinfo_face_detect_frame_length_X(i);
                var dly = deviceAdapter.af_faceinfo_face_detect_frame_length_Y(i);
                var ds = deviceAdapter.af_faceinfo_face_detect_status(i);
                afframe.changeValueFaceDetect(i,ds,s,f,v,dx,dy,dlx,dly)
            }
            //  ・簡易１点AF状態が、「簡易1点AF ON」の場合
            //    顔枠に加えて2.2の処理で1点表示する
            if(v == LT.Utilities.AFFrameSimpleState_On) {
                root.af_info_pointone_simple(false)
            } else {
                afframe.changeValuePointOneCenter(afframe.afcv_1p_cen_no_disp, x, y, w, h, false)
            }
            afframe.changeValuePoint225(afframe.afcv_1p_cen_no_disp, 0, 0, 0, 0, 0, 0, 0)
        }
    }

    function af_info_face_simple(){
        var s = deviceAdapter.af_status_ulAFStatus();
        var f = 0
        if(deviceAdapter.af_pdaf_info() === LT.Utilities.AfInfoPDAFInfo_ON){
            f = deviceAdapter.af_pdaf_display_DispInfo(0)
        }else{
            f = deviceAdapter.af_display_DispInfo(0);
        }
        var v = deviceAdapter.af_onepoin_frame_val();
        
        var start_index = 0
        var end_index = 15
        for(var i = start_index; i < end_index; i ++) {
            var dx = deviceAdapter.af_faceinfo_face_detect_face_pos_pos_X(i);
            var dy = deviceAdapter.af_faceinfo_face_detect_face_pos_pos_Y(i);
            var dlx = deviceAdapter.af_faceinfo_face_detect_frame_length_X(i);
            var dly = deviceAdapter.af_faceinfo_face_detect_frame_length_Y(i);
            var ds = deviceAdapter.af_faceinfo_face_detect_status(i);
            afframe.changeValueFaceDetect(i,ds,s,f,v,dx,dy,dlx,dly)
        }
    }

    function af_info_chase_Changed() {
        //LTSubFunction.console_debug.out("af_info_chase_Changed")
        var s = deviceAdapter.af_status_ulAFStatus();
        var f = 0
        if(deviceAdapter.af_pdaf_info() === LT.Utilities.AfInfoPDAFInfo_ON){
            f = deviceAdapter.af_pdaf_display_DispInfo(0)
        }else{
            f = deviceAdapter.af_display_DispInfo(0);
        }
        var x = deviceAdapter.af_onepoin_frame_pos_X();
        var y = deviceAdapter.af_onepoin_frame_pos_Y();
        var w = deviceAdapter.af_onepoin_frame_width();
        var h = deviceAdapter.af_onepoin_frame_height();
        var d = deviceAdapter.af_faceinfo_face_detect_status(0);
        var human = deviceAdapter.af_human_detect_info_status(0);
        var v = deviceAdapter.af_onepoin_frame_val();
        var tx = deviceAdapter.af_tracking_tracking_pos_pos_X();
        var ty = deviceAdapter.af_tracking_tracking_pos_pos_Y();
        var tw = deviceAdapter.af_tracking_tracking_area_img_img_width();
        var th = deviceAdapter.af_tracking_tracking_area_img_img_height();
        var tpx = deviceAdapter.af_tracking_frame_pos_x();
        var tpy = deviceAdapter.af_tracking_frame_pos_y();
        LTSubFunction.console_debug.out("af_info_chase_Changed s="+s+" f="+f+" x="+x+" y="+y+" w="+w+" h"+h+" d="+d+" v="+v+" tx="+tx+" ty="+ty+" tw="+tw+" th="+th+" tpx="+tpx+" tpy="+tpy)

        if(deviceAdapter.meteringMode == LT.Utilities.MM_Spot) {
            afframe.center_keep = true
        } else {
            afframe.center_keep = false
        }
        //AF情報ステータス 0x9401 0x01000011 AFステータス関連する情報
        //パラメータ１：ＡＦステータス
        //0 AF合焦OK
        //1 AF合焦OK：AF合焦枠表示なし
        //2 AF合焦NG
        //3 AFキャンセル
        //4 ローライトAF中
        //5 スターライトAF完了
        //0x0000FFFF 非合焦
        //合焦枠情報 0x9401 0x01000012 AF合焦枠に関する情報 パラメータ２：AF合焦枠情報
        //0 AF枠表示：なし
        //1 AF枠表示：緑枠
        //2 AF枠表示：赤枠
        //3 AF枠表示：緑枠（大）
        //4 AF枠表示：赤枠（大）
        //5 AF枠表示：スポット
        //6 AF枠表示：白枠（大）
        //7 AF枠表示：星空
        //LMX_DEF_AFINFO_FACEDETECT_STATUS_NOT_DETECT 0x00 AF情報：顔検出ステータス：未検出
        //LMX_DEF_AFINFO_FACEDETECT_STATUS_DETECT 0x01 AF情報：顔検出ステータス：検出
        //LMX_DEF_AFINFO_FACEDETECT_STATUS_IMPORTANT 0x02 AF情報：顔検出ステータス：重要顔

        // 顔未検出
        if(d === 0){
            for(var i = 0; i < 15; i ++) {
                afframe.changeValueFaceDetect(i,0,0,0,0,0,0,0,0)
            }
        }
        
        //・AF情報ステータスが、「スターライトAF完了」の場合
        //  AF枠を表示しない
        if(s == LT.Utilities.AfInfoStatus_StrRight) {
            afframe.changeValueChaseDetect(afframe.afcv_chase_detect_no_disp,0,0,0,0)
        }
        // 自動認識ONの場合
        else if(d !== 0 &&
                deviceAdapter.automaticRecoEnable && 
                deviceAdapter.automaticReco &&
                deviceAdapter.autoRecognizeGeneralEnable &&
                deviceAdapter.autoRecognizeGeneral !== LT.Utilities.AR_GENERAL_OFF) {
            if (f == LT.Utilities.AfInfoDispFrame_Green) {
                afframe.changeValueChaseDetect(afframe.afcv_chase_detect_no_disp,0,0,0,0)
            }else{
                afframe.changeValueChaseDetect(afframe.afcv_chase_detect_other,tpx,tpy,0,0)
            }
            if(v == LT.Utilities.AFFrameSimpleState_Off) {
                afframe.changeValuePointOneCenter(afframe.afcv_1p_cen_no_disp, x, y, w, h, false)
            }
            // 顔枠表示
            root.af_info_face_simple()
        }
        else if(human !== 0 &&
                deviceAdapter.automaticRecoEnable && 
                deviceAdapter.automaticReco &&
                deviceAdapter.autoRecognizeGeneralEnable &&
                deviceAdapter.autoRecognizeGeneral !== LT.Utilities.AR_GENERAL_OFF) {
            if (f == LT.Utilities.AfInfoDispFrame_Green) {
                afframe.changeValueChaseDetect(afframe.afcv_chase_detect_no_disp,0,0,0,0)
            }else{
                afframe.changeValueChaseDetect(afframe.afcv_chase_detect_other,tpx,tpy,0,0)
            }
            if(v == LT.Utilities.AFFrameSimpleState_Off) {
                afframe.changeValuePointOneCenter(afframe.afcv_1p_cen_no_disp, x, y, w, h, false)
            }
            // 人体検出は表示未対応
        }
        //・簡易１点AF状態が、「簡易１点AFON」の場合
        // 2.2の処理で１点表示する
        //else if((v == 1) && (deviceAdapter.recordingMode != LT.Utilities.RM_IntelligentAuto)) {
        else if(v == LT.Utilities.AFFrameSimpleState_On) {
            afframe.changeValueChaseDetect(afframe.afcv_chase_detect_no_disp,0,0,0,0)
            root.af_info_pointone_simple(false)
        }
        //・追尾AF位置の座標が０以外の場合
        else if((tx!=0)&&(ty!=0)) {
            //・AF情報ステータスが、「非合焦」または、「ローライトAF中」の場合
            // 黄色で表示
            if ((s == LT.Utilities.AfInfoStatus_InProgress)
                || (s == LT.Utilities.AfInfoStatus_Unfocused)
                || (s == LT.Utilities.AfInfoStatus_LowRight)) {
                afframe.changeValueChaseDetect(afframe.afcv_chase_detect_unfoc_prog,tx,ty,tw,th)
            }
            //・AF情報ステータスが、「非合焦」、「ローライトAF中」以外の場合
            // ・合焦枠情報の０番目の値が「AF枠表示：緑枠」の場合
            //  緑色で表示
            else if (f == LT.Utilities.AfInfoDispFrame_Green) {
                afframe.changeValueChaseDetect(afframe.afcv_chase_detect_green,tx,ty,tw,th)
            }
            // ・合焦枠情報の０番目の値が「AF枠表示：赤枠」の場合
            //  赤色で表示
            else if (f == LT.Utilities.AfInfoDispFrame_Red) {
                afframe.changeValueChaseDetect(afframe.afcv_chase_detect_red,tx,ty,tw,th)
            }
            // ・上記条件に当てはまらない場合
            //  黄色で表示
            else {
                afframe.changeValueChaseDetect(afframe.afcv_chase_detect_yellow,tx,ty,tw,th)
            }
        }
        //・AF情報ステータスが、「非合焦」、「ローライトAF中」以外で、合焦枠情報の０番目の値が「AF枠表示：なし」以外
        // 2.2の処理で１点表示する
        else if ((s != LT.Utilities.AfInfoStatus_Unfocused)
                 && (s != LT.Utilities.AfInfoStatus_InProgress)
                 && (s != LT.Utilities.AfInfoStatus_LowRight)
                 && (f != LT.Utilities.AfInfoDispFrame_Not) ) {
            afframe.changeValueChaseDetect(afframe.afcv_chase_detect_no_disp,0,0,0,0)
            af_info_pointone_simple(false)
        }
        //・上記条件に当てはまらない場合
        // 追尾初期枠表示
        else {
            afframe.changeValueChaseDetect(afframe.afcv_chase_detect_other,tpx,tpy,0,0)
            if(v == LT.Utilities.AFFrameSimpleState_Off) {
                afframe.changeValuePointOneCenter(afframe.afcv_1p_cen_no_disp, x, y, w, h, false)
            }
        }
    }
    function af_info_pinpoint_Changed() {
        var s = deviceAdapter.af_status_ulAFStatus()
        var f = 0
        if(deviceAdapter.af_pdaf_info() === LT.Utilities.AfInfoPDAFInfo_ON){
            f = deviceAdapter.af_pdaf_display_DispInfo(0)
        }else{
            f = deviceAdapter.af_display_DispInfo(0);
        }
        var x = deviceAdapter.af_pinpoin_frame_pos_X()
        var y = deviceAdapter.af_pinpoin_frame_pos_Y()
        var w = deviceAdapter.af_pinpoin_frame_width()
        var h = deviceAdapter.af_pinpoin_frame_height()
        var v = deviceAdapter.af_onepoin_frame_val();
        var cx = deviceAdapter.af_pinpoin_frame_cursorX()
        var cy = deviceAdapter.af_pinpoin_frame_cursorY()
        var aw = deviceAdapter.af_pinpoin_frame_area_width()
        var ah = deviceAdapter.af_pinpoin_frame_area_height()
        var ctx = deviceAdapter.af_pinpoin_frame_centerX()
        var cty = deviceAdapter.af_pinpoin_frame_centerY()
        var mg = parseInt(deviceAdapter.af_magnify / 10)
        var mw = parseInt(deviceAdapter.af_pinpoin_frame_width() / mg)
        var mh = parseInt(deviceAdapter.af_pinpoin_frame_height() / mg)
        var m1 = parseInt(416 / mg)
        var m2 = parseInt(108 / mg)
        LTSubFunction.console_debug.out("af_info_pinpoint_Changed s="+s+" f="+f+" x="+x+" y="+y+" w="+w+" h="+h+" v="+v+" cx="+cx+" cy="+cy+" aw="+aw+" ah="+ah+" ctx="+ctx+" cty="+cty)

        afframe.center_keep = false
        //・AF情報ステータスが、「スターライトAF完了」の場合
        // AF枠を表示しない
        if(s == LT.Utilities.AfInfoStatus_StrRight) {
            afframe.changeValuePinpoint(afframe.afcv_pinpoint_no_disp,x,y,w,h,0,0)
        }
        //・簡易１点AF状態が、「簡易1点AF ON」の場合
        // 2.2の処理で1点表示する
        else if(v == LT.Utilities.AFFrameSimpleState_On) {
            root.af_info_pointone_simple(false)
        }
        //・AF情報ステータスが、「非合焦」または、「ローライトAF中」の場合
        // ピンポイント白表示
        else if ((s == LT.Utilities.AfInfoStatus_InProgress)
                 || (s == LT.Utilities.AfInfoStatus_Unfocused)
                 || (s == LT.Utilities.AfInfoStatus_LowRight) ) {
            //１．合焦枠表示資料でピンポイントAF：非合焦＋拡大時の記載漏れ
            // 資料で「ピンポイント白」を表示する条件で、拡大していた場合の記載が
            // ありませんでした。拡大されていた場合はピンポイント（アシスト）と同じように
            // 拡大領域内カーソル位置を使用してください。
            if(deviceAdapter.mfa_mode == LT.Utilities.AsModCur_Zoom) {
                afframe.changeValuePinpoint(afframe.afcv_pinpoint_unfoc_prog,cx,cy,w,h,0,0)
            }
            else if(deviceAdapter.mfa_mode == LT.Utilities.AsModCur_Pinp) {
                afframe.changeValuePinpoint(afframe.afcv_pinpoint_unfoc_prog,cx,cy,aw,ah,ctx,cty)
            } else {
                afframe.changeValuePinpoint(afframe.afcv_pinpoint_unfoc_prog,x,y,w,h,0,0)
            }
        }
        //・ピンポイントAF/MFアシスト枠情報の現在のモードが「OFF(0xFFFF)」以外の場合
        else if( (deviceAdapter.mfa_mode != LT.Utilities.AsModCur_Off)
                && (deviceAdapter.mfa_mode != LT.Utilities.AsModCur_Unknown) ) {
            // ・合焦枠情報の0番目の値が、「AF枠表示：緑枠（大）」、「AF枠表示：赤枠（大）」のいずれかの場合
            //  ピンポイント（アシスト大）表示
            if (f == LT.Utilities.AfInfoDispFrame_Green_Big) {
                if(deviceAdapter.mfa_mode == LT.Utilities.AsModCur_Zoom) {
                    afframe.changeValuePinpoint(afframe.afcv_pinpoint_big_green_zoom,cx,cy,416,416,0,0)
                } else if(deviceAdapter.mfa_mode == LT.Utilities.AsModCur_Pinp) {
                    afframe.changeValuePinpoint(afframe.afcv_pinpoint_big_green_pip,cx,cy,277,277,ctx,cty)//277,277,0,0)
                }
            }
            else if (f == LT.Utilities.AfInfoDispFrame_Red_Big) {
                if(deviceAdapter.mfa_mode == LT.Utilities.AsModCur_Zoom) {
                    afframe.changeValuePinpoint(afframe.afcv_pinpoint_big_red_zoom,cx,cy,416,416,0,0)
                } else if(deviceAdapter.mfa_mode == LT.Utilities.AsModCur_Pinp) {
                    afframe.changeValuePinpoint(afframe.afcv_pinpoint_big_red_pip,cx,cy,277,277,ctx,cty)//277,277,0,0)
                }
            }
            // ・上記条件に当てはまらない場合
            //  ピンポイント（アシスト）表示
            else {
                if(deviceAdapter.mfa_mode == LT.Utilities.AsModCur_Zoom) {
                    afframe.changeValuePinpoint(afframe.afcv_pinpoint_other_zoom,cx,cy,108,108,0,0)
                } else if(deviceAdapter.mfa_mode == LT.Utilities.AsModCur_Pinp) {
                    afframe.changeValuePinpoint(afframe.afcv_pinpoint_other_pip,cx,cy,108,108,ctx,cty)//108,108,0,0)
                }
            }
        }
        //・上記条件に当てはまらない場合
        // ピンポイント表示
        else {
            //合焦枠情報の０番目の値が「AF枠表示：緑枠」の場合、緑で表示。
            //合焦枠情報の０番目の値が「AF枠表示：緑枠（大)」の場合、緑で表示。
            if ( (f == LT.Utilities.AfInfoDispFrame_Green)
                  || (f == LT.Utilities.AfInfoDispFrame_Green_Big) ) {
                afframe.changeValuePinpoint(afframe.afcv_pinpoint_green,x,y,w,h,0,0)
            }
            //合焦枠情報の０番目の値が「AF枠表示：赤枠」の場合、赤で表示。
            //合焦枠情報の０番目の値が「AF枠表示：赤枠（大)」の場合、赤で表示。
            else if ((f == LT.Utilities.AfInfoDispFrame_Red)
                     || (f == LT.Utilities.AfInfoDispFrame_Red_Big) ) {
                afframe.changeValuePinpoint(afframe.afcv_pinpoint_red,x,y,w,h,0,0)
            }
            //合焦枠情報の０番目の値が上記以外の場合、白で表示。
            else {
                afframe.changeValuePinpoint(afframe.afcv_pinpoint_default,x,y,w,h,0,0)
            }
        }
    }

    function af_info_mf_Changed() {
        var s = deviceAdapter.af_status_ulAFStatus();
        var f = 0
        if(deviceAdapter.af_pdaf_info() === LT.Utilities.AfInfoPDAFInfo_ON){
            f = deviceAdapter.af_pdaf_display_DispInfo(0)
        }else{
            f = deviceAdapter.af_display_DispInfo(0);
        }
        var x = deviceAdapter.af_pinpoin_frame_pos_X()
        var y = deviceAdapter.af_pinpoin_frame_pos_Y()
        var w = deviceAdapter.af_pinpoin_frame_width()
        var h = deviceAdapter.af_pinpoin_frame_height()
        var d = deviceAdapter.af_faceinfo_face_detect_status(0);
        LTSubFunction.console_debug.out("af_info_mf_Changed s="+s+" f="+f+" x="+x+" y="+y+" w="+w+" h="+h)

        afframe.center_keep = false
        //AF情報ステータス 0x9401 0x01000011 AFステータス関連する情報
        //パラメータ１：ＡＦステータス
        //0 AF合焦OK
        //1 AF合焦OK：AF合焦枠表示なし
        //2 AF合焦NG
        //3 AFキャンセル
        //4 ローライトAF中
        //5 スターライトAF完了
        //0x0000FFFF 非合焦
        //合焦枠情報 0x9401 0x01000012 AF合焦枠に関する情報 パラメータ２：AF合焦枠情報
        //0 AF枠表示：なし
        //1 AF枠表示：緑枠
        //2 AF枠表示：赤枠
        //3 AF枠表示：緑枠（大）
        //4 AF枠表示：赤枠（大）
        //5 AF枠表示：スポット
        //6 AF枠表示：白枠（大）
        //7 AF枠表示：星空
        //簡易1点AF状態 0x9402 0x020001D1 1点・顔AF枠設定に関連する情報 パラメータ５：簡易１点AF状態
        //0 簡易1点AF OFF
        //1 簡易1点AF ON

        //・合焦枠情報の0番目の値が、「AF枠表示：緑枠（大）」、「AF枠表示：赤枠（大）」、「AF枠表示：白枠（大）」のいずれかの場合
        // 枠（大）表示
        if (f == LT.Utilities.AfInfoDispFrame_Green_Big) {
            afframe.changeValuePointOneCenter(afframe.afcv_1p_cen_big_green, x, y, w, h, false)
        }
        else if (f == LT.Utilities.AfInfoDispFrame_Red_Big) {
            afframe.changeValuePointOneCenter(afframe.afcv_1p_cen_big_red, x, y, w, h, false)
        }
        else if (f == LT.Utilities.AfInfoDispFrame_White) {
            afframe.changeValuePointOneCenter(afframe.afcv_1p_cen_white, x, y, w, h, false)
        }
        //・上記条件に当てはまらない場合
        // MF枠表示
        else {
            //・AF情報ステータスが、「非合焦」または、「ローライトAF中」の場合
            //白色で表示
            if ((s == LT.Utilities.AfInfoStatus_InProgress)
                || (s == LT.Utilities.AfInfoStatus_Unfocused)
                || (s == LT.Utilities.AfInfoStatus_LowRight)) {
                afframe.changeValuePointOneCenter(afframe.afcv_1p_cen_other, x, y, w, h, false)
            }
            //・AF情報ステータスが、「非合焦」、「ローライトAF中」以外の場合
            else {
                // ・合焦枠情報の０番目の値が「AF枠表示：緑枠」の場合、緑で表示。
                //  緑色で表示
                if (f == LT.Utilities.AfInfoDispFrame_Green) {
                    afframe.changeValuePointOneCenter(afframe.afcv_1p_cen_green, x, y, w, h, false)
                }
                // ・合焦枠情報の０番目の値が「AF枠表示：赤枠」の場合、赤で表示。
                //  赤色で表示
                else if (f == LT.Utilities.AfInfoDispFrame_Red) {
                    afframe.changeValuePointOneCenter(afframe.afcv_1p_cen_red, x, y, w, h, false)
                }
                // ・上記条件に当てはまらない場合
                //  白色で表示
                else {
                    afframe.changeValuePointOneCenter(afframe.afcv_1p_cen_default, x, y, w, h, false)
                }
            }
            // iAモードで顔検出の場合
            if(deviceAdapter.recordingMode === LT.Utilities.RM_IntelligentAuto &&
               d !== 0){
                // 顔枠表示
                var v = deviceAdapter.af_onepoin_frame_val();
                
                var start_index = 0
                var end_index = 15
                for(var i = start_index; i < end_index; i ++) {
                    var dx = deviceAdapter.af_faceinfo_face_detect_face_pos_pos_X(i);
                    var dy = deviceAdapter.af_faceinfo_face_detect_face_pos_pos_Y(i);
                    var dlx = deviceAdapter.af_faceinfo_face_detect_frame_length_X(i);
                    var dly = deviceAdapter.af_faceinfo_face_detect_frame_length_Y(i);
                    var ds = deviceAdapter.af_faceinfo_face_detect_status(i);
                    if(ds > 1){
                        // 重要顔(黄)は検出(白)にする
                        ds = 1;
                    }
                    afframe.changeValueFaceDetect(i,ds,s,f,v,dx,dy,dlx,dly)
                }
            }else{
                // 顔未検出
                for(var i = 0; i < 15; i ++) {
                    afframe.changeValueFaceDetect(i,0,0,0,0,0,0,0,0)
                }
            }
        }
    }

    function af_info_mfz_Changed() {
        var s = deviceAdapter.af_status_ulAFStatus();
        var f = 0
        if(deviceAdapter.af_pdaf_info() === LT.Utilities.AfInfoPDAFInfo_ON){
            f = deviceAdapter.af_pdaf_display_DispInfo(0)
        }else{
            f = deviceAdapter.af_display_DispInfo(0);
        }
        var x = deviceAdapter.af_pinpoin_frame_pos_X()
        var y = deviceAdapter.af_pinpoin_frame_pos_Y()
        var w = deviceAdapter.af_pinpoin_frame_width()
        var h = deviceAdapter.af_pinpoin_frame_height()
        var cx = deviceAdapter.af_pinpoin_frame_centerX();
        var cy = deviceAdapter.af_pinpoin_frame_centerY();
        var aw = deviceAdapter.af_pinpoin_frame_area_width();
        var ah = deviceAdapter.af_pinpoin_frame_area_height();

        var minx = deviceAdapter.af_pinpoin_frame_upper_leftX();
        var maxx = deviceAdapter.af_pinpoin_frame_lower_rightX();
        var miny = deviceAdapter.af_pinpoin_frame_upper_leftY();
        var maxy = deviceAdapter.af_pinpoin_frame_lower_rightY();

        LTSubFunction.console_debug.out("af_info_mfz_Changed s="+s+" f="+f+" x="+x+" y="+y+" w="+w+" h="+h)
        afframe.center_keep = false

        // 顔枠非表示
        for(var i = 0; i < 15; i ++) {
            afframe.changeValueFaceDetect(i,0,0,0,0,0,0,0,0)
        }

        if(deviceAdapter.mfa_mode == LT.Utilities.AsModCur_Zoom) {
            //afframe.mfAssistZoomSetting(x,y,w,h)
            afframe.mfAssistZoomSetting(cx, cy, aw, ah, minx, maxx, miny, maxy)
        }
        afframe.changeValueMfz(x,y,w,h)
    }

    function af_info_pscope_Changed() {
        var s = deviceAdapter.af_status_ulAFStatus();
        var f = 0
        if(deviceAdapter.af_pdaf_info() === LT.Utilities.AfInfoPDAFInfo_ON){
            f = deviceAdapter.af_pdaf_display_DispInfo(0)
        }else{
            f = deviceAdapter.af_display_DispInfo(0);
        }
        var x = deviceAdapter.af_pinpoin_frame_pos_X()
        var y = deviceAdapter.af_pinpoin_frame_pos_Y()
        var w = deviceAdapter.af_pinpoin_frame_width()
        var h = deviceAdapter.af_pinpoin_frame_height()
        LTSubFunction.console_debug.out("af_info_pscope_Changed s="+s+" f="+f+" x="+x+" y="+y+" w="+w+" h="+h)

        afframe.center_keep = false

        //・合焦枠情報の0番目の値が、「AF枠表示：緑枠（大）」、「AF枠表示：赤枠（大）」、「AF枠表示：白枠（大）」のいずれかの場合
        // 枠（大）表示
        if (f == LT.Utilities.AfInfoDispFrame_Green_Big) {
            afframe.changeValuePointScopeCenter(afframe.afcv_pscope_big_green, x, y, w, h)
        }
        else if (f == LT.Utilities.AfInfoDispFrame_Red_Big) {
            afframe.changeValuePointScopeCenter(afframe.afcv_pscope_big_red, x, y, w, h)
        }
        else if (f == LT.Utilities.AfInfoDispFrame_White) {
            afframe.changeValuePointScopeCenter(afframe.afcv_pscope_white, x, y, w, h)
        }
        //・上記条件に当てはまらない場合
        // MF枠表示
        else {
            //・AF情報ステータスが、「非合焦」または、「ローライトAF中」の場合
            //白色で表示
            if ((s == LT.Utilities.AfInfoStatus_InProgress)
                || (s == LT.Utilities.AfInfoStatus_Unfocused)
                || (s == LT.Utilities.AfInfoStatus_LowRight)) {
                afframe.changeValuePointScopeCenter(afframe.afcv_pscope_other, x, y, w, h)
            }
            //・AF情報ステータスが、「非合焦」、「ローライトAF中」以外の場合
            else {
                // ・合焦枠情報の０番目の値が「AF枠表示：緑枠」の場合、緑で表示。
                //  緑色で表示
                if (f == LT.Utilities.AfInfoDispFrame_Green) {
                    afframe.changeValuePointScopeCenter(afframe.afcv_pscope_green, x, y, w, h)
                }
                // ・合焦枠情報の０番目の値が「AF枠表示：赤枠」の場合、赤で表示。
                //  赤色で表示
                else if (f == LT.Utilities.AfInfoDispFrame_Red) {
                    afframe.changeValuePointScopeCenter(afframe.afcv_pscope_red, x, y, w, h)
                }
                // ・上記条件に当てはまらない場合
                //  白色で表示
                else {
                    afframe.changeValuePointScopeCenter(afframe.afcv_pscope_default, x, y, w, h)
                }
            }
        }
    }

    function af_frame_sframe_Changed() {
        LTSubFunction.console_debug.out("af_frame_sframe_Changed")

        if (!deviceAdapter.sFrame_info) {
            LTSubFunction.console_debug.out("af_frame_sframe_Changed no display")
            afframe.changeValueSmallFrame(afframe.afcv_small_frame_no_display, 0, 0, 0, 0, 0, 0, 0, 0)

            if (afframe.mode_pscope_bk != afframe.afmode_init) {
                afframe.changeMode(afframe.mode_pscope_bk)
                af_frame_info_Changed()

                afframe.mode_pscope_bk = afframe.afmode_init
            }
            return
        }

        var o_x = deviceAdapter.sFrame_outer_posX;
        var o_y = deviceAdapter.sFrame_outer_posY;
        var o_w = deviceAdapter.sFrame_outer_sizeW;
        var o_h = deviceAdapter.sFrame_outer_sizeH;

        var m_x = deviceAdapter.sFrame_mag_posX;
        var m_y = deviceAdapter.sFrame_mag_posY;
        var m_w = deviceAdapter.sFrame_mag_sizeW;
        var m_h = deviceAdapter.sFrame_mag_sizeH;

        if (deviceAdapter.mfa_mode == LT.Utilities.AsModCur_Zoom) {
            LTSubFunction.console_debug.out("af_frame_sframe_Changed mode: zoom")
            afframe.changeValueSmallFrame(afframe.afcv_small_frame_zoom, o_x, o_y, o_w, o_h, m_x, m_y, m_w, m_h)
        } else if (deviceAdapter.mfa_mode == LT.Utilities.AsModCur_Pinp) {
            LTSubFunction.console_debug.out("af_frame_sframe_Changed mode: pip")
            afframe.changeValueSmallFrame(afframe.afcv_small_frame_pinp, o_x, o_y, o_w, o_h, m_x, m_y, m_w, m_h)
        } else {
            LTSubFunction.console_debug.out("af_frame_sframe_Changed mode: default")
            afframe.changeValueSmallFrame(afframe.afcv_small_frame_default, o_x, o_y, o_w, o_h, m_x, m_y, m_w, m_h)
        }

        return
    }

    function af_pdaf_frame_numChanged(){
        // AF枠行列数設定
        //deviceAdapter.af_pdaf_info()が合掌時しかONにならない？（MC8259）のでafInfoFrameNumSetting()では正しく設定できない
        afInfoFrameNumSetting()
        afframe.pdaf_frames_update()
    }

// IVC >> Ver.1.8 >> start >> No.1
    function lv_shooting_status_Changed() {
        LTSubFunction.console_debug.out("lv_shooting_status_Changed")

        lvComposite.shootingStatusChanged()
    }
// IVC >> Ver.1.8 >> start >> USBTHRV180-19
    function lvc_show_liveview_control_item_changed() {
        afframe.visible = deviceAdapter.lvcShowLvControlItem && (!deviceAdapter.isMultiviewMode)
    }
// IVC << Ver.1.8 << end << USBTHRV180-19

// IVC << Ver.1.8 << end << No.1

    function popupClose() {
        LTSubFunction.console_debug.out("popupClose start")
        guidelineClose()
        gridPopupClose()
        // ivc >> start >> No.1
        overlayPhotoPopupClose()
        // ivc << end << No.1
    }

    function guidelineCancelClose() {
        LTSubFunction.console_debug.out("guidelineCancelClose start")
        if(guidelinePopup.visible == true) {
            guidelinePopup.cancel()
        }
        guidelineClose()
    }

    function guidelineClose() {
        LTSubFunction.console_debug.out("guidelineCloseClose start")
        if(guidelinePopup.visible == true) {
            LTSubFunction.console_debug.out("guidelineCloseClose dismiss")
            guidelinePopup.dismiss();
        }
    }

    function gridPopupCancelClose() {
        LTSubFunction.console_debug.out("gridPopupCancelClose start")
        if(gridPopup.visible == true) {
            gridPopup.cancel()
        }
        gridPopupClose()
    }

    function gridPopupClose() {
        LTSubFunction.console_debug.out("gridPopupCloseClose start")
        if(gridPopup.visible == true) {
            LTSubFunction.console_debug.out("gridPopupCloseClose dismiss")
            gridPopup.dismiss();
        }
    }

    // ivc >> start >> No.1
    function overlayPhotoPopupClose() {
        LTSubFunction.console_debug.out("overlayPhotoPopupClose start")
        if(overlayPhotoPopup.visible == true) {
            LTSubFunction.console_debug.out("overlayPhotoPopupClose dismiss")
            overlayPhotoPopup.dismiss();
        }
    }
    // ivc << end << No.1

    function updateLiveViewMenu(){
        control.initSetupTetherMode()
        if (deviceAdapter.camSupportPowerSaving && deviceAdapter.pwTetherConnectMode == LT.Utilities.PwTether_OFF ) {
            liveViewMenu.enabled = false
        }
        else {
            liveViewMenu.enabled = true
        }
    }

    // IVC >> Ver.1.9 >> start >> [THRBOXV100-81]
    function initSetupTetherMode() {
        updateLiveViewMenu()
        cameraStatusCompleteNotify();
        
        //テザーモードが変更された場合に呼ばれる
        //マルチ中は何もしない
        if( deviceAdapter.isMultiviewMode === true ){
            return
        }

        if(root.visible){
            if (!deviceAdapter.camSupportPowerSaving || deviceAdapter.pwTetherConnectMode == LT.Utilities.PwTether_ON) {
                if(videoImageInfo.videoImageStatus !== LT.VideoImageInfo.VIS_Start) {
                    //開始されてないなら開始
                    deviceAdapter.adp_LMX_func_api_Ctrl_LiveView_Stop()
                    deviceAdapter.adp_LMX_func_api_Ctrl_LiveView_Start()
                    deviceAdapter.adp_LMX_func_api_LiveView_Str_Get_Recom_Img_Start()
                    deviceAdapter.adp_LMX_func_api_LiveView_Str_Get_Trans_Img_Start()
                }
            }else{
                if(videoImageInfo.videoImageStatus !== LT.VideoImageInfo.VIS_Pause) {
                    //黒画面のPause状態にする
                    deviceAdapter.adp_LMX_func_api_Ctrl_LiveView_Stop()
                    deviceAdapter.setLiveviewPause()
                }
            }
        }
    }
    // IVC << Ver.1.9 << end << [THRBOXV100-81]

    function switchCameraNotify(){
        updateLiveViewMenu()
        cameraStatusCompleteNotify();
    }

    function isMultiviewModeChanged()
    {
        if(deviceAdapter.isMultiviewMode === true){
            //for Streaming対応
            afframe.visible = (afframeVisible = false) && availableAFFrame && (!deviceAdapter.isMultiviewMode)
            if( deviceAdapter.isSupportMultiView() === true ){
                //AF OFFボタンの表示をOFFにする
                afoff.visible = false
                //バルブ撮影のタイマーカウント表示をOFFにする
                disptimeBulbGroup.visible = false
            }
        } else {
            //for Streaming対応
            afframe.visible = deviceAdapter.lvcShowLvControlItem && (afframeVisible = true) && availableAFFrame && (!deviceAdapter.isMultiviewMode)
            updateMaskPanel()
            if( deviceAdapter.isSupportMultiView() === true ){
                //AF OFFボタンの表示更新用
                afoff.visible = affOffVisible
                //バルブ撮影のタイマーカウント表示更新用
                disptimeBulbGroup.visible = bulbTimerVisible
            }
        }
    }

    function exTeleconChanged() {
        if(deviceAdapter.afPDAFEnable){
            // PDAF設定
            afframe.pdafTableTypeSetting()
            af_frame_info_Changed()
        }
    }

    function pictureSizeChanged() {
        if(deviceAdapter.afPDAFEnable){
            // PDAF設定
            afframe.pdafTableTypeSetting()
            af_frame_info_Changed()
        }
    }

    // 315点、PDAF枠行列数設定
    function afInfoFrameNumSetting(){
        // 315点行列数設定
        var numX = deviceAdapter.af_af_frame_num_X()
        var numY = deviceAdapter.af_af_frame_num_Y()
        afframe.frame315FrameNumSetting(numX, numY)
        // PDAF枠行列数設定
        if(deviceAdapter.af_pdaf_info() === LT.Utilities.AfInfoPDAFInfo_ON){
            numX = deviceAdapter.af_pdaf_frame_num_X()
            numY = deviceAdapter.af_pdaf_frame_num_Y()
            afframe.pdafFrameNumSetting(numX, numY)
        }
    }

    function updateLVMultiItemVisible(isMultiMode){
        //操作パネル非表示の場合はマルチ中でも選択枠出さないようにする
        if( isMultiMode === true && showControlPanel === true && deviceAdapter.getLiveviewDevNum() > 1){
            imageLVSelectBorder.visible = true;
        }else{
            imageLVSelectBorder.visible = false;
        }
    }

    flags:
//        Qt.Window
        Qt.Dialog
      | Qt.CustomizeWindowHint
      | Qt.WindowTitleHint
//      | Qt.WindowSystemMenuHint
      | Qt.WindowMinimizeButtonHint
      | Qt.WindowMaximizeButtonHint
      | Qt.WindowCloseButtonHint

    //  ウィンドウの最小サイズと最大サイズを同じ値にして，リサイズできないようにする
    minimumWidth: control.width + 320
    minimumHeight: 669
    //maximumWidth: minimumWidth
    //maximumHeight: minimumHeight

    //  ウィンドウのサイズを最小/最大サイズにする
    width: 1103
    height: 669

    title: "LIVE VIEW"

    color: palette.backgroundLight//"transparent"

    onClosing:{
        //Qtのバグ？最大化->非表示->表示（最大状態）->通常と遷移させるとウインドウサイズが最大化のものになってしまう
        //最大化から解除された時に前の状態の位置やサイズに明示的に戻すようにする
        //MacではLTWindowStateSaver.qmlの対応では回避できない
        //×ボタンだとWindowがCloseされるので、本来再度Createする必要あり？
        //最大化時はいったんCloseせずに操作パネルのボタン操作で行われる場合のHide状態とする
        if(root.visibility == Window.Maximized){
            close.accepted = false;
            root.hide();
        }else{
            close.accepted = true;
        }
    }

    onVisibleChanged: {
        //console.log("LiveView::onVisibleChanged visible" + deviceAdapter.elapsedInMovieRec);
        isErrorStop = false
        cameraStatusSetting()
        levelIndicator.redraw()
        // IVC >> Ver.1.8 >> start >> No.1
        lvComposite.init()
        // IVC << Ver.1.8 << end << No.1
        levelIndicator.rollingDegrees = levelIndicator.rollingDegrees
        levelIndicator.pitchingDegrees = levelIndicator.pitchingDegrees;

        //マルチ中はliveViewUpdate（cameraStatusSetting経由）でStop Start抑制してるので、ここで停止、開始判定する
        if( deviceAdapter.isMultiviewMode === true){
            if(root.visible == false) {
                if(videoImageInfo.videoImageStatus !== LT.VideoImageInfo.VIS_Pause) {
                    deviceAdapter.adp_LMX_func_api_Ctrl_LiveView_Stop();
                }
            }else{
                if(videoImageInfo.videoImageStatus !== LT.VideoImageInfo.VIS_Start){
                    deviceAdapter.adp_LMX_func_api_Ctrl_LiveView_Start()
                    deviceAdapter.adp_LMX_func_api_LiveView_Str_Get_Recom_Img_Start()
                    deviceAdapter.adp_LMX_func_api_LiveView_Str_Get_Trans_Img_Start()
                }
            }
        }

        if(root.visible == false) {
            lv_wbset_mode = false;
            control.wbSettingsChecked = false
            utilities.setMouseCursor(0);
            guidelinePopup.dismiss()
            gridPopup.dismiss()
            // ivc >> start >> No.1
            overlayPhotoPopup.dismiss()
            // ivc << end << No.1
            // IVC >> Ver.1.9 >> start >> No.2
            if (deviceAdapter.cameraStatus == LT.Utilities.CamStatus_Menu_Displayed) {
                var ret = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_Menu_End_Menu()
                if (ret == LT.DeviceAdapter.Ternary_True) {
                    control.controlItemSetting(false)
                }
            }
            // IVC << Ver.1.9 << end << No.2

            // カメラ切断して接続待機画面からアプリ終了するとAP断発生する対策
            deviceAdapter.videoSource.videoSink = null
        } else {
            // カメラ切断して接続待機画面からアプリ終了するとAP断発生する対策
            deviceAdapter.videoSource.videoSink = imageLV.videoSink
            //guidelinePopup.createColorDialog()
            //gridPopup.createColorDialog()
            iconArea.show()
        }

        deviceAdapter.videoSource.setVideoOutVisibleStatus(visible)
    }
    onActiveChanged: {
        //LTSubFunction.console_debug.out("LiveView::onActiveChanged")
        if(maskpanel.visible) {
            if(root.active) {
                utilities.preferenceWindowActive()
            }
        }
    }

    onWidthChanged:{
        if( maskpanel.visible === true ){
            //マスクパネルの表示位置を更新しておく
            maskpanel.maskSizeUpdate();
        }
    }
    onHeightChanged:{
        if( maskpanel.visible === true ){
            //マスクパネルの表示位置を更新しておく
            maskpanel.maskSizeUpdate();
        }
    }

    Component.onCompleted: {
        LTSubFunction.console_debug.out("liveview::Component.onCompleted")

        //autoFocusModeSetting();

        control.af_dispframeClicked.connect(function() {
            autoFocusModeSetting()
        });
//        control.mf_zoomClicked.connect(function() {
//            autoFocusModeSetting()
//        });
        control.afFramePointScopeEnd.connect(function() {
            autoFocusModeSetting()
        });

        deviceAdapter.isCamerasConnectedChanged.connect(root.usbEventCameraChanged);

        //Adapter connect
        deviceAdapter.autoFocusModeChanged.connect(root.autoFocusModeSetting);
        deviceAdapter.autoFocusModeInnerChanged.connect(root.autoFocusModeSetting);
        deviceAdapter.focusModeChanged.connect(root.autoFocusModeSetting);
        // IVC >> Ver.1.9 >> start >> [THRBOXV100-41]
        deviceAdapter.focusModeInnerChanged.connect(root.autoFocusModeSetting);
        // IVC << Ver.1.9 << end << [THRBOXV100-41]
        deviceAdapter.meteringModeChanged.connect(root.meteringModeSetting);
        deviceAdapter.meteringModeInnerChanged.connect(root.meteringModeSetting);
        videoImageInfo.postureChanged.connect(root.postureSetting);
        videoImageInfo.rollChanged.connect(root.rollSetting);
        videoImageInfo.pitchChanged.connect(root.pitchSetting);

        deviceAdapter.af_frame_info_Changed.connect(root.af_frame_info_Changed);
        deviceAdapter.liveview_size_Changed.connect(root.liveview_size_Changed);
        deviceAdapter.sFrame_infoChanged.connect(root.af_frame_sframe_Changed)
        deviceAdapter.af_pdaf_frame_numChanged.connect(root.af_pdaf_frame_numChanged)
        deviceAdapter.afFrameColorChanged.connect(root.af_frame_info_Changed);

        deviceAdapter.elapsedInMovieRecChanged.connect(elapsedInMovieRecSetting)
        deviceAdapter.cameraStatusChanged.connect(cameraStatusSetting)
        deviceAdapter.cameraStatusCompleteNotify.connect(cameraStatusCompleteNotify)
        utilities.preferenceWindowVisibleChangedNotify.connect(root.preferenceWindowVisibleSetting);
        utilities.searchCamWindowVisibleChangedNotify.connect(root.searchCamWindowVisibleSetting);

        //deviceAdapter.mfAssistModeChanged.connect(root.mfAssistModeSetting)
        //deviceAdapter.pinpointModeChanged.connect(root.pinpointModeSetting)

        deviceAdapter.whiteBalanceChanged.connect(root.whiteBalanceSetting);
        deviceAdapter.whiteBalanceInnerChanged.connect(root.whiteBalanceSetting);

        deviceAdapter.recPreviewModeChanged.connect(root.recPreviewSetting);

        //deviceAdapter.mfAssistModeFlgNumChanged.connect(mfAssistModeSetting);
        deviceAdapter.recPreviewModeFlgNumChanged.connect(root.recPreviewSetting);

        deviceAdapter.af_magnifyChanged.connect(root.af_magnifySetting);
        deviceAdapter.mf_magnifyChanged.connect(root.mf_magnifySetting);
        deviceAdapter.lvMag_magnifyChanged.connect(root.mf_magnifySetting);
        deviceAdapter.mfa_modeChanged.connect(root.mfa_modeSetting);

        deviceAdapter.afStateChanged.connect(root.afStateSetting);
        deviceAdapter.afaeStateChanged.connect(root.afStateSetting);
        // ivc >> start >> No.3
        deviceAdapter.afcStartPosStateChanged.connect(root.autoFocusModeSetting);
        // ivc << end << No.3

        deviceAdapter.driveModeChanged.connect(root.driveModeSetting);
        deviceAdapter.recordingModeChanged.connect(root.recordingModeSetting);

        deviceAdapter.mfAssistStartErrorNotify.connect(root.mfAssistStartError)
        deviceAdapter.pinpAspectRatioChanged.connect(root.pinpAspectRatioSetting)

        deviceAdapter.aspectRatioChanged.connect(root.aspectRatioSetting);
        deviceAdapter.aspectRatioInnerChanged.connect(root.aspectRatioSetting);  // 操作パネルからアスペクト比変更時

        utilities.activateWindowNotify.connect(root.activateWindowNotify);

        // IVC >> Ver.1.8 >> start >> No.1
        deviceAdapter.nrRemainingTimeChanged.connect(root.lv_shooting_status_Changed);
        deviceAdapter.lvShootingStatusChanged.connect(root.lv_shooting_status_Changed)
        // IVC >> Ver.1.8 >> start >> USBTHRV180-19
        deviceAdapter.lvcShowLvControlItemChanged.connect(root.lvc_show_liveview_control_item_changed)
        // IVC << Ver.1.8 << end << USBTHRV180-19
        // IVC << Ver.1.8 << end << No.1

        // IVC >> Ver.1.9 >> start >> [THRBOXV100-81]
        deviceAdapter.initSetupTetherModeChanged.connect(root.initSetupTetherMode);
        // IVC << Ver.1.9. << end >> [THRBOXV100-81]
        deviceAdapter.switchCameraNotify.connect(root.switchCameraNotify)

        //guidelinePopup.onCancelClicked.connect(root.guidelinePopupCancel);
        //gridPopup.onCancelClicked.connect(root.gridPopupCancel);
        deviceAdapter.pwTetherConnectModeChanged.connect(root.initSetupTetherMode);

        deviceAdapter.isMultiviewModeChanged.connect(root.isMultiviewModeChanged);

        deviceAdapter.exTeleconChanged.connect(root.exTeleconChanged);
        deviceAdapter.pictureSizeChanged.connect(root.pictureSizeChanged);
        deviceAdapter.pictureSizeInnerChanged.connect(root.pictureSizeChanged);

    }

    LTLogCollector {
        id: ltLog

        logMajTagID: LT.TagDef.RTMajor_Usage
        logMedTagID: LT.TagDef.RTMed_Usage_LiveView
        logWindowName: "LTLiveViewWindow"
    }

    LTWindowStateSaver {
        id:windowState
        window: root
        defaultWidth: 1103//minimumWidth
        defaultHeight: 669//minimumHeight
        targetWindow: LT.ApplicationSettings.WinList_Live
    }

    Row {
        anchors {
            fill: parent
        }

        Item {
            anchors {
                top: parent.top
                bottom: parent.bottom
            }
            //for Streaming対応
            width: showControlPanel
                   ? parent.width - control.width
                   : parent.width   // 2020/05/16 Panasonic Nakano

            /*
                背景
             */
            Rectangle {
                id: imageView
                anchors {
                    fill: parent
                }
                //color: palette.backgroundDark
                color: "grey"
                /*
                    画像
                 */
                VideoOutput{
                    id: imageLV
                    anchors {
                        centerIn: parent
                    }

                    Component.onCompleted: {
                        deviceAdapter.videoSource.paintSizeChanged.connect(imageLV.paintSizeChanged);
                        videoImageInfo.selctedPaintSizeChanged.connect(imageLV.selctedPaintSizeChanged);
                        deviceAdapter.videoSource.videoSink = imageLV.videoSink
                    }
                    Component.onDestruction: {
                        // デストラクタ時に開放されたメモリを参照している？
                        // バインディングを消しておく。
                        deviceAdapter.videoSource.videoSink = null
                    }

                    property double paintScaleW: 1.0
                    property double paintScaleH: 1.0
                    property double paintScaleX: 0
                    property double paintScaleY: 0

                    property double paintSelectedScaleW: 1.0
                    property double paintSelectedScaleH: 1.0
                    property double paintSelectedScaleX: 0
                    property double paintSelectedScaleY: 0


                    //VideoOutputのサイズが変わった
                    onContentRectChanged: {
                        //実際の描画領域を更新
                        paintSizeUpdate()
                    }
                    //実際の描画領域が変わった
                    function paintSizeChanged(offsetX,offsetY,w,h){
                        paintScaleX = offsetX;
                        paintScaleY = offsetY;
                        paintScaleW = w;
                        paintScaleH = h;

                        paintSizeUpdate()
                    }
                    //実際の描画領域を更新
                    function paintSizeUpdate()
                    {
                        //比率ベースで描画領域を計算
                        if( contentRect.width > 0){
                            if(contentRect.width * paintScaleW !== paintedWidth){
                                paintedWidth = contentRect.width * paintScaleW
                            }
                        }else{
                            paintedWidth = 1
                        }
                        if( contentRect.height > 0){
                            if(contentRect.height * paintScaleH !== paintedHeight){
                                paintedHeight = contentRect.height * paintScaleH
                            }
                        }else{
                            paintedHeight = 1
                        }
                        selctedPaintSizeUpdate()
                    }

                    function selctedPaintSizeChanged(isMultiMode, offsetX,offsetY,w,h){
                        paintSelectedScaleX = offsetX;
                        paintSelectedScaleY = offsetY;
                        paintSelectedScaleW = w;
                        paintSelectedScaleH = h;

                        updateLVMultiItemVisible(isMultiMode)
                        selctedPaintSizeUpdate()
                    }

                    function selctedPaintSizeUpdate()
                    {
                        //比率ベースで描画領域を計算
                        if( contentRect.width > 0 && contentRect.height > 0){
                            var selectX = paintedWidth * paintSelectedScaleX
                            var selectY = paintedHeight * paintSelectedScaleY
                            var selectW = paintedWidth * paintSelectedScaleW
                            var selectH = paintedHeight * paintSelectedScaleH
                            //計算誤差が出ると思われるので、1ピクセル大きい位置で表示するようにする
                            if( imageLVSelectBorder.x !== selectX){
                                imageLVSelectBorder.x = selectX + contentRect.x - 1
                            }
                            if( imageLVSelectBorder.y !== selectY){
                                imageLVSelectBorder.y = selectY + contentRect.y -1
                            }
                            if( imageLVSelectBorder.width !== selectW){
                                imageLVSelectBorder.width = selectW + 2
                            }
                            if( imageLVSelectBorder.height !== selectH){
                                imageLVSelectBorder.height = selectH + 2
                            }
                        }
                    }

                    width: {
                        if(lv_rotation_mode) {
                            //LTSubFunction.console_debug.out("image width lv_rotation_auto =" + lv_rotation_auto)
                            if(lv_rotation_auto % 180 != 0) {
                                return imageView.height;
                            }
                        } else {
                            //LTSubFunction.console_debug.out("image width lv_rotation =" + lv_rotation)
                            if(lv_rotation % 180 != 0) {
                                return imageView.height;
                            }
                        }
                        return imageView.width;
                    }
                    height: {
                        if(lv_rotation_mode) {
                            //LTSubFunction.console_debug.out("image height lv_rotation_auto =" + lv_rotation_auto)
                            if(lv_rotation_auto % 180 != 0) {
                                return imageView.width;
                            }
                        } else {
                            //LTSubFunction.console_debug.out("image height lv_rotation =" + lv_rotation)
                            if(lv_rotation % 180 != 0) {
                                return imageView.width;
                            }
                        }
                        return imageView.height;
                    }
                    rotation: (lv_rotation_mode)? lv_rotation_auto: lv_rotation
                    //fillMode: Image.PreserveAspectFit

                    property int paintedHeightOld: -1
                    property int paintedWidthOld: -1
                    property int aspectRatioOld: -1

                    property size sourceSize: Qt.size(1280, 720)
                    //property real paintedHeight: imageLV.height
                    //property real paintedWidth: imageLV.width
                    property real paintedHeight: 100
                    property real paintedWidth: 100

                    onPaintedHeightChanged: {
                        control.updatePhotoFrameXY()

                        //LTSubFunction.console_debug.out("liveview::onPaintedHeightChanged paintedHeight old=" + paintedHeightOld + " new=" + parseInt(paintedHeight))
                        if(deviceAdapter.mfa_mode == LT.Utilities.AsModCur_Zoom) {
                            if(paintedHeightOld != parseInt(paintedHeight)) {
                                aspectRatioSetting()
                            } else if(aspectRatioOld != deviceAdapter.aspectRatio ) {
                                aspectRatioSetting()
                            }
                        }
                        aspectRatioOld = deviceAdapter.aspectRatio;
                        paintedHeightOld = parseInt(paintedHeight)
                    }

                    onPaintedWidthChanged: {
                        control.updatePhotoFrameXY()

                        //LTSubFunction.console_debug.out("liveview::onPaintedWidthChanged paintedWidth old=" + paintedWidthOld + " new=" + parseInt(paintedWidth))
                        if(deviceAdapter.mfa_mode == LT.Utilities.AsModCur_Zoom) {
                            if(paintedWidthOld != parseInt(paintedWidth)) {
                                aspectRatioSetting()
                            } else if(aspectRatioOld != deviceAdapter.aspectRatio ) {
                                aspectRatioSetting()
                            }
                        }
                        aspectRatioOld = deviceAdapter.aspectRatio;
                        paintedWidthOld = parseInt(paintedWidth)
                    }
                }
                /*
                Image {
                    id: imageLV
                    anchors {
                        centerIn: parent
                    }
//                    width: 669
//                    height: 376
                    width: {
                        if(lv_rotation_mode) {
                            //LTSubFunction.console_debug.out("image width lv_rotation_auto =" + lv_rotation_auto)
                            if(lv_rotation_auto % 180 != 0) {
                                return imageView.height;
                            }
                        } else {
                            //LTSubFunction.console_debug.out("image width lv_rotation =" + lv_rotation)
                            if(lv_rotation % 180 != 0) {
                                return imageView.height;
                            }
                        }
                        return imageView.width;
                    }
                    height: {
                        if(lv_rotation_mode) {
                            //LTSubFunction.console_debug.out("image height lv_rotation_auto =" + lv_rotation_auto)
                            if(lv_rotation_auto % 180 != 0) {
                                return imageView.width;
                            }
                        } else {
                            //LTSubFunction.console_debug.out("image height lv_rotation =" + lv_rotation)
                            if(lv_rotation % 180 != 0) {
                                return imageView.width;
                            }
                        }
                        return imageView.height;
                    }
                    rotation: (lv_rotation_mode)? lv_rotation_auto: lv_rotation
                    fillMode: Image.PreserveAspectFit
                    source: "image://liveViewCapture/black"

                    property int paintedHeightOld: -1
                    property int paintedWidthOld: -1
                    property int aspectRatioOld: -1

                    // ivc >> start >> No.1
                    onPaintedHeightChanged: {
                        control.updatePhotoFrameXY()

                        //LTSubFunction.console_debug.out("liveview::onPaintedHeightChanged paintedHeight old=" + paintedHeightOld + " new=" + parseInt(paintedHeight))
                        if(deviceAdapter.mfa_mode == LT.Utilities.AsModCur_Zoom) {
                            if(paintedHeightOld != parseInt(paintedHeight)) {
                                aspectRatioSetting()
                            } else if(aspectRatioOld != deviceAdapter.aspectRatio ) {
                                aspectRatioSetting()
                            }
                        }
                        aspectRatioOld = deviceAdapter.aspectRatio;
                        paintedHeightOld = parseInt(paintedHeight)
                    }

                    onPaintedWidthChanged: {
                        control.updatePhotoFrameXY()

                        //LTSubFunction.console_debug.out("liveview::onPaintedWidthChanged paintedWidth old=" + paintedWidthOld + " new=" + parseInt(paintedWidth))
                        if(deviceAdapter.mfa_mode == LT.Utilities.AsModCur_Zoom) {
                            if(paintedWidthOld != parseInt(paintedWidth)) {
                                aspectRatioSetting()
                            } else if(aspectRatioOld != deviceAdapter.aspectRatio ) {
                                aspectRatioSetting()
                            }
                        }
                        aspectRatioOld = deviceAdapter.aspectRatio;
                        paintedWidthOld = parseInt(paintedWidth)
                    }
                    // ivc << end << No.1
                }
                Timer {
                    id: imageTimer
                    property int cnt: 0
                    interval: 10
                    running: false
                    repeat: true
                    onTriggered:  {
                        //LTSubFunction.console_debug.out("onTriggered")
                        if(videoImageInfo.videoImageStatus == LT.VideoImageInfo.VIS_Start) {
                            //LTSubFunction.console_debug.out("VIS_Start")
                            if(videoImageInfo.videoImageError == LT.VideoImageInfo.VIE_NoError) {
//                                LTSubFunction.console_debug.out("VIE_NoError:" + cnt)
                                imageTimer.interval = 10
// IVC >> Ver.1.9 >> start >> [THRBOXV100-126]
                                if (deviceAdapter.camSupportPowerSaving && deviceAdapter.pwTetherConnectMode == LT.Utilities.PwTether_OFF) {
                                    imageLV.source = "image://liveViewCapture/black"
                                } else {
                                    imageLV.source = "image://liveViewCapture/" + cnt;
                                    ++cnt;
                                }
// IVC << Ver.1.9 << end << [THRBOXV100-126]
                            } else if(videoImageInfo.videoImageError == LT.VideoImageInfo.VIE_Busy) {
//                                LTSubFunction.console_debug.out("VIE_Busy")
                                videoImageInfo.videoImageError = LT.VideoImageInfo.VIE_NoError
                                imageTimer.interval = 15
                            } else {
                                imageTimer.running = false
                                //videoImageInfo.videoImageStatus = LT.VideoImageInfo.VIS_Stop
//                                LTSubFunction.console_debug.out("LiveView::imageTimer call liveViewUpdate")

                                liveViewUpdate(false);
                                videoImageInfo.videoImageError = LT.VideoImageInfo.VIE_NoError
                                imageLV.source = "image://liveViewCapture/black"
                            }
                        }
                    }
                    function start_timer() {
                        imageTimer.running = true
                    }
                }
                */
                //for Streaming対応
                // 2020/05/16 Panasonic Nakano
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    propagateComposedEvents: true
                    onMouseXChanged: {
                        LTSubFunction.console_debug.out("***** Mouse X changed on Liveview")
                        iconArea.show()
                    }
                    onMouseYChanged: {
                        LTSubFunction.console_debug.out("***** Mouse Y changed on Liveview")
                        iconArea.show()
                    }
                }
                //マルチ表示用選択カメラ枠
                Rectangle{
                    id: imageLVSelectBorder
                    color: "transparent"
                    border.color: "#ffbf1f"
                    border.width: 5
                    width: 100
                    height: 100
                    visible: false
                }

                /*
                    グリッド
                */
                LTGridIndicator {
                    id: gridIndicator
                    x: {
                        if(lv_rotation_mode) {
                            if(lv_rotation_auto % 180 != 0) {
                                return imageLV.x + imageLV.width / 2 - imageLV.paintedHeight / 2
                            }
                        } else {
                            if(lv_rotation % 180 != 0) {
                                return imageLV.x + imageLV.width / 2 - imageLV.paintedHeight / 2
                            }
                        }
                        return imageLV.x + imageLV.width / 2 - imageLV.paintedWidth / 2
                    }
                    y: {
                        if(lv_rotation_mode) {
                            if(lv_rotation_auto % 180 != 0) {
                                return imageLV.y + imageLV.height / 2 - imageLV.paintedWidth / 2
                            }
                        } else {
                            if(lv_rotation % 180 != 0) {
                                return imageLV.y + imageLV.height / 2 - imageLV.paintedWidth / 2
                            }
                        }

                        return imageLV.y + imageLV.height / 2 - imageLV.paintedHeight / 2
                    }
                    width: {
                        if(lv_rotation_mode) {
                            if(lv_rotation_auto % 180 != 0) {
                                return imageLV.paintedHeight;
                            }
                        } else {
                            if(lv_rotation % 180 != 0) {
                                return imageLV.paintedHeight;
                            }
                        }
                        return imageLV.paintedWidth;
                    }
                    height: {
                        if(lv_rotation_mode) {
                            if(lv_rotation_auto % 180 != 0) {
                                return imageLV.paintedWidth;
                            }
                        } else {
                            if(lv_rotation % 180 != 0) {
                                return imageLV.paintedWidth;
                            }
                        }

                        return imageLV.paintedHeight;
                    }
                    // IVC >> Ver.1.8 >> start >> USBTHRV180-19
                    //visible: control.gridChecked
                    visible: control.gridChecked & deviceAdapter.lvcShowLvControlItem
                    // IVC << Ver.1.8 << end << USBTHRV180-19
                    //rotation: lv_rotation
                }
                /*
                    水準器
                */
                LTLevelIndicator {
                    id: levelIndicator
                    x: {
                        if(lv_rotation_mode) {
                            if(lv_rotation_auto % 180 != 0) {
                                return imageLV.x + imageLV.width / 2 - imageLV.paintedHeight / 2
                            }
                        }
                        return imageLV.x + imageLV.width / 2 - imageLV.paintedWidth / 2
                    }
                    y: {
                        if(lv_rotation_mode) {
                            if(lv_rotation_auto % 180 != 0) {
                                return imageLV.y + imageLV.height / 2 - imageLV.paintedWidth / 2
                            }
                        }
                        return imageLV.y + imageLV.height / 2 - imageLV.paintedHeight / 2
                    }
                    width: {
                        if(lv_rotation_mode) {
                            if(lv_rotation_auto % 180 != 0) {
                                return imageLV.paintedHeight;
                            }
                        }
                        return imageLV.paintedWidth;
                    }
                    height: {
                        if(lv_rotation_mode) {
                            if(lv_rotation_auto % 180 != 0) {
                                return imageLV.paintedWidth;
                            }
                        }
                        return imageLV.paintedHeight;
                    }
                    // IVC >> Ver.1.8 >> start >> USBTHRV180-19
                    //visible: control.levelIndicatorChecked
                    visible: control.levelIndicatorChecked & deviceAdapter.lvcShowLvControlItem
                    // IVC << Ver.1.8 << end << USBTHRV180-19
                    rotation: (lv_rotation_mode)? 0: lv_rotation
                }

// IVC >> Ver.1.8 >> start >> No.1
                /*
                    ライブビューコンポジット
                */
                LTLiveViewComposite {
                    id: lvComposite
                    x: 0
                    y: 0
                    width: imageView.width
                    height: imageView.height
                    visible: true
                }
// IVC << Ver.1.8 << end << No.1
                /*
                    AF枠
                */
                LTAFFrame {
                    id: afframe
                    //for Streaming対応
                    visible: afframeVisible && availableAFFrame // 2020/05/16 Panasonic Nakano
                    x: imageLV.x + imageLV.width / 2 - imageLV.paintedWidth / 2
                    y: imageLV.y + imageLV.height / 2 - imageLV.paintedHeight / 2
                    width: imageLV.paintedWidth
                    height: imageLV.paintedHeight

                    rotation: (lv_rotation_mode)? lv_rotation_auto: lv_rotation
                    onDispAfOff: {
                        switch(afframe.mode) {
                        case afframe.afmode_point225_af:
                        case afframe.afmode_point225s_af:
                        case afframe.afmode_point225f_af:
                        case afframe.afmode_point225sf_af:
                        case afframe.afmode_face_af://       5
                        case afframe.afmode_face_225_af:
                        case afframe.afmode_face_225f_af:
                        case afframe.afmode_chase_af://      7
                            //afoff.visible = true
                            break;
                        case afframe.afmode_pointone://      0
                        // ivc >> start >> No.3 -> nakhuong
                        case afframe.afmode_pointone_aux://  28
                        // ivc << end << No.3 -> nakhuong
                        case afframe.afmode_point225:
                        case afframe.afmode_point225s:
                        case afframe.afmode_point225f:
                        case afframe.afmode_point225sf:
                        case afframe.afmode_face://          3
                        case afframe.afmode_face_eye://      4
                        case afframe.afmode_face_225:
                        case afframe.afmode_face_225f:
                        case afframe.afmode_chase://         6
                        case afframe.afmode_pinpoint://      8
                        case afframe.afmode_pinpointf://     9
                        case afframe.afmode_pinpointp://     9
                        case afframe.afmode_pinpointz://     9
                        case afframe.afmode_custom:
                        case afframe.afmode_customs:
                        case afframe.afmode_custom_af:
                        case afframe.afmode_customs_af:
                        case afframe.afmode_customf:
                        case afframe.afmode_customsf:
                        case afframe.afmode_customf_af:
                        case afframe.afmode_customsf_af:
                        case afframe.afmode_mf://            12
                        case afframe.afmode_mff://           13
                        case afframe.afmode_mfz://           13
                        case afframe.afmode_mfp://           13
                        default:
                            //afoff.visible = false
                            break;
                        }
                    }
                    onPinpoint_af_zoom_started: {
                        //console.log("onPinpoint_af_zoom_started");
                        control.setMFZoom(true)
                    }
                    onMf_zoom_started: {
                        //console.log("onMf_zoom_started");
                        control.setMFZoom(true)
                    }
                    onVisibleChanged: {
                        //console.log("afframe onVisibleChanged");
                    }
// IVC >> Ver.1.9 >> start >> [THRBOXV100-184]
                    onWidthChanged: {
                        af_frame_info_Changed()
                    }
                    onHeightChanged: {
                        af_frame_info_Changed()
                    }
// IVC << Ver.1.9 << end << [THRBOXV100-184]
                }

                // IVC >> Ver.1.9 >> start >> No.2
                Rectangle {
                    id: lvMenuDsp
                    x: imageLV.x + imageLV.width / 2 - imageLV.paintedWidth / 2
                    y: imageLV.y + imageLV.height / 2 - imageLV.paintedHeight / 2
                    width: imageLV.paintedWidth
                    height: imageLV.paintedHeight
                    color: "transparent"
                    visible: (deviceAdapter.cameraStatus == LT.Utilities.CamStatus_Menu_Displayed)
                    rotation: (lv_rotation_mode)? lv_rotation_auto: lv_rotation
                    MouseArea {
                       anchors.fill: parent
                       onClicked:(mouse)=> {
                            if (deviceAdapter.cameraStatus == LT.Utilities.CamStatus_Menu_Displayed) {
                                var x_conv = parseInt( (mouse.x * 1000) / lvMenuDsp.width )
                                var y_conv = parseInt( (mouse.y * 1000) / lvMenuDsp.height )

                                deviceAdapter.adp_LMX_func_api_Rec_Ctrl_Menu_Touch_Down_Menu(x_conv, y_conv);
                                deviceAdapter.adp_LMX_func_api_Rec_Ctrl_Menu_Touch_Up_Menu(x_conv, y_conv);
                            }
                       }
                    }
                }
                // IVC << Ver.1.9 << end << No.2

                /*
                    ガイドライン
                */
                LTGuideLineIndicator {
                    id: guidelineIndicator
                    x: {
                        if(lv_rotation_mode) {
                            if(lv_rotation_auto % 180 != 0) {
                                return imageLV.x + imageLV.width / 2 - imageLV.paintedHeight / 2
                            }
                        } else {
                            if(lv_rotation % 180 != 0) {
                                return imageLV.x + imageLV.width / 2 - imageLV.paintedHeight / 2
                            }
                        }
                        return imageLV.x + imageLV.width / 2 - imageLV.paintedWidth / 2
                    }
                    y: {
                        if(lv_rotation_mode) {
                            if(lv_rotation_auto % 180 != 0) {
                                return imageLV.y + imageLV.height / 2 - imageLV.paintedWidth / 2
                            }
                        } else {
                            if(lv_rotation % 180 != 0) {
                                return imageLV.y + imageLV.height / 2 - imageLV.paintedWidth / 2
                            }
                        }
                        return imageLV.y + imageLV.height / 2 - imageLV.paintedHeight / 2
                    }
                    width: {
                        if(lv_rotation_mode) {
                            if(lv_rotation_auto % 180 != 0) {
                                return imageLV.paintedHeight;
                            }
                        } else {
                            if(lv_rotation % 180 != 0) {
                                return imageLV.paintedHeight;
                            }
                        }
                        return imageLV.paintedWidth;
                    }
                    height: {
                        if(lv_rotation_mode) {
                            if(lv_rotation_auto % 180 != 0) {
                                return imageLV.paintedWidth;
                            }
                        } else {
                            if(lv_rotation % 180 != 0) {
                                return imageLV.paintedWidth;
                            }
                        }
                        return imageLV.paintedHeight;
                    }
                    // IVC >> Ver.1.8 >> start >> USBTHRV180-19
                    //visible: control.guidelineChecked
                    visible: control.guidelineChecked & deviceAdapter.lvcShowLvControlItem
                    // IVC << Ver.1.8 << end << USBTHRV180-19
                    //rotation: lv_rotation
                }
                /* WB設定枠 */
                Rectangle{
                    id: wbsetting
                    x: imageLV.x + imageLV.width / 2 - imageLV.paintedWidth / 2
                    y: imageLV.y + imageLV.height / 2 - imageLV.paintedHeight / 2
                    width: imageLV.paintedWidth
                    height: imageLV.paintedHeight
                    visible:lv_wbset_mode
                    color:"#00000000"
                    /*LIVE VIEW画面でのマウス動作*/
                    MouseArea {
                        id: internalMouseArea
                        anchors.fill: parent
                        onClicked: {
                            if(lv_wbset_mode) {
                                deviceAdapter.wbset_pos_X = parseInt((mouseX*1000)/width);
                                deviceAdapter.wbset_pos_Y = parseInt((mouseY*1000)/height);
                                control.wb_Position_set()
                            }
                        }
                    }
                }
                // ivc >> start >> No.1
                LTOverlayPhotoFrame {
                    id: overlayPhotoFrame
                    width: overlayImagealias.sourceSize.width * lvOverlayPhotoScalePhoto
                    height: overlayImagealias.sourceSize.height * lvOverlayPhotoScalePhoto
                    liveViewWidth:  imageLV.width
                    liveViewHeight: imageLV.height
                    rotation: (lv_rotation_mode)? lv_rotation_auto: lvOverlayPhotoRotation
                    x: imageLV.x + imageLV.width / 2 - width / 2
                    y: imageLV.y + imageLV.height / 2 - height /2
                    //anchors.fill: parent
                    onWidthChanged: {
                        control.updatePhotoFrameXY()
                    }
                    onHeightChanged: {
                        control.updatePhotoFrameXY()
                    }
                }
                // ivc << end << No.1
                
                // AF Off
                Rectangle {
                    id: afoff
                    x: 10
                    y: root.height - afoff.height - 10
                    width: 72
                    height: 60
                    color: "transparent"
                    visible: false
                    Image {
                        source: "qrc:/images/499_af_off.svg"
                        sourceSize.width: 72
                        sourceSize.height: 60
                    }
                    MouseArea {
                       anchors.fill: parent
                       onClicked: {
                           afframe.afoff()
                       }
                    }
                }

                // マルチ表示中の画像クリックによるカメラ切り替え
                MouseArea{
                    id: switchCameraArea
                    x: imageLV.x + imageLV.width / 2 - imageLV.paintedWidth / 2
                    y: imageLV.y + imageLV.height / 2 - imageLV.paintedHeight / 2
                    width: imageLV.paintedWidth
                    height: imageLV.paintedHeight
                    enabled: deviceAdapter.isMultiviewMode
                    onClicked:(mouse)=> {
                        // クリック座標を入力画像スケールに変換
                        var scaleX = mouse.x * imageLV.sourceRect.width / imageLV.paintedWidth
                        var scaleY = mouse.y * imageLV.sourceRect.height / imageLV.paintedHeight
                        // クリック位置のカメラを判定
                        var dev_index = videoImageInfo.getCameraDevIndex(scaleX, scaleY)
                        if(dev_index >= 0 && dev_index != deviceAdapter.camera_list_get_camera_current_dev_index()) {
                            // カメラ切り替え
                            // Connect to target Camera
                            deviceAdapter.camConnectStatus = LT.Utilities.CamConnectSts_Connecting
                            // Try to connect the new selecting device
                            var ret = deviceAdapter.adp_LMX_func_api_Select_Device_Start(dev_index)
                            if (ret !== LT.DeviceAdapter.Ternary_True) {
                                deviceAdapter.camConnectStatus = LT.Utilities.CamConnectSts_Unknown
                            }
                        }
                    }
                }

                Row{
                    id: iconArea
                    x: {
                        if( deviceAdapter.isSupportMultiView() === true ){
                            return parent.width - width - 10
                        }else{
                            return 10
                        }
                    }
                    y: {
                        if( deviceAdapter.isSupportMultiView() === true ){
                            return parent.height - height - 10
                        }else{
                            return 10
                        }
                    }
                    layoutDirection: Qt.RightToLeft
                    spacing: 5
                    
                    //for Streaming対応
                    // 2020/05/16 Panasonic Nakano
                    // Button: unshow AF Frame & control panel
                    Rectangle {
                        id: unshowAFFrameControlPanel
                        width: 40
                        height: 40
                        color: "black"
                        opacity: 0.7
                        visible: true
                        Image {
                            source: "qrc:/images/liveview_only.svg"
                            sourceSize.width: 40
                            sourceSize.height: 40
                        }
                        MouseArea {
                           anchors.fill: parent
                           onClicked: {
                               availableAFFrame = !availableAFFrame
                               afframe.visible = deviceAdapter.lvcShowLvControlItem && afframeVisible && availableAFFrame && (!deviceAdapter.isMultiviewMode)
                               showControlPanel = !showControlPanel
                               updateLVMultiItemVisible(deviceAdapter.isMultiviewMode)
                               LTSubFunction.console_debug.out("***** availableAFFrame = " + availableAFFrame + ", afframe.visible = " + afframe.visible)
                               if( maskpanel.visible === true ){
                                   //マスクパネルの表示位置を更新しておく
                                   maskpanel.maskSizeUpdate();
                               }
                           }
                        }
                    }
                    // シングル表示/マルチ表示切替
                    Rectangle {
                        id: changeSingleMultiView
                        width: 60
                        height: 40
                        color: "black"
                        opacity: 0.7
                        visible: {
                            if( deviceAdapter.isSupportMultiView() === true ){
                                return true
                            }else{
                                return false
                            }
                        }
                        Image {
                            source: "qrc:/images/multi_mode.svg"
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectFit
                        }
                        MouseArea {
                           anchors.fill: parent
                           onClicked: {
                               if(deviceAdapter.cameraStatus == LT.Utilities.CamStatus_Menu_Displayed){
                                   var ret = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_Menu_End_Menu()
                               }
                               if(deviceAdapter.isMultiviewMode === true){
                                   // シングル表示に切り替え                                   
                                   deviceAdapter.setLiveviewMode_Async(false)
                               }else{
                                   // マルチ表示に切り替え
                                   deviceAdapter.setLiveviewMode_Async(true)
                               }
                           }
                        }
                        // 無効表示用マスク
                        Rectangle {
                            id: changeSingleMultiViewMask
                            anchors.fill: parent
                            color: "black"
                            opacity: 0.7
                            visible: !changeSingleMultiView.enabled
                        }
                    }
                    
                    function show() {
                        if (showTimer.running) {
                            showTimer.stop();
                        }
                        iconArea.visible = true
                        showTimer.start();
                    }
                    function hide() {
                        showTimer.stop()
                        iconArea.visible = false
                    }
                    Timer {
                        id: showTimer
                        interval: 2000
                        running: false
                        repeat: false
                        onTriggered: {
                            LTSubFunction.console_debug.out("***** Timer triggered")
                            iconArea.hide()
                        }
                    }
                }
            }

            /*
                動画記録秒数
             */
            Row {
                x: imageView.width - 180
                y: imageView.y + 10
                id: disptimegroup
                visible: false
                height: Math.max(recmark.implicitHeight, disptime.implicitHeight)
                spacing: 10
                //Text {
                Image {
                    id: recmark
                    anchors.verticalCenter: disptimegroup.verticalCenter
                    //font.pointSize: 20; text: "●"; color: "red"
                    source: "qrc:/images/12_rec_off.svg"
                }
                LTStylishText {
                    id: disptime
                    visible: false
                    type: text_style_liveViewDispTime
                    text: "0s";

                    style: Text.Outline;
                    styleColor: "black"
                    anchors.verticalCenter: disptimegroup.verticalCenter

                }
            }

// ivc >> start >> No.8
            /*
                Bulb Clock
             */
            Row {
                x: imageView.width - 100
                y: imageView.y + 10
                id: disptimeBulbGroup
                visible: false

                //Text
                LTStylishText {
                    id: disptimeBuld
                    type: text_style_liveViewBulbDispTime
                    text: "0";
                    style: Text.Outline;
                    styleColor: "black"
                }
                // Update time
                Timer {
                       id: bulbTimer
                       interval: 1000
                       running: false
                       repeat: true
                       onTriggered: {
                           var diffSecond  = Math.round(Date.now() / 1000) - startTime
                           //バルブは秒数をそのまま表示するように変更する
                           //バルブは最大1800秒（越えるとカメラ側はノイズ除去中になる）なので、1800越えたら表示を消す
                           if(diffSecond > 1800){
                               disptimeBuld.text = ""
                           }else{
                               disptimeBuld.text = diffSecond//bulbTimeFormat(diffSecond)
                           }
                       }
                }
            }
// ivc << end << No.8

            Item {
                id: lvimagemain
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                }
                　　width: parent.height*deviceAdapter.afFrame_asp_x
                x:(1096-width)/2
            }
        }
        Item {
            //for Streaming対応
            visible: showControlPanel  // 2020/05/16 Panasonic Nakano
            id: liveViewMenu
            anchors {
                top: parent.top
                bottom: parent.bottom
            }
            x: parent.width - control.width
            width: 212

            /*
                背景
             */
            Rectangle {
                anchors {
                    fill: parent
                }
                color: palette.backgroundDark
            }

            /*
                LiveView 操作パネル
             */
            LTLiveViewControlItem {
                id: control
                anchors {
                    fill: parent
                }
                onGridSetting: {
                    guidelinePopup.visible = false
                    gridPopup.visible = !gridPopup.visible
                }
                onGridPopupClose: {
                    gridPopup.visible = false
                }
                onGuidelinePopupClose: {
                    guidelinePopup.visible = false
                }
                onGuidelineSetting: {
                    gridPopup.visible = false
                    guidelinePopup.visible = !guidelinePopup.visible
                }
                // ivc >> start >> No.1
                onOverlaySetting: {
                    overlayPhotoPopup.visible = !overlayPhotoPopup.visible
                    //overlayPhotoFrame.updateRotationMarkStatus(overlayPhotoPopup.visible)
                }
                onOverlayPopupClose: {
                    overlayPhotoPopup.visible = false
                    //overlayPhotoFrame.updateRotationMarkStatus(overlayPhotoPopup.visible)
                }
                // ivc << end << No.1
            }
        }
    }

    /*ガイドラインポップアップ*/
    LTGuideLinePopup {
        id: guidelinePopup
        visible: false
        //x:root.width-control.width-guidelinePopup.width-2//700-(deviceAdapter.afFrame_asp_x*3)
        x: root.width-control.width
        y:120
        onVisibleChanged: {
            if(visible) {
                control.maskPanelOpen()
            } else {
                // IVC >> Ver.1.9 >> start >> [THRBOXV100-191]
                if(deviceAdapter.cameraStatus !== LT.Utilities.CamStatus_Menu_Displayed)
                // IVC << Ver.1.9 << end << [THRBOXV100-191]
                {
                    control.maskPanelClose()
                }
            }
        }

        onGuideline1ColorChanged: {
            line1.color = lvGuideLine_color
        }
        onGuideline2ColorChanged: {
            line2.color = lvGuideLine_color
        }
        onGuideline3ColorChanged: {
            line3.color = lvGuideLine_color
        }
        onGuideline4ColorChanged: {
            line4.color = lvGuideLine_color
        }
        onGuideline1PosChanged: {
             lvGuideLine_horizontal1_pos = lvGuideLine_thickness
         }
         onGuideline2PosChanged: {
             lvGuideLine_horizontal2_pos = lvGuideLine_thickness
         }
         onGuideline3PosChanged: {
             lvGuideLine_Vertical1_pos = lvGuideLine_thickness
         }
         onGuideline4PosChanged: {
             lvGuideLine_Vertical2_pos = lvGuideLine_thickness
         }
    }
    /*グリッドポップアップ*/
    LTGridPopup {
         id: gridPopup
         visible: false
         //x:(guidelinePopup.visible?
         //    // ガイドラインポップアップが表示中の場合
         //    ((guidelinePopup.x < gridPopup.width)? guidelinePopup.x+guidelinePopup.width: guidelinePopup.x-gridPopup.width-1):
         //    // ガイドラインポップアップが表示中の場合
         //    root.width-control.width-gridPopup.width-2
         //)
         x: root.width-control.width
         y:120
         onVisibleChanged: {
             if(visible) {
                 control.maskPanelOpen()
             } else {
                 // IVC >> Ver.1.9 >> start >> [THRBOXV100-191]
                 if(deviceAdapter.cameraStatus !== LT.Utilities.CamStatus_Menu_Displayed)
                 // IVC << Ver.1.9 << end << [THRBOXV100-191]
                 {
                    control.maskPanelClose()
                 }
             }
         }
     }

    // ivc >> start >> No.1
    /*ガイドラインポップアップ*/
    LTOverlayPhotoPopup {
        id: overlayPhotoPopup
        visible: false
        x: root.width-control.width
        y:180
        onVisibleChanged: {
            if(visible) {
                control.maskPanelOpen()
                //for Streaming対応
                //afframe.visible = false
                afframe.visible = (afframeVisible = false) && availableAFFrame && (!deviceAdapter.isMultiviewMode) // 2020/05/16 Panasonic Nakano
            } else {
                // IVC >> Ver.1.9 >> start >> [THRBOXV100-191]
                if(deviceAdapter.cameraStatus !== LT.Utilities.CamStatus_Menu_Displayed)
                // IVC << Ver.1.9 << end << [THRBOXV100-191]
                {
                    control.maskPanelClose()
                    // IVC >> Ver.1.8 >> start >> USBTHRV180-19
                    //afframe.visible = true
                    //for Streaming対応
                    //afframe.visible = deviceAdapter.lvcShowLvControlItem
                    afframe.visible = deviceAdapter.lvcShowLvControlItem && (afframeVisible = true) && availableAFFrame && (!deviceAdapter.isMultiviewMode) // 2020/05/16 Panasonic Nakano
                    // IVC << Ver.1.8 << end << USBTHRV180-19
                }
            }
        }
    }
    // ivc << end << No.1

    /*
        水準器の操作 (ピッチ)
     * !! /
    Slider {
        id: pitchSlider
        orientation: Qt.Vertical
        minimumValue: -75
        maximumValue: +75
        value: 0
        onValueChanged: {
            levelIndicator.pitchingDegrees = value;
        }
    }

    / !! *
        水準器の操作 (ロール)
     * !! /
    Slider {
        orientation: Qt.Horizontal
        minimumValue: -75
        maximumValue: +75
        value: 0
        onValueChanged: {
            levelIndicator.rollingDegrees = value;
        }
    }
     */

    /*
      カメラ操作中に全てのコントロールを押せなくする。
     */
    Rectangle {
        id: maskpanel

        property int mode: mode_init //状態をビットフラグでもつ
        readonly property int mode_init: 0
        readonly property int mode_camera: 1 //再生モード
        readonly property int mode_pref: 2 //アプリの設定画面開いている
        readonly property int mode_streaming: 4 //ストリーミング中
        readonly property int mode_lvmenu : 8 //ライブビューMENU中
        readonly property int mode_searchWindow: 16 //起動カメラウインド
        //操作パネル部分のみマスクかどうか
        property bool controlAreaOnly: false

        visible: false
        anchors {
            fill: parent
        }
        color: "black"
        opacity: 0.5
        MouseArea {
            id: maskpanelMouseArea
            anchors {
                fill: parent
            }
            hoverEnabled: true
            onClicked: {
                //root.dismiss();
            }
        }
        LTStylishText {
            id: cameraOperating
            x: imageLV.x + imageLV.width / 2 - cameraOperating.width / 2
            y: imageLV.y + imageLV.height / 2 - cameraOperating.height / 2

            type: text_style_liveViewCamOp
            text: qsTr("camera_operating")
            //ストリーミング中の文言表示で文字切れ起こらないように折り返し表示できるようにする
            width: imageLV.width*0.9
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
        }
        onVisibleChanged: {
            maskSizeUpdate()
        }
        onModeChanged: {
            maskSizeUpdate()
        }
        function maskSizeUpdate()
        {
            if(visible === true){
                if( mode === mode_streaming){
                    //ストリーミングの場合、操作パネルは電動ズーム操作できるようにマスクをかけない
                    anchors.fill = undefined
                    width = imageLV.width
                    height = imageLV.height
                    x = 0
                    y = 0
                    maskpanelMouseArea.anchors.fill = undefined
                    maskpanelMouseArea.width = imageLV.width
                    maskpanelMouseArea.height = imageLV.height
                }else{
                    if( controlAreaOnly === true ){
                        //操作パネル部分のみマスクかける（マルチ中の利用想定）
                        anchors.fill = undefined
                        width = control.width
                        height = control.height
                        x = imageLV.width
                        y = 0
                        maskpanelMouseArea.anchors.fill = undefined
                        maskpanelMouseArea.x = imageLV.width
                        maskpanelMouseArea.y = 0
                        maskpanelMouseArea.width = control.width
                        maskpanelMouseArea.height = control.height
                    }else{
                        x = 0
                        y = 0
                        anchors.fill = parent
                        maskpanelMouseArea.anchors.fill = maskpanel
                        maskpanelMouseArea.x = 0
                        maskpanelMouseArea.y = 0
                    }
                }
            }
        }
    }
}
