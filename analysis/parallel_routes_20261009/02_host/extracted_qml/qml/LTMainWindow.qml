import QtQuick 2.6
import QtQuick.Window 2.2
import QtQuick.Controls 2.3
import Qt.labs.platform 1.0 as LabPlat

import "qrc:/qml"
import LT 1.0 as LT

import "LTSubFunction.js" as LTSubFunction

/*! \qmltype LTMainWindow
    \inqmlmodule LT

    \brief
    撮影設定ウィンドウです
 */
Window {
    id: root

    /*!
        LiveView の切替え要求を通知します
     */
    signal toggleLiveView()

// IVC >> Ver.1.9 >> start >> No.1
    /*!
        CameraList の切替え要求を通知します
     */
    signal toggleCameraList()
// IVC << Ver.1.9 << end << No.1
    /*!
        FlashView の切替え要求を通知します
     */
    signal toggleFlashView()

    /*!
        PreviewView の切替え要求を通知します
     */
    signal togglePreviewView()

    /*!
        PreviewView をポップアップ状態で表示通知します
     */
    signal changePreviewTypePopup()

    /*!
        PreviewView の切替え要求を通知します
     */
    signal changePreviewTypeWindow()

    /*!
        SettingView の切替え要求を通知します
     */
    signal togglePreferenceView()

    /*!
        LiveViewの動画撮影スタートします。
     */
    signal recStart()

    /*!
        LiveViewの動画撮影ストップします。
     */
    signal recStop()

// ivc >> start >> No.8
    /*!
        LiveViewのBulb Start。
     */
    signal recBulbStart()

    /*!
        LiveViewのBulb Stop。
     */
    signal recBulbStop()
// ivc << end << No.8

    /*!
        LiveViewの更新をスタートします。
     */
    signal liveViewStart()

    /*!
        LiveViewの更新をストップします。
     */
    signal liveViewStop()

    /*!
        LiveViewのAFAEスタートします。
     */
    signal afaeStart()

    /*!
        LiveViewのAFAEストップします。
     */
    signal afaeStop()

    //TetherModeの変更が可能かどうかが更新
    signal tetherModeUpdate()

    /*!
        必要最小表示か否かを示します
     */
    property bool compact: applicationSettings.windowSize == LT.ApplicationSettings.WindowShrinked

    // Window height compact size
    readonly property real compactHeight: 163

    // Window height normal size
    readonly property real normalHeight: 669

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

    /*
        動画撮影開始フラグ
     */
    property bool movieRecStartFlg: false
    /*
        バルブ撮影開始フラグ
     */
    property bool bulbRecStartFlg: false
    /*
        連写撮影開始フラグ
     */
    property bool burstRecStartFlg: false
    /*
        6K4K連写撮影開始フラグ
     */
    property bool burst6K4KRecStartFlg: false

    /*
        録画ボタンをマウスが長時間プレスされているかどうかのフラグ
     */
    property bool recPressAndHoldFlg: false
    /*
        AFAEボタンをマウスが長時間プレスされているかどうかのフラグ
     */
    property bool afaePressAndHoldFlg: false
    /*
        シャッターボタンをマウスが長時間プレスされているかどうかのフラグ
     */
    property bool shutterPressAndHoldFlg: false

    /*
        AFAE開始フラグ
     */
    property bool afaeStartFlg: false

    // IVC >> MC893 >>
    readonly property int lastObjectAddInterval: 1000
    property int currentAddedFileCount: 0
    // << IVC << MC893
// IVC >> add >> start >> USBTHRV170-32
    property var displayMovQuality
// IVC << add << end << USBTHRV170-32

    property bool isCopying: false

    function activateWindowNotify() {
        if(root.visibility == Window.Minimized) {
            root.visibility = Window.Windowed
        }
        root.active = true
    }

    function camNameSetting() {
        LTSubFunction.console_debug.out("camNameSetting start = " + deviceAdapter.camName)
        var title_str = deviceAdapter.camName
        if(title_str.length != 0) {
            root.title = title_str
        }
    }

    function cameraValueGetComplete() {
        //Initial value
        recordingModeSetting();
        //intelligentAutoModeSetting();
        //creativeVideoAESetting();
        //custom3SetSetting();
        //creativeControlFilterSetting();
        //sceneGuideSceneSetting();
        batteryLevelSetting();
        imageFreeSpaceSetting();
        secondFreeSpaceSetting();
        statusOfCardsSetting();

        driveModeSetting();
        //picture4K6KSetting();
        //burstSpeedSetting();
        //focusSelectSetting();
        //selfTimerSetting();

        apertureSetting();
        shutterSpdSetting();
        whiteBalanceSetting();
        isoSetting();

        exposureSetting();
        exposureMaxSetting();
        exposureMinSetting();

        motionPictureFormatSetting();
        aspectRatioSetting();

        photoStyleSetting();

        imgInfoQualitySetting();
        focusModeSetting();
        autoFocusModeSetting();
        customMultiSetting();
        meteringModeSetting();
        wbKSetSetting();
        wbAjustABSetting();
        wbAjustGMSetting();

        cameraStatusSetting();

        af_frame_info_Changed()
        sFrame_info_Changed()

        camNameSetting()

        hdmiSdiStatusSetting()
        anotherCameraStatusUpdate()
// IVC >> add >> start >> USBTHRV170-32
//        displayMovQuality = deviceAdapter.adp_LMX_func_api_Mov_Config_Get_Quality_Detail_Display()
// IVC << add << end << USBTHRV170-32
    }

    function af_frame_info_Changed() {
        var s = deviceAdapter.af_status_ulAFStatus();
        LTSubFunction.console_debug.out("MainWindow::af_frame_info_Changed s="+s)
        if(s == LT.Utilities.AfInfoStatus_Unfocused) {
            if(root.afaeStartFlg) {
                root.afaeStartFlg = false;
                root.afaeStop()
                afaeButtonSetting()
            }
        } else {
            if(!root.afaeStartFlg) {
                root.afaeStartFlg = true;
                root.afaeStop()
                afaeButtonSetting()
            }
        }
    }

    function sFrame_info_Changed() {
        var v = deviceAdapter.sFrame_info;
        LTSubFunction.console_debug.out("MainWindow::sFrame_info_Changed v="+v)

        btnOptionAutoFocusMode.isForcedDisable = v
        autoFocusModeSetting()
    }

    // IVC >> MC893 >>
    function clearArrObjectCopy() {
        currentAddedFileCount = 0;
        objectcopy.clearObjectCopys();
    }

    function addObjectCopy() {
        objectcopy.pushObjectCopys();
    }

    function getArrObjectCountSizeString() {
        return parseInt(objectcopy.currentObjectCopySizeString());
    }

    function getArrObjectSizeString() {
        return parseInt(objectcopy.totalObjectCopysSizeString());
    }

    function onRecStartAction() {
        checkLastMovieTimer.isWaiting = true;
        clearArrObjectCopy();

        //コピー予定ならTetherMode変更できないようにする
        if(deviceAdapter.fileTarget !== LT.Utilities.FLTG_CameraOnly)
        {
            var uuid = deviceAdapter.camera_list_get_selected_camera_uuid()
            if (deviceAdapter.cameraStatus === LT.Utilities.CamStatus_RemoteRec ||
                deviceAdapter.cameraStatus === LT.Utilities.CamStatus_LiveStreamingRemoteRec ||
                deviceAdapter.cameraStatus === LT.Utilities.CamStatus_RemoteRecRawHDMI ||
                deviceAdapter.btnAllCameraStatus === LT.Utilities.BtnAllCameraStatus_Checked ||
                (deviceAdapter.isSupportMultiView() === true && deviceAdapter.getSendCmdDevNum() > 1)){
                //リモートのみ録画&AllCamera&コマンド送信対象が複数の場合はコピーしない
                deviceAdapter.camera_list_set_camera_tether_mode_status(uuid, LT.Utilities.TETHERMODE_Copy, false)
            }else{
                deviceAdapter.camera_list_set_camera_tether_mode_status(uuid, LT.Utilities.TETHERMODE_Copy, true)
            }
            tetherModeUpdate()
        }
    }

    // << IVC << MC893

    function cameraStatusSetting() {
        LTSubFunction.console_debug.out("MainWindow::cameraStatusSetting cameraStatus=" + deviceAdapter.cameraStatus)
        //---------------------------------
        //撮影スタンバイ 　　　→0
        //動画記録中(4K/6Kフォト含む) →1
        //動画再生中（4K/6Kフォト除く） →2
        //その他処理中 →3
        //動画以外再生中 →4
        //---------------------------------
        //テザー側で、カメラの状態が{ 2, 3, 4 }の時に操作中を表示するように
        //ご対応をお願いいたします
        if((deviceAdapter.cameraStatus == LT.Utilities.CamStatus_MovRec_Others) ||
           (deviceAdapter.cameraStatus == LT.Utilities.CamStatus_Playing) ||
           (deviceAdapter.cameraStatus == LT.Utilities.CamStatus_Processing) ||
           // IVC >> Ver.1.9 >> start >> [THRBOXV100-162]
            deviceAdapter.cameraStatus == LT.Utilities.CamStatus_Menu_Displayed){
            // IVC << Ver.1.9 << end << [THRBOXV100-162]
            //LTSubFunction.console_debug.out("cameraStatusSetting="+deviceAdapter.cameraStatus)
            //動画画質の設定でエラーメッセージ表示中にDSC本体操作後、ポップアップメニュー消えた後にメッセージ閉じるとAP断となるので
            //ポップアップをクローズする段階でメッセージを消すようにしておく
            settingErrorDlg.visible = false
            // カメラ操作中
            wbPopupCancelClose()
            ccPopupCancelClose()
            photoStylePopupForceClose()
            // IVC >> MC893 >> start >> No.1
            movieQualityPopupCancelClose()
            // IVC << MC893 << end << No.1
            driveModePopupClose()
            if(deviceAdapter.cameraStatus === LT.Utilities.CamStatus_Menu_Displayed) {
                maskpanel.mode |= maskpanel.mode_live_view_menu
                maskpanel.mode &= ~maskpanel.mode_camera
            } else {
                maskpanel.mode |= maskpanel.mode_camera
                maskpanel.mode &= ~maskpanel.mode_live_view_menu
            }
            updateMaskPanel()
        } else if(deviceAdapter.cameraStatus == LT.Utilities.CamStatus_MovRec_4k ||
                  deviceAdapter.cameraStatus == LT.Utilities.CamStatus_RemoteRec ||
                  deviceAdapter.cameraStatus == LT.Utilities.CamStatus_MovRemoteRec ||
                  deviceAdapter.cameraStatus == LT.Utilities.CamStatus_LiveStreamingRemoteRec ||
                  deviceAdapter.cameraStatus == LT.Utilities.CamStatus_RemoteRecRawHDMI
                  ) {
            closeCaptureDlg()
            // カメラ操作中からの復帰
            if(maskpanel.visible) {
                cameraStatusTimer.running = true
            }
            //LTSubFunction.console_debug.out("cameraStatusSetting=1")
            var uuid = deviceAdapter.camera_list_get_selected_camera_uuid()
            if( (deviceAdapter.cameraStatus == LT.Utilities.CamStatus_MovRec_4k ||
                 deviceAdapter.cameraStatus == LT.Utilities.CamStatus_MovRemoteRec) &&
                (deviceAdapter.fileTarget === LT.Utilities.FLTG_PcOnly ||
                 deviceAdapter.fileTarget === LT.Utilities.FLTG_PcAndCamera) &&
                deviceAdapter.btnAllCameraStatus !== LT.Utilities.BtnAllCameraStatus_Checked &&
                !(deviceAdapter.isSupportMultiView() === true && deviceAdapter.getSendCmdDevNum() > 1))
            {
                //SD記録中はコピーフラグ立てておく
                deviceAdapter.camera_list_set_camera_tether_mode_status(uuid, LT.Utilities.TETHERMODE_Copy, true)
            }else{
                deviceAdapter.camera_list_set_camera_tether_mode_status(uuid, LT.Utilities.TETHERMODE_Copy, false)
            }
            tetherModeUpdate()

            // 動画記録中
            updateMovieRecButtonViewStatus(false, false)
            // 録画中、ドライブモード、撮影モードはdisableにする
            btnOptionDriveMode.isForcedDisable = true
            recordingModeSetting()
            btnOptionRecordingMode.isForcedDisable = true
            driveModeSetting()
        } else if(deviceAdapter.cameraStatus == LT.Utilities.CamStatus_IP_LiveStreaming) {
            // カメラ操作中からの復帰
            if(maskpanel.visible) {
                cameraStatusTimer.running = true
            }
            //録画ボタン更新
            updateMovieRecButtonViewStatus(false, false)
            btnOptionDriveMode.isForcedDisable = false
            recordingModeSetting()
            btnOptionRecordingMode.isForcedDisable = false
            driveModeSetting()
        } else {
            //LTSubFunction.console_debug.out("cameraStatusSetting="+deviceAdapter.cameraStatus)
            // カメラ操作中からの復帰
            if(maskpanel.visible) {
                cameraStatusTimer.running = true
            }
            // 動画記録停止
            updateMovieRecButtonViewStatus(false, false)
            btnOptionDriveMode.isForcedDisable = false
            recordingModeSetting()
            btnOptionRecordingMode.isForcedDisable = false
            driveModeSetting()
            switch(deviceAdapter.statusOfCards) {
            case LT.DeviceAdapter.STOC_Normal://,
                root.movieRecStartFlg = false;
                // 2020/09/29 Panasonic THRBOXV100-143 >> start
                //root.afaeStartFlg = false;
                //root.afaeStop()
                //afaeButtonSetting()
                // 2020/09/29 Panasonic THRBOXV100-143 << end
                if(root.burst6K4KRecStartFlg){
                    root.burst6K4KRecStartFlg = false;
                    shutterButton.source = "qrc:/images/15_shutter.svg"
                    shutterButton_dot.source = "qrc:/images/530_shutter_point_normal.svg"
                }
                break;
            case LT.DeviceAdapter.STOC_Nocard://,
            case LT.DeviceAdapter.STOC_Protected://,
            case LT.DeviceAdapter.STOC_Error://,
            case LT.DeviceAdapter.STOC_Undef://=-1,
            case LT.DeviceAdapter.STOC_Max://,
            default:
                break;
            }
        }
    }

    function preferenceWindowVisibleSetting(flg) {
        LTSubFunction.console_debug.out("MainWindow::preferenceWindowVisibleSetting flg=" + flg)
        if(flg) {
            maskpanel.mode |= maskpanel.mode_pref
        } else {
            maskpanel.mode &= ~maskpanel.mode_pref
            //録画中設定ダイアログが閉じられた場合、保存場所が変更されてる可能性あるので再チェック
            if(root.movieRecStartFlg == true){
                var uuid = deviceAdapter.camera_list_get_selected_camera_uuid()
                if( (deviceAdapter.cameraStatus == LT.Utilities.CamStatus_MovRec_4k ||
                     deviceAdapter.cameraStatus == LT.Utilities.CamStatus_MovRemoteRec) &&
                    (deviceAdapter.fileTarget === LT.Utilities.FLTG_PcOnly ||
                     deviceAdapter.fileTarget === LT.Utilities.FLTG_PcAndCamera) &&
                    deviceAdapter.btnAllCameraStatus !== LT.Utilities.BtnAllCameraStatus_Checked &&
                    !(deviceAdapter.isSupportMultiView() === true && deviceAdapter.getSendCmdDevNum() > 1))
                {
                    //SD記録中はコピーフラグ立てておく
                    deviceAdapter.camera_list_set_camera_tether_mode_status(uuid, LT.Utilities.TETHERMODE_Copy, true)
                }else{
                    deviceAdapter.camera_list_set_camera_tether_mode_status(uuid, LT.Utilities.TETHERMODE_Copy, false)
                }
                tetherModeUpdate()
            }
        }
        // IVC << Ver.1.9 << end << [THRBOXV100-162]
        updateMaskPanel()
    }

 // IVC >> MC893 >> start >> No.1
    function movieQualityWindowVisibleSetting(flg) {
        LTSubFunction.console_debug.out("MainWindow::movieQualityWindowVisibleSetting flg=" + flg)
        if(flg) {
            maskpanel.mode |= maskpanel.mode_pref
        } else {
            maskpanel.mode &= ~maskpanel.mode_pref
        }
        updateMaskPanel()
    }
// IVC << MC893 << end << No.1

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
            maskpanel.visible = false
        }else{
            maskpanel.visible = true
        }
    }

//
// レバーの切り替わりを管理する (以前は recordingModeSetting() を emit していた)
// 2024/11 MC824x Start
    function shotModeSetting() {
        if(utilities.isMac()) {
            if (shotMode_timer.shotModeFlg === false) {
                shotMode_timer.shotModeFlg = true
                shotMode_timer.running = true
            } else {
                shotMode_timer.restart()
            }
        }
        recordingModeSetting()
    }

    Timer {
        id: shotMode_timer
        interval: 500; running: false; repeat: false
        property bool shotModeFlg: false
        onTriggered: {
            shotMode_timer.shotModeFlg = false
            recordingModeSetting()
        }
    }
// 2024/11 MC824x End

    function recordingModeSetting() {
        btnOptionRecordingMode.logCol = ltLog;
        btnOptionRecordingMode.logScrTagID = LT.TagDef.RTScr_Usage_Main_RecordMode;
        btnOptionRecordingMode.logFile = "recordingMode";
        //動画画質の設定でエラーメッセージ表示中にDSC本体操作後、ポップアップメニュー消えた後にメッセージ閉じるとAP断となるので
        //ポップアップをクローズする段階でメッセージを消すようにしておく
        settingErrorDlg.visible = false

        recordingModePopupClose()
        wbPopupCancelClose()
        ccPopupCancelClose()
        photoStylePopupForceClose()
        // IVC >> MC893 >> start >> No.1
        movieQualityPopupCancelClose()
        // IVC << MC893 << end << No.1

        btnOptionRecordingMode.popupTitle= qsTr("ShootingMode")
        switch(deviceAdapter.recordingMode) {
        case LT.Utilities.RM_Unknown:// = -1,
            break;
        case LT.Utilities.RM_ProgramAE://,           //P
            if(deviceAdapter.shotModeStatus !== LT.Utilities.Shot_Mode_Status_Unknown){
                exposureDialSetting();               // レバー有り機設定
            } else {
                //console.log("LT.Utilities.RM_ProgramAE recordingMode");
                btnOptionRecordingMode.popup = optionRecordingModeButtonPopup
                btnOptionRecordingMode.target = "recordingMode"
                btnOptionRecordingMode.optionSelect(LT.Utilities.RM_ProgramAE)
// IVC >> Ver.1.9 >> start >> No.5
                if(deviceAdapter.recordingModeCapabilityNum() > 0){
                    btnOptionRecordingMode.optionOpen = true
                    btnOptionRecordingMode.disabled = false
                }else{
                    btnOptionRecordingMode.optionOpen = false
                    btnOptionRecordingMode.disabled = true
                }
// IVC << Ver.1.9 << end << No.5
            }
            break;
        case LT.Utilities.RM_AperturePriorityAE://,  //A
            if(deviceAdapter.shotModeStatus !== LT.Utilities.Shot_Mode_Status_Unknown){
                exposureDialSetting();               // レバー有り機設定
            } else {
                //console.log("LT.Utilities.RM_AperturePriorityAE recordingMode");
                btnOptionRecordingMode.popup = optionRecordingModeButtonPopup
                btnOptionRecordingMode.target = "recordingMode"
                btnOptionRecordingMode.optionSelect(LT.Utilities.RM_AperturePriorityAE)
// IVC >> Ver.1.9 >> start >> No.5
                if(deviceAdapter.recordingModeCapabilityNum() > 0){
                    btnOptionRecordingMode.optionOpen = true
                    btnOptionRecordingMode.disabled = false
                }else{
                    btnOptionRecordingMode.optionOpen = false
                    btnOptionRecordingMode.disabled = true
                }
// IVC << Ver.1.9 << end << No.5
            }
            break;
        case LT.Utilities.RM_ShutterPriorityAE://,   //S
            if(deviceAdapter.shotModeStatus !== LT.Utilities.Shot_Mode_Status_Unknown){
                exposureDialSetting();               // レバー有り機設定
            } else {
                //console.log("LT.Utilities.RM_ShutterPriorityAE recordingMode");
                btnOptionRecordingMode.target = "recordingMode"
                btnOptionRecordingMode.popup = optionRecordingModeButtonPopup
                btnOptionRecordingMode.optionSelect(LT.Utilities.RM_ShutterPriorityAE)
// IVC >> Ver.1.9 >> start >> No.5
                if(deviceAdapter.recordingModeCapabilityNum() > 0){
                    btnOptionRecordingMode.optionOpen = true
                    btnOptionRecordingMode.disabled = false
                }else{
                    btnOptionRecordingMode.optionOpen = false
                    btnOptionRecordingMode.disabled = true
                }
// IVC << Ver.1.9 << end << No.5
            }
            break;
        case LT.Utilities.RM_ManualExposure://,      //M
            if(deviceAdapter.shotModeStatus !== LT.Utilities.Shot_Mode_Status_Unknown){
                exposureDialSetting();               // レバー有り機設定
            } else {
                //console.log("LT.Utilities.RM_ManualExposure recordingMode");
                btnOptionRecordingMode.target = "recordingMode"
                btnOptionRecordingMode.popup = optionRecordingModeButtonPopup
                btnOptionRecordingMode.optionSelect(LT.Utilities.RM_ManualExposure)
// IVC >> Ver.1.9 >> start >> No.5
                if(deviceAdapter.recordingModeCapabilityNum() > 0){
                    btnOptionRecordingMode.optionOpen = true
                    btnOptionRecordingMode.disabled = false
                }else{
                    btnOptionRecordingMode.optionOpen = false
                    btnOptionRecordingMode.disabled = true
                }
// IVC << Ver.1.9 << end << No.5
            }
            break;
        case LT.Utilities.RM_CreativeControl://,     //クリエイティブコントロール
            //console.log("LT.Utilities.RM_CreativeControl creativeControlFilter");
            btnOptionRecordingMode.popup = ccPopup
            if(utilities.getLanguageType() == LT.QLocale.Japanese) {
                btnOptionRecordingMode.target = "creativeControlFilter"
            } else {
                btnOptionRecordingMode.target = "creativeControlFilterRatin"
            }
            btnOptionRecordingMode.popupTitle = qsTr("CreativeControl")
            btnOptionRecordingMode.optionOpen = true
            btnOptionRecordingMode.disabled = false
            creativeControlFilterSetting();
            break;
        case LT.Utilities.RM_CreativeVideo://,       //クリエイティブ動画
            //console.log("LT.Utilities.RM_CreativeVideo creativeVideoAE");
            btnOptionRecordingMode.popup = optionRecordingModeButtonPopup
// IVC >> Ver.1.9 >> start >> No.5
            if(deviceAdapter.recordingModeCapabilityNum() > 0){
                btnOptionRecordingMode.target = "recordingMode"
                btnOptionRecordingMode.optionSelect(LT.Utilities.RM_CreativeVideo)
                btnOptionRecordingMode.optionOpen = true
                btnOptionRecordingMode.disabled = false
            }else{
                btnOptionRecordingMode.target = "creativeVideoAE"
                btnOptionRecordingMode.popupTitle = qsTr("CreativeVideo")
                btnOptionRecordingMode.optionOpen = true
                btnOptionRecordingMode.disabled = false
                creativeVideoAESetting();
            }
// IVC << Ver.1.9 << end << No.5
            break;
        case LT.Utilities.RM_SceneGuide://,          //シーンガイド
            //console.log("LT.Utilities.RM_SceneGuide sceneGuideScene");
            btnOptionRecordingMode.popup = optionRecordingModeButtonPopup
            btnOptionRecordingMode.target = "sceneGuideScene"
            btnOptionRecordingMode.popupTitle = qsTr("SceneGuide")
            btnOptionRecordingMode.optionOpen = true
            btnOptionRecordingMode.disabled = false
            sceneGuideSceneSetting();
            break;
        case LT.Utilities.RM_IntelligentAuto://,     //iA
            //console.log("LT.Utilities.RM_IntelligentAuto intelligentAutoMode");
            btnOptionRecordingMode.popup = optionRecordingModeButtonPopup
            btnOptionRecordingMode.target = "intelligentAutoMode"
            btnOptionRecordingMode.popupTitle = qsTr("IntelligentAuto")
            btnOptionRecordingMode.optionOpen = true
            btnOptionRecordingMode.disabled = false
            intelligentAutoModeSetting();
            break;
        case LT.Utilities.RM_Custom1://,             //C1
            //console.log("LT.Utilities.RM_Custom1 recordingMode");
            btnOptionRecordingMode.target = "recordingMode"
            btnOptionRecordingMode.popup = optionRecordingModeButtonPopup
            btnOptionRecordingMode.optionSelect(LT.Utilities.RM_Custom1)
// IVC >> Ver.1.9 >> start >> No.5
            if(deviceAdapter.recordingModeCapabilityNum() > 0){
                btnOptionRecordingMode.optionOpen = true
                btnOptionRecordingMode.disabled = false
            }else{
                btnOptionRecordingMode.optionOpen = false
                btnOptionRecordingMode.disabled = true
            }
// IVC << Ver.1.9 << end << No.5
            break;
        case LT.Utilities.RM_Custom2://,             //C2
            //console.log("LT.Utilities.RM_Custom2 recordingMode");
            btnOptionRecordingMode.target = "recordingMode"
            btnOptionRecordingMode.popup = optionRecordingModeButtonPopup
            btnOptionRecordingMode.optionSelect(LT.Utilities.RM_Custom2)
// IVC >> Ver.1.9 >> start >> No.5
            if(deviceAdapter.recordingModeCapabilityNum() > 0){
                btnOptionRecordingMode.optionOpen = true
                btnOptionRecordingMode.disabled = false
            }else{
                btnOptionRecordingMode.optionOpen = false
                btnOptionRecordingMode.disabled = true
            }
// IVC << Ver.1.9 << end << No.5
            break;
        case LT.Utilities.RM_Custom3://,             //C3
            //console.log("LT.Utilities.RM_Custom3 custom3Set");
            if(deviceAdapter.recordingModeCapabilityNum() > 0){
                btnOptionRecordingMode.target = "recordingMode"
                btnOptionRecordingMode.popup = optionRecordingModeButtonPopup
                btnOptionRecordingMode.optionSelect(LT.Utilities.RM_Custom3)
                btnOptionRecordingMode.optionOpen = true
                btnOptionRecordingMode.disabled = false
            }else{
                // カスタム3セットがOFFの場合は"C3"表示
                // BOXカメラでカスタム3セットが有効になる対策。テザーコネクトモードをサポートする場合も"C3"表示
                if(LT.Utilities.RM_C3_SetOFF == deviceAdapter.custom3Set || deviceAdapter.camSupportPowerSaving) {
                    btnOptionRecordingMode.target = "recordingMode"
                    btnOptionRecordingMode.popup = optionRecordingModeButtonPopup
                    btnOptionRecordingMode.optionSelect(LT.Utilities.RM_Custom3)
                    btnOptionRecordingMode.optionOpen = false
                    btnOptionRecordingMode.disabled = true
                } else {
                    btnOptionRecordingMode.target = "custom3Set"
                    btnOptionRecordingMode.popup = optionRecordingModeButtonPopup
                    btnOptionRecordingMode.popupTitle = qsTr("Custom3")
                    btnOptionRecordingMode.optionOpen = true
                    btnOptionRecordingMode.disabled = false
                    custom3SetSetting();
                }
            }
            break;
        case LT.Utilities.RM_Panorama://,            //パノラマ
            //console.log("LT.Utilities.RM_Panorama recordingMode");
            btnOptionRecordingMode.target = "recordingMode"
            btnOptionRecordingMode.popup = optionRecordingModeButtonPopup
            btnOptionRecordingMode.optionSelect(LT.Utilities.RM_Panorama)
            btnOptionRecordingMode.optionOpen = false
            btnOptionRecordingMode.disabled = true
            break;
    // IVC >> Ver.1.8 >> start >> No.3
        case LT.Utilities.RM_SQMotion://,       //スロー＆クイック
            //console.log("LT.Utilities.RM_SQMotion sqMotion");
            btnOptionRecordingMode.popup = optionRecordingModeButtonPopup
            btnOptionRecordingMode.target = "sqMotion"
            btnOptionRecordingMode.popupTitle = qsTr("SQMotion")
            btnOptionRecordingMode.optionOpen = true
            btnOptionRecordingMode.disabled = false
            creativeVideoAESetting();
            break;
    // IVC << Ver.1.8 << end << No.3
// IVC >> Ver.1.9 >> start >> No.5
        case LT.Utilities.RM_Custom4://,             //C4
            if(deviceAdapter.recordingModeCapabilityNum() > 0){
                btnOptionRecordingMode.target = "recordingMode"
                btnOptionRecordingMode.popup = optionRecordingModeButtonPopup
                btnOptionRecordingMode.optionSelect(LT.Utilities.RM_Custom4)
                btnOptionRecordingMode.optionOpen = true
                btnOptionRecordingMode.disabled = false
            }else{
                // カスタム3セットがOFFの場合は"C4"表示
                // BOXカメラでカスタム3セットが有効になる対策。テザーコネクトモードをサポートする場合も"C4"表示
                if(LT.Utilities.RM_C3_SetOFF == deviceAdapter.custom3Set || deviceAdapter.camSupportPowerSaving) {
                    btnOptionRecordingMode.target = "recordingMode"
                    btnOptionRecordingMode.popup = optionRecordingModeButtonPopup
                    btnOptionRecordingMode.optionSelect(LT.Utilities.RM_Custom4)
                    btnOptionRecordingMode.optionOpen = false
                    btnOptionRecordingMode.disabled = true
                } else {
                    btnOptionRecordingMode.target = "custom4Set"
                    btnOptionRecordingMode.popup = optionRecordingModeButtonPopup
                    btnOptionRecordingMode.popupTitle = qsTr("Custom4")
                    btnOptionRecordingMode.optionOpen = true
                    btnOptionRecordingMode.disabled = false
                    custom3SetSetting();
                }
            }

            break;
        case LT.Utilities.RM_Custom5://,             //C5
// MC8241 カスタム5 に ポップアップを追加 (カスタム3、カスタム4、カスタム5、のいずれかのみ Popup なら問題ないが複数なら別の処理が必要かも)
            if(deviceAdapter.recordingModeCapabilityNum() > 0){
                btnOptionRecordingMode.target = "recordingMode"
                btnOptionRecordingMode.popup = optionRecordingModeButtonPopup
                btnOptionRecordingMode.optionSelect(LT.Utilities.RM_Custom5)
                btnOptionRecordingMode.optionOpen = true
                btnOptionRecordingMode.disabled = false
            } else{
                // カスタム3セットがOFFの場合は"C5"表示
                // BOXカメラでカスタム3セットが有効になる対策。テザーコネクトモードをサポートする場合も"C5"表示
                if(LT.Utilities.RM_C3_SetOFF == deviceAdapter.custom3Set || deviceAdapter.camSupportPowerSaving) {
                    btnOptionRecordingMode.target = "recordingMode"
                    btnOptionRecordingMode.popup = optionRecordingModeButtonPopup
                    btnOptionRecordingMode.optionSelect(LT.Utilities.RM_Custom5)
                    btnOptionRecordingMode.optionOpen = false
                    btnOptionRecordingMode.disabled = true
                } else {
                    btnOptionRecordingMode.target = "custom5Set"
                    btnOptionRecordingMode.popup = optionRecordingModeButtonPopup
                    btnOptionRecordingMode.popupTitle = qsTr("Custom5")
                    btnOptionRecordingMode.optionOpen = true
                    btnOptionRecordingMode.disabled = false
                    custom3SetSetting();
                }
            }
 // MC8241 End
            break;
        case LT.Utilities.RM_Custom6://,             //C6
            btnOptionRecordingMode.target = "recordingMode"
            btnOptionRecordingMode.popup = optionRecordingModeButtonPopup
            btnOptionRecordingMode.optionSelect(LT.Utilities.RM_Custom6)
            btnOptionRecordingMode.optionOpen = true
            btnOptionRecordingMode.disabled = false
            //custom3SetSetting();
            break;
        case LT.Utilities.RM_Custom7://,             //C7
            btnOptionRecordingMode.target = "recordingMode"
            btnOptionRecordingMode.popup = optionRecordingModeButtonPopup
            btnOptionRecordingMode.optionSelect(LT.Utilities.RM_Custom7)
            btnOptionRecordingMode.optionOpen = true
            btnOptionRecordingMode.disabled = false
            //custom3SetSetting();
            break;
        case LT.Utilities.RM_Custom8://,             //C8
            btnOptionRecordingMode.target = "recordingMode"
            btnOptionRecordingMode.popup = optionRecordingModeButtonPopup
            btnOptionRecordingMode.optionSelect(LT.Utilities.RM_Custom8)
            btnOptionRecordingMode.optionOpen = true
            btnOptionRecordingMode.disabled = false
            //custom3SetSetting();
            break;
        case LT.Utilities.RM_Custom9://,             //C9
            btnOptionRecordingMode.target = "recordingMode"
            btnOptionRecordingMode.popup = optionRecordingModeButtonPopup
            btnOptionRecordingMode.optionSelect(LT.Utilities.RM_Custom9)
            btnOptionRecordingMode.optionOpen = true
            btnOptionRecordingMode.disabled = false
            //custom3SetSetting();
            break;
        case LT.Utilities.RM_Custom10://,             //C10
            btnOptionRecordingMode.target = "recordingMode"
            btnOptionRecordingMode.popup = optionRecordingModeButtonPopup
            btnOptionRecordingMode.optionSelect(LT.Utilities.RM_Custom10)
            btnOptionRecordingMode.optionOpen = true
            btnOptionRecordingMode.disabled = false
            //custom3SetSetting();
            break;
        case LT.Utilities.RM_Custom11://,             //C11
            btnOptionRecordingMode.target = "recordingMode"
            btnOptionRecordingMode.popup = optionRecordingModeButtonPopup
            btnOptionRecordingMode.optionSelect(LT.Utilities.RM_Custom11)
            btnOptionRecordingMode.optionOpen = true
            btnOptionRecordingMode.disabled = false
            //custom3SetSetting();
            break;
        case LT.Utilities.RM_Custom12://,             //C12
            btnOptionRecordingMode.target = "recordingMode"
            btnOptionRecordingMode.popup = optionRecordingModeButtonPopup
            btnOptionRecordingMode.optionSelect(LT.Utilities.RM_Custom12)
            btnOptionRecordingMode.optionOpen = true
            btnOptionRecordingMode.disabled = false
            //custom3SetSetting();
            break;
// IVC << Ver.1.9 << end << No.5
        default:
            break;
        }

        wbAdjustSetting()
        // IVC >> Ver.1.9 >> start >> No.5.1
        focusModeSetting();
        // IVC << Ver.1.9 << end << No.5.1

        ltLog.log(LT.TagDef.RecLvl_Info,
                  LT.TagDef.RTScr_Usage_Main_RecordMode,
                  "recordingModeSetting",
                  utilities.enumRecordingModeToVal(deviceAdapter.recordingMode));
    }

    function wbAdjustSetting() {
        wbAdjustPopup.recordingModeSetting()
        wbAdjustSettingText()
    }

    function wbAdjustSettingText() {
        btnWBAdjust.optionText = wbAdjustPopup.valueWBAdjustTextFormat();
        var text1 = "<HTML>"
        var text2 = qsTr("WB Tuning")
        var text3 = "<br>"
        var text4 = btnWBAdjust.optionText
        var text5 = "</HTML>"
        if (text4.length === 0){
            var disp_text = text1 + text2 + text5                   // WB微調整ツールチップの余白調整
        } else {
            disp_text = text1 + text2 + text3 + text4 + text5
        }
        btnWBAdjust.optionTextTooltip = disp_text
    }

    function intelligentAutoModeSetting() {
        //console.log("intelligentAutoModeSetting start");
        switch(deviceAdapter.recordingMode) {
        case LT.Utilities.RM_IntelligentAuto://,     //iA
            btnOptionRecordingMode.optionSelect(deviceAdapter.intelligentAutoMode)

            btnOptionRecordingMode.logScrTagID = LT.TagDef.RTScr_Usage_Main_IntelligentAutoMode;
            btnOptionRecordingMode.logFile = btnOptionRecordingMode.target;

            wbAdjustSetting()
            break;
        case LT.Utilities.RM_Unknown:// = -1,
        case LT.Utilities.RM_ProgramAE://,           //P
        case LT.Utilities.RM_AperturePriorityAE://,  //A
        case LT.Utilities.RM_ShutterPriorityAE://,   //S
        case LT.Utilities.RM_ManualExposure://,      //M
        case LT.Utilities.RM_CreativeControl://,     //クリエイティブコントロール
        case LT.Utilities.RM_CreativeVideo://,       //クリエイティブ動画
        case LT.Utilities.RM_SceneGuide://,          //シーンガイド
        case LT.Utilities.RM_Custom1://,             //C1
        case LT.Utilities.RM_Custom2://,             //C2
        case LT.Utilities.RM_Custom3://,             //C3
        case LT.Utilities.RM_Panorama://,            //パノラマ
        case LT.Utilities.RM_Custom4://,             //C4
        default:
            break;
        }
    }

    function creativeVideoAESetting() {
        //console.log("creativeVideoAESetting start");
        if(deviceAdapter.shotModeStatus !== LT.Utilities.Shot_Mode_Status_Unknown){
            exposureDialSetting();                      // 切替レバー機では recordingMode が違う
        }else{
            switch(deviceAdapter.recordingMode) {
            case LT.Utilities.RM_CreativeVideo://,       //クリエイティブ動画
// IVC >> Ver.1.9 >> start >> No.5
                if(deviceAdapter.recordingModeCapabilityNum() > 0){
                    btnOptionRecordingMode.optionSelect(deviceAdapter.recordingMode)
                    btnOptionRecordingMode.logScrTagID = LT.TagDef.RTScr_Usage_Main_RecordMode;
                    btnOptionRecordingMode.logFile = btnOptionRecordingMode.target;
                }else{
                    btnOptionRecordingMode.optionSelect(deviceAdapter.creativeVideoAE)
                    btnOptionRecordingMode.logScrTagID = LT.TagDef.RTScr_Usage_Main_CreativeVideoAE;
                    btnOptionRecordingMode.logFile = btnOptionRecordingMode.target;
                }
// IVC << Ver.1.9 << end << No.5
                break;
            // IVC >> Ver.1.8 >> start >> No.3
            case LT.Utilities.RM_SQMotion://,       //クリエイティブ動画
                btnOptionRecordingMode.optionSelect(deviceAdapter.sqMotion)

                btnOptionRecordingMode.logScrTagID = LT.TagDef.RTScr_Usage_Main_SQMotion;
                btnOptionRecordingMode.logFile = btnOptionRecordingMode.target;
                break;
            // IVC << Ver.1.8 << end << No.3
            case LT.Utilities.RM_Unknown:// = -1,
            case LT.Utilities.RM_ProgramAE://,           //P
            case LT.Utilities.RM_AperturePriorityAE://,  //A
            case LT.Utilities.RM_ShutterPriorityAE://,   //S
            case LT.Utilities.RM_ManualExposure://,      //M
            case LT.Utilities.RM_CreativeControl://,     //クリエイティブコントロール
            case LT.Utilities.RM_SceneGuide://,          //シーンガイド
            case LT.Utilities.RM_IntelligentAuto://,     //iA
            case LT.Utilities.RM_Custom1://,             //C1
            case LT.Utilities.RM_Custom2://,             //C2
            case LT.Utilities.RM_Custom3://,             //C3
            case LT.Utilities.RM_Panorama://,            //パノラマ
            case LT.Utilities.RM_Custom4://,             //C4
            default:
                break;
            }
        }
    }

