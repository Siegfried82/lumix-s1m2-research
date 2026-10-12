import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0
import QtQuick.Window 2.3

import "qrc:/qml"
import LT 1.0 as LT

/*! \qmltype LTPreferenceAgreementPopup
    \inqmlmodule LT

    \brief
    LTOptionButton の状態を選択するポップアップです
 */
Window {
    id: root

    flags:
        Qt.Window
        | Qt.CustomizeWindowHint
        | Qt.WindowTitleHint
//        | Qt.FramelessWindowHint
//        | Qt.WindowSystemMenuHint
//        | Qt. WindowCloseButtonHint
        | Qt.WindowStaysOnTopHint

    modality: Qt.WindowModal

    visible: false

    //  ウィンドウの最小サイズと最大サイズを同じ値にして，リサイズできないようにする
    minimumWidth: popup.width
    minimumHeight: popup.height
    maximumWidth: minimumWidth
    maximumHeight: minimumHeight

    //  ウィンドウのサイズを最小/最大サイズにする
    width: minimumWidth
    height: minimumHeight

    title: qsTr("Agreement")
    color: "transparent"

    signal okClicked(string type)

    signal cancelClicked(string type)

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
        "headerText": "#ffffff",
        "line": "#000000",
    }

    /*!
        ボタンを並べて表示する領域の高さの上限です
     */


    property alias headerText: labelText.text

    property alias mainText: mainLabelText.text

    readonly property real headerHeight: 50

    readonly property real usageTextHeight: usageContentText.paintedHeight + 20

    readonly property real lineSize: 2

    readonly property real mainTextHeight: mainLabelText.paintedHeight + 20

    readonly property real mainTextWidth: 323   //470

    readonly property real marginsFooter: 3

    property string type: "preferenceAuto"

    onClosing: {
        root.cancelClicked(root.type);
        root.dismiss();
    }

    /*
        ボタンを並べて表示する領域
     */
    Rectangle {
        id: popup
        implicitWidth: flickable.width + border.width * 2
        implicitHeight: flickable.height + btnPanel.height + border.width * 2
        color: "#000000"

        border {
            width: 2
            color: "#c6c6c6"
        }

        Flickable {
            id: flickable
            x: popup.border.width
            y: popup.border.width
            implicitWidth: popupContent.width
            implicitHeight: popupContent.height
            contentHeight: popupContent.height
            contentWidth: popupContent.width
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            Column {
                id: popupContent

                width: mainTextWidth
                height: headerHeight + mainTextHeight

                Item {
                    id: usagePanel

                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    height: headerHeight

                    visible: false

                    LTStylishText {
                        id: usageHeaderText

                        anchors {
                            left: parent.left
                            right: parent.right
                            margins: 12
                        }
                        height: parent.height

                        text:qsTr("Usage Title")
                        color: palette.headerText
                        type: text_style_agreementTitle
                    }
                }

                Item {
                    id: usageContentPanel
                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    height: usageTextHeight

                    visible: false

                    LTStylishText {
                        id: usageContentText

                        anchors {
                            left: parent.left
                            right: parent.right
                            margins: 12
                        }
                        height: parent.height

                        text:qsTr("Usage Content")
                        color: palette.headerText
                        type: text_style_agreementContent
                        wrapMode: Text.Wrap
                    }
                }

                Item {
                    id: headerPanel

                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    height: headerHeight


                    LTStylishText {
                        id: labelText

                        anchors {
                            left: parent.left
                            right: parent.right
                            margins: 12
                        }
                        height: parent.height

                        text:qsTr("Agreement Title")
                        color: palette.headerText
                        type: text_style_agreementTitle
                    }
                }

                Item {
                    id: contentPanel
                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    height: mainTextHeight

                    LTStylishText {
                        id: mainLabelText

                        anchors {
                            left: parent.left
                            right: parent.right
                            margins: 12
                        }
                        height: parent.height

                        text:qsTr("Agreement Content")
                        color: palette.headerText
                        type: text_style_agreementContent
                        wrapMode: Text.Wrap
                    }
                }
            }
        }

        Rectangle {
            id: btnPanel

            anchors {
                top: flickable.bottom
                left: flickable.left
                right: flickable.right
            }
            height: 40

            color: palette.backgroundDark

            Row {
                x: marginsFooter
                y: marginsFooter
                width: parent.width - x*2
                height: parent.height - y*2

                spacing : marginsFooter

                LTRectangleButton {
                    id: btnConfirm

                    height: parent.height
                    width: parent.width
                    type: "action"
                    buttonText: qsTr("Confirm")

                    fillColor: palette.backgroundLight
                    visible: false

                    onClicked: {
                        root.okClicked(root.type);
                        root.dismiss();
                    }
                }

                LTRectangleButton {
                    id: btnOk

                    height: parent.height
                    width: (parent.width - parent.spacing)/2
                    type: "action"
                    buttonText: qsTr("Ok")


                    fillColor: palette.backgroundLight
                    visible: true

                    onClicked: {
                        root.okClicked(root.type);         //signal to parent window
                        root.dismiss();                    //close
                    }
                }

                LTRectangleButton {
                    id: btnCancel

                    height: parent.height
                    width: (parent.width - parent.spacing)/2
                    type: "action"
                    buttonText: qsTr("Cancel")

                    fillColor: palette.backgroundLight
                    visible: true

                    onClicked: {
                        root.cancelClicked(root.type);
                        root.dismiss();
                    }
                }
            }

        }

        states: [
            State {
                name: "startup"
                when: type == "startup"

                PropertyChanges {
                    target: btnConfirm
                    visible: true
                }

                PropertyChanges {
                    target: btnCancel
                    visible: false
                }

                PropertyChanges {
                    target: btnOk
                    visible: false
                }

                PropertyChanges {
                    target: usagePanel
                    visible: true
                }

                PropertyChanges {
                    target: usageContentPanel
                    visible: true
                }

                PropertyChanges {
                    target: popupContent
                    height: headerHeight*2 + mainTextHeight + usageTextHeight
                }
            },

            State {
                name: "preference"
                when: (type == "preferenceAuto" || type == "preferenceManual")

                PropertyChanges {
                    target: btnConfirm
                    visible: false
                }

                PropertyChanges {
                    target: btnCancel
                    visible: true
                }

                PropertyChanges {
                    target: btnOk
                    visible: true
                }

                PropertyChanges {
                    target: usagePanel
                    visible: false
                }

                PropertyChanges {
                    target: usageContentPanel
                    visible: false
                }

                PropertyChanges {
                    target: popupContent
                    height: headerHeight + mainTextHeight
                }
            }
        ]
    }



    /*!
        ポップアップを表示します
     */
    function present(x, y, type) {
        if (type) {
            root.type = type
        }

        root.x = (x != null) ? x : Math.round((Screen.width - popupContent.width) / 2);
        root.y = (y != null) ? y : Math.round((Screen.height - popupContent.height) / 2);
        root.width = popup.width;
        root.height = popup.height;

        visible = true;
    }

    /*!
        ポップアップを隠します
     */
    function dismiss() {
        visible = false;
        var n = objects.length;
        for (var i = 0; i < n; ++i) {
            //  objects に格納されたオブジェクトを取出して破棄する
            var object = objects.pop();
            object.destroy();
        }
    }

    /*!
        ポップアップに表示する，動的に生成したボタン

        \internal
     */
    property var objects: [ ]

}
