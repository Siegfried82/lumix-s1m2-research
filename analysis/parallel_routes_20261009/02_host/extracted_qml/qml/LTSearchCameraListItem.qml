import QtQuick 2.15
import QtQml 2.2
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.1

import "qrc:/qml"
import LT 1.0 as LT

Item {
    id: root

    enum ViewMode{
        Standard,
        Header,
        AllCamera
    }

    property LT.SearchCameraListItemObject objectInfo
    //番号表示用に利用するIndex
    property int itemIndex: 0

    //文字列の色
    property color textColor: "#dddddd"
    //背景色の色
    property color fillColor: "#07090d"
    //区切り線の色
    property color sepalateColor: "#292b2d"

    //ヘッダ表示モードかどうか
    property int viewMode: LTSearchCameraListItem.ViewMode.Standard

    //使用有無のボタン押された時の通知
    signal enableDeviceChanged()

    //AllCamerasのチェック状態
    property bool allCameraCheck: false
    //AllCamerasのボタン押された時の通知
    signal allCamerasClicked()

    property string authorizeToolTipText: ""
    property string connectModeToolTipText: ""

    readonly property int bootW : 65
    readonly property int authorizeW : 50
    readonly property int item_numberW : 30
    readonly property int item_cameraNameW : 160
    readonly property int connectModeW : 50
    readonly property int item_ipW : 140

    Rectangle {
        //背景
        id: background
        z: 10
        width: root.width
        height: root.height-1

        color: fillColor

        Row {
            //ヘッダ表示用
            anchors.verticalCenter: parent.verticalCenter
            id: rowHeader
            spacing: 10
            height: background.height
            visible: {
                if( root.viewMode === LTSearchCameraListItem.ViewMode.Header){
                    return true
                }else{
                    return false
                }
            }

            Item {
                width: bootW
                height: parent.height

                Text {
                    text: qsTr("boot")
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.pixelSize: 14
                    color: textColor
                    font.family: utilities.getFontFamily()
                }
            }
            Item {
                width: authorizeW
                height: parent.height

                Text {
                    text: qsTr("authorize")
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.pixelSize: 14
                    color: textColor
                    font.family: utilities.getFontFamily()
                }
            }
            Item {
                width: item_numberW + 10 + item_cameraNameW
                height: parent.height

                Text {
                    text: qsTr("device name")
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.pixelSize: 14
                    color: textColor
                    font.family: utilities.getFontFamily()
                }
            }

            Item {
                width: connectModeW
                height: parent.height

                Text {
                    text: qsTr("connect")
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.pixelSize: 14
                    color: textColor
                    font.family: utilities.getFontFamily()
                }
            }

            Item {
                width: item_ipW
                height: parent.height

                Text {
                    text: qsTr("ip")
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.pixelSize: 14
                    color: textColor
                    font.family: utilities.getFontFamily()
                }
            }
//            Item {
//                width: 160
//                height: parent.height

//                Text {
//                    text: "MAC address"
//                    anchors.verticalCenter: parent.verticalCenter
//                    anchors.horizontalCenter: parent.horizontalCenter
//                    font.pixelSize: 14
//                    color: textColor
//                    font.family: utilities.getFontFamily()
//                }
//            }
        }

        Row {
            //通常の項目表示用
            anchors.verticalCenter: parent.verticalCenter
            id: row
            spacing: 10
            height: background.height
            visible: {
                if( root.viewMode === LTSearchCameraListItem.ViewMode.Standard){
                    return true
                }else{
                    return false
                }
            }

            //使用有無のチェック
            Item {
                id: enableCheck
                width: bootW
                height: parent.height


                Image{
                    id: cameraCmdCheckImg
                    anchors.centerIn: parent
                    width: 21
                    height: 21
                    source: {
                        if( objectInfo === null ){
                            return ""
                        }
                        if( objectInfo.enable === false){
                            return "qrc:/images/camera_cmd_check_off.svg"
                        }else{
                            return "qrc:/images/camera_cmd_check_on.svg"
                        }
                    }
                }
                MouseArea {
                    anchors.fill: enableCheck
                    onClicked:{
                        if( objectInfo === null ){
                            return null
                        }
                        objectInfo.enable = !objectInfo.enable
                        root.enableDeviceChanged()
                    }
                }
            }

            //接続履歴
            Item {
                id: authorize
                width: authorizeW
                height: parent.height

                Image{
                    id: authorizeImg
                    anchors.centerIn: parent
                    width: 21
                    height: 21
                    source: {
                        if( objectInfo === null ){
                            return ""
                        }
                        if( objectInfo.authorize === false){
                            return "qrc:/images/search_cam_unauthorized.svg"
                        }else{
                            return "qrc:/images/search_cam_authorize.svg"
                        }
                    }
                }
                LTToolTip{
                    id: authorizeToolTip
                    toolTipText: authorizeToolTipText
                }
                MouseArea {
                    anchors.fill: authorize
                    hoverEnabled: true
                    onEntered: {
                        if( objectInfo === null ){
                            return
                        }
                        if( objectInfo.connectMode === LT.SearchCameraListItemObject.CONNECT_LAN && objectInfo.enableTls === true){
                            authorizeToolTip.toolTipMouseContains = containsMouse
                            if( objectInfo.authorize === false){
                                authorizeToolTipText = qsTr("unauthorized")
                            }else{
                                authorizeToolTipText = qsTr("authorized")
                            }
                        }
                    }
                    onExited: {
                        authorizeToolTip.toolTipMouseContains = containsMouse
                        authorizeToolTipText = ""
                    }
                }
            }

            //デバイス名の前に表示する番号
            Item {
                id: item_number
                width: item_numberW
                anchors.top: parent.top
                anchors.bottom: parent.bottom

                Text {
                    id: text_number
                    text: itemIndex+1 + ":"
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 14
                    color: textColor
                    font.family: utilities.getFontFamily()
                }
            }

            //デバイス名
            Item {
                id: item_cameraName
                width: item_cameraNameW
                anchors.top: parent.top
                anchors.bottom: parent.bottom

                Text {
                    id: text_cameraName
                    text: {
                        if( objectInfo === null ){
                            return ""
                        }
                        if( objectInfo.devFrlyName.length > 0){
                            return objectInfo.devFrlyName
                        }
                        return objectInfo.devModelName
                    }
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 14
                    color: textColor
                    font.family: utilities.getFontFamily()
                }
            }

            //接続モード
            Item {
                id: connectMode
                width: connectModeW
                height: parent.height

                Image{
                    id: connectModeImg
                    anchors.centerIn: parent
                    width: 21
                    height: 21
                    source: {
                        if( objectInfo === null ){
                            return ""
                        }
                        if( objectInfo.connectMode === LT.SearchCameraListItemObject.CONNECT_LAN){
                            if(objectInfo.enableTls === true){
                                return "qrc:/images/search_cam_encrypt.svg"
                            }else{
                                return "qrc:/images/search_cam_unencrypted.svg"
                            }
                        }else if( objectInfo.connectMode === LT.SearchCameraListItemObject.CONNECT_USB){
                            return "qrc:/images/search_cam_usb.svg"
                        }
                    }
                }
                LTToolTip{
                    id: connectModeToolTip
                    toolTipText: connectModeToolTipText
                }
                MouseArea {
                    anchors.fill: connectMode
                    hoverEnabled: true
                    onEntered: {
                        if( objectInfo === null ){
                            return
                        }
                        connectModeToolTip.toolTipMouseContains = containsMouse
                        if( objectInfo.connectMode === LT.SearchCameraListItemObject.CONNECT_LAN){
                            if(objectInfo.enableTls === true){
                                connectModeToolTipText =  qsTr("encrypt")
                            }else{
                                connectModeToolTipText = qsTr("unencrypted")
                            }
                        }else if( objectInfo.connectMode === LT.SearchCameraListItemObject.CONNECT_USB){
                            connectModeToolTipText =  qsTr("usb")
                        }
                    }
                    onExited: {
                        connectModeToolTip.toolTipMouseContains = containsMouse
                        connectModeToolTipText = ""
                    }
                }
            }

            //IPアドレス
            Item {
                id: item_ip
                width: item_ipW
                anchors.top: parent.top
                anchors.bottom: parent.bottom

                Text {
                    id: text_ip
                    text: {
                        if( objectInfo === null ){
                            return ""
                        }
                        return objectInfo.ip
                    }
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.pixelSize: 14
                    color: textColor
                    font.family: utilities.getFontFamily()
                }
            }

            //MACアドレス
//            Item {
//                id: item_mac
//                width: 160
//                anchors.top: parent.top
//                anchors.bottom: parent.bottom

//               Text {
//                    id: text_mac
//                    text: {
//                        if( objectInfo === null ){
//                            return ""
//                        }
//                        return objectInfo.macAddress
//                    }
//                    anchors.verticalCenter: parent.verticalCenter
//                    anchors.horizontalCenter: parent.horizontalCenter
//                    font.pixelSize: 14
//                    color: textColor
//                    font.family: utilities.getFontFamily()
//               }
//           }
        }

        Row {
            //AllCamera用
            anchors.verticalCenter: parent.verticalCenter
            id: allCameraRow
            spacing: 10
            height: background.height
            visible: {
                if( root.viewMode === LTSearchCameraListItem.ViewMode.AllCamera){
                    return true
                }else{
                    return false
                }
            }

            //使用有無のチェック
            Item {
                id: enableCheckAll
                width: bootW
                height: parent.height

                Image{
                    id: cameraCmdCheckImgAll
                    anchors.centerIn: parent
                    width: 21
                    height: 21
                    source: {
                        if( allCameraCheck === false){
                            return "qrc:/images/camera_cmd_check_off.svg"
                        }else{
                            return "qrc:/images/camera_cmd_check_on.svg"
                        }
                    }
                }
                MouseArea {
                    anchors.fill: enableCheckAll
                    onClicked:{
                        root.allCamerasClicked()
                    }
                }
            }

            //接続履歴
            Item {
                id: authorizeAll
                width: authorizeW
                height: parent.height
            }

            //デバイス名の前に表示する番号
            Item {
                id: item_numberAll
                width: item_numberW
                anchors.top: parent.top
                anchors.bottom: parent.bottom
            }

            //デバイス名
            Item {
                id: item_cameraNameAll
                width: item_cameraNameW
                anchors.top: parent.top
                anchors.bottom: parent.bottom

                Text {
                    id: text_cameraNameAll
                    text: qsTr("All Cameras")
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 14
                    color: textColor
                    font.family: utilities.getFontFamily()
                }
            }
        }
    }
    //一番下に表示する区切り線
    Rectangle {
        id: sepalate
        z: 10
        width: root.width
        height: 1
        x: 0
        y: root.height-1

        color: sepalateColor
    }
}
