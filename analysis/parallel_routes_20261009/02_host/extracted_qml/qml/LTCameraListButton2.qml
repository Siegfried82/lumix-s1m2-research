import QtQuick 2.6
import QtQuick.Controls 2.1

import "qrc:/qml"
import LT 1.0 as LT

LTAbstractButton {
    id: root

    /*!
        type
    */
    property string type: "action"

    /*!
        状態を示すテキストです
     */
    //AllCamera用のアイテムかどうか
    property bool isAllCameraBtn : false
    //選択カメラかどうか
    property bool selectCamera : false
    //カメラの通し番号
    property string cameraIDText : ""
    //カメラ名
    property string cameraName: ""
    //テザーモードのステータス
    property int tetherModeStatus: LT.Utilities.TETHERMODE_NOT_SUPPORT
    //テザーモードの状態（ON/OFF）
    property bool tetherModeON: true
    //順番入れ替え矢印が有効かどうか
    property bool enableOrderChangeUp: false
    property bool enableOrderChangeDown: false
    //コマンド送信対象かどうか
    property bool sendCmdCheck: false
    //ライブビュー表示対象かどうか
    property bool liveViewCheck: false
    //コマンド送信のチェックが全部入っているかどうか（AllCamaeraの場合）
    property bool isSendCmdAllCheck: false
    //ライブビュー表示のチェックが全部入っているかどうか（AllCamaeraの場合）
    property bool isliveViewAllCheck: false


    signal clickedUpDown(var status)

    signal clickedCheck()

    signal clickedAllCamCheck(var check)
    //テザーモードのボタン押された
    signal clickedPowerMode()
    //コマンド送信のチェックボタンが押された
    signal clickedSendCmdCheck()
    //ライブビュー表示のチェックボタンが押された
    signal clickedLiveViewCheck()
    //AllCamerasのコマンド送信ボタンが押された
    signal clickedSendCmdAllCheck()
    //AllCamerasのライブビュー表示のチェックボタンが押された
    signal clickedLiveViewAllCheck()

    /*!
        テキストの色です
     */
    property color textColor: enabled ? (checked ? "#000000" : "#dddddd") : "#646464";

    // IVC >> Ver.1.9 >> start >> [THRBOXV100-46]
    Column {
        anchors.fill: parent
        z: 20
        Item {
            id:btnItem
            width: parent.width
            height: parent.height
            anchors.left: parent.left
            anchors.right: parent.right
    // IVC<< Ver.1.9 << end << [THRBOXV100-46]
            Row {
                id: detailRow
                anchors.fill: parent
                //選択カメラの枠（マルチ対応版）
                Item{
                    Rectangle{
                        id: selectBorder
                        color: "transparent"
                        border.color: "#ffbf1f"
                        border.width: 2
                        width: btnItem.width
                        height: btnItem.height
                        visible: selectCamera
                    }
                }
                //コマンド送信対象のチェック（マルチ対応版）
                Item {
                    id: cameraCmdCheck
                    width: 30
                    height: parent.height
                    enabled: {
                        if( root.enabled === true ){
                            return true
                        }else{
                            return false
                        }
                    }

                    Image{
                        id: cameraCmdCheckImg
                        anchors.centerIn: parent
                        width: 21
                        height: 21
                        source: {
                            if( sendCmdCheck === true || (isAllCameraBtn === true && isSendCmdAllCheck === true)){
                                return "qrc:/images/camera_cmd_check_on.svg"
                            }else{
                                return "qrc:/images/camera_cmd_check_off.svg"
                            }
                        }
                        visible: {
                            if( cameraCmdCheck.enabled === true){
                                return true
                            }else{
                                return false
                            }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if( isAllCameraBtn === false ){
                                root.clickedSendCmdCheck()
                            }else{
                                root.clickedSendCmdAllCheck()
                            }
                        }
                    }
                }
                //ライブ表示対象のチェック（マルチ対応版）
                Item {
                    id: cameraMultiViewCheck
                    width: 35
                    height: parent.height
                    enabled: {
                        if( root.enabled === true){
                            return true
                        }else{
                            return false
                        }
                    }

                    Image{
                        id: cameraMultiViewCheckImg
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 21
                        height: 21
                        source: {
                            if( liveViewCheck === true || (isAllCameraBtn === true && isliveViewAllCheck === true) ){
                                return "qrc:/images/camera_multi_visibility_on.svg"
                            }else{
                                return "qrc:/images/camera_multi_visibility_off.svg"
                            }
                        }
                        visible: {
                            if( cameraMultiViewCheck.enabled === true){
                                return true
                            }else{
                                return false
                            }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if( isAllCameraBtn === false ){
                                root.clickedLiveViewCheck()
                            }else{
                                root.clickedLiveViewAllCheck()
                            }
                        }
                    }
                }
                //カメラの通し番号表示部分
                Item {
                    id: cameraIdText
                    width: 25
                    height: parent.height
                    enabled: {
                        if( root.enabled === true && isAllCameraBtn === false ){
                            return true
                        }else{
                            return false
                        }
                    }
                    Text {
                        anchors.fill: parent
                        color: textColor
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                        textFormat: Text.AutoText
                        font.pixelSize: 14
                        font.family: "Tahoma"
                        text: qsTr(cameraIDText + ":")
                        visible: {
                            if( isAllCameraBtn === false && root.enabled === true){
                                return true
                            }else{
                                return false
                            }
                        }
                    }
                    //選択カメラ変更用のクリック領域
                    MouseArea {
                        id: mouseArea
                        z: 50
                        height: parent.height
                        width: {
                            return root.width - cameraCmdCheck.width - cameraMultiViewCheck.width - icoArrow.width - icoCameraItem.width - recStatusItem.width
                        }
                        hoverEnabled: true
                        onClicked:(mouse)=> {
                            root.clicked(mouse, root)
                        }
                        enabled: {
                            if( isAllCameraBtn === false && root.enabled === true){
                                return true
                            }else{
                                return false
                            }
                        }
                    }
                }
                //カメラ名表示部分
                Item {
                    implicitWidth: {
                        return parent.width - cameraCmdCheck.width - cameraMultiViewCheck.width - cameraIdText.width - icoCameraItem.width - icoArrow.width - recStatusItem.width
                    }
                    height: parent.height
                    Text {
                        id: lblCamera
                        width: parent.width - cameraIdText.width
                        height: parent.height
                        color: textColor
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                        textFormat: Text.AutoText
                        font.pixelSize: 14
                        font.family: "Tahoma"
                        elide: Text.ElideRight
                        text : qsTr(cameraName)
                    }
                }
                //テザーモードのカメラアイコン表示
                Item {
                    id: icoCameraItem
                    width: 30
                    height: parent.height
                    enabled: {
                        if( root.enabled === true && isAllCameraBtn === false ){
                            return true
                        }else{
                            return false
                        }
                    }

                    Image {
                        id: icoCamera
                        anchors.centerIn: parent
                        y: 2
                        width: 22
                        height: 20
                        source: {
                            if( tetherModeStatus === LT.Utilities.TETHERMODE_Enable){
                                if( tetherModeON === true){
                                    return "qrc:/images/camera_on.svg"
                                }else{
                                    return "qrc:/images/camera_off.svg"
                                }
                            }else{
                                return "qrc:/images/camera_off.svg"
                            }
                        }
                        visible: {
                            if( icoCameraItem.enabled === true){
                                return true
                            }else{
                                return false
                            }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if( tetherModeStatus & LT.Utilities.TETHERMODE_NOT_SUPPORT){
                                return
                            }else{
                                if(tetherModeStatus === LT.Utilities.TETHERMODE_Enable){
                                    root.clickedPowerMode()
                                }
                            }
                        }
                    }
                }
                //録画ステータスのアイコン表示
                Item {
                    id: recStatusItem
                    width: 30
                    height: parent.height
                    enabled: {
                        if( root.enabled === true && isAllCameraBtn === false ){
                            return true
                        }else{
                            return false
                        }
                    }
                    Image {
                        id: recmark
                        anchors.centerIn: parent
                        width: 20
                        height: 20
                        source: "qrc:/images/camera_status_rec.svg"
                        visible: {
                            if( tetherModeStatus & LT.Utilities.TETHERMODE_Rec &&
                                    recStatusItem.enabled === true){
                                return true
                            }else{
                                return false
                            }
                        }
                    }
                }
                //順番切り替えの矢印表示
                Column {
                    id: icoArrow
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20
                    spacing: 1
                    enabled: {
                        if( root.enabled === true && isAllCameraBtn === false ){
                            return true
                        }else{
                            return false
                        }
                    }
                    Image {
                        id: icoArrowUp
                        fillMode:  Image.PreserveAspectFit
                        source: "qrc:/images/camera_allow_up.svg"
                        y: -2
                        width: 12
                        height: 12
                        opacity: {
                            if( enableOrderChangeUp === true &&
                                    icoArrow.enabled === true){
                                return 1.0
                            }else{
                                return 0.5
                            }
                        }
                        visible: {
                            if( icoArrow.enabled === true){
                                return true
                            }else{
                                return false
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: enableOrderChangeUp
                            onClicked: {
                                root.clickedUpDown('up');
                            }
                            onEntered: {
                                icoArrowUp.opacity = 1.0
                            }
                            onExited: {
                                icoArrowUp.opacity = 0.5
                            }
                            onPressed: {
                                icoArrowUp.opacity = 0.7
                            }
                            onReleased: {
                                icoArrowUp.opacity = 1.0
                            }
                        }
                    }

                    Image {
                        id: icoArrowDown
                        fillMode:  Image.Stretch
                        width: 12
                        height: 12
                        source: "qrc:/images/camera_allow_down.svg"
                        opacity: {
                            if( enableOrderChangeDown === true &&
                                    icoArrow.enabled === true){
                                return 1.0
                            }else{
                                return 0.5
                            }
                        }
                        visible: {
                            if( icoArrow.enabled === true){
                                return true
                            }else{
                                return false
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: enableOrderChangeDown
                            onClicked: {
                                root.clickedUpDown('down');
                            }
                            onEntered: {
                                icoArrowDown.opacity = 1.0
                            }
                            onExited: {
                                icoArrowDown.opacity = 0.5
                            }
                            onPressed: {
                                icoArrowDown.opacity = 0.7
                            }
                            onReleased: {
                                icoArrowDown.opacity = 1.0
                            }
                        }
                    }
                }
            }
        // IVC >> Ver.1.9 >> start >> [THRBOXV100-46]
        }

        Rectangle {
            height: 1
            width: detailRow.width
            color: palette.backgroundLight
        }
    }
    // IVC<< Ver.1.9 << end << [THRBOXV100-46]
    /*
        境界線と背景ぬりつぶし
     */
    Rectangle {
        id: rectangle
        z: 10
        implicitWidth: parent.width
        implicitHeight: root.height
        color: fillColor
        radius: 0
    }
    onClicked: {
        if(lblCamera.text != "") {
            root.clickedCheck();
        }
    }
}
