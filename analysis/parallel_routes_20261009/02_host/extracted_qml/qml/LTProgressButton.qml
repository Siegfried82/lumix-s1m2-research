import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Controls.Basic

import "qrc:/qml"
import LT 1.0 as LT

/*! \qmltype LTRectangleButton
    \inqmlmodule LT

    \brief
    矩形のボタンです
 */
Button {
    id: root

    height: 26
    contentItem: Text {
        renderType: Text.NativeRendering
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        font.family: utilities.getFontFamily()
        font.pixelSize: 13
        text: root.text
        leftPadding: 4
        rightPadding: 4
    }
    background: Rectangle {         // 2024/10 Qt6.5_障害一覧-41 Button QML Type のボタンのスタイルを設定
        antialiasing: true
        radius: 3
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#FFFFFF"; }
            GradientStop { position: 1.0; color: "#E4E4E4"; }
        }
        border.color: "#999999"
        border.width: 1
    }
}
