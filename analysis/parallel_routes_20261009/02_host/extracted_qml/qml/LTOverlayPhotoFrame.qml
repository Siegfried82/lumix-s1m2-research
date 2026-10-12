import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0
import QtQuick.Window 2.3

import "qrc:/qml"
import LT 1.0 as LT
import "LTSubFunction.js" as LTSubFunction

/*! \qmltype LTOverlayPhotoFrame
    \inqmlmodule LT

    \brief
    OverlayPhoto の状態を選択するポップアップです
 */

Rectangle {
    id: selComp
    property int liveViewWidth: 0
    property int liveViewHeight: 0
    property int rulersSize: 12
    property int view: 900
    property alias mousescale01: mouscale1
    property alias mousescale02: mousescale2
    property alias mousescale03: mousescale3
    property alias mousescale04: mousescale4
    property alias dragAreaphoto1: dragAreaphoto
    property alias cornerTopLeft1: cornerTopLeft
    property alias cornerTopRight1: cornerTopRight
    property alias cornerBotLeft1: cornerBottomLeft
    property alias cornerBotRight1: cornerBottomRight
    property alias rotaimage1: rotateimg
    property alias overlayImagealias: overlayImage
    property alias mourorate1: mourorate

    scale: lvOverlayPhotoScaling/lvOverlayPhotoScalingDefault
    visible: false
    rotation: lvOverlayPhotoRotation
    smooth: true
    antialiasing: true
    LTOverlayPhotoPopup{
        id:lTOverlayPhotoPopup
    }

    function updateX() {
        if(lv_rotation == 0) {
            if((lvOverlayPhotoPosX + (selComp.x - lvOverlayPhotoFrameOldPosX)) != lvOverlayPhotoPosX) {
                lvOverlayPhotoPosX += (selComp.x - lvOverlayPhotoFrameOldPosX)
                // ivc >> start >> USBTHRV140-35
//                lvOverlayPhotoPopupAlias.sliderPosXalias.value = lvOverlayPhotoPosX / calcuratio()
//                lvOverlayPhotoSliderOldPosX = lvOverlayPhotoPopupAlias.sliderPosXalias.value
                lvOverlayPhotoPopupAlias.spinBoxPosXalias.value = lvOverlayPhotoPosX / calcuratio() * 10   // Qt 6から 小数点抜きの 値で処理を行っているので
                lvOverlayPhotoSpinBoxOldPosX = lvOverlayPhotoPopupAlias.spinBoxPosXalias.value
                // ivc << end << USBTHRV140-35
            }
            lvOverlayPhotoFrameOldPosX = selComp.x
        } else if(lv_rotation == 270) {
            if((lvOverlayPhotoPosX - (selComp.y - lvOverlayPhotoFrameOldPosY)) != lvOverlayPhotoPosX) {
                lvOverlayPhotoPosX -= (selComp.y - lvOverlayPhotoFrameOldPosY)
                // ivc >> start >> USBTHRV140-35
//                lvOverlayPhotoPopupAlias.sliderPosXalias.value = lvOverlayPhotoPosX / calcuratio()
//                lvOverlayPhotoSliderOldPosX = lvOverlayPhotoPopupAlias.sliderPosXalias.value
                lvOverlayPhotoPopupAlias.spinBoxPosXalias.value = lvOverlayPhotoPosX / calcuratio() * 10
                lvOverlayPhotoSpinBoxOldPosX = lvOverlayPhotoPopupAlias.spinBoxPosXalias.value
                // ivc << end << USBTHRV140-35
            }
            lvOverlayPhotoFrameOldPosY = selComp.y
        } else if(lv_rotation == 180) {
            if((lvOverlayPhotoPosX -(selComp.x - lvOverlayPhotoFrameOldPosX)) != lvOverlayPhotoPosX) {
                lvOverlayPhotoPosX -= (selComp.x - lvOverlayPhotoFrameOldPosX)
                // ivc >> start >> USBTHRV140-35
//                lvOverlayPhotoPopupAlias.sliderPosXalias.value = lvOverlayPhotoPosX / calcuratio()
//                lvOverlayPhotoSliderOldPosX = lvOverlayPhotoPopupAlias.sliderPosXalias.value
                lvOverlayPhotoPopupAlias.spinBoxPosXalias.value = lvOverlayPhotoPosX / calcuratio() * 10
                lvOverlayPhotoSpinBoxOldPosX = lvOverlayPhotoPopupAlias.spinBoxPosXalias.value
                // ivc << end << USBTHRV140-35
            }
            lvOverlayPhotoFrameOldPosX = selComp.x
        } else if(lv_rotation==90) {
            if((lvOverlayPhotoPosX + (selComp.y - lvOverlayPhotoFrameOldPosY)) != lvOverlayPhotoPosX) {
                lvOverlayPhotoPosX += (selComp.y-lvOverlayPhotoFrameOldPosY)
                // ivc >> start >> USBTHRV140-35
//                lvOverlayPhotoPopupAlias.sliderPosXalias.value = lvOverlayPhotoPosX/calcuratio()
//                lvOverlayPhotoSliderOldPosX = lvOverlayPhotoPopupAlias.sliderPosXalias.value
                lvOverlayPhotoPopupAlias.spinBoxPosXalias.value = lvOverlayPhotoPosX / calcuratio() * 10
                lvOverlayPhotoSpinBoxOldPosX = lvOverlayPhotoPopupAlias.spinBoxPosXalias.value
                // ivc << end << USBTHRV140-35
            }
            lvOverlayPhotoFrameOldPosY = selComp.y
        }
    }

    function updateY(){
        if(lv_rotation == 0) {
            if((lvOverlayPhotoPosY - (selComp.y - lvOverlayPhotoFrameOldPosY)) != lvOverlayPhotoPosY) {
                lvOverlayPhotoPosY -= (selComp.y - lvOverlayPhotoFrameOldPosY)
                // ivc >> start >> USBTHRV140-35
//                lvOverlayPhotoPopupAlias.sliderPosYalias.value = lvOverlayPhotoPosY/calcuratio()
//                lvOverlayPhotoSliderOldPosY = lvOverlayPhotoPopupAlias.sliderPosYalias.value
                lvOverlayPhotoPopupAlias.spinBoxPosYalias.value = lvOverlayPhotoPosY/calcuratio() * 10
                lvOverlayPhotoSpinBoxOldPosY = lvOverlayPhotoPopupAlias.spinBoxPosYalias.value
                // ivc << end << USBTHRV140-35
            }
            lvOverlayPhotoFrameOldPosY = selComp.y
        } else if(lv_rotation == 270) {
            if((lvOverlayPhotoPosY - (selComp.x - lvOverlayPhotoFrameOldPosX)) != lvOverlayPhotoPosY) {
                lvOverlayPhotoPosY -= (selComp.x - lvOverlayPhotoFrameOldPosX)
                // ivc >> start >> USBTHRV140-35
//                lvOverlayPhotoPopupAlias.sliderPosYalias.value = lvOverlayPhotoPosY / calcuratio()
//                lvOverlayPhotoSliderOldPosY = lvOverlayPhotoPopupAlias.sliderPosYalias.value
                lvOverlayPhotoPopupAlias.spinBoxPosYalias.value = lvOverlayPhotoPosY/calcuratio() * 10
                lvOverlayPhotoSpinBoxOldPosY = lvOverlayPhotoPopupAlias.spinBoxPosYalias.value
                // ivc << end << USBTHRV140-35
            }
            lvOverlayPhotoFrameOldPosX = selComp.x
        } else if(lv_rotation == 180) {
            if((lvOverlayPhotoPosY + (selComp.y - lvOverlayPhotoFrameOldPosY)) != lvOverlayPhotoPosY) {
                lvOverlayPhotoPosY += (selComp.y - lvOverlayPhotoFrameOldPosY)
                // ivc >> start >> USBTHRV140-35
//                lvOverlayPhotoPopupAlias.sliderPosYalias.value = lvOverlayPhotoPosY / calcuratio()
//                lvOverlayPhotoSliderOldPosY = lvOverlayPhotoPopupAlias.sliderPosYalias.value
                lvOverlayPhotoPopupAlias.spinBoxPosYalias.value = lvOverlayPhotoPosY/calcuratio() * 10
                lvOverlayPhotoSpinBoxOldPosY = lvOverlayPhotoPopupAlias.spinBoxPosYalias.value
                // ivc << end << USBTHRV140-35
            }
            lvOverlayPhotoFrameOldPosY = selComp.y
        } else if(lv_rotation == 90) {
            if((lvOverlayPhotoPosY - (selComp.x - lvOverlayPhotoFrameOldPosX)) != lvOverlayPhotoPosY) {
                lvOverlayPhotoPosY += (selComp.x - lvOverlayPhotoFrameOldPosX)
                // ivc >> start >> USBTHRV140-35
//                lvOverlayPhotoPopupAlias.sliderPosYalias.value = lvOverlayPhotoPosY/calcuratio()
//                lvOverlayPhotoSliderOldPosY = lvOverlayPhotoPopupAlias.sliderPosYalias.value
                lvOverlayPhotoPopupAlias.spinBoxPosYalias.value = lvOverlayPhotoPosY/calcuratio() * 10
                lvOverlayPhotoSpinBoxOldPosY = lvOverlayPhotoPopupAlias.spinBoxPosYalias.value
                // ivc << end << USBTHRV140-35
            }
            lvOverlayPhotoFrameOldPosX = selComp.x
        }
    }

    color: "transparent"

    // ivc >> start >> USBTHRV140-35
//    function minDragAreaX() {
//        if(imageLV.paintedHeight > imageLV.paintedWidth)
//            return ((imageView.width - imageLV.paintedWidth) / 2 - selComp.width / 2 - imageLV.paintedHeight / 2)
//        else
//            return ((imageView.width - imageLV.paintedWidth) / 2 - selComp.width / 2 - imageLV.paintedWidth / 2)
//    }

//    function minDragAreaY() {
//        if(imageLV.paintedHeight > imageLV.paintedWidth)
//            return ((imageView.height - imageLV.paintedHeight) / 2 - selComp.height / 2 - imageLV.paintedHeight / 2)
//        else
//            return ( (imageView.height - imageLV.paintedHeight) / 2 - selComp.height / 2 - imageLV.paintedWidth / 2)
//    }

//    function maxDragAreaX() {
//        if(imageLV.paintedHeight > imageLV.paintedWidth)
//            return (imageView.width - (imageView.width - imageLV.paintedWidth) / 2 - selComp.width / 2 + imageLV.paintedHeight / 2)
//        else
//            return (imageView.width - (imageView.width - imageLV.paintedWidth) / 2 - selComp.width / 2 + imageLV.paintedWidth / 2)
//    }

//    function maxDragAreaY() {
//        if(imageLV.paintedHeight > imageLV.paintedWidth)
//            return (imageView.height - ((imageView.height - imageLV.paintedHeight) / 2) - selComp.height / 2 + imageLV.paintedHeight / 2)
//        else
//            return (imageView.height - ((imageView.height - imageLV.paintedHeight) / 2) - selComp.height / 2 + imageLV.paintedWidth / 2)
//    }
    // ivc << end << USBTHRV140-35

    MouseArea {     // drag mouse area
        id:dragAreaphoto
        anchors.fill: parent
        drag{
            target: parent
            smoothed: true
            // ivc >> start >> USBTHRV140-35
//            minimumX:minDragAreaX()
//            minimumY:minDragAreaY()
//            maximumX:maxDragAreaX()
//            maximumY: maxDragAreaY()
            // ivc << end << USBTHRV140-35
        }
        onPositionChanged: {
            updateX()
            updateY()
        }
    }

    Rectangle {
        smooth: true
        antialiasing: true
        anchors.fill: parent
        color: "transparent"
        Image {
            id: overlayImage
            anchors.fill: parent
            opacity: lvOverlayPhotoAspectRatio
            smooth: true
            antialiasing: true
        }
    }

    function loadImageSource(){
        //ivc >> start >> USBTHRV140-34
        overlayImage.source = "image://overlayPhoto/" +(encodeURIComponent((lvOverSelectedFile)))
        //ivc << end << USBTHRV140-34
    }

    Rectangle{
        //visible: false
        id:rotateimg
        height: (rulersSize + 5)/parent.scale
        width: (rulersSize + 5)/parent.scale
        anchors.bottom: selComp.top
        anchors.horizontalCenter: selComp.horizontalCenter
        anchors.margins: 5
        antialiasing: true
        smooth: true
        color: "transparent"

        Image {
            anchors.fill: parent
            id: imgrotate
            source: "qrc:/images/rotation.svg"
            antialiasing: true
            smooth: true
            fillMode: Image.PreserveAspectFit
        }

        MouseArea{
            //visible: false
            id:mourorate
            anchors.fill: parent
            drag.target: rotateimg
            cursorShape: Qt.SizeAllCursor
            onPressedChanged: {
                if((selComp.rotation < -25 && selComp.rotation > -165) == true || (selComp.rotation < 165 && selComp.rotation > 25) == true) {
                    if((selComp.rotation > -75 && selComp.rotation <- 25) == true || (selComp.rotation > 115 && selComp.rotation < 165) == true) {
                        mousescale2.cursorShape = Qt.SizeVerCursor
                        mousescale3.cursorShape = Qt.SizeVerCursor
                        mouscale1.cursorShape = Qt.SizeHorCursor
                        mousescale4.cursorShape = Qt.SizeHorCursor
                    } else if((selComp.rotation > -165&& selComp.rotation < -115) == true||(selComp.rotation > 25 && selComp.rotation < 75) == true) {
                        mouscale1.cursorShape = Qt.SizeVerCursor
                        mousescale2.cursorShape = Qt.SizeHorCursor
                        mousescale3.cursorShape = Qt.SizeHorCursor
                        mousescale4.cursorShape = Qt.SizeVerCursor
                    } else {
                        mouscale1.cursorShape = Qt.SizeBDiagCursor
                        mousescale2.cursorShape = Qt.SizeFDiagCursor
                        mousescale3.cursorShape = Qt.SizeFDiagCursor
                        mousescale4.cursorShape = Qt.SizeBDiagCursor
                    }
                } else {
                    mouscale1.cursorShape = Qt.SizeFDiagCursor
                    mousescale2.cursorShape = Qt.SizeBDiagCursor
                    mousescale3.cursorShape = Qt.SizeBDiagCursor
                    mousescale4.cursorShape = Qt.SizeFDiagCursor
                }

                // ivc >> start >> USBTHRV140-38
//                if(mourorate.pressed) {
//                    mourorate.cursorShape = Qt.SizeAllCursor
//                    lvOverlayPhotoOldAspectRatio=lvOverlayPhotoAspectRatio
//                    lvOverlayPhotoAspectRatio = 0.4
//                } else {
//                    lvOverlayPhotoAspectRatio=lvOverlayPhotoOldAspectRatio
//                }
                // ivc << end << USBTHRV140-38
            }
            onPositionChanged:(mouse)=> {
                var point =  mapToItem(imageView, mouse.x, mouse.y)
				//ivc >> start >> #7617 
				//var truex = point.x - (selComp.x + selComp.width / 2 )
                //var truey = (selComp.y + selComp.height / 2 ) - point.y
                var truex = point.x - (selComp.x + selComp.width / 2 - 0.5)
                var truey = (selComp.y + selComp.height / 2 + 0.5) - point.y
				//ivc << end << #7617 
                var angle = Math.atan2(truex, truey)
                var strictangle = angle * 180 / Math.PI
                if(mourorate.drag.active == true) {
                    if (mourorate.angle < 0) {
                        selComp.rotation = strictangle
                        lvOverlayPhotoRotation = selComp.rotation
                    } else {
                        selComp.rotation = strictangle
                        lvOverlayPhotoRotation = selComp.rotation
                    }
                    updateRotaOverlayPhoto()
                }
            }
        }
    }
    // CornerScaleOverlayImage: top + left
    Rectangle {
        id: cornerTopLeft
        width: (rulersSize - 5)/parent.scale
        height: (rulersSize - 5)/parent.scale
        color: "white"
        anchors.horizontalCenter: parent.left
        anchors.verticalCenter: parent.top
        antialiasing: true
        clip:true
        MouseArea {
            id:mouscale1
            anchors.fill: parent
            drag {
                target: parent;
                axis: Drag.XAndYAxis
            }
            onPositionChanged: {
                if(drag.active) {
                    var newHeight = 0
                    var newWidth = 0
                    var radian = 0
                    var temX = 0
                    var temY = 0
                    var temXnew = 0
                    var temYnew = 0
                    var changexold = 0
                    var changyold = 0
                    var changexnew = 0
                    var changynew = 0
                    var cxold = 0
                    var cyold = 0
                    var cxnew = 0
                    var cynew = 0
                    function updatePosTopLeft() {
                        radian = Math.PI*selComp.rotation/180
                        temX = lvOverlayPhotoFrameOldWidth-lvOverlayPhotoFrameOldWidth / 2
                        temY = lvOverlayPhotoFrameOldHeight-lvOverlayPhotoFrameOldHeight / 2
                        temXnew = newWidth - newWidth / 2
                        temYnew = newHeight - newHeight / 2
                        cxold = lvOverlayPhotoFrameOldWidth / 2
                        cyold = lvOverlayPhotoFrameOldHeight / 2
                        cxnew = newWidth / 2
                        cynew = newHeight / 2
                        changexold = temX * Math.cos(radian) - temY*Math.sin(radian) - cxold
                        changyold = temX * Math.sin(radian) + temY * Math.cos(radian) - cyold
                        changexnew = temXnew * Math.cos(radian) - temYnew * Math.sin(radian) - cxnew
                        changynew = temXnew * Math.sin(radian) + temYnew * Math.cos(radian) - cynew
                        selComp.x += (lvOverlayPhotoFrameOldWidth - newWidth) / 2 - (changexnew - changexold)
                        selComp.y += (lvOverlayPhotoFrameOldHeight - newHeight) / 2 - (changynew - changyold)
                        updateX()
                        updateY()
                        lvOverlayPhotoFrameOldHeight = newHeight
                        lvOverlayPhotoFrameOldWidth = newWidth
                    }

                    if(mouseX > mouseY) {
                        // ivc >> start >> USBTHRV140-23
                        //newHeight = lvOverlayPhotoFrameOldHeight - mouseY
                        newHeight = lvOverlayPhotoFrameOldHeight - mouseY * selComp.scale
                        // ivc << end << USBTHRV140-23

                        if((selComp.scale / lvOverlayPhotoFrameOldHeight  * newHeight) * lvOverlayPhotoScalingDefault >= 200) {
                            lvOverlayPhotoScaling = 200
                            selComp.scale = lvOverlayPhotoScaling / lvOverlayPhotoScalingDefault
                            newHeight = selComp.height * selComp.scale
                            newWidth = selComp.width * selComp.scale
                            updatePosTopLeft()
                            return
                        } else if((selComp.scale / lvOverlayPhotoFrameOldHeight * newHeight) * lvOverlayPhotoScalingDefault<= 25) {
                            lvOverlayPhotoScaling = 25
                            selComp.scale = lvOverlayPhotoScaling / lvOverlayPhotoScalingDefault
                            newHeight = selComp.height * selComp.scale
                            newWidth = selComp.width * selComp.scale
                            updatePosTopLeft()
                            return
                        }

                        selComp.scale = selComp.scale  /lvOverlayPhotoFrameOldHeight * newHeight
                        lvOverlayPhotoScaling = selComp.scale * lvOverlayPhotoScalingDefault
                        newWidth = selComp.width * selComp.scale
                        updatePosTopLeft()
                    } else if(mouseX<mouseY) {
                        // ivc >> start >> USBTHRV140-23
                        //newWidth = lvOverlayPhotoFrameOldWidth - mouseX
                        newWidth = lvOverlayPhotoFrameOldWidth - mouseX * selComp.scale
                        // ivc >> start >> USBTHRV140-23
                        if((selComp.scale / lvOverlayPhotoFrameOldWidth * newWidth) * lvOverlayPhotoScalingDefault >= 200) {
                            lvOverlayPhotoScaling = 200
                            selComp.scale = lvOverlayPhotoScaling / lvOverlayPhotoScalingDefault
                            newHeight = selComp.height * selComp.scale
                            newWidth = selComp.width * selComp.scale
                            updatePosTopLeft()
                            return
                        } else if((selComp.scale/lvOverlayPhotoFrameOldWidth*newWidth)*lvOverlayPhotoScalingDefault<=25) {
                            lvOverlayPhotoScaling = 25
                            selComp.scale = lvOverlayPhotoScaling / lvOverlayPhotoScalingDefault
                            newHeight = selComp.height * selComp.scale
                            newWidth = selComp.width * selComp.scale
                            updatePosTopLeft()
                            return
                        }

                        selComp.scale = selComp.scale / lvOverlayPhotoFrameOldWidth * newWidth
                        lvOverlayPhotoScaling = selComp.scale * lvOverlayPhotoScalingDefault
                        newHeight = selComp.height * selComp.scale
                        updatePosTopLeft()
                    }
                }
            }
            cursorShape: Qt.SizeFDiagCursor
        }
    }
    // CornerScaleOverlayImage: bottom + left
    Rectangle {
        id: cornerBottomLeft
        width: (rulersSize - 5)/parent.scale
        height: (rulersSize - 5)/parent.scale
        color: "white"
        anchors.horizontalCenter: parent.left
        anchors.verticalCenter: parent.bottom
        antialiasing: true
        MouseArea {
            id:mousescale3
            anchors.fill: parent
            drag{ target: parent; axis: Drag.XAndYAxis }
            onPositionChanged: {
                if(drag.active){
                    var newHeight = 0
                    var newWidth = 0
                    var radian = 0
                    var temX = 0
                    var temY = 0
                    var temXnew = 0
                    var temYnew = 0
                    var changexold = 0
                    var changyold = 0
                    var changexnew = 0
                    var changynew = 0
                    var cxold = 0
                    var cyold = 0
                    var cxnew = 0
                    var cynew = 0
                    function updatePosBotLeft(){
                        radian = Math.PI * selComp.rotation / 180
                        temX = lvOverlayPhotoFrameOldWidth - lvOverlayPhotoFrameOldWidth / 2
                        temY = 0 - lvOverlayPhotoFrameOldHeight / 2
                        temXnew = newWidth - newWidth / 2
                        temYnew = 0 - newHeight / 2
                        cxold = lvOverlayPhotoFrameOldWidth/2
                        cyold = lvOverlayPhotoFrameOldHeight/2
                        cxnew = newWidth/2
                        cynew = newHeight/2
                        changexold = temX * Math.cos(radian) - temY * Math.sin(radian) - cxold
                        changyold = temX * Math.sin(radian) + temY * Math.cos(radian) + cyold
                        changexnew = temXnew * Math.cos(radian) - temYnew * Math.sin(radian) - cxnew
                        changynew = temXnew * Math.sin(radian) + temYnew * Math.cos(radian) + cynew
                        selComp.x += ((lvOverlayPhotoFrameOldWidth  -newWidth) / 2 -(changexnew - changexold))
                        selComp.y -= ((lvOverlayPhotoFrameOldHeight - newHeight) / 2 +(changynew - changyold))
                        updateX()
                        updateY()
                        lvOverlayPhotoFrameOldHeight = newHeight
                        lvOverlayPhotoFrameOldWidth = newWidth
                    }

                    if(Math.abs(mouseX) > Math.abs(mouseY)) {
                        // ivc >> start >> USBTHRV140-23
                        //newHeight = lvOverlayPhotoFrameOldHeight+mouseY
                        newHeight = lvOverlayPhotoFrameOldHeight+mouseY * selComp.scale
                        // ivc << end << USBTHRV140-23
                        if((selComp.scale / lvOverlayPhotoFrameOldHeight * newHeight) * lvOverlayPhotoScalingDefault >= 200) {
                            lvOverlayPhotoScaling = 200
                            selComp.scale = lvOverlayPhotoScaling/lvOverlayPhotoScalingDefault
                            newHeight = selComp.height * selComp.scale
                            newWidth = selComp.width * selComp.scale
                            updatePosBotLeft()
                            return
                        } else if((selComp.scale/lvOverlayPhotoFrameOldHeight*newHeight) * lvOverlayPhotoScalingDefault <= 25) {
                            lvOverlayPhotoScaling = 25
                            selComp.scale = lvOverlayPhotoScaling / lvOverlayPhotoScalingDefault
                            newHeight = selComp.height * selComp.scale
                            newWidth = selComp.width * selComp.scale
                            updatePosBotLeft()
                            return
                        }

                        selComp.scale = selComp.scale / lvOverlayPhotoFrameOldHeight * newHeight
                        lvOverlayPhotoScaling = selComp.scale * lvOverlayPhotoScalingDefault
                        newWidth = selComp.width * selComp.scale
                        updatePosBotLeft()
                    } else if(Math.abs(mouseX)<Math.abs(mouseY)) {
                        // ivc >> start >> USBTHRV140-23
                        //newWidth = lvOverlayPhotoFrameOldWidth - mouseX
                        newWidth = lvOverlayPhotoFrameOldWidth - mouseX * selComp.scale
                        // ivc << end << USBTHRV140-23
                        if((selComp.scale / lvOverlayPhotoFrameOldWidth * newWidth) * lvOverlayPhotoScalingDefault >= 200) {
                            lvOverlayPhotoScaling = 200
                            selComp.scale = lvOverlayPhotoScaling/lvOverlayPhotoScalingDefault
                            newHeight = selComp.height * selComp.scale
                            newWidth = selComp.width * selComp.scale
                            updatePosBotLeft()
                            return
                        } else if((selComp.scale / lvOverlayPhotoFrameOldWidth * newWidth) * lvOverlayPhotoScalingDefault <= 25) {
                            lvOverlayPhotoScaling = 25
                            selComp.scale = lvOverlayPhotoScaling / lvOverlayPhotoScalingDefault
                            newHeight = selComp.height * selComp.scale
                            newWidth = selComp.width * selComp.scale
                            updatePosBotLeft()
                            return
                        }

                        selComp.scale = selComp.scale / lvOverlayPhotoFrameOldWidth * newWidth
                        lvOverlayPhotoScaling = selComp.scale * lvOverlayPhotoScalingDefault
                        newHeight = selComp.height * selComp.scale
                        updatePosBotLeft()
                    }
                }
            }
            cursorShape: Qt.SizeBDiagCursor
            acceptedButtons: Qt.LeftButton
        }
    }
    // CornerScaleOverlayImage: top + right
    Rectangle {
        id: cornerTopRight
        width: (rulersSize -5)/parent.scale
        height: (rulersSize -5)/parent.scale
        x: parent.x / 2
        y: 0
        color: "white"
        anchors.horizontalCenter: parent.right
        anchors.verticalCenter: parent.top
        antialiasing: true
        MouseArea {
            id:mousescale2
            anchors.fill: parent
            drag{ target: parent; axis: Drag.XAndYAxis }
            onPositionChanged: {
                if(drag.active){
                    var newHeight = 0
                    var newWidth = 0
                    var radian = 0
                    var temX = 0
                    var temY = 0
                    var temXnew = 0
                    var temYnew = 0
                    var changexold = 0
                    var changyold = 0
                    var changexnew = 0
                    var changynew = 0
                    var cxold = 0
                    var cyold = 0
                    var cxnew = 0
                    var cynew = 0
                    function updatePosTopRight() {
                        radian = Math.PI * selComp.rotation / 180
                        temX = 0 - lvOverlayPhotoFrameOldWidth / 2
                        temY = lvOverlayPhotoFrameOldHeight - lvOverlayPhotoFrameOldHeight / 2
                        temXnew = 0 - newWidth / 2
                        temYnew = newHeight - newHeight / 2
                        cxold = lvOverlayPhotoFrameOldWidth / 2
                        cyold = lvOverlayPhotoFrameOldHeight / 2
                        cxnew = newWidth / 2
                        cynew = newHeight / 2
                        changexold = temX * Math.cos(radian) - temY * Math.sin(radian) + cxold
                        changyold = temX * Math.sin(radian) + temY * Math.cos(radian) - cyold
                        changexnew = temXnew * Math.cos(radian) - temYnew * Math.sin(radian) + cxnew
                        changynew = temXnew * Math.sin(radian) + temYnew * Math.cos(radian) - cynew
                        selComp.x -= ((lvOverlayPhotoFrameOldWidth - newWidth) / 2 + (changexnew - changexold))
                        selComp.y += ((lvOverlayPhotoFrameOldHeight - newHeight) / 2 - (changynew - changyold))
                        updateX()
                        updateY()
                        lvOverlayPhotoFrameOldHeight = newHeight
                        lvOverlayPhotoFrameOldWidth = newWidth
                    }

                    if(Math.abs(mouseX) > Math.abs(mouseY)){
                        // ivc >> start >> USBTHRV140-23
                        //newHeight = lvOverlayPhotoFrameOldHeight - mouseY
                        newHeight = lvOverlayPhotoFrameOldHeight - mouseY * selComp.scale
                        // ivc << end << USBTHRV140-23
                        if((selComp.scale / lvOverlayPhotoFrameOldHeight * newHeight) * lvOverlayPhotoScalingDefault >= 200) {
                            lvOverlayPhotoScaling = 200
                            selComp.scale = lvOverlayPhotoScaling / lvOverlayPhotoScalingDefault
                            newHeight = selComp.height * selComp.scale
                            newWidth = selComp.width * selComp.scale
                            updatePosTopRight()
                            return
                        } else if((selComp.scale / lvOverlayPhotoFrameOldHeight * newHeight) * lvOverlayPhotoScalingDefault <= 25) {
                            lvOverlayPhotoScaling = 25
                            selComp.scale = lvOverlayPhotoScaling / lvOverlayPhotoScalingDefault
                            newHeight = selComp.height * selComp.scale
                            newWidth = selComp.width * selComp.scale
                            updatePosTopRight()
                            return
                        }

                        selComp.scale = selComp.scale / lvOverlayPhotoFrameOldHeight * newHeight
                        lvOverlayPhotoScaling = selComp.scale*lvOverlayPhotoScalingDefault
                        newWidth = selComp.width*selComp.scale
                        updatePosTopRight()
                    } else if(Math.abs(mouseX) < Math.abs(mouseY)) {
                        // ivc >> start >> USBTHRV140-23
                        //newWidth = lvOverlayPhotoFrameOldWidth + mouseX
                        newWidth = lvOverlayPhotoFrameOldWidth + mouseX * selComp.scale
                        // ivc << end << USBTHRV140-23
                        if((selComp.scale / lvOverlayPhotoFrameOldWidth * newWidth) * lvOverlayPhotoScalingDefault >= 200) {
                            lvOverlayPhotoScaling = 200
                            selComp.scale = lvOverlayPhotoScaling / lvOverlayPhotoScalingDefault
                            newHeight = selComp.height * selComp.scale
                            newWidth = selComp.width * selComp.scale
                            updatePosTopRight()
                            return
                        } else if((selComp.scale/lvOverlayPhotoFrameOldWidth*newWidth)*lvOverlayPhotoScalingDefault<=25) {
                            lvOverlayPhotoScaling = 25
                            selComp.scale = lvOverlayPhotoScaling / lvOverlayPhotoScalingDefault
                            newHeight = selComp.height * selComp.scale
                            newWidth = selComp.width * selComp.scale
                            updatePosTopRight()
                            return
                        }

                        selComp.scale = selComp.scale / lvOverlayPhotoFrameOldWidth * newWidth
                        lvOverlayPhotoScaling = selComp.scale*lvOverlayPhotoScalingDefault
                        newHeight = selComp.height * selComp.scale
                        updatePosTopRight()
                    }
                }
            }
            cursorShape: Qt.SizeBDiagCursor
            acceptedButtons: Qt.LeftButton
        }
    }
    // CornerScaleOverlayImage: bottom + right
    Rectangle {
        id: cornerBottomRight
        width: (rulersSize -5)/parent.scale
        height: (rulersSize -5)/parent.scale
        x: parent.x / 2
        y: parent.y
        color: "white"
        anchors.horizontalCenter: parent.right
        anchors.verticalCenter: parent.bottom
        antialiasing: true
        MouseArea {
            //visible: false
            id:mousescale4
            anchors.fill: parent
            drag{ target: parent; axis: Drag.XAndYAxis }
            onPositionChanged: {
                if(drag.active) {
                    var newHeight = 0
                    var newWidth = 0
                    var radian = 0
                    var temX = 0
                    var temY = 0
                    var temXnew = 0
                    var temYnew = 0
                    var changexold = 0
                    var changyold = 0
                    var changexnew = 0
                    var changynew = 0
                    var cxold = 0
                    var cyold = 0
                    var cxnew = 0
                    var cynew = 0
                    function updatePosBotRight() {
                        radian = Math.PI * selComp.rotation / 180
                        temX = 0 - lvOverlayPhotoFrameOldWidth / 2
                        temY = 0 - lvOverlayPhotoFrameOldHeight / 2
                        temXnew = 0 - newWidth / 2
                        temYnew = 0 - newHeight / 2
                        cxold = lvOverlayPhotoFrameOldWidth / 2
                        cyold = lvOverlayPhotoFrameOldHeight / 2
                        cxnew = newWidth / 2
                        cynew = newHeight / 2
                        changexold = temX * Math.cos(radian) - temY * Math.sin(radian) + cxold
                        changyold = temX * Math.sin(radian) + temY * Math.cos(radian) + cyold
                        changexnew = temXnew * Math.cos(radian) - temYnew * Math.sin(radian) + cxnew
                        changynew = temXnew * Math.sin(radian) + temYnew * Math.cos(radian) + cynew
                        selComp.x -= ((lvOverlayPhotoFrameOldWidth - newWidth) / 2 + (changexnew - changexold))
                        selComp.y -= ((lvOverlayPhotoFrameOldHeight - newHeight) / 2 + (changynew - changyold))
                        updateX()
                        updateY()
                        lvOverlayPhotoFrameOldHeight = newHeight
                        lvOverlayPhotoFrameOldWidth = newWidth
                    }

                    if(mouseX < mouseY) {
                        // ivc >> start >> USBTHRV140-23
                        //newHeight = lvOverlayPhotoFrameOldHeight+mouseY
                        newHeight = lvOverlayPhotoFrameOldHeight+mouseY * selComp.scale
                        // ivc << end << USBTHRV140-23
                        if((selComp.scale / lvOverlayPhotoFrameOldHeight * newHeight) * lvOverlayPhotoScalingDefault >= 200) {
                            lvOverlayPhotoScaling = 200
                            selComp.scale = lvOverlayPhotoScaling / lvOverlayPhotoScalingDefault
                            newHeight = selComp.height * selComp.scale
                            newWidth = selComp.width * selComp.scale
                            updatePosBotRight()
                            return
                        } else if((selComp.scale / lvOverlayPhotoFrameOldHeight * newHeight) * lvOverlayPhotoScalingDefault <= 25) {
                            lvOverlayPhotoScaling = 25
                            selComp.scale = lvOverlayPhotoScaling / lvOverlayPhotoScalingDefault
                            newHeight = selComp.height * selComp.scale
                            newWidth = selComp.width * selComp.scale
                            updatePosBotRight()
                            return
                        }

                        selComp.scale = selComp.scale / lvOverlayPhotoFrameOldHeight * newHeight
                        lvOverlayPhotoScaling = selComp.scale * lvOverlayPhotoScalingDefault
                        newWidth = selComp.width * selComp.scale
                        updatePosBotRight()
                    } else if(mouseX > mouseY) {
                        // ivc >> start >> USBTHRV140-23
                        //newWidth = lvOverlayPhotoFrameOldWidth + mouseX
                        newWidth = lvOverlayPhotoFrameOldWidth + mouseX * selComp.scale
                        // ivc << end << USBTHRV140-23
                        if((selComp.scale / lvOverlayPhotoFrameOldWidth * newWidth) * lvOverlayPhotoScalingDefault >= 200) {
                            lvOverlayPhotoScaling = 200
                            selComp.scale = lvOverlayPhotoScaling/lvOverlayPhotoScalingDefault
                            newHeight = selComp.height * selComp.scale
                            newWidth = selComp.width * selComp.scale
                            updatePosBotRight()
                            return
                        } else if((selComp.scale / lvOverlayPhotoFrameOldWidth * newWidth)* lvOverlayPhotoScalingDefault <= 25) {
                            lvOverlayPhotoScaling = 25
                            selComp.scale = lvOverlayPhotoScaling / lvOverlayPhotoScalingDefault
                            newHeight = selComp.height * selComp.scale
                            newWidth = selComp.width * selComp.scale
                            updatePosBotRight()
                            return
                        }

                        selComp.scale = selComp.scale / lvOverlayPhotoFrameOldWidth * newWidth
                        lvOverlayPhotoScaling = selComp.scale * lvOverlayPhotoScalingDefault
                        newHeight = selComp.height * selComp.scale
                        updatePosBotRight()
                    }
                }
            }
            cursorShape: Qt.SizeFDiagCursor
            acceptedButtons: Qt.LeftButton
        }
    }
}
