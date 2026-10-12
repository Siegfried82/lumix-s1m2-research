import QtQuick 2.6
import QtQuick.Window 2.3
import QtQuick.Controls 2.0
import Qt.labs.platform 1.0

import "qrc:/qml"
import LT 1.0 as LT


import "LTSubFunction.js" as LTSubFunction

/*! \qmltype LTConnectionWindow
    \inqmlmodule LT

    \brief
    Dialog connect device
 */

Window {
    id: root
//    flags: Qt.Window | Qt.CustomizeWindowHint | Qt.WindowTitleHint | Qt.WindowSystemMenuHint | Qt. WindowCloseButtonHint | Qt.MSWindowsFixedSizeDialogHint
    flags:
        Qt.Dialog
        | Qt.CustomizeWindowHint
        | Qt.WindowTitleHint
        | Qt.WindowCloseButtonHint
        | Qt.MSWindowsFixedSizeDialogHint
        | Qt.WindowSystemMenuHint

    width: image.width
    height: image.height

    //Windowサイズを変更できなくする
    minimumWidth: image.width
    minimumHeight: image.height
    maximumWidth: image.width
    maximumHeight: image.height

    title: "LUMIX Tether"
    visible: true

    /*!
        初回起動時の接続が完了したことを通知します
     */
    signal connectCompleted(bool arg)
    /*!
        初回起動時以外の接続が完了したことを通知します
     */
    signal reconnectCompleted()
    /*!
        切断したことを通知します
     */
    signal disconnectCompleted()

    signal searchCompleted(bool background)

    property bool initialFlg: false

    property var searchStatus: deviceAdapter.deviceSearch.devSearchStatus
    property var connectingStatus: deviceAdapter.camConnectStatus

    /*
        画像
     */
    Image {
        id: image
        source: "qrc:/images/450_popup.png"
    }

    LTStylishText {
        id: message_disp
        type: text_style_connectionMsg
    }

    LT.MessageBox{
        id: errorDialog
        //icon: StandardIcon.Critical
        visible: false
        title: qsTr("Error")
        standardButtons: StandardButton.Close

        onVisibleChanged: {
            if(!this.visible) {
                if(deviceAdapter.isCamerasConnected) {
                    root.close();
                }
            }
        }
    }


    Component.onCompleted: {
        root.x = (Screen.width - image.width) / 2
        root.y = (Screen.height - image.height) / 2

    }

    onSearchStatusChanged: {

        if( deviceAdapter.deviceSearch.devSearchStatus === LT.DeviceSearch.DEVSEARCH_STATUS_Searching){
            if(deviceAdapter.deviceSearch.addSearchMode){
                //追加検索の場合は表示させない
                return
            }
            visible = true;

            message_disp.text = qsTr("Please connect to device")
            message_disp.x = root.width / 2 - message_disp.width / 2
            message_disp.y = (root.height * 3) / 4
            message_disp.z = 30
            message_disp.color = "#C3C3C3"
            message_disp.font.pixelSize = 15
            message_disp.verticalAlignment = Text.AlignVCenter
            message_disp.horizontalAlignment = Text.AlignHCenter
        }else if(deviceAdapter.deviceSearch.devSearchStatus === LT.DeviceSearch.DEVSEARCH_STATUS_Stop){
            visible = false;
            root.searchCompleted(deviceAdapter.deviceSearch.backgroundSearch)
        }
    }

    onConnectingStatusChanged: {
        if( deviceAdapter.camConnectStatus === LT.Utilities.CamConnectSts_GetData){
            message_disp.text = qsTr("connecting ...")
            visible = true;
        }else{
            visible = false;
        }
    }
}
