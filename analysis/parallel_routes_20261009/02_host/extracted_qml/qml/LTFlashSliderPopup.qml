import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0
import "LTSubFunction.js" as LTSubFunction

import "qrc:/qml"

/*! \qmltype LTFlashSliderPopup
    \inqmlmodule LT

    \brief
    LTOptionButton の状態を選択するポップアップです
 */
Item {
    id: root

    signal onOKClicked(int btnId)

    signal onCancelClicked(int btnId)

    visible: false
    anchors {
        fill: parent
    }

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
        "checked": "#ffbf1f"
    }

    /*!
        ボタンを並べて表示する領域の高さの上限です
     */
    property real maximumPopupHeight: 570

    property LTFlashSlider sliderObj

    property int btnId: -1

    property var source
    /*
        背景

        ボタンを表示する領域の外部全体を暗くして，マウス操作に反応しないようにします．
        また，クリックされると選択パネルを閉じます．
     */
    Rectangle {
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
                root.dismiss();
            }
        }
    }

    /*
        ボタンを並べて表示する領域
     */
    Rectangle {
        id: popup
        implicitWidth: flickable.width + border.width * 2
        implicitHeight: flickable.height + border.width * 2 + btnPanel.height
        color: "#000000"
        border {
            width: 2
            color: "#c6c6c6"
        }
        Flickable {
            id: flickable
            x: popup.border.width
            y: popup.border.width
            implicitWidth: popupContent.width + (ScrollBar.vertical.visible ? ScrollBar.vertical.width : 0)
            implicitHeight: Math.min(popupContent.height, maximumPopupHeight)
            contentHeight: popupContent.height
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            ColumnLayout {
                id: popupContent
                spacing: 0
            }
            ScrollBar.vertical: LTScrollBar {
                visible: flickable.height < flickable.contentHeight
            }
        }
        Row {
            id: btnPanel
            anchors {
                top: flickable.bottom
                left: flickable.left
                right: flickable.right
            }
            height: btnCancel.height

            spacing : 1

            LTRectangleButton {
                id: btnOk

                height: 40
                width: flickable.width/2
                type: "action"
                buttonText: qsTr("Ok")

                fillColor: palette.backgroundLight

                onClicked: {
                    if (sliderObj.windowType == sliderObj.slider_window_flashPopup) {
                        root.source.value = sliderObj.value;
                        root.source.optionText = sliderObj.textValue(sliderObj.value);

                        flashAdapter[sliderObj.target] = sliderObj.value;
                    }

                    LTSubFunction.console_debug.out("LTFlashSliderPopup::present", root.btnId)

                    root.onOKClicked(root.btnId);
                    root.dismiss();
                }
            }

            LTRectangleButton {
                id: btnCancel

                height: 40
                width: flickable.width/2
                type: "action"
                buttonText: qsTr("Cancel")

                fillColor: palette.backgroundLight

                onClicked: {
                    LTSubFunction.console_debug.out("LTFlashSliderPopup::btnCancel", root.btnId)

                    root.onCancelClicked(root.btnId);
                    root.dismiss();
                }
            }
        }
    }

    /*!
        ポップアップを表示します
     */
    function present(x, y, btnSource, components, btnId) {
        LTSubFunction.console_debug.out("LTFlashSliderPopup::present", btnId)
        popupContent.width = 0;
        popupContent.height = 0;

        source = btnSource;
        root.btnId = btnId;

        for (var i = 0; i < components.length; ++i) {
            //  コンポーネントからオブジェクトを生成して，objects に格納する
            var object = components[i].component.createObject(popupContent, components[i].properties);
            objects.push(object);

            if (object.objectName == "sliderObj") {
                sliderObj = object;
                sliderObj.curIndex = btnSource.value;
                sliderObj.sliderValueChanged(btnSource.value)
            }

            //  ボタンを表示する領域を，生成して配置したオブジェクトにあわせて拡げる
            popupContent.width = Math.max(popupContent.width, object.width);
            popupContent.height += object.height;
        }

        visible = true;
        //
        x -= popup.border.width;
        x = Math.max(x, 0);
        x = Math.min(x, root.width - popup.implicitWidth);
        y -= popup.border.width;
        y = Math.max(y, 0);
        y = Math.min(y, root.height - popup.implicitHeight);
        popup.x = x;
        popup.y = y;
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
        sliderObj = null
        source = null
        btnId = -1
    }

    /*!
        ポップアップに表示する，動的に生成したボタン

        \internal
     */
    property var objects: [ ]

}
