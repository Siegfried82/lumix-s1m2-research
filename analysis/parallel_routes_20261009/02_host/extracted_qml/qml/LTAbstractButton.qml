import QtQuick 2.6
import QtQuick.Controls 2.0
import "LTSubFunction.js" as LTSubFunction

import "qrc:/qml"

/*! \qmltype LTAbstractButton
    \inqmlmodule LT

    \brief
    ボタンに共通する，形状に依存しないインタフェースです

    矩形あるいは円形のボタンに共通するインタフェースを提供します．
    継承して境界線と背景ぬりつぶし (rectangle)，ならびにマウス操作領域 (mouseArea) を定義して使用します．
 */
Item {
    id: root

    /*!
        マウスボタンのクリックをキャンセルされたことを通知します
     */
    signal canceled()

    /*!
        マウスボタンが領域内に入ったことを通知します
     */
    signal entered()

    /*!
        マウスボタンが領域外に移動されたことを通知します
     */
    signal exited()

    /*!
        マウスボタンでクリックされたことを通知します
     */
    signal clicked(var event, var source)

    /*!
        マウスボタンで長押しされたことを通知します
     */
    signal pressAndHold(var event, var source)

    /*!
        マウスボタンで長押し開始されたことを通知します
     */
    signal pressed(var event, var source)

    /*!
        マウスボタンで長押し終了されたことを通知します
     */
    signal released(var containsMouse)

    /*!
        チェック状態 (押し下げられたまま維持している状態) です
     */
    property bool checked: false

    /*!
        マウスカーソルが当たっている場合に光らない
     */
    property bool disabled: false

    /*!
        エラーポップアップ表示、アイコン無効、マウスカーソルが当たっている場合に光らない
     */
    property bool error: false

    /*!
        画像の URL です
     */
    property alias source: image.source
    property alias sourceDsiable: imageDisable.source
    property alias sourceChecked: imageChecked.source

    /*!
        画像の alias です
     */
    property alias mainImg: image
    property alias mainDisableImg: imageDisable
    property alias mainCheckedImg: imageChecked

    /*!
        ツールチップのテキストです
     */
    property alias toolTipText: toolTip.text

    /*!
        初期状態への遷移において，背景色の変化にかける時間です
     */
    property real fadeDurationMilliseconds: 250 // 500  // H.NAKANO

    /*
        境界線と背景ぬりつぶし

        継承した型で定義，実装する必要があります．
     *
    Rectangle {
        id: rectangle
        z: 10
        ...
    }
     */

    /*
        画像
     */
    Image {
        id: image
        z: 20
        anchors {
            centerIn: parent
        }
    }
    Image {
        id: imageDisable
        z: 20
        visible: false
        //anchors.right: image.anchors.right
        //anchors.rightMargin: image.anchors.rightMargin
        //anchors.horizontalCenter: image.anchors.horizontalCenter
        //anchors.verticalCenter: image.anchors.verticalCenter
        height: image.height
        width: image.width
        fillMode: image.fillMode
        x: image.x
        y: image.y
        sourceSize: image.sourceSize
    }
    Image {
        id: imageChecked
        z: 20
        visible: false
        //anchors.right: image.anchors.right
        //anchors.rightMargin: image.anchors.rightMargin
        //anchors.horizontalCenter: image.anchors.horizontalCenter
        //anchors.verticalCenter: image.anchors.verticalCenter
        height: image.height
        width: image.width
        fillMode: image.fillMode
        x: image.x
        y: image.y
        sourceSize: image.sourceSize
    }

    /*
        ツールチップ
     */
    ToolTip {
        id: toolTip
        property int posX: 0//mouseArea.posX
        property int posY: 0//mouseArea.posY
        x: posX//mouseArea.mouseX
        y: posY+20//mouseArea.mouseY + 20
        visible: ((text) && (mouseArea.containsMouse))
        delay: 500
        //font: Qt.font({"pixelSize": 12, "family": utilities.getFontFamily()}) 効いていない
        background: Rectangle {
            color: "white"
        }
        contentItem: Text {
            text: toolTip.text
            font.pixelSize: 12
            font.family: utilities.getFontFamily()
        }

        onVisibleChanged: {
            //LTSubFunction.console_debug.out("tooltip onVisibleChanged")
            posX = mouseArea.mouseX
            posY = mouseArea.mouseY
        }
    }

    /*
        マウス操作領域

        継承した型で定義，実装する必要があります．
     *
    MouseArea {
        id: mouseArea
        ...
    }
     */

    /*!
        境界線の太さです
     */
    property real strokeWidth: 0

    /*!
        境界線の色です
     */
    property color strokeColor: "#292b2d"

    /*!
        初期状態の背景色
     */
    property color fillColor: "#07090d"

    /*!
        マウスホバーされている状態の背景色
     */
    property color hoveredColor: "#434343"

    /*!
        マウスボタンが押されている状態の背景色
     */
    property color pressedColor: "#5c5c5c"

    /*!
        チェック状態の背景色

        アルファ成分が 0 である場合は適用されません
     */
    property color checkedColor

    /*
        状態の定義
     */
    states: [
        //  チェック状態
        State {
            name: "checked"
            when: checked && (checkedColor.a != 0)
            PropertyChanges {
                target: rectangle
                color: checkedColor
            }
        },
        //  マウスボタンが押されている状態
        State {
            name: "pressed"
            when: mouseArea.containsMouse && mouseArea.pressed && !disabled && !error
            PropertyChanges {
                target: rectangle
                color: pressedColor
            }
        },
        //  マウスホバーされている状態
        State {
            name: "hovered"
            when: mouseArea.containsMouse && !disabled && !error
            PropertyChanges {
                target: rectangle
                color: hoveredColor
            }
        },
        //  初期状態
        State {
            PropertyChanges {
                target: rectangle
                color: fillColor
            }
        }
    ]

    /*
        状態遷移によるアニメーションの定義
     */
    transitions: [
        //  初期状態への遷移において，背景色を一定時間かけて変化させる
        Transition {
            to: ""
            ColorAnimation {
                target: rectangle
                duration: fadeDurationMilliseconds
            }
        }
    ]

}