// MC2841 2024/7 切替レバー P/A/S/M　対応 start
// レバー有り機セッティング
//----------------------------------------------------------
    function exposureDialSetting(){
        switch(deviceAdapter.recordingMode) {
        case LT.Utilities.RM_ProgramAE://,           //P
        case LT.Utilities.RM_AperturePriorityAE://,  //A
        case LT.Utilities.RM_ShutterPriorityAE://,   //S
        case LT.Utilities.RM_ManualExposure://,      //M:
            switch(deviceAdapter.shotModeStatus){
            case LT.Utilities.Shot_Mode_Status_Photo:
    //console.debug("photo ex ", deviceAdapter.photoExposure);
                if (deviceAdapter.photoExposure === LT.Utilities.RM_PE_Dial){
                    btnOptionRecordingMode.target = "photoExposure"
                    switch(deviceAdapter.recordingMode){
                    case LT.Utilities.RM_ProgramAE:                         //P
                        btnOptionRecordingMode.optionSelect(LT.Utilities.RM_PE_ProgramAE)
                        break;
                    case LT.Utilities.RM_AperturePriorityAE:                //A
                        btnOptionRecordingMode.optionSelect(LT.Utilities.RM_PE_AperturePriorityAE)
                        break;
                    case LT.Utilities.RM_ShutterPriorityAE:                 //S
                        btnOptionRecordingMode.optionSelect(LT.Utilities.RM_PE_ShutterPriorityAE)
                        break;
                    case LT.Utilities.RM_ManualExposure:                    //M
                        btnOptionRecordingMode.optionSelect(LT.Utilities.RM_PE_ManualExposure)
                        break;
                    }
                    btnOptionRecordingMode.popupTitle = qsTr("Photo")
                    btnOptionRecordingMode.optionOpen = false
                    btnOptionRecordingMode.disabled = true
                } else {
                    btnOptionRecordingMode.target = "photoExposure"
                    btnOptionRecordingMode.popup = optionRecordingModeButtonPopup           // ポップアップモード
                    btnOptionRecordingMode.optionSelect(deviceAdapter.photoExposure)
                    btnOptionRecordingMode.popupTitle = qsTr("Photo")
                    btnOptionRecordingMode.optionOpen = true
                    btnOptionRecordingMode.disabled = false
                }
                break;
            case LT.Utilities.Shot_Mode_Status_Movie:
                deviceAdapter.updateCreativeVideoMode();
                if (deviceAdapter.creativeVideoAE === LT.Utilities.RM_CV_Dial){
                    btnOptionRecordingMode.target = "creativeVideoAE"
                    switch(deviceAdapter.recordingMode){
                    case LT.Utilities.RM_ProgramAE:                          //P
                        btnOptionRecordingMode.optionSelect(LT.Utilities.RM_CV_ProgramAE)
                        break;
                    case LT.Utilities.RM_AperturePriorityAE:                 //A
                        btnOptionRecordingMode.optionSelect(LT.Utilities.RM_CV_AperturePriorityAE)
                        break;
                    case LT.Utilities.RM_ShutterPriorityAE:                  //S
                        btnOptionRecordingMode.optionSelect(LT.Utilities.RM_CV_ShutterPriorityAE)
                        break;
                    case LT.Utilities.RM_ManualExposure:                     //M
                        btnOptionRecordingMode.optionSelect(LT.Utilities.RM_CV_ManualExposure)
                        break;
                    }
                    btnOptionRecordingMode.popupTitle = qsTr("Movie")
                    btnOptionRecordingMode.optionOpen = false
                    btnOptionRecordingMode.disabled = true
                } else {
                    btnOptionRecordingMode.target = "creativeVideoAE"
                    btnOptionRecordingMode.popup = optionRecordingModeButtonPopup
                    btnOptionRecordingMode.optionSelect(deviceAdapter.creativeVideoAE)      // ポップアップモード
                    btnOptionRecordingMode.popupTitle = qsTr("Movie")
                    btnOptionRecordingMode.optionOpen = true
                    btnOptionRecordingMode.disabled = false
                }
                break;
            case LT.Utilities.Shot_Mode_Status_Slow_Quick:
                deviceAdapter.updateCreativeVideoMode();
                if (deviceAdapter.sqMotion === LT.Utilities.RM_CV_Dial){
                    btnOptionRecordingMode.target = "sqMotion"
                    switch(deviceAdapter.recordingMode){                    //ダイヤルモード   recordingMode 1-4  to optionSelect 0-3
                    case LT.Utilities.RM_ProgramAE:                         //P
                        btnOptionRecordingMode.optionSelect(LT.Utilities.RM_CV_ProgramAE)
                        break;
                    case LT.Utilities.RM_AperturePriorityAE:                //A
                        btnOptionRecordingMode.optionSelect(LT.Utilities.RM_CV_AperturePriorityAE)
                        break;
                    case LT.Utilities.RM_ShutterPriorityAE:                 //S
                        btnOptionRecordingMode.optionSelect(LT.Utilities.RM_CV_ShutterPriorityAE)
                        break;
                    case LT.Utilities.RM_ManualExposure:                    //M
                        btnOptionRecordingMode.optionSelect(LT.Utilities.RM_CV_ManualExposure)
                        break;
                    }
                    btnOptionRecordingMode.popupTitle = qsTr("SQMotion")
                    btnOptionRecordingMode.optionOpen = false
                    btnOptionRecordingMode.disabled = true
                } else {
                    btnOptionRecordingMode.target = "sqMotion"
                    btnOptionRecordingMode.popup = optionRecordingModeButtonPopup           // ポップアップモード
                    btnOptionRecordingMode.optionSelect(deviceAdapter.sqMotion)
                    btnOptionRecordingMode.popupTitle = qsTr("SQMotion")
                    btnOptionRecordingMode.optionOpen = true
                    btnOptionRecordingMode.disabled = false
                }
                break;
            }
            break;
        case LT.Utilities.RM_Unknown:// = -1,
        case LT.Utilities.RM_CreativeVideo://,       //クリエイティブ動画
        case LT.Utilities.RM_CreativeControl://,     //クリエイティブコントロール
        case LT.Utilities.RM_SceneGuide://,          //シーンガイド
        case LT.Utilities.RM_IntelligentAuto://,     //iA
        case LT.Utilities.RM_Custom1://,             //C1
        case LT.Utilities.RM_Custom2://,             //C2
        case LT.Utilities.RM_Custom3://,             //C3
        case LT.Utilities.RM_Panorama://,            //パノラマ
        case LT.Utilities.RM_SQMotion://,             //クリエイティブ動画
        case LT.Utilities.RM_Custom4://,             //C4
        default:
            break;
        }
    }
    // MC2841 2024/7 切替レバー P/A/S/M　対応 end

    function custom3SetSetting() {
        //console.log("custom3SetSetting start");
        switch(deviceAdapter.recordingMode) {
        case LT.Utilities.RM_Custom3://,             //C3
            if(deviceAdapter.recordingModeCapabilityNum() > 0){
                btnOptionRecordingMode.optionSelect(deviceAdapter.recordingMode)
                btnOptionRecordingMode.logScrTagID = LT.TagDef.RTScr_Usage_Main_RecordMode;
                btnOptionRecordingMode.logFile = btnOptionRecordingMode.target;
            }else{
                // カスタム3セットがOFFの場合は"C3"表示
                // BOXカメラでカスタム3セットが有効になる対策。テザーコネクトモードをサポートする場合も"C3"表示
                if(!deviceAdapter.camSupportPowerSaving && LT.Utilities.RM_C3_SetOFF != deviceAdapter.custom3Set) {
                    btnOptionRecordingMode.optionSelect(deviceAdapter.custom3Set)
    
                    btnOptionRecordingMode.logScrTagID = LT.TagDef.RTScr_Usage_Main_Custom3Set;
                    btnOptionRecordingMode.logFile = btnOptionRecordingMode.target;
                }
            }
            break;
        case LT.Utilities.RM_Custom4://,             //C4
            if(deviceAdapter.recordingModeCapabilityNum() > 0){
                btnOptionRecordingMode.optionSelect(deviceAdapter.recordingMode)
                btnOptionRecordingMode.logScrTagID = LT.TagDef.RTScr_Usage_Main_RecordMode;
                btnOptionRecordingMode.logFile = btnOptionRecordingMode.target;
            }else{
                // カスタム3セットがOFFの場合は"C4"表示
                // BOXカメラでカスタム3セットが有効になる対策。テザーコネクトモードをサポートする場合も"C4"表示
                if(!deviceAdapter.camSupportPowerSaving && LT.Utilities.RM_C3_SetOFF != deviceAdapter.custom3Set){
                    btnOptionRecordingMode.optionSelect(deviceAdapter.custom3Set)
        
                    btnOptionRecordingMode.logScrTagID = LT.TagDef.RTScr_Usage_Main_Custom3Set;
                    btnOptionRecordingMode.logFile = btnOptionRecordingMode.target;
                }
            }
            break;
        case LT.Utilities.RM_Custom5://,             //C5
            if(deviceAdapter.recordingModeCapabilityNum() > 0){
                btnOptionRecordingMode.optionSelect(deviceAdapter.recordingMode)
                btnOptionRecordingMode.logScrTagID = LT.TagDef.RTScr_Usage_Main_RecordMode;
                btnOptionRecordingMode.logFile = btnOptionRecordingMode.target;
            }else{
                // カスタム3セットがOFFの場合は"C5"表示
                // BOXカメラでカスタム3セットが有効になる対策。テザーコネクトモードをサポートする場合も"C5"表示
                if(!deviceAdapter.camSupportPowerSaving && LT.Utilities.RM_C3_SetOFF != deviceAdapter.custom3Set){
                    btnOptionRecordingMode.optionSelect(deviceAdapter.custom3Set)

                    btnOptionRecordingMode.logScrTagID = LT.TagDef.RTScr_Usage_Main_Custom3Set;
                    btnOptionRecordingMode.logFile = btnOptionRecordingMode.target;
                }
            }
            break;
        case LT.Utilities.RM_Unknown:// = -1,
        case LT.Utilities.RM_ProgramAE://,           //P
        case LT.Utilities.RM_AperturePriorityAE://,  //A
        case LT.Utilities.RM_ShutterPriorityAE://,   //S
        case LT.Utilities.RM_ManualExposure://,      //M
        case LT.Utilities.RM_CreativeControl://,     //クリエイティブコントロール
        case LT.Utilities.RM_CreativeVideo://,       //クリエイティブ動画
        case LT.Utilities.RM_SceneGuide://,          //シーンガイド
        case LT.Utilities.RM_IntelligentAuto://,     //iA
        case LT.Utilities.RM_Custom1://,             //C1
        case LT.Utilities.RM_Custom2://,             //C2
        case LT.Utilities.RM_Panorama://,            //パノラマ
        default:
            break;
        }
    }

    function creativeControlFilterSetting() {
        //console.log("creativeControlFilterSetting start");
        switch(deviceAdapter.recordingMode) {
        case LT.Utilities.RM_CreativeControl://,     //クリエイティブコントロール
            btnOptionRecordingMode.optionSelect(deviceAdapter.creativeControlFilter)

            btnOptionRecordingMode.logScrTagID = LT.TagDef.RTScr_Usage_Main_CreativeControlFilter;
            btnOptionRecordingMode.logFile = btnOptionRecordingMode.target;
            break;
        case LT.Utilities.RM_Unknown:// = -1,
        case LT.Utilities.RM_ProgramAE://,           //P
        case LT.Utilities.RM_AperturePriorityAE://,  //A
        case LT.Utilities.RM_ShutterPriorityAE://,   //S
        case LT.Utilities.RM_ManualExposure://,      //M
        case LT.Utilities.RM_CreativeVideo://,       //クリエイティブ動画
        case LT.Utilities.RM_SceneGuide://,          //シーンガイド
        case LT.Utilities.RM_IntelligentAuto://,     //iA
        case LT.Utilities.RM_Custom1://,             //C1
        case LT.Utilities.RM_Custom2://,             //C2
        case LT.Utilities.RM_Custom3://,             //C3
        case LT.Utilities.RM_Panorama://,            //パノラマ
        case LT.Utilities.RM_Custom4://,             //C4
        default:
            break;
        }
    }

    function sceneGuideSceneSetting() {
        //console.log("sceneGuideSceneSetting start");
        switch(deviceAdapter.recordingMode) {
        case LT.Utilities.RM_SceneGuide://,          //シーンガイド
            btnOptionRecordingMode.optionSelect(deviceAdapter.sceneGuideScene)

            btnOptionRecordingMode.logScrTagID = LT.TagDef.RTScr_Usage_Main_SceneGuide;
            btnOptionRecordingMode.logFile = btnOptionRecordingMode.target;
            break;
        case LT.Utilities.RM_Unknown:// = -1,
        case LT.Utilities.RM_ProgramAE://,           //P
        case LT.Utilities.RM_AperturePriorityAE://,  //A
        case LT.Utilities.RM_ShutterPriorityAE://,   //S
        case LT.Utilities.RM_ManualExposure://,      //M
        case LT.Utilities.RM_CreativeControl://,     //クリエイティブコントロール
        case LT.Utilities.RM_CreativeVideo://,       //クリエイティブ動画
        case LT.Utilities.RM_IntelligentAuto://,     //iA
        case LT.Utilities.RM_Custom1://,             //C1
        case LT.Utilities.RM_Custom2://,             //C2
        case LT.Utilities.RM_Custom3://,             //C3
        case LT.Utilities.RM_Panorama://,            //パノラマ
        case LT.Utilities.RM_Custom4://,             //C4
        default:
            break;
        }
    }

    function driveModeSetting() {
        LTSubFunction.console_debug.out("driveModeSetting start mode:" + deviceAdapter.driveMode);

        btnOptionDriveMode.logCol = ltLog;
        btnOptionDriveMode.logScrTagID = LT.TagDef.RTScr_Usage_Main_DriveMode;
        btnOptionDriveMode.logFile = "driveMode";
        //動画画質の設定でエラーメッセージ表示中にDSC本体操作後、ポップアップメニュー消えた後にメッセージ閉じるとAP断となるので
        //ポップアップをクローズする段階でメッセージを消すようにしておく
        settingErrorDlg.visible = false

        driveModePopupClose()
        wbPopupCancelClose()
        ccPopupCancelClose()
        photoStylePopupForceClose()
        // IVC >> MC893 >> start >> No.1
        movieQualityPopupCancelClose()
        // IVC << MC893 << end << No.1

        switch(deviceAdapter.driveMode) {
        case LT.Utilities.DM_Unknown:// = -1,
            break;
        case LT.Utilities.DM_Single://,              //単写
            //console.log("LT.Utilities.DM_Single driveMode");
            btnOptionDriveMode.target = "driveMode"
            btnOptionDriveMode.optionSelect(LT.Utilities.DM_Single)
            btnOptionDriveMode.optionOpen = false
//            btnOptionDriveMode.disabled = false  // btnOptionDriveMode.optionSelect 内で設定
            break;
        case LT.Utilities.DM_Burst://,               //連写
            //console.log("LT.Utilities.DM_Burst driveMode");
            btnOptionDriveMode.target = "burstSpeed"
            btnOptionDriveMode.popupTitle = qsTr("Burst")
            btnOptionDriveMode.optionOpen = true
//            btnOptionDriveMode.disabled = false
            burstSpeedSetting()
            break;
        case LT.Utilities.DM_Burst1://,              //連写1
            //console.log("LT.Utilities.DM_Burst1 driveMode");
            btnOptionDriveMode.target = "burstSpeed1"
            btnOptionDriveMode.popupTitle = qsTr("Burst1")
            btnOptionDriveMode.optionOpen = true
//            btnOptionDriveMode.disabled = false
            burstSpeedSetting()
            break;
        case LT.Utilities.DM_Burst2://,              //連写2
            //console.log("LT.Utilities.DM_Burst2 driveMode");
            btnOptionDriveMode.target = "burstSpeed2"
            btnOptionDriveMode.popupTitle = qsTr("Burst")               // 連写２だが連写として表示
            btnOptionDriveMode.optionOpen = true
//            btnOptionDriveMode.disabled = false
            burstSpeedSetting()
            break;
        case LT.Utilities.DM_Bracket://,             //ブラケット
            //console.log("LT.Utilities.DM_Bracket driveMode");
            btnOptionDriveMode.target = "driveMode"
            btnOptionDriveMode.optionSelect(LT.Utilities.DM_Bracket)
            btnOptionDriveMode.optionOpen = false
//            btnOptionDriveMode.disabled = false
            break;
        case LT.Utilities.DM_SelfTimer://,           //セルフタイマー
            //console.log("LT.Utilities.DM_SelfTimer driveMode");
            btnOptionDriveMode.target = "selfTimer"
            btnOptionDriveMode.popupTitle = qsTr("SelfTimer")
            btnOptionDriveMode.optionOpen = true
//            btnOptionDriveMode.disabled = false
            selfTimerSetting()
            break;
        case LT.Utilities.DM_Interval://,           //インターバル
            //console.log("LT.Utilities.DM_Interval driveMode");
            btnOptionDriveMode.target = "driveMode"
            btnOptionDriveMode.optionSelect(LT.Utilities.DM_Interval)
            btnOptionDriveMode.optionOpen = false
//            btnOptionDriveMode.disabled = false
            break;
        case LT.Utilities.DM_Komadori://,           //コマ撮りアニメ
            //console.log("LT.Utilities.DM_Komadori driveMode");
            btnOptionDriveMode.target = "driveMode"
            btnOptionDriveMode.optionSelect(LT.Utilities.DM_Komadori)
            btnOptionDriveMode.optionOpen = true
//            btnOptionDriveMode.disabled = false
            break;
        case LT.Utilities.DM_4K6K://,                //6Kフォト・4Kフォト（連写 / 連写（S/S） / プリ連写） / フォーカスセレクト / セルフタイマー / インターバル・コマ撮りアニメ
            //console.log("LT.Utilities.DM_4K6K driveMode");
            btnOptionDriveMode.target = "picture4K6K"
            btnOptionDriveMode.popupTitle = qsTr("4K6K")
            btnOptionDriveMode.optionOpen = true
//            btnOptionDriveMode.disabled = false
            picture4K6KSetting()
            break;
        case LT.Utilities.DM_Focus://,               //フォーカスセレクト
            //console.log("LT.Utilities.DM_Focus driveMode");
            btnOptionDriveMode.target = "focusSelect"
            btnOptionDriveMode.popupTitle = qsTr("Focus")
            btnOptionDriveMode.optionOpen = true
//            btnOptionDriveMode.disabled = false
            focusSelectSetting()
            break;
        case LT.Utilities.DM_HRS://,                 //ハイレゾショット
            //console.log("LT.Utilities.DM_HRS driveMode");
            btnOptionDriveMode.target = "driveMode"
            btnOptionDriveMode.optionSelect(LT.Utilities.DM_HRS)
            btnOptionDriveMode.optionOpen = false
//            btnOptionDriveMode.disabled = false
            break;
        case LT.Utilities.DM_HANDHELD_HRS://,        //手持ちハイレゾショット
            //console.log("LT.Utilities.DM_HANDHELD_HRS driveMode");
            btnOptionDriveMode.target = "driveMode"
            btnOptionDriveMode.optionSelect(LT.Utilities.DM_HANDHELD_HRS)
            btnOptionDriveMode.optionOpen = false
//            btnOptionDriveMode.disabled = false
            break;
        default:
            break;
        }
        statusOfCardsSetting()
    }

    function picture4K6KSetting() {
        //console.log("picture4K6KSetting start" + deviceAdapter.picture4K6K);
        switch(deviceAdapter.driveMode) {
        case LT.Utilities.DM_4K6K://,                //6Kフォト・4Kフォト（連写 / 連写（S/S） / プリ連写） / フォーカスセレクト / セルフタイマー / インターバル・コマ撮りアニメ
            btnOptionDriveMode.optionSelect(deviceAdapter.picture4K6K)
            break;
        case LT.Utilities.DM_Unknown:// = -1,
        case LT.Utilities.DM_Single://,              //単写
        case LT.Utilities.DM_Burst://,               //連写
        case LT.Utilities.DM_Burst1://,              //連写1
        case LT.Utilities.DM_Burst2://,              //連写2
        case LT.Utilities.DM_Bracket://,             //ブラケット
        case LT.Utilities.DM_SelfTimer://,           //セルフタイマー
        case LT.Utilities.DM_Interval://,            //インターバル
        case LT.Utilities.DM_Komadori://,            //コマ撮り
        case LT.Utilities.DM_Focus://,               //フォーカスセレクト
        case LT.Utilities.DM_HRS://,                 //ハイレゾショット
        case LT.Utilities.DM_HANDHELD_HRS://,        //手持ちハイレゾショット
        default:
            break;
        }

        ltLog.log(LT.TagDef.RecLvl_Info,
                  LT.TagDef.RTScr_Usage_Main_Picture4K6K,
                  "picture4K6KSetting",
                  deviceAdapter.picture4K6K);
    }

    function burstSpeedSetting() {
        LTSubFunction.console_debug.out("burstSpeedSetting start " + deviceAdapter.burstSpeed);
        switch(deviceAdapter.driveMode) {
        case LT.Utilities.DM_Burst://,               //連写
        case LT.Utilities.DM_Burst1://,              //連写1
        case LT.Utilities.DM_Burst2://,              //連写2
            btnOptionDriveMode.optionSelect(deviceAdapter.burstSpeed)

            if (deviceAdapter.driveMode == LT.Utilities.DM_Burst) {
                btnOptionDriveMode.logScrTagID = LT.TagDef.RTScr_Usage_Main_BurstSpeed;
            } else if (deviceAdapter.driveMode == LT.Utilities.DM_Burst1) {
                btnOptionDriveMode.logScrTagID = LT.TagDef.RTScr_Usage_Main_BurstSpeed1;
            } else if (deviceAdapter.driveMode == LT.Utilities.DM_Burst2) {
                btnOptionDriveMode.logScrTagID = LT.TagDef.RTScr_Usage_Main_BurstSpeed2;
            }

            btnOptionDriveMode.logFile = btnOptionDriveMode.target;
            break;
        case LT.Utilities.DM_Unknown:// = -1,
        case LT.Utilities.DM_Single://,              //単写
        case LT.Utilities.DM_Bracket://,             //ブラケット
        case LT.Utilities.DM_SelfTimer://,           //セルフタイマー
        case LT.Utilities.DM_Interval://,            //インターバル
        case LT.Utilities.DM_Komadori://,            //コマ撮り
        case LT.Utilities.DM_4K6K://,                //6Kフォト・4Kフォト（連写 / 連写（S/S） / プリ連写） / フォーカスセレクト / セルフタイマー / インターバル・コマ撮りアニメ
        case LT.Utilities.DM_Focus://,               //フォーカスセレクト
        case LT.Utilities.DM_HRS://,                 //ハイレゾショット
        case LT.Utilities.DM_HANDHELD_HRS://,        //手持ちハイレゾショット
        default:
            break;
        }
    }

    function focusSelectSetting() {
        //console.log("focusSelectSetting start");
        switch(deviceAdapter.driveMode) {
        case LT.Utilities.DM_Focus://,               //フォーカスセレクト
            btnOptionDriveMode.optionSelect(deviceAdapter.focusSelect)

            btnOptionDriveMode.logScrTagID = LT.TagDef.RTScr_Usage_Main_FocusSelect;
            btnOptionDriveMode.logFile = btnOptionDriveMode.target;
            break;
        case LT.Utilities.DM_Unknown:// = -1,
        case LT.Utilities.DM_Single://,              //単写
        case LT.Utilities.DM_Burst://,               //連写
        case LT.Utilities.DM_Burst1://,              //連写1
        case LT.Utilities.DM_Burst2://,              //連写2
        case LT.Utilities.DM_Bracket://,             //ブラケット
        case LT.Utilities.DM_SelfTimer://,           //セルフタイマー
        case LT.Utilities.DM_Interval://,            //インターバル
        case LT.Utilities.DM_Komadori://,            //コマ撮り
        case LT.Utilities.DM_4K6K://,                //6Kフォト・4Kフォト（連写 / 連写（S/S） / プリ連写） / フォーカスセレクト / セルフタイマー / インターバル・コマ撮りアニメ
        case LT.Utilities.DM_HRS://,                 //ハイレゾショット
        case LT.Utilities.DM_HANDHELD_HRS://,        //手持ちハイレゾショット
        default:
            break;
        }
    }

    function selfTimerSetting() {
        //console.log("selfTimerSetting start = " + deviceAdapter.driveMode);
        switch(deviceAdapter.driveMode) {
        case LT.Utilities.DM_SelfTimer://,           //セルフタイマー
            btnOptionDriveMode.optionSelect(deviceAdapter.selfTimer)

            btnOptionDriveMode.logScrTagID = LT.TagDef.RTScr_Usage_Main_DriveMode;
            btnOptionDriveMode.logFile = btnOptionDriveMode.target;
            break;
        case LT.Utilities.DM_Unknown:// = -1,
        case LT.Utilities.DM_Single://,              //単写
        case LT.Utilities.DM_Burst://,               //連写
        case LT.Utilities.DM_Burst1://,              //連写1
        case LT.Utilities.DM_Burst2://,              //連写2
        case LT.Utilities.DM_Bracket://,             //ブラケット
        case LT.Utilities.DM_Interval://,            //インターバル
        case LT.Utilities.DM_Komadori://,            //コマ撮り
        case LT.Utilities.DM_4K6K://,                //6Kフォト・4Kフォト（連写 / 連写（S/S） / プリ連写） / フォーカスセレクト / セルフタイマー / インターバル・コマ撮りアニメ
        case LT.Utilities.DM_Focus://,               //フォーカスセレクト
        case LT.Utilities.DM_HRS://,                 //ハイレゾショット
        case LT.Utilities.DM_HANDHELD_HRS://,        //手持ちハイレゾショット
        default:
            break;
        }
    }

    function batteryLevelSetting() {
        if(deviceAdapter.batteryLevel == LT.DeviceAdapter.BL_Full) {
            batteryImage.source = "qrc:/images/7_battery_3.svg";
        } else if(deviceAdapter.batteryLevel < LT.DeviceAdapter.BL_Full && deviceAdapter.batteryLevel > LT.DeviceAdapter.BL_Empty) {
            batteryImage.source = "qrc:/images/10_battery_0_gray.svg"
        } else if(deviceAdapter.batteryLevel <= LT.DeviceAdapter.BL_Empty && deviceAdapter.batteryLevel >= 0) {
            batteryImage.source = "qrc:/images/10_battery_0.svg";
        } else if(deviceAdapter.batteryLevel == LT.DeviceAdapter.BL_Ac) {
            batteryImage.source = "qrc:/images/11_battery_chaege.svg";
        } else {
            batteryImage.source = "";
        }
        canvas.requestPaint();

        ltLog.log(LT.TagDef.RecLvl_Info,
                  LT.TagDef.RTScr_Usage_Main_BatteryLevel,
                  "batteryLevelSetting",
                  deviceAdapter.batteryLevel);
    }

    function imageFreeSpaceSetting() {
        LTSubFunction.console_debug.out("imageFreeSpaceSetting start = " + deviceAdapter.imageFreeSpace);
//        var num = 0;
        //USBTHRV100-431
        //お手数ですが残量表示をドライブモードにかかわらず
        //imageFreeSpace/secondFreeSpaceを参照するように変更を
        //お願いいたします。
        //if(deviceAdapter.driveMode == LT.Utilities.DM_4K6K) {
        //    num = deviceAdapter.image4KFreeSpace
        //
        //    ltLog.log(LT.TagDef.RecLvl_Info,
        //              LT.TagDef.RTScr_Usage_Main_Image4KFreeSpace,
        //              "imageFreeSpaceSetting",
        //              deviceAdapter.image4KFreeSpace);
        //} else {
//            num = deviceAdapter.imageFreeSpace

            ltLog.log(LT.TagDef.RecLvl_Info,
                      LT.TagDef.RTScr_Usage_Main_ImageFreeSpace,
                      "imageFreeSpaceSetting",
                      deviceAdapter.imageFreeSpace);
        //}
        switch(deviceAdapter.statusOfCards) {
        case LT.DeviceAdapter.STOC_Normal://,
            // Check undefined value 0xFFFFFFFF
            if(deviceAdapter.imageFreeSpace == 0xFFFFFFFF) {
//                LTSubFunction.console_debug.out("imageFreeSpaceSetting undef");
                pictureAvailableText.text = "-----"
            } else if(deviceAdapter.imageFreeSpace >= 10000) {
//                LTSubFunction.console_debug.out("imageFreeSpaceSetting 10000");
                pictureAvailableText.text = "9999+"
            } else {
//                LTSubFunction.console_debug.out("imageFreeSpaceSetting else");
                pictureAvailableText.text = deviceAdapter.imageFreeSpace.toString()
            }
            break;
        case LT.DeviceAdapter.STOC_Nocard://,
        case LT.DeviceAdapter.STOC_Protected://,
        case LT.DeviceAdapter.STOC_Error://,
        case LT.DeviceAdapter.STOC_Undef://=-1,
        case LT.DeviceAdapter.STOC_Max://,
        default:
            pictureAvailableText.text = "-----"
            break;
        };
    }

    function secondFreeSpaceSetting() {
        LTSubFunction.console_debug.out("secondFreeSpaceSetting start = " + deviceAdapter.secondFreeSpace);
        switch(deviceAdapter.statusOfCards) {
        case LT.DeviceAdapter.STOC_Normal://,
            break;
        case LT.DeviceAdapter.STOC_Nocard://,
        case LT.DeviceAdapter.STOC_Protected://,
        case LT.DeviceAdapter.STOC_Error://,
        case LT.DeviceAdapter.STOC_Undef://=-1,
        case LT.DeviceAdapter.STOC_Max://,
        default:
            movieAvailableText.text = "-----"
            return;
        };
        var hour = 0//parseInt(deviceAdapter.secondFreeSpace / (3600))
        var min = 0//parseInt(deviceAdapter.secondFreeSpace / (60))
        var sec = 0//deviceAdapter.secondFreeSpace % 60
        //USBTHRV100-431
        //お手数ですが残量表示をドライブモードにかかわらず
        //imageFreeSpace/secondFreeSpaceを参照するように変更を
        //お願いいたします。
        //if(deviceAdapter.driveMode == LT.Utilities.DM_4K6K) {
        //    if(deviceAdapter.second4KFreeSpace == -1) {
        //        movieAvailableText.text = "-----"
        //        return
        //    }
        //    hour = parseInt(deviceAdapter.second4KFreeSpace / (3600))
        //    min = parseInt((deviceAdapter.second4KFreeSpace % 3600) / (60))
        //    sec = deviceAdapter.second4KFreeSpace % 60
        //
        //    ltLog.log(LT.TagDef.RecLvl_Info,
        //              LT.TagDef.RTScr_Usage_Main_Second4KFreeSpace,
        //              "second4KFreeSpaceSetting",
        //              deviceAdapter.second4KFreeSpace);
        //} else {
            // Check undefined value 0xFFFFFFFF
            if(deviceAdapter.secondFreeSpace == 0xFFFFFFFF) {
                LTSubFunction.console_debug.out("secondFreeSpaceSetting undef")
                movieAvailableText.text = "-----"

                //Fix tooltip display (USBTHRV 110 - 86)
//                movieRecButton.toolTipText = qsTr("sd_error_message_4")
//                if(deviceAdapter.driveMode == LT.Utilities.DM_4K6K) {
//                    shutterButton.toolTipText = qsTr("sd_error_message_4")
//                }
                return
            }
            hour = parseInt(deviceAdapter.secondFreeSpace / (3600))
            min = parseInt((deviceAdapter.secondFreeSpace % 3600) / (60))
            sec = deviceAdapter.secondFreeSpace % 60

            ltLog.log(LT.TagDef.RecLvl_Info,
                      LT.TagDef.RTScr_Usage_Main_SecondFreeSpace,
                      "secondFreeSpaceSetting",
                      deviceAdapter.secondFreeSpace);
        //}

        // 残時間が０の場合
        //USBTHRV 110 - 77 start
        // Keep shutter and record button enable (only change tooltip)
        if(hour == 0 && min == 0 && sec == 0) {
            // ボタンがエラーでない場合（ボタンがすでにエラーだったら他のエラーのはず）
//            if(movieRecButton.error == false) {
//                movieRecButton.error = true
                movieRecButton.toolTipText = qsTr("sd_error_message_4")
//            }
            if(deviceAdapter.driveMode == LT.Utilities.DM_4K6K) {
//                if(shutterButton.error == false) {
//                    shutterButton.error = true
                    shutterButton.toolTipText = qsTr("sd_error_message_4")
//                }
            }
        // 残時間が０以外の場合
        } else {            
            // ボタンがエラーの場合（ツールチップが残時間０の場合は元に戻す。それ以外は他のエラーのはず）
//            if(movieRecButton.error == true) {
                if(movieRecButton.toolTipText == qsTr("sd_error_message_4")) {
//                    movieRecButton.error = false
                    movieRecButton.toolTipText = ""
                }
//            }
//            if(deviceAdapter.driveMode == LT.Utilities.DM_4K6K) {
//                if(shutterButton.error == true) {
                    if(shutterButton.toolTipText == qsTr("sd_error_message_4")) {
//                        shutterButton.error = false
                        shutterButton.toolTipText = ""
                    }
//                }
//            }
        }
        //USBTHRV 110 - 77 end

        if(hour > 0) {
            if(hour < 10) {
                if(min < 10) {
                    movieAvailableText.text = "0" + hour.toString() + "h0" + min.toString() + "m"
                } else {
                    movieAvailableText.text = "0" + hour.toString() + "h" + min.toString() + "m"
                }
            } else if(hour >= 100) {
                movieAvailableText.text = "99h59m"
            } else {
                if(min < 10) {
                    movieAvailableText.text = hour.toString() + "h0" + min.toString() + "m"
                } else {
                    movieAvailableText.text = hour.toString() + "h" + min.toString() + "m"
                }
            }
        } else {
            if(min < 10) {
                if(sec < 10) {
                    movieAvailableText.text = "0" + min.toString() + "m0" + sec.toString() + "s"
                } else {
                    movieAvailableText.text = "0" + min.toString() + "m" + sec.toString() + "s"
                }
            } else {
                if(sec < 10) {
                    movieAvailableText.text = min.toString() + "m0" + sec.toString() + "s"
                } else {
                    movieAvailableText.text = min.toString() + "m" + sec.toString() + "s"
                }
            }
        }
    }

    function statusOfCardsSetting() {
        var noEnableChange = true
        LTSubFunction.console_debug.out("statusOfCardsSetting start = " + deviceAdapter.statusOfCards);
        switch(deviceAdapter.statusOfCards) {
        case LT.DeviceAdapter.STOC_Nocard://,
            //動画ボタン無効
            if(deviceAdapter.driveMode == LT.Utilities.DM_4K6K) {
                //撮影ボタン無効
                shutterButton.error = true
                shutterButton.toolTipText = qsTr("sd_error_message_1")
            } else {
                //撮影ボタン有効
                shutterButton.error = false
            }
            break;
        case LT.DeviceAdapter.STOC_Protected://,
            //動画ボタン無効
            if(deviceAdapter.driveMode == LT.Utilities.DM_4K6K) {
                //撮影ボタン無効
                shutterButton.error = true
                shutterButton.toolTipText = qsTr("sd_error_message_2")
            } else {
                //撮影ボタン有効
                shutterButton.error = false
            }
            break;
        case LT.DeviceAdapter.STOC_Error://,
            //動画ボタン無効
            if(deviceAdapter.driveMode == LT.Utilities.DM_4K6K) {
                //撮影ボタン無効
                shutterButton.error = true
                shutterButton.toolTipText = qsTr("sd_error_message_3")
            } else {
                //撮影ボタン有効
                shutterButton.error = false
            }
            break;
        case LT.DeviceAdapter.STOC_Normal://,
        case LT.DeviceAdapter.STOC_Undef://=-1,
        case LT.DeviceAdapter.STOC_Max://,
        default:
            //動画ボタン有効
            // IVC >> Ver.1.9 >> start >> [THRBOXV100-168][THRBOXV100-195]
            if((root.movieRecStartFlg) &&
               (deviceAdapter.cameraStatus !== LT.Utilities.CamStatus_MovRec_4k &&
                deviceAdapter.cameraStatus !== LT.Utilities.CamStatus_LiveStreamingRemoteRec &&
                deviceAdapter.cameraStatus !== LT.Utilities.CamStatus_MovRemoteRec &&
                deviceAdapter.cameraStatus !== LT.Utilities.CamStatus_RemoteRec &&
                deviceAdapter.cameraStatus !== LT.Utilities.CamStatus_RemoteRecRawHDMI
                )){
                root.movieRecStartFlg = false;
                root.recStop()
                movieRecButton.enabled = true
                noEnableChange = false
                if(deviceAdapter.fileTarget === LT.Utilities.FLTG_CameraOnly ||
                   deviceAdapter.hdmiSdiStatus === LT.Utilities.HDMI_SDI_Status_HDMI_ON ||
                   deviceAdapter.hdmiSdiStatus === LT.Utilities.HDMI_SDI_Status_SDI_ON ||
                   deviceAdapter.hdmiSdiStatus === LT.Utilities.HDMI_SDI_Status_HDMI_SDI_ON)
                {
                    //PCにコピーしないならTetherModeを変更できるようにする
                    //HDMI/SDIがONの時も変更できるようにする
                    var uuid = deviceAdapter.camera_list_get_selected_camera_uuid()
                    deviceAdapter.camera_list_set_camera_tether_mode_status(uuid, LT.Utilities.TETHERMODE_Copy, false)
                    tetherModeUpdate()
                }
            }else if(root.movieRecStartFlg == false && isCopying == false){
                //コピー中じゃなければ更新
                noEnableChange = false
            }

            // IVC << Ver.1.9 << end << [THRBOXV100-168][THRBOXV100-195]
            //撮影ボタン有効
            shutterButton.error = false
            shutterButton.toolTipText = ""
            break;
        };
        updateMovieRecButtonViewStatus(noEnableChange, true)

        ltLog.log(LT.TagDef.RecLvl_Info,
                  LT.TagDef.RTScr_Usage_Main_CardStatus,
                  "statusOfCardsSetting",
                  deviceAdapter.statusOfCards);

        root.imageFreeSpaceSetting();
        root.secondFreeSpaceSetting();
    }

    function apertureSetting() {
        //console.log("apertureSetting start");

        btnOptionAperture.logCol = ltLog;
        btnOptionAperture.logScrTagID = LT.TagDef.RTScr_Usage_Main_Aperture;
        btnOptionAperture.logFile = btnOptionAperture.target;

        btnOptionAperture.optionSelect(deviceAdapter.aperture);
    }

    function shutterSpdSetting() {
        //console.log("shutterSpdSetting start = " + deviceAdapter.shutterSpeed);

        btnOptionShutterSpd.logCol = ltLog;
        btnOptionShutterSpd.logScrTagID = LT.TagDef.RTScr_Usage_Main_ShutterSpeed;
        btnOptionShutterSpd.logFile = btnOptionShutterSpd.target;

// IVC >> Ver.1.9 >> start >> No.6
        if(deviceAdapter.ssGain == LT.Utilities.SSGain_Sec_n_ISO) {
            btnOptionShutterSpd.target = "shutterSpeed" // Second
            btnOptionShutterSpd.type = "optionWithStyledSelectedText"
            btnOptionShutterSpd.optionSelect(deviceAdapter.shutterSpeed);
        }
        else if(deviceAdapter.ssGain == LT.Utilities.SSGain_Angle_n_ISO) {
            btnOptionShutterSpd.target = "shutterSpeedAngle" // Angle
            btnOptionShutterSpd.type = "optionWithStyledTextReal"
            btnOptionShutterSpd.optionSelect(deviceAdapter.shutterSpeedAngle);
        }
        else if(deviceAdapter.ssGain == LT.Utilities.SSGain_Sec_n_dB) {
            btnOptionShutterSpd.target = "shutterSpeed" // Second
            btnOptionShutterSpd.type = "optionWithStyledSelectedText"
            btnOptionShutterSpd.optionSelect(deviceAdapter.shutterSpeed);
        }
        else {
            btnOptionShutterSpd.target = "shutterSpeed"
            btnOptionShutterSpd.type = "optionWithStyledSelectedText"
            btnOptionShutterSpd.optionSelect(deviceAdapter.shutterSpeed);
        }
// IVC << Ver.1.9 << end << No.6
    }

    function whiteBalanceSetting() {
        //console.log("whiteBalanceSetting start =" + deviceAdapter.whiteBalance);

        btnOptionWhiteBalance.logCol = ltLog;
        btnOptionWhiteBalance.logScrTagID = LT.TagDef.RTScr_Usage_Main_WhiteBalance;
        btnOptionWhiteBalance.logFile = btnOptionWhiteBalance.target;

        btnOptionWhiteBalance.optionSelect(deviceAdapter.whiteBalance);
    }

    function isoSetting() {
        //console.log("isoSetting start iso="+deviceAdapter.iso);

        btnOptionIso.logCol = ltLog;
        btnOptionIso.logScrTagID = LT.TagDef.RTScr_Usage_Main_ISO;
        btnOptionIso.logFile = btnOptionIso.target;

        // IVC >> Ver.1.9 >> start >> No.6
        if(deviceAdapter.ssGain == LT.Utilities.SSGain_Sec_n_dB)
        {
            btnOptionIso.target = "isoGain" // dB
            btnOptionIso.optionSelect(deviceAdapter.isoGain);
        }
        else {
            btnOptionIso.target = "iso" // ISO
            btnOptionIso.optionSelect(deviceAdapter.iso);
        }
        // IVC << Ver.1.9 << end << No.6
    }

    function isoAutoSetting() {
        //console.log("isoAutoSetting start iso="+deviceAdapter.isoAuto);

        btnOptionIso.logCol = ltLog;
        btnOptionIso.logScrTagID = LT.TagDef.RTScr_Usage_Main_ISO;
        btnOptionIso.logFile = btnOptionIso.target;

        if((deviceAdapter.isoAuto == 0xFFFFFFFD) || (deviceAdapter.isoAuto == -3)) {
            // IVC >> Ver.1.9 >> start >> No.6
            if(deviceAdapter.ssGain == LT.Utilities.SSGain_Sec_n_dB)
            {
                btnOptionIso.target = "isoGain" // dB
                btnOptionIso.optionSelect(deviceAdapter.isoGain);
            }
            else {
                btnOptionIso.target = "iso" // ISO
                btnOptionIso.optionSelect(deviceAdapter.iso);
            }
            // IVC << Ver.1.9 << end << No.6
        } else {
            btnOptionIso.target = "isoAuto"
            btnOptionIso.optionSelect(deviceAdapter.isoAuto);
        }
    }

    function exposureSetting() {
        //console.log("exposureSetting start =", deviceAdapter.exposureVal);

        sliderExposure.curIndex = deviceAdapter.exposureVal
    }

    function exposureMaxSetting() {
        //console.log("exposureMaxSetting start =", deviceAdapter.exposureRangeMax);

        sliderExposure.maxRange = deviceAdapter.exposureRangeMax;
    }

    function exposureMinSetting() {
        //console.log("exposureMinSetting start =", deviceAdapter.exposureRangeMin);

        sliderExposure.minRange = deviceAdapter.exposureRangeMin;
    }

    function motionPictureFormatSetting() {
        //console.log("motionPictureFormatSetting start");
        //console.log("motionPictureFormatSetting motionPictureFormat=" + deviceAdapter.motionPictureFormat);
        //console.log("motionPictureFormatSetting systemFrequency=" + deviceAdapter.systemFrequency);
        // 動画画質設定
        //// AVCHD_NTSC
        //if( (deviceAdapter.motionPictureFormat == LT.Utilities.MPF_AVCHD) &&
        //        (deviceAdapter.systemFrequency == LT.Utilities.SFQ_NTSC) ) {
        //    //console.log("AVCHD_NTSC");
        //    movieConfigQualityButton.target = "recMovie_AVCHD_NTSC"
        //    movieConfigQualityButton.optionSelect(deviceAdapter.recMovie_AVCHD_NTSC)
        //}
        //// AVCHD_PAL
        //else if( (deviceAdapter.motionPictureFormat == LT.Utilities.MPF_AVCHD) &&
        //        (deviceAdapter.systemFrequency == LT.Utilities.SFQ_PAL) ) {
        //    //console.log("AVCHD_PAL");
        //    movieConfigQualityButton.target = "recMovie_AVCHD_PAL"
        //    movieConfigQualityButton.optionSelect(deviceAdapter.recMovie_AVCHD_PAL)
        //}
        //// MP4_NTSC
        //else if( (deviceAdapter.motionPictureFormat == LT.Utilities.MPF_MP4) &&
        //        (deviceAdapter.systemFrequency == LT.Utilities.SFQ_NTSC) ) {
        //    //console.log("MP4_NTSC");
        //    movieConfigQualityButton.target = "recMovie_MP4_NTSC"
        //    movieConfigQualityButton.optionSelect(deviceAdapter.recMovie_MP4_NTSC)
        //}
        //// MP4_PAL
        //else if( (deviceAdapter.motionPictureFormat == LT.Utilities.MPF_MP4) &&
        //        (deviceAdapter.systemFrequency == LT.Utilities.SFQ_PAL) ) {
        //    //console.log("MP4_PAL");
        //    movieConfigQualityButton.target = "recMovie_MP4_PAL"
        //    movieConfigQualityButton.optionSelect(deviceAdapter.recMovie_MP4_PAL)
        //}
        //// MP4_CINEMA
        //else if( (deviceAdapter.motionPictureFormat == LT.Utilities.MPF_MP4) &&
        //        (deviceAdapter.systemFrequency == LT.Utilities.SFQ_CINEMA) ) {
        //    //console.log("MP4_CINEMA");
        //    movieConfigQualityButton.target = "recMovie_MP4_CINEMA"
        //    movieConfigQualityButton.optionSelect(deviceAdapter.recMovie_MP4_CINEMA)
        //}
        //// MP4_LPCM_NTSC
        //else if( (deviceAdapter.motionPictureFormat == LT.Utilities.MPF_MP4WithLPCM) &&
        //        (deviceAdapter.systemFrequency == LT.Utilities.SFQ_NTSC) ) {
        //    //console.log("MP4_LPCM_NTSC");
        //    movieConfigQualityButton.target = "recMovie_MP4_LPCM_NTSC"
        //    movieConfigQualityButton.optionSelect(deviceAdapter.recMovie_MP4_LPCM_NTSC)
        //}
        //// MP4_LPCM_PAL
        //else if( (deviceAdapter.motionPictureFormat == LT.Utilities.MPF_MP4WithLPCM) &&
        //        (deviceAdapter.systemFrequency == LT.Utilities.SFQ_PAL) ) {
        //    //console.log("MP4_LPCM_PAL");
        //    movieConfigQualityButton.target = "recMovie_MP4_LPCM_PAL"
        //    movieConfigQualityButton.optionSelect(deviceAdapter.recMovie_MP4_LPCM_PAL)
        //}
        //// MP4_LPCM_CINEMA
        //else if( (deviceAdapter.motionPictureFormat == LT.Utilities.MPF_MP4WithLPCM) &&
        //        (deviceAdapter.systemFrequency == LT.Utilities.SFQ_CINEMA) ) {
        //    //console.log("MP4_LPCM_CINEMA");
        //    movieConfigQualityButton.target = "recMovie_MP4_LPCM_CINEMA"
        //    movieConfigQualityButton.optionSelect(deviceAdapter.recMovie_MP4_LPCM_CINEMA)
        //}
        //// MOV_NTSC
        //else if( (deviceAdapter.motionPictureFormat == LT.Utilities.MPF_MOV) &&
        //        (deviceAdapter.systemFrequency == LT.Utilities.SFQ_NTSC) ) {
        //    //console.log("MOV_NTSC");
        //    movieConfigQualityButton.target = "recMovie_MOV_NTSC"
        //    movieConfigQualityButton.optionSelect(deviceAdapter.recMovie_MOV_NTSC)
        //}
        //// MOV_PAL
        //else if( (deviceAdapter.motionPictureFormat == LT.Utilities.MPF_MOV) &&
        //        (deviceAdapter.systemFrequency == LT.Utilities.SFQ_PAL) ) {
        //    //console.log("MOV_PAL");
        //    movieConfigQualityButton.target = "recMovie_MOV_PAL"
        //    movieConfigQualityButton.optionSelect(deviceAdapter.recMovie_MOV_PAL)
        //}
        //// MOV_CINEMA
        //else if( (deviceAdapter.motionPictureFormat == LT.Utilities.MPF_MOV) &&
        //        (deviceAdapter.systemFrequency == LT.Utilities.SFQ_CINEMA) ) {
        //    //console.log("MOV_CINEMA");
        //    movieConfigQualityButton.target = "recMovie_MOV_CINEMA"
        //    movieConfigQualityButton.optionSelect(deviceAdapter.recMovie_MOV_CINEMA)
        //}
        //// MP4_HEVC_NTSC
        //else if( (deviceAdapter.motionPictureFormat == LT.Utilities.MPF_MP4WithHEVC) &&
        //        (deviceAdapter.systemFrequency == LT.Utilities.SFQ_NTSC) ) {
        //    //console.log("MP4_HEVC_NTSC="+deviceAdapter.recMovie_MP4_HEVC_NTSC);
        //    movieConfigQualityButton.target = "recMovie_MP4_HEVC_NTSC"
        //    movieConfigQualityButton.optionSelect(deviceAdapter.recMovie_MP4_HEVC_NTSC)
        //}
        //// MP4_HEVC_PAL
        //else if( (deviceAdapter.motionPictureFormat == LT.Utilities.MPF_MP4WithHEVC) &&
        //        (deviceAdapter.systemFrequency == LT.Utilities.SFQ_PAL) ) {
        //    //console.log("MP4_HEVC_PAL="+deviceAdapter.recMovie_MP4_HEVC_PAL);
        //    movieConfigQualityButton.target = "recMovie_MP4_HEVC_PAL"
        //    movieConfigQualityButton.optionSelect(deviceAdapter.recMovie_MP4_HEVC_PAL)
        //}
        movieConfigQualityButton.optionSelect(deviceAdapter.recMovie)

        movieConfigQualityButton.logCol = ltLog;
        movieConfigQualityButton.logScrTagID = LT.TagDef.RTScr_Usage_Main_MotionPictureQuality;
        movieConfigQualityButton.logFile = movieConfigQualityButton.target;
    }

