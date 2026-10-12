//ndtri - add - LTFlashThreeButton
import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.1

import "qrc:/qml"

/*! \qmltype TLFlashThreeButton
    \inqmlmodule LT

    \brief
    矩形のボタン
 */
Item {
    id: root

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
        ラベルのテキストです
     */
    property alias label3BText: label_three_button.text

    /*!
        フォントの属性です
     */
    property var font: {
        return {
            "pixelSize": 14,
            "weight": Font.Normal
        };
    }
    onFontChanged: {
        //label.font = Qt.font(font);
        label_three_button.font = Qt.font(font);
    }

    /*!
        テキストの色です
     */
    property color textColor: "#808080"

    /*!
       Top and bottom padding (also label height)
     */
    property real labelHeight: 22
    /*!
       Button height
     */
    property real btnHeight: 55
    /*!
       Button width
     */
    property real btnWidth: 107

    /*!
       Button events
     */
    signal btn1Clicked(var event, var source)

    signal btn2Clicked(var event, var source)

    signal btn3Clicked(var event, var source)

    signal btn1PressAndHold(var event, var source)

    signal btn2PressAndHold(var event, var source)

    signal btn3PressAndHold(var event, var source)

    /*!
       Button padding
     */
    property real btnPadding: 1

    /*!
       Button access point
     */

    property alias btn1: btn1

    property alias btn2: btn2

    property alias btn3: btn3

    Rectangle{
        anchors {
            fill: parent
        }
        color: fillColor
    }

    Column {
        anchors {
            fill: parent
        }

        Item {
            anchors {
                left: parent.left
                right: parent.right
            }
            height: labelHeight

            LTStylishText {
                id: label_three_button
                x: 6
                y: 0
                z: 30

                type:text_style_threeButton
                width: root.width
                height: labelHeight
            }
        }

        Item {
            anchors {
                left: parent.left
                right: parent.right
            }
            height: btnHeight

            Rectangle {
                anchors {
                    fill: parent
                }
                color: fillColor
            }

            Row {
                anchors {
                    fill: parent
                }

                LTOptionFlashTreeButton{
                    id:btn1
                    width: btnWidth
                    height:btnHeight

                    fillColor: fillColor

                    onClicked:(event)=>{ root.btn1Clicked(event, root) }
                    onPressAndHold:(event)=>{ root.btn1PressAndHold(event, root) }
                }

                Rectangle {
                    anchors {
                        verticalCenter: parent.verticalCenter
                    }
                    width: btnPadding
                    height:btnHeight *2/3

                    color: strokeColor
                }

                LTRectangleButton {
                    id:btn2
                    width: btnWidth
                    height:btnHeight

                    fillColor: fillColor

                    property int button_id: 0

                    onClicked:(event)=>{ root.btn2Clicked(event, root) }
                    onPressAndHold:(event)=>{ root.btn2PressAndHold(event, root) }
                }

                Rectangle {
                    anchors {
                        verticalCenter: parent.verticalCenter
                    }
                    width: btnPadding
                    height:btnHeight *2/3

                    color: strokeColor
                }

                LTRectangleButton {
                    id:btn3
                    width: btnWidth
                    height:btnHeight

                    fillColor: fillColor

                    property int button_id: 0

                    onClicked:(event)=>{ root.btn3Clicked(event, root) }
                    onPressAndHold:(event)=>{ root.btn3PressAndHold(event, root) }
                }
            }
        }
    }
}
