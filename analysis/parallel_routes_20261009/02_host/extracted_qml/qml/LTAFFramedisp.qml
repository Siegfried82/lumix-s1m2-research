import QtQuick 2.6
import QtQuick.Controls 2.0

import "qrc:/qml"

/*! \qmltype LTAbstractButton
    \inqmlmodule LT

    \brief
    ボタンに共通する，形状に依存しないインタフェースです

    矩形あるいは円形のボタンに共通するインタフェースを提供します．
    継承して境界線と背景ぬりつぶし (rectangle)，ならびにマウス操作領域 (mouseArea) を定義して使用します．
 */
Item {
    Canvas{
        id: afFrame_pos_icon_canvas
        width: 40
        height: 40
        anchors.leftMargin: 0
        anchors.topMargin: 0
        /*縦線６本*/
        Rectangle {x: 3  ; y: 3 ; width: 1;height: 13;visible: true;color: "Green"}
        Rectangle {x: 3  ; y: 25; width: 1;height: 13;visible: true;color: "Green"}
        Rectangle {x: 37 ; y: 3 ; width: 1;height: 13;visible: true;color: "Green"}
        Rectangle {x: 37 ; y: 25; width: 1;height: 13;visible: true;color: "Green"}
        Rectangle {x: 20 ; y: 0 ; width: 1;height: 6;visible: true;color:  "Green"}
        Rectangle {x: 20 ; y: 34; width: 1;height: 6;visible: true;color:  "Green"}
        /*横線６本*/
        Rectangle {x: 3  ; y: 3 ; width: 13;height: 1;visible: true;color: "Green"}
        Rectangle {x: 25 ; y: 3 ; width: 13;height: 1;visible: true;color: "Green"}
        Rectangle {x: 3  ; y: 37; width: 13;height: 1;visible: true;color: "Green"}
        Rectangle {x: 25 ; y: 37; width: 13;height: 1;visible: true;color: "Green"}
        Rectangle {x: 0  ; y: 20; width:  6;height: 1;visible: true;color: "Green"}
        Rectangle {x: 34 ; y: 20; width:  6;height: 1;visible: true;color: "Green"}
    }

}