// IVC >> add >> start >> USBTHRV160-26
    function recMovieQualityDetaiSetting() {
// IVC >> del >> start >> USBTHRV170-32
        //var displayMovQuality = deviceAdapter.adp_LMX_func_api_Mov_Config_Get_Quality_Detail_Display()
// IVC << del << end << USBTHRV170-32
        var result = deviceAdapter.validDisplayMovQuality()
        if(result !== LT.DeviceAdapter.Ternary_True){
            deviceAdapter.updateDisplayMovQuality()
        }
        result = deviceAdapter.validDisplayMovQuality()
        if (result === LT.DeviceAdapter.Ternary_True) {
            // Get Video Quality Detail List
            deviceAdapter.adp_LMX_func_api_Mov_Config_Get_Quality_Detail_List()
        } else {
            // Get Video Quality Detail List Built-In Data
            deviceAdapter.adp_LMX_Mov_Config_Get_Quality_Detail_List_From_Built_In_Data()
        }

        // 動画画質ボタン更新
        motionPictureFormatSetting()
    }
// IVC << add << end << USBTHRV160-26

    function aspectRatioSetting() {
        //console.log("aspectRatioSetting start pictureSize="+deviceAdapter.pictureSize);
        //// 4by3_ExOff
        //if( (deviceAdapter.aspectRatio == LT.DeviceAdapter.AR_Nomal_4_3) &&
        //    (deviceAdapter.exTelecon == LT.Utilities.EXT_ZoomOff) ) {
        //    console.log("4by3_ExOff");
        //    pictureSizeButton.target = "pictureSize4by3";
        //    pictureSizeButton.optionSelect(deviceAdapter.pictureSize4by3);
        //}
        //// 4by3_ExOn
        //else if( (deviceAdapter.aspectRatio == LT.DeviceAdapter.AR_Nomal_4_3) &&
        //         ( (deviceAdapter.exTelecon == LT.Utilities.EXT_ZoomOn) ||
        //           (deviceAdapter.exTelecon == LT.Utilities.EXT_Converter) ) ) {
        //    console.log("4by3_ExOn");
        //    pictureSizeButton.target = "pictureSize4by3Ex";
        //    pictureSizeButton.optionSelect(deviceAdapter.pictureSize4by3Ex);
        //}
        //// 3by2_ExOff
        //if( (deviceAdapter.aspectRatio == LT.DeviceAdapter.AR_Film_3_2) &&
        //    (deviceAdapter.exTelecon == LT.Utilities.EXT_ZoomOff) ) {
        //    console.log("3by2_ExOff");
        //    pictureSizeButton.target = "pictureSize3by2";
        //    pictureSizeButton.optionSelect(deviceAdapter.pictureSize3by2);
        //}
        //// 3by2_ExOn
        //else if( (deviceAdapter.aspectRatio == LT.DeviceAdapter.AR_Film_3_2) &&
        //         ( (deviceAdapter.exTelecon == LT.Utilities.EXT_ZoomOn) ||
        //           (deviceAdapter.exTelecon == LT.Utilities.EXT_Converter) ) ) {
        //    console.log("3by2_ExOn");
        //    pictureSizeButton.target = "pictureSize3by2Ex";
        //    pictureSizeButton.optionSelect(deviceAdapter.pictureSize3by2Ex);
        //}
        //// 16by9_ExOff
        //if( (deviceAdapter.aspectRatio == LT.DeviceAdapter.AR_Hdtv_16_9) &&
        //    (deviceAdapter.exTelecon == LT.Utilities.EXT_ZoomOff) ) {
        //    console.log("16by9_ExOff");
        //    pictureSizeButton.target = "pictureSize16by9";
        //    pictureSizeButton.optionSelect(deviceAdapter.pictureSize16by9);
        //}
        //// 16by9_ExOn
        //else if( (deviceAdapter.aspectRatio == LT.DeviceAdapter.AR_Hdtv_16_9) &&
        //         ( (deviceAdapter.exTelecon == LT.Utilities.EXT_ZoomOn) ||
        //           (deviceAdapter.exTelecon == LT.Utilities.EXT_Converter) ) ) {
        //    console.log("16by9_ExOn");
        //    pictureSizeButton.target = "pictureSize16by9Ex";
        //    pictureSizeButton.optionSelect(deviceAdapter.pictureSize16by9Ex);
        //}
        //// 1by1_ExOff
        //if( (deviceAdapter.aspectRatio == LT.DeviceAdapter.AR_Blog_1_1) &&
        //    (deviceAdapter.exTelecon == LT.Utilities.EXT_ZoomOff) ) {
        //    console.log("1by1_ExOff");
        //    pictureSizeButton.target = "pictureSize1by1";
        //    pictureSizeButton.optionSelect(deviceAdapter.pictureSize1by1);
        //}
        //// 1by1_ExOn
        //else if( (deviceAdapter.aspectRatio == LT.DeviceAdapter.AR_Blog_1_1) &&
        //         ( (deviceAdapter.exTelecon == LT.Utilities.EXT_ZoomOn) ||
        //           (deviceAdapter.exTelecon == LT.Utilities.EXT_Converter) ) ) {
        //    console.log("1by1_ExOn");
        //    pictureSizeButton.target = "pictureSize1by1Ex";
        //    pictureSizeButton.optionSelect(deviceAdapter.pictureSize1by1Ex);
        //}
        pictureSizeButton.optionSelect(deviceAdapter.pictureSize);

        pictureSizeButton.logCol = ltLog;
        pictureSizeButton.logScrTagID = LT.TagDef.RTScr_Usage_Main_PictureSize;
        pictureSizeButton.logFile = pictureSizeButton.target;
    }

    // ivc >> MC893 [No 2] >> start
    function notifyObjectAdd(arg) {
        if (checkLastMovieTimer.isWaiting) {
            // disable REC button
            movieRecButton.enabled = false;
            isCopying = true;
            // count files
            currentAddedFileCount += 1;
            // restart timer
            checkLastMovieTimer.restart();
        }
    }
    // ivc << MC893 [No 2] << end

    // IVC >> Ver.1.9 >> start >> No.1
    function connectCameraSetting() {
        if(deviceAdapter.camConnectStatus == LT.Utilities.CamConnectSts_Connecting) {
            // show Panel Mask
            if (!maskpanel.visible) {
                maskpanel.visible = true;

                //動画画質の設定でエラーメッセージ表示中にDSC本体操作後、ポップアップメニュー消えた後にメッセージ閉じるとAP断となるので
                //ポップアップをクローズする段階でメッセージを消すようにしておく
                settingErrorDlg.visible = false

                wbPopupCancelClose();
                ccPopupCancelClose();
                photoStylePopupForceClose();
                movieQualityPopupCancelClose();
            }
        }
        else if(deviceAdapter.camConnectStatus == LT.Utilities.CamConnectSts_Unknown ||
                deviceAdapter.camConnectStatus == LT.Utilities.CamConnectSts_Success ||
                deviceAdapter.camConnectStatus == LT.Utilities.CamConnectSts_SuccessBackground
                ) {
            // hide Panel Mask
            if (maskpanel.visible) {
                maskpanel.visible = false;
            }
        }
    }
    // IVC << Ver.1.9 << end << No.1
    // IVC >> Ver.1.9 >> start >> No.6
    function ssGainSetting() {
        btnOptionShutterSpd.logCol = ltLog;
        btnOptionShutterSpd.logScrTagID = LT.TagDef.RTScr_Usage_Main_ShutterSpeed;
        btnOptionShutterSpd.logFile = btnOptionShutterSpd.target;

        btnOptionIso.logCol = ltLog;
        btnOptionIso.logScrTagID = LT.TagDef.RTScr_Usage_Main_ISO;
        btnOptionIso.logFile = btnOptionIso.target;

        if(deviceAdapter.ssGain == LT.Utilities.SSGain_Sec_n_ISO) {
            btnOptionShutterSpd.target = "shutterSpeed" // Second
            btnOptionShutterSpd.type = "optionWithStyledSelectedText"
            btnOptionIso.target = "iso" // ISO
            btnOptionIso.optionSelect(deviceAdapter.iso);
            btnOptionShutterSpd.optionSelect(deviceAdapter.shutterSpeed);
        }
        else if(deviceAdapter.ssGain == LT.Utilities.SSGain_Angle_n_ISO) {
            btnOptionShutterSpd.target = "shutterSpeedAngle" // Angle
            btnOptionShutterSpd.type = "optionWithStyledTextReal"
            btnOptionIso.target = "iso" // ISO
            btnOptionIso.optionSelect(deviceAdapter.iso);
            btnOptionShutterSpd.optionSelect(deviceAdapter.shutterSpeedAngle);
        }
        else if(deviceAdapter.ssGain == LT.Utilities.SSGain_Sec_n_dB) {
            btnOptionShutterSpd.target = "shutterSpeed" // Second
            btnOptionShutterSpd.type = "optionWithStyledSelectedText"
            btnOptionIso.target = "isoGain" // dB
            btnOptionIso.optionSelect(deviceAdapter.isoGain);
            btnOptionShutterSpd.optionSelect(deviceAdapter.shutterSpeed);
        }
        else {
            btnOptionShutterSpd.target = "shutterSpeed"
            btnOptionShutterSpd.type = "optionWithStyledSelectedText"
            btnOptionIso.target = "iso"
            btnOptionIso.optionSelect(deviceAdapter.iso);
            btnOptionShutterSpd.optionSelect(deviceAdapter.shutterSpeed);
        }
    }
    // IVC << Ver.1.9 << end << No.6

    function confirmMovie(arg) {
        //console.log("confirmMovie start");
        //console.log("    arg = " + arg);
        //console.log("    dataSize = " + objectcopy.objectAddDataSize);
        if(objectcopy.objectAddState == LT.ObjectCopy.OAS_Movie_Confirm) {
            // IVC >> MC893 >>
            if (checkLastMovieTimer.isWaiting || currentAddedFileCount > 0) {
                // keep/add file information
                addObjectCopy();

                // reduce file count
                currentAddedFileCount -= 1;
            }

//            var confirm_message1 = qsTr("confirm_message_1")//転送中はPCからの操作ができなくなります。
//            var confirm_message2 = qsTr("confirm_message_2")//撮影した動画をPCに取り込みますか？
//            var confirm_message3 = qsTr("confirm_message_3")//転送サイズ：
//            var confirm_message4 = qsTr("confirm_message_4")//MB
//            var confirm_message5 = qsTr("confirm_message_5")//（取り込みには時間がかかる場合があります）
//            var confirm_message6 = qsTr("confirm_message_6")//「いいえ」を選択した場合はSDカードからコピーをする必要があります。
//            //Fix dataSize display minus (USBTHRV 110 - 85)
//            var confirm_message = "<HTML>"
//                                + confirm_message1 + "<br>" + confirm_message2 + "<br>" + confirm_message3 + objectcopy.objectAddDataSizeString()//parseInt((parseInt((objectcopy.objectAddDataSize)/1024))/1024)
//                                + confirm_message4 + "<br>" + confirm_message5 + "<br>" + confirm_message6 + "</HTML>";
//            confirmMovieDlg_showDialog(confirm_message, true)//confirmMovieDlg1.visible = true
            // << IVC << MC893
        }
        else if(objectcopy.objectAddState == LT.ObjectCopy.CT6K4K_Confirm) {
        }
    }

    function cut6K4KStateSetting(arg) {
        //console.log("cut6K4KStateSetting start");
        if(objectcopy.cut6K4KState == LT.ObjectCopy.CT6K4K_Confirm) {
            confirm6K4K(arg)
        } else {
            confirm6K4KDlg_dismiss()//confirm6K4KDlg1.visible = false
            confirmCancel6K4KDlg_dismiss()//confirmCancel6K4KDlg.visible = false
            if(progress6K4KDlg_isVisible()) {//if(progress6K4KDlg.visible) {
                progress6K4KDlg_offsetSizeDispInit()
                progress6K4KTimer.running = false
                progress6K4KDlg_dismiss()//progress6K4KDlg.visible = false
            }
        }
    }

    function confirm6K4K(arg) {
        //console.log("confirm6K4K start");
        //console.log("    arg = " + arg);
        //console.log("    dataSize = " + objectcopy.objectAddDataSize);
        var confirm_message1 = qsTr("confirm_message_1")//転送中はPCからの操作ができなくなります。
        var confirm_message2 = qsTr("confirm_message_15")//撮影した6K/4Kフォトを取り込みますか？
        var confirm_message3 = qsTr("confirm_message_16")//転送枚数：
        var confirm_message4 = qsTr("confirm_message_17")//枚
        var confirm_message5 = qsTr("confirm_message_18")//（取り込みには時間がかかる可能性があります）
        var confirm_message6 = qsTr("confirm_message_19")//「いいえ」を選択した場合はカメラ本体で切り出し操作を実施してからSDカードからコピーをする必要があります。
        var confirm_message = "<HTML>"
                            + confirm_message1 + "<br>" + confirm_message2 + "<br>" + confirm_message3 + objectcopy.cut6K4KDataNum
                            + confirm_message4 + "<br>" + confirm_message5 + "<br>" + confirm_message6 + "</HTML>";
        confirm6K4KDlg_showDialog(confirm_message, true)
    }

    function objectReqTransferConfirm() {
        //console.log("objectReqTransferConfirm start");
    }

    function photoStyleSetting() {
        //console.log("photoStyleSetting start photoStyle" + deviceAdapter.photoStyle);

        btnOptionPhotoStyle.logCol = ltLog;
        btnOptionPhotoStyle.logScrTagID = LT.TagDef.RTScr_Usage_Main_PhotoStyle;
        btnOptionPhotoStyle.logFile = btnOptionPhotoStyle.target;

        if (deviceAdapter.photoStyle != LT.Utilities.PS_Unknown) {
            btnOptionPhotoStyle.optionSelect(deviceAdapter.photoStyle);
        }
    }

    function imgInfoQualitySetting() {
        //console.log("imgInfoQualitySetting start");

        btnOptionImgInfoQuality.logCol = ltLog;
        btnOptionImgInfoQuality.logScrTagID = LT.TagDef.RTScr_Usage_Main_PictureQuality;
        btnOptionImgInfoQuality.logFile = btnOptionImgInfoQuality.target;

        if (deviceAdapter.imgInfoQuality != LT.Utilities.ImgInfoQ_Unknown) {
            btnOptionImgInfoQuality.optionSelect(deviceAdapter.imgInfoQuality);
        }
    }

