import QtQuick 2.6

import LT 1.0 as LT
import "qrc:/qml"
import "LTSubFunction.js" as LTSubFunction


/*! \qmltype LTLiveViewComposite
    \inqmlmodule LT

    \brief
    ライブビューコンポジット
 */
Item {
    id: root
    z: 999

    property alias loadingRotation: loadingImg.rotation
    property int lastPositionY: 0
    property var previousShootingStatus
    property bool isShowMessage: false
    property int img_number: 0
    //Windowサイズ変えたりするとメッセージの表示/非表示が繰り返されるので一度表示したことがあるかフラグで判断する
    property bool firstMessage: false

    property int centerFontSize: 30
    property int topFontSize: 26

    LTOptionComponentsProvider {
        id: componentsProvider
    }
    /*
        Message in center
     */
    Text {
        id: messageCenter
        x: (root.width) / 2
        y: (root.height) / 2
        width: (root.width) / 2
        height: (root.height) / 2
        font: Qt.font({
                          pixelSize: centerFontSize,
                          family: utilities.getFontFamily()
                      })
        visible: false
    }

    /*
        Message on Top
     */
    Text {
        id: messageTop
        x: root.width - (root.width / 4 + 30)
        y: 27
        width: root.width / 4 + 30
        height: 20
        font: Qt.font({
                          pixelSize: topFontSize,
                          family: utilities.getFontFamily()
                      })
        visible: false
    }

    /*
        Loading image
     */
    Image {
        id: loadingImg
        x: (root.width) / 2 - 30
        y: (root.height) / 2 + 50
        z: 999
        source: "qrc:/images/wait_anim0_gray.svg"
        visible: false
        width: 60
        height: 60
        fillMode: Image.PreserveAspectFit
        rotation: 0
    }

    /*
        Time counter
     */
    Timer {
        id: time
        interval: 999
        running: false
        repeat: true

        onTriggered: {
            switch (deviceAdapter.lvShootingStatus) {
            case LT.Utilities.LCST_PREPARE:
                if (deviceAdapter.cameraStatus == LT.Utilities.CamStatus_Noise_Reduction) {
                    deviceAdapter.adp_LMX_func_api_Get_NoiseReduction_RemainingTime()
                } else {
                    isShowMessage = false
                    // IVC >> Ver.1.8 >> start >> USBTHRV180-19
                    deviceAdapter.lvcShowLvControlItem = true;
                    // IVC << Ver.1.8 << end << USBTHRV180-19
                }
                clearScreen(true)
                running = false
                break
            }

            canvas.requestPaint()
        }
    }

    /*
        Area to draw message
     */
    Canvas {
        id: canvas
        anchors {
            fill: parent
        }
        onPaint: {
            var messages = ""
            // Clear screen
            clearScreen(true)

            if (isShowMessage == false) {
                time.running = false
                root.visible = false
                return
            }

            switch (deviceAdapter.lvShootingStatus) {
            case LT.Utilities.LCST_PREPARE:
                // 撮影準備 → [Message-1]
                if (deviceAdapter.cameraStatus != LT.Utilities.CamStatus_Noise_Reduction) {
                    messages = qsTr("Message-1").split('<br />')
                    canvas.drawTextInCenter(true, messages)

                    // [Message-1] の表示時間は、最大5秒
                    if (time.running == false && firstMessage === false) {
                        time.interval = 5000
                        time.running = true
                        firstMessage = true
                    }
                } else {
                    if (time.running == false) {
                        time.interval = 100
                        time.running = true
                    }
                    messages = qsTr("Message-2-1").split('<br />')
    // IVC >> Ver.1.8 >> start >> USBTHRV180-19
                    //canvas.drawTextInCenter(false, messages)
                    canvas.drawTextWithFullBackground(messages)
    // IVC << Ver.1.8 << end << USBTHRV180-19

                    drawTextAtPosition(
                                deviceAdapter.nrRemainingTime,
                                messageCenter.x - (deviceAdapter.nrRemainingTime > 9 ? 30 : 15),
                                lastPositionY)
                }
                // IVC >> Ver.1.8 >> start >> USBTHRV180-19
                deviceAdapter.lvcShowLvControlItem = false;
                // IVC << Ver.1.8 << end << USBTHRV180-19
                break
            case LT.Utilities.LCST_STANDBY:
                // 撮影待機 → [Message-2-2] & [Message-2-3]
                if (time.running == false && firstMessage === false) {
                    messages = qsTr("Message-2-2").split('<br />')
                    canvas.drawTextInCenter(true, messages)

                    // [Message-2-2] の表示時間は、最大5秒
                    if (time.running == false) {
                        time.interval = 5000
                        time.running = true
                        firstMessage = true
                // IVC >> Ver.1.8 >> start >> USBTHRV180-19
                        deviceAdapter.lvcShowLvControlItem = false;
                // IVC << Ver.1.8 << end << USBTHRV180-19
                    }
                } else {
                    var message_2_3 = '**1 x 0'
                    messages = message_2_3.replace(
                                '**1', makeShutterSpeedText(deviceAdapter.shutterSpeed))
                    canvas.drawTextOnTop(messages)

                    if (time.running == true) {
                        time.running = false
                // IVC >> Ver.1.8 >> start >> USBTHRV180-19
                        deviceAdapter.lvcShowLvControlItem = true;
                // IVC << Ver.1.8 << end << USBTHRV180-19
                    }
                }

                break
            case LT.Utilities.LCST_SHOOTING:
                // 撮影中 → [Message-3]
                var remain_time = deviceAdapter.lv_composite_shooting_information_remaining_time()
                var number_shots = deviceAdapter.lv_composite_shooting_information_number_completed_shots()
                var elapsed = deviceAdapter.lv_composite_shooting_information_elapsed_shoot_time()

                var minutes = parseInt(elapsed / 60)
                var seconds = elapsed - minutes * 60
                if (minutes > 0 && minutes < 10) {
                    minutes = "0" + minutes
                }
                else if (minutes === 0) {
                    minutes = "00"
                }
                if (seconds < 10) {
                    seconds = "0" + seconds
                }

                var message_3 = '**1"    **2x**3    **4'
                messages = message_3.replace(
                            '**1', remain_time).replace(
                            '**2', makeShutterSpeedText(deviceAdapter.shutterSpeed)).replace(
                            '**3', number_shots).replace(
                            '**4', minutes + ':' + seconds)

                canvas.drawTextOnTop(messages)

                // Loop
                if (time.running == false) {
                    time.interval = 100
                    time.running = true
                // IVC >> Ver.1.8 >> start >> USBTHRV180-19
                    deviceAdapter.lvcShowLvControlItem = true;
                // IVC << Ver.1.8 << end << USBTHRV180-19
                }
                break
            case LT.Utilities.LCST_COMBINING:
                // 合成中 → [Message-4]
                messages = qsTr("Message-4").split('<br />')
                // IVC >> Ver.1.8 >> start >> USBTHRV180-19
                //canvas.drawTextInCenter(false, messages)
                canvas.drawTextWithFullBackground(messages)
                // IVC << Ver.1.8 << end << USBTHRV180-19

                var img_name = "wait_anim**1_gray.svg"
                loadingImg.source = "qrc:/images/" + img_name.replace('**1', img_number++)
                if (img_number >= 30)
                    img_number = 0
                if (time.running == false) {
                    time.interval = 30
                    time.running = true
                    loadingImg.visible = true
                // IVC >> Ver.1.8 >> start >> USBTHRV180-19
                    deviceAdapter.lvcShowLvControlItem = false;
                // IVC << Ver.1.8 << end << USBTHRV180-19
                }
                break
            default:
                time.running = false
                root.visible = false
                // IVC >> Ver.1.8 >> start >> USBTHRV180-19
                deviceAdapter.lvcShowLvControlItem = true;
                // IVC << Ver.1.8 << end << USBTHRV180-19
            }
        }

        /*
            Draw text in center with background
         */
        function drawTextInCenter(isUseBackground, messages) {
            // get context to draw with
            var context = getContext("2d")
            context.save()
            var maxLen = 0
            var i
            for (i = 0; i < messages.length; i++) {
                if (maxLen < messages[i].length) {
                    maxLen = messages[i].length
                    messageCenter.text = messages[i]
                }
            }

            // render background
            if (isUseBackground) {
                // setup the stroke
                // IVC >> Ver.1.8 >> start >> USBTHRV180-19
                context.lineWidth = 2
                context.strokeStyle = "#ffffff"
                // setup the fill
                context.fillStyle = "rgba(7,9,13,0.5)"
                // IVC << Ver.1.8 << end << USBTHRV180-19
                // begin a new path to draw
                context.beginPath()
                // top-left start point
                context.moveTo(
                            messageCenter.x - (messageCenter.paintedWidth / 2 + 20),
                            messageCenter.y - ((messages.length * 30) / 2 + 25))
                // upper line
                context.lineTo(
                            messageCenter.x + (messageCenter.paintedWidth / 2 + 20),
                            messageCenter.y - ((messages.length * 30) / 2 + 25))
                // right line
                context.lineTo(
                            messageCenter.x + (messageCenter.paintedWidth / 2 + 20),
                            messageCenter.y + ((messages.length * 30) / 2 + 10))
                // bottom line
                context.lineTo(
                            messageCenter.x - (messageCenter.paintedWidth / 2 + 20),
                            messageCenter.y + ((messages.length * 30) / 2 + 10))
                // left line through path closing
                context.closePath()
                // fill using fill style
                context.fill()
                // stroke using line width and stroke style
                context.stroke()
                context.restore()
            }

            // render text
//            context.font = '30px Tahoma'
            context.font = centerFontSize.toString() + 'px '+'"'+utilities.getFontFamily()+'"'
            context.fillStyle = "#ffffff"
            for (i = 0; i < messages.length; i++) {
                context.fillText(
                            messages[i],
                            messageCenter.x - messageCenter.paintedWidth / 2,
                            messageCenter.y - (messages.length * 30) / 2 + i * 30 + 15)
            }
            lastPositionY = messageCenter.y - (messages.length * 30) / 2 + (i + 1) * 30 + 20
        }


// IVC >> Ver.1.8 >> start >> USBTHRV180-19
        /*
            Draw text in center with background
         */
        function drawTextWithFullBackground(messages) {
            // get context to draw with
            var context = getContext("2d")
            context.save()
            var maxLen = 0
            var i
            for (i = 0; i < messages.length; i++) {
                if (maxLen < messages[i].length) {
                    maxLen = messages[i].length
                    messageCenter.text = messages[i]
                }
            }

            // render background
            // setup the stroke
            //context.lineWidth = 0
            //context.strokeStyle = "#a6a6a6"
            // setup the fill
            context.fillStyle = "#000000"
            // begin a new path to draw
            context.beginPath()
            // top-left start point
            context.moveTo(
                        0,
                        0)
            // upper line
            context.lineTo(
                        root.width,
                        0)
            // right line
            context.lineTo(
                        root.width,
                        root.height)
            // bottom line
            context.lineTo(
                        0,
                        root.height)
            // left line through path closing
            context.closePath()
            // fill using fill style
            context.fill()
            // stroke using line width and stroke style
            context.stroke()
            context.restore()

            // render text
//            context.font = '30px Tahoma'
            context.font = centerFontSize.toString() + 'px '+'"'+utilities.getFontFamily()+'"'
            context.fillStyle = "#ffffff"
            for (i = 0; i < messages.length; i++) {
                context.fillText(
                            messages[i],
                            messageCenter.x - messageCenter.paintedWidth / 2,
                            messageCenter.y - (messages.length * 30) / 2 + i * 30 + 15)
            }
            lastPositionY = messageCenter.y - (messages.length * 30) / 2 + (i + 1) * 30 + 20
        }
// IVC << Ver.1.8 << end << USBTHRV180-19

        /*
            Draw text at specific position
         */
        function drawTextAtPosition(messages, posX, posY) {
            // get context to draw with
            var context = getContext("2d")
            context.save()

            // render text
//            context.font = 'bold 48px Tahoma'
            context.font = 'bold 48px '+'"'+utilities.getFontFamily()+'"'
            context.fillStyle = "#ffffff"
            context.fillText(messages, posX, posY)
        }

        /*
            Draw text on Top
         */
        function drawTextOnTop(message) {
            // get context to draw with
            var context = getContext("2d")
            context.clearRect(0, 0, root.width, 20)
            context.save()

            messageTop.text = message

// IVC >> Ver.1.8 >> start >> USBTHRV180-19
            // render background
            // setup the stroke
            context.lineWidth = 1
            context.strokeStyle = "rgba(7,9,13,0.5)"
            // setup the fill
            context.fillStyle = "rgba(7,9,13,0.5)"
            // begin a new path to draw
            context.beginPath()
            // top-left start point
            context.moveTo(
                        messageTop.x - messageTop.paintedWidth / 2 -10,
                        0)
            // upper line
            context.lineTo(
                        root.width,
                        0)
            // right line
            context.lineTo(
                        root.width,
                        35)
            // bottom line
            context.lineTo(
                        messageTop.x - messageTop.paintedWidth / 2 -10,
                        35)
            // left line through path closing
            context.closePath()
            // fill using fill style
            context.fill()
            // stroke using line width and stroke style
            context.stroke()
            context.restore()
// IVC << Ver.1.8 << end << USBTHRV180-19

            // render text
//            context.font = '26px Tahoma'
            context.font = topFontSize.toString() + 'px '+'"'+utilities.getFontFamily()+'"'
            context.fillStyle = "#ffffff"
            context.fillText(message,
                             messageTop.x - messageTop.paintedWidth / 2,
                             messageTop.y)
        }
    }

    onWidthChanged: {
        if(root.width < 500){
            centerFontSize = 20
            topFontSize = 18
        }else{
            centerFontSize = 30
            topFontSize = 26
        }
    }

    function init() {
        isShowMessage = true
        loadingImg.visible = false
        time.running = false
        img_number = 0
        // IVC >> Ver.1.8 >> start >> USBTHRV180-19
        if (root.visible == false
                && deviceAdapter.lvShootingStatus != LT.Utilities.LCST_Unknown
                && (!deviceAdapter.isMultiviewMode)
                ) {
            root.visible = true
        }
        // IVC << Ver.1.8 << end << USBTHRV180-19
        canvas.requestPaint();
    }

    function clearScreen(clearAll) {
        var context = canvas.getContext("2d")
        if (context) {
            if (clearAll == true) {
                context.clearRect(0, 0, root.width, root.height)
            } else {
                context.clearRect(0, messageTop.y, root.width,
                                  root.height - messageTop.y)
            }
        }

    }

    function shootingStatusChanged() {
        isShowMessage = true
        loadingImg.visible = false
        time.running = false
        firstMessage = false
        if (root.visible == false
                && deviceAdapter.lvShootingStatus != LT.Utilities.LCST_Unknown
                && (!deviceAdapter.isMultiviewMode)
                ) {
            root.visible = true
        }

        canvas.requestPaint()
    }

    function makeShutterSpeedText(value) {
        var components = componentsProvider["shutterSpeed"]

        for (var i = 0; i < components.length; i++) {
            if ( components[i].properties.value == value ) {
                return components[i].properties.optionText.replace(/<b><big>/g, '')
            }
        }

        return "";
    }

    clip: true
}
