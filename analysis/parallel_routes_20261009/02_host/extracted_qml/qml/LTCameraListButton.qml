import QtQuick 2.6
import QtQuick.Controls 2.1
//import Qt5Compat.GraphicalEffects

import "qrc:/qml"
import LT 1.0 as LT

LTAbstractButton {
    id: root
    enabled: false

    /*!
        type
    */
    property string type: "action"

    /*!
        状態を示すテキストです
     */
    property string cameraIDText : ""

    property alias cameraIDTextOpacity : cameraIdText.opacity

    property string cameraName: ""

    property alias checkedCameraVisible: checkedCamera.opacity

    property alias allCameraUncheckImgSource: checkedCamera.source

    property alias cameraBtnIconOpacity: icoCamera.opacity
    //カメラアイコンの有効無効（画像は変化しない）
    property alias cameraBtnIconEnable: icoCameraItem.enabled

    property alias arrowIconVisible: icoArrow.visible

    property alias btnEnabled: checkedCameraItem.enabled

    property alias icoArrowUpOpacity: icoArrowUp.opacity

    property alias icoArrowDownOpacity: icoArrowDown.opacity

    property alias icoArrowUpEnable: icoArrowUp.enabled

    property alias icoArrowDownEnable: icoArrowDown.enabled

    property alias icoCameraSrc: icoCamera.source

    property bool checkStatus: false

    property int camTetherModeStatus: LT.Utilities.TETHERMODE_NOT_SUPPORT

    signal clickedUpDown(var status)

    signal clickedCheck(var checkedState)

    signal clickedAllCamCheck(var check)

    signal clickedPowerMode()

    /*!
        テキストの色です
     */
    property color textColor: enabled ? (checked ? "#000000" : "#dddddd") : "#646464";

    // IVC >> Ver.1.9 >> start >> [THRBOXV100-46]
    Column {
        anchors.fill: parent
        z: 20
        Item {
            width: parent.width
            height: parent.height
            anchors.left: parent.left
            anchors.right: parent.right
    // IVC<< Ver.1.9 << end << [THRBOXV100-46]
            Row {
                id: detailRow
                anchors.fill: parent
                Item {
                    id: checkedCameraItem
                    enabled: root.enabled
                    width: 45
                    height: parent.height
                    z: 10
                    Image {
                        id: checkedCamera
                        anchors.centerIn: parent
                        smooth: true
                        width: cameraName === "All Cameras" ? 20 : 25
                        height: cameraName === "All Cameras" ? 20 : 25
                        fillMode:  Image.Stretch
                        source: "qrc:/images/camera_selected.svg"
                        visible: true
                    }
                    MouseArea {
                        id: mouseArea
                        z: 50
                        height: parent.height
                        width: root.width - icoArrow.width - icoCameraItem.width
                        hoverEnabled: true
                        onClicked:(mouse)=> {
                            root.clicked(mouse, root)
                        }
                    }
                }
                Item {
                    id: cameraIdText
                    width: 25
                    height: parent.height
                    Text {
                        anchors.fill: parent
                        color: textColor
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment: Text.AlignVCenter
                        textFormat: Text.AutoText
                        font.pixelSize: 14
                        font.family: "Tahoma"
                        text: qsTr(cameraIDText + ":")
                    }
                }
                Item {
                    implicitWidth: {
                        if( deviceAdapter.isSupportMultiView() === false){
                            return parent.width - checkedCameraItem.width - cameraIdText.width - icoCameraItem.width - icoArrow.width
                        }else{
                            return parent.width - checkedCameraItem.width - cameraIdText.width - icoCameraItem.width - icoArrow.width - recStatusItem.width
                        }
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
                Item {
                    id: recStatusItem
                    width: 20
                    height: parent.height
                    visible: {
                        if( deviceAdapter.isSupportMultiView() === false){
                            return false
                        }else{
                            return true
                        }
                    }
                    Image {
                        id: recmark
                        anchors.centerIn: parent
                        width: 16
                        height: 16
                        source: "qrc:/images/12_rec_off.svg"
                        visible: {
                            if( deviceAdapter.isSupportMultiView() === false){
                                return false
                            }else{
                                if( camTetherModeStatus & LT.Utilities.TETHERMODE_Rec){
                                    return true
                                }else{
                                    return false
                                }
                            }
                        }
                    }
                }

                Item {
                    id: icoCameraItem
                    width: 40
                    height: parent.height
                    Image {
                        id: icoCamera
                        anchors.centerIn: parent
                        y: 2
                        width: 22
                        height: 20
                        source: "qrc:/images/camera_on.svg"
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.clickedPowerMode();
                        }
                    }
                }

                Column {
                    id: icoArrow
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20
                    spacing: 1
                    Image {
                        id: icoArrowUp
                        fillMode:  Image.PreserveAspectFit
                        source: "qrc:/images/camera_allow_up.svg"
                        y: -2
                        width: 12
                        height: 12
                        MouseArea {
                            anchors.fill: parent
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
                        MouseArea {
                            anchors.fill: parent
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
            root.clickedCheck(checkedCameraVisible);
        }
    }

    onCheckedCameraVisibleChanged: {
        if(checkedCameraVisible === 1) {
            deviceAdapter.camName = cameraIDText + ": " + cameraName
        }
    }
}
