import QtQuick 2.6
// IVC >> Ver.1.9 >> start >> No.7
import Qt.labs.platform
// IVC << Ver.1.9 << end << No.7
import QtQuick.Dialogs as Dlg
import "qrc:/qml"
import LT 1.0 as LT

/*! \qmltype LTOptionButton
    \inqmlmodule LT

    \brief
    状態を保持するボタンです

    LTOptionButtonPopup によって状態を選択する機能を提供します．
 */
LTRectangleButton {
    id: root

    property bool isShowPopup: true
    /*!
        root view for calculating popup position
     */
    property var rootParent

    /*!
        ApplicationSettings オブジェクト，ならびに LTOptionButton::componentsProvider のプロパティ名です
     */
    property string target

    /*!
        状態を選択するポップアップ LTOptionButtonPopup です
     */
    property var popup

    /*!
        ポップアップに表示するコンポーネントの組を提供するオブジェクトです
     */
    property var componentsProvider


// IVC >> Ver.1.9 >> start >> No.1
    property bool secondPopup

    property var currentCamera

    property var currentSerialNo

    property var allCameraStoLoc
// IVC << Ver.1.9 << end << No.1

// IVC >> Ver.1.9 >> start >> No.7
    property var dynamicComponentsProvider: []

    signal startFirmwareUpdate()

    LTOptionComponentsProvider {
        id: optionComponentsProvider
    }
// IVC >> Ver.1.9 >> start >> No.3
    FileDialog {
        id: firmwareUpdateFileDialog
        fileMode: FileDialog.OpenFile
        selectedNameFilter.index: 1
        nameFilters: ["All Files (*.*)", "bin (*.bin)"]
        onAccepted: {
            var path = firmwareUpdateFileDialog.file.toString();
            path = path.replace(/^(file:\/{3})/,"");
            console.log("FilePath:"+path)
            fwPath = path;
            fwDeviceUUID = deviceUUID
            fwupConfirmDialog.visible = true
// IVC >> Ver.1.9 >> start >> CustomDialog
//            deviceAdapter.trigger_window_dialog(LT.Utilities.FirmwareUpdate_ConfirmationDialog, LT.Utilities.Question_Icon, true);
// IVC << Ver.1.9 << end << CustomDialog
        }
        property var deviceUUID
    }
// IVC << Ver.1.9 << end << No.3

    FileDialog {
        id: saveSettingFileDialog
        fileMode: FileDialog.SaveFile
        selectedNameFilter.index: 1
        nameFilters: ["All Files (*.*)", "Data (*.dat)"]
        onAccepted: {
            var filePath = utilities.qUrlToLocalFileWithoutNative(file);
            console.log("Selected file (converted): " + filePath)
            console.log("Selected file: " + file);

            // call Restore Camera Setting
            var ret = deviceAdapter.setup_file_config_setting_save_setting(deviceUUID, filePath);
            if(ret == LT.DeviceAdapter.Ternary_True) {
                message_box.text = "<html><div style='margin-right: 30px;'>" + qsTranslate("lumixtether::CustomDialog", "Message_Complete") + "</div></html>"
                message_box.icon = LT.StandardIcon.Information
                message_box.standardButtons = LT.StandardButton.Ok
                message_box.visible = true
                // IVC >> Ver.1.9 >> start >> [THRBOXV100-87] - [THRBOXV100-88]
                // IVC >> Ver.1.9 >> start >> CustomDialog
//                deviceAdapter.trigger_window_dialog(LT.Utilities.Success_NotificationDialog, LT.Utilities.Information_Icon, true);
                // IVC << Ver.1.9 << end << CustomDialog
                // IVC << Ver.1.9 << end << [THRBOXV100-87] - [THRBOXV100-88]
            } else {
                message_box.text ="<html><div style='margin-right: 30px;'>" + qsTranslate("lumixtether::CustomDialog", "Message_Failed") + "</div></html>"
                message_box.icon = LT.StandardIcon.Critical
                message_box.standardButtons = LT.StandardButton.Ok
                message_box.visible = true
                // IVC >> Ver.1.9 >> start >> [THRBOXV100-87] - [THRBOXV100-88]
                // IVC >> Ver.1.9 >> start >> CustomDialog
//                deviceAdapter.trigger_window_dialog(LT.Utilities.Failed_NotificationDialog, LT.Utilities.Critical_Icon, true);
                // IVC << Ver.1.9 << end << CustomDialog
                // IVC << Ver.1.9 << end << [THRBOXV100-87] - [THRBOXV100-88]
            }
        }
        property var deviceUUID
    }

    FileDialog {
        id: restoreSettingFileDialog
        fileMode: FileDialog.OpenFile
        selectedNameFilter.index: 1
        nameFilters: ["All Files (*.*)", "Data (*.dat)"]
        onAccepted: {
            var filePath = utilities.qUrlToLocalFileWithoutNative(file);
            console.log("Selected file (converted): " + filePath)
            console.log("Selected file: " + file);

            // call Restore Camera Setting
            var ret = deviceAdapter.setup_file_config_setting_restore_setting(deviceUUID,filePath);
            if(ret == LT.DeviceAdapter.Ternary_True) {
                message_box.text = "<html><div style='margin-right: 30px;'>" + qsTranslate("lumixtether::CustomDialog", "Message_Complete") + "</div></html>"
                message_box.icon = LT.StandardIcon.Information
                message_box.standardButtons = LT.StandardButton.Ok
                message_box.visible = true
                // IVC >> Ver.1.9 >> start >> [THRBOXV100-87] - [THRBOXV100-88]
                // IVC >> Ver.1.9 >> start >> CustomDialog
//                deviceAdapter.trigger_window_dialog(LT.Utilities.Success_NotificationDialog, LT.Utilities.Information_Icon, true);
                // IVC << Ver.1.9 << end << CustomDialog
                // IVC << Ver.1.9 << end << [THRBOXV100-87] - [THRBOXV100-88]
            } else {
                message_box.text = "<html><div style='margin-right: 30px;'>" + qsTranslate("lumixtether::CustomDialog", "Message_Failed") + "</div></html>"
                message_box.icon = LT.StandardIcon.Critical
                message_box.standardButtons = LT.StandardButton.Ok
                message_box.visible = true
                // IVC >> Ver.1.9 >> start >> [THRBOXV100-87] - [THRBOXV100-88]
                // IVC >> Ver.1.9 >> start >> CustomDialog
//                deviceAdapter.trigger_window_dialog(LT.Utilities.Failed_NotificationDialog, LT.Utilities.Critical_Icon, true);
                // IVC << Ver.1.9 << end << CustomDialog
                // IVC << Ver.1.9 << end << [THRBOXV100-87] - [THRBOXV100-88]
            }
        }
        property var deviceUUID
    }

// IVC << Ver.1.9 << end << No.7

    LT.MessageBox{
        id: fwupConfirmDialog
        modality: Qt.ApplicationModal
        title: "LUMIX Tether"
        visible: false
        text: qsTranslate("lumixtether::CustomDialog", "firmware_update_confirmation")
        icon: LT.StandardIcon.Question
        standardButtons: LT.StandardButton.Yes | LT.StandardButton.No
        onYes: {
            startFirmwareUpdate()
        }
    }

    LT.MessageBox{
        id: message_box
        modality: Qt.ApplicationModal
        title: "LUMIX Tether"
        visible: false
    }

    function showRestoreCompatibleMessage(compatibleList){
        message_box.text = qsTranslate("lumixtether::CustomDialog", "Compatible_Info")
        for(var i=0; i<compatibleList.length; i++){
            message_box.text +=  "\r\n" + compatibleList[i]
        }

        message_box.icon = LT.StandardIcon.Information
        message_box.standardButtons = LT.StandardButton.Ok
        message_box.visible = true
    }

    function showPopup() {
        //  コンポーネントのプロパティを設定する
        //    * 使用可否と，状態に合わせた LTAbstractButton::checked を設定する
// IVC >> Ver.1.9 >> start >> No.7
        //var components = componentsProvider[target];
        var components;
        if(target === "saveCameraSetting" || target === "restoreCameraSetting" ||
            target === "storeLocationType" ||
            // IVC >> Ver.1.9 >> start >> No.3
            target === "firmwareUpdate"
            // IVC << Ver.1.9 << end << No.3
            // IVC >> Ver.1.9 >> start >> Enhance Security
            ||target === "changePassword"
            // IVC << Ver.1.9 << end << Enhance Security
            || target === "hlgShootingType"
        ) {
            // Clear dynamicComponentsProvider
            var n = dynamicComponentsProvider.length;
            for (var z = 0; z < n; z++) {
                dynamicComponentsProvider.pop();
            }

            //Add objects to dynamicComponentsProvider
            var optionText;
            var camIndex = 0;
            for(var i = 0; i < deviceAdapter.camera_list_number_of_camera(); i++) {
                var connectCamera = deviceAdapter["camConnectDeviceStatus"]
                if (connectCamera(i)) {
                    if(judge_AddCameraToDynamicComponentsProvider(i, target)) {
                        camIndex++;
                        var camIndividualId = deviceAdapter.camera_list_get_camera_individual_id(i);
                        if(camIndividualId === ""){
                            camIndividualId = deviceAdapter.camera_list_get_camera_modelName(i);
                        }
                        if(camIndex.length === 1) {
                            optionText = camIndex + ":   " + camIndividualId;
                        }
                        else {
                            optionText = camIndex + ": " + camIndividualId;
                        }

                        dynamicComponentsProvider.push( {
                                                           component: optionComponentsProvider.optionWithTextButtonComponent,
                                                           properties: {
                                                               type: "optionWithDynamicText",
                                                               value: deviceAdapter.camera_list_get_camera_uuid(i),
                                                               value2: deviceAdapter.camera_list_get_camera_serial_number(i),
                                                               optionText: optionText
                                                           }
                                                       } );
                    }
                }
            }
            var camNum = dynamicComponentsProvider.length

            if(target === "restoreCameraSetting") {
                dynamicComponentsProvider.push( {
                                                    component: optionComponentsProvider.optionWithTextButtonComponent,
                                                    properties: {
                                                       type: "optionWithDynamicText",
                                                       value: "ALL",
                                                       optionText: "      All Cameras"
                                                   }
                                               } );
                /*コマンド送信対象のみ対象にする
                if( deviceAdapter.isSupportMultiView() === true){
                    dynamicComponentsProvider.push( {
                                                        component: optionComponentsProvider.optionWithTextButtonComponent,
                                                        properties: {
                                                           type: "optionWithDynamicText",
                                                           value: "SELECTED",
                                                           optionText: "      Selected Cameras"
                                                       }
                                                   } );
                }
                */
            }
            else if(target === "storeLocationType" || target === "hlgShootingType") {
                dynamicComponentsProvider.push( {
                                                    component: optionComponentsProvider.optionWithTextButtonComponent,
                                                    properties: {
                                                       type: "optionWithDynamicText",
                                                       value: LT.DeviceAdapter.CameraID_ALL,
                                                       optionText: "      All Cameras"
                                                   }
                                               } );
                /*コマンド送信対象のみ対象にする
                if( deviceAdapter.isSupportMultiView() === true){
                    dynamicComponentsProvider.push( {
                                                        component: optionComponentsProvider.optionWithTextButtonComponent,
                                                        properties: {
                                                           type: "optionWithDynamicText",
                                                           value: LT.DeviceAdapter.CameraID_SELECTED,
                                                           optionText: "      Selected Cameras"
                                                       }
                                                   } );
                }
                */
            }
            components = dynamicComponentsProvider;
        }
        else {
            components = componentsProvider[target];
        }
// IVC << Ver.1.9 << end << No.7
// IVC >> Ver.1.9 >> start >> No.1.1
        // Init target camera list in application settings in order to handle multi-camera store location
        if(target === "storeLocationType") {
            var storeLocationType;
            applicationSettings.setTargetCameraListLength(camNum);

            if(isFirstTimePopup) {
                for(var i = 0; i < camNum; i ++) {
                    storeLocationType = applicationSettings.getStoreLocationTypeFromFile(dynamicComponentsProvider[i].properties.value2);
                    applicationSettings.setTargetCameraListByID(dynamicComponentsProvider[i].properties.value2, storeLocationType , i);
                }
                isFirstTimePopup = false;
            }
        }
// IVC << Ver.1.9 << end << No.1.1
// ivc >> start >> No.4
        if(target =="hlgShootingType")
        {
            var curr_uuid = deviceAdapter.camera_list_get_selected_camera_uuid()
            for (var i = 0; i < components.length; ++i) {
                components[i].properties.capable = true;
                components[i].properties.checked = components[i].properties.value === curr_uuid;
            }
        }
        else
        {
            for (var i = 0; i < components.length; ++i) {
                components[i].properties.capable = true;
                // IVC >> Ver.1.9 >> start >> [THRBOXV100-96]
                if (target === "restoreCameraSetting") {
                    if(deviceAdapter.btnAllCameraStatus == LT.Utilities.BtnAllCameraStatus_Checked) {
                        components[i].properties.checked = components[i].properties.value ==  "ALL";
                    }
                    else {
                        components[i].properties.checked = components[i].properties.value ==  value;
                    }
                } else {
                    components[i].properties.checked = components[i].properties.value ==  value;
                }
                // IVC << Ver.1.9 << end << [THRBOXV100-96]
            }
        }
// ivc << end << No.4

        //  ポップアップの表示位置を決定する
        var point = rootParent.mapFromItem(root, root.x, root.y);
        var preferX = point.x + root.width;
        var preferY = point.y + root.height;
        //console.log("SHOW_POPUP: point: X: " + point.x + " Y: "+ point.y)
        //console.log("SHOW_POPUP: size: width: " + root.width + " height: "+ root.height)
// IVC >> Ver.1.9 >> start >> No.7
        var comps
        if(target === "saveCameraSetting" || target === "restoreCameraSetting" ||
            target === "storeLocationType" ||
            // IVC >> Ver.1.9 >> start >> No.3
            target === "firmwareUpdate"
            // IVC << Ver.1.9 << end << No.3
            // IVC >> Ver.1.9 >> start >> Enhance Security
            || target === "changePassword"
            // IVC << Ver.1.9 << end << Enhance Security
            || target === "hlgShootingType"
        ) {
            comps = dynamicComponentsProvider;
        }
        else {
            comps = componentsProvider[target];
        }
        //  ポップアップを表示する
        if ((dynamicComponentsProvider.length === 0 && (target === "firmwareUpdate" || target === "saveCameraSetting" || target === "changePassword"))
                || (dynamicComponentsProvider.length === 1 && (target === "restoreCameraSetting" || target === "hlgShootingType"))) {
            //warningCameraDialog.open();
        }
        else if (dynamicComponentsProvider.length === 1 && target === "firmwareUpdate") {
            var uuid = deviceAdapter.camera_list_get_selected_camera_uuid()
            firmwareUpdateFileDialog.deviceUUID = uuid
            firmwareUpdateFileDialog.open();
        }
        else if ((dynamicComponentsProvider.length === 1 && target === "saveCameraSetting")) {
            var uuid = deviceAdapter.camera_list_get_selected_camera_uuid()
            if(utilities.isMac()) {
                saveSettingFileDialog.deviceUUID = uuid
                saveSettingFileDialog.open()
            } else {
                var ret = utilities.selectCameraSetting(uuid, LT.Utilities.CameraSettingFile_Save)
                if(ret === LT.Utilities.CST_Success) {
                    message_box.text = "<html><div style='margin-right: 30px;'>" + qsTranslate("lumixtether::CustomDialog", "Message_Complete") + "</div></html>"
                    message_box.icon = LT.StandardIcon.Information
                    message_box.standardButtons = LT.StandardButton.Ok
                    message_box.visible = true
                    // IVC >> Ver.1.9 >> start >> [THRBOXV100-87] - [THRBOXV100-88]
                    // IVC >> Ver.1.9 >> start >> CustomDialog
//                    deviceAdapter.trigger_window_dialog(LT.Utilities.Success_NotificationDialog, LT.Utilities.Information_Icon, true);
                    // IVC << Ver.1.9 << end << CustomDialog
                    // IVC << Ver.1.9 << end << [THRBOXV100-87] - [THRBOXV100-88]
                }
                else if(ret == LT.Utilities.CST_Unknown){
                    message_box.text = "<html><div style='margin-right: 30px;'>" + qsTranslate("lumixtether::CustomDialog", "Message_Failed") + "</div></html>"
                    message_box.icon = LT.StandardIcon.Critical
                    message_box.standardButtons = LT.StandardButton.Ok
                    message_box.visible = true
                    // IVC >> Ver.1.9 >> start >> [THRBOXV100-87] - [THRBOXV100-88]
                    // IVC >> Ver.1.9 >> start >> CustomDialog
//                    deviceAdapter.trigger_window_dialog(LT.Utilities.Failed_NotificationDialog, LT.Utilities.Critical_Icon, true);
                    // IVC << Ver.1.9 << end << CustomDialog
                    // IVC << Ver.1.9 << end << [THRBOXV100-87] - [THRBOXV100-88]
                }
            }
        }
        else if(dynamicComponentsProvider.length === 2 && target === "restoreCameraSetting") {
            var uuid = deviceAdapter.camera_list_get_selected_camera_uuid()
            /* 警告メッセージの表示はいったん中止
            var compatible = deviceAdapter.checkRestoreCompatible(uuid)
            if( compatible.length > 0){
                showRestoreCompatibleMessage(compatible)
            }*/
            if(utilities.isMac()) {
                restoreSettingFileDialog.deviceUUID = uuid
                restoreSettingFileDialog.open()
            } else {
                var ret = utilities.selectCameraSetting(uuid, LT.Utilities.CameraSettingFile_Restore)
                if(ret === LT.Utilities.CST_Success) {
                    message_box.text = "<html><div style='margin-right: 30px;'>" + qsTranslate("lumixtether::CustomDialog", "Message_Complete") + "</div></html>"
                    message_box.icon = LT.StandardIcon.Information
                    message_box.standardButtons = LT.StandardButton.Ok
                    message_box.visible = true
                    // IVC >> Ver.1.9 >> start >> [THRBOXV100-87] - [THRBOXV100-88]
                    // IVC >> Ver.1.9 >> start >> CustomDialog
//                    deviceAdapter.trigger_window_dialog(LT.Utilities.Success_NotificationDialog, LT.Utilities.Information_Icon, true);
                    // IVC << Ver.1.9 << end << CustomDialog
                    // IVC << Ver.1.9 << end << [THRBOXV100-87] - [THRBOXV100-88]
                }
                else if(ret == LT.Utilities.CST_Unknown){
                    message_box.text = "<html><div style='margin-right: 30px;'>" + qsTranslate("lumixtether::CustomDialog", "Message_Failed") + "</div></html>"
                    message_box.icon = LT.StandardIcon.Critical
                    message_box.standardButtons = LT.StandardButton.Ok
                    message_box.visible = true
                    // IVC >> Ver.1.9 >> start >> [THRBOXV100-87] - [THRBOXV100-88]
                    // IVC >> Ver.1.9 >> start >> CustomDialog
//                    deviceAdapter.trigger_window_dialog(LT.Utilities.Failed_NotificationDialog, LT.Utilities.Critical_Icon, true);
                    // IVC << Ver.1.9 << end << CustomDialog
                    // IVC << Ver.1.9 << end << [THRBOXV100-87] - [THRBOXV100-88]
                }
            }
        }
// IVC >> Ver.1.9 >> start >> Enhance Security
        else if (dynamicComponentsProvider.length === 1 && target === "changePassword"){
            // IVC >> Ver.1.9 >> start >> [THRBOXV100-156]
            //deviceAdapter.ptpip_enhance_security_show_change_password_dialog(0, deviceAdapter.camCurrentSelectedSerialNo)
            var dev_index = 0
            var numberOfCameras = deviceAdapter.camera_list_number_of_camera();
            for ( var i = 0; i < numberOfCameras; i++) {
                var connectCamera = deviceAdapter["camConnectDeviceStatus"]
                if (connectCamera(i)) {
                    var dev_uuid = deviceAdapter.camera_list_get_camera_uuid(i)
                    if (deviceAdapter.camera_list_get_selected_camera_uuid() === dev_uuid) {
                        dev_index = deviceAdapter.camera_list_get_camera_dev_index(i)
                        break;
                    }
                }
            }
            deviceAdapter.ptpip_enhance_security_show_change_password_dialog(dev_index, deviceAdapter.camCurrentSelectedSerialNo)
            // IVC << Ver.1.9 << end << [THRBOXV100-156]
        }
// IVC << Ver.1.9 << end << Enhance Security
        else if(dynamicComponentsProvider.length === 2 && target === "storeLocationType") {
            comps = componentsProvider[target];
            btnOptionStoLoc.currentCamera = dynamicComponentsProvider[0].properties.value
            btnOptionStoLoc.currentSerialNo = dynamicComponentsProvider[0].properties.value2
            root.showSecondPopup(comps, target, dynamicComponentsProvider[0].properties.value2, 0);
        }
        else if(dynamicComponentsProvider.length === 2 && target === "hlgShootingType"){
            comps = componentsProvider[target];
            root.showSecondPopup(comps, target, dynamicComponentsProvider[0].properties.value2, 0);
        }

        //popup.present(preferX, preferY, null, componentsProvider[target], target, function (object) {
        else
            popup.present(preferX, preferY, null, comps, target, function (object) {
// IVC << Ver.1.9 << end << No.7
            //log record
            if (logCol){
                logCol.log(logLevel, logScrTagID, logFile + " selected", object.value);
            }
// IVC >> Ver.1.9 >> start >> No.3
            if(target === "firmwareUpdate") {
                firmwareUpdateFileDialog.deviceUUID = object.value
                firmwareUpdateFileDialog.open();
            }
// IVC << Ver.1.9 << end << No.3
// IVC >> Ver.1.9 >> start >> No.7
            else if(target === "saveCameraSetting") {
                if(utilities.isMac()) {
                    saveSettingFileDialog.deviceUUID = object.value
                    saveSettingFileDialog.open()
                } else {
                    var ret = utilities.selectCameraSetting(object.value, LT.Utilities.CameraSettingFile_Save)
                    if(ret === LT.Utilities.CST_Success) {
                        message_box.text = "<html><div style='margin-right: 30px;'>" + qsTranslate("lumixtether::CustomDialog", "Message_Complete") + "</div></html>"
                        message_box.icon = LT.StandardIcon.Information
                        message_box.standardButtons = LT.StandardButton.Ok
                        message_box.visible = true
                        // IVC >> Ver.1.9 >> start >> [THRBOXV100-87] - [THRBOXV100-88]
                        // IVC >> Ver.1.9 >> start >> CustomDialog
//                        deviceAdapter.trigger_window_dialog(LT.Utilities.Success_NotificationDialog, LT.Utilities.Information_Icon, true);
                        // IVC << Ver.1.9 << end << CustomDialog
                        // IVC << Ver.1.9 << end << [THRBOXV100-87] - [THRBOXV100-88]
                    }
                    else if(ret == LT.Utilities.CST_Unknown){
                        message_box.text = "<html><div style='margin-right: 30px;'>" + qsTranslate("lumixtether::CustomDialog", "Message_Failed") + "</div></html>"
                        message_box.icon = LT.StandardIcon.Critical
                        message_box.standardButtons = LT.StandardButton.Ok
                        message_box.visible = true
                        // IVC >> Ver.1.9 >> start >> [THRBOXV100-87] - [THRBOXV100-88]
                        // IVC >> Ver.1.9 >> start >> CustomDialog
//                        deviceAdapter.trigger_window_dialog(LT.Utilities.Failed_NotificationDialog, LT.Utilities.Critical_Icon, true);
                        // IVC << Ver.1.9 << end << CustomDialog
                        // IVC << Ver.1.9 << end << [THRBOXV100-87] - [THRBOXV100-88]
                    }
                }
            }
            else if(target === "restoreCameraSetting") {
                /* 警告メッセージの表示はいったん中止
                var compatible = deviceAdapter.checkRestoreCompatible(object.value)
                if( compatible.length > 0){
                    showRestoreCompatibleMessage(compatible)
                }
                */
                if(utilities.isMac()) {
                    restoreSettingFileDialog.deviceUUID = object.value
                    restoreSettingFileDialog.open()
                } else {
                    var ret = utilities.selectCameraSetting(object.value, LT.Utilities.CameraSettingFile_Restore)
                    if(ret === LT.Utilities.CST_Success) {
                        message_box.text = "<html><div style='margin-right: 30px;'>" + qsTranslate("lumixtether::CustomDialog", "Message_Complete") + "</div></html>"
                        message_box.icon = LT.StandardIcon.Information
                        message_box.standardButtons = LT.StandardButton.Ok
                        message_box.visible = true
                        // IVC >> Ver.1.9 >> start >> [THRBOXV100-87] - [THRBOXV100-88]
                        // IVC >> Ver.1.9 >> start >> CustomDialog
//                        deviceAdapter.trigger_window_dialog(LT.Utilities.Success_NotificationDialog, LT.Utilities.Information_Icon, true);
                        // IVC << Ver.1.9 << end << CustomDialog
                        // IVC << Ver.1.9 << end << [THRBOXV100-87] - [THRBOXV100-88]
                    }
                    else if(ret == LT.Utilities.CST_Unknown){
                        message_box.text = "<html><div style='margin-right: 30px;'>" + qsTranslate("lumixtether::CustomDialog", "Message_Failed") + "</div></html>"
                        message_box.icon = LT.StandardIcon.Critical
                        message_box.standardButtons = LT.StandardButton.Ok
                        message_box.visible = true
                        // IVC >> Ver.1.9 >> start >> [THRBOXV100-87] - [THRBOXV100-88]
                        // IVC >> Ver.1.9 >> start >> CustomDialog
//                        deviceAdapter.trigger_window_dialog(LT.Utilities.Failed_NotificationDialog, LT.Utilities.Critical_Icon, true);
                        // IVC << Ver.1.9 << end << CustomDialog
                        // IVC << Ver.1.9 << end << [THRBOXV100-87] - [THRBOXV100-88]
                    }
                }
            }
// IVC << Ver.1.9 << end << No.7
// IVC >> Ver.1.9 >> start >> Enhance Security
           else if (target === "changePassword") {
                var dev_index = 0
                var numberOfCameras = deviceAdapter.camera_list_number_of_camera();
                for ( var i = 0; i < numberOfCameras; i++) {
                    var connectCamera = deviceAdapter["camConnectDeviceStatus"]
                    if (connectCamera(i)) {
                        var dev_uuid = deviceAdapter.camera_list_get_camera_uuid(i)
                        if ((object.value === dev_uuid)) {
                            dev_index = deviceAdapter.camera_list_get_camera_dev_index(i)
                            break;
                        }
                    }
                }
                deviceAdapter.ptpip_enhance_security_show_change_password_dialog(dev_index, object.value2)
            }
// IVC << Ver.1.9 << end << Enhance Security
// IVC >> Ver.1.9 >> start >> No.1
            else if(target === "storeLocationType") {
                currentCamera = object.value;
                currentSerialNo = object.value;
                //get selected camera index
                var currentIndex = -1;
                if(object.value !== LT.DeviceAdapter.CameraID_ALL &&
                   object.value !== LT.DeviceAdapter.CameraID_SELECTED) {
                    for(var i = 0; i < dynamicComponentsProvider.length; i++) {
                        if(currentCamera === dynamicComponentsProvider[i].properties.value) {
                            currentSerialNo = dynamicComponentsProvider[i].properties.value2
                            currentIndex = i;
                            break;
                        }
                    }
                }
                popup.dismiss();
                var storeLocationTypeComponents = componentsProvider[target];
                root.showSecondPopup(storeLocationTypeComponents, target, currentSerialNo, currentIndex);
            }
// IVC << Ver.1.9 << end << No.1
            else if(target === "hlgShootingType"){
                currentCamera = deviceAdapter.camera_list_get_selected_camera_uuid();
                currentSerialNo = object.value
                if(object.value !== LT.DeviceAdapter.CameraID_ALL &&
                   object.value !== LT.DeviceAdapter.CameraID_SELECTED){
                    currentCamera = object.value;
                    currentSerialNo = object.value2;
                }
                var currentIndex = -1;
                for(var i = 0; i < dynamicComponentsProvider.length; i++) {
                    if(currentCamera === dynamicComponentsProvider[i].properties.value) {
                        currentIndex = i;
                        break;
                    }
                }
                popup.dismiss();
                var hlgTypeComponents = componentsProvider[target];
                root.showSecondPopup(hlgTypeComponents, target, currentSerialNo, currentIndex);
            }
            else {
                //  状態と表示内容を設定する
                root.value = object.value;
                switch (object.type) {
                case "optionWithText":
                    root.optionText = object.optionText;
                    break;
                default:
                    break;
                }
            }
            //  ポップアップを非表示にする
// IVC >> Ver.1.9 >> start >> No.1
            if(target !== "storeLocationType" &&
               target !== "hlgShootingType") {
                popup.dismiss();
            }
// IVC << Ver.1.9 << end << No.1

        });
    }

    function judge_AddCameraToDynamicComponentsProvider(index, target){
        if(target === "storeLocationType"){
            if(deviceAdapter.camera_list_get_camera_power_mode(index) === true){
                return true;
            }else{
                return false;
            }
        }else if(target === "hlgShootingType"){
            if(deviceAdapter.camera_list_get_camera_supportHLG(index) === true &&
               deviceAdapter.camera_list_get_camera_enableHLG(index) === true &&
               deviceAdapter.camera_list_get_camera_power_mode(index) === true){
                return true;
            }else{
                return false;
            }
        }else if(target === "saveCameraSetting" || target === "restoreCameraSetting"){
            if(deviceAdapter.camera_list_get_camera_setupFilesCfgSet(index) === true &&
               deviceAdapter.camera_list_get_camera_power_mode(index) === true){
                return true;
            }else{
                return false;
            }
        }else if(target === "firmwareUpdate"){
            if(deviceAdapter.camera_list_get_camera_support_FWUP(index) === true &&
               deviceAdapter.camera_list_get_camera_power_mode(index) === true){
                return true;
            }else{
                return false;
            }
        }else if(target === "changePassword"){
            if(deviceAdapter.connectionType === LT.Utilities.PtpipConnType_Lan &&
               deviceAdapter.camera_list_get_camera_power_mode(index) === true){
                return true;
            }else{
                return false;
            }
        }else{
           if(deviceAdapter.camera_list_check_camera_support_power_saving(index) === true &&
              deviceAdapter.camera_list_get_camera_power_mode(index) === true) {
               return true;
           }else{
               return false;
           }
        }
    }

    function optionSelect(selected) {
        //log record
        if (logCol){
            logCol.log(logLevel, logScrTagID, logFile + " optionSelect", selected);
        }

        root.value = selected;
        //  コンポーネントのプロパティを設定する
        //    * 使用可否と，状態に合わせた LTAbstractButton::checked を設定する
// IVC >> Ver.1.9 >> start >> No.7
        //var components = componentsProvider[target];
        var components
        if(target === "saveCameraSetting" || target === "restoreCameraSetting" ||
            target === "storeLocationType" ||
            // IVC >> Ver.1.9 >> start >> No.3
            target === "firmwareUpdate"
            // IVC << Ver.1.9 << end << No.3
            // IVC >> Ver.1.9 >> start >> Enhance Security
            || target === "changePassword"
            // IVC << Ver.1.9 << end << Enhance Security
        ){
            components = dynamicComponentsProvider;
        }
        else {
            components = componentsProvider[target];
        }
// IVC << Ver.1.9 << end << No.7
        for (var i = 0; i < components.length; ++i) {
            components[i].properties.checked = components[i].properties.value == value;
            if(components[i].properties.checked) {
                switch (components[i].properties.type) {
                case "optionWithText":
                    root.optionText = components[i].properties.optionText;
                    break;
                default:
                    break;
                }
            }
        }
    }

// IVC >> Ver.1.9 >> start >> No.5
    function showSecondPopup(secondComponents, secondTarget, camerSerialNo, index) {
        if(target === "hlgShootingType"){
            var capability = deviceAdapter[target + "Capability"];
            var select_uuid = dynamicComponentsProvider[index].properties.value
            var hlgType = deviceAdapter.getPscHlgShootingTypeByUUID(select_uuid)
            for (var i = 0; i < secondComponents.length; ++i) {
                //Check value to display
                if (capability(secondComponents[i].properties.value, select_uuid) === LT.DeviceAdapter.Ternary_True) {
                    secondComponents[i].properties.capable = true;
                    secondComponents[i].properties.checked = secondComponents[i].properties.value === hlgType;
                } else {
                    secondComponents[i].properties.capable = false;
                    secondComponents[i].properties.enabled = false;
                    secondComponents[i].properties.checked = false;
                }
            }
        }else{
            for (var i = 0; i < secondComponents.length; ++i) {
                secondComponents[i].properties.capable = true;
                secondComponents[i].properties.checked = secondComponents[i].properties.value === value;
            }
        }
        //  ポップアップの表示位置を決定する
        var point = rootParent.mapFromItem(root, root.x, root.y);
        var preferX = point.x + root.width;
        var preferY = point.y + root.height;
// IVC >> Ver.1.9 >> start >> [THRBOXV100-208]
        allCameraStoLoc = applicationSettings.getStoreLocationTypeFromList(deviceAdapter.camCurrentSelectedSerialNo)
// IVC << Ver.1.9 << end << [THRBOXV100-208]

        popup.present(preferX, preferY, null, secondComponents, secondTarget, function (object) {
            //log record
            if (logCol){
                logCol.log(logLevel, logScrTagID, logFile + " selected", object.value);
            }

            //  状態と表示内容を設定する
            root.value = object.value;
            if(secondTarget === "storeLocationType") {
                if(camerSerialNo === LT.DeviceAdapter.CameraID_ALL) {
                    for(var i = 0; i < dynamicComponentsProvider.length; i++) {
                        if( dynamicComponentsProvider[i].properties.value !== LT.DeviceAdapter.CameraID_ALL &&
                            dynamicComponentsProvider[i].properties.value !== LT.DeviceAdapter.CameraID_SELECTED ){
                            applicationSettings.setTargetCameraListByID(dynamicComponentsProvider[i].properties.value2, object.value, i);
                        }
                    }
// IVC >> Ver.1.9 >> start >> [THRBOXV100-208]
                    //allCameraStoLoc = object.value
// IVC << Ver.1.9 << end << [THRBOXV100-208]
                }else if(camerSerialNo === LT.DeviceAdapter.CameraID_SELECTED){
                    for(var i = 0; i < dynamicComponentsProvider.length; i++) {
                        if( dynamicComponentsProvider[i].properties.value !== LT.DeviceAdapter.CameraID_ALL &&
                            dynamicComponentsProvider[i].properties.value !== LT.DeviceAdapter.CameraID_SELECTED ){
                            if( deviceAdapter.camera_list_get_camera_sendCmdEnableByUUID(dynamicComponentsProvider[i].properties.value)){
                                applicationSettings.setTargetCameraListByID(dynamicComponentsProvider[i].properties.value2, object.value, i);
                            }
                        }
                    }
                }else {
                    applicationSettings.setTargetCameraListByID(camerSerialNo, object.value, index);
                }
            }else if(target === "hlgShootingType"){
                if(camerSerialNo === LT.DeviceAdapter.CameraID_ALL){
                    var capability = deviceAdapter[target + "Capability"];
                    for(var i = 0; i < dynamicComponentsProvider.length - 1; i++) {
                        var select_uuid = dynamicComponentsProvider[i].properties.value
                        if (capability(object.value, select_uuid) === LT.DeviceAdapter.Ternary_True) {
                            deviceAdapter.setPscHlgShootingTypeByUUID(select_uuid, object.value)
                        }
                    }
                }else if(camerSerialNo === LT.DeviceAdapter.CameraID_SELECTED){
                    var capability = deviceAdapter[target + "Capability"];
                    for(var i = 0; i < dynamicComponentsProvider.length - 1; i++) {
                        var select_uuid = dynamicComponentsProvider[i].properties.value
                        if (capability(object.value, select_uuid) === LT.DeviceAdapter.Ternary_True) {
                            if( deviceAdapter.camera_list_get_camera_sendCmdEnableByUUID(dynamicComponentsProvider[i].properties.value)){
                                deviceAdapter.setPscHlgShootingTypeByUUID(select_uuid, object.value)
                            }
                        }
                    }
                }else{
                    deviceAdapter.setPscHlgShootingTypeByUUID(dynamicComponentsProvider[index].properties.value, object.value)
                }
            }

            // IVC >> Ver.1.9 >> start >> [THRBOXV100-50]
            // Update option text for the selected camera
            if ( (camerSerialNo === deviceAdapter.camCurrentSelectedSerialNo)
// IVC >> Ver.1.9 >> start >> [THRBOXV100-208]
                 || (camerSerialNo === LT.DeviceAdapter.CameraID_ALL)
                 || (camerSerialNo === LT.DeviceAdapter.CameraID_SELECTED))
// IVC << Ver.1.9 << end << [THRBOXV100-208]
            {
                switch (object.type) {
                case "optionWithText":
                    root.optionText = object.optionText;
                    break;
                default:
                    break;
                }
            }
            // IVC << Ver.1.9 << end << [THRBOXV100-50]

            popup.dismiss();
        });
    }
// IVC << Ver.1.9 << end << No.5

    onClicked: {
        if (isShowPopup) {
            root.showPopup();
        }
    }

    value: deviceAdapter[target]

    type: "optionWithImage"
//    fillColor: palette.backgroundDark

}
