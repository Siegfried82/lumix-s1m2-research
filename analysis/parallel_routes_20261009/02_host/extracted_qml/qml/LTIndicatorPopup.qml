import QtQuick 2.6
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.0
import QtQuick.Window 2.3

import "qrc:/qml"
import LT 1.0 as LT

/*! \qmltype LTIndicatorPopup
    \inqmlmodule LT

    \brief
    LTOptionButton の状態を選択するポップアップです
 */
Item {
    id: root

    z: parent.z+1
    anchors.fill: parent

    visible: false

    property alias bgColor: maskpanel.color

    property alias bgOpacity: maskpanel.opacity

    property bool maskVisible: false

    property real borderWidth: 0

    property string borderColor: "#c6c6c6"

    /*!
        ボタンを並べて表示する領域の高さの上限です
     */

    Rectangle {
        id: maskpanel
        z: parent.z+1
        anchors {
            fill: parent
        }
        color: "#000000"
        opacity: 0.5

        visible: maskVisible
        border {
            width: borderWidth
            color: borderColor
        }
    }

    /*
        ボタンを並べて表示する領域
     */
    Rectangle {
        id: popup
        anchors.fill: parent
        z: parent.z+2
        color: "transparent"

        BusyIndicator {
            id: indicator
            anchors.centerIn: parent
            z: parent.z+1

            running: root.visible

            background: Rectangle {
                color: "transparent"
            }
        }

    }


    /*!
        ポップアップを表示します
     */
    function present(parent) {
        //console.log("LTIndicatorPopup -- present")

        root.visible = true;
    }

    /*!
        ポップアップを隠します
     */
    function dismiss() {
        root.visible = false;
//        var n = objects.length;
//        for (var i = 0; i < n; ++i) {
//            //  objects に格納されたオブジェクトを取出して破棄する
//            var object = objects.pop();
//            object.destroy();
//        }
    }

    /*!
        ポップアップに表示する，動的に生成したボタン

        \internal
     */
//    property var objects: [ ]

}
