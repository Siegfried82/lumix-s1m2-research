import QtQuick 2.6
import Qt5Compat.GraphicalEffects

import "qrc:/qml"

/*! \qmltype LTRoundButton
    \inqmlmodule LT

    \brief
    円形のボタンです

    大きさは LTRoundButton::diameter で設定します．
    width ならびに height を設定することも可能ですが，マウス操作に対して width あるいは height のうち短い方を直径とする
    円の内部でのみ反応するため，見た目と振る舞いが一致しません．
 */
LTAbstractButton {
    id: root
    /*!
        円形の直径です
     */
    property real diameter: Math.min(width, height)
    onDiameterChanged: {
        if (width != diameter) {
            width = diameter;
        }
        if (height != diameter) {
            height = diameter;
        }
    }

    /*
        境界線と背景ぬりつぶし
     */
    Rectangle {
        id: rectangle
        z: 10
        anchors {
            fill: parent
        }
        color: fillColor
        border {
            width: strokeWidth
            color: strokeColor
        }
        radius: diameter / 2
    }

    /*
        マウス操作領域

        \sa {http://stackoverflow.com/questions/38164074/how-to-create-a-round-mouse-area-in-qml}
     */
    Item {
        id: mouseArea
        anchors {
            fill: parent
        }
        property int mouseX: internalMouseArea.mouseX
        property int mouseY: internalMouseArea.mouseY

        /*
            マウスが円の内部にあるか否かを返します

            MouseArea::containsMouse に相当します．
         */
        readonly property bool containsMouse: {
            if (!internalMouseArea.containsMouse) {
                return false;
            }
            var radius = diameter / 2;
            var distance = Math.pow(radius - internalMouseArea.mouseX, 2) + Math.pow(radius - internalMouseArea.mouseY, 2);
            return distance < Math.pow(radius, 2);
        }

        /*
            マウスが円の内部でボタンを押されているか否かを返します

            MouseArea::pressed に相当します．
         */
        readonly property bool pressed: {
            return internalMouseArea.pressed && mouseArea.containsMouse;
        }

        /*
            マウス操作領域 (矩形)
         */
        MouseArea {
            id: internalMouseArea
            anchors {
                fill: parent
            }
            hoverEnabled: true
            onClicked:(mouse)=> {
                if (mouseArea.containsMouse) {
                    root.clicked(mouse, root);
                }
            }
            onExited: {
                root.exited();
            }
            onCanceled: {
                root.canceled();
            }
            onPressed:(mouse)=> {
                if (mouseArea.containsMouse) {
                    root.pressed(mouse, root);
                }
            }
            onReleased: {
                root.released(mouseArea.containsMouse);
            }
            onPressAndHold:(mouse)=> {
                if (mouseArea.containsMouse) {
                    root.pressAndHold(mouse, root);
                }
            }
        }
    }
    /*
        ボタンが選択状態、ボタンが無効状態のSVG描画カスタマイズ
     */
    onSourceChanged: {
        //OpenGLの場合は動作しないようにする
        if( isOpenGLMode === "true" ){
            return
        }
        setDisableImg()

        visibleCheck()
    }

    onEnabledChanged: {
        //OpenGLの場合は動作しないようにする
        if( isOpenGLMode === "true" ){
            return
        }
        setDisableImg()

        visibleCheck()
    }

    onCheckedChanged: {
        //OpenGLの場合は動作しないようにする
        if( isOpenGLMode === "true" ){
            return
        }
        setDisableImg()

        visibleCheck()
    }

    onErrorChanged: {
        //OpenGLの場合は動作しないようにする
        if( isOpenGLMode === "true" ){
            return
        }
        setDisableImg()

        visibleCheck()
    }

    function setDisableImg()
    {
        //OpenGLの場合は動作しないようにする
        if( isOpenGLMode === "true" ){
            return
        }
        //輝度変更してDisable用のイメージを作成
        if( mainDisableImg.source != "image://brightnessChg/" + mainImg.source + "?y=0" &&
            mainImg.source.toLocaleString() )
        {
            mainDisableImg.source = "image://brightnessChg/" + mainImg.source + "?y=0"
        }
    }

    function visibleCheck()
    {
        //OpenGLの場合は動作しないようにする
        if( isOpenGLMode === "true" ){
            return
        }
        //表示状態を管理
        if( (!enabled)||(error)){
            mainImg.visible = false

            mainDisableImg.visible = true
        }else{
            mainImg.visible = true

            mainDisableImg.visible = false
        }
    }
    BrightnessContrast {
        z: 30

        anchors.fill: mainImg
        source: mainImg
        brightness: {
            if((!enabled)||(error)) {
                return -0.6
            }
            return -1
        }
        contrast: 0

        visible: {
            //OpenGL以外の場合は表示しないようにする
            if( isOpenGLMode === "false" ){
                return false
            }
            if((!enabled)||(error)) {
                mainImg.visible = false;
                return true;
            } else {
                mainImg.visible = true;
                return false;
            }
        }
    }

}
