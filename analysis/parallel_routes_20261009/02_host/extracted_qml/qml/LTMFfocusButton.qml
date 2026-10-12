import QtQuick 2.6
import QtQuick.Controls 2.1
import Qt5Compat.GraphicalEffects

import "qrc:/qml"

/*! \qmltype LTRectangleButtonrs
    \inqmlmodule LT

    \brief
    矩形のボタンです マウスの戻りでonPressed:onReleased:

 */
LTAbstractButton {
    id: root

    /*!
        デザインを制御する値です

        \table
        \header
            \li 値
            \li 説明
        \row
            \li \tt action
            \li 中央にラベルのテキストを表示します
        \row
            \li \tt optionWithImage
            \li 中央に状態を示す画像を，左上にラベルのテキストを表示します
        \row
            \li \tt optionWithText
            \li 中央に左寄せでラベルのテキストを，右寄せで状態を示すテキストを表示します
        \row
            \li \tt checkableWithText
            \li 中央に左寄せで，LTAbstractButton::checked に応じて色が変化する，ラベルのテキストを表示します
        \row
            \li \tt checkableWithImageAndText
            \li Image in right side and Text in left side change color with LTAbstractButton::checked
        \endtable
     */
    property string type: "action"

    /*!
        状態を示す値です
     */
    property var value

    /*!
        ラベルのテキストです
     */
    property alias labelText: label.text

    /*!
        状態を示すテキストです
     */
    property alias optionText: option.text
    /*!
        状態を示すテキストです
     */
    property alias optionTextTooltip: root.toolTipText

    /*!
        プルダウン用のImage
     */
    property string optionSource: ""

    /*!
        For check image
     */
    property alias checkedImage: checkedImg.source

    /*!
        テキストの色です
     */
    property color textColor: {
        if (type == "optionWithRichText" || type == "optionWithText") {
            return checked ? "#000000" : "#808080";
        } else {
            return checked ? "#ffbf1f" : "#808080";
        }
    }
    /*!
        フォントの属性です
     */
    property var font: {
        switch (type) {
        case "action":
            return {
                "pixelSize": 14,
                "weight": Font.Bold,
                "family": "Tahoma"
            };
        case "optionWithImage":
            return {
                "pixelSize": 13,
                "family": "Tahoma"
            };
        case "optionWithRichText":
            return {
                "pixelSize": 14,
                "family": "Tahoma"
            };
        case "optionWithText":
            return {
                "pixelSize": 14,
                "family": "Tahoma"
            };
        case "checkableWithText":
            return {
                "pixelSize": 14,
                "family": "Tahoma"
            };
        case "checkableWithImageAndText":
            return {
                "pixelSize": 14,
                "weight": Font.Bold,
                "family": "Tahoma"
            };
        case "optionWithImagetoText":
        case "optionWithImagetoTextCc":
        case "optionWithImagetoText_dm":
            return {
                "pixelSize": 14,
                "family": "Tahoma"
            };
        default:
            return {
                "pixelSize": 14,
                "family": "Tahoma"
            };
        }
    }
    onFontChanged: {
        label.font = Qt.font(font);
        option.font = Qt.font(font);
    }

    /*!
        境界線の角を丸める半径です
     */
    property alias radius: rectangle.radius

    /*
        チェックインジケータ

        LTAbstractButton::type が \tt checkableWithText の場合にのみ表示します
     */
    Rectangle {
        id: indicator
        visible: (type == "checkableWithText") && checked
        x: 0
        y: 2
        z: 30
        width: 4
        height: parent.height - y * 2
        color: textColor
    }

    /*
        ラベルのテキスト
     */
    Text {
        id: label
        x: {
            switch (type) {
            case "action":
                return 0;
            case "optionWithImage":
                return 6;
            case "optionWithRichText":
                return 6;
            case "optionWithText":
                return 14;
            case "checkableWithText":
                return 14;
            case "checkableWithImageAndText":
                return 14;
            case "optionWithImagetoText":
            case "optionWithImagetoTextCc":
            case "optionWithImagetoText_dm":
                return 14;
            default:
                return 0;
            }
        }
        y: {
            switch (type) {
            case "action":
                return 0;
            case "optionWithImage":
                return 6;
            case "optionWithRichText":
                return 6;
            case "optionWithText":
                return 0;
            case "checkableWithText":
                return 0;
            case "checkableWithImageAndText":
                return 0;
            case "optionWithImagetoText":
            case "optionWithImagetoTextCc":
            case "optionWithImagetoText_dm":
                return 0;
            default:
                return 0;
            }
        }
        z: 30
        width: parent.width - x * 2
        height: parent.height - y * 2
        color: textColor
        horizontalAlignment: {
            switch (type) {
            case "action":
                return Text.AlignHCenter;
            case "optionWithImage":
                return Text.AlignLeft;
            case "optionWithRichText":
                return Text.AlignLeft;
            case "optionWithText":
                return Text.AlignLeft;
            case "checkableWithText":
                return Text.AlignLeft;
            case "checkableWithImageAndText":
                return Text.AlignLeft;
            case "optionWithImagetoText":
            case "optionWithImagetoTextCc":
            case "optionWithImagetoText_dm":
                return Text.AlignLeft;
            default:
                return Text.AlignLeft;
            }
        }
        verticalAlignment: {
            switch (type) {
            case "action":
                return Text.AlignVCenter;
            case "optionWithImage":
                return Text.AlignTop;
            case "optionWithRichText":
                return Text.AlignTop;
            case "optionWithText":
                return Text.AlignVCenter;
            case "checkableWithText":
                return Text.AlignVCenter;
            case "checkableWithImageAndText":
                return Text.AlignVCenter;
            case "optionWithImagetoText":
            case "optionWithImagetoTextCc":
            case "optionWithImagetoText_dm":
                return Text.AlignVCenter;
            default:
                return Text.AlignTop;
            }
        }
    }

    /*
        For checked image

        LTAbstractButton::type が \tt checkableWithImageAndText の場合にのみ表示します
     */
    Image {
        id: checkedImg
        visible: type == "checkableWithImageAndText"
        z: 20

        anchors {
//            centerIn: parent
            verticalCenter: parent.verticalCenter
            right: parent.right
            rightMargin: 14
        }
    }
    /*
        状態を示すテキスト

        LTAbstractButton::type が \tt optionWithText の場合にのみ表示します
     */
    Text {
        id: option
//        visible: (type == "optionWithText")||(type == "optionWithImagetoText")||(type == "optionWithImagetoTextCc")||(type == "optionWithImagetoText_dm")
        visible: (type == "optionWithText" || type == "optionWithRichText")
        x: 14
        y: 0
        z: 30
        width: parent.width - x * 2
        height: parent.height - y * 2
        color: textColor
        horizontalAlignment: {
            switch (type) {
            case "optionWithRichText":
                return Text.AlignHCenter;
            default:
                return Text.AlignRight;
            }
        }

        verticalAlignment: Text.AlignVCenter

        textFormat: {
            switch (type) {
            case "optionWithRichText":
                return Text.RichText;
            default:
                return Text.AutoText;
            }
        }

//        font: {
//            switch (type) {
//            case "optionWithRichText":
//                return {
//                    "pixelSize": 18,
//                    "weight": Font.Bold
//                };
//            default:
//                return;
//            }
//        }
    }
    /*for debug*/
    /*
    Text {
        id: optionDebug
        visible: true
        x: 14
        y: 0
        z: 30
        width: parent.width - x * 2
        height: parent.height - y * 2
        color: textColor
        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
    }
    Popup {
        id: optionPopup
        x: 100
        y: 100
        width: 200
        height: 300
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
    }*/
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
        radius: 0
    }

    /*
        マウス操作領域
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

    /*
        Effect image for selected button
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
        //輝度変更してChecked用のイメージを作成
        if( mainCheckedImg.source != "image://colorizeChg/" + mainImg.source + "?l=0" &&
            mainImg.source.toLocaleString() )
        {
            mainCheckedImg.source = "image://colorizeChg/" + mainImg.source + "?l=0"
        }
    }

    function visibleCheck()
    {
        //OpenGLの場合は動作しないようにする
        if( isOpenGLMode === "true" ){
            return
        }
        //表示状態を管理
        if (type != "optionWithImage") {
            mainImg.visible = true
            mainCheckedImg.visible = false
        } else {
            mainImg.visible = !checked;
            mainCheckedImg.visible = checked;
        }
    }

    Colorize {
        z: 30

        anchors.fill: mainImg
        source: mainImg
        lightness: -1
        cached: true

        visible: {
            //OpenGL以外の場合は表示しないようにする
            if( isOpenGLMode === "false" ){
                return false
            }
            if (type != "optionWithImage") {
                return false;
            } else {
                mainImg.visible = !checked;
                return checked;
            }
        }
    }

    /*!
        チェック状態の背景色
     */
    checkedColor: (type == "checkableWithText" || type == "checkableWithImageAndText") ? "#00000000" : "#ffbf1f"

}