//    function imgInfoAspectSetting() {
//        console.log("imgInfoAspectSetting start");

//        if (deviceAdapter.imgInfoAspect != LT.Utilities.ImgInfoA_Unknown) {
//            btnOptionImgInfoAspect.optionSelect(deviceAdapter.imgInfoAspect);
//        }
//    }

    function afaeButtonSetting() {
        LTSubFunction.console_debug.out("mainview::afaeButtonSetting")
        var ret = LT.DeviceAdapter.Ternary_False;
        if(!root.afaeStartFlg){
            switch(deviceAdapter.focusMode) {
            case LT.Utilities.FM_AF://               = 0,
            case LT.Utilities.FM_AF_Macro://         = 1,
            case LT.Utilities.FM_AF_Macro_Digi://    = 2,
            case LT.Utilities.FM_AF_S://             = 4,
            case LT.Utilities.FM_AF_F://             = 5,
            case LT.Utilities.FM_AF_C://             = 6,
                afButton.source = "qrc:/images/464_af_ae.svg"
                afButton_dot.source = "qrc:/images/526_afae_point_normal.svg"
                break;
            case LT.Utilities.FM_MF://               = 3,
                afButton.source = "qrc:/images/465_ae.svg"
                afButton_dot.source = "qrc:/images/527_ae_point_normal.svg"
                break;
            case LT.Utilities.FM_Unknown://          = -1,
            case LT.Utilities.FM_Max://
            default:
                return;
            };
        } else {
            switch(deviceAdapter.focusMode) {
            case LT.Utilities.FM_AF://               = 0,
            case LT.Utilities.FM_AF_Macro://         = 1,
            case LT.Utilities.FM_AF_Macro_Digi://    = 2,
            case LT.Utilities.FM_AF_S://             = 4,
            case LT.Utilities.FM_AF_F://             = 5,
            case LT.Utilities.FM_AF_C://             = 6,
                afButton.source = "qrc:/images/520_af_ae_push.svg"
                afButton_dot.source = "qrc:/images/528_afae_point_selected.svg"
                break;
            case LT.Utilities.FM_MF://               = 3,
                afButton.source = "qrc:/images/521_ae_push.svg"
                afButton_dot.source = "qrc:/images/529_ae_point_selected.svg"
                break;
            case LT.Utilities.FM_Unknown://          = -1,
            case LT.Utilities.FM_Max://
            default:
                return;
            };
        }
    }

    function focusModeSetting() {
        //console.log("focusModeSetting start");

        // モードによって連写のケーパビリティが変わるため、ドライブモードが連写の場合はポップアップを閉じる
        if((btnOptionDriveMode.target === "burstSpeed") ||
           (btnOptionDriveMode.target === "burstSpeed1") ||
           (btnOptionDriveMode.target === "burstSpeed2")){
            driveModePopupClose()
        }

        if (deviceAdapter.focusMode != LT.Utilities.FM_Unknown) {
            btnOptionFocusMode.optionSelect(deviceAdapter.focusMode);
            afaeButtonSetting()
        }

        btnOptionFocusMode.logCol = ltLog;
        btnOptionFocusMode.logScrTagID = LT.TagDef.RTScr_Usage_Main_FocusMode;
        btnOptionFocusMode.logFile = btnOptionFocusMode.target;
    }

    function autoFocusModeSetting() {
        //console.log("afModeSetting start");

        btnOptionAutoFocusMode.optionSelect(deviceAdapter.autoFocusMode);
        afaeButtonSetting()
        //if (deviceAdapter.autoFocusMode != LT.Utilities.AFM_Unknown) {
        //    btnOptionAutoFocusMode.optionSelect(deviceAdapter.autoFocusMode);
        //    switch(deviceAdapter.focusMode) {
        //    case LT.Utilities.FM_AF://               = 0,
        //    case LT.Utilities.FM_AF_Macro://         = 1,
        //    case LT.Utilities.FM_AF_Macro_Digi://    = 2,
        //    case LT.Utilities.FM_AF_S://             = 4,
        //    case LT.Utilities.FM_AF_F://             = 5,
        //    case LT.Utilities.FM_AF_C://             = 6,
        //        afButton.source = "qrc:/images/464_af_ae.svg"
        //        afButton_dot.source = "qrc:/images/526_afae_point_normal.svg"
        //        break;
        //    case LT.Utilities.FM_MF://               = 3,
        //    case LT.Utilities.FM_Unknown://          = -1,
        //    case LT.Utilities.FM_Max://
        //    default:
        //        afButton.source = "qrc:/images/465_ae.svg"
        //        afButton_dot.source = "qrc:/images/527_ae_point_normal.svg"
        //        break;
        //    }
        //}

        btnOptionAutoFocusMode.logCol = ltLog;
        btnOptionAutoFocusMode.logScrTagID = LT.TagDef.RTScr_Usage_Main_AFMode;
        btnOptionAutoFocusMode.logFile = btnOptionAutoFocusMode.target;
    }

    function customMultiSetting() {
        //console.log("customMultiSetting start customMulti = " + deviceAdapter.customMulti);
    }

    function meteringModeSetting() {
        //console.log("meteringModeSetting start");

        btnOptionMeteringMode.logCol = ltLog;
        btnOptionMeteringMode.logScrTagID = LT.TagDef.RTScr_Usage_Main_MeteringMode;
        btnOptionMeteringMode.logFile = btnOptionMeteringMode.target;

        if (deviceAdapter.meteringMode != LT.Utilities.MM_Unknown) {
            btnOptionMeteringMode.optionSelect(deviceAdapter.meteringMode);
        }
    }

    function wbKSetSetting() {
        //console.log("wbKSetSetting start =" + deviceAdapter.whiteBalanceKSet);

        btnOptionWBKSet.logCol = ltLog;
        btnOptionWBKSet.logScrTagID = LT.TagDef.RTScr_Usage_Main_WBColorTemp;
        btnOptionWBKSet.logFile = btnOptionWBKSet.target;

        if (deviceAdapter.whiteBalanceKSet != LT.Utilities.WBK_Unknown) {
            btnOptionWBKSet.optionSelect(deviceAdapter.whiteBalanceKSet);
        }
    }

    function wbAjustABSetting() {
        //console.log("wbAjustABSetting start =" + deviceAdapter.wbAdjustAB);

        if (deviceAdapter.wbAdjustAB != LT.Utilities.WBAdj_Unknown) {
            if( (deviceAdapter.recordingMode == LT.Utilities.RM_IntelligentAuto) &&
                (deviceAdapter.intelligentAutoMode == LT.Utilities.RM_IA_IntelligentAutoPlus) ){
                //if(wbAdjustPopup.visible == false) {
                    //console.log("wbAjustABSetting sep value =" + deviceAdapter.wbAdjustABSep);
                    wbAdjustPopup.valAB = deviceAdapter.wbAdjustABSep;
                    //wbAdjustPopup.preValAB = deviceAdapter.wbAdjustABSep;
                //}
            } else {
                //if(wbAdjustPopup.visible == false) {
                    //console.log("wbAjustABSetting value =" + deviceAdapter.wbAdjustAB);
                    wbAdjustPopup.valAB = deviceAdapter.wbAdjustAB;
                    //wbAdjustPopup.preValAB = deviceAdapter.wbAdjustAB;
                //}
            }
        }

        wbAdjustSettingText()
    }

    function wbAjustGMSetting() {
        //console.log("wbAjustGMSetting start =" + deviceAdapter.wbAdjustGM);

        if (deviceAdapter.wbAdjustGM != LT.Utilities.WBAdj_Unknown) {
            //if(wbAdjustPopup.visible == false) {
                wbAdjustPopup.valGM = deviceAdapter.wbAdjustGM;
                //wbAdjustPopup.preValGM = deviceAdapter.wbAdjustGM;
            //}
        }

        wbAdjustSettingText()
    }

    function updateMovieRecButtonViewStatus(noEnableChange, noRecStatusChange){
        //ツールチップはSDカードのステータスに依存
        switch(deviceAdapter.statusOfCards) {
        case LT.DeviceAdapter.STOC_Nocard://,
            movieRecButton.toolTipText = qsTr("sd_error_message_1")
            break;
        case LT.DeviceAdapter.STOC_Protected://,
            movieRecButton.toolTipText = qsTr("sd_error_message_2")
            break;
        case LT.DeviceAdapter.STOC_Error://,
            movieRecButton.toolTipText = qsTr("sd_error_message_3")
            break;
        case LT.DeviceAdapter.STOC_Normal://,
        case LT.DeviceAdapter.STOC_Undef://=-1,
        case LT.DeviceAdapter.STOC_Max://,
        default:
            movieRecButton.toolTipText = ""
            break;
        };

        var sdErr = false;
        switch(deviceAdapter.statusOfCards) {
        case LT.DeviceAdapter.STOC_Nocard://,
        case LT.DeviceAdapter.STOC_Protected://,
        case LT.DeviceAdapter.STOC_Error://,
            sdErr = true;
            break;
        case LT.DeviceAdapter.STOC_Normal://,
        case LT.DeviceAdapter.STOC_Undef://=-1,
        case LT.DeviceAdapter.STOC_Max://,
        default:
            sdErr = false;
            break;
        };

        //ストリーミング機能の設定状態
        var uuid = deviceAdapter.camera_list_get_selected_camera_uuid()
        var isStreamingON = deviceAdapter.camera_list_get_camera_streamingFunction(uuid)

        //ボタンのイメージ
        if (deviceAdapter.cameraStatus === LT.Utilities.CamStatus_IP_LiveStreaming){
            //赤丸
            movieRecButton.source = "qrc:/images/12_rec_off.svg"
            if( root.movieRecStartFlg == true && noRecStatusChange === false)
            {
                //録画中にステータスが変わったので停止状態へ
                root.movieRecStartFlg = false;
                if( deviceAdapter.btnAllCameraStatus === LT.Utilities.BtnAllCameraStatus_Checked ||
                    (deviceAdapter.isSupportMultiView() === true && deviceAdapter.getSendCmdDevNum() > 1)){
                    //AllCameraの場合はコピーしない
                    deviceAdapter.camera_list_set_camera_tether_mode_status(uuid, LT.Utilities.TETHERMODE_Copy, false)
                }
            }
        }else if (deviceAdapter.cameraStatus === LT.Utilities.CamStatus_MovRec_4k){
            //白四角
            movieRecButton.source = "qrc:/images/13_rec_on.svg"
            if( root.movieRecStartFlg == false && noRecStatusChange === false)
            {
                //録画中にステータスが変わったので開始状態へ
                root.movieRecStartFlg = true;
                onRecStartAction();
            }
        }else if (deviceAdapter.cameraStatus === LT.Utilities.CamStatus_RemoteRec){
            //SDあるかつストリーミングOFFならさらに録画可能
            if(sdErr == false && isStreamingON === false) {
                //赤丸
                movieRecButton.source = "qrc:/images/12_rec_off.svg"
            }else{
                //白四角
                movieRecButton.source = "qrc:/images/13_rec_on.svg"
            }
            if( root.movieRecStartFlg == false && noRecStatusChange === false)
            {
                //録画中にステータスが変わったので開始状態へ
                root.movieRecStartFlg = true;
                onRecStartAction();
            }
        }else if (deviceAdapter.cameraStatus === LT.Utilities.CamStatus_MovRemoteRec){
            //赤丸
            movieRecButton.source = "qrc:/images/13_rec_on.svg"
            if( root.movieRecStartFlg == false && noRecStatusChange === false)
            {
                //録画中にステータスが変わったので開始状態へ
                root.movieRecStartFlg = true;
                onRecStartAction();
            }
        }else if (deviceAdapter.cameraStatus === LT.Utilities.CamStatus_LiveStreamingRemoteRec){
            //白四角
            movieRecButton.source = "qrc:/images/13_rec_on.svg"
            if( root.movieRecStartFlg == false && noRecStatusChange === false)
            {
                //録画中にステータスが変わったので開始状態へ
                root.movieRecStartFlg = true;
                onRecStartAction();
            }
        }else if (deviceAdapter.cameraStatus === LT.Utilities.CamStatus_RemoteRecRawHDMI){
            //白四角
            movieRecButton.source = "qrc:/images/13_rec_on.svg"
            if( root.movieRecStartFlg == false && noRecStatusChange === false)
            {
                //録画中にステータスが変わったので開始状態へ
                root.movieRecStartFlg = true;
                onRecStartAction();
            }
        }else{
            movieRecButton.source = "qrc:/images/12_rec_off.svg"
            if( root.movieRecStartFlg == true && noRecStatusChange === false)
            {
                //録画中にステータスが変わったので停止状態へ
                root.movieRecStartFlg = false;
                if( deviceAdapter.btnAllCameraStatus === LT.Utilities.BtnAllCameraStatus_Checked ||
                    (deviceAdapter.isSupportMultiView() === true && deviceAdapter.getSendCmdDevNum() > 1)){
                    //AllCameraの場合はコピーしない
                    deviceAdapter.camera_list_set_camera_tether_mode_status(uuid, LT.Utilities.TETHERMODE_Copy, false)
                }
            }
        }

        if (deviceAdapter.pwTetherConnectMode === LT.Utilities.PwTether_OFF &&
            //deviceAdapter.pwTetherModeFlgNum > 0
            deviceAdapter.camSupportPowerSaving
            ) {
            //Tetherコネクトモードが有効かつOFFなら操作できないようにする
            movieRecButton.enabled = false;

            switch(deviceAdapter.statusOfCards) {
            case LT.DeviceAdapter.STOC_Nocard://,
            case LT.DeviceAdapter.STOC_Protected://,
            case LT.DeviceAdapter.STOC_Error://,
                movieRecButton.error = true;
                break;
            case LT.DeviceAdapter.STOC_Normal://,
            case LT.DeviceAdapter.STOC_Undef://=-1,
            case LT.DeviceAdapter.STOC_Max://,
            default:
                movieRecButton.error = false;
                break;
            };
        }else{
            if(deviceAdapter.hdmiSdiStatus === LT.Utilities.HDMI_SDI_Status_HDMI_ON ||
               deviceAdapter.hdmiSdiStatus === LT.Utilities.HDMI_SDI_Status_SDI_ON ||
               deviceAdapter.hdmiSdiStatus === LT.Utilities.HDMI_SDI_Status_HDMI_SDI_ON
               ) {
                //HDMI/SDI有効なら操作できる
                if(noEnableChange === false){
                    movieRecButton.enabled = true;
                }
                movieRecButton.error = false;
            }else{
                switch(deviceAdapter.statusOfCards) {
                case LT.DeviceAdapter.STOC_Nocard://,
                case LT.DeviceAdapter.STOC_Protected://,
                case LT.DeviceAdapter.STOC_Error://,
                    if(noEnableChange === false){
                        movieRecButton.enabled = false;
                    }
                    movieRecButton.error = true;
                    break;
                case LT.DeviceAdapter.STOC_Normal://,
                case LT.DeviceAdapter.STOC_Undef://=-1,
                case LT.DeviceAdapter.STOC_Max://,
                default:
                    if(noEnableChange === false){
                        movieRecButton.enabled = true;
                    }
                    movieRecButton.error = false;
                    break;
                };
            }
        }
    }

    function hdmiSdiStatusSetting(){
        switch(deviceAdapter.hdmiSdiStatus)
        {
        case LT.Utilities.HDMI_SDI_Status_HDMI_ON:
            movieRecButtonText.text = qsTr("HDMI");
            break;
        case LT.Utilities.HDMI_SDI_Status_SDI_ON:
            movieRecButtonText.text = qsTr("SDI");
            break;
        case LT.Utilities.HDMI_SDI_Status_HDMI_SDI_ON:
            movieRecButtonText.text = qsTr("HDMI");
            movieRecButtonText.text += " / ";
            movieRecButtonText.text += qsTr("SDI");
            break;
        default:
            movieRecButtonText.text = "";
            break;
        }
        updateMovieRecButtonViewStatus(false, true)
    }

    function anotherCameraStatusUpdate()
    {
        tetherModeUpdate()
    }

    function movieRec() {
        var stop = false
        var uuid = deviceAdapter.camera_list_get_selected_camera_uuid()

        if( root.movieRecStartFlg ){
            var sdErr = false;
            switch(deviceAdapter.statusOfCards) {
            case LT.DeviceAdapter.STOC_Nocard://,
            case LT.DeviceAdapter.STOC_Protected://,
            case LT.DeviceAdapter.STOC_Error://,
                sdErr = true;
                break;
            case LT.DeviceAdapter.STOC_Normal://,
            case LT.DeviceAdapter.STOC_Undef://=-1,
            case LT.DeviceAdapter.STOC_Max://,
            default:
                sdErr = false;
                break;
            };

            //ストリーミング機能の設定状態
            var isStreamingON = deviceAdapter.camera_list_get_camera_streamingFunction(uuid)

            if( deviceAdapter.cameraStatus === LT.Utilities.CamStatus_RemoteRec && sdErr == false　&& isStreamingON === false){
                //リモート中+SDある+ストリーミング機能OFFならさらにSDに録画
                stop = false;
            }else{
                stop = true;
            }
        }else{
            stop = false;
        }
        var isRemoteRecOnly = false
        if( deviceAdapter.cameraStatus === LT.Utilities.CamStatus_RemoteRec ||
            deviceAdapter.cameraStatus === LT.Utilities.CamStatus_LiveStreamingRemoteRec ||
            deviceAdapter.cameraStatus == LT.Utilities.CamStatus_RemoteRecRawHDMI){
            isRemoteRecOnly = true;
        }

        if(stop == true){
            var ret = deviceAdapter.adp_LMX_func_api_MoveRec_Ctrl_Stop();
            if(ret == LT.DeviceAdapter.Ternary_True) {
                root.movieRecStartFlg = false;
                // 録画時のLiveView表示変更はカメラからのステータ変更のイベントで行う
                //root.recStop()
                if(deviceAdapter.fileTarget === LT.Utilities.FLTG_CameraOnly||
                   isRemoteRecOnly === true ||
                   deviceAdapter.btnAllCameraStatus === LT.Utilities.BtnAllCameraStatus_Checked ||
                   (deviceAdapter.isSupportMultiView() === true && deviceAdapter.getSendCmdDevNum() > 1))
                {
                    //PCにコピーしないならTetherModeを変更できるようにする
                    //リモート録画のみの場合はコピーは発生しない
                    deviceAdapter.camera_list_set_camera_tether_mode_status(uuid, LT.Utilities.TETHERMODE_Copy, false)
                    tetherModeUpdate()
                }
                if(utilities.get_SDK_API_DEBUG()) {
                    objectcopy.objectAddMovie()
                }
            }
        } else {
            if (deviceAdapter.motionPictureFormat == LT.Utilities.MPF_AVCHD) {
                movieTypeChangeRequestDlg.visible = true
            } else {
                var ret = deviceAdapter.adp_LMX_func_api_MoveRec_Ctrl_Start();
                if(ret == LT.DeviceAdapter.Ternary_True) {
                    root.movieRecStartFlg = true;
                    // 録画時のLiveView表示変更はカメラからのステータ変更のイベントで行う
                    //root.recStart()
                    // IVC >> MC893 >>
                    // reset object copy list
                    checkLastMovieTimer.isWaiting = true;
                    clearArrObjectCopy();
                    // << IVC << MC893
                }
            }
        }
        //ボタンの更新は、カメラからのステータ変更のイベントで行う
        //updateMovieRecButtonViewStatus(false)
    }

    function bulbRec() {
        if(root.bulbRecStartFlg){
            var ret = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_Release_cont_end();
            if(ret == LT.DeviceAdapter.Ternary_True) {
                if(root.afaeStartFlg){
                    root.afaeLock()
                }
                root.bulbRecStartFlg = false;
                shutterButton.source = "qrc:/images/15_shutter.svg"
                shutterButton_dot.source = "qrc:/images/530_shutter_point_normal.svg"
// ivc >> start >> No.8
                root.recBulbStop();
// ivc << end << No.8
            }
        } else {
            var ret = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_Release_cont_start();
            if(ret == LT.DeviceAdapter.Ternary_True) {
                root.bulbRecStartFlg = true;
                shutterButton.source = "qrc:/images/15_shutter_y.svg"
                shutterButton_dot.source = "qrc:/images/531_shutter_point_selected.svg"
// ivc >> start >> No.8
                root.recBulbStart();
// ivc << end << No.8
            }
        }
    }

    function burst6K4KRecBurst(arg) {
        if(!arg){
            var ret = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_4k_burst_stop();
            if(ret == LT.DeviceAdapter.Ternary_True) {
                if(root.afaeStartFlg){
                    root.afaeLock()
                }
                root.burst6K4KRecStartFlg = false;
                if(utilities.get_SDK_API_DEBUG()) {
                    objectcopy.cut6K4K()
                }
            }
        } else {
            var ret = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_4k_burst_start();
            if(ret == LT.DeviceAdapter.Ternary_True) {
                root.burst6K4KRecStartFlg = true;
            }
        }
    }
    function burst6K4KRecBurstSS() {
        if(root.burst6K4KRecStartFlg){
//            var ret = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_4k_precap_end();
            var ret = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_4k_burst_stop();
            if(ret == LT.DeviceAdapter.Ternary_True) {
                if(root.afaeStartFlg){
                    root.afaeLock()
                }
                root.burst6K4KRecStartFlg = false;
                shutterButton.source = "qrc:/images/15_shutter.svg"
                shutterButton_dot.source = "qrc:/images/530_shutter_point_normal.svg"
                if(utilities.get_SDK_API_DEBUG()) {
                    objectcopy.cut6K4K()
                }
            }
        } else {
//            var ret = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_4k_precap_start();
            var ret = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_4k_burst_start();
            if(ret == LT.DeviceAdapter.Ternary_True) {
                root.burst6K4KRecStartFlg = true;
                shutterButton.source = "qrc:/images/15_shutter_y.svg"
                shutterButton_dot.source = "qrc:/images/531_shutter_point_selected.svg"
            }
        }
    }

    function burstRec(arg) {
//        if(utilities.isMac()) {
            if(!arg){
                utilities.setHoldingShutterFlg(false)
                var ret = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_Release_cont_end();
                if(ret == LT.DeviceAdapter.Ternary_True) {
                    root.changePreviewTypeWindow();
                    if(root.afaeStartFlg){
                        root.afaeLock()
                    }
                    root.burstRecStartFlg = false;
                }
            } else {
                utilities.setHoldingShutterFlg(true)
                var ret = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_Release_cont_start();
                if(ret == LT.DeviceAdapter.Ternary_True) {
                    root.changePreviewTypePopup();
                    root.burstRecStartFlg = true;
                } else {
                    utilities.setHoldingShutterFlg(false)
                }
            }
//        } else {
//            if(!arg){
//                var ret = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_Release_cont_end();
//                if(ret == LT.DeviceAdapter.Ternary_True) {
//                    root.changePreviewTypeWindow();
//                    if(root.afaeStartFlg){
//                        root.afaeLock()
//                    }
//                    root.burstRecStartFlg = false;
//                    //utilities.setHoldingShutterFlg(false)
//                }
//            } else {
//                var ret = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_Release_cont_start();
//                if(ret == LT.DeviceAdapter.Ternary_True) {
//                    root.changePreviewTypePopup();
//                    root.burstRecStartFlg = true;
//                    //utilities.setHoldingShutterFlg(true)
//                }
//            }
//        }
    }

    function shutterPressed(arg) {
        var ret = LT.DeviceAdapter.Ternary_False;
        // 動画記録中はドライブモードや設定にかかわらず単写要求 -> ここでは何もしない
        if((deviceAdapter.cameraStatus == LT.Utilities.CamStatus_MovRec_4k) &&
           (deviceAdapter.driveMode != LT.Utilities.DM_4K6K)){
            LTSubFunction.console_debug.out("shutterPressed 1")
            return;
        }
        // クリエイティブ動画の場合、撮影ボタンプレス時は何もしない。
        if(deviceAdapter.recordingMode ===　LT.Utilities.RM_CreativeVideo || deviceAdapter.shotModeStatus === LT.Utilities.Shot_Mode_Status_Movie) {   // MC2841 shutterClicked() と同様のチェック追加
            LTSubFunction.console_debug.out("shutterPressed 2")
        // シャッタースピードがバルブの場合、撮影ボタンプレス時は何もしない。
        } else if(deviceAdapter.shutterSpeed == LT.Utilities.SS_Bulb || deviceAdapter.shutterSpeed == LT.Utilities.SS_Time) {
            LTSubFunction.console_debug.out("shutterPressed 3")
        // 上記以外の場合、通常の写真撮影を行う。
        } else {
            LTSubFunction.console_debug.out("shutterPressed 4 driveMode=" + deviceAdapter.driveMode)
            switch(deviceAdapter.driveMode) {
            case LT.Utilities.DM_Burst://連写
            case LT.Utilities.DM_Burst1://連写1
            case LT.Utilities.DM_Burst2://連写2
                // 撮影ボタンプレス時に、通常連写を行う。
                if(deviceAdapter.burstSpeed != LT.Utilities.BS_6K4K) {
                    root.burstRec(arg)
                } else {
                    switch(deviceAdapter.picture4K6K) {
                    case LT.Utilities.PQQ_Unknown:// = -1,
                    case LT.Utilities.PQQ_6K_30p_Burst://,
                    case LT.Utilities.PQQ_4K_60p_Burst://,
                    case LT.Utilities.PQQ_4K_30p_Burst://,
                        // 撮影ボタンプレス時に、6Kフォト・4Kフォト（連写）を行う。
                        root.burst6K4KRecBurst(arg)
                        break;
                    case LT.Utilities.PQQ_6K_30p_PreBurst://,
                    case LT.Utilities.PQQ_4K_60p_PreBurst://,
                    case LT.Utilities.PQQ_4K_30p_PreBurst://,
                    case LT.Utilities.PQQ_6K_30p_Burst_SS://,
                    case LT.Utilities.PQQ_4K_60p_Burst_SS://,
                    case LT.Utilities.PQQ_4K_30p_Burst_SS://,
                    default:
                        //撮影ボタンプレス時は何もしない。
                        break;
                    }
                }
                break;
            case LT.Utilities.DM_4K6K://6Kフォト・4Kフォト（連写 / 連写（S/S） / プリ連写）
                switch(deviceAdapter.picture4K6K) {
                case LT.Utilities.PQQ_Unknown:// = -1,
                case LT.Utilities.PQQ_6K_30p_Burst://,
                case LT.Utilities.PQQ_4K_60p_Burst://,
                case LT.Utilities.PQQ_4K_30p_Burst://,
                    // 撮影ボタンプレス時に、6Kフォト・4Kフォト（連写）を行う。
                    root.burst6K4KRecBurst(arg)
                    break;
                case LT.Utilities.PQQ_6K_30p_PreBurst://,
                case LT.Utilities.PQQ_4K_60p_PreBurst://,
                case LT.Utilities.PQQ_4K_30p_PreBurst://,
                case LT.Utilities.PQQ_6K_30p_Burst_SS://,
                case LT.Utilities.PQQ_4K_60p_Burst_SS://,
                case LT.Utilities.PQQ_4K_30p_Burst_SS://,
                default:
                    //撮影ボタンプレス時は何もしない。
                    break;
                }
                break;
            case LT.Utilities.DM_Single://単写
            case LT.Utilities.DM_SelfTimer://セルフタイマー
            case LT.Utilities.DM_Focus://フォーカスセレクト(未対応)
            case LT.Utilities.DM_Bracket://ブラケット(未対応)
            case LT.Utilities.DM_Interval://,            //インターバル
            case LT.Utilities.DM_Komadori://,            //コマ撮り
            case LT.Utilities.DM_HRS://,                 //ハイレゾショット
            case LT.Utilities.DM_HANDHELD_HRS://,        //手持ちハイレゾショット
            case LT.Utilities.DM_Unknown:// = -1,
            default:
                //撮影ボタンプレス時は何もしない。
                break;
            }
        }
    }

    function shutterClicked() {
        LTSubFunction.console_debug.out("shutterClicked")
        var ret = LT.Utilities.Ternary_False;
        // 動画記録中はドライブモードや設定にかかわらず単写要求
        if(deviceAdapter.cameraStatus == LT.Utilities.CamStatus_MovRec_4k) {
            // テザーアプリで6K/4Kを開始した場合のシャッターボタンは今と同じ6K/4Kの停止要求
            if((root.burst6K4KRecStartFlg) &&
               (deviceAdapter.driveMode == LT.Utilities.DM_4K6K) &&
               ((deviceAdapter.picture4K6K == LT.Utilities.PQQ_6K_30p_Burst_SS) ||
                (deviceAdapter.picture4K6K == LT.Utilities.PQQ_4K_60p_Burst_SS) ||
                (deviceAdapter.picture4K6K == LT.Utilities.PQQ_4K_30p_Burst_SS))){
                root.burst6K4KRecBurstSS()
                return;
            } else {
                ret = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_Release_one_shot();
                if(root.afaeStartFlg){
                    root.afaeLock()
                }
                if(utilities.get_SDK_API_DEBUG()) {
                    objectcopy.objectAddPicture()
                }
                return;
            }
        }
        // クリエイティブ動画の場合、撮影ボタンクリック時も動画撮影を行う。 MC8241 レバー切替えの場合レバー判定を追加
        if(deviceAdapter.recordingMode === LT.Utilities.RM_CreativeVideo || deviceAdapter.shotModeStatus === LT.Utilities.Shot_Mode_Status_Movie) {
            root.movieRec()
        // シャッタースピードがバルブの場合、撮影ボタンクリック時にバルブでの撮影を行う。
        } else if(deviceAdapter.shutterSpeed == LT.Utilities.SS_Bulb ) {
            root.bulbRec()
        // 上記以外の場合、通常の写真撮影を行う。
        } else {
            switch(deviceAdapter.driveMode) {
            case LT.Utilities.DM_4K6K://6Kフォト・4Kフォト（連写 / 連写（S/S） / プリ連写）
                switch(deviceAdapter.picture4K6K) {
                case LT.Utilities.PQQ_6K_30p_Burst_SS://,
                case LT.Utilities.PQQ_4K_60p_Burst_SS://,
                case LT.Utilities.PQQ_4K_30p_Burst_SS://,
                    //6Kフォト・4Kフォト(連写(S/S))の場合、撮影ボタンクリック時に6Kフォト・4Kフォト撮影を行う。
                    root.burst6K4KRecBurstSS()
                    break;
                case LT.Utilities.PQQ_6K_30p_PreBurst://,
                case LT.Utilities.PQQ_4K_60p_PreBurst://,
                case LT.Utilities.PQQ_4K_30p_PreBurst://,
                    ret = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_4k_prewrite_req();
                    if(root.afaeStartFlg){
                        root.afaeLock()
                    }
                    break;
                case LT.Utilities.PQQ_6K_30p_Burst://,
                case LT.Utilities.PQQ_4K_60p_Burst://,
                case LT.Utilities.PQQ_4K_30p_Burst://,
                case LT.Utilities.PQQ_Unknown:// = -1,
                default:
                    // クリック時は何もしない。
                    break;
                }
                break;
            case LT.Utilities.DM_Bracket://ブラケット(未対応)
            case LT.Utilities.DM_Burst://連写
            case LT.Utilities.DM_Burst1://連写1
            case LT.Utilities.DM_Burst2://連写2
                if(deviceAdapter.burstSpeed == LT.Utilities.BS_6K4K) {
                    switch(deviceAdapter.picture4K6K) {
                    case LT.Utilities.PQQ_6K_30p_Burst_SS://,
                    case LT.Utilities.PQQ_4K_60p_Burst_SS://,
                    case LT.Utilities.PQQ_4K_30p_Burst_SS://,
                        //6Kフォト・4Kフォト(連写(S/S))の場合、撮影ボタンクリック時に6Kフォト・4Kフォト撮影を行う。
                        root.burst6K4KRecBurstSS()
                        break;
                    case LT.Utilities.PQQ_6K_30p_PreBurst://,
                    case LT.Utilities.PQQ_4K_60p_PreBurst://,
                    case LT.Utilities.PQQ_4K_30p_PreBurst://,
                        ret = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_4k_prewrite_req();
                        if(root.afaeStartFlg){
                            root.afaeLock()
                        }
                        break;
                    case LT.Utilities.PQQ_6K_30p_Burst://,
                    case LT.Utilities.PQQ_4K_60p_Burst://,
                    case LT.Utilities.PQQ_4K_30p_Burst://,
                    case LT.Utilities.PQQ_Unknown:// = -1,
                    default:
                        // クリック時は何もしない。
                        break;
                    }
                }
                // クリック時は何もしない。
                break;
            case LT.Utilities.DM_Focus://フォーカスセレクト
            case LT.Utilities.DM_Single://単写
            case LT.Utilities.DM_SelfTimer://セルフタイマー
            case LT.Utilities.DM_Interval://インターバル
            case LT.Utilities.DM_Komadori://コマ撮り
            case LT.Utilities.DM_HRS://ハイレゾショット
            case LT.Utilities.DM_HANDHELD_HRS://,        //手持ちハイレゾショット
                // 以下、不定値の場合も単写とみなす。
            case LT.Utilities.DM_Unknown:// = -1,
            default:
//                deviceAdapter.pcSavedFilePath = "";
//                root.dispPreviewWindow();
                ret = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_Release_one_shot();
                if(root.afaeStartFlg){
                    root.afaeLock()
                }
                if(utilities.get_SDK_API_DEBUG()) {
                    objectcopy.objectAddPicture()
                }
                break;
            }
        }
    }

    function afaeLock() {
        LTSubFunction.console_debug.out("mainview::afaeLock")
        var ret = LT.DeviceAdapter.Ternary_False;
        if(root.afaeStartFlg){
            //ret = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE_AFAE_Clear();
            ret = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_Release_halfs_end()
            if(ret == LT.DeviceAdapter.Ternary_True) {
                root.afaeStartFlg = false;
                root.afaeStop()
                afaeButtonSetting()
                // AFAEロック解除でバルブ撮影も終了するため表示切り替え
                if(root.bulbRecStartFlg){
                    root.bulbRecStartFlg = false;
                    shutterButton.source = "qrc:/images/15_shutter.svg"
                    shutterButton_dot.source = "qrc:/images/530_shutter_point_normal.svg"
                    root.recBulbStop();
                }
            }
        } else {
            switch(deviceAdapter.focusMode) {
            case LT.Utilities.FM_AF://               = 0,
            case LT.Utilities.FM_AF_Macro://         = 1,
            case LT.Utilities.FM_AF_Macro_Digi://    = 2,
            case LT.Utilities.FM_AF_S://             = 4,
            case LT.Utilities.FM_AF_F://             = 5,
            case LT.Utilities.FM_AF_C://             = 6,
                //ret = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE_AFAE();
                ret = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_Release_halfs_start()
                break;
            case LT.Utilities.FM_MF://               = 3,
                //ret = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE_AE();
                ret = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_Release_halfs_start()
                break;
            case LT.Utilities.FM_Unknown://          = -1,
            case LT.Utilities.FM_Max://
            default:
                return;
            };
            if(ret == LT.DeviceAdapter.Ternary_True) {
                root.afaeStartFlg = true;
                root.afaeStart()
                afaeButtonSetting()
            }
        }
    }

    function wbPopupCancelClose() {
        LTSubFunction.console_debug.out("wbPopupCancelClose start")
        if(wbAdjustPopup.visible == true) {
            wbAdjustPopup.cancel()
        }
        wbPopupClose()
    }

    function wbPopupClose() {
        LTSubFunction.console_debug.out("wbPopupClose start")
        if(wbAdjustPopup.visible == true) {
            LTSubFunction.console_debug.out("wbPopupClose dismiss")
            wbAdjustPopup.dismiss();
        }
    }

    function photoStylePopupCancelClose() {
        LTSubFunction.console_debug.out("photoStylePopupClose start")
        if(photoStylePopup.visible == true) {
            LTSubFunction.console_debug.out("photoStylePopup dismiss")
            photoStylePopup.cancel();
        }
    }

    function photoStylePopupClose() {
        LTSubFunction.console_debug.out("photoStylePopupClose start")
        if(photoStylePopup.visible == true) {
            LTSubFunction.console_debug.out("photoStylePopup dismiss")
            photoStylePopup.dismiss();
        }
    }

    function photoStylePopupForceClose() {
        LTSubFunction.console_debug.out("photoStylePopupClose start")
        if(photoStylePopup.visible == true) {
            LTSubFunction.console_debug.out("photoStylePopup dismiss")
            photoStylePopup.forceClose();
        }
    }

    function ccPopupCancelClose() {
        LTSubFunction.console_debug.out("ccPopupCancelClose start")
        if(ccPopup.visible == true) {
            ccPopup.cancel()
        }
        ccPopupClose()
    }

    function ccPopupClose() {
        LTSubFunction.console_debug.out("ccPopupClose start")
        if(ccPopup.visible == true) {
            LTSubFunction.console_debug.out("ccPopupClose dismiss")
            ccPopup.dismiss();
        }
    }

    function recordingModePopupClose(){
        LTSubFunction.console_debug.out("recordingModePopupClose start")
        if(optionRecordingModeButtonPopup.visible == true) {
            LTSubFunction.console_debug.out("recordingModePopupClose dismiss")
            optionRecordingModeButtonPopup.dismiss();
        }
        if(optionSubButtonPopup.visible == true) {
            LTSubFunction.console_debug.out("optionSubButtonPopup dismiss")
            optionSubButtonPopup.dismiss();
        }
    }

    function driveModePopupClose(){
        LTSubFunction.console_debug.out("driveModePopupClose start")
        if(optionDriveModeButtonPopup.visible == true) {
            LTSubFunction.console_debug.out("optionDriveModeButtonPopup dismiss")
            optionDriveModeButtonPopup.dismiss();
        }
        if(optionButtonSelfTimerPopup.visible == true) {
            LTSubFunction.console_debug.out("optionButtonSelfTimerPopup dismiss")
            optionButtonSelfTimerPopup.dismiss();
        }
        if(optionButtonDriveModePopup.visible == true){
            LTSubFunction.console_debug.out("optionButtonDriveModePopup dismiss")
            optionButtonDriveModePopup.dismiss();
        }
    }

    function aperturePopupClose(){
        LTSubFunction.console_debug.out("aperturePopupClose start")
        if(optionButtonPopup.visible == true) {
            LTSubFunction.console_debug.out("optionButtonPopup dismiss")
            optionButtonPopup.dismiss();
        }
    }

    function shutterSpdPopupClose(){
        LTSubFunction.console_debug.out("shutterSpdPopupClose start")
        if(optionButtonPopup.visible == true) {
            LTSubFunction.console_debug.out("optionButtonPopup dismiss")
            optionButtonPopup.dismiss();
        }
    }

    function whiteBalancePopupClose(){
        LTSubFunction.console_debug.out("whiteBalancePopupClose start")
        if(optionButtonPopup.visible == true) {
            LTSubFunction.console_debug.out("optionButtonPopup dismiss")
            optionButtonPopup.dismiss();
        }
    }

    function isoPopupClose(){
        LTSubFunction.console_debug.out("isoPopupClose start")
        if(optionButtonPopup.visible == true) {
            LTSubFunction.console_debug.out("optionButtonPopup dismiss")
            optionButtonPopup.dismiss();
        }
    }

    function pictureSizePopupClose(){
        LTSubFunction.console_debug.out("pictureSizePopupClose start")
        if(optionButtonPopup.visible == true) {
            LTSubFunction.console_debug.out("optionButtonPopup dismiss")
            optionButtonPopup.dismiss();
        }
    }

    function imgInfoQualityPopupClose(){
        LTSubFunction.console_debug.out("imgInfoQualityPopupClose start")
        if(optionButtonPopup.visible == true) {
            LTSubFunction.console_debug.out("optionButtonPopup dismiss")
            optionButtonPopup.dismiss();
        }
    }

    function focusModePopupClose(){
        LTSubFunction.console_debug.out("focusModePopupClose start")
        if(optionButtonPopup.visible == true) {
            LTSubFunction.console_debug.out("optionButtonPopup dismiss")
            optionButtonPopup.dismiss();
        }
    }

    function autoFocusModePopupClose(){
        LTSubFunction.console_debug.out("autoFocusModePopupClose start")
        if(optionButtonPopup.visible == true) {
            LTSubFunction.console_debug.out("optionButtonPopup dismiss")
            optionButtonPopup.dismiss();
        }
    }

    function meteringModePopupClose(){
        LTSubFunction.console_debug.out("meteringModePopupClose start")
        if(optionButtonPopup.visible == true) {
            LTSubFunction.console_debug.out("optionButtonPopup dismiss")
            optionButtonPopup.dismiss();
        }
    }

    function wbKSetPopupClose(){
        LTSubFunction.console_debug.out("wbKSetPopupClose start")
        if(optionButtonPopup.visible == true) {
            LTSubFunction.console_debug.out("optionButtonPopup dismiss")
            optionButtonPopup.dismiss();
        }
    }

    function popupClose() {
        LTSubFunction.console_debug.out("popupClose start movie="+progressMovieDlg_isVisible())
        recordingModePopupClose()
        driveModePopupClose()
        aperturePopupClose()
        shutterSpdPopupClose()
        whiteBalancePopupClose()
        isoPopupClose()
        pictureSizePopupClose()
        imgInfoQualityPopupClose()
        focusModePopupClose()
        autoFocusModePopupClose()
        meteringModePopupClose()
        wbKSetPopupClose()
        photoStylePopupClose()
        wbPopupClose()
        ccPopupClose()
        // IVC >> MC893 >> start >> No.1
        movieQualityPopupClose()
        // IVC << MC893 << end << No.1
        confirmMovieDlg_dismiss()//confirmMovieDlg1.visible = false
        confirmCancelMovieDlg_dismiss()//confirmCancelMovieDlg1.visible = false
        fileCopyFailedDlg.visible = false
        if(progressMovieDlg_isVisible()) {
            if(objectcopy.objectAddState == LT.ObjectCopy.OAS_Movie_Start) {
                objectcopy.objectAddState = LT.ObjectCopy.OAS_Movie_Stop
            } else if(objectcopy.objectAddState == LT.ObjectCopy.CT6K4K_Start) {
                objectcopy.objectAddState = LT.ObjectCopy.CT6K4K_Stop
            }
            progressMovieDlg_offsetSizeDispInit()
            progressMovieTimer.running = false
            progressMovieDlg_dismiss()//progressMovieDlg.visible = false
            fileCopyFailedDisp()
        }
        confirm6K4KDlg_dismiss()//confirm6K4KDlg1.visible = false
        confirmCancel6K4KDlg_dismiss()//confirmCancel6K4KDlg.visible = false
        if(progress6K4KDlg_isVisible()) {//if(progress6K4KDlg.visible) {
            progress6K4KDlg_offsetSizeDispInit()
            progress6K4KTimer.running = false
            progress6K4KDlg_dismiss()//progress6K4KDlg.visible = false
            if(objectcopy.cut6K4KState == LT.ObjectCopy.CT6K4K_Start) {
                objectcopy.cut6K4KState = LT.ObjectCopy.CT6K4K_Stop
            }
        }
        movieTypeChangeRequestDlg.visible = false
        settingErrorDlg.visible = false
        wbErrorDlg.visible = false
        memoryCardNothingDlg.visible = false
        root.afaeStartFlg = false;
        root.afaeStop()
        afaeButtonSetting()
        // IVC >> Ver.1.9 >> start >> [THRBOXV100-155]
        cameraErrorDlg.visible = false
//        utilities.closeMessage(qsTr("LUMIX Tether "));
        // IVC << Ver.1.9 << end << [THRBOXV100-155]
    }

