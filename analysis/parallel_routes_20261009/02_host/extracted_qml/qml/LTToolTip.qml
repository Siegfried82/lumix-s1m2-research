import QtQuick 2.15
import QtQml 2.2
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.1

import "qrc:/qml"
import LT 1.0 as LT

Item {
    id: root

    /*!
        ツールチップのテキストです
     */
    property alias toolTipText: toolTip.text

    property alias toolTipVisible: toolTip.visible

    property bool toolTipMouseContains: false

    /*
        ツールチップ
     */
    ToolTip {
        id: toolTip
        property int posX: 0
        property int posY: 0
        x: posX
        y: posY+40
        visible: ((text) && (toolTipMouseContains)) //false
        delay: 500
        background: Rectangle {
            color: "white"
        }
        contentItem: Text {
            text: toolTip.text
            font.pixelSize: 12
            font.family: utilities.getFontFamily()
        }
    }
}
