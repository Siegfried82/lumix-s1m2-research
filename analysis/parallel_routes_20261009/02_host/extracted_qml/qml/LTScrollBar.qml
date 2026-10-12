import QtQuick 2.6
import QtQuick.Templates 2.0

import "qrc:/qml"

/*! \qmltype LTScrollBar
    \inqmlmodule LT

    \brief
    スクロールバーです

    See: ScrollBar QML type (QtQuick.Controls 2.x)
 */
ScrollBar {
    id: root

    implicitWidth: Math.max(background ? background.implicitWidth : 0,
                            contentItem.implicitWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(background ? background.implicitHeight : 0,
                             contentItem.implicitHeight + topPadding + bottomPadding)
    padding: 2

    /*
        溝
     */
    Rectangle {
        anchors {
            centerIn: parent
        }
        z: contentItem.z - 1
        width: orientation == Qt.Vertical ? 2 : parent.width - 4
        height: orientation == Qt.Vertical ? parent.height - 4 : 2
        color: "#5c5c5c"
    }

    /*
        ハンドル
     */
    contentItem: Rectangle {
        implicitWidth: 4
        implicitHeight: 4
        color: "#ffbf1f"
        radius: width / 2
    }

}
