import QtQuick 2.15
import QtQml 2.2
import QtQuick.Window 2.3
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.1
import Qt.labs.platform 1.0 as Labs

import "qrc:/qml"
import LT 1.0 as LT
import "LTSubFunction.js" as LTSubFunction

Window {
    id: root

    LTLogCollector {
        id: ltLog

        logMajTagID: LT.TagDef.RTMajor_Usage
        logMedTagID: LT.TagDef.RTMed_Usage_Preferences
        logWindowName: "LTPreferenceWindow"
    }

    LTWindowStateSaver {
        id:windowState
        window: root
        defaultWidth: minimumWidth
        defaultHeight: minimumHeight
        targetWindow: LT.ApplicationSettings.WinList_Preference
    }

    flags:
        Qt.Dialog
      | Qt.CustomizeWindowHint
      | Qt.WindowTitleHint
      | Qt.WindowSystemMenuHint
//      | Qt.WindowMinimizeButtonHint
//    | Qt.WindowMaximizeButtonHint
//      | Qt. WindowCloseButtonHint
    |Qt.MSWindowsFixedSizeDialogHint

    modality: Qt.WindowModal//ApplicationModal

    //  ウィンドウの最小サイズと最大サイズを同じ値にして，リサイズできないようにする
    minimumWidth: prefColWidth1
    // ivc >> start >> USBTHRV140-24
//    minimumHeight: prefRowHeight*13+prefRowSpacing*12+prefRowHeight
    //minimumHeight: prefRowHeight*(13+(hlgShooting.visible?1:0)+(hlgTrans.visible?1:0))+prefRowSpacing*(12+(hlgShooting.visible?1:0)+(hlgTrans.visible?1:0))+prefRowHeight
    // IVC >> Ver.1.9 >> start >> No.7
    //minimumHeight: prefRowHeight*(13+(deviceAdapter.pscSupportHLG?2:0))+prefRowSpacing*(12+(deviceAdapter.pscSupportHLG?2:0))+prefRowHeight
    //使用状況送信削除のため変更
    //minimumHeight: prefRowHeight*(13+(deviceAdapter.pscSupportHLG?2:0)+(deviceAdapter.setupFilesCfgSetEnable?1:0)+(deviceAdapter.camFirmUpEnable?1:0)+(deviceAdapter.connectionType?1:0))
    //               +prefRowSpacing*(12+(deviceAdapter.pscSupportHLG?2:0)+(deviceAdapter.setupFilesCfgSetEnable?2:0)+(deviceAdapter.camFirmUpEnable?1:0)+(deviceAdapter.connectionType?1:0))
    //               +prefRowHeight
    minimumHeight: prefRowHeight*(mustRowItemNum+(deviceAdapter.pscSupportHLG?2:0)+(deviceAdapter.setupFilesCfgSetEnable?1:0)+(deviceAdapter.camFirmUpEnable?1:0)+(deviceAdapter.connectionType?1:0))
                   +prefRowSpacing*((mustRowItemNum+1)+(deviceAdapter.pscSupportHLG?2:0)+(deviceAdapter.setupFilesCfgSetEnable?2:0)+(deviceAdapter.camFirmUpEnable?1:0)+(deviceAdapter.connectionType?1:0))
                   +prefRowHeight
    // IVC << Ver.1.9 << end << No.7
    // ivc << end << USBTHRV140-24
    maximumWidth: minimumWidth
    maximumHeight: minimumHeight

    //  ウィンドウのサイズを最小/最大サイズにする
    width: minimumWidth
    height: minimumHeight

    title: qsTr("Preference")
    color: palette.backgroundLight//"transparent"

    /*!
        必ず表示する行の数
     */
    readonly property int mustRowItemNum: 11//13　いったん封印

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
        "checked": "#ffbf1f",
        "defaultColor": "#525356",
        "selectedColor": "#FFD600"
    }

    /*!
        Row size
     */
    readonly property double prefRowHeight: 35

    /*!
        Row spacing
     */
    readonly property double prefRowSpacing: 1

    /*!
        Column spacing
     */
    readonly property double prefColSpacing: 1

    /*!
        Column size (1 column)
     */
    readonly property double prefColWidth1: 323

    /*!
        Column size (2 column)
     */
    readonly property double prefColWidth2: 161

    /*!
        Column size (3 column)
     */
    readonly property double prefColWidth3: 107

    /*!
        テキストの色です
     */
    property color lblTextColor: "#808080"

    /*!
       Label height
     */
    property real lblHeight: 22

// IVC >> Ver.1.9 >> start >> No.3
    /*!
        F/W Contain Path
     */
    property  string fwPath
// IVC << Ver.1.9 << end << No.3
// IVC >> Ver 1.9 >> start >> CustomDialog
    property var fwDeviceUUID
// IVC << Ver.1.9 << end << CustomDialog
// IVC >> Ver 1.9 >> start >> No.1
    property bool isFirstTimePopup: true