// IVC >> MC893 >> start >> No.1
    function movieQualityPopupCancelClose() {
        LTSubFunction.console_debug.out("movieQualityPopupCancelClose start")
        if(movieQualityPopup.visible == true) {
            LTSubFunction.console_debug.out("movieQualityPopup cancel")
            movieQualityPopup.cancel();
        }
    }

    function movieQualityPopupClose() {
        LTSubFunction.console_debug.out("movieQualityPopupClose start")
        if(movieQualityPopup.visible == true) {
            LTSubFunction.console_debug.out("movieQualityPopup dismiss")
            movieQualityPopup.dismiss();
        }
    }
// IVC << MC893 << end << No.1

// IVC >> Ver.1.9 >> start >> [THRBOXV100-81]
        function initSetupTetherMode() {
            // ポップアップクローズ
            popupClose()

            if (deviceAdapter.camSupportPowerSaving && deviceAdapter.pwTetherConnectMode == LT.Utilities.PwTether_OFF) {
                firstMainRec.enabled = false
                secMainRec.enabled = false
                flashButton.enabled = false
                sliderExposure.enabled = false
                movieRecButton.enabled = false
                afButton.enabled = false
                shutterButton.enabled = false
            }
            else {
                firstMainRec.enabled = true
                secMainRec.enabled = true
                flashButton.enabled = true
                sliderExposure.enabled = true
                movieRecButton.enabled = true
                afButton.enabled = true
                shutterButton.enabled = true
            }
        }

// IVC << Ver.1.9. << end <<  [THRBOXV100-81]

    flags:
//        Qt.Window
        Qt.Dialog
      | Qt.CustomizeWindowHint
      | Qt.WindowTitleHint
//      | Qt.WindowSystemMenuHint
      | Qt.WindowMinimizeButtonHint
//    | Qt.WindowMaximizeButtonHint
      | Qt. WindowCloseButtonHint
//      | Qt.WindowStaysOnTopHint
    |Qt.MSWindowsFixedSizeDialogHint

    //  ウィンドウの最小サイズと最大サイズを同じ値にして，リサイズできないようにする
    //    * LTMainWindow::compact によって決定する
    minimumWidth: 323
    //minimumHeight: compact ? compactHeight : normalHeight
    minimumHeight: height
    //Behavior on minimumHeight { NumberAnimation { duration: 150; easing.type: Easing.Linear}}//OutBounce }}
    maximumWidth: minimumWidth
    //maximumHeight: minimumHeight
    maximumHeight: height
    //Behavior on maximumHeight { NumberAnimation { duration: 150; easing.type: Easing.Linear}}//OutBounce }}

    //  ウィンドウのサイズを最小/最大サイズにする
    //    * バインドの関係を逆にすると，ウィンドウのサイズを制御するプロパティを変更しても，最小/最大サイズの制限に違反
    //      して表示サイズが変化しないケースがある
    //        * Windows プラットフォームの Qt 5.8 でそのようになる
    width: minimumWidth
    height: compact? compactHeight : normalHeight
    //Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.Linear}}//OutBounce }}

    title: "LUMIX Tether"
    //color: "transparent"
    color: palette.backgroundLight

    onActiveChanged: {
        //LTSubFunction.console_debug.out("MainView::onActiveChanged")
        if(maskpanel.visible) {
            if(root.active) {
                // IVC >> MC893 >> start >> No.1
                if (!movieQualityPopup.visible)
                // IVC << MC893 << end << No.1
                utilities.preferenceWindowActive()
            }
        }
    }

    Component.onCompleted: {
// IVC >> Ver.1.9 >> start >> [THRBOXV100-41]
//        if(utilities.get_SDK_API_DEBUG() ==0) {
//            btnOptionFocusMode.optionOpen = false
//            btnOptionFocusMode.disabled = true
//        } else {
//            btnOptionFocusMode.optionOpen = true
//            btnOptionFocusMode.disabled = false
//        }
// IVC << Ver.1.9 << end << [THRBOXV100-41]
        //Adapter connect
        deviceAdapter.recordingModeChanged.connect(root.recordingModeSetting);
        // IVC >> Ver.1.9 >> start >> No.5.1
        deviceAdapter.reflectFocusMode.connect(root.focusModeSetting);
        // IVC << Ver.1.9 << end << No.5.1
        deviceAdapter.intelligentAutoModeChanged.connect(root.intelligentAutoModeSetting);
        deviceAdapter.intelligentAutoModeInnerChanged.connect(root.wbAdjustSetting);
        deviceAdapter.creativeVideoAEChanged.connect(root.creativeVideoAESetting);
        // IVC >> Ver.1.8 >> start >> No.3
        deviceAdapter.sqMotionChanged.connect(root.creativeVideoAESetting);
        // IVC << Ver.1.8 << end << No.3
        deviceAdapter.custom3SetChanged.connect(root.custom3SetSetting);
        deviceAdapter.photoExposureChanged.connect(root.creativeVideoAESetting);
        deviceAdapter.creativeControlFilterChanged.connect(root.creativeControlFilterSetting);
        deviceAdapter.sceneGuideSceneChanged.connect(root.sceneGuideSceneSetting);
        deviceAdapter.batteryLevelChanged.connect(root.batteryLevelSetting);
        deviceAdapter.imageFreeSpaceChanged.connect(root.imageFreeSpaceSetting);
        deviceAdapter.secondFreeSpaceChanged.connect(root.secondFreeSpaceSetting);
        deviceAdapter.image4KFreeSpaceChanged.connect(root.imageFreeSpaceSetting);
        deviceAdapter.second4KFreeSpaceChanged.connect(root.secondFreeSpaceSetting);
        deviceAdapter.statusOfCardsChanged.connect(root.statusOfCardsSetting)
        deviceAdapter.driveModeChanged.connect(root.driveModeSetting);
        deviceAdapter.picture4K6KChanged.connect(root.picture4K6KSetting);
        deviceAdapter.burstSpeedChanged.connect(root.burstSpeedSetting);
        deviceAdapter.focusSelectChanged.connect(root.focusSelectSetting);
        deviceAdapter.selfTimerChanged.connect(root.selfTimerSetting);
        deviceAdapter.selfTimerCustomChanged.connect(root.selfTimerSetting);
        deviceAdapter.apertureChanged.connect(root.apertureSetting);
        deviceAdapter.shutterSpeedChanged.connect(root.shutterSpdSetting);
        deviceAdapter.whiteBalanceChanged.connect(root.whiteBalanceSetting);
        deviceAdapter.isoChanged.connect(root.isoSetting);
        deviceAdapter.isoAutoChanged.connect(root.isoAutoSetting);
        // IVC >> Ver.1.9 >> start >> No.6
        deviceAdapter.isoGainChanged.connect(root.isoSetting);
        deviceAdapter.shutterSpeedAngleChanged.connect(root.shutterSpdSetting);
        // IVC << Ver.1.9 << end << No.6
        deviceAdapter.exposureValChanged.connect(root.exposureSetting);
        deviceAdapter.exposureRangeMaxChanged.connect(root.exposureMaxSetting);
        deviceAdapter.exposureRangeMinChanged.connect(root.exposureMinSetting);
// IVC >> add >> start >> USBTHRV160-26
        deviceAdapter.systemFrequencyChanged.connect(root.recMovieQualityDetaiSetting);
        deviceAdapter.systemFrequencyFlgNumChanged.connect(root.recMovieQualityDetaiSetting);
        deviceAdapter.recMovieFlgNumChanged.connect(root.recMovieQualityDetaiSetting);
// IVC << add << end << USBTHRV160-26
// IVC >> add >> start >> USBTHRV170-32
        deviceAdapter.motionPictureFormatChanged.connect(root.recMovieQualityDetaiSetting);
// IVC << add << end << USBTHRV170-32
// IVC >> Ver.1.8 >> start >> USBTHRV180-21
        deviceAdapter.motionPictureFormatChanged.connect(root.recordingModeSetting);
// IVC << Ver.1.8 << end << USBTHRV180-21
//        deviceAdapter.motionPictureFormatChanged.connect(root.motionPictureFormatSetting);
//        deviceAdapter.systemFrequencyChanged.connect(root.motionPictureFormatSetting);
        //deviceAdapter.recMovie_AVCHD_NTSCChanged.connect(root.motionPictureFormatSetting);
        //deviceAdapter.recMovie_AVCHD_PALChanged.connect(root.motionPictureFormatSetting);
        //deviceAdapter.recMovie_MP4_NTSCChanged.connect(root.motionPictureFormatSetting);
        //deviceAdapter.recMovie_MP4_PALChanged.connect(root.motionPictureFormatSetting);
        //deviceAdapter.recMovie_MP4_CINEMAChanged.connect(root.motionPictureFormatSetting);
        //deviceAdapter.recMovie_MP4_HEVC_NTSCChanged.connect(root.motionPictureFormatSetting);
        //deviceAdapter.recMovie_MP4_HEVC_PALChanged.connect(root.motionPictureFormatSetting);
        //deviceAdapter.recMovie_MP4_LPCM_NTSCChanged.connect(root.motionPictureFormatSetting);
        //deviceAdapter.recMovie_MP4_LPCM_PALChanged.connect(root.motionPictureFormatSetting);
        //deviceAdapter.recMovie_MP4_LPCM_CINEMAChanged.connect(root.motionPictureFormatSetting);
        //deviceAdapter.recMovie_MOV_NTSCChanged.connect(root.motionPictureFormatSetting);
        //deviceAdapter.recMovie_MOV_PALChanged.connect(root.motionPictureFormatSetting);
        //deviceAdapter.recMovie_MOV_CINEMAChanged.connect(root.motionPictureFormatSetting);
        deviceAdapter.recMovieChanged.connect(root.motionPictureFormatSetting);
// IVC >> MC893 >> start >> No.1
        deviceAdapter.recMovieInnerChanged.connect(root.motionPictureFormatSetting);
// IVC << MC893 << end << No.1
        deviceAdapter.photoStyleChanged.connect(root.photoStyleSetting);
        deviceAdapter.imgInfoQualityChanged.connect(root.imgInfoQualitySetting);
        //deviceAdapter.imgInfoAspectChanged.connect(root.imgInfoAspectSetting);
        deviceAdapter.focusModeChanged.connect(root.focusModeSetting);
        deviceAdapter.autoFocusModeChanged.connect(root.autoFocusModeSetting);
        deviceAdapter.customMultiChanged.connect(root.customMultiSetting);
        deviceAdapter.meteringModeChanged.connect(root.meteringModeSetting);
        deviceAdapter.whiteBalanceKSetChanged.connect(root.wbKSetSetting);
        deviceAdapter.wbAdjustABChanged.connect(root.wbAjustABSetting);
        deviceAdapter.wbAdjustABSepChanged.connect(root.wbAjustABSetting);
        deviceAdapter.wbAdjustGMChanged.connect(root.wbAjustGMSetting);
        deviceAdapter.aspectRatioChanged.connect(root.aspectRatioSetting)
        deviceAdapter.exTeleconChanged.connect(root.aspectRatioSetting)
        //deviceAdapter.pictureSize4by3Changed.connect(root.aspectRatioSetting)
        //deviceAdapter.pictureSize4by3ExChanged.connect(root.aspectRatioSetting)
        //deviceAdapter.pictureSize3by2Changed.connect(root.aspectRatioSetting)
        //deviceAdapter.pictureSize3by2ExChanged.connect(root.aspectRatioSetting)
        //deviceAdapter.pictureSize16by9Changed.connect(root.aspectRatioSetting)
        //deviceAdapter.pictureSize16by9ExChanged.connect(root.aspectRatioSetting)
        //deviceAdapter.pictureSize1by1Changed.connect(root.aspectRatioSetting)
        //deviceAdapter.pictureSize1by1ExChanged.connect(root.aspectRatioSetting)
        deviceAdapter.pictureSizeChanged.connect(root.aspectRatioSetting)
        deviceAdapter.aspectRatioInnerChanged.connect(root.aspectRatioSetting)

        deviceAdapter.recordingModeCapabilityFlgNumChanged.connect(root.recordingModeSetting);
        deviceAdapter.intelligentAutoModeFlgNumChanged.connect(root.intelligentAutoModeSetting);
        deviceAdapter.creativeVideoAEFlgNumChanged.connect(root.creativeVideoAESetting);
        // IVC >> Ver.1.8 >> start >> No.3
        deviceAdapter.sqMotionFlgNumChanged.connect(root.creativeVideoAESetting);
        // IVC << Ver.1.8 << end << No.3
        deviceAdapter.custom3SetFlgNumChanged.connect(root.custom3SetSetting);
        deviceAdapter.photoExposureFlgNumChanged.connect(root.creativeVideoAESetting);
        deviceAdapter.creativeControlFilterFlgNumChanged.connect(root.creativeControlFilterSetting);
        deviceAdapter.sceneGuideSceneFlgNumChanged.connect(root.sceneGuideSceneSetting);
        deviceAdapter.driveModeFlgNumChanged.connect(root.driveModeSetting);
        deviceAdapter.burstSpeedFlgNumChanged.connect(root.burstSpeedSetting);
        deviceAdapter.focusSelectFlgNumChanged.connect(root.focusSelectSetting);
        deviceAdapter.selfTimerFlgNumChanged.connect(root.selfTimerSetting);
        deviceAdapter.selfTimerCustomFlgNumChanged.connect(root.selfTimerSetting);
        //deviceAdapter.intervalModeFlgNumChanged.connect(root.intervalModeFlgNumChangedSetting);
        deviceAdapter.apertureFlgNumChanged.connect(root.apertureSetting);
        deviceAdapter.shutterSpeedFlgNumChanged.connect(root.shutterSpdSetting);
        deviceAdapter.isoFlgNumChanged.connect(root.isoSetting);
        deviceAdapter.isoGainFlgNumChanged.connect(root.isoSetting);
        deviceAdapter.focusModeFlgNumChanged.connect(root.focusModeSetting);
        deviceAdapter.autoFocusFlgNumChanged.connect(root.autoFocusModeSetting);
        deviceAdapter.meteringModeFlgNumChanged.connect(root.meteringModeSetting);
        deviceAdapter.exTeleconFlgNumChanged.connect(root.aspectRatioSetting);
        deviceAdapter.photoStyleFlgNumChanged.connect(root.photoStyleSetting);
        //deviceAdapter.pictureSize4by3FlgNumChanged.connect(root.aspectRatioSetting);
        //deviceAdapter.pictureSize4by3ExFlgNumChanged.connect(root.aspectRatioSetting);
        //deviceAdapter.pictureSize3by2FlgNumChanged.connect(root.aspectRatioSetting);
        //deviceAdapter.pictureSize3by2ExFlgNumChanged.connect(root.aspectRatioSetting);
        //deviceAdapter.pictureSize16by9FlgNumChanged.connect(root.aspectRatioSetting);
        //deviceAdapter.pictureSize16by9ExFlgNumChanged.connect(root.aspectRatioSetting);
        //deviceAdapter.pictureSize1by1FlgNumChanged.connect(root.aspectRatioSetting);
        //deviceAdapter.pictureSize1by1ExFlgNumChanged.connect(root.aspectRatioSetting);
        deviceAdapter.pictureSizeFlgNumChanged.connect(root.aspectRatioSetting);
        deviceAdapter.motionPictureFormatFlgNumChanged.connect(root.motionPictureFormatSetting);
//        deviceAdapter.systemFrequencyFlgNumChanged.connect(root.motionPictureFormatSetting);
        //deviceAdapter.fileTargetFlgNumChanged.connect(root.fileTargetFlgNumChangedSetting);
        //deviceAdapter.recMovie_AVCHD_NTSC_FlgNumChanged.connect(root.motionPictureFormatSetting);
        //deviceAdapter.recMovie_AVCHD_PAL_FlgNumChanged.connect(root.motionPictureFormatSetting);
        //deviceAdapter.recMovie_MP4_NTSC_FlgNumChanged.connect(root.motionPictureFormatSetting);
        //deviceAdapter.recMovie_MP4_PAL_FlgNumChanged.connect(root.motionPictureFormatSetting);
        //deviceAdapter.recMovie_MP4_CINEMA_FlgNumChanged.connect(root.motionPictureFormatSetting);
        //deviceAdapter.recMovie_MP4_HEVC_NTSC_FlgNumChanged.connect(root.motionPictureFormatSetting);
        //deviceAdapter.recMovie_MP4_HEVC_PAL_FlgNumChanged.connect(root.motionPictureFormatSetting);
        //deviceAdapter.recMovie_MP4_LPCM_NTSC_FlgNumChanged.connect(root.motionPictureFormatSetting);
        //deviceAdapter.recMovie_MP4_LPCM_PAL_FlgNumChanged.connect(root.motionPictureFormatSetting);
        //deviceAdapter.recMovie_MP4_LPCM_CINEMA_FlgNumChanged.connect(root.motionPictureFormatSetting);
        //deviceAdapter.recMovie_MOV_NTSC_FlgNumChanged.connect(root.motionPictureFormatSetting);
        //deviceAdapter.recMovie_MOV_PAL_FlgNumChanged.connect(root.motionPictureFormatSetting);
        //deviceAdapter.recMovie_MOV_CINEMA_FlgNumChanged.connect(root.motionPictureFormatSetting);
//        deviceAdapter.recMovieFlgNumChanged.connect(root.motionPictureFormatSetting);
        deviceAdapter.whiteBalanceFlgNumChanged.connect(root.whiteBalanceSetting);
        deviceAdapter.whiteBalanceKSetFlgNumChanged.connect(root.wbKSetSetting);
        deviceAdapter.exposureValFlgNumChanged.connect(root.exposureSetting);
        deviceAdapter.picture4K6KTypeFlgNumChanged.connect(root.picture4K6KSetting);
        deviceAdapter.picture4K6KFpsFlgNumChanged.connect(root.picture4K6KSetting);
        deviceAdapter.aspectRatioFlgNumChanged.connect(root.aspectRatioSetting);
        deviceAdapter.imgInfoQualityFlgNumChanged.connect(root.imgInfoQualitySetting);
        //deviceAdapter.imgInfoAspectFlgNumChanged.connect(root.imgInfoAspectFlgNumChangedSetting);
        //deviceAdapter.recPreviewModeFlgNumChanged.connect(root.recPreviewModeFlgNumChangedSetting);
        //deviceAdapter.afmfModeFlgNumChanged.connect(root.afmfModeFlgNumChangedSetting);
        //deviceAdapter.mfAssistModeFlgNumChanged.connect(root.mfAssistModeFlgNumChangedSetting);

        objectcopy.objectAddStateChanged.connect(root.confirmMovie)
        //objectcopy.objectAddOffsetSizeChanged(root.objectAddOffsetSize);
        objectcopy.cut6K4KStateChanged.connect(root.cut6K4KStateSetting)

        deviceAdapter.cameraStatusChanged.connect(root.cameraStatusSetting)
        utilities.preferenceWindowVisibleChangedNotify.connect(root.preferenceWindowVisibleSetting);
// IVC >> MC893 >> start >> No.1
        utilities.movieQualityWindowVisibleChangedNotify.connect(root.movieQualityWindowVisibleSetting);
// IVC << MC893 << end << No.1
        utilities.searchCamWindowVisibleChangedNotify.connect(root.searchCamWindowVisibleSetting);

        //Popup connect
        wbAdjustPopup.onOKClicked.connect(btnWBAdjust.onPopupOkClicked);
        wbAdjustPopup.onCancelClicked.connect(btnWBAdjust.onPopupCancelClicked);
        wbAdjustPopup.onResetClicked.connect(btnWBAdjust.onPopupResetClicked);
        wbAdjustPopup.onChangeValue.connect(btnWBAdjust.onPopupChangeValue);

        deviceAdapter.settingErrorNotify.connect(root.settingErrorDisp)
        flashAdapter.settingErrorNotify.connect(root.settingErrorDisp)
        // IVC >> Ver.1.9 >> start >> No.4
        deviceAdapter.cameraErrorNotify.connect(root.cameraErrorDisp)
        // IVC << Ver.1.9 << end << No.4

        deviceAdapter.wbErrorNotify.connect(root.wbErrorDisp)

        deviceAdapter.mfAssistStartErrorNotify.connect(root.settingErrorDisp)

        deviceAdapter.memoryCardNothingNotify.connect(root.memoryCardNothingDisp);

        deviceAdapter.af_frame_info_Changed.connect(root.af_frame_info_Changed);
        deviceAdapter.sFrame_infoChanged.connect(root.sFrame_info_Changed);
        deviceAdapter.autoRecognizeGeneralChanged.connect(root.autoFocusModeSetting);
        deviceAdapter.autoRecognizeAnimalChanged.connect(root.autoFocusModeSetting);
        deviceAdapter.automaticRecoChanged.connect(root.autoFocusModeSetting);
        // MC 5229
        deviceAdapter.autoRecognizePartsChanged.connect(root.autoFocusModeSetting);

        utilities.activateWindowNotify.connect(root.activateWindowNotify);

        camNameSetting()
        deviceAdapter.camNameChanged.connect(root.camNameSetting);

        // ivc >> MC893 [No 2] >> start
        deviceAdapter.objectAddEventReceivedNotify.connect(root.notifyObjectAdd);
        // ivc << MC893 [No 2] << end

//        agreementPopup.onOKClicked.connect(agreementPopup.onAgreementOK);
//        agreementPopup.onCancelClicked.connect(agreementPopup.onAgreementCancel);

        // 使用状況の送信機能の削除（LUMIX Tether for Multicam 1.3/LUMIX Tether 2.0 より）
        /*
        //show agreementPopup for the first time running
        if (applicationSettings.logPermission == LT.ApplicationSettings.LogPer_Unknown) {
            agreementPopup.present();
        }
        //*/

        // ※念のため、使用状況の送信「OFF」を設定しています。
        applicationSettings.logPermission = LT.ApplicationSettings.LogPer_Off;

        // IVC >> Ver.1.9 >> start >> No.1
        deviceAdapter.camConnectStatusChanged.connect(root.connectCameraSetting);
        // IVC << Ver.1.9 << end << No.1
        // IVC >> Ver.1.9 >> start >> No.6
        deviceAdapter.ssGainChanged.connect(root.ssGainSetting);
        // IVC << Ver.1.9 << end << No.6
        // IVC >> Ver.1.9 >> start >> [THRBOXV100-81]
        deviceAdapter.initSetupTetherModeChanged.connect(root.initSetupTetherMode);
        // IVC << Ver.1.9. << end >> [THRBOXV100-81]
        deviceAdapter.switchCameraNotify.connect(root.initSetupTetherMode)
        // IVC >> Ver.1.9 >> start >> [THRBOXV100-190][THRBOXV100-206]
        objectcopy.objectAddErrorNotify.connect(root.objectAddErrorNotify)
        // IVC << Ver.1.9 << end << [THRBOXV100-190][THRBOXV100-206]
        deviceAdapter.hdmiSdiStatusChanged.connect(root.hdmiSdiStatusSetting)
//MC8241 2024/7
//        deviceAdapter.shotModeStatusChanged.connect(root.recordingModeSetting)
        deviceAdapter.shotModeStatusChanged.connect(root.shotModeSetting)
        deviceAdapter.anotherCameraStatusChanged.connect(root.anotherCameraStatusUpdate)
        deviceAdapter.pwTetherConnectModeChanged.connect(root.initSetupTetherMode);

        //起動時撮影パネルのサイズがおかしくなる状態の回避策
        //想定サイズと異なる場合は変更する
        if( height !== compactHeight && height !== normalHeight){
            if( compact ){
                root.minimumHeight = compactHeight
                height = compactHeight;
            }else{
                root.maximumHeight = normalHeight
                height = normalHeight;
            }
        }
    }

