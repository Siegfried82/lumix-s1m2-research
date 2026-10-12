import QtQuick 2.6
import QtQuick.Controls.Basic 2.0

import "qrc:/qml"
import LT 1.0 as LT
import "LTSubFunction.js" as LTSubFunction

/*! \qmltype LTLiveViewControlItem
    \inqmlmodule LT

    \brief
    LiveView 操作パネルです
 */
Item {
    id: root

    /*!
        WB 設定のチェック状態です
     */
    property alias wbSettingsChecked: wbSettingsButton.checked

    /*!
        AF 枠表示のチェック状態です
     */
    property alias afAreaChecked: afAreaButton.checked

    /*!
        ワンショット AF のチェック状態です
     */
    property alias oneShotAFChecked: oneShotAFButton.checked

    /*!
        プレビューのチェック状態です
     */
//    property alias previewChecked: previewButton.checked

    /*!
        水準器のチェック状態です
     */
    property alias levelIndicatorChecked: levelIndicatorButton.checked

    /*!
        グリッドのチェック状態です
     */
    property alias gridChecked: gridButton.checked

    /*!
        ガイドラインのチェック状態です
     */
    property alias guidelineChecked: guidelineButton.checked

    /*!
        ヒストグラムのチェック状態です
     */
    property alias histogramChecked: histogramButton.checked

    /*!
        MF 拡大のチェック状態です
     */
    property alias mfZoomChecked: mfZoom.checked

    //property bool afaeStartFlg: false

    // ivc >> start >> No.1
    property alias overlayButtonAlias: overlayButton
    // ivc << end << No.1

    signal guidelineSetting()
    signal gridSetting()
    // ivc >> start >> No.1
    signal overlaySetting()
    // ivc << end << No.1
    signal guidelinePopupClose()
    signal gridPopupClose()
    // ivc >> start >> No.1
    signal overlayPopupClose()
    // ivc << end << No.1

    // IVC >> Ver.1.7 >> start >> No.1
    property bool isDisplayImgQuality: false
    // IVC << Ver.1.7 << end << No.1

    // IVC >> Ver.1.9 >> start >> No.2
    property bool afAreaEnabled_Save: false
    property bool oneShotAFEnabled_Save: false
    property bool overlayButtonEnabled_Save: false
    
    property bool wbSettingsChecked_Save: false
    property bool afAreaChecked_Save: false
    property bool oneShotAFChecked_Save: false
    property bool levelIndicatorChecked_Save: false
    property bool gridChecked_Save: false
    property bool guidelineChecked_Save: false
    property bool histogramChecked_Save: false
    property bool mfZoomChecked_Save: false
    // IVC >> Ver.1.9 >> start >> [THRBOXV100-77]
    property bool overlayButtonChecked_Save: false
    // IVC << Ver.1.9 << end << [THRBOXV100-77]
    // IVC >> Ver.1.9 >> start >> [THRBOXV100-141]
    property bool isMenuBtnChecked: false
    // IVC << Ver.1.9 << end << [THRBOXV100-141]
    // IVC << Ver.1.9 << end << No.2
    property bool isZoomCtrlEnable: false
    property bool zoomStartFlg: false

    property int lv_rotation_Save: 0
    property bool lv_rotation_mode_Save: false
    property double lvOverlayPhotoRotation_Save: 0

    readonly property int btnHeight_normal: 27

    Component.onCompleted: {
        //Adapter connect
        deviceAdapter.aspectRatioChanged.connect(root.aspectRatioSetting);
        deviceAdapter.aspectRatioFlgNumChanged.connect(root.aspectRatioSetting);

        // IVC >> Ver.1.7 >> start >> No.1
        deviceAdapter.displayImgQualityChanged.connect(root.imgQualitySetting);
        deviceAdapter.imgQualityChanged.connect(root.imgQualitySetting);
        // IVC << Ver.1.7 << end << No.1
        // IVC >> Ver.1.9 >> start >> No.1
        deviceAdapter.camConnectStatusChanged.connect(root.connectCameraSetting);
        // IVC << Ver.1.9 << end << No.1
        deviceAdapter.zoomLensCtrlEnableChanged.connect(root.zoomLensCtrlEnableSetting);
        deviceAdapter.zoomLensTeleChanged.connect(root.zoomLensTeleSetting);
        deviceAdapter.zoomLensWideChanged.connect(root.zoomLensWideSetting);
        deviceAdapter.zoomLensLenChanged.connect(root.zoomLensLenSetting);
        deviceAdapter.btnAllCameraStatusChanged.connect(root.btnAllCameraStatusChanged);
        deviceAdapter.isMultiviewModeChanged.connect(root.isMultiviewModeChanged);

    }

    signal af_dispframeClicked()
//    signal mf_zoomClicked()
    signal afFramePointScopeEnd()

    /*!
        Call option popup
     */

    // ivc >> start >> No.1
    function updateSliderXY() {
        // ivc >> start >> USBTHRV140-35
//        lvOverlayPhotoPopupAlias.sliderPosXalias.value = lvOverlayPhotoPosX/calcuratio()
//        lvOverlayPhotoPopupAlias.sliderPosYalias.value = lvOverlayPhotoPosY/calcuratio()
//        lvOverlayPhotoSliderOldPosX = lvOverlayPhotoPopupAlias.sliderPosXalias.value
//        lvOverlayPhotoSliderOldPosY = lvOverlayPhotoPopupAlias.sliderPosYalias.value
//        console.log("Before lvOverlayPhotoPopupAlias.spinBoxPosXalias.value:" + lvOverlayPhotoPopupAlias.spinBoxPosXalias.value)
//        console.log("lvOverlayPhotoPosX:" + lvOverlayPhotoPosX)
//        console.log("calcuratio()" + calcuratio())
        lvOverlayPhotoPopupAlias.spinBoxPosXalias.value = lvOverlayPhotoPosX/calcuratio()
//        console.log("After lvOverlayPhotoPopupAlias.spinBoxPosXalias.value:" + lvOverlayPhotoPopupAlias.spinBoxPosXalias.value)
        lvOverlayPhotoPopupAlias.spinBoxPosYalias.value = lvOverlayPhotoPosY/calcuratio()
        lvOverlayPhotoSpinBoxOldPosX = lvOverlayPhotoPopupAlias.spinBoxPosXalias.value
        lvOverlayPhotoSpinBoxOldPosY = lvOverlayPhotoPopupAlias.spinBoxPosYalias.value
        // ivc << end << USBTHRV140-35
        lvOverlayPhotoFrameOldHeight = lvOverlayPhotoFrameOldHeight * imageLV.paintedWidth/lvOverlayPhotoOldPaintedWidth
        lvOverlayPhotoFrameOldWidth = lvOverlayPhotoFrameOldWidth * imageLV.paintedHeight/lvOverlayPhotoOldPaintedHeight
    }

    function updateOldxy() {
        lvOverlayPhotoFrameOldPosY = overlayPhotoFrame.y
        lvOverlayPhotoFrameOldPosX = overlayPhotoFrame.x
    }

    function updatePhotoFrameXY() {
        if(calcuratio() != 0) {
            lvOverlayPhotoFlagChangeXY = 1
            if(lv_rotation_mode) {
                if(lv_rotation_auto % 180 != 0) {
                    overlayPhotoFrame.x = imageLV.x + imageLV.width / 2 -overlayPhotoFrame.width / 2
                    overlayPhotoFrame.y = imageLV.y + imageLV.height / 2 -overlayPhotoFrame.height /2
                    updateSliderXY()
                    updateOldxy()
                }
            } else {
                var oldlvOverlayPhotoPosX = 0
                if(lv_rotation == 270) {
                    overlayPhotoFrame.x = imageLV.x + imageLV.width / 2 -  overlayPhotoFrame.width / 2 - lvOverlayPhotoPosY * imageLV.paintedHeight / lvOverlayPhotoOldPaintedHeight
                    overlayPhotoFrame.y = imageLV.y + imageLV.height / 2 - overlayPhotoFrame.height / 2 - lvOverlayPhotoPosX * imageLV.paintedWidth / lvOverlayPhotoOldPaintedWidth
                    lvOverlayPhotoPosX = lvOverlayPhotoPosX * imageLV.paintedWidth/lvOverlayPhotoOldPaintedWidth
                    lvOverlayPhotoPosY = lvOverlayPhotoPosY * imageLV.paintedHeight/lvOverlayPhotoOldPaintedHeight
                    updateSliderXY()
                    lvOverlayPhotoOldPaintedHeight = imageLV.paintedHeight
                    lvOverlayPhotoOldPaintedWidth = imageLV.paintedWidth
                    updateOldxy()
                } else if(lv_rotation == 180||lv_rotation == -180) {
                    lvOverlayPhotoPosX = lvOverlayPhotoPosX * imageLV.paintedWidth / lvOverlayPhotoOldPaintedWidth
                    lvOverlayPhotoPosY = lvOverlayPhotoPosY * imageLV.paintedHeight / lvOverlayPhotoOldPaintedHeight
                    updateSliderXY()
                    lvOverlayPhotoOldPaintedHeight = imageLV.paintedHeight
                     lvOverlayPhotoOldPaintedWidth = imageLV.paintedWidth
                    overlayPhotoFrame.x = imageLV.x + imageLV.width / 2 - overlayPhotoFrame.width / 2 - lvOverlayPhotoPosX
                    overlayPhotoFrame.y = imageLV.y + imageLV.height / 2 - overlayPhotoFrame.height / 2 + lvOverlayPhotoPosY
                    updateOldxy()
                } else if(lv_rotation == 90) {
                    overlayPhotoFrame.x = imageLV.x + imageLV.width / 2 - overlayPhotoFrame.width / 2 + lvOverlayPhotoPosY * imageLV.paintedHeight / lvOverlayPhotoOldPaintedHeight
                    overlayPhotoFrame.y = imageLV.y + imageLV.height / 2 - overlayPhotoFrame.height / 2 + lvOverlayPhotoPosX * imageLV.paintedWidth / lvOverlayPhotoOldPaintedWidth
                    lvOverlayPhotoPosX = lvOverlayPhotoPosX * imageLV.paintedWidth/lvOverlayPhotoOldPaintedWidth
                    lvOverlayPhotoPosY = lvOverlayPhotoPosY * imageLV.paintedHeight/lvOverlayPhotoOldPaintedHeight
                    updateSliderXY()
                    lvOverlayPhotoOldPaintedHeight = imageLV.paintedHeight
                    lvOverlayPhotoOldPaintedWidth = imageLV.paintedWidth
                    updateOldxy()
                }
            }

            if(lv_rotation == 0) {
                lvOverlayPhotoPosX = lvOverlayPhotoPosX * imageLV.paintedWidth/lvOverlayPhotoOldPaintedWidth
                lvOverlayPhotoPosY = lvOverlayPhotoPosY * imageLV.paintedHeight/lvOverlayPhotoOldPaintedHeight
                updateSliderXY()
                lvOverlayPhotoOldPaintedHeight = imageLV.paintedHeight
                lvOverlayPhotoOldPaintedWidth = imageLV.paintedWidth
                overlayPhotoFrame.x = imageLV.width / 2 - overlayPhotoFrame.width / 2 + lvOverlayPhotoPosX
                overlayPhotoFrame.y = imageLV.height / 2 - overlayPhotoFrame.height / 2 - lvOverlayPhotoPosY
                updateOldxy()
            }
            lvOverlayPhotoFlagChangeXY = 0
        }
    }
    // ivc << end << No.1


    function showOptionPopup(btn, componentsProvider, target, popup) {
        var components = componentsProvider[target];
        var capability = deviceAdapter[target+"Capability"];
        for (var i = 0; i < components.length; ++i) {
            if (capability(components[i].properties.value) == LT.DeviceAdapter.Ternary_True) {
                components[i].properties.capable = true;
                components[i].properties.checked = (components[i].properties.value == btn.value);
            } else {
                components[i].properties.capable = false;
                components[i].properties.checked = false;
            }
        }

        var point = rootColumn.mapFromItem(btn, btn.x, btn.y);

        popup.present(
            point.x + btn.x,
            point.y + btn.y,
            componentsProvider[target],
            target,
            function(object) {
                btn.value = object.value;
                btn.source = object.source;
                popup.dismiss();
            });
    }

    function cameraValueGetComplete() {
        LTSubFunction.console_debug.out("LiveviewControlItem::cameraValueGetComplete")
        setMFText()
        setMFScale()
        setMFZoom(false)
        aspectRatioSetting()
        recPreviewSetting()
        // IVC >> Ver.1.7 >> start >> No.1
        imgQualitySetting()
        // IVC << Ver.1.7 << end << No.1
        columnsSetting()
        zoomLensCtrlEnableSetting()
        zoomLensTeleSetting()
        zoomLensWideSetting()
        zoomLensLenSetting()
    }

    // IVC >> Ver.1.7 >> start >> No.1
    function imgQualitySetting() {
        isDisplayImgQuality = deviceAdapter.displayImgQuality;
        if (isDisplayImgQuality) {
            btnOptionLvImgQuality.optionSelect(deviceAdapter.imageQuality);
        }
    }
    // IVC << Ver.1.7 << end << No.1

    // IVC >> Ver.1.9 >> start >> No.1
    function connectCameraSetting() {
        if(deviceAdapter.camConnectStatus == LT.Utilities.CamConnectSts_Connecting) {
            // show Panel Mask
            if(deviceAdapter.isMultiviewMode === false){
                maskpanel.isFillAll = true;
                maskPanelOpen();
            }
        }
        else if(deviceAdapter.camConnectStatus == LT.Utilities.CamConnectSts_Unknown ||
                deviceAdapter.camConnectStatus == LT.Utilities.CamConnectSts_Success ||
                deviceAdapter.camConnectStatus == LT.Utilities.CamConnectSts_SuccessBackground
                ) {
            // hide Panel Mask
            if(deviceAdapter.isMultiviewMode === false){
                maskpanel.isFillAll = true;
                maskPanelClose();
            }
        }
    }
    // IVC << Ver.1.9 << end << No.1

    function setMFText() {
        if(deviceAdapter.cameraStatus === LT.Utilities.CamStatus_Menu_Displayed ||
           deviceAdapter.cameraStatus === LT.Utilities.CamStatus_IP_LiveStreaming ||
           deviceAdapter.cameraStatus === LT.Utilities.CamStatus_LiveStreamingRemoteRec ||
           deviceAdapter.isMultiviewMode === true){
            // MENU表示、マルチ表示中
            return
        }

        var mf_text = true
        var mf_flg = false
        switch(deviceAdapter.focusMode) {
        case LT.Utilities.FM_MF://               = 3,
            mf_flg = true
            break;
// IVC >> Ver.1.9 >> start >> [THRBOXV100-83]
        case LT.Utilities.FM_AF://               = 0,
// IVC << Ver.1.9 << end << [THRBOXV100-83]
        case LT.Utilities.FM_AF_S://             = 4,
        case LT.Utilities.FM_AF_F://             = 5,
            switch(deviceAdapter.autoFocusMode) {
            //case LT.Utilities.AFM_Pinpoint://    ,
            //    mf_text = false
            //    mf_flg = true
            //    break;
            //case LT.Utilities.AFM_Unknown:// = -1,
            case LT.Utilities.AFM_1Point://      ,
            case LT.Utilities.AFM_Face://        ,
            case LT.Utilities.AFM_Tracking://    ,
            case LT.Utilities.AFM_225Point://    ,
            case LT.Utilities.AFM_CustomVertical:// ,
            case LT.Utilities.AFM_CustomHorizon:// ,
            case LT.Utilities.AFM_CustomCenter:// ,
            case LT.Utilities.AFM_CustomC1:// ,
            case LT.Utilities.AFM_CustomC2:// ,
            case LT.Utilities.AFM_CustomC3:// ,
            case LT.Utilities.AFM_Pinpoint:// ,
            // ivc >> start >> No.3 -> nakhuong
            case LT.Utilities.AFM_1PointAux:// ,
            case LT.Utilities.AFM_VertHori:// ,
            case LT.Utilities.AFM_Square:// ,
            case LT.Utilities.AFM_Ellipse:// ,
            case LT.Utilities.AFM_Custom1:// ,
            case LT.Utilities.AFM_Custom2:// ,
            case LT.Utilities.AFM_Custom3:// ,
            // ivc << end << No.3 <- nakhuong
            case LT.Utilities.AFM_FullArea:
            //case LT.Utilities.AFM_Max://
                if(afaeStartFlg) {
                    mf_flg = true
                } else {
                    mf_flg = false
                }
                break;
            }
            break;
        case LT.Utilities.FM_AF_C://             = 6,
            switch(deviceAdapter.autoFocusMode) {
            //case LT.Utilities.AFM_Pinpoint://    ,
            //case LT.Utilities.AFM_Unknown:// = -1,
            case LT.Utilities.AFM_1Point://      ,
            case LT.Utilities.AFM_Face://        ,
            case LT.Utilities.AFM_Tracking://    ,
            case LT.Utilities.AFM_225Point://    ,
            case LT.Utilities.AFM_CustomVertical:// ,
            case LT.Utilities.AFM_CustomHorizon:// ,
            case LT.Utilities.AFM_CustomCenter:// ,
            case LT.Utilities.AFM_CustomC1:// ,
            case LT.Utilities.AFM_CustomC2:// ,
            case LT.Utilities.AFM_CustomC3:// ,
            case LT.Utilities.AFM_Pinpoint:// ,
            // ivc >> start >> No.3 -> nakhuong
            case LT.Utilities.AFM_1PointAux:// ,
            case LT.Utilities.AFM_VertHori:// ,
            case LT.Utilities.AFM_Square:// ,
            case LT.Utilities.AFM_Ellipse:// ,
            case LT.Utilities.AFM_Custom1:// ,
            case LT.Utilities.AFM_Custom2:// ,
            case LT.Utilities.AFM_Custom3:// ,
            // ivc << end << No.3 <- nakhuong
            case LT.Utilities.AFM_FullArea:
            //case LT.Utilities.AFM_Max://
                if(afaeStartFlg) {
                    mf_flg = true
                } else {
                    mf_flg = false
                }
                break;
            }
            break;
// IVC >> Ver.1.9 >> start >> [THRBOXV100-83]
        //case LT.Utilities.FM_AF://               = 0,
// IVC << Ver.1.9 << end << [THRBOXV100-83]
        case LT.Utilities.FM_AF_Macro://         = 1,
        case LT.Utilities.FM_AF_Macro_Digi://    = 2,
        case LT.Utilities.FM_Unknown://          = -1,
        case LT.Utilities.FM_Max://
        default:
            break;
        }
        //if(mf_text) {
        //    mfZoom.text = qsTr("MF Zoom")
        //} else {
        //    mfZoom.text = qsTr("Pinpoint AF Zoom")
        //}
        if(mf_flg && mf_text) {
            mfadjust.enabled = true
        } else {
            mfadjust.enabled = false
        }
    }
    function setMFZoom(flg) {
        LTSubFunction.console_debug.out("setMFZoom flg=" + flg + " afmode=" + afframe.mode + " af_magnify=" + deviceAdapter.af_magnify)
        if(deviceAdapter.cameraStatus === LT.Utilities.CamStatus_Menu_Displayed ||
           deviceAdapter.cameraStatus === LT.Utilities.CamStatus_IP_LiveStreaming ||
           deviceAdapter.cameraStatus === LT.Utilities.CamStatus_LiveStreamingRemoteRec ||
           deviceAdapter.isMultiviewMode === true){
            // MENU表示、マルチ表示終了時に使用するため保持
            mfZoomChecked_Save = flg
            return
        }

        //------------------------------------------------------
        // mfZoom.enabled設定後にmfZoom.checkedを設定すること。
        // mfZoom.onCheckedChanged()で、設定後のenabled値が必要。
        //------------------------------------------------------
        // 動画LV拡大
        if(deviceAdapter.lvMagEnable &&
//           (deviceAdapter.recordingMode === LT.Utilities.RM_CreativeVideo || deviceAdapter.recordingMode === LT.Utilities.RM_SQMotion)) {
            deviceAdapter.isExpMovieMode()) {
            LTSubFunction.console_debug.out("setMFZoom lvMag")
            mfZoom.enabled = true
            mfZoom.checked = flg;
        }
        else if((!afaeStartFlg)
            && ((afframe.mode == afframe.afmode_pinpoint)
                 || (afframe.mode == afframe.afmode_pinpointf)
                 || (afframe.mode == afframe.afmode_pinpointp)
                 || (afframe.mode == afframe.afmode_pinpointz))) {
//            if (afaeStartFlg && deviceAdapter.afmfMode == LT.Utilities.AFMFM_Off) {
//                LTSubFunction.console_debug.out("setMFZoom pinpoint afae")
//                mfZoom.checked = false
//                mfZoom.enabled = false
//            } else {
                LTSubFunction.console_debug.out("setMFZoom pinpoint")
                mfZoom.enabled = true
                mfZoom.checked = flg;
//            }
        }
        else if( (afframe.mode == afframe.afmode_mf) ||
            (afframe.mode == afframe.afmode_mff) ) {
            LTSubFunction.console_debug.out("setMFZoom mf or mff")
            mfZoom.enabled = true
            mfZoom.checked = false;
        }
        else if( (afframe.mode == afframe.afmode_mfp) ||
            (afframe.mode == afframe.afmode_mfz) ) {
            LTSubFunction.console_debug.out("setMFZoom mfp or mfz")
            mfZoom.enabled = true
            mfZoom.checked = flg;
        }
        else if(afaeStartFlg) {
            LTSubFunction.console_debug.out("setMFZoom afaeStartFlg")
            mfZoom.enabled = true
            mfZoom.checked = flg;
        }
        else if(deviceAdapter.afPointScopeEnable) {
            LTSubFunction.console_debug.out("setMFZoom afPointScopeEnable")
            mfZoom.enabled = true
            mfZoom.checked = flg;
        }
        else {
            LTSubFunction.console_debug.out("setMFZoom else")
            mfZoom.enabled = false
            mfZoom.checked = false
        }
    }
    function setMFScale() {
        LTSubFunction.console_debug.out("setMFScale afmode=" + afframe.mode)
        if( (afframe.mode == afframe.afmode_pinpoint) ||
            (afframe.mode == afframe.afmode_pinpointf) ||
            (afframe.mode == afframe.afmode_pinpointp) ||
            (afframe.mode == afframe.afmode_pinpointz)) {
            LTSubFunction.console_debug.out("setMFScale pinpoint")
            mfZoomText.text = "x" + parseInt(deviceAdapter.af_magnify/10) + "." + deviceAdapter.af_magnify%10
        }
        else if( (afframe.mode == afframe.afmode_mf) ||
                (afframe.mode == afframe.afmode_mff) ||
                (afframe.mode == afframe.afmode_mfp) ||
                (afframe.mode == afframe.afmode_mfz)) {
            mfZoomText.text = "x" + parseInt(deviceAdapter.mf_magnify/10) + "." + deviceAdapter.mf_magnify%10
        }
        else if((afframe.mode == afframe.afmode_lvmag_z) ||
                (afframe.mode == afframe.afmode_lvmag_p)) {
            // 動画LV拡大
            mfZoomText.text = "x" + parseInt(deviceAdapter.lvMag_magnify/10) + "." + deviceAdapter.lvMag_magnify%10
        } else {
            //default
            mfZoomText.text = "x" + parseInt(deviceAdapter.mf_magnify/10) + "." + deviceAdapter.mf_magnify%10
        }
    }
    function aspectRatioSetting() {
        LTSubFunction.console_debug.out("liveviewcontrolitem::aspectRatioSetting aspectRatio=" + deviceAdapter.aspectRatio)
        switch(deviceAdapter.aspectRatio) {
        case LT.DeviceAdapter.AR_Unknown:// = -1,
            break;
        case LT.DeviceAdapter.AR_Nomal_4_3://,           //AR_Nomal_4_3
            btnOptionAspectRatio.optionSelect(LT.DeviceAdapter.AR_Nomal_4_3)
            break;
        case LT.DeviceAdapter.AR_Film_3_2://,  //AR_Film_3_2
            btnOptionAspectRatio.optionSelect(LT.DeviceAdapter.AR_Film_3_2)
            break;
        case LT.DeviceAdapter.AR_Hdtv_16_9://,   //AR_Hdtv_16_9
            btnOptionAspectRatio.optionSelect(LT.DeviceAdapter.AR_Hdtv_16_9)
            break;
        case LT.DeviceAdapter.AR_Blog_1_1://,      //AR_Blog_1_1
            btnOptionAspectRatio.optionSelect(LT.DeviceAdapter.AR_Blog_1_1)
            break;
        case LT.DeviceAdapter.AR_Multi_MULTI://,     //AR_Multi_MULTI
            btnOptionAspectRatio.optionSelect(LT.DeviceAdapter.AR_Multi_MULTI)
            break;
// ivc >> start >> No.7
        case LT.DeviceAdapter.AR_65_24://,     //AR_65_24
            btnOptionAspectRatio.optionSelect(LT.DeviceAdapter.AR_65_24)
            break;
        case LT.DeviceAdapter.AR_2_1://,       //AR_2_1
            btnOptionAspectRatio.optionSelect(LT.DeviceAdapter.AR_2_1)
            break;
// ivc << end << No.7
        case LT.DeviceAdapter.AR_Cinema_4k://,       //AR_Cinema_4k
        case LT.DeviceAdapter.AR_7_5://,          //AR_7_5
        case LT.DeviceAdapter.AR_3_1://,     //AR_3_1
        case LT.DeviceAdapter.AR_Check://,             //AR_Check
        default:
            break;
        }

        ltLog.log(LT.TagDef.RecLvl_Info,
                  LT.TagDef.RTScr_Usage_LiveView_AspectRatio,
                  "aspectRatioSetting",
                  deviceAdapter.aspectRatio);
    }
    function recPreviewSetting() {
        //console.log("recPreviewSetting start");
        btnOptionRecPreview.optionSelect(deviceAdapter.recPreviewMode);
    }

    function setAfAreaButtonCheck(flg) {
        if(deviceAdapter.cameraStatus === LT.Utilities.CamStatus_Menu_Displayed ||
           deviceAdapter.cameraStatus === LT.Utilities.CamStatus_IP_LiveStreaming ||
           deviceAdapter.cameraStatus === LT.Utilities.CamStatus_LiveStreamingRemoteRec ||
           deviceAdapter.isMultiviewMode === true){
            afAreaChecked_Save = flg
        }else{
            afAreaButton.checked = flg
        }
    }

    function setAfAreaButtonEnable(flg) {
        if(deviceAdapter.cameraStatus === LT.Utilities.CamStatus_Menu_Displayed ||
           deviceAdapter.cameraStatus === LT.Utilities.CamStatus_IP_LiveStreaming ||
           deviceAdapter.cameraStatus === LT.Utilities.CamStatus_LiveStreamingRemoteRec ||
           deviceAdapter.isMultiviewMode === true){
            afAreaEnabled_Save = flg
        }else{
            afAreaButton.enabled = flg
        }
    }

    function setOneShotAFButtonCheck(flg) {
        if(deviceAdapter.cameraStatus === LT.Utilities.CamStatus_Menu_Displayed ||
           deviceAdapter.cameraStatus === LT.Utilities.CamStatus_IP_LiveStreaming ||
           deviceAdapter.cameraStatus === LT.Utilities.CamStatus_LiveStreamingRemoteRec ||
           deviceAdapter.isMultiviewMode === true){
            oneShotAFChecked_Save = flg
        }else{
            oneShotAFButton.checked = flg
        }
    }

    function setOneShotAFButtonEnable(flg) {
        if(deviceAdapter.cameraStatus === LT.Utilities.CamStatus_Menu_Displayed ||
           deviceAdapter.cameraStatus === LT.Utilities.CamStatus_IP_LiveStreaming ||
           deviceAdapter.cameraStatus === LT.Utilities.CamStatus_LiveStreamingRemoteRec ||
           deviceAdapter.isMultiviewMode === true){
            oneShotAFEnabled_Save = flg
        }else{
            oneShotAFButton.enabled = flg
        }
    }

    function whiteBalanceSetting() {
        //console.log("liveview::whiteBalanceSetting =" + deviceAdapter.whiteBalance);
        if(deviceAdapter.cameraStatus === LT.Utilities.CamStatus_Menu_Displayed ||
           deviceAdapter.cameraStatus === LT.Utilities.CamStatus_IP_LiveStreaming ||
           deviceAdapter.cameraStatus === LT.Utilities.CamStatus_LiveStreamingRemoteRec ||
           deviceAdapter.isMultiviewMode === true){
            // MENU表示、マルチ表示中
            return
        }
        
        switch (deviceAdapter.whiteBalance) {
        case LT.Utilities.WB_Keep://        ,
        case LT.Utilities.WB_Keep2://       ,
        case LT.Utilities.WB_Keep3://       ,
        case LT.Utilities.WB_Keep4://       ,
            wbSettingsButton.enabled = true
            break;
        case LT.Utilities.WB_Unknown:// = -1,
        case LT.Utilities.WB_Auto://        ,
        case LT.Utilities.WB_Auto_Cool://   ,
        case LT.Utilities.WB_Daylight://    ,
        case LT.Utilities.WB_Cloud://       ,
        case LT.Utilities.WB_Flash://       ,
        case LT.Utilities.WB_Tengsten://    ,
        case LT.Utilities.WB_Shade://       ,
        case LT.Utilities.WB_K_Set://       ,
        case LT.Utilities.WB_K_Set2://      ,
        case LT.Utilities.WB_K_Set3://      ,
        case LT.Utilities.WB_K_Set4://      ,
// ivc >> start >> No.5
        case LT.Utilities.WB_Auto_Warm:
// ivc << end << No.5
        case LT.Utilities.WB_Max://
        default:
            wbSettingsButton.enabled = false
            utilities.setMouseCursor(0);
            lv_wbset_mode=false;
            wbSettingsChecked = false
            break;
        };
    }

    function wb_Position_set(){
        //LTSubFunction.console_debug.out("wb_Position_set")
        utilities.setMouseCursor(0);
        lv_wbset_mode=false;
        wbSettingsButton.checked=false;
        //WB設定
        var ret1 = deviceAdapter.adp_LMX_func_api_WB_Ctrl_WBSET_START_REQ();
        if(ret1 != LT.DeviceAdapter.Ternary_True) {
            LTSubFunction.console_debug.out("wb_Position_set 1")
            deviceAdapter.adp_LMX_func_api_WB_Ctrl_WBSET_END_REQ();
        } else {
            LTSubFunction.console_debug.out("wb_Position_set 2")
            var ret2 = deviceAdapter.adp_LMX_func_api_WB_Ctrl_WBSET_SET_REQ();
            if(ret2 != LT.DeviceAdapter.Ternary_True) {
                deviceAdapter.adp_LMX_func_api_WB_Ctrl_WBSET_END_REQ();
            }
        }
    }

    //電動ズーム関連
    function zoomLensCtrlEnableSetting(){
        if(deviceAdapter.cameraStatus !== LT.Utilities.CamStatus_Menu_Displayed ){
            isZoomCtrlEnable = deviceAdapter.zoomLensCtrlEnable
        }
    }
    function zoomLensTeleSetting(){
        if(deviceAdapter.cameraStatus !== LT.Utilities.CamStatus_Menu_Displayed){
            zoomCtrlSlider.to = (deviceAdapter.zoomLensTele)
        }
    }
    function zoomLensWideSetting(){
        if(deviceAdapter.cameraStatus !== LT.Utilities.CamStatus_Menu_Displayed){
            zoomCtrlSlider.from = (deviceAdapter.zoomLensWide)
        }
    }
    function zoomLensLenSetting(){
        if(deviceAdapter.cameraStatus !== LT.Utilities.CamStatus_Menu_Displayed){
            zoomCtrlSlider.value = (deviceAdapter.zoomLensLen)
        }
    }

    function btnAllCameraStatusChanged()
    {
        if(deviceAdapter.btnAllCameraStatus === LT.Utilities.BtnAllCameraStatus_Checked) {
            //Menu表示してないなら現在のボタン状況を保存
            //Menu表示中ならすでに保存済み
            if (deviceAdapter.cameraStatus !== LT.Utilities.CamStatus_Menu_Displayed) {
                updateBtnSaveStatus()
                updateBtnEnable()
            }
        }else{
            //Menu表示中でないなら、保存してたボタン状況を元に戻す
            if (deviceAdapter.cameraStatus !== LT.Utilities.CamStatus_Menu_Displayed) {
                updateBtnEnable()
            }
        }
    }

    function isMultiviewModeChanged()
    {
        if(deviceAdapter.isMultiviewMode === true) {
            //Menu表示してないなら現在のボタン状況を保存
            //Menu表示中ならすでに保存済み
            if (deviceAdapter.cameraStatus !== LT.Utilities.CamStatus_Menu_Displayed) {
                updateBtnSaveStatus()
                updateBtnEnable()
            }
        }else{
            //Menu表示中でないなら、保存してたボタン状況を元に戻す
            if (deviceAdapter.cameraStatus !== LT.Utilities.CamStatus_Menu_Displayed) {
                updateBtnEnable()
            }
        }
    }

    function updateBtnSaveStatus()
    {
        //ボタン状況を待避
        wbSettingsChecked_Save = wbSettingsChecked
        afAreaEnabled_Save = afAreaButton.enabled
        afAreaChecked_Save = afAreaChecked
        oneShotAFEnabled_Save = oneShotAFButton.enabled
        oneShotAFChecked_Save = oneShotAFChecked
        levelIndicatorChecked_Save = levelIndicatorChecked
        gridChecked_Save = gridChecked
        guidelineChecked_Save = guidelineChecked
        histogramChecked_Save = histogramChecked
        mfZoomChecked_Save = mfZoomChecked
        overlayButtonEnabled_Save = lvOverlayPhotoEnabledSettingButton
        overlayButtonChecked_Save = overlayButtonAlias.checked
    }

    function updateBtnEnable()
    {
        if (deviceAdapter.cameraStatus === LT.Utilities.CamStatus_Menu_Displayed &&
            deviceAdapter.isMultiviewMode === false) {
            if(lvOverlayPhotoPopupAlias.visible == true) {
                lvOverlayPhotoPopupAlias.dismiss()
            }
            root.guidelinePopupClose()
            root.gridPopupClose()
            root.controlItemSetting(controlItemSetting_menu)
//            maskpanel.isFillAll = false;
//            maskPanelOpen();
            isMenuBtnChecked = true;
            //カメラステータスの変更通知でボタンの状態を変更するようにする
            menuBtn.checked = true;
            menuBtn.enabled = true;
            menuMaskpanel.visible = false
        }else if (deviceAdapter.cameraStatus === LT.Utilities.CamStatus_IP_LiveStreaming ||
            deviceAdapter.cameraStatus === LT.Utilities.CamStatus_LiveStreamingRemoteRec ) {
            if(lvOverlayPhotoPopupAlias.visible == true) {
                lvOverlayPhotoPopupAlias.dismiss()
            }
            root.guidelinePopupClose()
            root.gridPopupClose()
            root.controlItemSetting(controlItemSetting_streaming)
//            maskpanel.isFillAll = false;
//            maskPanelOpen();
            isMenuBtnChecked = true;
            menuBtn.checked = false;
            menuBtn.enabled = false;
            menuMaskpanel.visible = true
        }else{
            if(deviceAdapter.isMultiviewMode === true){
                //マルチ表示
                if(lvOverlayPhotoPopupAlias.visible == true) {
                    lvOverlayPhotoPopupAlias.dismiss()
                }
                root.guidelinePopupClose()
                root.gridPopupClose()
				root.lvImgQualityPopupClose()
                root.controlItemSetting(controlItemSetting_multi)
//                maskpanel.isFillAll = true;
//                maskPanelOpen();
                isMenuBtnChecked = true;
                menuBtn.checked = false;
                menuBtn.enabled = false;
                menuMaskpanel.visible = true
            }else{
                //元に戻す
                root.controlItemSetting(controlItemSetting_enable)
                maskpanel.isFillAll = true;
                maskPanelClose();
                menuBtn.checked = false;
                if(deviceAdapter.btnAllCameraStatus === LT.Utilities.BtnAllCameraStatus_Checked) {
                    menuBtn.enabled = false;
                }
                else {
                    menuBtn.enabled = true;
                }
                menuMaskpanel.visible = false
            }
        }
    }

    /*
        LTLogCollector Log record helper
     */
    LTLogCollector {
        id: ltLog

        logMajTagID: LT.TagDef.RTMajor_Usage
        logMedTagID: LT.TagDef.RTMed_Usage_LiveView
        logWindowName: "LTLiveViewControlItem"
    }

    /*
        LTOptionButtonPopup に表示するコンポーネントの組を提供するオブジェクト
     */
    LTOptionComponentsProvider {
        id: optionComponentsProvider
    }

    Column {
        anchors {
            fill: parent
        }

        Item {
            anchors {
                left: parent.left
                right: parent.right
            }
            height: 1

            /*
                背景
             */
            Rectangle {
                anchors {
                    fill: parent
                }
                color: palette.backgroundLight
            }
        }

        Item {
            id: ctrlItem1
            anchors {
                left: parent.left
                right: parent.right
            }
            readonly property int heightDefault: btnHeight_normal * 7 + 7
            // ivc >> start >> No.1
            //height: 29 * 7 + 7      //プレビュー表示位置移動
// IVC >> Ver.1.9 >> start >> No.2
            //height: 29 * 8 + 8
//            height: 29 * 9 + 8      //プレビュー表示位置移動
// IVC << Ver.1.9 << end << No.2
            // ivc << end << No.1

            /*
                背景
             */
            Rectangle {
                anchors {
                    fill: parent
                }
                color: palette.backgroundLight
            }

            Grid {
                id: ctrlItem1Grid1
                columns: 1
// IVC >> Ver.1.9 >> start >> No.2
                //rows: 9
//                rows: 10
// IVC << Ver.1.9 << end << No.2
                spacing: 1

                readonly property int rowsDefault: 7

           // IVC >> Ver.1.9 >> start >> No.2
                /*
                    Menu
                 */
                LTRectangleButton {
                    id: menuBtn
                    width: root.width
                    height: btnHeight_normal
                    type: "checkableWithText"
                    buttonText: qsTr("MENU")

                    logCol: ltLog
                    logScrTagID: LT.TagDef.RTScr_Usage_LiveView_Menu
                    logFile: "menuBtn"

                    visible: false

                    onClicked: {
                        var ret = LT.DeviceAdapter.Ternary_False
                        if (checked) {
// IVC >> Ver.1.9 >> start >> [THRBOXV100-137]
                            //カメラステータスの変更通知でボタンの状態を変更するようにするため、呼び出し元で変更されたフラグを元に戻す
                            checked = false;
// IVC << Ver.1.9 << end << [THRBOXV100-137]
                            ret = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_Menu_Start_Menu();
// IVC >> Ver.1.9 >> start >> [THRBOXV100-76]
//                            // IVC >> Ver.1.9 >> start >> [THRBOXV100-68]
////                            if (ret == LT.DeviceAdapter.Ternary_True) {
//                            if(deviceAdapter.cameraStatus == LT.Utilities.CamStatus_Menu_Displayed) {
//                            // IVC << Ver.1.9 << end << [THRBOXV100-68]
//                                root.controlItemSetting(true)
//                            } else {
//                                checked = false
//                            }
// IVC << Ver.1.9 << end << [THRBOXV100-76]
                        } else {
                            //カメラステータスの変更通知でボタンの状態を変更するようにするため、呼び出し元で変更されたフラグを元に戻す
                            checked = true;
                            ret = deviceAdapter.adp_LMX_func_api_Rec_Ctrl_Menu_End_Menu();
// IVC >> Ver.1.9 >> start >> [THRBOXV100-76]
//                            if (ret == LT.DeviceAdapter.Ternary_True) {
//                                root.controlItemSetting(false)
//                            } else {
//                                checked = true
//                            }
// IVC << Ver.1.9 << end << [THRBOXV100-76]
                        }
                    }

                    Connections {
                        target: deviceAdapter
                        function onCameraStatusChanged() {
                            if (deviceAdapter.cameraStatus === LT.Utilities.CamStatus_Menu_Displayed) {
                                if(deviceAdapter.isMultiviewMode === false){
                                    //マルチ表示中じゃないなら現在のボタン状況を保存
                                    //マルチ表示中ならすでに保存済み
                                    updateBtnSaveStatus()
                                }
                                updateBtnEnable()
                            }else{
                                updateBtnEnable()
                            }
                        }
                    }
                }
           // IVC << Ver.1.9 << end << No.2

                /*
                    WB 設定
                 */
                LTRectangleButton {
                    id: wbSettingsButton
                    width: root.width
                    height: btnHeight_normal
                    type: "checkableWithText"
                    buttonText: qsTr("WB Settings")
                    checked:lv_wbset_mode
                    disabled: (wbSettingsButton.enabled === true)? false: true

                    logCol: ltLog
                    logScrTagID: LT.TagDef.RTScr_Usage_LiveView_WBSetting
                    logFile: "wbSettingsButton"

                    onClicked: {
                        if(lv_wbset_mode) {
                            utilities.setMouseCursor(0);
                            lv_wbset_mode=false;
                        }
                        else{
                            utilities.setMouseCursor(1);
                            lv_wbset_mode=true;
                        }
                    }
                }

                /*
                    AF 枠表示
                 */
                LTRectangleButton {
                    id: afAreaButton
                    width: root.width
                    height: btnHeight_normal
                    type: "checkableWithText"
                    buttonText: qsTr("AF Area")

                    visible: false
                    disabled: (afAreaButton.enabled === true)? false: true

                    logCol: ltLog
                    logScrTagID: LT.TagDef.RTScr_Usage_LiveView_AFArea
                    logFile: "afAreaButton"

                    onClicked: {
                        root.af_dispframeClicked()
                    }
                }

                /*
                    ワンショット AF
                 */
                LTRectangleButton {
                    id: oneShotAFButton
                    width: root.width
                    height: btnHeight_normal
                    type: "action_left"
                    buttonText:qsTr("One-Shot AF")
                    disabled: ( mfadjust.enabled == true )? false: true

                    logCol: ltLog
                    logScrTagID: LT.TagDef.RTScr_Usage_LiveView_OneShotAF
                    logFile: "afAreaButton"

                    onClicked: {
                        root.af_oneshotClicked()
                    }
                }

                 /*
                    水準器
                 */
                LTRectangleButton {
                    id: levelIndicatorButton
                    width: root.width
                    height: btnHeight_normal
                    type: "checkableWithText"
                    buttonText: qsTr("Level Indicator")
                    checked: lv_level_indicator_on_off

                    logCol: ltLog
                    logScrTagID: LT.TagDef.RTScr_Usage_LiveView_LevelIndicator
                    logFile: "levelIndicatorButton"

                    onClicked: {
                        lv_level_indicator_on_off = levelIndicatorButton.checked
                    }
                }

                /*
                    グリッド
                 */
                LTRectangleButton {
                    id: gridButton
                    width: root.width
                    height: btnHeight_normal
                    type: "checkableWithText"
                    buttonText: qsTr("Grid")
                    checked: lv_grid_indicator_on_off

                    logCol: ltLog
                    logScrTagID: LT.TagDef.RTScr_Usage_LiveView_Grid
                    logFile: "gridButton"

                    onClicked: {
                        if(gridButton.checked == false) {
                            root.gridPopupClose()
                        }

                        lv_grid_indicator_on_off = gridButton.checked
                    }
                }

                /*
                    ガイドライン
                 */
                LTRectangleButton {
                    id: guidelineButton
                    width: root.width
                    height: btnHeight_normal
                    type: "checkableWithText"
                    buttonText: qsTr("Guideline")
                    checked: lv_gline_indicator_on_off

                    logCol: ltLog
                    logScrTagID: LT.TagDef.RTScr_Usage_LiveView_Guideline
                    logFile: "guidelineButton"

                    onClicked: {
                        if(guidelineButton.checked == false) {
                            root.guidelinePopupClose()
                        }

                        lv_gline_indicator_on_off = guidelineButton.checked
                    }
                }

                // ivc >> start >> No.1
                /*
                    オーバーレイ
                 */
                LTRectangleButton {
                    id: overlayButton
                    width: root.width
                    height: btnHeight_normal
                    type: "checkableWithText"
                    buttonText: qsTr("Overlay")
                    checked: lv_overlay_indicator_on_off
                    enabled: lvOverlayPhotoEnabledSettingButton
                    logCol: ltLog
                    logScrTagID: LT.TagDef.RTScr_Usage_LiveView_OverlayPhoto
                    logFile: "overlayButton"

                    onEnabledChanged: {
                        if(enabled == false) {
                            LTSubFunction.console_debug.out("overlayButton onEnabledChanged enabled=false")
                            overlayPhotoFrame.visible = false
                        } else {
                            LTSubFunction.console_debug.out("overlayButton onEnabledChanged enabled=true")
                            if(overlayButton.checked == true) {
                                overlayPhotoFrame.visible = true
                                if(lvOverSelectedFile == ""){
                                    lvOverlayPhotoFrameAlias.rotaimage1.visible=false
                                    lvOverlayPhotoFrameAlias.dragAreaphoto1.visible=false
                                    lvOverlayPhotoFrameAlias.cornerTopLeft1.visible=false
                                    lvOverlayPhotoFrameAlias.cornerTopRight1.visible=false
                                    lvOverlayPhotoFrameAlias.cornerBotLeft1.visible=false
                                    lvOverlayPhotoFrameAlias.cornerBotRight1.visible=false
                                }
                            }
                        }
                    }
                    onClicked: {
                        lv_overlay_indicator_on_off = overlayButton.checked
                        if(lv_overlay_indicator_on_off) {
                            lvOverlayPhotoFrameOldHeight = overlayPhotoFrame.height
                            lvOverlayPhotoFrameOldWidth = overlayPhotoFrame.width
                            if(lv_rotation_mode == false) {
                                if(lv_rotation >= 180) {
                                    lvOverlayPhotoRotation = (-180 + (lv_rotation - 180))
                                } else {
                                    lvOverlayPhotoRotation = lv_rotation
                                }
                            }

                            LTSubFunction.console_debug.out("overlayButton onClicked enabled=true")
                            overlayPhotoFrame.visible = true
                            lvOverlayPhotoFrameAlias.dragAreaphoto1.visible = false
                            lvOverlayPhotoFrameAlias.cornerTopLeft1.visible = false
                            lvOverlayPhotoFrameAlias.cornerTopRight1.visible = false
                            lvOverlayPhotoFrameAlias.cornerBotLeft1.visible = false
                            lvOverlayPhotoFrameAlias.cornerBotRight1.visible = false
                            lvOverlayPhotoFrameAlias.rotaimage1.visible = false
                            lvOverlayPhotoOldPaintedHeight = imageLV.paintedHeight
                            lvOverlayPhotoOldPaintedWidth = imageLV.paintedWidth
                            updateCursorScale()

                            // Invisible overlay popup in case overlay photo is loaded incorrectly
                            if((lvOverlayPhotoFrameAlias.overlayImagealias.status == Image.Null) || (lvOverlayPhotoFrameAlias.overlayImagealias.status == Image.Error)) {
                                overlayPhotoPopup.visible = !overlayPhotoPopup.visible
                            }
                        } else {
                            LTSubFunction.console_debug.out("overlayButton onClicked enabled=false")
                            overlayPhotoFrame.visible = false
                        }
                    }
                }
                // ivc << end << No.1

                /*
                    ヒストグラム
                 */
                LTRectangleButton {
                    id: histogramButton
                    width: root.width
                    height: btnHeight_normal
                    type: "checkableWithText"
                    buttonText: qsTr("Histogram")
                    checked: lv_histogram_indicator_on_off

                    logCol: ltLog
                    logScrTagID: LT.TagDef.RTScr_Usage_LiveView_Histogram
                    logFile: "histogramButton"

                    onClicked: {
                        lv_histogram_indicator_on_off = histogramButton.checked
                    }
                }

            }
            // IVC >> Ver.1.9 >> start >> No.1
//            Component.onCompleted: {
//                deviceAdapter.btnAllCameraStatusChanged.connect(root.cameraMenuEnableHandler);
//            }
            // IVC << Ver.1.9 << end << No.1
            /*グリッド歯車アイコン*/
             LTRectangleButton {
                 id: gridSettingButton
                 x: gridButton.x + gridButton.width - btnHeight_normal
                 y: gridButton.y
                 visible: gridButton.checked
                 width: btnHeight_normal
                 height: btnHeight_normal
                 source: "qrc:/images/436_setting_btn.svg"

                 logCol: ltLog
                 logScrTagID: LT.TagDef.RTScr_Usage_LiveView_GridSetting
                 logFile: "gridSettingButton"

                 onClicked: {
                     root.gridSetting()
                 }
             }

            LTRectangleButton {
                id: guidelineSettingButton
                x: guidelineButton.x + guidelineButton.width - btnHeight_normal
                y: guidelineButton.y
                visible: guidelineButton.checked;
                width: btnHeight_normal
                height: btnHeight_normal
                source: "qrc:/images/436_setting_btn.svg"

                logCol: ltLog
                logScrTagID: LT.TagDef.RTScr_Usage_LiveView_GuidelineSetting
                logFile: "gridSettingButton"

                onClicked: {
                    root.guidelineSetting()
                }
            }

            // ivc >> start >> No.1
            /* オーバーレイ歯車アイコン */
            LTRectangleButton {
                id: overlaySettingButton
                x: overlayButton.x + overlayButton.width - btnHeight_normal
                y: overlayButton.y
                visible: overlayButton.checked;
                width: btnHeight_normal
                height: btnHeight_normal
                source: "qrc:/images/436_setting_btn.svg"
                enabled: lvOverlayPhotoEnabledSettingButton
                logCol: ltLog
                logScrTagID: LT.TagDef.RTScr_Usage_LiveView_OverlayPhotoSetting
                logFile: "overlaySettingButton"

                onClicked: {
                    root.overlaySetting()
                    if((lvOverlayPhotoFrameAlias.overlayImagealias.status != Image.Null) && (lvOverlayPhotoFrameAlias.overlayImagealias.status != Image.Error)) {
                        lvOverlayPhotoFrameAlias.dragAreaphoto1.visible = true
                        lvOverlayPhotoFrameAlias.cornerTopLeft1.visible = true
                        lvOverlayPhotoFrameAlias.cornerTopRight1.visible = true
                        lvOverlayPhotoFrameAlias.cornerBotLeft1.visible = true
                        lvOverlayPhotoFrameAlias.cornerBotRight1.visible = true
                        lvOverlayPhotoFrameAlias.rotaimage1.visible = true
                    }
                }
            }
            // ivc << end << No.1
        }

        Item {
            anchors {
                left: parent.left
                right: parent.right
            }
            height: 36

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
                MF 拡大
             */
            LTRectangleButton {
                id: mfZoom
                width: (root.width*7)/12
                height: btnHeight_normal + 9
                type: "checkableWithText"
                buttonText: qsTr("MF Zoom")
                disabled: (mfZoom.enabled == true) ? false: true

                logCol: ltLog
                logScrTagID: LT.TagDef.RTScr_Usage_LiveView_MFZoom
                logFile: "MFZoomButton"

                onCheckedChanged: {
                    if (!checked
                        && enabled
                        && (afframe.mode == afframe.afmode_pscope
                            || afframe.mode == afframe.afmode_pscope_z
                            || afframe.mode == afframe.afmode_pscope_p)) {
//                        afframe.changeMode(afframe.afmode_init)
                        root.afFramePointScopeEnd()
                    }

                    // ivc >> start >> No.1
                    if(!checked && enabled) {
                        lvOverlayPhotoEnabledSettingButton = true
                    } else {
                        lvOverlayPhotoEnabledSettingButton = false
                    }
                    // ivc << end << No.1
                }

                onClicked: {
                    LTSubFunction.console_debug.out("mfZoom onClicked afframe.mode=" + afframe.mode
                                                    + " afaeStartFlg="+ afaeStartFlg + " small_frame=" + deviceAdapter.sFrame_info)

                    mfZoom.enabled = false

                    //MF => MF Assist(0x03000051)
                    if(afframe.mode == afframe.afmode_mf
                            || afframe.mode == afframe.afmode_mff) {
                        afframe.mfStart()
                    }
                    else if(afframe.mode == afframe.afmode_mfz
                            || afframe.mode == afframe.afmode_mfp) {
                        afframe.mfEnd()
                    }

                    // 動画LV拡大(0x030000D1)
                    else if(deviceAdapter.lvMagEnable &&
//                            (deviceAdapter.recordingMode === LT.Utilities.RM_CreativeVideo || deviceAdapter.recordingMode === LT.Utilities.RM_SQMotion) &&
                            deviceAdapter.isExpMovieMode() &&
                            ((afframe.mode !== afframe.afmode_lvmag_z) && (afframe.mode !== afframe.afmode_lvmag_p))) {
                        afframe.lvMagStart()
                    }
                    else if(deviceAdapter.lvMagEnable &&
//                            (deviceAdapter.recordingMode === LT.Utilities.RM_CreativeVideo || deviceAdapter.recordingMode === LT.Utilities.RM_SQMotion) &&
                            deviceAdapter.isExpMovieMode() &&
                            ((afframe.mode === afframe.afmode_lvmag_z) || (afframe.mode === afframe.afmode_lvmag_p))) {
                        afframe.lvMagEnd()
                    }

                    //AFpinpoint and AFAE unlock => AF Pintpoint(0x0300002B)
                    else if(!afaeStartFlg
                            && afframe.mode == afframe.afmode_pinpoint) {
                        afframe.pinpointAfStart()
                    }
                    else if(!afaeStartFlg
                            && (afframe.mode == afframe.afmode_pinpointz
                                || afframe.mode == afframe.afmode_pinpointp)) {
                        afframe.pinpointAfEnd()
                    }

                    //AFAE lock
                    else if(afaeStartFlg) {
                        // AFpinpoint and AFAE lock => MF Assist(0x03000051)
                        if (afframe.mode == afframe.afmode_pinpoint
                                 || afframe.mode == afframe.afmode_pinpointz
                                 || afframe.mode == afframe.afmode_pinpointp) {
                            afAeSelected()
                        }
                        // case starting with point scope => AF Point Scope(0x030000C5)
                        else if (deviceAdapter.afPointScopeEnable
                                 && deviceAdapter.sFrame_info) {
                            afPointScopeSelected()
                        }
                        // AF+MF OFF and point scope enabled => AF Point Scope(0x030000C5)
                        else if (deviceAdapter.afPointScopeEnable
                                 && deviceAdapter.afmfMode == LT.Utilities.AFMFM_Off) {
                            afPointScopeSelected()
                        } // Other cases => MF Assist(0x03000051)
                        else {
                            afAeSelected()
                        }
                    }

                    //AF Point Scope enable=> AF Point Scope(0x030000C5)
                    else if (deviceAdapter.afPointScopeEnable) {
                        afPointScopeSelected()
                    }
                }

                function afPointScopeSelected() {
                    if( mfZoom.checked == true ) {
                        var ret = afframe.pScopeStart()
                        if(ret == false) {
                            LTSubFunction.console_debug.out("point scope error!!")
                        }
                    }
                    else {
                        afframe.pScopeEnd()
                    }
                }

                function afAeSelected() {
                    if( mfZoom.checked == true ) {
                        var ret = afframe.afmfStart()
                        if(ret == false) {
                            LTSubFunction.console_debug.out("mfZoom afmfStart error!!")
                        }
                    }
                    else {
                        afframe.afmfEnd()
                    }
                }
            }

            LTStylishText {
                id: mfZoomText
                x: parent.width - width - 8
                y: 0
                width: 80
                height: parent.height - y * 2

                type:text_style_liveViewLabel

                visible: (mfZoom.enabled ? (mfZoom.checked ? true: false): false)
                color: (mfZoom.enabled? "#dddddd": "#646464")
                horizontalAlignment: Text.AlignRight
                property bool checked: false
            }
        }

        Item {
            anchors {
                left: parent.left
                right: parent.right
            }
            height: btnHeight_normal
            /*
                背景
             */
            Rectangle {
                anchors {
                    fill: parent
                }
                color: palette.backgroundLight
            }
            Grid {
                columns: 6
                rows: 1
                spacing: 1
                LTRectangleButton {
                    id: mfZoomLeft3
                    width: 34
                    height: btnHeight_normal
                    source: "qrc:/images/461_allow_left3.svg"
                    enabled: ( (mfZoom.enabled == true) && (mfZoom.checked == true) )? true: false
                    disabled: ( (mfZoom.enabled == true) && (mfZoom.checked == true) )? false: true

                    logCol: ltLog
                    logScrTagID: LT.TagDef.RTScr_Usage_LiveView_MFZoomLeft3
                    logFile: "mfZoomLeft3"

                    onPressAndHold: {
                    }
                    onClicked: {
                    }
                    onCanceled: {
                    }
                    onPressed: {
                        root.zoomStart(-50)
                    }
                    onReleased: {
                        root.zoomStop()
                    }
                }
                LTRectangleButton {
                    id: mfZoomLeft2
                    width: 34
                    height: btnHeight_normal
                    source: "qrc:/images/461_allow_left2.svg"
                    enabled: ( (mfZoom.enabled == true) && (mfZoom.checked == true) )? true: false
                    disabled: ( (mfZoom.enabled == true) && (mfZoom.checked == true) )? false: true

                    logCol: ltLog
                    logScrTagID: LT.TagDef.RTScr_Usage_LiveView_MFZoomLeft2
                    logFile: "mfZoomLeft2"

                    onPressAndHold: {
                    }
                    onClicked: {
                    }
                    onCanceled: {
                    }
                    onPressed: {
                        root.zoomStart(-10)
                    }
                    onReleased: {
                        root.zoomStop()
                    }
                }
                LTRectangleButton {
                    id: mfZoomLeft1
                    width: 34
                    height: btnHeight_normal
                    source: "qrc:/images/461_allow_left1.svg"
                    enabled: ( (mfZoom.enabled == true) && (mfZoom.checked == true) )? true: false
                    disabled: ( (mfZoom.enabled == true) && (mfZoom.checked == true) )? false: true

                    logCol: ltLog
                    logScrTagID: LT.TagDef.RTScr_Usage_LiveView_MFZoomLeft1
                    logFile: "mfZoomLeft1"

                    onPressAndHold: {
                    }
                    onClicked: {
                    }
                    onCanceled: {
                    }
                    onPressed: {
                        root.zoomStart(-1)
                    }
                    onReleased: {
                        root.zoomStop()
                    }
                }
                LTRectangleButton {
                    id: mfZoomRight1
                    width: 34
                    height: btnHeight_normal
                    source: "qrc:/images/462_allow_right1.svg"
                    enabled: ( (mfZoom.enabled == true) && (mfZoom.checked == true) )? true: false
                    disabled: ( (mfZoom.enabled == true) && (mfZoom.checked == true) )? false: true

                    logCol: ltLog
                    logScrTagID: LT.TagDef.RTScr_Usage_LiveView_MFZoomRight1
                    logFile: "mfZoomRight1"

                    onPressAndHold: {
                    }
                    onClicked: {
                    }
                    onCanceled: {
                    }
                    onPressed: {
                        root.zoomStart(1)
                    }
                    onReleased: {
                        root.zoomStop()
                    }
                }
                LTRectangleButton {
                    id: mfZoomRight2
                    width: 34
                    height: btnHeight_normal
                    source: "qrc:/images/462_allow_right2.svg"
                    enabled: ( (mfZoom.enabled == true) && (mfZoom.checked == true) )? true: false
                    disabled: ( (mfZoom.enabled == true) && (mfZoom.checked == true) )? false: true

                    logCol: ltLog
                    logScrTagID: LT.TagDef.RTScr_Usage_LiveView_MFZoomRight2
                    logFile: "mfZoomRight2"

                    onPressAndHold: {
                    }
                    onClicked: {
                    }
                    onCanceled: {
                    }
                    onPressed: {
                        root.zoomStart(10)
                    }
                    onReleased: {
                        root.zoomStop()
                    }
                }
                LTRectangleButton {
                    id: mfZoomRight3
                    width: 34
                    height: btnHeight_normal
                    source: "qrc:/images/462_allow_right3.svg"
                    enabled: ( (mfZoom.enabled == true) && (mfZoom.checked == true) )? true: false
                    disabled: ( (mfZoom.enabled == true) && (mfZoom.checked == true) )? false: true

                    logCol: ltLog
                    logScrTagID: LT.TagDef.RTScr_Usage_LiveView_MFZoomRight3
                    logFile: "mfZoomRight3"

                    onPressAndHold: {
                    }
                    onClicked: {
                    }
                    onCanceled: {
                    }
                    onPressed: {
                        root.zoomStart(50)
                    }
                    onReleased: {
                        root.zoomStop()
                    }
                }
                Timer {
                    id: mfZoomTimer
                    interval: 300   //タイマー間隔
                    running: false  //動いてない
                    repeat: true    //リピート あり
                    property int diff: 0
                    //トリガー動作
                    onTriggered:{
                        if(root.zoomExec() == false) {
                            root.zoomStop()
                        }
                    }
                }
                //LTRectangleButton {
                //    id: mfZoom3xButton
                //    width: 52
                //    height: 29
                //    type: "radioWithImage"
                //    enabled: mfZoom.enabled
                //    source: (checked? "qrc:/images/456_x3_y.svg": "qrc:/images/456_x3.svg")
                //
                //    logCol: ltLog
                //    logScrTagID: LT.TagDef.RTScr_Usage_LiveView_MFZoom3x
                //    logFile: "mfZoom3xButton"
                //
                //    onClicked: {
                //        switch(afFrame_magnification) {
                //        case 3:
                //            afFrame_magnification = 0
                //            mfZoom.checked=false
                //            mfZoom3xButton.checked=false
                //            mfZoom5xButton.checked=false
                //            mfZoom7xButton.checked=false
                //            mfZoom10xButton.checked=false
                //            root.mf_zoomClicked()
                //            zoom_stop()
                //            break;
                //        case 5:
                //        case 7:
                //        case 10:
                //            afFrame_magnification=3
                //            if(deviceAdapter.focusMode == LT.Utilities.FM_MF){
                //                deviceAdapter.mf_magnify=3
                //            } else if(deviceAdapter.autoFocusMode == LT.Utilities.AFM_Pinpoint) {
                //                deviceAdapter.af_magnify=3
                //            }
                //            mfZoom.checked = true
                //            mfZoom3xButton.checked = true
                //            mfZoom5xButton.checked = false
                //            mfZoom7xButton.checked = false
                //            mfZoom10xButton.checked = false
                //            break;
                //        default:
                //            magnify_start()
                //            afFrame_magnification=3
                //            if(deviceAdapter.focusMode == LT.Utilities.FM_MF){
                //                deviceAdapter.mf_magnify=3
                //            } else if(deviceAdapter.autoFocusMode == LT.Utilities.AFM_Pinpoint) {
                //                deviceAdapter.af_magnify=3
                //            }
                //            mfZoom.checked = true
                //            mfZoom3xButton.checked = true
                //            mfZoom5xButton.checked = false
                //            mfZoom7xButton.checked = false
                //            mfZoom10xButton.checked = false
                //            break;
                //        }
                //    }
                //}
            }
        }

        Item {
            anchors {
                left: parent.left
                right: parent.right
            }
            height: 5

            /*
                背景
             */
            Rectangle {
                anchors {
                    fill: parent
                }
                color: palette.backgroundDark
            }
        }

        Item {
            anchors {
                left: parent.left
                right: parent.right
            }
            height: 1

            /*
                背景
             */
            Rectangle {
                anchors {
                    fill: parent
                }
                color: palette.backgroundLight
            }
        }

        Item {
            anchors {
                left: parent.left
                right: parent.right
            }
            height: btnHeight_normal

            /*
                背景
             */
            Rectangle {
                anchors {
                    fill: parent
                }
                color: palette.backgroundDark
            }

            LTStylishText {
                id: mfadjust
                x: 8
                y: 0
                width: parent.width - x * 2
                height: parent.height - y * 2

                type:text_style_liveViewLabel
                color: (enabled? "#dddddd": "#646464")

                text: qsTr("MF Adjust")

            }
        }

        Item {
            anchors {
                left: parent.left
                right: parent.right
            }
            height: 21

            /*
                背景
             */
            Rectangle {
                anchors {
                    fill: parent
                }
                color: palette.backgroundLight
            }

            //MFピント調整
            Grid {
                columns: 4
                rows: 1
                spacing: 1

                LTRectangleButton {
                    id: mffarFast
                    width: 52
                    height: 21
                    source: "qrc:/images/460_allow_left_w.svg"
                    enabled: mfadjust.enabled
                    disabled: ( mfadjust.enabled == true )? false: true

                    logCol: ltLog
                    logScrTagID: LT.TagDef.RTScr_Usage_LiveView_MFAdjustLeftW
                    logFile: "mfAdjustLeftW"

                    onPressAndHold: {
                    }
                    onClicked: {
                    }
                    onCanceled: {
                        fs2stepTimer.running=false    //タイマー停止
                    }
                    onPressed: {
                        //mfZoom.checked = true
                        if(!afaeStartFlg) {
                            afframe.mfAdjust()
                        } else if(afframe.mfzoom_mode==afframe.mfzoom_mode_unknown) {
                            afframe.dispFrame()
                        }
                        var ret = root.af_focusfarfastClicked()
                        if(ret == LT.DeviceAdapter.Ternary_True) {
                            fs2stepTimer.running=true    //タイマー開始
                        } else {
                            mfZoom.checked = false
                        }
                    }
                    onReleased: {
                        fs2stepTimer.running=false    //タイマー停止
                    }
                }
                Timer {
                    id: fs2stepTimer
                    interval: 300   //タイマー間隔
                    running: false  //動いてない
                    repeat: true    //リピート あり
                    //トリガー動作
                    onTriggered:{
                        var ret = root.af_focusfarfastClicked()
                    }
                }

                LTRectangleButton {
                    width: 52
                    height: 21
                    source: "qrc:/images/461_allow_left.svg"
                    enabled: mfadjust.enabled
                    disabled: ( mfadjust.enabled == true )? false: true

                    logCol: ltLog
                    logScrTagID: LT.TagDef.RTScr_Usage_LiveView_MFAdjustLeft
                    logFile: "mfAdjustLeft"

                    onPressAndHold: {
                    }
                    onClicked: {
                    }
                    onCanceled: {
                        fs1stepTimer.running=false    //タイマー停止
                    }
                    onPressed: {
                        //mfZoom.checked = true
                        if(!afaeStartFlg) {
                            afframe.mfAdjust()
                        } else if(afframe.mfzoom_mode==afframe.mfzoom_mode_unknown) {
                            afframe.dispFrame()
                        }
                        var ret = root.af_focusfarslowClicked()
                        if(ret == LT.DeviceAdapter.Ternary_True) {
                            fs1stepTimer.running=true    //タイマー開始
                        } else {
                            mfZoom.checked = false
                        }
                    }
                    onReleased: {
                        fs1stepTimer.running=false    //タイマー停止
                    }
                }
                Timer {
                    id: fs1stepTimer
                    interval: 300   //タイマー間隔
                    running: false  //動いてない
                    repeat: true    //リピート あり
                    //トリガー動作
                    onTriggered:{
                        root.af_focusfarslowClicked()
                    }
                }

                LTRectangleButton {
                    width: 52
                    height: 21
                    source: "qrc:/images/462_allow_right.svg"
                    enabled: mfadjust.enabled
                    disabled: ( mfadjust.enabled == true )? false: true

                    logCol: ltLog
                    logScrTagID: LT.TagDef.RTScr_Usage_LiveView_MFAdjustRight
                    logFile: "mfAdjustRight"

                    onPressAndHold: {
                    }
                    onClicked: {
                    }
                    onCanceled: {
                        ns1stepTimer.running=false    //タイマー停止
                    }
                    onPressed: {
                        //mfZoom.checked = true
                        if(!afaeStartFlg) {
                            afframe.mfAdjust()
                        } else if(afframe.mfzoom_mode==afframe.mfzoom_mode_unknown) {
                            afframe.dispFrame()
                        }
                        var ret = root.af_focusnearslowClicked()
                        if(ret == LT.DeviceAdapter.Ternary_True) {
                            ns1stepTimer.running=true    //タイマー開始
                        } else {
                            mfZoom.checked = false
                        }
                    }
                    onReleased: {
                        ns1stepTimer.running=false    //タイマー停止
                    }
                }
                Timer {
                    id: ns1stepTimer
                    interval: 300   //タイマー間隔
                    running: false  //動いてない
                    repeat: true    //リピート あり
                    //トリガー動作
                    onTriggered:{
                        root.af_focusnearslowClicked()
                    }
                }
                LTRectangleButton {
                    width: 52 + 1
                    height: 21
                    source: "qrc:/images/463_allow_right_w.svg"
                    enabled: mfadjust.enabled
                    disabled: ( mfadjust.enabled == true )? false: true

                    logCol: ltLog
                    logScrTagID: LT.TagDef.RTScr_Usage_LiveView_MFAdjustRightW
                    logFile: "mfAdjustRightW"

                    onPressAndHold: {
                    }
                    onClicked: {
                    }
                    onCanceled: {
                        ns2stepTimer.running=false    //タイマー停止
                    }
                    onPressed: {
                        //mfZoom.checked = true
                        if(!afaeStartFlg) {
                            afframe.mfAdjust()
                        } else if(afframe.mfzoom_mode==afframe.mfzoom_mode_unknown) {
                            afframe.dispFrame()
                        }
                        var ret = root.af_focusnearfastClicked()
                        if(ret == LT.DeviceAdapter.Ternary_True) {
                            ns2stepTimer.running=true    //タイマー開始
                        } else {
                            mfZoom.checked = false
                        }
                    }
                    onReleased: {
                        ns2stepTimer.running=false    //タイマー停止
                    }
                }
                Timer {
                    id: ns2stepTimer
                    interval: 300   //タイマー間隔
                    running: false  //動いてない
                    repeat: true    //リピート あり
                    //トリガー動作
                    onTriggered:{
                        var ret = root.af_focusnearfastClicked()
                    }
                }
            }
        }

        Item {
            anchors {
                left: parent.left
                right: parent.right
            }
            height: 5

            /*
                背景
             */
            Rectangle {
                anchors {
                    fill: parent
                }
                color: palette.backgroundDark
            }
        }

        Item {
            anchors {
                left: parent.left
                right: parent.right
            }
            height: 1

            /*
                背景
             */
            Rectangle {
                anchors {
                    fill: parent
                }
                color: palette.backgroundLight
            }
        }
        //電動ズーム
        Item {
            enabled: isZoomCtrlEnable
            anchors {
                left: parent.left
                right: parent.right
            }
            height: btnHeight_normal

            /*
                背景
             */
            Rectangle {
                anchors {
                    fill: parent
                }
                color: palette.backgroundDark
            }

            LTStylishText {
                id: zoomCtrl
                x: 8
                y: 0
                width: 80
                height: parent.height - y * 2

                enabled: isZoomCtrlEnable

                type:text_style_liveViewLabel
                color: (enabled? "#dddddd": "#646464")

                text: qsTr("Zoom")
            }

            //現在値
            LTStylishText {
                id: zoomCtrlVal
                x: parent.width - width - 8
                y: 0
                width: 80
                height: parent.height - y * 2

                enabled: true
                visible: isZoomCtrlEnable

                type:text_style_liveViewLabel
                color: "#dddddd"
                horizontalAlignment: Text.AlignRight

                text: zoomCtrlSlider.value + " " + qsTr("mm")
            }

        }

        //電動ズーム
        //非表示状態にするとレイアウトが崩れるので、同じ色や表示文字無しで非活性状態を実現する
        Item {
            enabled: isZoomCtrlEnable
            anchors {
                left: parent.left
                right: parent.right
            }
            height: 21

            /*
                背景
             */
            Rectangle {
                anchors {
                    fill: parent
                }
                color: palette.backgroundDark
            }

            Grid {
                columns: 5
                rows: 1
                spacing: 1

                LTRectangleButton {
                    width: 34
                    height: 21
                    type: "action"
                    buttonText: qsTr("W")
                    disabled: ( isZoomCtrlEnable === true )? false: true

                    onPressAndHold: {
                    }
                    onClicked: {
                    }
                    onCanceled: {
                    }
                    onPressed: {
                        //全体値、相対値指定では動作しなくなる位置にハマる場合があるので、1クリック動作をさせるために単純にPressedとReleasedで行うようにする
                        deviceAdapter.adp_LMX_func_api_Rec_Ctrl_Zoom_Start(LT.Utilities.ZOOM_DIR_WIDE,LT.Utilities.ZOOM_SPEED_MID)
                        zoomStartFlg = true
                    }
                    onReleased: {
                        if( zoomStartFlg === true){
                            deviceAdapter.adp_LMX_func_api_Rec_Ctrl_Zoom_Stop()
                            zoomStartFlg = false
                        }
                    }
                }
                LTStylishText {
                    id: zoomCtrlSliderMin
                    width: 30
                    height: 21

                    type:text_style_liveViewLabel
                    color: "#dddddd"
                    horizontalAlignment: Text.Center

                    text: (enabled? zoomCtrlSlider.from: "")
                }
                Slider {
                    width: 80
                    height: 21
                    id: zoomCtrlSlider

                    live: false
                    enabled: false
                    value : 0
                    from: 0
                    to: 100
                    background: Rectangle {
                        x: zoomCtrlSlider.leftPadding
                        y: zoomCtrlSlider.topPadding + zoomCtrlSlider.availableHeight / 2 - height / 2
                        implicitWidth: 80
                        implicitHeight: 15
                        width: zoomCtrlSlider.availableWidth
                        height: implicitHeight
                        radius: 2
                        color: palette.backgroundDark
                        Rectangle {
                            x:zoomCtrlSliderHandle.x-2
                            width: 3
                            height: parent.height
                            color: (isZoomCtrlEnable? Qt.rgba(255, 204, 0): palette.backgroundDark)
                            radius: 2
                        }
                    }
                    handle: Rectangle {
                        id:zoomCtrlSliderHandle
                        x: zoomCtrlSlider.visualPosition * (zoomCtrlSlider.leftPadding + zoomCtrlSlider.availableWidth - width/2)
                        y: zoomCtrlSlider.topPadding + zoomCtrlSlider.availableHeight +1
                        implicitWidth: 16
                        implicitHeight: 20
                        visible: false
                    }
                    onValueChanged: {
                    }
                }
                LTStylishText {
                    id: zoomCtrlSliderMax
                    width: 30
                    height: 21

                    type:text_style_liveViewLabel
                    color: "#dddddd"
                    horizontalAlignment: Text.Center

                    text: (enabled? zoomCtrlSlider.to: "")
                }
                LTRectangleButton {
                    width: 34
                    height: 21
                    type: "action"
                    buttonText: qsTr("T")
                    disabled: ( isZoomCtrlEnable === true )? false: true

                    onPressAndHold: {
                    }
                    onClicked: {
                    }
                    onCanceled: {
                    }
                    onPressed: {
                        //全体値、相対値指定では動作しなくなる位置にハマる場合があるので、1クリック動作をさせるために単純にPressedとReleasedで行うようにする
                        deviceAdapter.adp_LMX_func_api_Rec_Ctrl_Zoom_Start(LT.Utilities.ZOOM_DIR_TELE,LT.Utilities.ZOOM_SPEED_MID)
                        zoomStartFlg = true
                    }
                    onReleased: {
                        if( zoomStartFlg === true){
                            deviceAdapter.adp_LMX_func_api_Rec_Ctrl_Zoom_Stop()
                            zoomStartFlg = false
                        }
                    }
                }
            }
        }

        Item {
            anchors {
                left: parent.left
                right: parent.right
            }
            height: 5

            /*
                背景
             */
            Rectangle {
                anchors {
                    fill: parent
                }
                color: palette.backgroundDark
            }
        }

        Item {
            anchors {
                left: parent.left
                right: parent.right
            }
            height: 1

            /*
                背景
             */
            Rectangle {
                anchors {
                    fill: parent
                }
                color: palette.backgroundLight
            }
        }

        Item {
            anchors {
                left: parent.left
                right: parent.right
            }
            height: btnHeight_normal

            /*
                背景
             */
            Rectangle {
                anchors {
                    fill: parent
                }
                color: palette.backgroundDark
            }

            LTStylishText {
                id: lvRotation
                x: 8
                y: 0
                width: parent.width - x * 2
                height: parent.height - y * 2
                color: (enabled? "#dddddd": "#646464")

                type: text_style_liveViewLabel
                text: qsTr("LiveView Rotation")
            }
        }

        Item {
            anchors {
                left: parent.left
                right: parent.right
            }
            height: 21

            /*
                背景
             */
            Rectangle {
                anchors {
                    fill: parent
                }
                color: palette.backgroundLight
            }

            Grid {
                columns: 3
                rows: 1
                spacing: 1

                LTRectangleButton {
                    width: 70
                    height: 21
                    source: "qrc:/images/442_left.svg"
                    enabled: lvRotation.enabled

                    logCol: ltLog
                    logScrTagID: LT.TagDef.RTScr_Usage_LiveView_RotationLeft
                    logFile: "rotationLeft"

                    // ivc >> start >> No.1
                    onClicked: {
                        lv_rotation += 270
                        if(lv_rotation >= 360) {
                            lv_rotation %= 360;
                        }
                        lvOverlayPhotoFlagChangeRotation = 1
                        lvOverlayPhotoRotation = -90 + lvOverlayPhotoRotation
                        if(lvOverlayPhotoRotation < -180)
                        {
                           lvOverlayPhotoRotation = 180 + (lvOverlayPhotoRotation % 180)
                        }
                        lvOverlayPhotoFrameAlias.rotation = lvOverlayPhotoRotation
                        updateRotaOverlayPhoto()
                        lvOverlayPhotoFlagChangeRotation = 0
                        autobotton.checked = false
                        lv_rotation_mode = false
                        updatePhotoFrameXY()
                        submitValueOverlaySetting()
                        updateCursorScale()
                    }
                    // ivc << end << No.1
                }

                LTRectangleButton {
                    id: autobotton
                    width: 70
                    height: 21
                    type: "checkableWithImage"
                    source: (checked? "qrc:/images/522_auto_push.svg": "qrc:/images/443_auto.svg")
                    checked: lv_rotation_mode
                    enabled: lvRotation.enabled

                    logCol: ltLog
                    logScrTagID: LT.TagDef.RTScr_Usage_LiveView_RotationAuto
                    logFile: "rotationAuto"

                    // ivc >> start >> No.1
                    onClicked: {
                        lv_rotation_mode = autobotton.checked
                        lv_rotation = 0
                        overlayPhotoPopup.sliderRotation1.value = 0
                        updatePhotoFrameXY()
                        updateCursorScale()
                    }
                    // ivc << end << No.1
                }

                LTRectangleButton {
                    width: 70
                    height: 21
                    source: "qrc:/images/444_right.svg"
                    enabled: lvRotation.enabled

                    logCol: ltLog
                    logScrTagID: LT.TagDef.RTScr_Usage_LiveView_RotationRight
                    logFile: "rotationRight"

                    // ivc >> start >> No.1
                    onClicked: {
                        lv_rotation += 90
                        if(lv_rotation == 360) {
                            lv_rotation = 0
                        }
                        lvOverlayPhotoFlagChangeRotation = 1
                        lvOverlayPhotoRotation = 90 + lvOverlayPhotoRotation
                        if(lvOverlayPhotoRotation > 180)
                        {
                           lvOverlayPhotoRotation = -(360 % lvOverlayPhotoRotation)
                        }
                        lvOverlayPhotoFrameAlias.rotation = lvOverlayPhotoRotation
                        updateRotaOverlayPhoto()
                        lvOverlayPhotoFlagChangeRotation = 0
                        autobotton.checked = false
                        lv_rotation_mode = false
                        updatePhotoFrameXY()
                        submitValueOverlaySetting()
                        updateCursorScale()
                    }
                    // ivc << end << No.1
                }
            }
        }

        Item {
            anchors {
                left: parent.left
                right: parent.right
            }
            height: 5

            /*
                背景
             */
            Rectangle {
                anchors {
                    fill: parent
                }
                color: palette.backgroundDark
            }
        }

        Item {
            anchors {
                left: parent.left
                right: parent.right
            }
            height: 1

            /*
                背景
             */
            Rectangle {
                anchors {
                    fill: parent
                }
                color: palette.backgroundLight
            }
        }

// IVC >> Ver.1.7 >> start >> No.1
        Item {
            visible: isDisplayImgQuality
            anchors {
                left: parent.left
                right: parent.right
            }
            height: btnHeight_normal

            /*
                背景
             */
            Rectangle {
                anchors {
                    fill: parent
                }
                color: palette.backgroundDark
            }

            LTOptionImageQualityButton {
                id: btnOptionLvImgQuality
                anchors.fill: parent
                anchors.leftMargin: 2
                type: "optionWithImage"
                labelText: qsTr("Image Quality")
                target: "imageQuality"
                popup: optionButtonPopup
                componentsProvider: optionComponentsProvider
                popupTitle: qsTr("Image Quality")
                fillColor: palette.backgroundDark
                value: LT.DeviceAdapter.LvImgQ_Low
                logCol: ltLog
                logScrTagID: LT.TagDef.RTScr_Usage_LiveView_AspectRatio
                logFile: "btnOptionLvImgQuality"
            }
        }

        Item {
            visible: isDisplayImgQuality
            anchors {
                left: parent.left
                right: parent.right
            }
            height: 1

            /*
                背景
             */
            Rectangle {
                anchors {
                    fill: parent
                }
                color: palette.backgroundLight
            }
        }

        Item {
            anchors {
                left: parent.left
                right: parent.right
            }
            height: btnHeight_normal

            /*
                背景
             */
            Rectangle {
                anchors {
                    fill: parent
                }
                color: palette.backgroundDark
            }

            LTOptionButton {
                id: btnOptionAspectRatio
                anchors.fill: parent
                popupX: width / 2
                anchors.leftMargin: 2
                type: "optionWithImage"
                labelText: qsTr("Aspect Ratio")
                target: "aspectRatio"
                popup: optionButtonPopupAspect
                componentsProvider: optionComponentsProvider
                popupTitle: qsTr("Aspect Ratio")
                fillColor: palette.backgroundDark

                logCol: ltLog
                logScrTagID: LT.TagDef.RTScr_Usage_LiveView_AspectRatio
                logFile: "btnOptionAspectRatio"
            }
        }

        Item {
            anchors {
                left: parent.left
                right: parent.right
            }
            height: 1

            /*
                背景
             */
            Rectangle {
                anchors {
                    fill: parent
                }
                color: palette.backgroundLight
            }
        }

        Item {
            anchors {
                left: parent.left
                right: parent.right
            }
            height: btnHeight_normal

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
                プレビュー
             */
            LTOptionButton {
                id: btnOptionRecPreview
                anchors.fill: parent
                anchors.leftMargin: 2
                popupX: width / 2
                type: "optionWithImage"
                labelText: qsTr("Monitor Preview")
                target:"recPreviewMode"
                popup: optionButtonPopup
                componentsProvider: optionComponentsProvider
                popupTitle: qsTr("Monitor Preview")

                fillColor: palette.backgroundDark

                logCol: ltLog
                logScrTagID: LT.TagDef.RTScr_Usage_LiveView_MonitorPreview
                logFile: "btnOptionRecPreview"
            }
        }

        Item {
            anchors {
                left: parent.left
                right: parent.right
            }
            height: 1

            /*
                背景
             */
            Rectangle {
                anchors {
                    fill: parent
                }
                color: palette.backgroundLight
            }
        }

        Item {
            anchors {
                left: parent.left
                right: parent.right
            }
            height: 1

            /*
                背景
             */
            Rectangle {
                anchors {
                    fill: parent
                }
                color: palette.backgroundLight
            }
        }
    }
// IVC << Ver.1.7 << end << No.1

    // マルチ表示中のMENUボタンのツールチップ
    Rectangle {
        id: menuMaskpanel
        visible: false
        enabled: menuBtn.visible
        anchors {
            top: parent.top
        }
        width: menuBtn.width
        height: menuBtn.height
        color: "#00000000"
        MouseArea {
            id: menuMaskMouseArea
            anchors.fill: parent
            hoverEnabled: true
        }
        ToolTip {
            property int posX: 0
            property int posY: 0
            x: posX
            y: posY+20
            visible: ((text) && (menuMaskMouseArea.containsMouse) && menuMaskpanel.enabled)
            delay: 500
            font: Qt.font({"pixelSize": 12, "family": utilities.getFontFamily()})
            text: qsTr("Please Change to Single View")
            background: Rectangle {
                color: "white"
            }
            onVisibleChanged: {
                posX = menuMaskMouseArea.mouseX
                posY = menuMaskMouseArea.mouseY
            }
        }
    }

    Column {
        id: hist
        visible: histogramChecked
        anchors {
            bottom: parent.bottom
        }

        onVisibleChanged: {
            if(visible) {
                //deviceAdapter.adp_LMX_func_api_RecDisp_Config_Set_Histgram_Mode_Param_On()
            }
        }
        //電動ズームの追加に伴い、表示エリア調整のために非表示に変更
        /*
        Item {
            anchors {
                left: parent.left
                right: parent.right
            }
            height: 21

            LTStylishText {
                x: 8
                y: 0
                width: parent.width - x * 2
                height: parent.height - y * 2

                type: text_style_liveViewLabelHis
                text: qsTr("Histogram")
            }
        }
        */
        LTHistogram {
            id: histgramArea
            readonly property int heightDefault: 147
            // IVC >> Ver.1.9 >> start >> No.1
//            width: 89 * aspect
//            height: 89
            // IVC << Ver.1.9 << end << No.1
        }

        Item {
            anchors {
                left: parent.left
                right: parent.right
            }
            height: 5
        }
    }

    Rectangle {
        id: maskpanel

        visible: false
// IVC >> Ver.1.9 >> start >> No.2
        property bool isFillAll: true
        anchors {
            bottom: parent.bottom
        }
        width: parent.width
        height: isFillAll ? parent.height : parent.height - menuBtn.height
// IVC << Ver.1.9 << end << No.2
        color: "#000000"
        opacity: 0.5
        MouseArea {
            anchors {
                fill: parent
            }
            hoverEnabled: true
            onClicked: {
                //root.dismiss();
            }
        }
    }

    function maskPanelOpen() {
        maskpanel.visible = true
    }
    function maskPanelClose() {
        maskpanel.visible = false
    }

    /*
        LTOptionButton の状態を選択するポップアップ
     */
    LTOptionButtonPopup {
        id: optionButtonPopup
    }
    LTCCPopup {
        id: ccPopup
    }

    // IVC >> Ver.1.7 >> start >> No.1
    LTOptionButtonPopup {
        id: optionButtonPopupAspect
        maximumPopupHeight: 180
    }
    // IVC << Ver.1.7 << end << No.1

    function set_RecPreviewMode() {
        // プレビュー
        deviceAdapter.setRecPreviewMode();
    }
    function get_sdk_range() {
        // アスペクト
        deviceAdapter.adp_LMX_func_api_ImageInfo_Get_ImageAspec();
    }
    function af_oneshotClicked() {
        //ワンショットAF
        deviceAdapter.adp_LMX_def_lib_tag_rec_Ctrl_AfAe_af_onesht();
    }
    function af_focusstopClicked() {
        //ピント調整  レンズ制御
        deviceAdapter.adp_LMX_func_api_Rec_Ctrl_Lens_stop();
    }
    function af_focusfarfastClicked() {
//        if ( (afframe.mode == afframe.afmode_mf) || (afframe.mode == afframe.afmode_mff) ) {
//            //afframe.mfStart()
//        }
        //ピント調整  レンズ制御
        if((afframe.mode === afframe.afmode_lvmag_z) || (afframe.mode === afframe.afmode_lvmag_p)) {
            // 動画LV拡大
            return deviceAdapter.adp_LMX_func_api_Rec_Ctrl_LV_Mag_MF_Adjust(LT.Utilities.RcLVMMFAdjust_Far_Fast)
        }
        else {
            return deviceAdapter.adp_LMX_func_api_Rec_Ctrl_Far_Fast();
        }
    }
    function af_focusfarslowClicked() {
//        if ( (afframe.mode == afframe.afmode_mf) || (afframe.mode == afframe.afmode_mff) ) {
//            //afframe.mfStart()
//        }
        //ピント調整  レンズ制御
        if((afframe.mode === afframe.afmode_lvmag_z) || (afframe.mode === afframe.afmode_lvmag_p)) {
            // 動画LV拡大
            return deviceAdapter.adp_LMX_func_api_Rec_Ctrl_LV_Mag_MF_Adjust(LT.Utilities.RcLVMMFAdjust_Far_Slow)
        }
        else {
            return deviceAdapter.adp_LMX_func_api_Rec_Ctrl_Far_Slow();
        }
    }
    function af_focusnearslowClicked() {
//        if ( (afframe.mode == afframe.afmode_mf) || (afframe.mode == afframe.afmode_mff) ) {
//            //afframe.mfStart()
//        }
        //ピント調整  レンズ制御
        if((afframe.mode === afframe.afmode_lvmag_z) || (afframe.mode === afframe.afmode_lvmag_p)) {
            // 動画LV拡大
            return deviceAdapter.adp_LMX_func_api_Rec_Ctrl_LV_Mag_MF_Adjust(LT.Utilities.RcLVMMFAdjust_Near_Slow)
        }
        else {
            return deviceAdapter.adp_LMX_func_api_Rec_Ctrl_Near_Slow();
        }
    }
    function af_focusnearfastClicked() {
//        if ( (afframe.mode == afframe.afmode_mf) || (afframe.mode == afframe.afmode_mff) ) {
//            //afframe.mfStart()
//        }
        //ピント調整  レンズ制御
        if((afframe.mode === afframe.afmode_lvmag_z) || (afframe.mode === afframe.afmode_lvmag_p)) {
            // 動画LV拡大
            return deviceAdapter.adp_LMX_func_api_Rec_Ctrl_LV_Mag_MF_Adjust(LT.Utilities.RcLVMMFAdjust_Near_Fast)
        }
        else {
            return deviceAdapter.adp_LMX_func_api_Rec_Ctrl_Near_Fast();
        }
    }
    function zoomStart(arg) {
        LTSubFunction.console_debug.out("zoomStart")
        mfZoomTimer.diff = arg
        if(zoomExec() == true) {
            mfZoomTimer.restart()
        }
    }
    function zoomStop(arg) {
        LTSubFunction.console_debug.out("zoomStop")
        mfZoomTimer.stop()
    }
    function zoomExec() {
        LTSubFunction.console_debug.out("zoomExec")
        var val
        if( (afframe.mode == afframe.afmode_pinpoint) ||
            (afframe.mode == afframe.afmode_pinpointf) ||
            (afframe.mode == afframe.afmode_pinpointp) ||
            (afframe.mode == afframe.afmode_pinpointz)) {
            val = deviceAdapter.af_magnify
            deviceAdapter.af_magnify = val + mfZoomTimer.diff
            if(deviceAdapter.af_magnify != val + mfZoomTimer.diff) {
                return false
            }
        }
        // 動画LV拡大
        else if((afframe.mode === afframe.afmode_lvmag_z) ||
                (afframe.mode === afframe.afmode_lvmag_p)) {
            val = deviceAdapter.lvMag_magnify
            deviceAdapter.lvMag_magnify = val + mfZoomTimer.diff
            if(deviceAdapter.lvMag_magnify != val + mfZoomTimer.diff) {
                return false
            }
        }
        else {
            val = deviceAdapter.mf_magnify
            deviceAdapter.mf_magnify = val + mfZoomTimer.diff
            if(deviceAdapter.mf_magnify != val + mfZoomTimer.diff) {
                return false
            }
        }
        return true
    }
// IVC >> Ver.1.9 >> start >> [THRBOXV100-144]
    function initSetupTetherMode() {
        // ポップアップクローズ
        lvImgQualityPopupClose()
        aspectRatioPopupClose()
        recPreviewPopupClose()

        columnsSetting()
        if (deviceAdapter.camSupportPowerSaving && deviceAdapter.pwTetherConnectMode == LT.Utilities.PwTether_OFF) {
                liveViewMenu.enabled = false
        }
        else {
                liveViewMenu.enabled = true
        }
    }
// IVC << Ver.1.9 << end << [THRBOXV100-144]
// IVC >> Ver.1.9 >> start >> No.2
//    function cameraMenuEnableHandler() {
//        if(deviceAdapter.btnAllCameraStatus === LT.Utilities.BtnAllCameraStatus_Checked) {
//            menuBtn.enabled = false;
//        }
//        else {
//            menuBtn.enabled = true;
//        }
//    }

    readonly property int controlItemSetting_enable: 0  // 設定を戻す
    readonly property int controlItemSetting_menu: 1    // Disable (MENU表示)
    readonly property int controlItemSetting_multi: 2   // Disable (マルチ表示)
    readonly property int controlItemSetting_streaming: 3   // Disable (ストリーミング中)
    function controlItemSetting(type) {
        if (type) {
            // ホワイトセット
            wbSettingsButton.enabled = false
            wbSettingsChecked = false
            lv_wbset_mode=false;
            utilities.setMouseCursor(0);
            // AFエリア表示
            afAreaButton.enabled = false
            afAreaChecked = false
            // ワンショットAF
            oneShotAFButton.enabled = false
            oneShotAFChecked = false
            // 水準器
            levelIndicatorButton.enabled = false
            levelIndicatorChecked = false
            // グリッド
            gridButton.enabled = false
            gridChecked = false
            // ガイドライン
            guidelineButton.enabled = false
            guidelineChecked = false
            // ヒストグラム
            histogramButton.enabled = false
            histogramChecked = false
            // 拡大倍率
            mfZoom.enabled = false
            mfZoomChecked = false
            // MF調整
            mfadjust.enabled = false
            // LV回転
            lvRotation.enabled = false
            lv_rotation_setting(true)
            // オーバーレイ表示
            lvOverlayPhotoEnabledSettingButton = false
            overlayButtonAlias.checked = false
            overlayPhotoFrame.visible = false
            // LV画質
            btnOptionLvImgQuality.isForcedDisable = true
            btnOptionLvImgQuality.enabled = false
            // 縦横比
            btnOptionAspectRatio.isForcedDisable = true
            btnOptionAspectRatio.enabled = false
            // プレビュー
            btnOptionRecPreview.isForcedDisable = true
            btnOptionRecPreview.enabled = false
            if(type === controlItemSetting_menu){
                // 電動ズーム
                isZoomCtrlEnable = false
            }else{
                // 電動ズーム
                zoomLensCtrlEnableSetting()
                zoomLensTeleSetting()
                zoomLensWideSetting()
                zoomLensLenSetting()
            }
        } else {
// IVC >> Ver.1.9 >> start >> [THRBOXV100-141]
            if(isMenuBtnChecked) {
                isMenuBtnChecked = false;
// IVC << Ver.1.9 << end << [THRBOXV100-141]
                // ホワイトセット
                wbSettingsChecked = wbSettingsChecked_Save
                if(wbSettingsChecked){
                    lv_wbset_mode=true;
                    utilities.setMouseCursor(1);
                }
                whiteBalanceSetting()
                // AFエリア表示
                afAreaButton.enabled = afAreaEnabled_Save
                afAreaChecked = afAreaChecked_Save
                // ワンショットAF
                oneShotAFButton.enabled = oneShotAFEnabled_Save
                oneShotAFChecked = oneShotAFChecked_Save
                // 水準器
                levelIndicatorButton.enabled = true
                levelIndicatorChecked = levelIndicatorChecked_Save
                // グリッド
                gridButton.enabled = true
                gridChecked = gridChecked_Save
                // ガイドライン
                guidelineButton.enabled = true
                guidelineChecked = guidelineChecked_Save
                // ヒストグラム
                histogramButton.enabled = true
                histogramChecked = histogramChecked_Save
                // 拡大倍率
                setMFZoom(mfZoomChecked_Save)
                setMFScale()
                // オーバーレイ表示は拡大倍率のチェック状態を参照する
                if(!mfZoom.checked) {
                    lvOverlayPhotoEnabledSettingButton = true
                } else {
                    lvOverlayPhotoEnabledSettingButton = false
                }
                overlayButtonAlias.checked = overlayButtonChecked_Save
                overlayPhotoFrame.visible = overlayButtonChecked_Save
                // MF調整
                setMFText()
                // LV回転
                lvRotation.enabled = true
                lv_rotation_setting(false)
                // 電動ズーム
                zoomLensCtrlEnableSetting()
                zoomLensTeleSetting()
                zoomLensWideSetting()
                zoomLensLenSetting()
                // LV画質
                btnOptionLvImgQuality.isForcedDisable = false
                btnOptionLvImgQuality.enabled = true
                imgQualitySetting()
                // 縦横比
                btnOptionAspectRatio.isForcedDisable = false
                aspectRatioSetting()
                // プレビュー
                btnOptionRecPreview.isForcedDisable = false
                recPreviewSetting()
// IVC >> Ver.1.9 >> start >> [THRBOXV100-141]
            }
// IVC << Ver.1.9 << end <<  [THRBOXV100-141]
        }
    }
// IVC << Ver.1.9 << end << No.2
    
    // LV回転の設定
    function lv_rotation_setting(isDisable){
        if(isDisable){
            // 現状を保存
            lv_rotation_mode_Save = lv_rotation_mode
            lv_rotation_Save = lv_rotation
            lvOverlayPhotoRotation_Save = lvOverlayPhotoRotation
            // 回転なしに設定
            lv_rotation_mode = false
            lv_rotation = 0
            autobotton.checked = false
        }else{
            // 元に戻す
            if(lv_rotation_mode_Save){
                lv_rotation_mode = lv_rotation_mode_Save
                lv_rotation = 0
                autobotton.checked = true
                overlayPhotoPopup.sliderRotation1.value = 0
                updatePhotoFrameXY()
                updateCursorScale()
            }else{
                lv_rotation = lv_rotation_Save
                if(lv_rotation == 360) {
                    lv_rotation = 0
                }
                lvOverlayPhotoFlagChangeRotation = 1
                lvOverlayPhotoRotation = lvOverlayPhotoRotation_Save
                if(lvOverlayPhotoRotation > 180)
                {
                   lvOverlayPhotoRotation = -(360 % lvOverlayPhotoRotation)
                }
                lvOverlayPhotoFrameAlias.rotation = lvOverlayPhotoRotation
                updateRotaOverlayPhoto()
                lvOverlayPhotoFlagChangeRotation = 0
                autobotton.checked = false
                lv_rotation_mode = false
                updatePhotoFrameXY()
                submitValueOverlaySetting()
                updateCursorScale()
            }
        }
    }
    
    function columnsSetting(){
        var item1Height = ctrlItem1.heightDefault
        var item1Rows = ctrlItem1Grid1.rowsDefault
        var histAreaHeight = histgramArea.heightDefault
        // ボタン非表示
        menuBtn.visible = false
        afAreaButton.visible = false

        if(deviceAdapter.recCtrlMenuEnable){
            // MENUボタン表示
            menuBtn.visible = true
            item1Height += btnHeight_normal + 1
            item1Rows += 1
            histAreaHeight -= btnHeight_normal + 1
        }
        if(deviceAdapter.afFramesMax !== LT.Utilities.AFFMax_315){
            // AFエリア表示ボタン表示
            afAreaButton.visible = true
            item1Height += btnHeight_normal + 1
            item1Rows += 1
            histAreaHeight -= btnHeight_normal + 1
        }

        // 行数、高さを設定
        ctrlItem1.height = item1Height
        ctrlItem1Grid1.rows = item1Rows
        // ヒストグラムエリアサイズ
        var histAreaWidth = histAreaHeight * histgramArea.aspect
        if((hist.width / histgramArea.aspect) < histAreaHeight){
            histAreaWidth = hist.width
            histAreaHeight = hist.width / histgramArea.aspect
        }
        histgramArea.width = histAreaWidth
        histgramArea.height = histAreaHeight
    }

    function lvImgQualityPopupClose(){
        LTSubFunction.console_debug.out("lvImgQualityPopupClose start")
        if(optionButtonPopup.visible == true) {
            LTSubFunction.console_debug.out("optionButtonPopup dismiss")
            optionButtonPopup.dismiss();
        }
    }

    function aspectRatioPopupClose(){
        LTSubFunction.console_debug.out("aspectRatioPopupClose start")
        if(optionButtonPopupAspect.visible == true) {
            LTSubFunction.console_debug.out("optionButtonPopupAspect dismiss")
            optionButtonPopupAspect.dismiss();
        }
    }

    function recPreviewPopupClose(){
        LTSubFunction.console_debug.out("recPreviewPopupClose start")
        if(optionButtonPopup.visible == true) {
            LTSubFunction.console_debug.out("optionButtonPopup dismiss")
            optionButtonPopup.dismiss();
        }
    }

    //function pinpoint_af_start(){
    //   //　AF.MF拡大開始
    //   if(deviceAdapter.focusMode==LT.Utilities.FM_MF){
    //       deviceAdapter.adp_LMX_def_lib_tag_rec_ctrl_mfa_start_req()
    //       mfZoom.checked=true
    //   } else if(deviceAdapter.autoFocusMode == LT.Utilities.AFM_Pinpoint) {
    //       deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE_PINPOINT_AF_START()
    //       mfZoom.checked=true
    //   }
    //}
//    function magnify_start(){
//        //　AF.MF拡大開始
//        LTSubFunction.console_debug.out("magnify_start")
//        if(deviceAdapter.focusMode==LT.Utilities.FM_MF){
//            switch(deviceAdapter.mfAssistMode) {
//            case LT.Utilities.MFASTM_Normal:
//                deviceAdapter.adp_LMX_func_api_Rec_Ctrl_MF_Assist_START_REQ(1)
//                break;
//            case LT.Utilities.MFASTM_Pinp:
//                deviceAdapter.adp_LMX_func_api_Rec_Ctrl_MF_Assist_START_REQ(2)
//                break;
//            }
//            mfZoom.checked=true
//        } else if(deviceAdapter.autoFocusMode == LT.Utilities.AFM_Pinpoint) {
//            deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE2_PINPOINT_ZOOMSTART();
//            mfZoom.checked=true
//        }
//    }
    //function maginfyr_set(){
    //    //倍率設定
    //    if(deviceAdapter.focusMode==LT.Utilities.FM_MF){
    //        deviceAdapter.adp_LMX_def_lib_tag_rec_ctrl_mfa_setratio_req()
    //        mfZoom.checked=true
    //    } else if(deviceAdapter.autoFocusMode == LT.Utilities.AFM_Pinpoint) {
    //        deviceAdapter.adp_LMX_func_api_Rec_Ctrl_AF_AE_PINPOINT_AF_MAGNIFY()
    //        mfZoom.checked=true
    //    }
    //}
}