// IVC << Ver 1.9 << end << No.1
   property bool success: false
    /*!
        Hung debugger
     */
    property real processPercent: 0.0
    property int processRate: 0

    property QtObject progressFWUPDlg2: null
    
    // FWUP進捗ダイアログを閉じる
    function progressFWUPDlg_dismiss() {
        if(!utilities.isMac()) {
            if(progressFWUPDlg2 != null) {
                if(progressFWUPDlg2.visible == true) {
                    progressFWUPDlg2.dismiss()
                    progressFWUPDlg2 = null
                }
            }


        } else {
             progressFWUPDlg1.visible = false
        }


//            objectcopy.setObjectAddOffsetSizeValue(0)
    }

    // FWUP進捗ダイアログ表示中かどうか
    function progressFWUPDlg_isVisible() {
        if(!utilities.isMac()) {
            if(progressFWUPDlg2 != null) {
                return progressFWUPDlg2.visible
            } else {
                return false
            }
        } else {
            return progressFWUPDlg1.visible
        }


    }

    // FWUP進捗ダイアログを表示
    function progressFWUPDlg_showDialog(arg) {
        LTSubFunction.console_debug.out("progressFWUPDlg_showDialog start")
        if(utilities.isMac()) {
            // IVC >> Ver.1.9 >> start >> [THRBOXV100-188]
            progressFWUPTimer.pastTime = 0
            // IVC << Ver.1.9 << end << [THRBOXV100-188]
            progressFWUPDlg1.visible = arg
        } else {
            var component = Qt.createComponent("LTProgressFWUPDlg.qml")
            if (component.status === Component.Error) {
                console.log("Err createComponent LTProgressFWUPDlg: " + component.errorString())
            }
            progressFWUPDlg2 = null
            if (component.status == Component.Ready) {
                progressFWUPDlg2 = component.createObject(null);
                progressFWUPDlg2.onVisibleChanged.connect(function() {
                    if(progressFWUPDlg2.visible==false) {
                        // do nothing
                    }
                });
    //            progressFWUPDlg2.setProgressFWUPText2(qsTr("confirm_message_7"))//"取り込み中"

                progressFWUPDlg2.visible = arg
            } else {
                progressFWUPDlg2 = component.createObject(null);
                progressFWUPDlg2.onVisibleChanged.connect(function() {
                    if(progressMovieDlg2.visible==false) {
                        // do nothing

                    }
                });
    //            progressFWUPDlg2.setProgressFWUPText2(qsTr("confirm_message_7"))//"取り込み中"
                progressFWUPDlg2.visible = arg
                component.onStatusChanged = function(status) {
                    if (component.status == Component.Ready) {
                        progressFWUPDlg2 = component.createObject(null);
                        progressFWUPDlg2.onVisibleChanged.connect(function() {
                            if(progressMovieDlg2.visible==false) {
                                // do nothing

                            }
                        });
    //                    progressFWUPDlg2.setProgressFWUPText2(qsTr("confirm_message_7"))//"取り込み中"

                        progressFWUPDlg2.visible = arg
                    }
                }
            }
        }

    }

    function progressFWUPDlg_offsetSizeInit() {

        progressFWUPTimer.running = true
        progressFWUPDlg_showDialog(true)//progressMovieDlg1.visible = true
        progressFWUPDlg_offsetSizeDispInit()
    }

    // FWUP進捗ダイアログ初期化
    function progressFWUPDlg_offsetSizeDispInit() {
        var text1 = qsTr("fwup_message_1")
        var text2 = "00:00"
        var text3 = qsTr("fwup_message_2")
        var text4 = qsTr("title_message")

        var text5 = String(parseInt(deviceAdapter.firmware_update_get_data_frame()))

        var text6 = "%"

        // IVC >> Ver.1.9 >> start >> [THRBOXV100-188]
        progressFWUPTimer.pastTime = 0
        // IVC << Ver.1.9 << end << [THRBOXV100-188]
        if(!utilities.isMac()) {

            progressFWUPDlg2.setProgressFWUPText1(text4)
            progressFWUPDlg2.setProgressFWUPText2(text1 + text2 + "  "+text5+ text6 + text3)

            progressFWUPDlg2.setProgressFWUPBar(0.0)
        } else {
            progressFWUPText1.text = text4
            progressFWUPText2.text = text1 + text2 + "  "+text5+ text6 + text3
            progressFWUPBar.value = 0.0

        }
    }

    // FWUP進捗ダイアログ更新
    function progressFWUPDlg_offsetSize() {
        //console.log("progressMovieDlg_offsetSize start");
        //console.log("    dataSize = " + objectcopy.objectAddDataSize);
        var text1 = qsTr("fwup_message_1")//"(経過時間 "
        var text2 = " "
        if(parseInt(progressFWUPTimer.pastTime/60) < 10) {
            text2 += "0"
        }
        var text3 = String(parseInt(progressFWUPTimer.pastTime/60))
        var text4 = ":"
        if(parseInt(progressFWUPTimer.pastTime%60) < 10) {
            text4 = ":0"
        }
        var text5 = String(parseInt(progressFWUPTimer.pastTime%60))

        var text6 = String(parseInt(deviceAdapter.firmware_update_get_data_frame()))

        // IVC >> Ver.1.9 >> start >> [THRBOXV100-163]
        //var text7 = "% "
        var text7 = "%"
        // IVC << Ver.1.9 << end << [THRBOXV100-163]

        var text12 = qsTr("fwup_message_2")//")"
        if(!utilities.isMac()) {
            progressFWUPDlg2.setProgressFWUPText2(text1 + text2 + text3 + text4 + text5 +"  "+text6+ text7 + text12)


            progressFWUPDlg2.setProgressFWUPBar(deviceAdapter.firmware_update_get_data_frame()/100)
        } else {
            progressFWUPText2.text = text1 + text2 + text3 + text4 + text5 +"  "+text6+ text7 + text12
            progressFWUPBar.value = deviceAdapter.firmware_update_get_data_frame()/100
        }
// IVC >> Ver.1.9 >> start >> [THRBOXV100-121]
        //deviceAdapter.firmwareUpdateCompleted.connect(function (){success = true})
// IVC << Ver.1.9 << end << [THRBOXV100-121]
// IVC << Ver.1.9 >> start >> [THRBOXV100-97]
        //if(deviceAdapter.firmware_update_get_data_frame()/100 >=1.0 || success == true) {
/*
        if( ((deviceAdapter.firmware_update_get_data_frame()/100 >=1.0)
             &&(deviceAdapter.firmware_update_get_result() === true))) {
// IVC << Ver.1.9 << end << [THRBOXV100-97]

            success = deviceAdapter.firmware_update_get_result()

            progressFWUPTimer.running = false
            // IVC << Ver.1.9 >> start >> [THRBOXV100-97]
            deviceAdapter.firmware_update_finish_progress()
            // IVC << Ver.1.9 << end << [THRBOXV100-97]
            delayAfter(500, function() {
              progressFWUPDlg_dismiss()//progressMovieDlg1.visible = false
              if (success)
              {
                  message_box.text = qsTranslate("lumixtether::CustomDialog", "Message_Complete")
                  message_box.icon = LT.StandardIcon.Information
                  message_box.standardButtons = LT.StandardButton.Ok
                  message_box.visible = true
                  // IVC >> Ver.1.9 >> start >> [THRBOXV100-87] - [THRBOXV100-88]
                  // IVC >> Ver.1.9 >> start >> CustomDialog
//                  deviceAdapter.trigger_window_dialog(LT.Utilities.Success_NotificationDialog, LT.Utilities.Information_Icon, true);
                  // IVC << Ver.1.9 << end << CustomDialog
                  // IVC << Ver.1.9 << end << [THRBOXV100-87] - [THRBOXV100-88]
              }
              else
              {
                  message_box.text = qsTranslate("lumixtether::CustomDialog", "Message_Failed")
                  message_box.icon = LT.StandardIcon.Critical
                  message_box.standardButtons = LT.StandardButton.Ok
                  message_box.visible = true
                  // IVC >> Ver.1.9 >> start >> [THRBOXV100-87] - [THRBOXV100-88]
                  // IVC >> Ver.1.9 >> start >> CustomDialog
//                  deviceAdapter.trigger_window_dialog(LT.Utilities.Failed_NotificationDialog, LT.Utilities.Critical_Icon, true);
                  // IVC << Ver.1.9 << end << CustomDialog
                  // IVC << Ver.1.9 << end << [THRBOXV100-87] - [THRBOXV100-88]
              }
              success = false
          })

        }
*/

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

    // IVC << Ver 1.9 << end << No.3

    /*!

    /*!
        Validate and save before closing
     */
    function validateOnClosing() {
        //Validate URL
        if (btnOptionStoFolder.value == LT.ApplicationSettings.StoFolderType_User) {
            if (!utilities.validateUrl(tfStoFolderUrl.text)) {
                //TODO: show dialog
                //console.log("Preference: VALIDATE >>>>>> StoreFolderUrl: ", tfStoFolderUrl.text);
                return false;
            }
        }

        //Validate folder name
//        if (btnOptionFolderName.value == LT.ApplicationSettings.FolNameType_User) {
//            if (!utilities.validateFolderName(tfFolderName.text)) {
//                //TODO: show dialog
//                console.log("Preference: VALIDATE >>>>>> FolderName: ", tfFolderName.text);
//                return false;
//            }
//        }

        //Validate URL
//        if (btnOptionImgViewer.value == LT.ApplicationSettings.ImageViewerType_Ext) {
//            if (!utilities.validateUrl(tfImageViewerUrl.text)) {
//                //TODO: show dialog
//                console.log("Preference: VALIDATE >>>>>> ImageViewerUrl: ", tfImageViewerUrl.text);
//                return false;
//            }
//        }

// IVC >> Ver.1.9 >> start >> No.1.1
//        var storeLocationType_old = applicationSettings.storeLocationType
//        applicationSettings.storeLocationType = btnOptionStoLoc.value;
//        if(applicationSettings.storeLocationType != btnOptionStoLoc.value) {
//            btnOptionStoLoc.value = storeLocationType_old
//        }
        applicationSettings.setStoreLocationType();
// IVC << Ver.1.9 << end << No.1.1
        applicationSettings.storeFolderType = btnOptionStoFolder.value;
        if (btnOptionStoFolder.value == LT.ApplicationSettings.StoFolderType_User) {
            applicationSettings.storeFolderUrl = tfStoFolderUrl.text;
            //applicationSettings.storeFolderDate = btnOptionStoFolderDate.value;
        } else {
            applicationSettings.storeFolderUrl = "";
        }
        applicationSettings.storeFolderDate = btnOptionStoFolderDate.value;
        applicationSettings.storeFolderCamera = btnOptionStoFolderCamera.value

        applicationSettings.folderNameType = btnOptionFolderName.value;
        if (btnOptionFolderName.value == LT.ApplicationSettings.FolNameType_User) {
            applicationSettings.folderNamePrefix = tfFolderName.text;

            ltLog.log(LT.TagDef.RecLvl_Info,
                      LT.TagDef.RTScr_Usage_Preferences_CaptureFileNameUser,
                      "File Name Prefix",
                      tfFolderName.text);

            if(tfStartNumber.text == "") {
                applicationSettings.fileNumber = 0
            } else {
                applicationSettings.fileNumber = parseInt(tfStartNumber.text, 10)-1
            }

            ltLog.log(LT.TagDef.RecLvl_Info,
                      LT.TagDef.RTScr_Usage_Preferences_CaptureFileStartNumber,
                      "File Start Number",
                      tfStartNumber.text);
        }
        applicationSettings.storeFileNameCamera = btnOptionFileNameCamera.value

// ivc >> start >> No.4
        //applicationSettings.jpgTransferType = btnOptionJpgTrans.value;
// ivc << end << No.4

// ivc >> start >> No.4
        applicationSettings.rawTransferType = btnOptionRawTrans.value;      //RAWの転送
        // incase support HLG
        if(deviceAdapter.pscSupportHLG)
        {
           applicationSettings.hlgTransferType = btnOptionHlgTrans.value;      //HLGの転送
        }
// ivc << end << No.4

        applicationSettings.displayReviewType = btnOptionDisReview.value;
//        applicationSettings.imageViewerType = btnOptionImgViewer.value;
//        if (btnOptionImgViewer.value == LT.ApplicationSettings.ImageViewerType_Ext) {
//            applicationSettings.imageViewerUrl = tfImageViewerUrl.text;
//        }

        //console.log("btnOptionVerChkStartup.value: ", btnOptionVerChkStartup.value);
        applicationSettings.versionCheckType = btnOptionVerChkStartup.value;

        //applicationSettings.logPermission = btnOptionLogPer.value;

        // 転送確認ダイアログの表示切り替え
        applicationSettings.transConfirmDlgType = btnOptionConfirmDlgItem.value;

// ivc >> start >> No.4
        deviceAdapter.updateCopyPcMask();
// ivc << end << No.4
        return true;
    }

    /*!
        Initialize default/saved button value
     */
    function initializeBtnValue(btn) {
        // IVC >> Ver.1.9 >> start >> [THRBOXV100-96]
        if(btn.target === "saveCameraSetting" || btn.target === "restoreCameraSetting" ||
            btn.target === "firmwareUpdate"
            // IVC >> Ver.1.9 >> start >> Enhance Security
            || btn.target === "changePassword"
            // IVC << Ver.1.9 << end << Enhance Security
        ){
            btn.optionSelect(btn.value)
        }
        // IVC << Ver.1.9 << end << [THRBOXV100-96]
        else
        btn.optionSelect(applicationSettings[btn.target])
//        btn.value = applicationSettings[btn.target];


//        var components = btn.componentsProvider[btn.target];

//        for (var i = 0; i < components.length; ++i) {
//            if (btn.value == components[i].properties.value) {
//                btn.optionText = components[i].properties.optionText;
//                break;
//            }
//        }
    }

    /*!
        Initialize default/saved text field value
     */
    function initializeTextFieldValue(textfield, target) {
        var scrTagId = 0;
        var txtFile;
        switch (textfield) {
        case tfStoFolderUrl:
            scrTagId = LT.TagDef.RTScr_Usage_Preferences_StorageFolderPath;
            break;
        case tfFolderName:
            scrTagId = LT.TagDef.RTScr_Usage_Preferences_CaptureFileNameUser;
            break;
        case tfStartNumber:
            scrTagId = LT.TagDef.RTScr_Usage_Preferences_CaptureFileStartNumber;
            break;
        default:
            break;
        }

        ltLog.log(LT.TagDef.RecLvl_Info,
                  scrTagId,
                  target + "ini",
                  applicationSettings[target]);

        switch (textfield) {
        case tfStoFolderUrl:
        case tfFolderName:
            textfield.text = applicationSettings[target];
            break;
        case tfStartNumber:
            textfield.text = applicationSettings[target]+1;
            break;
        default:
            break;
        }
    }

    // 設定項目の初期値設定
    function initializePreference() {
// IVC >> Ver.1.9 >> start >> No.1.1
        //initializeBtnValue(btnOptionStoLoc);
        var initStoLoc = applicationSettings.getStoreLocationTypeFromFile(deviceAdapter.camCurrentSelectedSerialNo);
        btnOptionStoLoc.optionText = optionComponentsProvider.storeLocationType[initStoLoc].properties.optionText;
// IVC << Ver.1.9 << end << No.1.1
        initializeBtnValue(btnOptionStoFolder);
        initializeTextFieldValue(tfStoFolderUrl, "storeFolderUrl");
        initializeBtnValue(btnOptionStoFolderDate);
        initializeBtnValue(btnOptionStoFolderCamera);
        initializeBtnValue(btnOptionFolderName);
        initializeTextFieldValue(tfFolderName, "folderNamePrefix");
        initializeTextFieldValue(tfStartNumber, "fileNumber");
        storeFileNameCameraSetting()
// ivc >> start >> No.4
        //initializeBtnValue(btnOptionJpgTrans);
// ivc << end << No.4
// ivc >> start >> No.4
        initializeBtnValue(btnOptionRawTrans);

        // incase support HLG
        if(deviceAdapter.pscSupportHLG)
        {
            btnOptionHlgShooting.optionSelect(deviceAdapter.pscHlgShootingType);
            initializeBtnValue(btnOptionHlgTrans);
        }

        // Update status of HLG shooting and transfer
        hlgSupport.visible = deviceAdapter.pscSupportHLG
        hlgSupport.enabled = deviceAdapter.pscEnableHLG
        //hlgTrans.visible = deviceAdapter.pscSupportHLG
// ivc << end << No.4
        initializeBtnValue(btnOptionDisReview);
// IVC >> Ver.1.9 >> start >> No.3
        initializeBtnValue(btnOptionConfirmDlgItem);
        firmwareUpdate.visible = deviceAdapter.camFirmUpEnable
        // IVC >> Ver.1.9 >> start >> [THRBOXV100-96]
        btnStartUpdate.value = deviceAdapter.camera_list_get_selected_camera_uuid()
        // IVC << Ver.1.9 << end << [THRBOXV100-96]
        initializeBtnValue(btnStartUpdate);
// IVC << Ver.1.9 << end << No.3
// IVC >> Ver.1.9 >> start >> No.7
        cameraSetting.visible = deviceAdapter.setupFilesCfgSetEnable
        // IVC >> Ver.1.9 >> start >> [THRBOXV100-96]
        btnSaveSetting.value = deviceAdapter.camera_list_get_selected_camera_uuid()
        btnRestoreSetting.value = deviceAdapter.camera_list_get_selected_camera_uuid()
        // IVC << Ver.1.9 << end << [THRBOXV100-96]
        initializeBtnValue(btnSaveSetting);
        initializeBtnValue(btnRestoreSetting);
// IVC << Ver.1.9 << end << No.7
// IVC >> Ver.1.9 >> start >> Enhance Security
        btnchangePW.value = deviceAdapter.camera_list_get_selected_camera_uuid()
        initializeBtnValue(btnchangePW);
// IVC << Ver.1.9 << end << Enhance Security
        initializeBtnValue(btnOptionVerChkStartup);
        //initializeBtnValue(btnOptionLogPer);
    }

//    property LTIndicatorPopup indicator

    function onSendLogFinished(result) {
        logCollector.onRequestFinished.disconnect(root.onSendLogFinished);
        indicator.dismiss();

        //console.log("onSendLogFinished",result, confirmDialog)
        if (result) {
            confirmDialog.text = qsTr("Sending Log Successfully");
            confirmDialog.icon = LT.StandardIcon.Information;
        } else {
            confirmDialog.text = qsTr("Sending Log Failed");
            confirmDialog.icon = LT.StandardIcon.Warning;
        }

        confirmDialog.visible = true;
    }
    function popupClose() {
        utilities.selectFolderClose()
        versionDialog.visible = false
        progressFWUPDlg_dismiss()
        message_box.visible = false
        visible = false
        btnStoFolderBrowser.openFlg = false
        // IVC >> Ver.1.9 >> start >> [THRBOXV100-155]
//        utilities.closeMessage(qsTr("Version"));
        // IVC << Ver.1.9 << end << [THRBOXV100-155]
        deviceAdapter.ptpip_enhance_security_close_password_dialog();
    }

// ivc >> start >> No.4
    function cameraHlgChangedValue()
    {
        if(deviceAdapter.pscSupportHLG)
        {
            btnOptionHlgShooting.popup.dismiss();
            btnOptionHlgShooting.optionSelect(deviceAdapter.pscHlgShootingType);
        }
    }
// ivc << end << No.4
// IVC >> Ver.1.9 >> start >> No.7
    function isAllCameraPowerSaving() {
        for(var i = 0; i < deviceAdapter.camera_list_number_of_camera(); i++) {
            if(deviceAdapter.camera_list_get_camera_power_mode(i)) {
                return false;
            }
        }
        // すべて電源OFF
        return true;
    }

    function isCameraListEmpty() {
        return deviceAdapter.camera_list_get_number_of_displayed_camera() === 0 ? true : false;
    }
// IVC << Ver.1.9 << end << No.7

    function storeFileNameCameraSetting(){
        if(btnOptionStoFolderCamera.value === LT.ApplicationSettings.StoFolderCamera_On){
            btnOptionFileNameCamera.enabled = false
            btnOptionFileNameCamera.optionSelect(LT.ApplicationSettings.StoFolderCamera_Off)
        }else{
            btnOptionFileNameCamera.enabled = true
            initializeBtnValue(btnOptionFileNameCamera);
        }
    }

    // FWUP開始
    function startFWUpdate() {
        progressFWUPDlg_offsetSizeInit()
        // Start F/W update
        var ret = deviceAdapter.adp_LMX_func_api_FirmwareUpdate_start(fwDeviceUUID, fwPath,true);
        if (ret == false) {
            var success = deviceAdapter.firmware_update_get_result()
            progressFWUPTimer.running = false
            delayAfter(500, function() {
              progressFWUPDlg_dismiss()
              if (success)
              {
                  message_box.text = "<html><div style='margin-right: 30px;'>" + qsTranslate("lumixtether::CustomDialog", "Message_Complete") + "</div></html>"
                  message_box.icon = LT.StandardIcon.Information
                  message_box.standardButtons = LT.StandardButton.Ok
                  message_box.visible = true
                  // IVC >> Ver.1.9 >> start >> [THRBOXV100-87] - [THRBOXV100-88]
                  // IVC >> Ver.1.9 >> start >> CustomDialog
//                  deviceAdapter.trigger_window_dialog(LT.Utilities.Success_NotificationDialog, LT.Utilities.Information_Icon, false)
                  // IVC << Ver.1.9 << end << CustomDialog
                  // IVC << Ver.1.9 << end << [THRBOXV100-87] - [THRBOXV100-88]
              }
              else
              {
                  message_box.text = "<html><div style='margin-right: 30px;'>" + qsTranslate("lumixtether::CustomDialog", "Message_Failed") + "</div></html>"
                  message_box.icon = LT.StandardIcon.Critical
                  message_box.standardButtons = LT.StandardButton.Ok
                  message_box.visible = true
                  // IVC >> Ver.1.9 >> start >> [THRBOXV100-87] - [THRBOXV100-88]
                  // IVC >> Ver.1.9 >> start >> CustomDialog
//                  deviceAdapter.trigger_window_dialog(LT.Utilities.Failed_NotificationDialog, LT.Utilities.Critical_Icon, false)
                  // IVC << Ver.1.9 << end << CustomDialog
                  // IVC << Ver.1.9 << end << [THRBOXV100-87] - [THRBOXV100-88]
              }
              success = false
            })
        }
    }
// IVC >> Ver.1.9 >> start >> [THRBOXV100-121]
    // FWUP終了
    function finishFWUpdate() {
        if( ((deviceAdapter.firmware_update_get_data_frame()/100 >=1.0)
             &&(deviceAdapter.firmware_update_get_result() === true))) {
            // 成功
            success = deviceAdapter.firmware_update_get_result()
            progressFWUPTimer.running = false
            deviceAdapter.firmware_update_finish_progress()
            delayAfter(500, function() {
                progressFWUPDlg_dismiss()//progressMovieDlg1.visible = false
                message_box.text = "<html><div style='margin-right: 30px;'>" + qsTranslate("lumixtether::CustomDialog", "Message_Complete") + "</div></html>"
                message_box.icon = LT.StandardIcon.Information
                message_box.standardButtons = LT.StandardButton.Ok
                message_box.visible = true
                success = false
            })
        }else{
            // 失敗
            success = deviceAdapter.firmware_update_get_result()
            progressFWUPTimer.running = false
            deviceAdapter.firmware_update_finish_progress()
            delayAfter(500, function() {
                progressFWUPDlg_dismiss()//progressMovieDlg1.visible = false
                message_box.text = "<html><div style='margin-right: 30px;'>" + qsTranslate("lumixtether::CustomDialog", "Message_Failed") + "</div></html>"
                message_box.icon = LT.StandardIcon.Critical
                message_box.standardButtons = LT.StandardButton.Ok
                message_box.visible = true
                success = false
            })
        }
/*
// IVC >> Ver.1.9 >> start >> [THRBOXV100-164] 
        if (false === deviceAdapter.firmware_update_get_result()) {
// IVC << Ver.1.9 << end << [THRBOXV100-164] 
            progressFWUPTimer.running = false
            deviceAdapter.firmware_update_finish_progress()
            delayAfter(500, function() {
                progressFWUPDlg_dismiss()
                message_box.text = qsTranslate("lumixtether::CustomDialog", "Message_Failed")
                message_box.icon = LT.StandardIcon.Critical
                message_box.standardButtons = LT.StandardButton.Ok
                message_box.visible = true
//                deviceAdapter.trigger_window_dialog(LT.Utilities.Failed_NotificationDialog, LT.Utilities.Critical_Icon, false)
            })
// IVC >> Ver.1.9 >> start >> [THRBOXV100-164] 
        }
// IVC << Ver.1.9 << end << [THRBOXV100-164] 
*/
    }
// IVC << Ver.1.9 << end << [THRBOXV100-121]

// ivc >> start >> USBTHRV140-24
    onMinimumHeightChanged: {
        height = minimumHeight
    }
// ivc << end << USBTHRV140-24

    onVisibleChanged: {
        preferenceWindowVisibleSetting()
     }

    Component.onCompleted: {
        deviceAdapter.cameraStatusChanged.connect(root.cameraStatusSetting)
        deviceAdapter.cameraStatusCompleteNotify.connect(cameraStatusCompleteNotify)
        utilities.preferenceWindowActiveNotify.connect(preferenceWindowActiveSetting)
// IVC >> Ver.1.9 >> start >> CustomDialog
//        deviceAdapter.customDialogFWOnAcceptedSignal.connect(root.startFWUpdate)
// IVC << Ver.1.9 << end << CustomDialog

// ivc >> start >> No.4
        deviceAdapter.hlgShootingTypeChanged.connect(cameraHlgChangedValue)
// ivc << end << No.4
        // ivc >> start >> USBTHRV140-44
        deviceAdapter.pscSupportHLGChanged.connect(cameraHlgChangedValue)
        // ivc << end << USBTHRV140-44
// IVC >> Ver.1.9 >> start >> [THRBOXV100-121]
        deviceAdapter.firmwareUpdateCompleted.connect(finishFWUpdate);
// IVC << Ver.1.9 << end << [THRBOXV100-121]
        deviceAdapter.camConnectStatusChanged.connect(root.connectCameraSetting);
        deviceAdapter.initSetupTetherModeChanged.connect(root.initSetupTetherMode);
        deviceAdapter.switchCameraNotify.connect(root.initSetupTetherMode)
        deviceAdapter.cameraListChanged.connect(root.cameraListSetting)
    }

    function connectCameraSetting() {
        if(deviceAdapter.camConnectStatus == LT.Utilities.CamConnectSts_Connecting) {
            // show Panel Mask
            maskpanel.visible = true;
        }
        else if(deviceAdapter.camConnectStatus == LT.Utilities.CamConnectSts_Unknown ||
                deviceAdapter.camConnectStatus == LT.Utilities.CamConnectSts_Success ||
                deviceAdapter.camConnectStatus == LT.Utilities.CamConnectSts_SuccessBackground
                ) {
            // hide Panel Mask
            maskpanel.visible = false;
        }
    }

    function initSetupTetherMode(){
        // ポップアップクローズ
        optionButtonPopupClose()
        // 表示項目を更新
        preferenceWindowVisibleSetting()
    }

    function cameraListSetting(){
        // applicationSettings.targetCameraListを更新する
        isFirstTimePopup = true
    }

    function preferenceWindowVisibleSetting(){
        //USBTHRV140-24: Update height
// IVC >> Ver.1.9 >> start >> No.7
        //root.minimumHeight = prefRowHeight*(13+(deviceAdapter.pscSupportHLG?2:0))+prefRowSpacing*(12+(deviceAdapter.pscSupportHLG?2:0))+prefRowHeight
        //使用状況送信削除のため変更
        //root.minimumHeight = prefRowHeight*(13+(deviceAdapter.pscSupportHLG?2:0)+(deviceAdapter.setupFilesCfgSetEnable?1:0)+(deviceAdapter.camFirmUpEnable?1:0)+(deviceAdapter.connectionType?1:0))
        //                   +prefRowSpacing*(12+(deviceAdapter.pscSupportHLG?2:0)+(deviceAdapter.setupFilesCfgSetEnable?1:0)+(deviceAdapter.camFirmUpEnable?1:0)+(deviceAdapter.connectionType?1:0))
        //                   +prefRowHeight
        root.minimumHeight = prefRowHeight*(mustRowItemNum+(deviceAdapter.pscSupportHLG?2:0)+(deviceAdapter.setupFilesCfgSetEnable?1:0)+(deviceAdapter.camFirmUpEnable?1:0)+(deviceAdapter.connectionType?1:0))
                           +prefRowSpacing*((mustRowItemNum+1)+(deviceAdapter.pscSupportHLG?2:0)+(deviceAdapter.setupFilesCfgSetEnable?1:0)+(deviceAdapter.camFirmUpEnable?1:0)+(deviceAdapter.connectionType?1:0))
                           +prefRowHeight
// IVC << Ver.1.9 << end << No.7
        root.height = minimumHeight
        //USBTHRV140-24

        if (visible) {
            //utilities.selectFolderOpen()
            initializePreference();
        }
        utilities.preferenceWindowVisibleChanged(root.visible)
// IVC >> Ver.1.9 >> start >> No.3
        btnStartUpdate.enabled = isAllCameraPowerSaving() || isCameraListEmpty() ? false : true;
        btnStartUpdate.disabled = isAllCameraPowerSaving() || isCameraListEmpty() ? true : false;               // 2024/11 Qt6.2 対応
// IVC << Ver.1.9 << end << No.3
// IVC >> Ver.1.9 >> start >> No.7
        btnOptionStoLoc.enabled = isAllCameraPowerSaving() || isCameraListEmpty() ? false : true;
        btnSaveSetting.enabled = isAllCameraPowerSaving() || isCameraListEmpty() ? false : true;
        btnSaveSetting.disabled = isAllCameraPowerSaving() || isCameraListEmpty() ? true : false;               // 2024/11 Qt6.2 対応
        btnRestoreSetting.enabled = isAllCameraPowerSaving() || isCameraListEmpty() ? false : true;
        btnRestoreSetting.disabled = isAllCameraPowerSaving() || isCameraListEmpty() ? true : false;            // 2024/11 Qt6.2 対応
// IVC << Ver.1.9 << end << No.7
// IVC >> Ver.1.9 >> start >> Enhance Security
        btnchangePW.enabled = isAllCameraPowerSaving() || isCameraListEmpty() ? false : true;
// IVC << Ver.1.9 << end << Enhance Security
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
        if((deviceAdapter.cameraStatus == LT.Utilities.CamStatus_MovRec_Others) ||
           (deviceAdapter.cameraStatus == LT.Utilities.CamStatus_Playing) ||
           (deviceAdapter.cameraStatus == LT.Utilities.CamStatus_Processing) ||
           (deviceAdapter.cameraStatus == LT.Utilities.CamStatus_Menu_Displayed)) {
            LTSubFunction.console_debug.out("PreferenceView::cameraStatusSetting cameraStatus " + deviceAdapter.cameraStatus)
            optionButtonPopupClose()
            maskpanel.visible = true
        } else {
            LTSubFunction.console_debug.out("PreferenceView::cameraStatusSetting cameraStatus " + deviceAdapter.cameraStatus)
        }
    }

    function cameraStatusCompleteNotify() {
        LTSubFunction.console_debug.out("PreferenceView::cameraStatusCompleteNotify")
        if((deviceAdapter.cameraStatus != LT.Utilities.CamStatus_MovRec_Others) &&
           (deviceAdapter.cameraStatus != LT.Utilities.CamStatus_Playing) &&
           (deviceAdapter.cameraStatus != LT.Utilities.CamStatus_Processing) &&
           (deviceAdapter.cameraStatus != LT.Utilities.CamStatus_Menu_Displayed)) {
            if(maskpanel.visible) {
                maskpanel.visible = false
            }
        }
    }

    function preferenceWindowActiveSetting() {
        LTSubFunction.console_debug.out("PreferenceView::preferenceWindowActiveSetting")
        root.raise()
        root.requestActivate()
    }

    function optionButtonPopupClose(){
        if(optionButtonPopup.visible === true){
            optionButtonPopup.dismiss()
        }
    }

    LT.MessageBox{
        id: message_box
        modality: Qt.ApplicationModal
        title: "LUMIX Tether"
        visible: false
    }

    /*
        背景 - Background
     */
    Rectangle {
        anchors {
            fill: parent
        }
        color: palette.backgroundLight
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
        z: 30
    }

    LTPreferenceAgreementPopup{
        id: agreementPopup

        onOkClicked: {
            //console.log("Preference -- onOkClicked")
            if (agreementPopup.type == "preferenceAuto") {
                //btnOptionLogPer.onOKClicked();
            } else if (agreementPopup.type == "preferenceManual") {
                //btnManualSendLog.onOKClicked();
            }
        }

        onCancelClicked: {
            if (agreementPopup.type == "preferenceAuto") {
                //btnOptionLogPer.onCancelClicked()
            } else if (agreementPopup.type == "preferenceManual") {
                //btnManualSendLog.onCancelClicked();
            }
        }
    }

    LTIndicatorPopup {
        id: indicator
    }

    Column {
        id: panelMain

        anchors.fill: parent
        spacing: prefRowSpacing

        // 保存場所
        Item {
            id: stoLoc

            width: parent.width
            height: panelStoLoc.height

            LTFlashGridLayout {
                id: panelStoLoc

                colMulti: prefColWidth1
                rowMulti: prefRowHeight

                columns: 1
                rows: 1
                rowSpacing: prefRowSpacing
                columnSpacing: prefColSpacing

                LTPreferenceOptionButton {
                    id: btnOptionStoLoc

                    Layout.rowSpan : 1
                    Layout.columnSpan: 1

                    width: panelStoLoc.prefWidth(this)
                    height: panelStoLoc.prefHeight(this)

                    type: "optionWithTextPref"
                    labelText: qsTr("Storage Location")
                    target: "storeLocationType"
                    popup: optionButtonPopup
                    componentsProvider: optionComponentsProvider
                    rootParent: panelMain

                    logCol: ltLog
                    logScrTagID: LT.TagDef.RTScr_Usage_Preferences_StorageLocation
                    logFile: "Storage Location"
                }
            }
        }

        // 取り込みフォルダー
        Item {
            id: stoFolder

            width: parent.width
            height: panelStoFolder.height

            LTFlashGridLayout {
                id: panelStoFolder

                colMulti: prefColWidth1
                rowMulti: prefRowHeight

                columns: 1
                rows: 2
                rowSpacing: prefRowSpacing
                columnSpacing: prefColSpacing

                LTPreferenceOptionButton {
                    id: btnOptionStoFolder

                    Layout.rowSpan : 1
                    Layout.columnSpan: 1

                    width: panelStoFolder.prefWidth(this)
                    height: panelStoFolder.prefHeight(this)

                    type: "optionWithTextPref"
                    labelText: qsTr("Storage Folder")
                    target: "storeFolderType"
                    popup: optionButtonPopup
                    componentsProvider: optionComponentsProvider
                    rootParent: panelMain

                    logCol: ltLog
                    logScrTagID: LT.TagDef.RTScr_Usage_Preferences_StorageFolder
                    logFile: "Storage Folder"

                    onValueChanged: {
                        if (btnOptionStoFolder.value == LT.ApplicationSettings.StoFolderType_User) {
                            btnStoFolderBrowser.enabled = true;
                            btnStoFolderBrowser.disabled = false;
                            tfStoFolderUrl.enabled = true;
                            //btnOptionStoFolderDate.enabled = true;
                        } else {
                            btnStoFolderBrowser.enabled = false;
                            btnStoFolderBrowser.disabled = true;
                            tfStoFolderUrl.enabled = false;
                            //btnOptionStoFolderDate.enabled = false;
                        }
                    }
                }

                Item {
                    id: panelStoFolderBrowser

                    Layout.rowSpan : 1
                    Layout.columnSpan: 1

                    width: panelStoFolder.prefWidth(this)
                    height: panelStoFolder.prefHeight(this)

                    Rectangle {
                        anchors.fill: parent
                        color: palette.backgroundDark
                    }

                    Row {
                        anchors.fill: parent
                        spacing: 0

                        LTTextField {
                            id: tfStoFolderUrl
                            width: parent.width*0.75
                            height: prefRowHeight
                            enabled: true
                            placeholderText: qsTr("Storage Folder URL Placeholder")
                            //入力できないようにしてフォーカス枠が出ないようにする
                            readOnly: true
                            background: Rectangle {
                                border.width: 0
                            }

                            //inputMask: "000.000.000.000;0"
                            //validator: RegExpValidator {
                            //    regExp: /^((?:[0-1]?[0-9]?[0-9]|2?[0-4]?[0-9]|25[0-5]).){3}(?:[0-1]?[0-9]?[0-9]|2?[0-4]?[0-9]|25[0-5])$/
                            //}
                        }

                        LTRectangleButton {
                            id: btnStoFolderBrowser

                            width: parent.width - tfStoFolderUrl.width - parent.spacing
                            height: prefRowHeight

                            enabled: true

                            type:"action"
                            buttonText: qsTr("Browser")

                            strokeWidth: 2
                            strokeColor: palette.backgroundDark
                            fillColor: palette.backgroundLight

                            logCol: ltLog
                            logScrTagID: LT.TagDef.RTScr_Usage_Preferences_StorageFolderPath
                            logFile: "Storage Folder Browser"

                            property bool openFlg: false

                            onClicked: {
                                tfStoFolderUrl.focus = true
                                tfFolderName.focus = true
                                tfStartNumber.focus = true
                                tfStoFolderUrl.focus = false
                                tfFolderName.focus = false
                                tfStartNumber.focus = false
                                if(utilities.isMac()) {
                                    fileDialogStoFolder.visible = true
                                } else {
                                    if(openFlg) {
                                        return
                                    }
                                    openFlg = true
                                    var sel = utilities.selectFolder()
                                    openFlg = false
                                    if(sel.length != 0) {
                                        tfStoFolderUrl.text = sel
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // 日付でサブフォルダを自動生成
        Item {
            id: stoDate

            width: parent.width
            height: panelStoDate.height

            LTFlashGridLayout {
                id: panelStoDate

                colMulti: prefColWidth1
                rowMulti: prefRowHeight

                columns: 1
                rows: 1
                rowSpacing: prefRowSpacing
                columnSpacing: prefColSpacing

                LTPreferenceOptionButton {
                    id: btnOptionStoFolderDate

                    Layout.rowSpan : 1
                    Layout.columnSpan: 1

                    width: panelStoDate.prefWidth(this)
                    height: panelStoDate.prefHeight(this)

                    type: "optionWithTextPref"
                    labelText: qsTr("Storage Folder Date")
                    target: "storeFolderDate"
                    popup: optionButtonPopup
                    componentsProvider: optionComponentsProvider
                    rootParent: panelMain

                    logCol: ltLog
                    logScrTagID: LT.TagDef.RTScr_Usage_Preferences_StorageFolderDate
                    logFile: "Storage Folder Date"
                }
            }
        }

        // カメラごとにサブフォルダーを自動生成
        Item {
            id: stoCamera
            //いったん封印
            visible: false

            width: parent.width
            height: panelStoCamera.height

            LTFlashGridLayout {
                id: panelStoCamera

                colMulti: prefColWidth1
                rowMulti: prefRowHeight

                columns: 1
                rows: 1
                rowSpacing: prefRowSpacing
                columnSpacing: prefColSpacing

                LTPreferenceOptionButton {
                    id: btnOptionStoFolderCamera

                    Layout.rowSpan : 1
                    Layout.columnSpan: 1

                    width: panelStoCamera.prefWidth(this)
                    height: panelStoCamera.prefHeight(this)

                    type: "optionWithTextPref"
                    labelText: qsTr("Storage Folder Camera")
                    target: "storeFolderCamera"
                    popup: optionButtonPopup
                    componentsProvider: optionComponentsProvider
                    rootParent: panelMain
                    
                    onValueChanged: {
                        storeFileNameCameraSetting()
                    }
                }
            }
        }

        // 取り込みファイル名
        Item {
            id: folderName

            width: parent.width
            height: panelFolderName.height

            LTFlashGridLayout {
                id: panelFolderName

                colMulti: prefColWidth1
                rowMulti: prefRowHeight

                columns: 1
                rows: 3
                rowSpacing: prefRowSpacing
                columnSpacing: prefColSpacing

                LTPreferenceOptionButton {
                    id: btnOptionFolderName

                    Layout.rowSpan : 1
                    Layout.columnSpan: 1

                    width: panelFolderName.prefWidth(this)
                    height: panelFolderName.prefHeight(this)

                    type: "optionWithTextPref"
                    labelText: qsTr("Captured File Name")
                    target: "folderNameType"
                    popup: optionButtonPopup
                    componentsProvider: optionComponentsProvider
                    rootParent: panelMain

                    logCol: ltLog
                    logScrTagID: LT.TagDef.RTScr_Usage_Preferences_CaptureFileName
                    logFile: "Captured File Name"

                    onValueChanged: {
                        if (btnOptionFolderName.value == LT.ApplicationSettings.FolNameType_User) {
                            tfFolderName.enabled = true;
                            tfFolderName.editingFinished()
                            tfStartNumber.enabled = true;
                            tfStartNumber.editingFinished()
                            mask1.visible = false
                            mask2.visible = false
                        } else {
                            tfFolderName.enabled = false;
                            tfStartNumber.enabled = false;
                            mask1.visible = true
                            mask2.visible = true
                        }
                    }
                }

                Item {
                    id: panelFolderNameInput

                    Layout.rowSpan : 1
                    Layout.columnSpan: 1

                    width: panelFolderName.prefWidth(this)
                    height: panelFolderName.prefHeight(this)

                    Rectangle {
                        anchors.fill: parent
                        color: palette.backgroundDark
                    }

                    Row {
                        anchors.fill: parent
                        spacing: 0

                        LTStylishText {
                            type: text_style_preferSubline
                            text: qsTr("Captured File Prefix Character")

                            color: ((tfFolderName.enabled == true)? "#C8C8C8": "#505050")
                            width: parent.width/2
                            height: prefRowHeight
                            leftPadding: 30
                        }
                        LTTextField {
                            id: tfFolderName
                            width: parent.width/2
                            height: prefRowHeight
                            horizontalAlignment: TextInput.AlignRight

                            //validator: RegExpValidator { regExp: /[0-9A-Za-z_]+/ }
                            //validator: RegExpValidator { regExp: /^^([a-zA-Z0-9!#$%&'()-=~^{}+.,_][^*/><?\\|;]*)$/ }
                            //validator: RegExpValidator { regExp: /[a-zA-Z0-9!#$%&'()-=~{}@+;,._]{1,}/ }
                            //validator: RegExpValidator { regExp: /[a-zA-Z&&[^*?<>|]]{1,}/ }
                            //validator: RegExpValidator { regExp: /[!#-)+-.0-9;=@-Z_-~]{1,}/ }
                            //validator: RegExpValidator { regExp: /[a-zA-Z0-9!#$%&'()=~{}@+;,._^^-]{1,}/ }
                            validator: RegularExpressionValidator { regularExpression: /[^\x00-\x1F\x7F\\/:*?"<>|]{1,20}/ }
                        }
                    }

                    Rectangle {
                        id: mask1
                        x: tfFolderName.x
                        y: tfFolderName.y
                        width: tfFolderName.width
                        height: tfFolderName.height

                        visible: false
                        color: palette.backgroundDark
                        //opacity: 0.5
                        LTStylishText {
                            text: tfFolderName.text

                            width: tfFolderName.width
                            height: tfFolderName.height
                            rightPadding: 10

                            type: text_style_preferMark
                        }
                        MouseArea {
                            anchors {
                                fill: parent
                            }
                            hoverEnabled: true
                            onClicked: {
                            }
                        }
                    }
                }

                Item {
                    id: panelStartNumberInput

                    Layout.rowSpan : 1
                    Layout.columnSpan: 1

                    width: panelFolderName.prefWidth(this)
                    height: panelFolderName.prefHeight(this)

                    Rectangle {
                        anchors.fill: parent
                        color: palette.backgroundDark
                    }

                    Row {
                        anchors.fill: parent
                        spacing: 0

                        LTStylishText {
                            type: text_style_preferSubline
                            text: qsTr("Captured File Start Number")

                            color: ((tfStartNumber.enabled == true)? "#C8C8C8": "#505050")
                            width: parent.width/2
                            height: prefRowHeight
                            leftPadding: 30
                        }
                        LTTextField {
                            id: tfStartNumber
                            width: parent.width/2
                            height: prefRowHeight
                            horizontalAlignment: TextInput.AlignRight

                            validator: IntValidator {bottom: 1; top: 9999;}
                        }
                    }

                    Rectangle {
                        id: mask2
                        x: tfStartNumber.x
                        y: tfStartNumber.y
                        width: tfStartNumber.width
                        height: tfStartNumber.height

                        visible: false
                        color: palette.backgroundDark
                        //opacity: 0.5
                        LTStylishText {
                            text: tfStartNumber.text
                            width: tfStartNumber.width
                            height: tfStartNumber.height
                            rightPadding: 10

                            type: text_style_preferMark
                        }
                        MouseArea {
                            anchors {
                                fill: parent
                            }
                            hoverEnabled: true
                            onClicked: {
                            }
                        }
                    }
                }
            }
        }

        // 取り込みファイル名に機器名称を含める
        Item {
            id: fileNameCamera
            //いったん封印
            visible: false

            width: parent.width
            height: panelFileNameCamera.height

            LTFlashGridLayout {
                id: panelFileNameCamera

                colMulti: prefColWidth1
                rowMulti: prefRowHeight

                columns: 1
                rows: 1
                rowSpacing: prefRowSpacing
                columnSpacing: prefColSpacing

                LTPreferenceOptionButton {
                    id: btnOptionFileNameCamera

                    Layout.rowSpan : 1
                    Layout.columnSpan: 1

                    width: panelFileNameCamera.prefWidth(this)
                    height: panelFileNameCamera.prefHeight(this)

                    type: "optionWithTextPref"
                    labelText: qsTr("Store File Name Camera")
                    target: "storeFileNameCamera"
                    popup: optionButtonPopup
                    componentsProvider: optionComponentsProvider
                    rootParent: panelMain
                }
            }
        }

// ivc >> start >> No.4
        /*        Item {
                    id: jpgTrans

                    width: parent.width
                    height: panelJpgTrans.height

                    LTFlashGridLayout {
                        id: panelJpgTrans

                        colMulti: prefColWidth1
                        rowMulti: prefRowHeight

                        columns: 1
                        rows: 1
                        rowSpacing: prefRowSpacing
                        columnSpacing: prefColSpacing

                        LTPreferenceOptionButton {
                            id: btnOptionJpgTrans

                            Layout.rowSpan : 1
                            Layout.columnSpan: 1

                            width: panelJpgTrans.prefWidth(this)
                            height: panelJpgTrans.prefHeight(this)

                            type: "optionWithTextPref"
                            labelText: qsTr("JPEG Transfer Only")
                            target: "jpgTransferType"
                            popup: optionButtonPopup
                            componentsProvider: optionComponentsProvider
                            rootParent: panelMain

                            logCol: ltLog
                            logScrTagID: LT.TagDef.RTScr_Usage_Preferences_JPEGTransfer
                            logFile: "JPEG Transfer"
                        }
                    }
                }
        */
// ivc << end << No.4

// ivc >> start >> No.4
        // RAWの転送
        Item {
            id: rawTrans

            width: parent.width
            height: panelRawTrans.height

            LTFlashGridLayout {
                id: panelRawTrans

                colMulti: prefColWidth1
                rowMulti: prefRowHeight

                columns: 1
                rows: 1
                rowSpacing: prefRowSpacing
                columnSpacing: prefColSpacing

                LTPreferenceOptionButton {
                    id: btnOptionRawTrans

                    Layout.rowSpan : 1
                    Layout.columnSpan: 1

                    width: panelRawTrans.prefWidth(this)
                    height: panelRawTrans.prefHeight(this)

                    type: "optionWithTextPref"
                    labelText: qsTr("RAW TRANSFER")
                    target: "rawTransferType"
                    popup: optionButtonPopup
                    componentsProvider: optionComponentsProvider
                    rootParent: panelMain

                    logCol: ltLog
                    logScrTagID: LT.TagDef.RTScr_Usage_Preferences_RawTransfer
                    logFile: "RAW Transfer"
                }
            }
        }

       // HLG Support
        Item {
            id: hlgSupport
            width: parent.width
            height: panelHlgSupport.height

            LTFlashGridLayout {
                id: panelHlgSupport

                colMulti: prefColWidth1
                rowMulti: prefRowHeight

                columns: 1
                rows: 2
                rowSpacing: prefRowSpacing
                columnSpacing: prefColSpacing

                // HLG撮影
                LTPreferenceOptionButton {
                    id: btnOptionHlgShooting

                    Layout.rowSpan : 1
                    Layout.columnSpan: 1

                    width: panelHlgSupport.prefWidth(this)
                    height: panelHlgSupport.prefHeight(this)

                    value: 0
                    type: "optionWithTextPref"
                    labelText: qsTr("HLG SHOOTING")
                    target: "hlgShootingType"
                    popup: optionButtonPopup
                    componentsProvider: optionComponentsProvider
                    rootParent: panelMain

                    logCol: ltLog
                    logScrTagID: LT.TagDef.RTScr_Usage_Preferences_HlgShooting
                    logFile: "HLG Shooting"

                }

                // HLGの転送
                LTPreferenceOptionButton {
                    id: btnOptionHlgTrans

                    Layout.rowSpan : 1
                    Layout.columnSpan: 1

                    width: panelHlgSupport.prefWidth(this)
                    height: panelHlgSupport.prefHeight(this)

                    type: "optionWithTextPref"
                    labelText: qsTr("HLG Transfer")
                    target: "hlgTransferType"
                    popup: optionButtonPopup
                    componentsProvider: optionComponentsProvider
                    rootParent: panelMain

                    logCol: ltLog
                    logScrTagID: LT.TagDef.RTScr_Usage_Preferences_HlgTransfer
                    logFile: "HLG Transfer"
                }
            }
        }
// ivc << end << No.4

        // レビュー画像の自動表示
        Item {
            id: disReview

            width: parent.width
            height: panelDisReview.height

            LTFlashGridLayout {
                id: panelDisReview

                colMulti: prefColWidth1
                rowMulti: prefRowHeight

                columns: 1
                rows: 1
                rowSpacing: prefRowSpacing
                columnSpacing: prefColSpacing

                LTPreferenceOptionButton {
                    id: btnOptionDisReview

                    Layout.rowSpan : 1
                    Layout.columnSpan: 1

                    width: panelDisReview.prefWidth(this)
                    height: panelDisReview.prefHeight(this)

                    type: "optionWithTextPref"
                    labelText: qsTr("Auto Display Review Images")
                    target: "displayReviewType"
                    popup: optionButtonPopup
                    componentsProvider: optionComponentsProvider
                    rootParent: panelMain

                    logCol: ltLog
                    logScrTagID: LT.TagDef.RTScr_Usage_Preferences_AutoDisplayReview
                    logFile: "Display Review"
                }
            }
        }

        // 転送確認ダイアログの表示切り替え
        Item {
            id: confirmDlgItem
            visible: false

            width: parent.width
            height: panelConfirmDlgItem.height

            LTFlashGridLayout {
                id: panelConfirmDlgItem

                colMulti: prefColWidth1
                rowMulti: prefRowHeight

                columns: 1
                rows: 1
                rowSpacing: prefRowSpacing
                columnSpacing: prefColSpacing

                LTPreferenceOptionButton {
                    id: btnOptionConfirmDlgItem

                    Layout.rowSpan : 1
                    Layout.columnSpan: 1

                    width: panelConfirmDlgItem.prefWidth(this)
                    height: panelConfirmDlgItem.prefHeight(this)

                    type: "optionWithTextPref"
                    labelText: qsTr("Show Trans Confirm Dialog")
                    target: "transConfirmDlgType"
                    popup: optionButtonPopup
                    componentsProvider: optionComponentsProvider
                    rootParent: panelMain
                }
            }
        }

// IVC >> Ver.1.9 >> start >> No.3
        // ファームウェアアップデート
        Item {
            id: firmwareUpdate

            width: parent.width
            height: panelFirmWareUpdate.height

            LTFlashGridLayout {
                id: panelFirmWareUpdate

                colMulti: prefColWidth1
                rowMulti: prefRowHeight

                columns: 1
                rows: 1
                rowSpacing: prefRowSpacing
                columnSpacing: prefColSpacing
                Item {
                    width: parent.width
                    height: parent.height


                    Row {
                        anchors.fill: parent
                        spacing: 0


                        LTPreferenceOptionButton {
                            id: btnFirmwareUpdate

                            Layout.rowSpan : 1
                            Layout.columnSpan: 1
                            isShowPopup: false

                            width: panelFirmWareUpdate.prefWidth(this)*0.75
                            height: panelFirmWareUpdate.prefHeight(this)
                            enabled: false
                            disabled: true
                            textColor: "#ffffff"
                            type: "optionWithTextPref"

                            labelText: qsTr("Update F/W")
                            componentsProvider: optionComponentsProvider
                            rootParent: panelMain
                        }

                        LTPreferenceOptionButton {
                            id: btnStartUpdate

                            width: parent.width - btnFirmwareUpdate.width - parent.spacing
                            height: panelFirmWareUpdate.prefHeight(this)

                            type: "action_noBold"
                            buttonText: qsTr("Start")
                            target: "firmwareUpdate"
                            popup: optionButtonPopup
                            rootParent: panelMain
                            enabled: isAllCameraPowerSaving() || isCameraListEmpty() ? false : true
                            disabled: isAllCameraPowerSaving() || isCameraListEmpty() ? true : false            // 2024/11 Qt6.2 対応

                            strokeWidth: 1
                            strokeColor: palette.backgroundDark
                            fillColor: palette.backgroundLight

                            onStartFirmwareUpdate: {
                                startFWUpdate()
                            }
                        }
                    }
                }
            }
        }

        // FWUP進捗ダイアログ
        Window {
            id: progressFWUPDlg1
            x: Screen.width / 2 - progressFWUPDlg1.width / 2
            y: Screen.height / 2 - progressFWUPDlg1.height / 2
            maximumWidth: 600
            maximumHeight: 260
            minimumWidth: maximumWidth
            minimumHeight: maximumHeight

            flags:Qt.Window | Qt.CustomizeWindowHint | Qt.WindowTitleHint //| Qt.WindowSystemMenuHint | Qt. WindowCloseButtonHint
            modality: Qt.ApplicationModal

            title: "LUMIX Tether"
            visible: false

            readonly property var palette: {
                "dialogBackground": "#ffffff",
                "dialogButtonFieldBackground": "#f0f0f0",
                "dialogBorder": "#dfdfdf"

            }


            LTStylishText {
                id: progressFWUPText1
                x: progressFWUPDlg1.width / 2 - progressFWUPText1.width / 2
                y: 30
                type: text_style_wbmainProgressTitle
                text: ""
            }

            LTStylishText {
                id: progressFWUPText2
                x: progressFWUPDlg1.width / 2 - progressFWUPText2.width / 2
                y: progressFWUPText1.y + progressFWUPText1.height + 30
        //        font.bold : true
                //font.pointSize : 16
                type: text_style_wbmainProgressContent
                text: ""
            }


            ProgressBar {
                id: progressFWUPBar
                x: (progressFWUPDlg1.width) / 2 - progressFWUPBar.width / 2
                y: progressFWUPText2.y + progressFWUPText2.height + 25
                width: progressFWUPDlg1.width - 100
                value: 0
            }


        }
 // IVC << Ver.1.9 << end << No.3

// IVC >> Ver.1.9 >> start >> No.7
        // カメラ設定
        Item {
            id: cameraSetting

            width: parent.width
            height: panelCameraSetting.height

            LTFlashGridLayout {
                id: panelCameraSetting

                colMulti: prefColWidth1
                rowMulti: prefRowHeight

                columns: 1
                rows: 1
                rowSpacing: prefRowSpacing
                columnSpacing: prefColSpacing

                Item {
                    width: parent.width
                    height: parent.height

                    Row {
                        anchors.fill: parent
                        spacing: 0

                        LTPreferenceOptionButton {
                            id: btnCameraSetting

                            Layout.rowSpan : 1
                            Layout.columnSpan: 1

                            width: panelCameraSetting.prefWidth(this)*0.50
                            height: panelCameraSetting.prefHeight(this)
                            enabled: false
                            disabled: true
                            textColor: "#ffffff"
                            type: "optionWithTextPref"
                            labelText: qsTr("Camera Setting")
                            //popup: optionButtonPopup
                            componentsProvider: optionComponentsProvider
                            rootParent: panelMain

        //                  logCol: ltLog
        //                  logScrTagID: LT.TagDef.RTScr_Usage_Preferences_AutoDisplayReview
        //                  logFile: "Camera Setting"
                        }

                        LTPreferenceOptionButton {
                            id: btnSaveSetting

                            width: parent.width - btnCameraSetting.width*1.50 - parent.spacing
                            height: panelCameraSetting.prefHeight(this)

                            type: "action_noBold"
                            buttonText: qsTr("Camera_setting_save")
                            target: "saveCameraSetting"
                            popup: optionButtonPopup
                            rootParent: panelMain
                            enabled: isAllCameraPowerSaving() || isCameraListEmpty() ? false : true
                            disabled: isAllCameraPowerSaving() || isCameraListEmpty() ? true : false            // 2024/11 Qt6.2 対応

                            strokeWidth: 1
                            strokeColor: palette.backgroundDark
                            fillColor: palette.backgroundLight
        //                        logCol: ltLog
        //                        logScrTagID:
        //                        logFile: "Start Updating Firmware"

                        }

                        LTPreferenceOptionButton {
                            id: btnRestoreSetting

                            width: parent.width - btnCameraSetting.width*1.50 - parent.spacing
                            height: panelCameraSetting.prefHeight(this)

                            type: "action_noBold"
                            buttonText: qsTr("Camera_setting_restore")
                            target: "restoreCameraSetting"
                            popup: optionButtonPopup
                            rootParent: panelMain
                            enabled: isAllCameraPowerSaving() || isCameraListEmpty() ? false : true
                            disabled: isAllCameraPowerSaving() || isCameraListEmpty() ? true : false            // 2024/11 Qt6.2 対応

                            strokeWidth: 1
                            strokeColor: palette.backgroundDark
                            fillColor: palette.backgroundLight
        //                        logCol: ltLog
        //                        logScrTagID:
        //                        logFile: "Start Updating Firmware"
                        }
                    }
                }
            }
        }
// IVC << Ver.1.9 << end << No.7

// IVC >> Ver.1.9 >> start >> Enhance Security
        //Camera Password
        Item {
            id: cameraPasswd
            width: parent.width
            height: panelCameraPW.height
            visible: (deviceAdapter.connectionType == 1)
            LTFlashGridLayout {
                id: panelCameraPW
                colMulti: prefColWidth1
                rowMulti: prefRowHeight
                columns: 1
                rows: 1
                rowSpacing: prefRowSpacing
                columnSpacing: prefColSpacing
                Item {
                    width: parent.width
                    height: parent.height
                    Row {
                        anchors.fill: parent
                        spacing: 0
                        LTPreferenceOptionButton {
                            id: btncameraPW
                            Layout.rowSpan : 1
                            Layout.columnSpan: 1
                            isShowPopup: false
                            width: panelCameraPW.prefWidth(this)*0.75
                            height: panelCameraPW.prefHeight(this)
                            enabled: false
                            disabled: true
                            textColor: "#ffffff"
                            type: "optionWithTextPref"
                            labelText: qsTr("Camera P/W")
                            componentsProvider: optionComponentsProvider
                            rootParent: panelMain
                        }

                        LTPreferenceOptionButton {
                            id: btnchangePW
                            width: parent.width - btncameraPW.width - parent.spacing
                            height: panelCameraPW.prefHeight(this)
                            type: "action_noBold"
                            buttonText: qsTr("Change")
                            target: "changePassword"
                            popup: optionButtonPopup
                            rootParent: panelMain
                            enabled: isAllCameraPowerSaving() || isCameraListEmpty() ? false : true
                            disabled: deviceAdapter.connectionType === 1 ? false : true        // 表示・非表示の切替の為に指定しておく
                            strokeWidth: 1
                            strokeColor: palette.backgroundDark
                            fillColor: palette.backgroundLight
                        }
                    }
                }
            }
        }
// IVC << Ver.1.9 << end << Enhance Security

        // 起動時のアプリケーション更新確認
        Item {
            id: verChkStartup

            width: parent.width
            height: panelVerChkStartup.height

            LTFlashGridLayout {
                id: panelVerChkStartup

                colMulti: prefColWidth1
                rowMulti: prefRowHeight

                columns: 1
                rows: 1
                rowSpacing: prefRowSpacing
                columnSpacing: prefColSpacing

                LTPreferenceOptionButton {
                    id: btnOptionVerChkStartup

                    Layout.rowSpan : 1
                    Layout.columnSpan: 1

                    width: panelVerChkStartup.prefWidth(this)
                    height: panelVerChkStartup.prefHeight(this)

                    type: "optionWithTextPref"
                    labelText: qsTr("Version Check at Startup")
                    target: "versionCheckType"
                    popup: optionButtonPopup
                    componentsProvider: optionComponentsProvider
                    rootParent: panelMain

                    logCol: ltLog
                    logScrTagID: LT.TagDef.RTScr_Usage_Preferences_VersionCheck
                    logFile: "Version Check at Startup"
                }

            }
        }

// IVC >> Ver.1.9 >> start >> No.3
        // FWUP進捗ダイアログ更新タイマー
        Timer {
            id: progressFWUPTimer
            interval: 1000//1秒
            running: false
            repeat: true
            property int pastTime: 0
            onTriggered: {
                pastTime += 1
                // HUNG debugger
                root.processPercent += 0.1
                root.processRate +=10
                root.progressFWUPDlg_offsetSize()
            }
        }
// IVC << Ver.1.9 << end << No.3

        // 使用状況の送信機能の削除（LUMIX Tether for Multicam 1.3/LUMIX Tether 2.0 より）
        /*
        Item {
            id: logPermission

            width: parent.width
            height: panelLogPer.height

            LTFlashGridLayout {
                id: panelLogPer

                colMulti: prefColWidth1
                rowMulti: prefRowHeight

                columns: 1
                rows: 2 // 2 + 3 placeholders
                rowSpacing: prefRowSpacing
                columnSpacing: prefColSpacing

                LTPreferenceOptionButton {
                    id: btnOptionLogPer

                    Layout.rowSpan : 1
                    Layout.columnSpan: 1

                    width: panelLogPer.prefWidth(this)
                    height: panelLogPer.prefHeight(this)

                    type: "optionWithTextPref"
                    labelText: qsTr("Allow to record log")
                    target: "logPermission"
                    popup: optionButtonPopup
                    componentsProvider: optionComponentsProvider
                    rootParent: panelMain
                    isShowPopup: false //stop show popup onClicked

                    logCol: ltLog
                    logScrTagID: LT.TagDef.RTScr_Usage_Preferences_UsageDataTransmission
                    logFile: "Log Permission"

                    onClicked: {
                        if (btnOptionLogPer.value == LT.ApplicationSettings.LogPer_On) {
                            btnOptionLogPer.showPopup()
                        } else {
                            agreementPopup.type = "preferenceAuto";
                            agreementPopup.present();
                        }
                    }

                    function onOKClicked() {
                        btnOptionLogPer.optionSelect(LT.ApplicationSettings.LogPer_On);
                    }

                    function onCancelClicked() {
                        btnOptionLogPer.optionSelect(LT.ApplicationSettings.LogPer_Off);
                    }
                }

                LTRectangleButton {
                    id: btnManualSendLog

                    Layout.rowSpan : 1
                    Layout.columnSpan: 1

                    width: panelLogPer.prefWidth(this)
                    height: panelLogPer.prefHeight(this)

                    type:"optionWithTextPref"
                    labelText: qsTr("ManualSendLog")

                    strokeWidth: 0
                    fillColor: palette.backgroundDark

                    logCol: ltLog
                    logScrTagID: LT.TagDef.RTScr_Usage_Preferences_SendUsageData
                    logFile: "Send Usage"

                    onClicked: {
                        agreementPopup.type = "preferenceManual";
                        agreementPopup.present();
                    }

                    function onOKClicked() {
                        //console.log("Preference -- btnManualSendLog -- onOKClicked")
                        indicator.present(root);
                        logCollector.onRequestFinished.connect(root.onSendLogFinished);
                        logCollector.sendLog(LT.TagDef.RecSend_Manual);
                    }

                    function onCancelClicked() {
                        //do nothing
                    }

                    MessageDialog {
                        id: confirmDialog
                        modality: Qt.WindowModal
                        buttons: MessageDialog.Ok
//                        icon: StandardIcon.NoIcon

                        title: "LUMIX Tether"
                        visible: false

                        onAccepted: {
                            confirmDialog.visible = false;
                        }
                    }
                }

                // Placeholder
                Rectangle {
                    id: placeholder

                    Layout.rowSpan: 3
                    Layout.columnSpan: 1

                    width: panelLogPer.prefWidth(this)
                    height: panelLogPer.prefHeight(this)

                    color: palette.backgroundDark
                }
            }
        }
        //*/

        // バージョン情報
        Item {
            id: version

            width: parent.width
            height: panelVersion.height

            LTFlashGridLayout {
                id: panelVersion

                colMulti: prefColWidth1
                rowMulti: prefRowHeight

                columns: 1
                rows: 1 // 2 + 3 placeholders
                rowSpacing: prefRowSpacing
                columnSpacing: prefColSpacing

                LTRectangleButton {
                    id: btnVersion

                    Layout.rowSpan : 1
                    Layout.columnSpan: 1

                    width: panelVersion.prefWidth(this)
                    height: panelVersion.prefHeight(this)

                    type:"optionWithTextPref"
                    labelText: qsTr("Version")

                    strokeWidth: 0
                    fillColor: palette.backgroundDark

                    logCol: ltLog
                    logScrTagID: LT.TagDef.RTScr_Usage_Preferences_Version
                    logFile: "Version"

                    onClicked: {
                        var text = "";
//                        if(utilities.isMac()) {
                            text += "<HTML>";
                            text += qsTr("VersionApplicationName");
                            text += utilities.get_APPLICATION_VERSION_STRING();
                            text += "<br>";
                            text += "<nobr>";
                            text += qsTr("VersionCompanyName");
                            text += "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;";
                            text += "</nobr>";
                            text += "</HTML>";
                            versionDialog.text = text;
                            versionDialog.visible = true;
//                        } else {
//                            text += qsTr("VersionApplicationName");
//                            text += utilities.get_APPLICATION_VERSION_STRING();
//                            text += "\n";
//                            text += qsTr("VersionCompanyName");
//                            text += "     ";
//                            // IVC >> Ver.1.9 >> start >> [THRBOXV100-29]
//                            //utilities.informationMessage(text);
//                            var title = qsTr("Version");
//                            utilities.informationMessage(title, text);
//                            // IVC << Ver.1.9 << end << [THRBOXV100-29]
//                        }
                    }

                    // バージョン情報ダイアログ
                    //MessageDialog {
                    LT.MessageBox{
                        id: versionDialog
                        modality: Qt.ApplicationModal
                        standardButtons: LT.StandardButton.Ok
                        icon: LT.StandardIcon.Information

                        title: qsTr("Version")
                        visible: false
                    }
                }
            }
        }
    }

    // 保存・キャンセル ボタン
    Item {
        id: panelSaveCancel

        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
        height: prefRowHeight+2

        Rectangle {
            anchors.fill: parent
            color: palette.backgroundDark
        }

        Row {
            anchors {
                fill: parent
                margins: 3
            }

            spacing: 3

            LTRectangleButton {
                width: (parent.width - parent.spacing)/2
                height: prefRowHeight - parent.spacing/2

                type:"action"
                buttonText: qsTr("Save")

                fillColor: palette.backgroundLight

                logCol: ltLog
                logScrTagID: LT.TagDef.RTScr_Usage_Preferences_Save
                logFile: "Save"

                onClicked: {
                    if (validateOnClosing()) {
                        hide();
                    }
                    //次回表示時のために初期状態に戻す
                    isFirstTimePopup = true
                }
            }

            LTRectangleButton {
                width: (parent.width - parent.spacing)/2
                height: prefRowHeight - parent.spacing/2

                type:"action"
                buttonText: qsTr("Cancel")

                fillColor: palette.backgroundLight

                logCol: ltLog
                logScrTagID: LT.TagDef.RTScr_Usage_Preferences_Cancel
                logFile: "Cancel"

                onClicked: {
                    hide();
                    //次回表示時のために初期状態に戻す
                    isFirstTimePopup = true
                }
            }
        }
    }
    // file dialog
    Labs.FolderDialog {
        id: fileDialogStoFolder
        title: qsTr("Choose Storage Location")
        visible: false

        onAccepted: {
            tfStoFolderUrl.text = utilities.qUrlToLocalFile(folder);

            ltLog.log(LT.TagDef.RecLvl_Info,
                      LT.TagDef.RTScr_Usage_Preferences_StorageFolderPath,
                      "Choose Storage Location",
                      "");
        }
    }
//    FileDialog {
//        id: fileDialogStoFolder
//        title: qsTr("Choose Storage Location")
//        selectFolder: true
//        visible: false

//        onAccepted: {
//            tfStoFolderUrl.text = utilities.qUrlToLocalFile(fileUrl);

//            ltLog.log(LT.TagDef.RecLvl_Info,
//                      LT.TagDef.RTScr_Usage_Preferences_StorageFolderPath,
//                      "Choose Storage Location",
//                      "");
//        }
//    }
    /*
      カメラ操作中に全てのコントロールを押せなくする。
     */
    Rectangle {
        id: maskpanel
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
                //root.dismiss();
            }
        }
    }
}

