import QtQuick 2.6
import LT 1.0 as LT

import "qrc:/qml"
import "LTSubFunction.js" as LTSubFunction

/*! \qmltype LTHistogram
    \inqmlmodule LT

    \brief
    ヒストグラムです
    使用者側で256個の高さhist01～hist128に0から127までの値を入力してください。
    元のデータ数が64個の場合は同じ値を２個ずつセットしてください。


 */



Item {
    // IVC >> Ver.1.7 >> start >> No.1
    property double aspect: image.sourceSize.width / image.sourceSize.height
    // IVC << Ver.1.7 << end << No.1
    width: 192
    height: 130

    onVisibleChanged: {
        imageTimer.running = true
    }

    Rectangle {
        id: rectangle
        anchors {
            fill: parent
        }
        color: "#1e1e1e"
        border {
            width: 1
            color: "#2b2b2b"
        }

        /*
            画像
         */
        Image {
            id: image
            anchors {
                centerIn: parent
            }
            width: parent.width
            height: parent.height
            fillMode: Image.PreserveAspectFit
            source: "image://histgramCapture/black"
        }
        Timer {
            id: imageTimer
            property int cnt: 0
            interval: 10
            running: false
            repeat: true
            onTriggered:  {
                //LTSubFunction.console_debug.out("onTriggered")
                if(videoImageInfo.videoImageStatus == LT.VideoImageInfo.VIS_Start) {
                    //LTSubFunction.console_debug.out("VIS_Start")
                    if(videoImageInfo.videoImageError == LT.VideoImageInfo.VIE_NoError) {
                        //LTSubFunction.console_debug.out("VIE_NoError")
                        imageTimer.interval = 10
                        image.source = "image://histgramCapture/" + cnt;
                        ++cnt;
                    } else if(videoImageInfo.videoImageError == LT.VideoImageInfo.VIE_Busy) {
                        //videoImageInfo.videoImageError = LT.VideoImageInfo.VIE_NoError
                        imageTimer.interval = 15
                    } else {
                        imageTimer.running = false
                        //videoImageInfo.videoImageStatus = LT.VideoImageInfo.VIS_Stop
                        //videoImageInfo.stopVideoImage();
                        //videoImageInfo.videoImageError = LT.VideoImageInfo.VIE_NoError
                        image.source = "image://histgramCapture/black"
                    }
                }
            }
        }
    }
}
