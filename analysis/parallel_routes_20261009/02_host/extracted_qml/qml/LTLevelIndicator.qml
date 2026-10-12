import QtQuick 2.6

import "qrc:/qml"

/*! \qmltype LTLevelIndicator
    \inqmlmodule LT

    \brief
    水準器です
 */
Item {
    id: root

    /*!
        ピッチ角度です
     */
    property real pitchingDegrees: 0
    onPitchingDegreesChanged: {
        canvas.requestPaint();
    }

    /*!
        ロール角度です
     */
    property real rollingDegrees: 0
    onRollingDegreesChanged: {
        canvas.requestPaint();
    }

    function redraw() {
        image.source = "qrc:/images/levelindicator_groove.svg"
    }

    onWidthChanged: {
        canvas.requestPaint();
    }
    onHeightChanged: {
        canvas.requestPaint();
    }

    /*
        (| |) な画像
     */
    Image {
        id: image
        anchors { centerIn: parent }
        source: "qrc:/images/levelindicator_groove.svg"
        width: (root.width)/3
        height: (root.height)/3
        fillMode: Image.PreserveAspectFit
        rotation: (lv_rotation_mode)? 0: (lv_rotation + lv_rotation_auto)
    }

    /*
        傾きを示す線を描画する領域
     */
    Canvas {
        id: canvas
        anchors { fill: parent }
        onPaint: {
            var context = getContext("2d");
            context.clearRect(0, 0, width, height);
            // ivc >> start >> USBTHRV140-32
            //drawLevel();
            // ivc << end << USBTHRV140-32
            drawPitching();
            drawRolling();
        }

        /*
            水平線を描画します
         */
        function drawLevel() {
            var context = getContext("2d");
            context.save();
            context.lineWidth = 2;
            context.strokeStyle = "#ffffff"
            context.translate(width / 2, height / 2);
            context.beginPath();
            if( (lv_rotation_mode == false) && ((lv_rotation + lv_rotation_auto) % 180)) {
                context.moveTo( 0, (-80*(image.paintedWidth))/(400));
                context.lineTo( 0, (-120*(image.paintedWidth))/(400));
                context.moveTo( 0, (80*(image.paintedWidth))/(400));
                context.lineTo( 0, (120*(image.paintedWidth))/(400));
            } else {
                context.moveTo( (-80*(image.paintedWidth))/(400), 0);
                context.lineTo( (-120*(image.paintedWidth))/(400), 0);
                context.moveTo( (80*(image.paintedWidth))/(400), 0);
                context.lineTo( (120*(image.paintedWidth))/(400), 0);
            }
            context.stroke();
            context.restore();
        }

        /*
            ピッチの線を描画します
         */
        function drawPitching() {
            var context = getContext("2d");
            context.save();
            context.lineWidth = 2;
            context.strokeStyle = pitchingDegrees == 0 ? "#00ff00" : "#ffff00"
            // !! 角度から位置を決定する式が不明
            if( (lv_rotation_mode == false) && ((lv_rotation + lv_rotation_auto) % 180)) {
                if(width == height) {
                    context.translate(width / 2 - ((pitchingDegrees*27*root.height)/(40*100)), height / 2);
                } else {
                    context.translate(width / 2 - ((pitchingDegrees*35*root.height)/(40*100)), height / 2);
                }
                context.beginPath();
                context.moveTo( 0, (-80*(image.paintedWidth))/(400));
                context.lineTo( 0, (-120*(image.paintedWidth))/(400));
                context.moveTo( 0, (80*(image.paintedWidth))/(400));
                context.lineTo( 0, (120*(image.paintedWidth))/(400));
            } else {
                if(width == height) {
                    context.translate(width / 2, height / 2 - ((pitchingDegrees*27*root.height))/(40*100));
                } else {
                    context.translate(width / 2, height / 2 - ((pitchingDegrees*35*root.height))/(40*100));
                }
                context.beginPath();
                context.moveTo( (-80*(image.paintedWidth))/(400), 0);
                context.lineTo( (-120*(image.paintedWidth))/(400), 0);
                context.moveTo( (80*(image.paintedWidth))/(400), 0);
                context.lineTo( (120*(image.paintedWidth))/(400), 0);
            }
            context.stroke();
            context.restore();
        }

        /*
            ロールの線を描画します
         */
        function drawRolling() {
            var context = getContext("2d");
            context.save();
            context.lineWidth = 2;
            context.strokeStyle = rollingDegrees == 0 ? "#00ff00" : "#ffff00"
            context.translate(width / 2, height / 2);
            var rollval = rollingDegrees
            if(lv_rotation_mode == false) {
                rollval += (lv_rotation + lv_rotation_auto)
            }
            context.rotate(rollval / 180 * Math.PI);
            context.beginPath();
            context.moveTo(-160, 0);
            context.lineTo(-999, 0);
            context.moveTo(+160, 0);
            context.lineTo(+999, 0);
            context.moveTo( (-160*(image.paintedWidth))/(400), 0);
            context.lineTo( (-999*(image.paintedWidth))/(400), 0);
            context.moveTo( (160*(image.paintedWidth))/(400), 0);
            context.lineTo( (999*(image.paintedWidth))/(400), 0);
            context.stroke();
            context.restore();
        }
    }

    clip: true;

}
