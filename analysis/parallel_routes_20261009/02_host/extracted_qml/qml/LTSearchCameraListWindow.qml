import QtQuick 2.15
import QtQml 2.2
import QtQuick.Window 2.3
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.1

import "qrc:/qml"
import LT 1.0 as LT
import "LTSubFunction.js" as LTSubFunction

Window {
    id: root

    //  ウィンドウのサイズを最小/最大サイズにする
    minimumWidth: 600     //710
    minimumHeight: 300    //232

    width: minimumWidth
    height: minimumHeight

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

    property int listRowHeight: 33
    property int btnRowHeight: 33
    property int informationHeight: 66
    //文字列の色
    property color textColor: "#dddddd"

    title: "CAMERA"

    Rectangle{
        id: background
        width: root.width
        height: root.height
        color: palette.backgroundDark
    }

    Column {
        id: column
        anchors {
            bottom: information.top                     //btnColumn.top
            top: parent.top
            left: parent.left
            right: parent.right
        }
        //ヘッダ部分
        LTSearchCameraListItem{
            id: itemsHeader
            height: listRowHeight
            width:flickable.width

            viewMode: LTSearchCameraListItem.ViewMode.Header
            fillColor: palette.backgroundLight
            sepalateColor: palette.backgroundLight
        }

        Flickable {
            id: flickable
            anchors.top: itemsHeader.bottom
            anchors.left: parent.left
            anchors.right: parent.right

            height: background.height - itemsHeader.height - btnRowHeight - informationHeight
            contentHeight: columnLayout.implicitHeight
            clip: true

            ColumnLayout {
                id: columnLayout
                enabled: true
                height: listRowHeight * (deviceAdapter.searchList.length+1)
                spacing: 0
                //項目一覧
                Repeater {
                    id: repeater
                    model: deviceAdapter.searchList
                    delegate: LTSearchCameraListItem{
                        Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                        height: listRowHeight
                        width:flickable.width

                        itemIndex: index
                        objectInfo: modelData
                        onEnableDeviceChanged: root.enableDeviceChanged()
                        fillColor: palette.backgroundDark
                        sepalateColor: palette.backgroundLight
                    }
                }

                //AllCameras
                LTSearchCameraListItem{
                    Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                    id: allCamera
                    height: listRowHeight
                    width:root.width

                    viewMode: LTSearchCameraListItem.ViewMode.AllCamera
                    fillColor: palette.backgroundDark
                    sepalateColor: palette.backgroundLight
                    onAllCamerasClicked: root.allCamerasClicked()
                }
            }

            ScrollBar.vertical: LTScrollBar {
                visible: (flickable.height < columnLayout.height)
            }
        }
    }

    Item {
        id: information
        anchors {
            top: column.bottomt
            bottom: btnColumn.top
            left: parent.left
            right: parent.right
        }

        width: parent.width
        height: informationHeight+2

        Text {
            id: information_caption
            text: qsTr("SearchCameraInformation")              // "起動したいカメラを選択して（チェックを付けて）、開始ボタンをクリックしてください。"
            anchors.verticalCenter: information.verticalCenter
            anchors.horizontalCenter: information.horizontalCenter
            font.pixelSize: 14
            color: textColor
            font.family: utilities.getFontFamily()
        }
    }

    Column {
        id: btnColumn
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

            height: btnRowHeight+2

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
                    height: btnRowHeight - parent.spacing/2

                    type:"action"
                    buttonText: qsTr("Update")
                    fillColor: palette.backgroundLight

                    onClicked: {
                        if(deviceAdapter.deviceSearch.addSearchMode){
                            //カメラリストからの追加検索の場合
                            deviceAdapter.camera_list_update_camera_list(true)
                        }else{
                            //起動時、全切断時の検索の場合
                            root.visible = false
                            //一度停止してから再検索する(LANが終わってない可能性あり)
                            deviceAdapter.deviceSearch.stopSearch()
                            deviceAdapter.deviceSearch.startSearch(false)
                        }
                    }
                }

                LTRectangleButton {
                    id: startButton
                    width: (parent.width - parent.spacing)/2
                    height: btnRowHeight - parent.spacing/2

                    type:"action"
                    buttonText: qsTr("Start")
                    toolTipText: qsTr("StartMessage")
                    enabled: false

                    fillColor: palette.backgroundLight

                    onClicked: {
                        if(deviceAdapter.deviceSearch.addSearchMode){
                            //カメラリストからの追加検索の場合
                            deviceAdapter.searchAddedDevice()
                            root.visible = false
                        }else{
                            //起動時、全切断時の検索の場合
                            deviceAdapter.connectEnableDevice()
                            //非表示は接続処理のイベント（camConnectStatusChanged）をトリガーにLTMainObjectで行われる
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        deviceAdapter.searchListChanged.connect(root.searchListChanged)
    }

    onVisibilityChanged: {
        utilities.searchCamWindowVisibleChanged(root.visible)
    }

    function searchListChanged()
    {
        //項目自体がなくなった時うまく更新できてなさそうなので、再bindする
        repeater.model = null
        if(deviceAdapter.searchList.length > 0){
            repeater.model = deviceAdapter.searchList
        }

        startButtonUpdate()
        allCamerasUpdate()
    }

    function enableDeviceChanged()
    {
        startButtonUpdate()
        allCamerasUpdate()
    }

    function startButtonUpdate(){
        //スタートボタンのチェック更新
        var enableBtn = false
        for( var i=0; i<deviceAdapter.searchList.length; i++){
            if( deviceAdapter.searchList[i].enable){
                enableBtn = true
                break;
            }
        }
        startButton.enabled = enableBtn
    }

    function allCamerasUpdate(){
        //AllCamarasのチェック更新
        var enableAll = true
        if( deviceAdapter.searchList.length === 0){
            enableAll = false
        }

        for(var i=0; i<deviceAdapter.searchList.length; i++){
            if( !deviceAdapter.searchList[i].enable){
                enableAll = false
                break;
            }
        }
        allCamera.allCameraCheck = enableAll
    }

    function allCamerasClicked()
    {
        //リスト0なら何もしない
        if( deviceAdapter.searchList.length === 0){
            allCamerasUpdate()
            return
        }

        //全部チェック入ってるか確認
        var enableAll = true
        for( var i=0; i<deviceAdapter.searchList.length; i++){
            if( !deviceAdapter.searchList[i].enable){
                enableAll = false
                break;
            }
        }
        if( !enableAll ){
            //1つでもチェック入ってないなら、全部チェック
            for( i=0; i<deviceAdapter.searchList.length; i++){
                deviceAdapter.searchList[i].enable = true
            }
            allCamera.allCameraCheck = true
        }else{
            //全部チェック入ってるなら、全部OFF
            for( i=0; i<deviceAdapter.searchList.length; i++){
                deviceAdapter.searchList[i].enable = false
            }
            allCamera.allCameraCheck = false
        }

        startButtonUpdate()
    }

    /*!
        ポップアップを隠します
     */
    function dismiss() {
        visible = false
        root.clearObjects()
    }
}
