import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0
import QtQuick.Window 2.3

import "qrc:/qml"

/*! \qmltype LTCCPopup
    \inqmlmodule LT

    \brief
    LTOptionButton の状態を選択するポップアップです
 */
Window {
    id: root

    flags:
        Qt.Window
      | Qt.FramelessWindowHint

    modality: Qt.ApplicationModal

    //Windowサイズを変更できなくする
    minimumWidth: popup.width
    minimumHeight: popup.height
    maximumWidth: popup.width
    maximumHeight: popup.height

    visible: false

    readonly property int columnNum: 5

    /*!
        ボタンを並べて表示する領域の高さの上限です
     */
    property real maximumPopupHeight: 200

    /*
        背景

        ボタンを表示する領域の外部全体を暗くして，マウス操作に反応しないようにします．
        また，クリックされると選択パネルを閉じます．
     */
    Rectangle {
        id: backGround
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
        y: headerItem.height
        implicitWidth: flickable.width// + border.width * 2
        implicitHeight: flickable.height// + border.width * 2
        color: "#000000"
//        border {
//            width: 2
//            color: "#c6c6c6"
//        }
        Flickable {
            id: flickable
            x: 0//popup.border.width
            y: 0//popup.border.width
            implicitWidth: popupContent.width + (ScrollBar.vertical.visible ? ScrollBar.vertical.width : 0)
            implicitHeight: Math.min(popupContent.height, maximumPopupHeight)
            contentHeight: popupContent.height
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            GridLayout {
                //  QtQuick モジュールの Column でも同様のことは実現できるが，生成から表示するあたりの制御が異なるらしく，
                //  状態を明示せずに生成した LTAbstractButton の状態が (配置された位置にかかわらず) "hoverred" になって
                //  しまう
                id: popupContent
                columns: root.columnNum
                columnSpacing: 0
                rowSpacing: 0
            }
            ScrollBar.vertical: LTScrollBar {
                visible: flickable.height < flickable.contentHeight
            }
        }
    }
    Item {
        id: headerItem
        visible: true
        anchors {
            left: backGround.left
            right: backGround.right
            top: backGround.top
        }
        height: 36

        /*
            背景
         */
        Rectangle {
            anchors {
                fill: headerItem
            }
            color: palette.backgroundDark;
        }

        /*
            ラベル
         */
        LTStylishText {
            id: selectLabel
            width: headerItem.width
            height: headerItem.height
            visible: true
            color: "#FFFFFF"
            type: text_style_normal
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment : Text.AlignHCenter
        }
    }

    Item {
        id: footerItem
        visible: true
        anchors {
            left: backGround.left
            right: backGround.right
            bottom: backGround.bottom
        }
        height: 36

        /*
            背景
         */
        Rectangle {
            anchors {
                fill: parent
            }
            color: palette.backgroundDark;
        }

        /*
            決定
         */
        LTRectangleButton {
            id: okButton
            x: 2 // footerItem.width / 2 + 1
            y: 2 // cancelButton.y
            width: footerItem.width / 2 - 3
            height: footerItem.height - 4
            buttonText: qsTr("OK")
            fillColor: palette.backgroundLight
            visible: true

            onClicked: {
                var n = objects.length;
                for (var i = 0; i < n; ++i) {
                    //  objects に格納されたオブジェクトを取出して破棄する
                    var object = objects[i];
                    if(object.optionText == selectLabel.text) {
                        var op_source = object.optionSource
                        object.optionSource = object.source;
                        object.source = op_source;
                        selectedFunction(object);
                        break;
                    }
                }
            }
        }

        /*
            キャンセル
         */
        LTRectangleButton {
            id: cancelButton
            x: footerItem.width / 2 + 1 // 2
            y: okButton.y // 2
            width: footerItem.width / 2 - 3
            height: footerItem.height - 4
            visible: true
            buttonText: qsTr("Cancel")
            fillColor: palette.backgroundLight

            onClicked: {
                root.dismiss()
            }
        }
    }

    function cancel() {

    }

    /*!
        ポップアップを表示します
     */
    function present(pos_x, pos_y, title, components, target, onSelected) {
        popupContent.width = 0;
        popupContent.height = 0;
        var x_size = 0;
        var y_size = 0;
        selectedFunction = onSelected
        for (var i = 0; i < components.length; ++i) {
            //  使用可能でなければ，オブジェクトの生成をスキップする
            if (!components[i].properties.capable) {
                continue;
            }
            //  コンポーネントからオブジェクトを生成して，objects に格納する
            var object = components[i].component.createObject(popupContent, components[i].properties);
            objects.push(object);
            if(object.checked == true) {
                selectLabel.text = object.optionText;
            }
            object.optionSource = object.source;
            object.source = components[i].properties.optionSource;
            object.optionTextTooltip = object.optionText;
            //  生成したオブジェクトが clicked シグナルを発行できる場合，シグナルハンドラを設定する
            if (object.clicked) {
                object.clicked.connect(function (event, source) {
                    //onSelected(source);
                    //console.log("source.optionText " + source.optionText);
                    selectLabel.text = source.optionText;
                    //console.log("objects.length " + objects.length);
                    var n = objects.length;
                    for (var i = 0; i < n; ++i) {
                        //  objects に格納されたオブジェクトを取出して破棄する
                        var object1 = objects[i];
                        //console.log("objects.length " + object1.optionText);
                        object1.checked = false
                    }
                    source.checked = true
                });
            }
            //  ボタンを表示する領域を，生成して配置したオブジェクトにあわせて拡げる
            x_size = Math.max(x_size, object.width);
            y_size = Math.max(y_size, object.height);
        }
        //  ボタンを表示する領域を，生成して配置したオブジェクトにあわせて拡げる
        popupContent.width = x_size * root.columnNum;
        popupContent.height = y_size * (Math.round(objects.length / root.columnNum) + ((objects.length % root.columnNum)? 1:0));
        visible = true;
        root.x = Math.round((Screen.width - popupContent.width) / 2)
        root.y = Math.round((Screen.height - popupContent.height) / 2)
        root.width = popupContent.width + 10//(ScrollBar.vertical.visible ? ScrollBar.vertical.width : 0)
        root.height = Math.min(maximumPopupHeight, popupContent.height) + headerItem.height + footerItem.height
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
    property var selectedFunction
}