//    menuBar: MenuBar {
    LabPlat.MenuBar {
        LabPlat.Menu{
            title: qsTr("About")
            visible: utilities.isMac()

            LabPlat.MenuItem {
                text: qsTr("Manual")
                onTriggered: {
                    if (!utilities.openManual()) {
                        //TODO: error message
                        LTSubFunction.console_debug.out("Manual error!");
                    }
                }
            }
        }
    }

    LTLogCollector {
        id: ltLog

        logMajTagID: LT.TagDef.RTMajor_Usage
        logMedTagID: LT.TagDef.RTMed_Usage_Main
        logWindowName: "LTMainWindow"
    }

    LTWindowStateSaver {
        id:windowState
        window: root
        defaultWidth: minimumWidth
        defaultHeight: compact ? compactHeight : normalHeight
        targetWindow: LT.ApplicationSettings.WinList_Main
    }

    Timer {
        id: animation_timer
        interval: 50
        running: false
        repeat: true

        readonly property int mode_ini: 0
        readonly property int mode_normal: 1
        readonly property int mode_compact: 2
        property int mode: mode_ini

        readonly property int resize: 150
        onTriggered: {
            var h = root.height
            if(mode == mode_compact) {
                h -= resize
                if(h <= compactHeight) {
                    h = compactHeight
                    root.maximumHeight = compactHeight
                    running = false
                    windowsizebutton.disabled = false
                    mode = mode_ini
                }
                root.height = h
            } else if(mode == mode_normal) {
                h += resize
                if(h >= normalHeight) {
                    h = normalHeight
                    root.minimumHeight = normalHeight
                    running = false
                    windowsizebutton.disabled = false
                    mode = mode_ini
                }
                root.height = h
            }
            //root.minimumHeight = root.height
            //root.maximumHeight = root.height
        }
    }

    Timer {
        id: cameraStatusTimer
        interval: 50
        running: false
        repeat: false
        onTriggered: {
            LTSubFunction.get_sdk_capability2()
            if((deviceAdapter.cameraStatus != LT.Utilities.CamStatus_MovRec_Others) &&
               (deviceAdapter.cameraStatus != LT.Utilities.CamStatus_Playing) &&
               (deviceAdapter.cameraStatus != LT.Utilities.CamStatus_Processing) &&
                // IVC >> Ver.1.9 >> start >> [THRBOXV100-162]
                deviceAdapter.cameraStatus != LT.Utilities.CamStatus_Menu_Displayed){
                // IVC << Ver.1.9 << end << [THRBOXV100-162]
                deviceAdapter.cameraStatusComplete()
                maskpanel.mode &= ~maskpanel.mode_camera
                maskpanel.mode &= ~maskpanel.mode_live_view_menu
                updateMaskPanel()
            }
            cameraStatusTimer.running = false
        }
    }

    /*
        LTOptionButtonPopup に表示するコンポーネントの組を提供するオブジェクト
     */
    LTOptionComponentsProvider {
        id: optionComponentsProvider
    }

    /*
        LTOptionButton の状態を選択するポップアップ
     */
    LTOptionButtonPopup {
        id: optionButtonPopup
        z: 100
    }

    LTOptionButtonPopup {
        id: optionDriveModeButtonPopup
        z: 100
    }

    LTOptionButtonPopup {
        id: optionRecordingModeButtonPopup
        z: 100
    }

// IVC >> Ver.1.9 >> start >> No.5
    LTOptionButtonPopup {
        id: optionSubButtonPopup
        z: 100
    }
// IVC << Ver.1.9 << end << No.5

    LTCCPopup {
        id: ccPopup
    }

    LTMainWBPopup {
        id: wbAdjustPopup
    }
// IVC >> MC893 >> start >> No.1
    LTMainMQComponentsProvider {
        id: movieQualityComponentsProvider
    }

    LTMainMovieQualityPopup {
        id: movieQualityPopup
    }
// IVC << MC893 << end << No.1
    LTMainPhotoStylePopup {
        id: photoStylePopup
    }

    LTPreferenceAgreementPopup {
        id: agreementPopup

        type: "startup"

        onOkClicked: {
            applicationSettings.logPermission = LT.ApplicationSettings.LogPer_On;
        }

        onCancelClicked: {
            applicationSettings.logPermission = LT.ApplicationSettings.LogPer_Off;
        }
    }

    /*
        LTOptionDriveModeButton のセルフタイマーの状態を選択するポップアップ
     */
    LTOptionButtonSelfTimerPopup {
        id: optionButtonSelfTimerPopup
        z: 100
        componentsProvider: optionComponentsProvider
    }

    /*
        LTOptionDriveModeButton のドライブモードの状態を選択するポップアップ
     */
    LTOptionButtonDriveModePopup {
        id: optionButtonDriveModePopup
        z: 100
    }

    function settingErrorDisp() {
        LTSubFunction.console_debug.out("settingErrorDisp")
//        if(utilities.isMac()) {
            settingErrorDlg.visible = true
//        } else {
//            utilities.warningMessage(qsTr("setting_error_message"))
//        }
    }
    // IVC >> Ver.1.9 >> start >> No.4
    function cameraErrorDisp(individual_id) {
        LTSubFunction.console_debug.out("cameraErrorDisp individual_id = " + individual_id)
        for (var i = 0; i < 16 /*LMX_LIB_DEF_SETUP_INFO_ERROR_MAX*/; i++) {
            var error_dt = deviceAdapter.setup_info_error_date_time(i)
            var error_code = deviceAdapter.setup_info_error_code(i)
            if (error_code !== 0) {
                var errorContent = qsTr("ERR-" + error_code)
                // IVC >> Ver.1.9 >> start >> [THRBOXV100-45]
                if (errorContent === ("ERR-" + error_code)) {
                    continue
                }
                // IVC << Ver.1.9 << end << [THRBOXV100-45]

                var text = ""

                if(utilities.isMac()) {
                    text = '<HTML>' + qsTr("Error Info") + '<br> <br>'
                    text += qsTr('Error Camera') + ': ' + individual_id + '<br>'
                    text += qsTr('Error Date-time') + ': ' + error_dt + '<br>'
                    text += qsTr('Error Code') + ': ' + error_code + '<br>'
                    text += qsTr('Error Content') + ': ' + errorContent + '</HTML>'

                    cameraErrorDlg.text = text
                    cameraErrorDlg.visible = true
                } else {
//                    text = qsTr("Error Info") + '\n \n'
//                    text += qsTr('Error Camera') + ': ' + individual_id + '\n'
//                    text += qsTr('Error Date-time') + ': ' + error_dt + '\n'
//                    text += qsTr('Error Code') + ': ' + error_code + '\n'
//                    text += qsTr('Error Content') + ': ' + errorContent
//                    // IVC >> Ver.1.9 >> start >> Testcase05 No.70
//                    text = replaceAll("<br />", "\n", text)
//                    // IVC << Ver.1.9 << end << Testcase05 No.70
//                    utilities.criticalMessage("LUMIX Tether ", text)
                    text = '<HTML>' + qsTr("Error Info") + '<br> <br>'
                    text += qsTr('Error Camera') + ': ' + individual_id + '<br>'
                    text += qsTr('Error Date-time') + ': ' + error_dt + '<br>'
                    text += qsTr('Error Code') + ': ' + error_code + '<br>'
                    text += qsTr('Error Content') + ': ' + errorContent + '</HTML>'

                    cameraErrorDlg.text = text
                    cameraErrorDlg.visible = true
                    if(deviceAdapter.isCamerasConnected === false) {
                        break;
                    }
                }
            }
        }

    }
    // IVC << Ver.1.9 << end << No.4
// IVC >> Ver.1.9 >> start >> Testcase05 No.70
    function replaceAll(find, replace, str) {
        while( str.indexOf(find) > -1)
        {
            str = str.replace(find, replace);
        }
        return str;
    }
// IVC << Ver.1.9 << end << Testcase05 No.70
    //設定時エラーダイアログ
//    MessageDialog {
    LT.MessageBox{
        id: settingErrorDlg
        modality: Qt.ApplicationModal
        icon: LT.StandardIcon.Warning
        standardButtons: LT.StandardButton.Ok
        title: "LUMIX Tether"
        visible: false
        text: qsTr("setting_error_message")
    }
    // IVC >> Ver.1.9 >> start >> No.4
//    MessageDialog {
    LT.MessageBox{
        id: cameraErrorDlg
        modality: Qt.ApplicationModal
        icon: LT.StandardIcon.Critical
        standardButtons: LT.StandardButton.Ok
        title: "LUMIX Tether"
        visible: false
    }
    // IVC << Ver.1.9 << end << No.4

    function wbErrorDisp() {
        LTSubFunction.console_debug.out("wbErrorDisp")
//        if(utilities.isMac()) {
            wbErrorDlg.visible = true
//        } else {
//            utilities.warningMessage(qsTr("wb_error_message"))
//        }
    }

    //ホワイトセットエラーダイアログ
//    MessageDialog {
    LT.MessageBox{
        id: wbErrorDlg
        modality: Qt.ApplicationModal
        icon: LT.StandardIcon.Warning
        standardButtons: LT.StandardButton.Ok
        title: "LUMIX Tether"
        visible: false
        text: qsTr("wb_error_message")
    }

    function memoryCardNothingDisp() {
        LTSubFunction.console_debug.out("memoryCardNothingDisp")
//        if(utilities.isMac()) {
            memoryCardNothingDlg.visible = true
//        } else {
//            utilities.warningMessage(qsTr("sd_error_message_1"))
//        }
    }

    //メモリーカードなしダイアログ
//    MessageDialog {
    LT.MessageBox{
        id: memoryCardNothingDlg
        modality: Qt.ApplicationModal
        icon: LT.StandardIcon.Warning
        standardButtons: LT.StandardButton.Ok
        title: "LUMIX Tether"
        visible: false
        text: qsTr("sd_error_message_1")
    }

    //記録方式確認ダイアログ
//    MessageDialog {
    LT.MessageBox{
        id: movieTypeChangeRequestDlg
        modality: Qt.ApplicationModal
        icon: LT.StandardIcon.Critical
        standardButtons: LT.StandardButton.Ok
        title: "LUMIX Tether"
        text: qsTr("confirm_message_14")//"動画の記録方式をMP4/MP4(LPCM)/MOVに変更してください"
        visible: false
    }

    //property QtObject confirmMovieDlg2: null
    property var confirmMovieDlg2Array: new Array

    function closeCaptureDlg(){
        confirmMovieDlg_dismiss()//confirmMovieDlg1.visible = false
        confirmCancelMovieDlg_dismiss()//confirmCancelMovieDlg1.visible = false
        fileCopyFailedDlg.visible = false
        if(progressMovieDlg_isVisible()) {
            if(objectcopy.objectAddState == LT.ObjectCopy.OAS_Movie_Start) {
                objectcopy.objectAddState = LT.ObjectCopy.OAS_Movie_Stop
            } else if(objectcopy.objectAddState == LT.ObjectCopy.CT6K4K_Start) {
                objectcopy.objectAddState = LT.ObjectCopy.CT6K4K_Stop
            }
            progressMovieDlg_offsetSizeDispInit()
            progressMovieTimer.running = false
            progressMovieDlg_dismiss()//progressMovieDlg.visible = false
            fileCopyFailedDisp()
        }
        confirm6K4KDlg_dismiss()//confirm6K4KDlg1.visible = false
        confirmCancel6K4KDlg_dismiss()//confirmCancel6K4KDlg.visible = false
        if(progress6K4KDlg_isVisible()) {//if(progress6K4KDlg.visible) {
            progress6K4KDlg_offsetSizeDispInit()
            progress6K4KTimer.running = false
            progress6K4KDlg_dismiss()//progress6K4KDlg.visible = false
            if(objectcopy.cut6K4KState == LT.ObjectCopy.CT6K4K_Start) {
                objectcopy.cut6K4KState = LT.ObjectCopy.CT6K4K_Stop
            }
        }
    }

    function confirmMovieDlg_dismiss() {
//        if(true){//!utilities.isMac()) {
            //if(confirmMovieDlg2 != null) {
            //    if(confirmMovieDlg2.visible == true) {
            //        confirmMovieDlg2.dismiss()
            //    }
            //}
            for(var i = 0; i < confirmMovieDlg2Array.length; i ++){
                if(confirmMovieDlg2Array.indexOf() != null) {
                    if(confirmMovieDlg2Array[i].visible == true) {
                        confirmMovieDlg2Array[i].dismiss()
                    }
                }
            }
//        } else {
//            confirmMovieDlg1.visible = false
//        }
        isCopying = false;
// IVC >> Ver.1.9 >> start >> [THRBOXV100-157]
        updateMovieRecButtonViewStatus(false, false)
// IVC << Ver.1.9 << end << [THRBOXV100-157]
    }

    function confirmMovieDlg_showDialog(arg1, arg2) {
        LTSubFunction.console_debug.out("confirmMovieDlg_showDialog start")
        if(applicationSettings.transConfirmDlgType == LT.ApplicationSettings.ConfirmDlgType_OFF){
            // 転送確認ダイアログ表示をスキップして転送開始
            progressMovieDlg_offsetSizeInit()
            root.liveViewStop()
        } else {
            // 転送確認ダイアログ作成、表示
            var component = Qt.createComponent("LTConfirmMovieDialog.qml")
            if (component.status === Component.Error) {
                console.log("Err createComponent LTConfirmMovieDialog: " + component.errorString())
            }
            //confirmMovieDlg2 = null
            if (component.status == Component.Ready) {
                var confirmMovieDlg2 = component.createObject(null);
                confirmMovieDlg2.onYes.connect(function() {
                    progressMovieDlg_offsetSizeInit()
                    // IVC >> MC893 >>
//                    LTSubFunction.console_debug.out("confirmMovieDlg_showDialog set movieHandle" + confirmMovieDlg2.movieHandle + " objectAddDataSize=" + confirmMovieDlg2.objectAddDataSize)
//                    objectcopy.movieHandle = confirmMovieDlg2.movieHandle
//                    objectcopy.objectAddDataSize = confirmMovieDlg2.objectAddDataSize;
//                    //if(objectcopy.objectAddState == LT.ObjectCopy.OAS_Movie_Confirm) {
//                        objectcopy.objectAddState = LT.ObjectCopy.OAS_Movie_Confirm
//                        objectcopy.objectAddState = LT.ObjectCopy.OAS_Movie_Start
                    //}
                    // IVC << MC893 <<
                    root.liveViewStop()
                    confirmMovieDlg2.dismiss()
                    confirmMovieDlg2 = null
                });
                confirmMovieDlg2.onNo.connect(function() {
                    confirmMovieDlg2.dismiss()
                    confirmMovieDlg2 = null
                    // enable REC button
                    isCopying = false;
                    // IVC >> Ver.1.9 >> start >> [THRBOXV100-81]
                    updateMovieRecButtonViewStatus(false, false)
                    // IVC << Ver.1.9. << end <<  [THRBOXV100-81]
                    //ThtherMode変更できるようにする
                    var uuid = deviceAdapter.camera_list_get_selected_camera_uuid()
                    deviceAdapter.camera_list_set_camera_tether_mode_status(uuid, LT.Utilities.TETHERMODE_Copy, false)
                    tetherModeUpdate()
                });
// IVC >> Ver.1.9 >> start >> [THRBOXV100-157]
                confirmMovieDlg2.onMovieRecStatusUpdate.connect(function() {
                    updateMovieRecButtonViewStatus(false, false)
                });
// IVC << Ver.1.9 << end << [THRBOXV100-157]
                confirmMovieDlg2.onRejected.connect(function() {
                    // ×ボタンクリック
                    if(confirmMovieDlg2 !== null){
                        confirmMovieDlg2.dismiss()
                        confirmMovieDlg2 = null
                    }
                    // enable REC button
                    isCopying = false;
                    // IVC >> Ver.1.9 >> start >> [THRBOXV100-81]
                    updateMovieRecButtonViewStatus(false, false)
                    // IVC << Ver.1.9. << end <<  [THRBOXV100-81]
                    //ThtherMode変更できるようにする
                    var uuid = deviceAdapter.camera_list_get_selected_camera_uuid()
                    deviceAdapter.camera_list_set_camera_tether_mode_status(uuid, LT.Utilities.TETHERMODE_Copy, false)
                    tetherModeUpdate()
                });
                confirmMovieDlg2.text = arg1
                confirmMovieDlg2.visible = arg2
                // IVC >> MC893 >>
                //                confirmMovieDlg2.movieHandle = objectcopy.movieHandle
                //                confirmMovieDlg2.objectAddDataSize = objectcopy.objectAddDataSize
                //                LTSubFunction.console_debug.out("confirmMovieDlg_showDialog get movieHandle" + confirmMovieDlg2.movieHandle + " objectAddDataSize=" + confirmMovieDlg2.objectAddDataSize)
                // IVC << MC893 <<
                confirmMovieDlg2Array.push(confirmMovieDlg2)
            } else {
                component.onStatusChanged = function(status) {
                    if (status == Component.Ready) {
                        var confirmMovieDlg2 = component.createObject(null);
                        confirmMovieDlg2.onYes.connect(function() {
                            progressMovieDlg_offsetSizeInit()
                            // IVC >> MC893 >>
//                            LTSubFunction.console_debug.out("confirmMovieDlg_showDialog set movieHandle=" + confirmMovieDlg2.movieHandle + " objectAddDataSize=" + confirmMovieDlg2.objectAddDataSize)
//                            objectcopy.movieHandle = confirmMovieDlg2.movieHandle;
//                            objectcopy.objectAddDataSize = confirmMovieDlg2.objectAddDataSize;
//                            //if(objectcopy.objectAddState == LT.ObjectCopy.OAS_Movie_Confirm) {
//                                objectcopy.objectAddState = LT.ObjectCopy.OAS_Movie_Confirm
//                                objectcopy.objectAddState = LT.ObjectCopy.OAS_Movie_Start
//                            //}
                            // IVC << MC893 <<
                            root.liveViewStop()
                            confirmMovieDlg2.dismiss()
                            confirmMovieDlg2 = null
                        });
                        confirmMovieDlg2.onNo.connect(function() {
                            confirmMovieDlg2.dismiss()
                            confirmMovieDlg2 = null
                            // enable REC button
                            isCopying = false;
                            // IVC >> Ver.1.9 >> start >> [THRBOXV100-81]
                            updateMovieRecButtonViewStatus(false, false)
                            // IVC << Ver.1.9. << end <<  [THRBOXV100-81]
                            //ThtherMode変更できるようにする
                            var uuid = deviceAdapter.camera_list_get_selected_camera_uuid()
                            deviceAdapter.camera_list_set_camera_tether_mode_status(uuid, LT.Utilities.TETHERMODE_Copy, false)
                            tetherModeUpdate()
                        });
// IVC >> Ver.1.9 >> start >> [THRBOXV100-157]
                        confirmMovieDlg2.onMovieRecStatusUpdate.connect(function() {
                            updateMovieRecButtonViewStatus(false, false)
                        });
// IVC << Ver.1.9 << end << [THRBOXV100-157]
                        confirmMovieDlg2.onRejected.connect(function(){
                            // ×ボタンクリック
                            if(confirmMovieDlg2 !== null){
                                confirmMovieDlg2.dismiss()
                                confirmMovieDlg2 = null
                            }
                            // enable REC button
                            isCopying = false;
                            // IVC >> Ver.1.9 >> start >> [THRBOXV100-81]
                            updateMovieRecButtonViewStatus(false, false)
                            // IVC << Ver.1.9. << end <<  [THRBOXV100-81]
                            //ThtherMode変更できるようにする
                            var uuid = deviceAdapter.camera_list_get_selected_camera_uuid()
                            deviceAdapter.camera_list_set_camera_tether_mode_status(uuid, LT.Utilities.TETHERMODE_Copy, false)
                            tetherModeUpdate()
                        });
                        confirmMovieDlg2.text = arg1
                        confirmMovieDlg2.visible = arg2
                        // IVC >> MC893 >>
//                        confirmMovieDlg2.movieHandle = objectcopy.movieHandle
//                        confirmMovieDlg2.objectAddDataSize = objectcopy.objectAddDataSize
//                        LTSubFunction.console_debug.out("confirmMovieDlg_showDialog get movieHandle" + confirmMovieDlg2.movieHandle + " objectAddDataSize=" + confirmMovieDlg2.objectAddDataSize)
                        // IVC << MC893 <<
                        confirmMovieDlg2Array.push(confirmMovieDlg2)
                    }
                }
            }
        }
    }

    //取り込み確認(動画)ダイアログ
//    MessageDialog {
//    LT.MessageBox{
//        id: confirmMovieDlg1
//        modality: Qt.ApplicationModal
//        icon: LT.StandardIcon.Question
//        standardButtons: LT.StandardButton.Yes | LT.StandardButton.No
//        title: "LUMIX Tether"
//        visible: false

