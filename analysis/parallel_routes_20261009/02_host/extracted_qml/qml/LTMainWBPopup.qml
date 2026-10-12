import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0
import QtQuick.Window 2.3

import "qrc:/qml"
import LT 1.0 as LT
import "LTSubFunction.js" as LTSubFunction

/*! \qmltype LTMainWBPopup
    \inqmlmodule LT

    \brief
    LTOptionButton の状態を選択するポップアップです
 */
Window {
    id: root

    flags:
        Qt.Window
      | Qt.FramelessWindowHint

    //Windowサイズを変更できなくする
    minimumWidth: popup.width
    minimumHeight: popup.height
    maximumWidth: popup.width
    maximumHeight: popup.height

    modality: Qt.ApplicationModal

    visible: false

    signal onOKClicked()

    signal onCancelClicked()

    signal onResetClicked()

    signal onChangeValue()

    /*!
        各部の描画色を定義するパレットです
     */
    readonly property var palette: {
        "backgroundDark": "#07090d",
        "backgroundLight": "#292b2d",
        "foregroundDark": "#808080",
        "foregroundLight": "#c6c6c6",
        "hovered": "#434343",
        "pressed": "#5c5c5c",
        "checked": "#ffbf1f",
        "titleText": "#808080",
        "valueText": "#ffffff",
        "headerText": "#ffffff",
        "line": "#000000",
    }

    /*!
        ボタンを並べて表示する領域の高さの上限です
     */


    property alias headerText: labelText.text

    property alias valueText: valText.text

    readonly property real headerHeight: 36

    readonly property real titleSize: 36

    readonly property real lineSize: 2

    readonly property real colorTableHeight: colorTable.sourceSize.height     //250

    readonly property real colorTableWidth: colorTable.sourceSize.width     //250

    readonly property real pointerHeight: 14//pointer.sourceSize.height/15

    readonly property real pointerWidth: 14//pointer.sourceSize.width/15

    readonly property real fontTitleSize: 14

    readonly property real fontValueSize: 18

    readonly property int maxAB: 20

    readonly property int maxGM: 20

    readonly property int minAB: 0

    readonly property int minGM: 0

    property int maxRangeAB: 19

    property int maxRangeGM: 19

    property int minRangeAB: 1

    property int minRangeGM: 1

    property int preValAB: 0

    property int preValGM: 0

    property int valAB: 10
    onValABChanged: {
        if (minAB <= valAB && valAB <= maxAB) {
            pointer.x = valToPosAB(valAB);
        }
    }

    function valToPosAB(val) {
        var pos = val/(maxAB-minAB) * colorTableWidth;
        return (pos - pointerWidth/2);
    }

    property int valGM: 10
    onValGMChanged: {
        if (root.wb_mode == root.wb_mode_normal) {
            if (minGM <= valGM && valGM <= maxGM) {
                pointer.y = valToPosGM(valGM);
            }
        } else if (root.wb_mode == root.wb_mode_ia_plus) {
            var tempGM = Math.round((maxGM - minGM)/2)
            pointer.y = valToPosGM(tempGM);
        }
    }

    function valToPosGM(val) {
        var pos = colorTableHeight - val/(maxGM-minGM) * colorTableHeight;
        return (pos - pointerHeight/2);
    }

    readonly property int wb_mode_normal:  0
    readonly property int wb_mode_ia_plus: 1
    property int wb_mode: wb_mode_normal

    /*
        ボタンを並べて表示する領域
     */
    Rectangle {
        id: popup
        implicitWidth: flickable.width + border.width * 2
        implicitHeight: flickable.height + btnPanel.height + border.width * 2
        color: "#000000"

        border {
            width: 2
            color: "#c6c6c6"
        }

        Flickable {
            id: flickable
            x: popup.border.width
            y: popup.border.width
            implicitWidth: popupContent.width
            implicitHeight: popupContent.height
            contentHeight: popupContent.height
            contentWidth: popupContent.width
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            Column {
                id: popupContent

                width: colorTableWidth + titleSize * 2
                height: headerHeight + colorTableHeight + titleSize * 3

                Item {
                    id: headerPanel

                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    height: headerHeight


                    LTStylishText {
                        id: labelText

                        anchors {
                            left: parent.left
                            right: parent.right
                            margins: 12
                        }
                        height: parent.height

                        text:qsTr("WB Adjust")
                        color: palette.headerText
                        type: text_style_wbTuningTitle
                    }
                }

                Item {
                    id: titleG
                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    height: titleSize

                    LTStylishText {
                        anchors.fill: parent

                        text:qsTr("G")

                        color: palette.titleText
                        type: text_style_wbTuningLabel
                    }
                }

                Item {
                    id: midRow
                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    height: colorTable.height

                    Row{
                        anchors.fill: parent

                        Item {
                            id: titleA

                            anchors {
                                top: parent.top
                                bottom: parent.bottom
                            }
                            width: titleSize

                            LTStylishText {
                                anchors.fill: parent

                                text:qsTr("A")

                                color: palette.titleText
                                type: text_style_wbTuningLabel
                            }
                        }

                        Item {
                            id: colorPanel

                            height: colorTableHeight
                            width: colorTableWidth

                            Image {
                                id: colorTable

                                anchors.fill: parent

                                anchors.centerIn: parent
                                source: "qrc:/images/397_wb_color.png"
                            }

                            Rectangle {
                                id: verLine

                                x: pointer.x + pointer.width/2 - verLine.width/2
                                y: 0
                                z: 10

                                width: lineSize
                                height: colorPanel.height

                                color: palette.line
                            }

                            Rectangle {
                                id: horLine

                                x: 0
                                y: pointer.y + pointer.height/2 - horLine.height/2
                                z: 10

                                width: colorPanel.width
                                height: lineSize

                                color: palette.line
                            }

                            Image {
                                id: pointer

                                x: 0
                                y: 0
                                z: 30

                                height: pointerHeight
                                width: pointerWidth

                                source: "qrc:/images/454_plus_l.svg"
                            }

                            MouseArea {
                                id: msArea

                                z: 50
                                anchors.fill: parent

                                onClicked:(mouse)=> {
                                    var perAB = mouse.x/msArea.width;
                                    var tempAB = Math.round(perAB * (maxAB - minAB));
                                    valAB = (tempAB > maxRangeAB) ? maxRangeAB : (tempAB < minRangeAB) ? minRangeAB : tempAB;

                                    //console.log("Clicked: AB ", mouse.y, msArea.height, tempAB, valAB);

                                    if (root.wb_mode == wb_mode_normal) {
                                        var perGM = mouse.y/msArea.height;
                                        var tempGM = Math.round(perGM * (maxGM - minGM));
                                        valGM = maxGM - ((tempGM > maxRangeGM) ? maxRangeGM : (tempGM < minRangeGM) ? minRangeGM : tempGM);
                                    }

                                    //console.log("Clicked: GM ", mouse.x, msArea.width, tempGM, valGM);

                                    root.onChangeValue()
                                }
                            }

                            //Component.onCompleted: {
                            //    console.debug("Component.onCompleted preValAB=" + preValAB)
                            //    console.debug("Component.onCompleted preValGM=" + preValGM)
                            //    console.debug("Component.onCompleted valAB=" + valAB)
                            //    console.debug("Component.onCompleted valGM=" + valGM)
                            //    //initial reset values
                            //    preValAB = valAB;
                            //    preValGM = valGM;
                            //
                            //    //set initial pointer position
                            //    if (minAB <= valAB && valAB <= maxAB) {
                            //        pointer.x = valToPosAB(valAB);
                            //    }
                            //
                            //    if (root.wb_mode == root.wb_mode_normal) {
                            //        if (minGM <= valGM && valGM <= maxGM) {
                            //            pointer.y = valToPosGM(valGM);
                            //        }
                            //    } else if ((root.wb_mode == root.wb_mode_ia_plus)) {
                            //        var tempGM = Math.round((maxGM - minGM)/2)
                            //        pointer.y = valToPosGM(tempGM);
                            //    }
                            //}
                        }

                        Item {
                            id: titleB

                            anchors {
                                top: parent.top
                                bottom: parent.bottom
                            }
                            width: titleSize

                            LTStylishText {
                                anchors.fill: parent

                                text:qsTr("B")

                                color: palette.titleText
                                type: text_style_wbTuningLabel
                            }
                        }
                    }
                }

                Item {
                    id: titleM

                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    height: titleSize

//                    color: "blue"

                    LTStylishText {
                        anchors.fill: parent

                        text:qsTr("M")

                        color: palette.titleText
                        type: text_style_wbTuningLabel
                    }
                }

                Item {
                    id: valuePanel

                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    height: titleSize

                    LTStylishText {
                        id: valText

                        anchors.fill: parent

                        text: valueWBAdjustTextFormat()

                        textFormat: Text.RichText
                        color: palette.valueText
                        type: text_style_wbTuningText
                    }
                }
            }
        }

        Row {
            id: btnPanel

            anchors {
                top: flickable.bottom
                left: flickable.left
                right: flickable.right
            }
            height: btnCancel.height

            spacing : 2

            LTRectangleButton {
                id: btnOk

                height: 40
                width: (flickable.width - btnPanel.spacing*2)/3
                type: "action"
                buttonText: qsTr("Ok")

                fillColor: palette.backgroundLight

                onClicked: {
                    //save reset values
                    //LTSubFunction.console_debug.out("btnOk preValAB=" + preValAB)
                    //LTSubFunction.console_debug.out("btnOk preValGM=" + preValGM)
                    //LTSubFunction.console_debug.out("btnOk valAB1=" + valAB)
                    //LTSubFunction.console_debug.out("btnOk valGM1=" + valGM)
                    preValAB = valAB;
                    preValGM = valGM;
                    //LTSubFunction.console_debug.out("btnOk valAB2=" + valAB)
                    //LTSubFunction.console_debug.out("btnOk valGM2=" + valGM)

                    root.onOKClicked();
                    root.dismiss();
                }
            }

            LTRectangleButton {
                id: btnReset

                height: 40
                width: (flickable.width - btnPanel.spacing*2)/3
                type: "action"
                buttonText: qsTr("Reset")

                fillColor: palette.backgroundLight

                onClicked: {
                    // リセットボタンは中央値
                    //LTSubFunction.console_debug.out("btnReset preValAB=" + preValAB)
                    //LTSubFunction.console_debug.out("btnReset preValGM=" + preValGM)
                    //LTSubFunction.console_debug.out("btnReset valAB1=" + valAB)
                    //LTSubFunction.console_debug.out("btnReset valGM1=" + valGM)
                    valAB = (maxAB - minAB)/2
                    valGM = (maxGM - minGM)/2
                    //LTSubFunction.console_debug.out("btnReset valAB2=" + valAB)
                    //LTSubFunction.console_debug.out("btnReset valGM2=" + valGM)

                    root.onResetClicked();
                }
            }

            LTRectangleButton {
                id: btnCancel

                height: 40
                width: (flickable.width - btnPanel.spacing*2)/3
                type: "action"
                buttonText: qsTr("Cancel")

                fillColor: palette.backgroundLight

                onClicked: {
                    //LTSubFunction.console_debug.out("btnCancel preValAB=" + preValAB)
                    //LTSubFunction.console_debug.out("btnCancel preValGM=" + preValGM)
                    //LTSubFunction.console_debug.out("btnCancel valAB1=" + valAB)
                    //LTSubFunction.console_debug.out("btnCancel valGM1=" + valGM)
                    valAB = preValAB;
                    valGM = preValGM;
                    //LTSubFunction.console_debug.out("btnCancel valAB2=" + valAB)
                    //LTSubFunction.console_debug.out("btnCancel valGM2=" + valGM)

                    root.onCancelClicked();
                    root.dismiss();
                }
            }
        }
    }

    onVisibleChanged: {
        //LTSubFunction.console_debug.out("onVisibleChanged preValAB=" + preValAB)
        //LTSubFunction.console_debug.out("onVisibleChanged preValGM=" + preValGM)
        //LTSubFunction.console_debug.out("onVisibleChanged valAB=" + valAB)
        //LTSubFunction.console_debug.out("onVisibleChanged valGM=" + valGM)
        if(visible == true) {
            //initial reset values
            preValAB = valAB;
            preValGM = valGM;

            //set initial pointer position
            if (minAB <= valAB && valAB <= maxAB) {
                pointer.x = valToPosAB(valAB);
            }

            if (root.wb_mode == root.wb_mode_normal) {
                if (minGM <= valGM && valGM <= maxGM) {
                    pointer.y = valToPosGM(valGM);
                }
            } else if ((root.wb_mode == root.wb_mode_ia_plus)) {
                var tempGM = Math.round((maxGM - minGM)/2)
                pointer.y = valToPosGM(tempGM);
            }
        }
    }

    function recordingModeSetting() {
        //console.log("recordingModeSetting start");
        if( (deviceAdapter.recordingMode == LT.Utilities.RM_IntelligentAuto) &&
            (deviceAdapter.intelligentAutoMode == LT.Utilities.RM_IA_IntelligentAutoPlus) ){
            titleG.visible = false
            titleM.visible = false
            colorTable.source = "qrc:/images/504_wb_color_s.png"
            popupContent.height = headerHeight + colorTableHeight + titleSize
            root.wb_mode = root.wb_mode_ia_plus
            valAB = deviceAdapter.wbAdjustABSep
        } else {
            titleG.visible = true
            titleM.visible = true
            colorTable.source = "qrc:/images/397_wb_color.png"
            popupContent.height = headerHeight + colorTableHeight + titleSize * 3
            root.wb_mode = root.wb_mode_normal
            valAB = deviceAdapter.wbAdjustAB
        }
        //set initial pointer position
        if (minAB <= valAB && valAB <= maxAB) {
            pointer.x = valToPosAB(valAB);
        }

        if (root.wb_mode == root.wb_mode_normal) {
            if (minGM <= valGM && valGM <= maxGM) {
                pointer.y = valToPosGM(valGM);
            }
        } else if ((root.wb_mode == root.wb_mode_ia_plus)) {
            var tempGM = Math.round((maxGM - minGM)/2)
            pointer.y = valToPosGM(tempGM);
        }
    }

    function valueWBAdjustTextFormat() {
        if(root.wb_mode == root.wb_mode_normal) {
            var horText = (valAB == LT.Utilities.WBAdj_Zero) ? "" : (valAB < LT.Utilities.WBAdj_Zero) ? "A" : "B";
            var horVal = (horText != "") ? Math.abs(valAB-LT.Utilities.WBAdj_Zero) : "";

            var verText = (valGM == LT.Utilities.WBAdj_Zero) ? "" : (valGM < LT.Utilities.WBAdj_Zero) ? "M" : "G";
            var verVal = (verText != "") ? Math.abs(valGM-LT.Utilities.WBAdj_Zero) : "";

            var coma = (horText != "") && (verText != "") ? "," : "";
        	var str = horText + horVal + coma + verText + verVal;

            return str;
        } else if(root.wb_mode == root.wb_mode_ia_plus) {
            var horText = (valAB == LT.Utilities.WBAdj_Zero) ? "" : (valAB < LT.Utilities.WBAdj_Zero) ? "A" : "B";
            var horVal = (horText != "") ? Math.abs(valAB-LT.Utilities.WBAdj_Zero) : "";

            var str = horText + horVal;

            return str;
        }
    }

    /*!
        ポップアップを表示します
     */
    function present(x, y, vX, vY, onOkSelected, onCancelSelected, onResetSelected) {
//        root.x = (x != null) ? x-popupContent.width/2 : Math.round((Screen.width - popupContent.width) / 2);
//        root.y = (y != null) ? y-popupContent.height/2: Math.round((Screen.height - popupContent.height) / 2);

        root.width = popup.width;
        root.height = popup.height;
        var setX = Math.round((Screen.width - popupContent.width) / 2)
        var setY = Math.round((Screen.height - popupContent.height) / 2)

        // Adjust position
        if (x !== null && y !== null && vX !== null && vY !== null) {
            var virX = utilities.availableDesktopX(vX, vY)
            var virY = utilities.availableDesktopY(vX, vY)
            var w = utilities.availableDesktopWidth(vX, vY)
            var h = utilities.availableDesktopHeight(vX, vY)

            if (x+popup.width/2 > virX + w ) {
                setX = virX + w - popup.width
            } else if (x-popup.width/2 < virX) {
                setX = virX
            } else {
                setX = x-popup.width/2
            }

            if (y+popup.height/2 > virY + h ) {
                setY = virY + h - popup.height
            } else if (y-popup.height/2 < virY) {
                setY = virY
            } else {
                setY = y-popup.height/2
            }
        }

        root.x = setX
        root.y = setY

        /*
        //  add clicked event for OK, Cancel and Reset buttons
        if (btnOk.clicked && onOkSelected) {
            btnOk.clicked.connect(function (event, source) {
                onOkSelected(source);
            });
        }
        if (btnCancel.clicked && onCancelSelected) {
            btnCancel.clicked.connect(function (event, source) {
                onOkSelected(source);
            });
        }
        if (btnReset.clicked && onResetSelected) {
            btnReset.clicked.connect(function (event, source) {
                onResetSelected(source);
            });
        }*/

        visible = true;
    }

    function cancel() {
        valAB = preValAB;
        valGM = preValGM;
        //LTSubFunction.console_debug.out("btnCancel valAB2=" + valAB)
        //LTSubFunction.console_debug.out("btnCancel valGM2=" + valGM)

        root.onCancelClicked();
        root.dismiss();
    }

    /*!
        ポップアップを隠します
     */
    function dismiss() {
        visible = false;
        var n = objects.length;
        for (var i = 0; i < n; ++i) {
            //  objects に格納されたオブジェクトを取出して破棄する
            var object = objects.pop();
            object.destroy();
        }
    }

    /*!
        ポップアップに表示する，動的に生成したボタン

        \internal
     */
    property var objects: [ ]

}
