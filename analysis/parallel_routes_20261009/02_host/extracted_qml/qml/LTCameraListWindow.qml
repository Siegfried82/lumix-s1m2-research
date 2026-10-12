import QtQuick 2.6
import QtQml 2.2
import QtQuick.Window 2.3
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.1
//import Qt5Compat.GraphicalEffects

import "qrc:/qml"
import LT 1.0 as LT
import "LTSubFunction.js" as LTSubFunction

Window {
    id: root

    //  ウィンドウのサイズを最小/最大サイズにする
    minimumWidth: 285
    minimumHeight: 232

// IVC >> Ver.1.9 >> start >> [THRBOXV100-30] No.7
    // Define width & height for calculating default winStateX and winStateY
    width: minimumWidth
    height: minimumHeight
// IVC << Ver.1.9 << end << [THRBOXV100-30] No.7
    //maximumWidth: minimumWidth
    // IVC >> Ver.1.9 >> start >> [THRBOXV100-46]
//    maximumHeight: (componentNum + 2 ) * componentHeight + componentSpacing * (componentNum + 2)

//    property int rowHeight: 32
    property int rowHeight: 33
    // IVC << Ver.1.9 << end << [THRBOXV100-46]

    property real componentMax: 12

    property real componentNum: 0

    property int componentSpacing: 1

    readonly property real componentHeight: 32

    property real contentHeight: componentHeight*componentNum + componentSpacing * (componentNum - 1)
//    property bool windowFirstInit: false
// IVC << Ver.1.9 << end << [THRBOXV100-58]
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
        "titleText": "#808080",
        "valueText": "#ffffff",
        "line": "#000000"
    }

    property int powerChangeCamIndex: 0
    property var powerChangeCamSerialNo
    property var cameraList: []
    property var objects: []
    property int dumbModel: 0

    title: "CAMERA"

    // IVC >> Ver.1.9 >> start >> [THRBOXV100-46]
    //    color: palette.backgroundLight
    color: palette.backgroundDark
    // IVC << Ver.1.9 << end << [THRBOXV100-46]
    LTWindowStateSaver {
        id: windowState
        window: root
        defaultWidth: minimumWidth
        defaultHeight: minimumHeight
        targetWindow: LT.ApplicationSettings.WinList_CamList
    }
    property bool lastMaximised: windowState.curMaximised

    Flickable {
        id: flickable
        width: parent.width
        // IVC >> Ver.1.9 >> start >> [THRBOXV100-47]
//        height: parent.height - btnAllCameras.height - panelUpdateClose.height
//        contentHeight: (componentNum + 1) * ( rowHeight + componentSpacing ) - componentSpacing
        height: parent.height - panelUpdateClose.height
        contentHeight: (componentNum + 2) * ( rowHeight + componentSpacing ) - componentSpacing
        // IVC << Ver.1.9 << end << [THRBOXV100-47]
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        ColumnLayout {
            id: popupContent
            spacing: componentSpacing
            Repeater {
                id: popupContentRepeat
                model: objects
                delegate:
                LTCameraListButton {
                    id: cameraButton
                    anchors {
                        left: root.left
                        right: root.right
                    }

                    implicitWidth: flickable.width
                    implicitHeight: btnAllCameras.height
                    cameraIDText: modelData.cameraIdOrder
                    cameraName: modelData.cameraId
                    checkedCameraVisible: modelData.checkedState ? 1 : 0
                    icoCameraSrc: (modelData.powerOnMode === true && modelData.cameraBtnEnable === true) ? "qrc:/images/camera_on.svg" : "qrc:/images/camera_off.svg"
                    // IVC >> Ver.1.9 >> start >> [THRBOXV100-65] - [THRBOXV100-66]
                    textColor: (modelData.powerOnMode === true )? "#dddddd" : "#646464"
                    // IVC << Ver.1.9 << end << [THRBOXV100-65] - [THRBOXV100-66]
                    icoArrowUpOpacity: (index === 0) ? 0.5 : 1
                    icoArrowUpEnable: (index === 0) ? false : true
                    icoArrowDownOpacity: (index === componentNum - 1) ? 0.5 : 1
                    icoArrowDownEnable: (index === componentNum - 1) ? false : true
                    cameraBtnIconEnable: modelData.cameraBtnEnable
                    camTetherModeStatus: modelData.camTetherModeStatus

                    onClickedUpDown:(status)=> {
                        root.onClickedUpDownButton(status, index);
                    }
                    onClickedCheck: {
                        deviceAdapter.camName = objects[index].cameraIdOrder + ": " + objects[index].cameraIdFullName
                        if(componentNum > 1 && objects[index].checkedState !== true) {
                            root.onClickedCheckCamera(index);
                        }
                    }
                    onClickedPowerMode: {
                        // IVC >> Ver.1.9 >> start >> [THRBOXV100-48]
//                        var ACMode = false;
                        var dev_index = deviceAdapter.camera_list_get_camera_dev_index(objects[index].index);
                        var ACMode = deviceAdapter.isBatteryLevelAC(dev_index);
                        // IVC << Ver.1.9 << end << [THRBOXV100-48]
                        powerChangeCamSerialNo = objects[index].cameraSerialNo;
                        // IVC >> Ver.1.9 >> start >> [THRBOXV100-160]
                        powerChangeCamIndex = index;
                        // IVC<< Ver.1.9 << end << [THRBOXV100-160]
                        if(ACMode === true || modelData.powerOnMode === false) {
                            // IVC >> Ver.1.9 >> start >> [THRBOXV100-160]
//                            root.triggerPowerMode(index);
                            root.triggerPowerMode();
                            // IVC<< Ver.1.9 << end << [THRBOXV100-160]
                        }
                        else {
                            powerConfirmDialog.visible = true
                            // IVC >> Ver.1.9 >> start >> [THRBOXV100-160]
//                            powerChangeCamIndex = index;
                            // IVC<< Ver.1.9 << end << [THRBOXV100-160]
                            // IVC >> Ver.1.9 >> start >> CustomDialog
//                            deviceAdapter.trigger_window_dialog(LT.Utilities.PowerSaving_ConfirmationDialog, LT.Utilities.Warning_Icon, true);
                            // IVC<< Ver.1.9 << end << CustomDialog
                        }
                    }
                }
            }
            // IVC >> Ver.1.9 >> start >> [THRBOXV100-47]
            /*
                All Cameras ボタン
             */
            Item {
                id: allCamerasItem
                Layout.fillWidth: true
                height: rowHeight
                // IVC >> Ver.1.9 >> start >> [THRBOXV100-46]
                Column {
                    anchors.fill: parent
                    z: 20
                // IVC<< Ver.1.9 << end << [THRBOXV100-46]
                    LTCameraListButton {
                        id: btnAllCameras
                        width: parent.width
                        height: parent.height
                        cameraName: "All Cameras"
                        allCameraUncheckImgSource: "qrc:/images/camera_unchecked.svg"
                        cameraIDTextOpacity: 0
                        cameraBtnIconOpacity: 0
                        arrowIconVisible: false
                        btnEnabled: componentNum > 1 ? true : false
                        textColor: btnEnabled ? "#dddddd" : "#646464"
                        onClicked: {
                            if(checked) {
                                btnAllCameras.checked = false;
                                deviceAdapter.setLiveviewMode_Async(false)
                                deviceAdapter.btnAllCameraStatus = LT.Utilities.BtnAllCameraStatus_Unchecked;
                                btnAllCameras.allCameraUncheckImgSource = "qrc:/images/camera_unchecked.svg";
                                updateCurrentSelectedCamera();
                            }
                            else {
                                btnAllCameras.checked = true;
                                deviceAdapter.setLiveviewMode_Async(true)
                                deviceAdapter.btnAllCameraStatus = LT.Utilities.BtnAllCameraStatus_Checked;
                                btnAllCameras.allCameraUncheckImgSource = "qrc:/images/camera_checked.svg";
                            }
                        }
                        onBtnEnabledChanged: {
                            // Uncheck all cameras button when the button is disabled
                            if(deviceAdapter.isMultiviewMode === false){
                                if(!btnEnabled) {
                                    btnAllCameras.checked = false;
                                    btnAllCameras.allCameraUncheckImgSource = "qrc:/images/camera_unchecked.svg";
                                    deviceAdapter.btnAllCameraStatus = LT.Utilities.BtnAllCameraStatus_Unchecked;
                                }
                            }
                        }
                    }
                    // IVC >> Ver.1.9 >> start >> [THRBOXV100-46]
                    Rectangle {
                        height: 1
                        width: btnAllCameras.width
                        color: palette.backgroundLight
                        visible: dumbModel > 0 ? false : true;
                    }
                }
                // IVC << Ver.1.9 << end << [THRBOXV100-46]
            }
            // IVC << Ver.1.9 << end << [THRBOXV100-47]
            /*
              Dumb objects is used in case the camera panel's items < 6
              */
            Repeater {
                id: dumbObject
                model: dumbModel
                delegate:
                LTCameraListButton {
                    anchors {
                        left: root.left
                        right: root.right
                    }

                    implicitWidth: flickable.width
                    implicitHeight: btnAllCameras.height
                    cameraName: ""
                    checkedCameraVisible: 0
                    cameraIDTextOpacity: 0
                    cameraBtnIconOpacity: 0
                    arrowIconVisible: false
                    btnEnabled: false
                }
            }
        }

        ScrollBar.vertical: LTScrollBar {
            visible: (flickable.height < flickable.contentHeight)
        }
    }

    Column {
        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }

        /*
            更新ボタン　＆　閉じるボタン
         */
        Item {
            id: panelUpdateClose
            anchors {
                left: parent.left
                right: parent.right
            }

            height: rowHeight+2

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
                    id: btnUpdateCamList
                    width: (parent.width - parent.spacing)/2
                    height: rowHeight - parent.spacing/2

                    type:"action"
                    buttonText: qsTr("Update")

                    fillColor: palette.backgroundLight

                    onClicked: {
                        // IVC >> Ver.1.9 >> start >> Enhance Security
                        deviceAdapter.camera_list_update_camera_list(true)
                        // IVC << Ver.1.9 << end << Enhance Security
                        // IVC >> Ver.1.9 >> start >> [THRBOXV100-57]
                        showPopup();
                        // IVC << Ver.1.9 << end << [THRBOXV100-57]
                        // IVC >> Ver.1.9 >> start >> [THRBOXV100-38]
//                        hide();
                        // IVC << Ver.1.9 << end << [THRBOXV100-38]
                    }
                }

                LTRectangleButton {
                    width: (parent.width - parent.spacing)/2
                    height: rowHeight - parent.spacing/2

                    type:"action"
                    buttonText: qsTr("Close")

                    fillColor: palette.backgroundLight

                    onClicked: {
                        close();
                    }
                }
            }
        }
    }

    /*
      カメラ設定パネルを開いているうちに全てのコントロールを押せなくする。
     */
    Rectangle {
        id: maskpanel

        property int mode: 0
        readonly property int mode_camera: 1
        readonly property int mode_pref: 2
        readonly property int mode_camera_and_pref: 3

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

    // テザーコネクトモード確認ダイアログ
    LT.MessageBox{
        id: powerConfirmDialog
        modality: Qt.ApplicationModal
        title: "LUMIX Tether"
        visible: false
        text: qsTranslate("lumixtether::CustomDialog", "power_mode_change_warning")
        icon: LT.StandardIcon.Warning
        defaultButton: LT.StandardButton.No
        standardButtons: LT.StandardButton.Yes | LT.StandardButton.No
        onYes: {
            root.triggerPowerMode()
        }
    }

    Component.onCompleted: {
// IVC >> Ver.1.9 >> start >> [THRBOXV100-61]
        //usbEvent.usbEventCameraChanged.connect(root.usbEventCameraChanged);
// IVC << Ver.1.9 << end << [THRBOXV100-61]
        deviceAdapter.switchCameraNotify.connect(root.reconnectCameraStart)
        deviceAdapter.cameraStatusChanged.connect(root.btnAllCamerasEnableHandler);
        utilities.preferenceWindowVisibleChangedNotify.connect(root.preferenceWindowVisibleSetting);
        deviceAdapter.cameraListChanged.connect(root.cameraListSetting)
        // IVC >> Ver.1.9 >> start >> CustomDialog
//        deviceAdapter.customDialogPowerSavingOnAcceptedSignal.connect(root.triggerPowerMode);
        // IVC << Ver.1.9 << end << CustomDialog
// IVC >> Ver.1.9 >> start >> [THRBOXV100-61]
        //connectionEvent.cameraListChanged.connect(root.cameraListSetting)
        //var connType = deviceAdapter.adp_LMX_func_api_ptpip_Get_Connection_Type();
        //if(usbEvent.usbEventCamera == LT.UsbEvent.UEC_Connected && connType === LT.Utilities.PtpipConnType_Usb) {
        //    if (!utilities.isMac()) {
        //        connectionEvent.setEvent()
        //    }
        //}
// IVC << Ver.1.9 << end << [THRBOXV100-61]
        // IVC >> Ver.1.9 >> start >> [THRBOXV100-150] [THRBOXV100-154]
        // IVC << Ver.1.9. << end >> [THRBOXV100-150] [THRBOXV100-154]
        // IVC >> Ver.1.9 >> start >> [THRBOXV100-199]
//        if(!utilities.isMac()) {
//            // IVC >> Ver.1.9 >> start >> [THRBOXV100-63]
//            root.flags = Qt.Dialog | Qt.CustomizeWindowHint | Qt.WindowTitleHint | Qt.WindowCloseButtonHint | Qt.WindowMinimizeButtonHint
//            // IVC << Ver.1.9 << end << [THRBOXV100-63]
//        }
//        else {
//            root.flags = Qt.Dialog | Qt.CustomizeWindowHint | Qt.Tool | Qt.WindowTitleHint | Qt.WindowCloseButtonHint | Qt.WindowMinimizeButtonHint
//        }
        root.flags = Qt.Dialog | Qt.CustomizeWindowHint | Qt.WindowTitleHint | Qt.WindowCloseButtonHint | Qt.WindowMinimizeButtonHint | Qt.WindowMaximizeButtonHint
        // IVC << Ver.1.9 << end << [THRBOXV100-199]
    }

    onVisibleChanged: {
        if (root.visible) {
            root.showPopup();
        }
    }

    function preferenceWindowVisibleSetting(flg) {
        LTSubFunction.console_debug.out("MainWindow::preferenceWindowVisibleSetting flg=" + flg)
        if(flg) {
            maskpanel.mode = maskpanel.mode_pref
        } else {
            maskpanel.mode = 0
        }
        maskpanel.visible = flg
    }

    function showPopup() {
        root.clearObjects();

        // Update the camera list (auto) without pressing Update button
// IVC >> Ver.1.9 >> start >> [THRBOXV100-58]
//        if(!windowFirstInit) {
//            deviceAdapter.camera_list_update_camera_list();
//            root.windowFirstInit = true;
//        }
// IVC << Ver.1.9 << end << [THRBOXV100-58]
        // Load Camera list
        var numberOfCameras = deviceAdapter.camera_list_number_of_camera();

        var camIndex = 0;
        var number_camera = 0;
        var validSelect = false;
        for ( var i = 0; i < numberOfCameras; i++) {

            var connectCamera = deviceAdapter["camConnectDeviceStatus"]
            if (connectCamera(i)) {
                camIndex++;
                var camSerialNo = deviceAdapter.camera_list_get_camera_serial_number(i);
                var camIndividualId = deviceAdapter.camera_list_get_camera_individual_id(i);
                if(camIndividualId === ""){
                    camIndividualId = deviceAdapter.camera_list_get_camera_modelName(i);
                }
                var camPowerOnMode = deviceAdapter.camera_list_get_camera_power_mode(i);
                //テザーモード変更できるかどうか
                var camTetherModeStatus = deviceAdapter.camera_list_get_camera_tether_mode_status(i);
                var tetherModeButtonEnable = false;
                if( camTetherModeStatus === LT.Utilities.TETHERMODE_Enable){
                    tetherModeButtonEnable = true;
                }
//                var camSelectedState = (deviceAdapter.camCurrentSelectedSerialNo === camSerialNo && camPowerOnMode);
                // IVC >> Ver.1.9 >> start >> [THRBOXV100-65] - [THRBOXV100-66]
                var camSelectedState = (deviceAdapter.camCurrentSelectedSerialNo === camSerialNo);
                // IVC << Ver.1.9 << end << [THRBOXV100-65] - [THRBOXV100-66]
                if (camSelectedState) {
                     validSelect = true
                }

                objects.push( {
                                 index: i,
                                 cameraIdOrder: camIndex,
                                 cameraSerialNo: camSerialNo,
                                 cameraIdFullName: camIndividualId,
                                 cameraId: camIndividualId,
                                 checkedState: camSelectedState,
                                 powerOnMode: camPowerOnMode,
                                 cameraBtnEnable: tetherModeButtonEnable,
                                 camTetherModeStatus: camTetherModeStatus
                             } )
                number_camera++;
            }
            //In Camera List, display up to 12 cameras and 「All Cameras」.
            if(camIndex >= 12)
                break;
        }

        // Handle select camera in case there is no valid selection/select the 1st camera at the first show of the popup
        if(validSelect === false) {
            for(var i = 0; i < objects.length; i++) {
                if(objects[i].powerOnMode) {
                    objects[i].checkedState = true;
                    break;
                }
            }
        }
        updateCurrentSelectedCamera();
        handleAllCamerasButtonEnabled();

        for (var i = 0; i < number_camera; i++) {
            if(objects[i].checkedState) {
                deviceAdapter.camName = objects[i].cameraIdOrder + ": " + objects[i].cameraIdFullName
                break;
            }
        }

        if(objects.length < 5) {
            dumbModel = 5 - objects.length;
        }
        componentNum = number_camera;
        flickable.contentHeight = (componentNum + 1) * ( rowHeight + componentSpacing ) - componentSpacing

        popupContentRepeat.model = objects;
        dumbObject.model = dumbModel;
        //Check objects
        if (objects.length <= 0) {
//            btnUpdateCamList.enabled = false;
//            root.dismiss()
//            return;
        }
    }

    function clearObjects() {
        var n = objects.length;
        for (var i = 0; i < n; ++i) {
            //  objects に格納されたオブジェクトを取出して破棄する
            objects.pop();
        }
    }

    function onClickedUpDownButton(status, btnIndex) {
        var newIndex = btnIndex;
        if (status === 'up' && btnIndex > 0) {
            newIndex -= 1;
        } else if (status === 'down' && btnIndex < (objects.length - 1)) {
            newIndex += 1;
        }
        var curComponent = objects[btnIndex];
        objects[btnIndex] =  objects[newIndex];
        objects[newIndex] = curComponent;
        //Camera ID Order will not be changed when changing camera position
        var tempOrder = objects[btnIndex].cameraIdOrder;
        objects[btnIndex].cameraIdOrder = objects[newIndex].cameraIdOrder;
        objects[newIndex].cameraIdOrder = tempOrder
        var tempIndex = objects[btnIndex].index;
        objects[btnIndex].index = objects[newIndex].index;
        objects[newIndex].index = tempIndex
        popupContentRepeat.model = objects;
        updateModelCameraList();
        deviceAdapter.camera_list_update_camera_list();
        if(objects[btnIndex].checkedState) {
            deviceAdapter.camName = objects[btnIndex].cameraIdOrder + ": " + objects[btnIndex].cameraIdFullName
        }
        else if(objects[newIndex].checkedState) {
            deviceAdapter.camName = objects[newIndex].cameraIdOrder + ": " + objects[newIndex].cameraIdFullName
        }
        deviceAdapter.updateLiveviewSelectCamera()
    }

    function onClickedCheckCamera(index) {
        for(var i = 0; i < objects.length; i++) {
            if(objects[i].checkedState === true) {
                objects[i].checkedState = false;
                //選択外れた時にテザーモードのコピーフラグは解除しておく
                //表示の更新は選択処理のタイミングに任せる
                var uuid = deviceAdapter.camera_list_get_camera_uuid(objects[i].index)
                deviceAdapter.camera_list_set_camera_tether_mode_status(uuid, LT.Utilities.TETHERMODE_Copy, false)

                break;
            }
        }
//        console.debug("onClickedCheckCamera objects["+index+ "] " + " checkedState : " + checkedState
//                      + ", dev_index : " + objects[index].index
//                      + ", cameraSerialNo : " + objects[index].cameraSerialNo)
        objects[index].checkedState = true;
        popupContentRepeat.model = objects;
        updateCurrentSelectedCamera();
        updateModelCameraList();
        switchCamera(index);
    }

    function switchCamera(index) {
        var dev_index = deviceAdapter.camera_list_get_camera_dev_index(objects[index].index)
//        console.debug("switchCamera index="+index + " dev_index= " + dev_index)
        if(dev_index >= 0) {
            // Connect to target Camera
            deviceAdapter.camConnectStatus = LT.Utilities.CamConnectSts_Connecting

            // Try to connect the new selecting device
            var ret = deviceAdapter.adp_LMX_func_api_Select_Device(dev_index)
            if (ret !== LT.DeviceAdapter.Ternary_True) {
                deviceAdapter.camConnectStatus = LT.Utilities.CamConnectSts_Unknown
// IVC >> Ver.1.9 >> start >> [THRBOXV100-57]
            } else {
                deviceAdapter.camName = objects[index].cameraIdOrder + ": " + objects[index].cameraIdFullName
// IVC << Ver.1.9 << end << [THRBOXV100-57]
            }
        }
    }

    function triggerPowerMode() {
// IVC >> Ver.1.9 >> start >> [THRBOXV100-65] - [THRBOXV100-66]
//        var switchedCamIndex = -1
// IVC << Ver.1.9 << end << [THRBOXV100-65] - [THRBOXV100-66]
// IVC >> Ver.1.9 >> start >> [THRBOXV100-90]
        //var deviceUUID = deviceAdapter.camera_list_get_camera_uuid(index)
// IVC >> Ver.1.9 >> start >> [THRBOXV100-160]
//        var deviceUUID = deviceAdapter.camera_list_get_camera_uuid(objects[index].index);
        var deviceUUID = deviceAdapter.camera_list_get_camera_uuid(objects[powerChangeCamIndex].index);
// IVC << Ver.1.9 << end << [THRBOXV100-160]
// IVC << Ver.1.9 << end << [THRBOXV100-90]
        //console.debug("triggerPowerMode index="+index + " deviceUUID= " + deviceUUID)
        var error = false;
// IVC >> Ver.1.9 >> start >> CustomDialog
        if (objects.length > 0) {
// IVC << Ver.1.9 << end << CustomDialog
            if(objects[powerChangeCamIndex].powerOnMode === true) {
                // Power Saving ON → OFF
                // IVC >> Ver.1.9 >> start >> [THRBOXV100-144] - [THRBOXV100-145]
                deviceAdapter.adp_LMX_func_api_Rec_Ctrl_Menu_End_Menu(deviceUUID);
                // IVC << Ver.1.9 << end << [THRBOXV100-144] - [THRBOXV100-145]
                var result = deviceAdapter.adp_LMX_func_api_Power_SavingInfo_Set_Tether_Connect_Mode(deviceUUID,LT.Utilities.PwTether_OFF);
                if(result === LT.DeviceAdapter.Ternary_False) {
                    error = true
                }
                if(error == false) {
                    objects[powerChangeCamIndex].powerOnMode = false;
                }
// IVC >> Ver.1.9 >> start >> [THRBOXV100-65] - [THRBOXV100-66]
    //            if( objects[index].checkedState === true && error == false) {
    //                objects[index].checkedState = false;
    //                for(var i = 0; i < objects.length; i++) {
    //                    if(objects[i].powerOnMode === true && i !== index) {
    //                        objects[i].checkedState = true;
    //                        switchedCamIndex = i;
    //                        deviceAdapter.camName = objects[i].cameraIdOrder + ": " + objects[i].cameraIdFullName
    //                        break;
    //                    }
    //                }
    //            }
// IVC << Ver.1.9 << end << [THRBOXV100-65] - [THRBOXV100-66]
            }
            else {
// IVC >> Ver.1.9 >> start >> [THRBOXV100-65] - [THRBOXV100-66]
    //            var count = 0;
    //            for( var y = 0; y < objects.length; y++) {
    //                if(objects[y].powerOnMode === false) {
    //                    count++;
    //                }
    //            }
    //            if(count === objects.length) {
    //                objects[index].checkedState = true;
    //                switchedCamIndex = index;
    //                deviceAdapter.camName = objects[index].cameraIdOrder + ": " + objects[index].cameraIdFullName
    //            }
// IVC << Ver.1.9 << end << [THRBOXV100-65] - [THRBOXV100-66]

                // Power Saving OFF → ON
                var result = deviceAdapter.adp_LMX_func_api_Power_SavingInfo_Set_Tether_Connect_Mode(deviceUUID,LT.Utilities.PwTether_ON);
                if(result === LT.DeviceAdapter.Ternary_False) {
                    error = true
                }
                if(error == false) {
                    objects[powerChangeCamIndex].powerOnMode = true;
                }
            }

            handleAllCamerasButtonEnabled()

            // Update camera list to UI and to Model
            popupContentRepeat.model = objects;
// IVC >> Ver.1.9 >> start >> [THRBOXV100-65] - [THRBOXV100-66]
    //        updateCurrentSelectedCamera();
// IVC << Ver.1.9 << end << [THRBOXV100-65] - [THRBOXV100-66]
            updateModelCameraList();
// IVC >> Ver.1.9 >> start >> [THRBOXV100-65] - [THRBOXV100-66]
            // IVC >> Ver.1.9 >> start >> [THRBOXV100-49]
    //        if(isAllCameraPowerSaving() && error == false) {
    //        if(error == true) {
    //            //            deviceAdapter.isPowerSavingWaitDialogOpen = true;
    //            //            connectWindow.disconnectCameraStart();
    //        // IVC << Ver.1.9. << end << [THRBOXV100-49]
    ////            deviceAdapter.isPowerSavingWaitDialogOpenChanged.connect(root.reconnectCameraStart);
    //        }
    //        else {
    //            if(switchedCamIndex !== -1) {
    //                switchCamera(switchedCamIndex);
    //            }
    //        }
// IVC << Ver.1.9 << end << [THRBOXV100-65] - [THRBOXV100-66]
// IVC >> Ver.1.9 >> start >> CustomDialog
        }
// IVC << Ver.1.9 << end << CustomDialog
    }

    function updateModelCameraList() {
        for(var i = 0; i < objects.length; i++) {
            deviceAdapter.camera_list_set_camera_value(objects[i].index, objects[i].cameraSerialNo, objects[i].powerOnMode);
        }
    }

    // If there's only one camera is power-on, the All Cameras button will be disable
    function handleAllCamerasButtonEnabled() {
        var count = 0;
        for(var i = 0; i < objects.length; i++) {
            if(objects[i].powerOnMode) {
                count++;
                if(count === 2) {
                    break;
                }
            }
        }
        if(count < 2 || deviceAdapter.cameraStatus === LT.Utilities.CamStatus_Menu_Displayed) {
            btnAllCameras.btnEnabled = false;
        }
        else {
            btnAllCameras.btnEnabled = true;
        }
    }
// IVC >> Ver.1.9 >> start >> [THRBOXV100-49]
//    function connectWindowOpen() {
////        console.debug("connectionTest: Camera List Panel connectWindowOpen")
//        connectWindow.usbEventCheckStart()
//        connectWindow.objectStartFunc()
//        connectWindow.windowOpen()
//    }
// IVC << Ver.1.9. << end << [THRBOXV100-49]
    // IVC >> Ver.1.9 >> start >> No.2
    function btnAllCamerasEnableHandler() {
        if( deviceAdapter.isMultiviewMode === true ){
            if (deviceAdapter.cameraStatus === LT.Utilities.CamStatus_Menu_Displayed) {
                btnAllCameras.btnEnabled = false;
            } else {
                if(componentNum > 1){
                    btnAllCameras.btnEnabled = true;
                }
            }
        }else{
            if (deviceAdapter.cameraStatus === LT.Utilities.CamStatus_Menu_Displayed) {
                btnAllCameras.btnEnabled = false;
            } else {
                if(handleAllCamerasButtonEnabled() && componentNum > 1){
                    btnAllCameras.btnEnabled = true;
                }
            }
        }
    }

    // IVC >> Ver.1.9 >> start >> [THRBOXV100-58]
    function initCameraSetting() {
//        if(!root.windowFirstInit) {
//            deviceAdapter.camera_list_update_camera_list();
            // IVC >> Ver.1.9 >> start >> [THRBOXV100-57]
            showPopup();
            // IVC << Ver.1.9 << end << [THRBOXV100-57]
//            root.windowFirstInit = true;
//        }
    }
    // IVC << Ver.1.9 << end << [THRBOXV100-58]

    // IVC << Ver.1.9 << end << No.2
    function cameraListSetting() {
//        console.debug("cameraListChanged >>>>>>>>>>>>>>>> Reload Popup")
//        if (root.visible) {
            root.showPopup();
//        }
        var isConfirmingCamDisconnected = true;
        if (deviceAdapter.isCustomDialogVisible) {
            // Check whether the confirming camera index is changed or not
            for (var i = 0; i < objects.length; i++) {
                if(objects[i].cameraSerialNo === powerChangeCamSerialNo) {
                    if(i !== powerChangeCamIndex) {
                        powerChangeCamIndex = i;
                    }
                    isConfirmingCamDisconnected = false;
                    break;
                }
            }
            // If the confirming camera is disconnected, close the popup
            if(isConfirmingCamDisconnected) {
// IVC >> Ver.1.9 >> start >> [THRBOXV100-164] 
                //deviceAdapter.closeCustomDialog();
                deviceAdapter.closeCustomDialog(LT.Utilities.PowerSaving_ConfirmationDialog);
// IVC << Ver.1.9 << end << [THRBOXV100-164] 
            }
        }
    }

    function updateCurrentSelectedCamera() {
        if(!btnAllCameras.checked) {
            for(var i = 0; i < objects.length; i++) {
                if(objects[i].checkedState) {
                    deviceAdapter.camName = objects[i].cameraIdOrder + ": " + objects[i].cameraIdFullName;
                    deviceAdapter.camCurrentSelectedSerialNo = objects[i].cameraSerialNo;
                    break;
                }
            }
        }
    }
// IVC >> Ver.1.9 >> start >> [THRBOXV100-49]
//    function isAllCameraPowerSaving() {
//        for(var i = 0; i < deviceAdapter.camera_list_number_of_camera(); i++) {
//            if(deviceAdapter.camera_list_get_camera_power_mode(i)) {
//                return false;
//            }
//        }
//        return true;
//    }
// IVC << Ver.1.9. << end << [THRBOXV100-49]
// IVC >> Ver.1.9 >> start >> [THRBOXV100-61]
//    function usbEventCameraChanged() {
//        var connType = deviceAdapter.adp_LMX_func_api_ptpip_Get_Connection_Type();
//        if(connType === LT.Utilities.PtpipConnType_Usb)
//        {
//            if(usbEvent.usbEventCamera == LT.UsbEvent.UEC_Connected) {
//                connectionEvent.setEvent()
//            } else {
//                connectionEvent.checkStop()
//            }
//        }
//    }
// IVC << Ver.1.9 << end << [THRBOXV100-61]

    //TetherModeの変更を更新
    function tetherModeButtonUpdate() {
        for(var i = 0; i < objects.length; i++) {
            //テザーモード変更できるかどうか
            var camTetherModeStatus = deviceAdapter.camera_list_get_camera_tether_mode_status(objects[i].index)
            var tetherModeButtonEnable = false
            if( camTetherModeStatus === LT.Utilities.TETHERMODE_Enable){
                tetherModeButtonEnable = true
            }else{
                tetherModeButtonEnable = false
            }

            objects[i].cameraBtnEnable = tetherModeButtonEnable
            objects[i].camTetherModeStatus = camTetherModeStatus
        }
        //リストの表示
        popupContentRepeat.model = objects
    }

    function reconnectCameraStart() {
        deviceAdapter.camConnectStatus = LT.Utilities.CamConnectSts_GetData;
        deviceAdapter.isPowerSavingWaitDialogOpen = false;
        LTSubFunction.console_debug.out(">>>>>>>>> reconnectCameraStart")
        //SDK APIを呼び出しコントロールの設定範囲を呼び出す。
        if(!LTSubFunction.get_sdk_capability(false)) {
        }
        //SDK APIを呼び出しコントロールの設定値取得を呼び出す。
        if(!LTSubFunction.get_sdk_value(false)) {
        }
        //SDK APIを呼び出しコントロールの設定を呼び出す。
        LTSubFunction.set_sdk_value()

        deviceAdapter.camConnectStatus = LT.Utilities.CamConnectSts_Success

// IVC >> Ver.1.9 >> start >> [THRBOXV100-61]
        //var connType = deviceAdapter.adp_LMX_func_api_ptpip_Get_Connection_Type();
        //if(usbEvent.usbEventCamera == LT.UsbEvent.UEC_Connected && connType === LT.Utilities.PtpipConnType_Usb) {
        //    if (!utilities.isMac()) {
        //        connectionEvent.setEvent()
        //    }
        //}
// IVC << Ver.1.9 << end << [THRBOXV100-61]
        // IVC >> Ver.1.9 >> start >> [THRBOXV100-57]
        showPopup();
        // IVC << Ver.1.9 << end << [THRBOXV100-57]
    }

    function popupClose() {
//        LTSubFunction.console_debug.out("popupClose start")
        if(deviceAdapter.isCustomDialogVisible) {
            deviceAdapter.closeCustomDialog();
        }
    }

    /*!
        ポップアップを隠します
     */
    function dismiss() {
        visible = false
        root.clearObjects()
    }
}