//        onYes: {
//            progressMovieDlg_offsetSizeInit()
//            if(objectcopy.objectAddState == LT.ObjectCopy.OAS_Movie_Confirm) {
//                objectcopy.objectAddState = LT.ObjectCopy.OAS_Movie_Start
//            }
//            root.liveViewStop()
//        }
//    }

    property QtObject progressMovieDlg2: null

    function progressMovieDlg_dismiss() {
        if(!utilities.isMac()) {
            if(progressMovieDlg2 != null) {
                if(progressMovieDlg2.visible == true) {
                    progressMovieDlg2.dismiss()
                    progressMovieDlg2 = null
                }
            }
        } else {
            progressMovieDlg1.visible = false
        }
        objectcopy.setObjectAddOffsetSizeValue(0)
        //ThtherMode変更できるようにする
        var uuid = deviceAdapter.camera_list_get_selected_camera_uuid()
        deviceAdapter.camera_list_set_camera_tether_mode_status(uuid, LT.Utilities.TETHERMODE_Copy, false)
        tetherModeUpdate()
    }

    function progressMovieDlg_isVisible() {
        if(utilities.isMac()) {
            return progressMovieDlg1.visible
        } else {
            if(progressMovieDlg2 != null) {
                return progressMovieDlg2.visible
            } else {
                return false
            }
        }
    }

    function progressMovieDlg_showDialog(arg) {
        LTSubFunction.console_debug.out("progressMovieDlg_showDialog start")
        if(utilities.isMac()) {
            progressMovieDlg1.visible = arg
        } else {
            var component = Qt.createComponent("LTProgressMovieDialog.qml")
            if (component.status === Component.Error) {
                console.log("Err createComponent LTProgressMovieDialog: " + component.errorString())
            }
            progressMovieDlg2 = null
            if (component.status == Component.Ready) {
                progressMovieDlg2 = component.createObject(null);
                progressMovieDlg2.onVisibleChanged.connect(function() {
                    if(progressMovieDlg2.visible==false) {
                        root.liveViewStart()
                        // enable REC button
                        isCopying = false;
                        // IVC >> Ver.1.9 >> start >> [THRBOXV100-81]
                        updateMovieRecButtonViewStatus(false, false)
                        // IVC << Ver.1.9. << end <<  [THRBOXV100-81]
                    }
                });
                progressMovieDlg2.setProgressMovieText1(qsTr("confirm_message_7"))//"取り込み中"
                progressMovieDlg2.setProgressMovieCancel(qsTr("confirm_message_10"))//"キャンセル"
                // IVC >> MC893 >>
                progressMovieDlg2.setProgressMovieTextFileCount(qsTr("confirm_message_22"))//"ファイル数"
                // IVC << MC893 <<
                progressMovieDlg2.confirmCancelMovieDlg_showDialog.connect(root.confirmCancelMovieDlg_showDialog)
                progressMovieDlg2.confirmCancelMovieDlg_dismiss.connect(root.confirmCancelMovieDlg_dismiss)
                progressMovieDlg2.visible = arg
            } else {
                component.onStatusChanged = function(status) {
                    if (component.status == Component.Ready) {
                        progressMovieDlg2 = component.createObject(null);
                        progressMovieDlg2.onVisibleChanged.connect(function() {
                            if(progressMovieDlg2.visible==false) {
                                root.liveViewStart()
                                // enable REC button
                                isCopying = false;
                                // IVC >> Ver.1.9 >> start >> [THRBOXV100-81]
                                updateMovieRecButtonViewStatus(false, false)
                                // IVC << Ver.1.9. << end <<  [THRBOXV100-81]
                            }
                        });
                        progressMovieDlg2.setProgressMovieText1(qsTr("confirm_message_7"))//"取り込み中"
                        progressMovieDlg2.setProgressMovieCancel(qsTr("confirm_message_10"))//"キャンセル"
                        // IVC >> MC893 >>
                        progressMovieDlg2.setProgressMovieTextFileCount(qsTr("confirm_message_22"))//"ファイル数"
                        // IVC << MC893 <<
                        progressMovieDlg2.confirmCancelMovieDlg_showDialog.connect(root.confirmCancelMovieDlg_showDialog)
                        progressMovieDlg2.confirmCancelMovieDlg_dismiss.connect(root.confirmCancelMovieDlg_dismiss)
                        progressMovieDlg2.visible = arg
                    }
                }
            }
        }
    }

    //取り込み中(動画)ダイアログ
    Window {
        id: progressMovieDlg1
        x: Screen.width / 2 - progressMovieDlg1.width / 2
        y: Screen.height / 2 - progressMovieDlg1.height / 2
        // IVC >> MC893 >>
        width: 650
        height: 280

        //Windowサイズを変更できなくする
        minimumWidth: width
        minimumHeight: height
        maximumWidth: width
        maximumHeight: height

        // IVC << MC893 <<
        flags: Qt.Window | Qt.CustomizeWindowHint | Qt.WindowTitleHint //| Qt.WindowSystemMenuHint | Qt. WindowCloseButtonHint

        modality: Qt.ApplicationModal
        //standardButtons: StandardButton.Cancel
        title: "LUMIX Tether"
        visible: false

        LTStylishText {
            id: progressMovieText1
            x: progressMovieDlg1.width / 2 - progressMovieText1.width / 2
            y: 30
            //font.bold : true
            //font.pointSize : 20
            type: text_style_mainProgressTitle
            text: qsTr("confirm_message_7")//"取り込み中"
        }
        LTStylishText {
            id: progressMovieText2
            x: progressMovieDlg1.width / 2 - progressMovieText2.width / 2
            y: progressMovieText1.y + progressMovieText1.height + 20

            //font.pointSize : 16
            type: text_style_mainProgressContent
            text: "" //"(経過時間 転送済サイズ/全体サイズ)"
        }
        // IVC >> MC893 >>
        ProgressBar {
            id: progressMovieBar
            x: (progressMovieDlg1.width - 100) / 2 - progressMovieBar.width / 2
            y: progressMovieText2.y + progressMovieText2.height + 20
            width: progressMovieDlg1.width - 230
            value: 0
        }

        LTStylishText {
            id: progressMovieTextSizeOne
            x: progressMovieBar.x + progressMovieBar.width + 5
            y: progressMovieBar.y + 2

            type: text_style_mainProgressSize
            text: ""
        }

        // Total progress bar
        ProgressBar {
            id: progressMovieBarTotal
            x: progressMovieBar.x
            y: progressMovieBar.y + progressMovieBar.height + 10
            width: progressMovieBar.width
            value: 0
        }

        LTStylishText {
            id: progressMovieTextSizeAll
            x: progressMovieBarTotal.x + progressMovieBarTotal.width + 5
            y: progressMovieBarTotal.y + 2

            type: text_style_mainProgressSize
            text: ""
        }

        LTStylishText {
            id: progressMovieTextTotalCount
            x: progressMovieBar.x + progressMovieBar.width - width
            y: progressMovieBarTotal.y + progressMovieBarTotal.height + 10

            type: text_style_mainProgressSize
            text: ""
        }

        LTStylishText {
            id: progressMovieTextCurCount
            x: progressMovieTextTotalCount.x - width - 10
            y: progressMovieBarTotal.y + progressMovieBarTotal.height + 10

            type: text_style_mainProgressSize
            text: ""
        }

        LTStylishText {
            id: progressMovieTextFileCount
            x: progressMovieTextCurCount.x - width - 10
            y: progressMovieBarTotal.y + progressMovieBarTotal.height + 10

            type: text_style_mainProgressSize
            text: qsTr("confirm_message_22") //"(ファイル数)"
        }
        // IVC << MC893 <<

        LTProgressButton {
            id: progressMovieCancel
            x: progressMovieDlg1.width / 2 - progressMovieCancel.width / 2
            y: progressMovieDlg1.height - progressMovieCancel.height - 10

            width: 150
            height: 30

            text: qsTr("confirm_message_10")//"キャンセル"

            onClicked: {
                confirmCancelMovieDlg_showDialog(true)//confirmCancelMovieDlg1.visible = true
            }
        }
        onVisibleChanged: {
            // 終了
            if(visible==false) {
                root.liveViewStart()
                // enable REC button
                isCopying = false;
                // IVC >> Ver.1.9 >> start >> [THRBOXV100-81]
                updateMovieRecButtonViewStatus(false, false)
                // IVC << Ver.1.9. << end <<  [THRBOXV100-81]
            }
        }
    }
    Timer {
        id: progressMovieTimer
        interval: 1000//1秒
        running: false
        repeat: true
        property int pastTime: 0
        onTriggered: {
            pastTime += 1
            root.progressMovieDlg_offsetSize()
        }
    }
    // IVC >> MC893 >>
    Timer {
        id: checkLastMovieTimer
        interval: lastObjectAddInterval //1000ms
        running: false
        repeat: false
        property bool isWaiting: false
        onTriggered: {
            root.stopWaitingObject()
        }
    }

    Timer {
        id: gettingMovieTimer
        interval: 20
        running: false
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.monitorAddingObject()
        }
    }
    // IVC >> Ver.1.9 >> start >> [THRBOXV100-190][THRBOXV100-206]
    function objectAddErrorNotify() {
        if(currentAddedFileCount > 0) {
            currentAddedFileCount -= 1;
        }
    }
    // IVC << Ver.1.9 << end << [THRBOXV100-190][THRBOXV100-206]
    function stopWaitingObject() {
        // stop the timer
        checkLastMovieTimer.isWaiting = false;
        checkLastMovieTimer.stop();
        // start the monitor timer
        gettingMovieTimer.start();
    }

    function monitorAddingObject() {
        if (currentAddedFileCount <= 0) {
            // stop the timer
            gettingMovieTimer.stop();
            // show the message
            confirmMovieLastObjectAdd();
        }
    }

    function confirmMovieLastObjectAdd () {
        // Don't show message when count of objectCopy is zero
        if(!objectcopy.objectCopysCount()){
            //コピー前にカード抜かれた？
            isCopying = false;
            // IVC >> Ver.1.9 >> start >> [THRBOXV100-81]
            updateMovieRecButtonViewStatus(false, false)
            // IVC << Ver.1.9. << end <<  [THRBOXV100-81]
            //ThtherMode変更できるようにする
            var uuid = deviceAdapter.camera_list_get_selected_camera_uuid()
            deviceAdapter.camera_list_set_camera_tether_mode_status(uuid, LT.Utilities.TETHERMODE_Copy, false)
            tetherModeUpdate()

            return;
        }
        // the last file is received
        var confirm_message1 = qsTr("confirm_message_1")//転送中はPCからの操作ができなくなります。
        var confirm_message2 = qsTr("confirm_message_2")//撮影した動画をPCに取り込みますか？
        var confirm_message22 = qsTr("confirm_message_22")//ファイル数：
        var confirm_message3 = qsTr("confirm_message_3")//転送サイズ：
        var confirm_message4 = qsTr("confirm_message_4")//MB
        var confirm_message5 = qsTr("confirm_message_5")//（取り込みには時間がかかる場合があります）
        var confirm_message6 = qsTr("confirm_message_6")//「いいえ」を選択した場合はSDカードからコピーをする必要があります。
        //Fix dataSize display minus (USBTHRV 110 - 85)
        var confirm_message = "<HTML><font style='font-size: 11px;'>"
                            + confirm_message1 + "<br>" + confirm_message2 + "<br>" + confirm_message22 + objectcopy.objectCopysCount()
                            + "<br>" + confirm_message3 + getArrObjectSizeString()
                            + confirm_message4 + "<br>" + confirm_message5 + "<br>" + confirm_message6 + "</font></HTML>";
        confirmMovieDlg_showDialog(confirm_message, true)//confirmMovieDlg1.visible = true
    }
    // IVC << MC893 <<

    function progressMovieDlg_offsetSizeInit() {
        //console.log("progressMovieDlg_offsetSizeInit start");
        // IVC >> MC893 >>
        // Don't show message when count of objectCopy is zero
        if(!objectcopy.objectCopysCount()){
            // IVC >> Ver.1.9 >> start >> [THRBOXV100-81]
            updateMovieRecButtonViewStatus(false, false)
            // IVC << Ver.1.9. << end <<  [THRBOXV100-81]
            return;
        }
        objectcopy.beginCopying();
        // LTSubFunction.console_debug.out("confirmMovieDlg_showDialog set movieHandle" + arrObjectCopy[arrObjectCopyIndex].movieHandle + " objectAddDataSize=" + arrObjectCopy[arrObjectCopyIndex].objectAddDataSize)
        objectcopy.setObjectCopyToCurrent();
        objectcopy.objectAddState = LT.ObjectCopy.OAS_Movie_Confirm
        objectcopy.objectAddState = LT.ObjectCopy.OAS_Movie_Start
        // IVC << MC893 <<

        progressMovieTimer.running = true
        progressMovieDlg_showDialog(true)//progressMovieDlg1.visible = true
        root.progressMovieDlg_offsetSizeDispInit()
    }
    function progressMovieDlg_offsetSizeDispInit() {
        //console.log("progressMovieDlg_offsetSizeDispInit start");
        //console.log("    dataSize = " + objectcopy.objectAddDataSize);
        var text1 = qsTr("confirm_message_8")
        // IVC >> MC893 >>
        var text2 = "00:00"
//        var text3 = qsTr("confirm_message_4")//"MB"
//        var text4 = "/"
//        //Fix dataSize display minus (USBTHRV 110 - 85)
//        var text5 = objectcopy.objectAddDataSizeString()//String(parseInt((objectcopy.objectAddDataSize/1024)/1024))
//        var text6 = qsTr("confirm_message_4")//"MB"
        var text7 = qsTr("confirm_message_9")

        // size string
        var sizeOne1 = "0"
        var sizeOne2 = qsTr("confirm_message_4") //"MB"
        var sizeOne3 = "/"
        var sizeOne4 = objectcopy.objectAddDataSizeString()//String(parseInt((objectcopy.objectAddDataSize/1024)/1024))
        var sizeOne5 = qsTr("confirm_message_4")//"MB"

        var sizeAll1 = "0"
        var sizeAll2 = qsTr("confirm_message_4") //"MB"
        var sizeAll3 = "/"
        var sizeAll4 = getArrObjectSizeString()
        var sizeAll5 = qsTr("confirm_message_4")//"MB"

        // IVC << MC893 <<
        progressMovieTimer.pastTime = 0
        if(!utilities.isMac()) {
            // IVC >> MC893 >>
            progressMovieDlg2.setProgressMovieText2(text1 + text2 + text7)
            progressMovieDlg2.setProgressMovieTextSizeOne(sizeOne1 + sizeOne2 + sizeOne3 + sizeOne4 + sizeOne5)
            progressMovieDlg2.setProgressMovieTextSizeAll(sizeAll1 + sizeAll2 + sizeAll3 + sizeAll4 + sizeAll5)
            progressMovieDlg2.setProgressMovieTextCurCount("0/")
            progressMovieDlg2.setMovieTextTotalCount(objectcopy.objectCopysCount())
            progressMovieDlg2.setProgressMovieBarTotal(0.0)
            // IVC << MC893 <<
            progressMovieDlg2.setProgressMovieBar(0.0)
        } else {
            // IVC >> MC893 >>
            progressMovieText2.text = text1 + text2 + text7
            progressMovieTextSizeOne.text = sizeOne1 + sizeOne2 + sizeOne3 + sizeOne4 + sizeOne5
            progressMovieTextSizeAll.text = sizeAll1 + sizeAll2 + sizeAll3 + sizeAll4 + sizeAll5
            progressMovieTextCurCount.text = "0/"
            progressMovieTextTotalCount.text = objectcopy.objectCopysCount()
            progressMovieBarTotal.value = 0.0
            // IVC << MC893 <<
            progressMovieBar.value = 0.0
        }
    }

    function progressMovieDlg_offsetSize() {
        //console.log("progressMovieDlg_offsetSize start");
        //console.log("    dataSize = " + objectcopy.objectAddDataSize);
        var text1 = qsTr("confirm_message_8")//"(経過時間 "
        var text2 = ""
        if(parseInt(progressMovieTimer.pastTime/60) < 10) {
            text2 = "0"
        }
        var text3 = String(parseInt(progressMovieTimer.pastTime/60))
        var text4 = ":"
        if(parseInt(progressMovieTimer.pastTime%60) < 10) {
            text4 = ":0"
        }
        var text5 = String(parseInt(progressMovieTimer.pastTime%60))
        // IVC >> MC893 >>
//        var text6 = " "
//        //Fix dataSize display minus (USBTHRV 110 - 85)
//        var text7 = objectcopy.objectAddDataOffsetSizeString()//String(parseInt((objectcopy.objectAddOffsetSize/1024)/1024))
//        var text8 = qsTr("confirm_message_4")//"MB"
//        var text9 = "/"
//        //Fix dataSize display minus (USBTHRV 110 - 85)
//        var text10 = objectcopy.objectAddDataSizeString()//String(parseInt((objectcopy.objectAddDataSize/1024)/1024))
//        var text11 = qsTr("confirm_message_4")//"MB"
        // IVC << MC893 <<
        var text12 = qsTr("confirm_message_9")//")"

        // IVC >> MC893 >>
        // size string
        var sizeOne1 = objectcopy.objectAddDataOffsetSizeString()//String(parseInt((objectcopy.objectAddOffsetSize/1024)/1024))
        var sizeOne2 = qsTr("confirm_message_4") //"MB"
        var sizeOne3 = "/"
        var sizeOne4 = objectcopy.objectAddDataSizeString()//String(parseInt((objectcopy.objectAddDataSize/1024)/1024))
        var sizeOne5 = qsTr("confirm_message_4")//"MB"

        var sizeAll1 = parseInt(getArrObjectCountSizeString()) + parseInt(objectcopy.objectAddDataOffsetSizeString())
        var sizeAll2 = qsTr("confirm_message_4") //"MB"
        var sizeAll3 = "/"
        var sizeAll4 = getArrObjectSizeString()
        var sizeAll5 = qsTr("confirm_message_4")//"MB"

        var totalPercent = (parseInt(getArrObjectCountSizeString()) + parseInt(objectcopy.objectAddDataOffsetSizeString()))
                / getArrObjectSizeString()

        // IVC << MC893 <<
        if(!utilities.isMac()) {
            // IVC >> MC893 >>
            progressMovieDlg2.setProgressMovieText2(text1 + text2 + text3 + text4 + text5 + text12)
            progressMovieDlg2.setProgressMovieTextSizeOne(sizeOne1 + sizeOne2 + sizeOne3 + sizeOne4 + sizeOne5)
            progressMovieDlg2.setProgressMovieTextSizeAll(sizeAll1 + sizeAll2 + sizeAll3 + sizeAll4 + sizeAll5)
            progressMovieDlg2.setProgressMovieTextCurCount((objectcopy.currentObjectCopyIndex() + 1) + "/")
            progressMovieDlg2.setMovieTextTotalCount(objectcopy.objectCopysCount())

            progressMovieDlg2.setProgressMovieBarTotal(totalPercent)
            // IVC << MC893 <<
            //Fix dataSize display minus (USBTHRV 110 - 85)
            //progressMovieDlg2.setProgressMovieBar(objectcopy.objectAddOffsetSize / objectcopy.objectAddDataSize)
            progressMovieDlg2.setProgressMovieBar(objectcopy.objectAddDataSizeProgress())
        } else {
            // IVC >> MC893 >>
            progressMovieText2.text = text1 + text2 + text3 + text4 + text5 + text12
            progressMovieTextSizeOne.text = sizeOne1 + sizeOne2 + sizeOne3 + sizeOne4 + sizeOne5
            progressMovieTextSizeAll.text = sizeAll1 + sizeAll2 + sizeAll3 + sizeAll4 + sizeAll5
            progressMovieTextCurCount.text = (objectcopy.currentObjectCopyIndex() + 1) + "/"
            progressMovieTextTotalCount.text = objectcopy.objectCopysCount()
            progressMovieBarTotal.value = totalPercent
            // IVC << MC893 <<
            //Fix dataSize display minus (USBTHRV 110 - 85)
            progressMovieBar.value = objectcopy.objectAddDataSizeProgress()//objectcopy.objectAddOffsetSize / objectcopy.objectAddDataSize
        }

        //if(objectcopy.objectAddOffsetSize == objectcopy.objectAddDataSize) {
        if (objectcopy.objectAddDataSizeProgress() >= 1) {
            // IVC >> MC893 >>
            objectcopy.nextCopy();

            if (objectcopy.isFinalObjectCopy()) {
                progressMovieBar.value = progressMovieBar.to
                progressMovieTimer.running = false

                //delay 0.5s before close
                delayAfter(500, function() {
                    progressMovieDlg_dismiss()//progressMovieDlg1.visible = false
                    confirmCancelMovieDlg_dismiss()//confirmCancelMovieDlg1.visible = false
                })
            } else {
                // LTSubFunction.console_debug.out("confirmMovieDlg_showDialog set movieHandle" + arrObjectCopy[arrObjectCopyIndex].movieHandle + " objectAddDataSize=" + arrObjectCopy[arrObjectCopyIndex].objectAddDataSize)
                objectcopy.setObjectCopyToCurrent();
                objectcopy.setObjectAddOffsetSizeValue(0)
                objectcopy.objectAddState = LT.ObjectCopy.OAS_Movie_Confirm
                objectcopy.objectAddState = LT.ObjectCopy.OAS_Movie_Start
            }
            // IVC << MC893 <<
        }
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

    property QtObject confirmCancelMovieDlg2: null

    function confirmCancelMovieDlg_dismiss() {
        if(!utilities.isMac()) {
            if(confirmCancelMovieDlg2 != null) {
                if(confirmCancelMovieDlg2.visible == true) {
                    confirmCancelMovieDlg2.close()
//                    confirmCancelMovieDlg2.dismiss()
                }
            }
        } else {
            confirmCancelMovieDlg1.visible = false
        }
    }

    function confirmCancelMovieDlg_showDialog(arg) {
        LTSubFunction.console_debug.out("confirmCancelMovieDlg_showDialog start")
        if(utilities.isMac()) {
            if((arg!=null)&&(arg)) {
                confirmCancelMovieDlg1.visible = true
            }
        } else {
            var component = Qt.createComponent("LTConfirmCancelMovieDialog.qml")
            if (component.status === Component.Error) {
                console.log("Err createComponent LTConfirmCancelMovieDialog: " + component.errorString())
            }
            confirmCancelMovieDlg2 = null
            if (component.status == Component.Ready) {
                confirmCancelMovieDlg2 = component.createObject(null);
                confirmCancelMovieDlg2.onYes.connect(function() {
                    if(objectcopy.objectAddState == LT.ObjectCopy.OAS_Movie_Start) {
                        objectcopy.objectAddState = LT.ObjectCopy.OAS_Movie_Stop
                    } else if(objectcopy.objectAddState == LT.ObjectCopy.CT6K4K_Start) {
                        objectcopy.objectAddState = LT.ObjectCopy.CT6K4K_Stop
                    }
                    progressMovieTimer.running = false
                    progressMovieDlg_dismiss()//progressMovieDlg.visible = false
                    confirmCancelMovieDlg2.dismiss()
                    confirmCancelMovieDlg2 = null
                });
                confirmCancelMovieDlg2.onNo.connect(function() {
                    confirmCancelMovieDlg2.dismiss()
                    confirmCancelMovieDlg2 = null
                });
                var text1 = qsTr("confirm_message_11")//本当に取り込みを中止しますか？<br>動画をPCにコピーするには<br>SDカードからコピーする必要があります。
                var text2 = qsTr("confirm_message_12")//本当に取り込みを中止しますか？<br>動画をPCにコピーするには<br>SDカードからコピーする必要があります。
                var text3 = qsTr("confirm_message_13")//本当に取り込みを中止しますか？<br>動画をPCにコピーするには<br>SDカードからコピーする必要があります。
                var disp = "<HTML>" + text1 + "<br>" + text2 + "<br>" + text3 + "</HTML>"
                confirmCancelMovieDlg2.text = disp
                if((arg!=null)&&(arg)) {
                    confirmCancelMovieDlg2.visible = true
                }
            } else {
                component.onStatusChanged = function(status) {
                    if (status == Component.Ready) {
                        confirmCancelMovieDlg2 = component.createObject(null);
                        confirmCancelMovieDlg2.onYes.connect(function() {
                            if(objectcopy.objectAddState == LT.ObjectCopy.OAS_Movie_Start) {
                                objectcopy.objectAddState = LT.ObjectCopy.OAS_Movie_Stop
                            } else if(objectcopy.objectAddState == LT.ObjectCopy.CT6K4K_Start) {
                                objectcopy.objectAddState = LT.ObjectCopy.CT6K4K_Stop
                            }
                            progressMovieTimer.running = false
                            progressMovieDlg_dismiss()//progressMovieDlg.visible = false
                            confirmCancelMovieDlg2.dismiss()
                            confirmCancelMovieDlg2 = null
                        });
                        confirmCancelMovieDlg2.onNo.connect(function() {
                            confirmCancelMovieDlg2.dismiss()
                            confirmCancelMovieDlg2 = null
                        });
                        var text1 = qsTr("confirm_message_11")//本当に取り込みを中止しますか？<br>動画をPCにコピーするには<br>SDカードからコピーする必要があります。
                        var text2 = qsTr("confirm_message_12")//本当に取り込みを中止しますか？<br>動画をPCにコピーするには<br>SDカードからコピーする必要があります。
                        var text3 = qsTr("confirm_message_13")//本当に取り込みを中止しますか？<br>動画をPCにコピーするには<br>SDカードからコピーする必要があります。
                        var disp = "<HTML>" + text1 + "<br>" + text2 + "<br>" + text3 + "</HTML>"
                        confirmCancelMovieDlg2.text = disp
                        if((arg!=null)&&(arg)) {
                            confirmCancelMovieDlg2.visible = true
                        }
                    }
                }
            }
        }
    }

    //取り込みキャンセル確認(動画)ダイアログ
//    MessageDialog {
    LT.MessageBox{
        id: confirmCancelMovieDlg1
        modality: Qt.ApplicationModal
        icon: LT.StandardIcon.Warning
        standardButtons: LT.StandardButton.Yes | LT.StandardButton.No
        title: "LUMIX Tether"
        visible: false
        Component.onCompleted: {
            var text1 = qsTr("confirm_message_11")//本当に取り込みを中止しますか？<br>動画をPCにコピーするには<br>SDカードからコピーする必要があります。
            var text2 = qsTr("confirm_message_12")//本当に取り込みを中止しますか？<br>動画をPCにコピーするには<br>SDカードからコピーする必要があります。
            var text3 = qsTr("confirm_message_13")//本当に取り込みを中止しますか？<br>動画をPCにコピーするには<br>SDカードからコピーする必要があります。
            var disp = "<HTML>" + text1 + "<br>" + text2 + "<br>" + text3 + "</HTML>"
            confirmCancelMovieDlg1.text = disp
        }

        onYes: {
            if(objectcopy.objectAddState == LT.ObjectCopy.OAS_Movie_Start) {
                objectcopy.objectAddState = LT.ObjectCopy.OAS_Movie_Stop
            } else if(objectcopy.objectAddState == LT.ObjectCopy.CT6K4K_Start) {
                objectcopy.objectAddState = LT.ObjectCopy.CT6K4K_Stop
            }
            progressMovieTimer.running = false
            progressMovieDlg_dismiss()//progressMovieDlg.visible = false
        }
    }

    property QtObject confirm6K4KDlg2: null

    function confirm6K4KDlg_dismiss() {
        if(!utilities.isMac()) {
            if(confirm6K4KDlg2 != null) {
                if(confirm6K4KDlg2.visible == true) {
                    confirm6K4KDlg2.dismiss()
                }
            }
        } else {
            confirm6K4KDlg1.visible = false
        }
    }

    function confirm6K4KDlg_showDialog(arg1, arg2) {
        LTSubFunction.console_debug.out("confirm6K4KDlg_showDialog start")
        if(applicationSettings.transConfirmDlgType == LT.ApplicationSettings.ConfirmDlgType_OFF){
            // 転送確認ダイアログ表示をスキップして転送開始
            progress6K4KDlg_offsetSizeInit()
            if(objectcopy.cut6K4KState == LT.ObjectCopy.CT6K4K_Confirm) {
                objectcopy.cut6K4KState = LT.ObjectCopy.CT6K4K_Start
            }
        }else{
            // 転送確認ダイアログ作成、表示
            if(utilities.isMac()) {
                confirm6K4KDlg1.text = arg1
                confirm6K4KDlg1.visible = arg2
            } else {
                var component = Qt.createComponent("LTConfirm6K4KDialog.qml")
                if (component.status === Component.Error) {
                    console.log("Err createComponent LTConfirm6K4KDialog: " + component.errorString())
                }
                confirm6K4KDlg2 = null
                if (component.status == Component.Ready) {
                    confirm6K4KDlg2 = component.createObject(null);
                    confirm6K4KDlg2.onYes.connect(function() {
                        progress6K4KDlg_offsetSizeInit()
                        if(objectcopy.cut6K4KState == LT.ObjectCopy.CT6K4K_Confirm) {
                            objectcopy.cut6K4KState = LT.ObjectCopy.CT6K4K_Start
                        }
                        confirm6K4KDlg2.dismiss()
                        confirm6K4KDlg2 = null
                    });
                    confirm6K4KDlg2.onNo.connect(function() {
                        if(objectcopy.cut6K4KState == LT.ObjectCopy.CT6K4K_Confirm) {
                            objectcopy.cut6K4KState = LT.ObjectCopy.CT6K4K_Cancel
                        }
                        confirm6K4KDlg2.dismiss()
                        confirm6K4KDlg2 = null
                    });
                    confirm6K4KDlg2.text = arg1
                    confirm6K4KDlg2.visible = arg2
                } else {
                    component.onStatusChanged = function(status) {
                        if (status == Component.Ready) {
                            confirm6K4KDlg2 = component.createObject(null);
                            confirm6K4KDlg2.onYes.connect(function() {
                                progress6K4KDlg_offsetSizeInit()
                                if(objectcopy.cut6K4KState == LT.ObjectCopy.CT6K4K_Confirm) {
                                    objectcopy.cut6K4KState = LT.ObjectCopy.CT6K4K_Start
                                }
                                confirm6K4KDlg2.dismiss()
                                confirm6K4KDlg2 = null
                            });
                            confirm6K4KDlg2.onNo.connect(function() {
                                if(objectcopy.cut6K4KState == LT.ObjectCopy.CT6K4K_Confirm) {
                                    objectcopy.cut6K4KState = LT.ObjectCopy.CT6K4K_Cancel
                                }
                                confirm6K4KDlg2.dismiss()
                                confirm6K4KDlg2 = null
                            });
                            confirm6K4KDlg2.text = arg1
                            confirm6K4KDlg2.visible = arg2
                        }
                    }
                }
            }
        }
    }

    //取り込み確認(6K4K)ダイアログ
//    MessageDialog {
    LT.MessageBox{
        id: confirm6K4KDlg1
        modality: Qt.ApplicationModal
        icon: LT.StandardIcon.Question
        standardButtons: LT.StandardButton.Yes | LT.StandardButton.No
        title: "LUMIX Tether"
        visible: false

        onYes: {
            progress6K4KDlg_offsetSizeInit()
            if(objectcopy.cut6K4KState == LT.ObjectCopy.CT6K4K_Confirm) {
                objectcopy.cut6K4KState = LT.ObjectCopy.CT6K4K_Start
            }
        }
        onNo: {
            if(objectcopy.cut6K4KState == LT.ObjectCopy.CT6K4K_Confirm) {
                objectcopy.cut6K4KState = LT.ObjectCopy.CT6K4K_Cancel
            }
        }
    }

    property QtObject progress6K4KDlg2: null

    function progress6K4KDlg_dismiss() {
        if(!utilities.isMac()) {
            if(progress6K4KDlg2 != null) {
                if(progress6K4KDlg2.visible == true) {
                    progress6K4KDlg2.dismiss()
                    progress6K4KDlg2 = null
                }
            }
        } else {
            progress6K4KDlg1.visible = false
        }
    }

    function progress6K4KDlg_isVisible() {
        if(utilities.isMac()) {
            return progress6K4KDlg1.visible
        } else {
            if(progress6K4KDlg2 != null) {
                return progress6K4KDlg2.visible
            } else {
                return false
            }
        }
    }

    function progress6K4KDlg_showDialog(arg) {
        LTSubFunction.console_debug.out("progress6K4KDlg_showDialog start")
        if(utilities.isMac()) {
            progress6K4KDlg1.visible = arg
        } else {
            var component = Qt.createComponent("LTProgress6K4KDialog.qml")
            if (component.status === Component.Error) {
                console.log("Err createComponent LTProgress6K4KDialog: " + component.errorString())
            }
            progress6K4KDlg2 = null
            if (component.status == Component.Ready) {
                progress6K4KDlg2 = component.createObject(null);
                progress6K4KDlg2.setProgress6K4KText1(qsTr("confirm_message_7"))//"取り込み中"
                progress6K4KDlg2.setProgress6K4KCancel(qsTr("confirm_message_10"))//"キャンセル"
                progress6K4KDlg2.confirmCancel6K4KDlg_showDialog.connect(root.confirmCancel6K4KDlg_showDialog)
                progress6K4KDlg2.confirmCancel6K4KDlg_dismiss.connect(root.confirmCancel6K4KDlg_dismiss)
                progress6K4KDlg2.visible = arg
            } else {
                component.onStatusChanged = function(status) {
                    if (component.status == Component.Ready) {
                        progress6K4KDlg2 = component.createObject(null);
                        progress6K4KDlg2.setProgress6K4KText1(qsTr("confirm_message_7"))//"取り込み中"
                        progress6K4KDlg2.setProgress6K4KCancel(qsTr("confirm_message_10"))//"キャンセル"
                        progress6K4KDlg2.confirmCancel6K4KDlg_showDialog.connect(root.confirmCancel6K4KDlg_showDialog)
                        progress6K4KDlg2.confirmCancel6K4KDlg_dismiss.connect(root.confirmCancel6K4KDlg_dismiss)
                        progress6K4KDlg2.visible = arg
                    }
                }
            }
        }
    }

    //取り込み中(6K4K)ダイアログ
    Window {
        id: progress6K4KDlg1
        x: Screen.width / 2 - progress6K4KDlg1.width / 2
        y: Screen.height / 2 - progress6K4KDlg1.height / 2
        width: 600
        height: 230

        //Windowサイズを変更できなくする
        minimumWidth: width
        minimumHeight: height
        maximumWidth: width
        maximumHeight: height

        flags: Qt.Window | Qt.CustomizeWindowHint | Qt.WindowTitleHint //| Qt.WindowSystemMenuHint | Qt. WindowCloseButtonHint

        modality: Qt.ApplicationModal
        //standardButtons: StandardButton.Cancel
        title: "LUMIX Tether"
        visible: false

        LTStylishText {
            id: progress6K4KText1
            x: progress6K4KDlg1.width / 2 - progress6K4KText1.width / 2
            y: 30

            type: text_style_mainProgressTitle
            text: qsTr("confirm_message_7")//"取り込み中"
        }
        LTStylishText {
            id: progress6K4KText2
            x: progress6K4KDlg1.width / 2 - progress6K4KText2.width / 2
            y: progress6K4KText1.y + progress6K4KText1.height + 20

            type: text_style_mainProgressContent
            text: ""//"(経過時間 転送済枚数/全体枚数)"
        }
        ProgressBar {
            id: progress6K4KBar
            x: progress6K4KDlg1.width / 2 - progress6K4KBar.width / 2
            y: progress6K4KText2.y + progress6K4KText2.height + 20
            width: progress6K4KDlg1.width - 100
            value: 0
        }
        LTProgressButton {
            id: progress6K4KCancel
            x: progress6K4KDlg1.width / 2 - progress6K4KCancel.width / 2
            y: progress6K4KDlg1.height - progress6K4KCancel.height - 10

            text: qsTr("confirm_message_10")//"キャンセル"

            onClicked: {
                confirmCancel6K4KDlg_showDialog(true)//confirmCancel6K4KDlg.visible = true
            }
        }

        onVisibleChanged: {
            //MacでUSB接続時、カメラステータスの変化でライブをStartすると、なぜかマウスカーソルを動かさないとライブが画面が更新されない（原因不明）
            //この時点で明示的に開始することで回避
            if(visible==false) {
                //LANでキャンセルされた場合にライブ開始されない問題出るのでUSBの時のみに限定
                if(deviceAdapter.connectionType === LT.Utilities.PtpipConnType_Usb ){
                    root.liveViewStart()
                }
            }
        }
    }
    function progress6K4KDlg_offsetSizeInit() {
        //console.log("offsetSizeInit start");
        progress6K4KTimer.running = true
        progress6K4KDlg_showDialog(true)
        progress6K4KDlg_offsetSizeDispInit()
    }
    function progress6K4KDlg_offsetSizeDispInit() {
        //console.log("offsetSizeDispInit start");
        //console.log("    dataSize = " + objectcopy.objectAddDataSize);
        var text1 = qsTr("confirm_message_8")
        var text2 = "00:00 0"
        var text3 = qsTr("confirm_message_17")//"枚"
        var text4 = "/"
        var text5 = String(objectcopy.cut6K4KDataNum)
        var text6 = qsTr("confirm_message_17")//"枚"
        var text7 = qsTr("confirm_message_9")
        progress6K4KTimer.pastTime = 0
        if(utilities.isMac()) {
            progress6K4KText2.text = text1 + text2 + text3 + text4 + text5 + text6 + text7
            progress6K4KBar.value = 0.0
        } else {
            progress6K4KDlg2.setProgress6K4KText2(text1 + text2 + text3 + text4 + text5 + text6 + text7)
            progress6K4KDlg2.setProgress6K4KBar(0.0)
        }
    }

    function progress6K4KDlg_offsetSize() {
        //console.log("offsetSize start");
        //console.log("    dataSize = " + objectcopy.objectAddDataSize);
        var progress = objectcopy.cut6K4KDataProgress
        var text1 = qsTr("confirm_message_8")
        var text2 = ""
        if(parseInt(progress6K4KTimer.pastTime/60) < 10) {
            text2 = "0"
        }
        var text3 = String(parseInt(progress6K4KTimer.pastTime/60))
        var text4 = ":"
        if(parseInt(progress6K4KTimer.pastTime%60) < 10) {
            text4 = ":0"
        }
        var text5 = String(parseInt(progress6K4KTimer.pastTime%60))
        var text6 = " "
        var text7 = String(progress)
        var text8 = qsTr("confirm_message_17")//"枚"
        var text9 = "/"
        var text10 = String(objectcopy.cut6K4KDataNum)
        var text11 = qsTr("confirm_message_17")//"枚"
        var text12 = qsTr("confirm_message_9")
        if(utilities.isMac()) {
            progress6K4KText2.text = text1 + text2 + text3 + text4 + text5 + text6 + text7 + text8 + text9 + text10 + text11 + text12
        } else {
            progress6K4KDlg2.setProgress6K4KText2(text1 + text2 + text3 + text4 + text5 + text6 + text7 + text8 + text9 + text10 + text11 + text12)
        }
        if(progress >= objectcopy.cut6K4KDataNum) {
            progress6K4KTimer.running = false
            if(utilities.isMac()) {
                progress6K4KBar.value = 1.0
            } else {
                progress6K4KDlg2.setProgress6K4KBar(1.0)
            }
            progress6K4KDlg_dismiss()//progress6K4KDlg1.visible = false
            confirmCancel6K4KDlg_dismiss()//confirmCancel6K4KDlg.visible = false
            if(objectcopy.cut6K4KState == LT.ObjectCopy.CT6K4K_Start) {
                objectcopy.cut6K4KState = LT.ObjectCopy.CT6K4K_Complete
            }
        } else {
            if(utilities.isMac()) {
                progress6K4KBar.value = progress / objectcopy.cut6K4KDataNum
            } else {
                progress6K4KDlg2.setProgress6K4KBar(progress / objectcopy.cut6K4KDataNum)
            }
        }
    }
    Timer {
        id: progress6K4KTimer
        interval: 1000//1秒
        running: false
        repeat: true
        property int pastTime: 0
        onTriggered: {
            progress6K4KTimer.pastTime += 1
            progress6K4KDlg_offsetSize()
        }
    }

    property QtObject confirmCancel6K4KDlg2: null

    function confirmCancel6K4KDlg_dismiss() {
        if(!utilities.isMac()) {
            if(confirmCancel6K4KDlg2 != null) {
                if(confirmCancel6K4KDlg2.visible == true) {
                    confirmCancel6K4KDlg2.dismiss()
                }
            }
        } else {
            confirmCancel6K4KDlg1.visible = false
        }
    }

    function confirmCancel6K4KDlg_showDialog(arg) {
        LTSubFunction.console_debug.out("confirmCancel6K4KDlg_showDialog start")
        if(utilities.isMac()) {
            if((arg!=null)&&(arg)) {
                confirmCancel6K4KDlg1.visible = true
            }
        } else {
            var component = Qt.createComponent("LTConfirmCancel6K4KDialog.qml")
            if (component.status === Component.Error) {
                console.log("Err createComponent LTConfirmCancel6K4KDialog: " + component.errorString())
            }
            confirmCancel6K4KDlg2 = null
            if (component.status == Component.Ready) {
                confirmCancel6K4KDlg2 = component.createObject(null);
                confirmCancel6K4KDlg2.onYes.connect(function() {
                    progress6K4KTimer.running = false
                    progress6K4KDlg_dismiss()//progress6K4KDlg.visible = false
                    if(objectcopy.cut6K4KState == LT.ObjectCopy.CT6K4K_Start) {
                        objectcopy.cut6K4KState = LT.ObjectCopy.CT6K4K_Stop
                    }
                    progress6K4KDlg_dismiss()//progress6K4KDlg.visible = false
                    confirmCancel6K4KDlg2.dismiss()
                    confirmCancel6K4KDlg2 = null
                });
                confirmCancel6K4KDlg2.onNo.connect(function() {
                    confirmCancel6K4KDlg2.dismiss()
                    confirmCancel6K4KDlg2 = null
                });
                var text1 = qsTr("confirm_message_11")//本当に取り込みを中止しますか？<br>6K/4KフォトをPCにコピーするには<br>カメラ本体で切り出し操作を実施してからSDカードでコピーする必要があります。
                var text2 = qsTr("confirm_message_20")//本当に取り込みを中止しますか？<br>6K/4KフォトをPCにコピーするには<br>カメラ本体で切り出し操作を実施してからSDカードでコピーする必要があります。
                var text3 = qsTr("confirm_message_21")//本当に取り込みを中止しますか？<br>6K/4KフォトをPCにコピーするには<br>カメラ本体で切り出し操作を実施してからSDカードでコピーする必要があります。
                var disp = "<HTML>" + text1 + "<br>" + text2 + "<br>" + text3 + "</HTML>"
                confirmCancel6K4KDlg2.text = disp
                if((arg!=null)&&(arg)) {
                    confirmCancel6K4KDlg2.visible = true
                }
            } else {
                component.onStatusChanged = function(status) {
                    if (status == Component.Ready) {
                        confirmCancel6K4KDlg2 = component.createObject(null);
                        confirmCancel6K4KDlg2.onYes.connect(function() {
                            progress6K4KTimer.running = false
                            progress6K4KDlg_dismiss()//progress6K4KDlg.visible = false
                            if(objectcopy.cut6K4KState == LT.ObjectCopy.CT6K4K_Start) {
                                objectcopy.cut6K4KState = LT.ObjectCopy.CT6K4K_Stop
                            }
                            progress6K4KDlg_dismiss()//progress6K4KDlg.visible = false
                            confirmCancel6K4KDlg2.dismiss()
                            confirmCancel6K4KDlg2 = null
                        });
                        confirmCancel6K4KDlg2.onNo.connect(function() {
                            confirmCancel6K4KDlg2.dismiss()
                            confirmCancel6K4KDlg2 = null
                        });
                        var text1 = qsTr("confirm_message_11")//本当に取り込みを中止しますか？<br>6K/4KフォトをPCにコピーするには<br>カメラ本体で切り出し操作を実施してからSDカードでコピーする必要があります。
                        var text2 = qsTr("confirm_message_20")//本当に取り込みを中止しますか？<br>6K/4KフォトをPCにコピーするには<br>カメラ本体で切り出し操作を実施してからSDカードでコピーする必要があります。
                        var text3 = qsTr("confirm_message_21")//本当に取り込みを中止しますか？<br>6K/4KフォトをPCにコピーするには<br>カメラ本体で切り出し操作を実施してからSDカードでコピーする必要があります。
                        var disp = "<HTML>" + text1 + "<br>" + text2 + "<br>" + text3 + "</HTML>"
                        confirmCancel6K4KDlg2.text = disp
                        if((arg!=null)&&(arg)) {
                            confirmCancel6K4KDlg2.visible = true
                        }
                    }
                }
            }
        }
    }

    //取り込みキャンセル確認(6K4K)ダイアログ
//    MessageDialog {
    LT.MessageBox{
        id: confirmCancel6K4KDlg1
        modality: Qt.ApplicationModal
        icon: LT.StandardIcon.Warning
        standardButtons: LT.StandardButton.Yes | LT.StandardButton.No
        title: "LUMIX Tether"
        visible: false
        Component.onCompleted: {
            var text1 = qsTr("confirm_message_11")//本当に取り込みを中止しますか？<br>6K/4KフォトをPCにコピーするには<br>カメラ本体で切り出し操作を実施してからSDカードでコピーする必要があります。
            var text2 = qsTr("confirm_message_20")//本当に取り込みを中止しますか？<br>6K/4KフォトをPCにコピーするには<br>カメラ本体で切り出し操作を実施してからSDカードでコピーする必要があります。
            var text3 = qsTr("confirm_message_21")//本当に取り込みを中止しますか？<br>6K/4KフォトをPCにコピーするには<br>カメラ本体で切り出し操作を実施してからSDカードでコピーする必要があります。
            var disp = "<HTML>" + text1 + "<br>" + text2 + "<br>" + text3 + "</HTML>"
            confirmCancel6K4KDlg1.text = disp
        }

        onYes: {
            progress6K4KTimer.running = false
            progress6K4KDlg_dismiss()//progress6K4KDlg.visible = false
            if(objectcopy.cut6K4KState == LT.ObjectCopy.CT6K4K_Start) {
                objectcopy.cut6K4KState = LT.ObjectCopy.CT6K4K_Stop
            }
        }
    }

    function fileCopyFailedDisp() {
        LTSubFunction.console_debug.out("fileCopyFailedDisp")
        //if(utilities.isMac()) {
            fileCopyFailedDlg.visible = true
        //} else {
        //    utilities.warningMessage2(qsTr("Failed to copy the file."))
        //}
    }

    //ファイルのコピーに失敗しました。エラーダイアログ
//    MessageDialog {
    LT.MessageBox{
        id: fileCopyFailedDlg
        modality: Qt.NonModal
        icon: LT.StandardIcon.Warning
        standardButtons: LT.StandardButton.Ok
        title: "LUMIX Tether"
        visible: false
        text: qsTr("Failed to copy the file.")
    }

    Column {
        id: rootColumn

        anchors {
            fill: parent
        }
//        x: 0
//        y: 0
//        width: minimumWidth
//        height: normalHeight
        spacing: 1

        //states: [
        //    State {
        //        name: "not compact"
        //        when: compact == false
        //
        //        PropertyChanges {
        //            target: root
        //            height: normalHeight
        //            minimumHeight: normalHeight
        //            maximumHeight: normalHeight
        //        }
        //    },
        //    State {
        //        name: "compact"
        //        when: compact == true
        //
        //        PropertyChanges {
        //            target: root
        //            height: compactHeight
        //            minimumHeight: compactHeight
        //            maximumHeight: compactHeight
        //        }
        //    }
        //]
        //Status bar
        Item {
            //anchors {
            //    left: parent.left
            //    right: parent.right
            //}
            width: minimumWidth
            height: 142

            /*
                背景
             */
            Rectangle {
                anchors {
                    fill: parent
                }
                color: palette.backgroundLight
            }

            /*
                ボタン間ぬりつぶし
             */
            Rectangle {
                x: 160
                // IVC >> Ver.1.9 >> start >> No.1
                //y: 48
                y: 53
                // IVC << Ver.1.9 << end << No.1
                width: 92
                height: 76
                color: palette.backgroundDark
            }

            /*
                LiveView
             */
            LTRectangleButton {
                id: liveViewButton
                x: 8
                y: 8
                // IVC >> Ver.1.9 >> start >> No.1
                //width: 70
                width: 55
                // IVC << Ver.1.9 << end << No.1
                height: 30
                type: "action_halfSize"
                buttonText: qsTr("LV")
                toolTipText: "LIVE VIEW"
                radius: 3
                strokeWidth: 3
                strokeColor: palette.backgroundDark
                fillColor: palette.backgroundLight
                onClicked: {
                    root.toggleLiveView();
                }
            }
// IVC >> Ver.1.9 >> start >> No.1
            /*
                Camera List
             */
            LTRectangleButton {
                id: cameraListButton
                x: liveViewButton.x + liveViewButton.width + 10
                y: 8
                width: 70
                height: 30
                type: "action_halfSize"
                buttonText: qsTr("CAMERA")
                toolTipText: "CAMERA LIST"
                radius: 3
                strokeWidth: 3
                strokeColor: palette.backgroundDark
                fillColor: palette.backgroundLight
                onClicked: {
                    root.toggleCameraList();
                }
            }

            Column {
                anchors.verticalCenter: liveViewButton.verticalCenter
                Image {
                    id: cameraLittleImage
                    x: cameraListButton.x + cameraListButton.width + 20
                    source: "qrc:/images/3_camera.svg"
                }

                LTStylishText {
                    id: pictureAvailableText
                    x: cameraLittleImage.x
                    //text: imageFreeSpaceSetting()
                    width: 50
                    color: "gray"
                    type: text_style_halfSize
                }
            }

            Column {
                anchors.verticalCenter: liveViewButton.verticalCenter
                Image {
                    id: movieLittleImage
                    x: pictureAvailableText.x + pictureAvailableText.width + 10
                    source: "qrc:/images/5_video-01.svg"
                }

                LTStylishText {
                    id: movieAvailableText
                    x: movieLittleImage.x
                    //text: secondFreeSpaceSetting()
                    width: 50
                    color: "gray"
                    //font.bold: true	// H.NAKANO
                    type: text_style_halfSize
                }
            }
// IVC << Ver.1.9 << end << No.1

            Image {
                id: batteryImage
                x: movieAvailableText.x + movieAvailableText.width + 15
                anchors.verticalCenter: liveViewButton.verticalCenter
                source: batteryLevelSetting()

                Canvas {
                    id: canvas
                    x: 3
                    y: 2
                    width: batteryImage.width - 6
                    height: batteryImage.height - 6
                    antialiasing : true
                    smooth: true
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.save();
                        if(deviceAdapter.batteryLevel < LT.DeviceAdapter.BL_Full && deviceAdapter.batteryLevel > LT.DeviceAdapter.BL_Empty) {
                            // battery picture width is 14px
                            var reduceBattery = Math.round((1 - deviceAdapter.batteryLevel / 100) * 14); 
                            reduceBattery = reduceBattery < 0 ? 0 : reduceBattery;
                            ctx.reset();
                            ctx.fillStyle = "#8d8e8f";
                            ctx.fillRect(x + reduceBattery, y, width - reduceBattery, height);
                        } else {
                            ctx.reset();
                        }
                        ctx.restore();
                    }
                }
            }
            /*
                動画ボタン
             */
            LTRoundButton {
                id: movieRecButton
                x: 38
                // IVC >> Ver.1.9 >> start >> No.1
//              y: 56
                y: 61
                // IVC << Ver.1.9 << end << No.1
                diameter: 60
                source: "qrc:/images/12_rec_off.svg"
                strokeWidth: 3
                strokeColor: palette.backgroundDark
                fillColor: palette.backgroundLight
                mainImg.sourceSize.width: 20    // H.NAKANO
                mainImg.sourceSize.height: 20   // H.NAKANO

                onPressAndHold: {
                    if(error) {
                        return
                    }
                    root.recPressAndHoldFlg = true

//                    ltLog.log(LT.TagDef.RecLvl_Info,
//                              LT.TagDef.RTScr_Usage_Main_MovieRecord,
//                              "movieRecButton PressAndHold",
//                              "")
                }

                onClicked: {
                    if(error) {
                        return
                    }
                    root.movieRec()

//                    ltLog.log(LT.TagDef.RecLvl_Info,
//                              LT.TagDef.RTScr_Usage_Main_MovieRecord,
//                              "movieRecButton Clicked",
//                              "")
                }

                onCanceled: {
                    if(error) {
                        return
                    }
                }

                onPressed: {
                    if(error) {
                        return
                    }
                    root.recPressAndHoldFlg = false

//                    ltLog.log(LT.TagDef.RecLvl_Info,
//                              LT.TagDef.RTScr_Usage_Main_MovieRecord,
//                              "movieRecButton Pressed",
//                              "")
                }

                onReleased: {
                    if(error) {
                        return
                    }
                    if(root.recPressAndHoldFlg) {
                        root.recPressAndHoldFlg = false
                        if(containsMouse) {
                            root.movieRec()
                        }
                    }

                    ltLog.log(LT.TagDef.RecLvl_Info,
                              LT.TagDef.RTScr_Usage_Main_MovieRecord,
                              "movieRecButton Released",
                              "")
                }
            }

            //HDMI/SDI
            LTStylishText {
                id: movieRecButtonText

                x: movieRecButton.x
                y: movieRecButton.y + movieRecButton.height
                height: 20
                width: movieRecButton.width

                text: ""
                type: text_style_halfSize
                horizontalAlignment: Text.AlignHCenter

            }


            /*
                AF
             */
            LTRoundButton {
                id: afButton
                x: 122
                // IVC >> Ver.1.9 >> start >> No.1
                //y: 48
                y: 53
                // IVC << Ver.1.9 << end << No.1
                diameter: 76
                source: "qrc:/images/14_af.svg"
                strokeWidth: 3
                strokeColor: palette.backgroundDark
                fillColor: palette.backgroundLight
                mainImg.sourceSize.width: 45    // H.NAKANO
                mainImg.sourceSize.height: 45   // H.NAKANO

                onPressAndHold: {
                    root.afaePressAndHoldFlg = true

//                    ltLog.log(LT.TagDef.RecLvl_Info,
//                              LT.TagDef.RTScr_Usage_Main_AFAE,
//                              "afButton PressAndHold",
//                              "")
                }

                onClicked: {
                    root.afaeLock()

//                    ltLog.log(LT.TagDef.RecLvl_Info,
//                              LT.TagDef.RTScr_Usage_Main_AFAE,
//                              "afButton Clicked",
//                              "")
                }

                onCanceled: {
                }

                onPressed: {
                    root.afaePressAndHoldFlg = false

//                    ltLog.log(LT.TagDef.RecLvl_Info,
//                              LT.TagDef.RTScr_Usage_Main_AFAE,
//                              "afButton Pressed",
//                              "")
                }

                onReleased: {
                    if(root.afaePressAndHoldFlg) {
                        root.afaePressAndHoldFlg = false
                        if(containsMouse) {
                            root.afaeLock()
                        }
                    }

                    ltLog.log(LT.TagDef.RecLvl_Info,
                              LT.TagDef.RTScr_Usage_Main_AFAE,
                              "afButton Release",
                              "")
                }
            }
            Image {
                id: afButton_dot
                x: afButton.x + parseInt(afButton.width/2) - parseInt(afButton_dot.sourceSize.width/2)
                y: afButton.y + afButton.height - afButton_dot.sourceSize.height - 10
                source: "qrc:/images/526_afae_point_normal.svg"
            }

            /*
                Sシャッター
             */
            LTRoundButton {
                id: shutterButton
                x: 214
                // IVC >> Ver.1.9 >> start >> No.1
                //y: 48
                y: 53
                // IVC << Ver.1.9 << end << No.1
                diameter: 76
                source: "qrc:/images/15_shutter.svg"
                strokeWidth: 3
                strokeColor: palette.backgroundDark
                fillColor: palette.backgroundLight
                mainImg.sourceSize.width: 35    // H.NAKANO
                mainImg.sourceSize.height: 35   // H.NAKANO

                onPressAndHold: {
                    LTSubFunction.console_debug.out("shutterButton onPressAndHold")
                    if(error) {
                        LTSubFunction.console_debug.out("shutterButton onPressAndHold error")
                        return
                    }
                    // remove shutter log
//                    ltLog.log(LT.TagDef.RecLvl_Info,
//                              LT.TagDef.RTScr_Usage_Main_Shutter,
//                              "shutterButton PressedAndHold",
//                              "")

                    root.shutterPressAndHoldFlg = true
                }

                onClicked: {
                    if(error) {
                        LTSubFunction.console_debug.out("shutterButton onClicked error")
                        return
                    }
                    // remove shutter log
//                    ltLog.log(LT.TagDef.RecLvl_Info,
//                              LT.TagDef.RTScr_Usage_Main_Shutter,
//                              "shutterButton Clicked",
//                              "")

                    root.shutterClicked()
                }

                onCanceled: {
                    LTSubFunction.console_debug.out("shutterButton onCanceled")
                    if(error) {
                        LTSubFunction.console_debug.out("shutterButton onCanceled error")
                        return
                    }
                    // remove shutter log
//                    ltLog.log(LT.TagDef.RecLvl_Info,
//                              LT.TagDef.RTScr_Usage_Main_Shutter,
//                              "shutterButton Canceled",
//                              "")

                    root.shutterPressed(false)
                }

                onPressed: {
                    LTSubFunction.console_debug.out("shutterButton onPressed")
                    if(error) {
                        LTSubFunction.console_debug.out("shutterButton onPressed error")
                        return
                    }
                    // remove shutter log
//                    ltLog.log(LT.TagDef.RecLvl_Info,
//                              LT.TagDef.RTScr_Usage_Main_Shutter,
//                              "shutterButton Pressed",
//                              "")

                    root.shutterPressAndHoldFlg = false
                    root.shutterPressed(true)
                }

                onReleased: {
                    LTSubFunction.console_debug.out("shutterButton onReleased")
                    if(error) {
                        LTSubFunction.console_debug.out("shutterButton onReleased error")
                        return
                    }
                    ltLog.log(LT.TagDef.RecLvl_Info,
                              LT.TagDef.RTScr_Usage_Main_Shutter,
                              "shutterButton Released",
                              "")

                    if(root.shutterPressAndHoldFlg) {
                        root.shutterPressAndHoldFlg = false
                        if(containsMouse) {
                            root.shutterClicked()
                        }
                    }
                    root.shutterPressed(false)
                }
            }

            Image {
                id: shutterButton_dot
                x: shutterButton.x + parseInt(shutterButton.width/2) - parseInt(shutterButton_dot.sourceSize.width/2)
                y: shutterButton.y + shutterButton.height - shutterButton_dot.sourceSize.height - 10
                source: "qrc:/images/530_shutter_point_normal.svg"
            }
        }

        //Item {
        //    //visible: !compact
        //    //anchors {
        //    //    left: parent.left
        //    //    right: parent.right
        //    //}
        //    width: minimumWidth
        //    height: 1
        //
        /*
            背景
         */
//        Rectangle {
//            //anchors {
//            //    fill: parent
//            //}
//            width: minimumWidth
//            height: 1
//            color: palette.backgroundLight
//        }
        //}

        //The first panel
        //Item {
        //    //visible: !compact
        //    //anchors {
        //    //    left: parent.left
        //    //    right: parent.right
        //    //}
        //    width: minimumWidth
        //    height: 77 * 2 + 1
        //
        //  /*
        //      背景
        //   */
        Rectangle {
            //anchors {
            //    fill: parent
            //}
            id : firstMainRec
            width: minimumWidth
            height: 77 * 2 + 1
            color: palette.backgroundLight

            Grid {
                columns: 3
                rows: 2
                spacing: 1

                /*
                    撮影モード
                 */
                LTOptionButton {
                    id: btnOptionRecordingMode
                    width: 107
                    height: 77
                    type: "optionWithImage"
                    target: "recordingMode"
                    // IVC >> Ver.1.9 >> start >> [THRBOXV100-30] No.5
// 2024 Qt6 対応 start
                    labelText: qsTr("ShootingMode")
// 2024 Qt6 対応 end
                    popupTitle: qsTr("ShootingMode")
                    // IVC << Ver.1.9 << end << [THRBOXV100-30] No.5
                    //source: "qrc:/images/button_placeholder.svg"
                    popup: optionRecordingModeButtonPopup
                    componentsProvider: optionComponentsProvider
// 2024 Qt6 対応 start
                    // mainImg.anchors.centerIn: this  // H.NAKANO      ボックスタイプの時アイコンが正しく表示されなかった為の対応と思われる
                    // movie ポップアップ以降上にずれる
// 2024 Qt6 対応 end
                }

                /*
                    絞り
                 */
                LTOptionButton {
                    id: btnOptionAperture

                    width: 107
                    height: 77
                    type: "optionWithStyledTextReal"
                    target: "aperture"
// 2024 Qt6 対応 start
                    labelText: qsTr("Aperture")
// 2024 Qt6 対応 end
                    popupTitle: qsTr("Aperture")
                    popup: optionButtonPopup
                    componentsProvider: optionComponentsProvider
                    keepPopupOpen: true
                    fontPixelSize: utilities.isMac() ? 19: 20

                    Connections {
                        target: btnOptionRecordingMode

                        function onValueChanged() {
                            btnOptionAperture.forceClosePopup()
                        }
                    }

                    Connections {
                        target: btnOptionDriveMode

                        function onValueChanged() {
                            btnOptionAperture.forceClosePopup()
                        }
                    }
                }

                /*
                    シャッタースピード
                 */
                LTOptionButton {
                    id: btnOptionShutterSpd

                    width: 107
                    height: 77
                    type: "optionWithStyledSelectedText"
                    target: "shutterSpeed"
// 2024 Qt6 対応 start
                    labelText: qsTr("SS")
// 2024 Qt6 対応 end
                    popupTitle: qsTr("SS")
                    popup: optionButtonPopup
                    componentsProvider: optionComponentsProvider
                    keepPopupOpen: true
                    fontPixelSize: utilities.isMac() ? 19: 20

                    Connections {
                        target: btnOptionRecordingMode

                        function onValueChanged() {
                            btnOptionShutterSpd.forceClosePopup()
                        }
                    }

                    Connections {
                        target: btnOptionDriveMode

                        function onValueChanged() {
                            btnOptionShutterSpd.forceClosePopup()
                        }
                    }
                }

                /*
                    ドライブモード driveModeIcon
                 */
                LTOptionDriveModeButton {
                    id: btnOptionDriveMode

                    width: 107
                    height: 77
                    type: "optionWithImage"
                    labelText: qsTr("Drive Mode")
                    //source: driveModeIcon
                    target: "driveMode"
                    driveModePopup: optionButtonDriveModePopup
                    generalPopup: optionDriveModeButtonPopup
                    selfTimerPopup: optionButtonSelfTimerPopup
                    componentsProvider: optionComponentsProvider
                    keepPopupOpen: true
                }

                /*
                    ホワイトバランス
                 */
                LTOptionButton {
                    id: btnOptionWhiteBalance

                    width: 107
                    height: 77
                    type: "optionWithImage"
                    labelText: qsTr("WB")
                    popupTitle: qsTr("WB")
                    target: "whiteBalance"
                    popup: optionButtonPopup
                    componentsProvider: optionComponentsProvider
                }

                /*
                    ISO
                 */
                LTOptionButton {
                    id: btnOptionIso

                    width: 107
                    height: 77
                    //type: "optionWithImage"
                    type: "optionWithStyledTextReal"
                    labelText: qsTr("ISO")
                    popupTitle: qsTr("ISO")
                    target: "iso"
                    popup: optionButtonPopup
                    componentsProvider: optionComponentsProvider
                    keepPopupOpen: true
                    fontPixelSize: utilities.isMac() ? 19: 20

                    Connections {
                        target: btnOptionRecordingMode

                        function onValueChanged() {
                            btnOptionIso.forceClosePopup()
                        }
                    }

                    Connections {
                        target: btnOptionDriveMode

                        function onValueChanged() {
                            btnOptionIso.forceClosePopup()
                        }
                    }
                }
            }
        }

        //Item {
        //    //visible: !compact
        //    //anchors {
        //    //    left: parent.left
        //    //    right: parent.right
        //    //}
        //    width: minimumWidth
        //    height: 1
        //
        /*
            背景
         */
//        Rectangle {
//            //anchors {
//            //    fill: parent
//            //}
//            width: minimumWidth
//            height: 1
//            color: palette.backgroundLight
//        }
        //}

        //Slider
        //Item {
        //    //visible: !compact
        //    //anchors {
        //    //    left: parent.left
        //    //    right: parent.right
        //    //}
        //    width: minimumWidth
        //    height: 74
        //
        //    /*
        //        背景
        //     */
        Rectangle {
            //anchors {
            //    fill: parent
            //}
            width: minimumWidth
            height: 74
            color: palette.backgroundDark

            /*
                露出補正　フラッシュ光量設定 流用
             */
            Rectangle {
                y:0
                x:1
                width: 107*3+2//310
                height: 74
                color: palette.backgroundDark

                LTFlashSlider {
                    id: sliderExposure

                    anchors.fill: parent

                    optionText: qsTr("Exposure")
                    type: slider_type_exposure
                    windowType: slider_window_main
                    target: "exposureVal"

                    onValueChanged: {
                        ltLog.log(LT.TagDef.RecLvl_Info,
                                  LT.TagDef.RTScr_Usage_Main_Exposure,
                                  "ExposureValueChanged",
                                  sliderExposure.value);
                    }
                }
            }
        }

        //Item {
        //    //visible: !compact
        //    //anchors {
        //    //    left: parent.left
        //    //    right: parent.right
        //    //}
        //    width: minimumWidth
        //    height: 1
        //
        //    /*
        //        背景
        //     */
//        Rectangle {
//            //anchors {
//            //    fill: parent
//            //}
//            width: minimumWidth
//            height: 1
//            color: palette.backgroundLight
//        }

        //The second panel
        //Item {
        //    //visible: !compact
        //    //anchors {
        //    //    left: parent.left
        //    //    right: parent.right
        //    //}
        //    width: minimumWidth
        //    height: 77 * 3 + 2
        //
        //    /*
        //        背景
        //     */
        Rectangle {
            //anchors {
            //    fill: parent
            //}
            id : secMainRec
            width: minimumWidth
            height: 77 * 3 + 2
            color: palette.backgroundLight
            /*
                隙間ぬりつぶし
             */
//            Rectangle {
//                x: 216
//                y: 157
//                width: 107
//                height: 77
//                color: palette.backgroundDark
//            }

            Grid {
                columns: 3
                rows: 3
                spacing: 1

                /*
                    記録画素数
                 */
                LTOptionButton {
                    id: pictureSizeButton
                    width: 107
                    height: 77
                    //type: "optionWithImage"
                    type: "optionWithStyledTextPictureSize"
                    labelText: qsTr("Picture Size")
                    popupTitle: qsTr("Picture Size")
                    target: "pictureSize"
                    popup: optionButtonPopup
                    componentsProvider: optionComponentsProvider
                }

                /*
                    クオリティ
                 */
                LTOptionButton {
                    id: btnOptionImgInfoQuality

                    width: 107
                    height: 77
                    type: "optionWithImage"
                    labelText: qsTr("Picture Quality")
                    popupTitle: qsTr("Picture Quality")
                    target: "imgInfoQuality"
                    popup: optionButtonPopup
                    componentsProvider: optionComponentsProvider
                }

                /*
                    動画画質設定
                 */
// IVC >> MC893 >> start >> No.1
                LTOptionMovieQualityButton {
                    id: movieConfigQualityButton
                    width: 107
                    height: 77
                    type: "optionDetailWithImagePopup"
                    labelText: qsTr("Motion Picture Quality")
                    popupTitle: qsTr("Motion Picture Quality")
                    target: "recMovie"
                    popup: movieQualityPopup
                    componentsProvider: movieQualityComponentsProvider

                    popupX: root.x+root.width/2
                    popupY: root.y+root.height/2
                    keepPopupOpen: true
                    isDetail: true

                    onClicked: {
                        if (!movieQualityPopup.visible) {
                            movieConfigQualityButton.virtualX = root.screen.virtualX
                            movieConfigQualityButton.virtualY = root.screen.virtualY

                            movieConfigQualityButton.clickCustomSub()
                        } else {
                            movieQualityPopup.dismiss()
                        }
                    }
                }
// IVC << MC893 << end << No.1
                /*
                    フォーカスモード
                 */
                LTOptionButton {
                    id: btnOptionFocusMode

                    width: 107
                    height: 77
                    type: "optionWithImage"
                    labelText: qsTr("Focus Mode")
                    popupTitle: qsTr("Focus Mode")
                    target: "focusMode"
                    popup: optionButtonPopup
                    componentsProvider: optionComponentsProvider
                    // IVC >> Ver.1.9 >> start >> [THRBOXV100-41]
                    //optionOpen: false
                    // IVC << Ver.1.9 << end << [THRBOXV100-41]
                }

                /*
                    AF モード
                 */
                LTOptionButton {
                    id: btnOptionAutoFocusMode

                    width: 107
                    height: 77
                    type: "optionWithImage"
                    labelText: qsTr("AF Mode")
                    popupTitle: qsTr("AF Mode")
                    target: "autoFocusMode"
                    popup: optionButtonPopup
                    componentsProvider: optionComponentsProvider
                }

                /*
                    フォトスタイル
                 */
                LTOptionButton {
                    id: btnOptionPhotoStyle
                    width: 107
                    height: 77

                    type: "optionWithImagePopup"
                    labelText: qsTr("Photo Style")
                    popupTitle: qsTr("Photo Style")

                    target: "photoStyle"
                    componentsProvider: optionComponentsProvider
                    popup: photoStylePopup
                    popupX: root.x+root.width/2
                    popupY: root.y+root.height/2
                    keepPopupOpen: true
                    // IVC >> Ver.1.9 >> start >> [THRBOXV100-95]
                    //MC551初期の対応で、フォトスタイル1つの時に押せないように強制してたのは問題なので変更
                    isDetail: true
                    //isDetail: false
                    // IVC << Ver.1.9 << end << [THRBOXV100-95]
                    onClicked: {
                        if (!photoStylePopup.visible) {
                            btnOptionPhotoStyle.virtualX = root.screen.virtualX
                            btnOptionPhotoStyle.virtualY = root.screen.virtualY

                            btnOptionPhotoStyle.clickCustomSub()
                        } else {
                            photoStylePopup.dismiss()
                        }
                    }

                    function onPopupOkClicked() {
                    }

                    function onPopupCancelClicked() {
                    }
                }

                /*
                    測光モード
                 */
                LTOptionButton {
                    id: btnOptionMeteringMode

                    width: 107
                    height: 77
                    type: "optionWithImage"
                    labelText: qsTr("Metering Mode")
                    popupTitle: qsTr("Metering Mode")
                    target: "meteringMode"
                    popup: optionButtonPopup
                    componentsProvider: optionComponentsProvider
                }

                /*
                    WB 色温度
                 */
                LTOptionButton {
                    id: btnOptionWBKSet

                    width: 107
                    height: 77
                    type: "optionWithStyledSelectedText"
                    labelText: qsTr("WB Color Temp.")
                    popupTitle: qsTr("WB Color Temp.")
                    target: "whiteBalanceKSet"
                    popup: optionButtonPopup
                    componentsProvider: optionComponentsProvider
                }

                /*
                    WB 微調整

                    カラーピッカーで指定 ?
                 */
                LTRectangleButton {
                    id: btnWBAdjust
                    width: 107
                    height: 77

                    type: "optionWithStyledSelectedText"
                    labelText: qsTr("WB Tuning")

                    fillColor: palette.backgroundDark

                    //log info
                    logCol: ltLog
                    logScrTagID: LT.TagDef.RTScr_Usage_Main_WBTuning
                    logFile: "WBTuning"

                    onClicked: {
                        if (!wbAdjustPopup.visible) {
                            wbAdjustPopup.present(
                                root.x+root.width/2,
                                root.y+root.height/2,
                                root.screen.virtualX,
                                root.screen.virtualY,
                                // onOkSelected
                                function (object) {
                                    //wbAdjustSettingText()
                                },
                                // onCancelSelected
                                function (object) {
                                    //wbAdjustSettingText()
                                },
                                // onResetSelected
                                function (object) {
                                    //wbAdjustSettingText()
                                }
                                );
                        } else {
                            wbAdjustPopup.dismiss();
                        }
                    }

                    function onPopupOkClicked() {
                        LTSubFunction.console_debug.out("onPopupOkClicked ab=" + wbAdjustPopup.valAB + " gm=" + wbAdjustPopup.valGM)
                        if( (deviceAdapter.recordingMode == LT.Utilities.RM_IntelligentAuto) &&
                            (deviceAdapter.intelligentAutoMode == LT.Utilities.RM_IA_IntelligentAutoPlus) ){
                            deviceAdapter.wbAdjustABSep = wbAdjustPopup.valAB;
                            if(deviceAdapter.wbAdjustABSep != wbAdjustPopup.valAB) {
                                wbAdjustPopup.valAB = deviceAdapter.wbAdjustABSep
                            }
                        } else {
                            LTSubFunction.console_debug.out("onPopupOkClicked 1")
                            //deviceAdapter.wbAdjustAB = wbAdjustPopup.valAB;
                            //if(deviceAdapter.wbAdjustAB == wbAdjustPopup.valAB) {
                            //    console.debug("onPopupOkClicked 2")
                            //    deviceAdapter.wbAdjustGM = wbAdjustPopup.valGM;
                            //}
                            //if((deviceAdapter.wbAdjustAB != wbAdjustPopup.valAB)||(deviceAdapter.wbAdjustGM != wbAdjustPopup.valGM)) {
                            //    console.debug("onPopupOkClicked 3")
                            //    wbAdjustPopup.valAB = deviceAdapter.wbAdjustAB
                            //    wbAdjustPopup.valGM = deviceAdapter.wbAdjustGM
                            //}
                            deviceAdapter.setWbAdjust(wbAdjustPopup.valAB, wbAdjustPopup.valGM);
                        }
                        wbAdjustSettingText()

						ltLog.log(LT.TagDef.RecLvl_Info,
                                  LT.TagDef.RTScr_Usage_Main_WBTuning,
                                  "wbAdjustPopup OK",
                                  wbAdjustPopup.valueWBAdjustTextFormat());
                    }

					function onPopupCancelClicked() {
                        if( (deviceAdapter.recordingMode == LT.Utilities.RM_IntelligentAuto) &&
                            (deviceAdapter.intelligentAutoMode == LT.Utilities.RM_IA_IntelligentAutoPlus) ){
                            deviceAdapter.wbAdjustABSep = wbAdjustPopup.valAB;
                        } else {
                            deviceAdapter.wbAdjustAB = wbAdjustPopup.valAB;
                            deviceAdapter.wbAdjustGM = wbAdjustPopup.valGM;
                        }
                        wbAdjustSettingText()

                        ltLog.log(LT.TagDef.RecLvl_Info,
                                  LT.TagDef.RTScr_Usage_Main_WBTuning,
                                  "wbAdjustPopup Cancel",
                                  wbAdjustPopup.valueWBAdjustTextFormat());
					}

                    function onPopupResetClicked() {
                        if( (deviceAdapter.recordingMode == LT.Utilities.RM_IntelligentAuto) &&
                            (deviceAdapter.intelligentAutoMode == LT.Utilities.RM_IA_IntelligentAutoPlus) ){
                            deviceAdapter.wbAdjustABSep = wbAdjustPopup.valAB;
                        } else {
                            deviceAdapter.wbAdjustAB = wbAdjustPopup.valAB;
                            deviceAdapter.wbAdjustGM = wbAdjustPopup.valGM;
                        }
                        wbAdjustSettingText()

                        ltLog.log(LT.TagDef.RecLvl_Info,
                                  LT.TagDef.RTScr_Usage_Main_WBTuning,
                                  "wbAdjustPopup Reset",
                                  wbAdjustPopup.valueWBAdjustTextFormat());
                    }

                    function onPopupChangeValue() {
                        if( (deviceAdapter.recordingMode == LT.Utilities.RM_IntelligentAuto) &&
                            (deviceAdapter.intelligentAutoMode == LT.Utilities.RM_IA_IntelligentAutoPlus) ){
                            deviceAdapter.wbAdjustABSep = wbAdjustPopup.valAB;
                        } else {
                            //deviceAdapter.wbAdjustAB = wbAdjustPopup.valAB;
                            //if(deviceAdapter.wbAdjustAB == wbAdjustPopup.valAB) {
                            //    deviceAdapter.wbAdjustGM = wbAdjustPopup.valGM;
                            //}
                            deviceAdapter.setWbAdjust(wbAdjustPopup.valAB, wbAdjustPopup.valGM);
                        }
                        wbAdjustSettingText()

                        ltLog.log(LT.TagDef.RecLvl_Info,
                                  LT.TagDef.RTScr_Usage_Main_WBTuning,
                                  "wbAdjustPopup ChangeValue",
                                  wbAdjustPopup.valueWBAdjustTextFormat());
                    }
                }
            }
        }

        //Item {
        //    //visible: !compact
        //    //anchors {
        //    //    left: parent.left
        //    //    right: parent.right
        //    //}
        //    width: minimumWidth
        //    height: 1
        //
        //    /*
        //        背景
        //     */
//        Rectangle {
//            //anchors {
//            //    fill: parent
//            //}
//            width: minimumWidth
//            height: 1
//            color: palette.backgroundLight
//        }

        //4K6Kフォト設定はドライブモードで行うため削除
        //The third panel
        //Item {
        //    visible: !compact
        //    anchors {
        //        left: parent.left
        //        right: parent.right
        //    }
        //    y: 0
        //    height: 28 * 1 + 3
        //
        //    /*
        //        背景
        //     */
        //    Rectangle {
        //        anchors {
        //            fill: parent
        //        }
        //        color: palette.backgroundLight
        //    }
        //
        //    /*
        //        隙間ぬりつぶし
        //     */
        //    Rectangle {
        //        x: 0
        //        y: 29
        //        width: root.width
        //        height: 96
        //        color: palette.backgroundDark
        //    }
        //
        //    Grid {
        //        columns: 1
        //        rows: 1
        //        spacing: 1
        //
        //        /*
        //            4K6K フォト設定
        //         */
        //        LTOptionButton {
        //            width: root.width
        //            height: 28
        //            type: "optionWithText"
        //            labelText: qsTr("4K6K Photo")
        //            target: "picture4K6K"
        //            popup: optionButtonPopup
        //            componentsProvider: optionComponentsProvider
        //        }
        //
        //    }
        //}

        //flash panel
        //Item {
        //    //visible: !compact
        //    //anchors {
        //    //    left: parent.left
        //    //    right: parent.right
        //    //}
        //    width: minimumWidth
        //    height: 36 + 2 + 2
        //
        //    /*
        //        背景
        //     */
        Rectangle {
            //anchors {
            //    fill: parent
            //}
            width: minimumWidth
            height: 36 + 2 + 2
            color: palette.backgroundDark;

            /*
                フラッシュ
             */
            LTRectangleButton {
                id: flashButton
                x: 2
                y: 2 + 1
                width: 158
                height: 36
                buttonText: qsTr("Flash")
                toolTipText: qsTr("Flash")
                type: "action"
                fillColor: palette.backgroundLight

                logCol: ltLog
                logScrTagID: LT.TagDef.RTScr_Usage_Main_FlashWindow
                logFile: "Flash"

                onClicked: {
                    root.toggleFlashView();
                }
            }

            /*
                環境設定
             */
            LTRectangleButton {
                id: settingButton
                x: 163
                y: 2 + 1
                width: 158
                height: 36
                buttonText: qsTr("Preferences")
                toolTipText: qsTr("Preferences")
                type: "action"
                fillColor: palette.backgroundLight

                logCol: ltLog
                logScrTagID: LT.TagDef.RTScr_Usage_Main_PreferenceWindow
                logFile: "Preferences"

                onClicked: {
                    root.togglePreferenceView();
                }
            }
        }
        //expand panel
        Item {
            //anchors {
            //    left: parent.left
            //    right: parent.right
            //}
            width: minimumWidth
            height: 19 + 2
        }
    }
    //expand panel
    Item {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: 19 + 2

        /*
            背景
         */
        Rectangle {
            anchors {
                fill: parent
            }
            color: palette.backgroundDark;
        }

        /*
            ウィンドウサイズ
         */
        LTRectangleButton {
            id: windowsizebutton
            x: 0
            y: 2
            width: root.width
            height: 19
            source: compact ? "qrc:/images/button_expand.svg" : "qrc:/images/button_shrink.svg"
            fillColor: palette.backgroundLight

            logCol: ltLog
            logScrTagID: LT.TagDef.RTScr_Usage_Main_ExpandWindow
            logFile: "Expand"

            onClicked: {
                if(!animation_timer.mode) {
                    if(root.height == normalHeight) {
                        animation_timer.mode = animation_timer.mode_compact
                        root.minimumHeight = compactHeight
                        windowsizebutton.disabled = true
                        compact = true;
                    } else if(root.height == compactHeight) {
                        animation_timer.mode = animation_timer.mode_normal
                        root.maximumHeight = normalHeight
                        windowsizebutton.disabled = true
                        compact = false;
                    }
                    applicationSettings.windowSize = compact ? LT.ApplicationSettings.WindowShrinked : LT.ApplicationSettings.WindowExpanded;
                    //root.height = compact ? compactHeight : normalHeight;
                    animation_timer.running = true
                }
            }
        }
    }
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
        readonly property int mode_live_view_menu : 8 //ライブビューMENU中
        readonly property int mode_searchWindow: 16 //起動カメラウインド
        readonly property int mode_Connecting: 32 //カメラ接続中

        visible: false
        anchors {
            fill: parent
        }
        color: "#000000"
        opacity: 0.5
        MouseArea {
            anchors {
                fill: parent
            }
            hoverEnabled: true
            onClicked: {
// IVC >> MC893 >> start >> No.1
                if (movieQualityPopup.visible) {
                    movieQualityPopup.dismiss()
                }
// IVC << MC893 << end << No.1
                //root.dismiss();
            }
        }
    }
}
