import QtQuick 2.6
import QtQuick.Controls.Basic
import QtQuick.Layouts 1.0
import QtQuick.Window 2.3

import "qrc:/qml"
import LT 1.0 as LT
import "LTSubFunction.js" as LTSubFunction

/*! \qmltype LTGuideLinePopup
    \inqmlmodule LT

    \brief
    GuideLine の状態を選択するポップアップです
 */
Item {
    id: root

    visible: false
    height: 532
    // ivc >> start >> fix UI overlap
//    width: 217
    width: 212
    // ivc << end << fix UI overlap
    //x:root.parent.width-root.width-10//700-(deviceAdapter.afFrame_asp_x*3)
    //y:120
    z:30

    signal guideline1ColorChanged(variant value)
    signal guideline2ColorChanged(variant value)
    signal guideline3ColorChanged(variant value)
    signal guideline4ColorChanged(variant value)
    signal guideline1PosChanged(variant value)
    signal guideline2PosChanged(variant value)
    signal guideline3PosChanged(variant value)
    signal guideline4PosChanged(variant value)

    MouseArea {
       anchors.fill: parent
       onClicked: {
           //visible=false
       }
    }

    property QtObject linecolordialog

    function dismiss() {
        if(utilities.isMac()) {
            linecolordialog2.visible = false
        } else {
            if(linecolordialog != null) {
                if(linecolordialog.visible == true) {
                    linecolordialog.dismiss()
                }
            }
        }
        visible = false;
    }

    function showDialog(arg) {
        LTSubFunction.console_debug.out("gridPopup showDialog")
        if(utilities.isMac()) {
            if((arg!=null)&&(arg)) {
                linecolordialog2.visible = true
            }
        } else {
            var component = Qt.createComponent("LTCustomColorDialog.qml")
            if (component.status === Component.Error) {
                console.log("Err createComponent LTCustomColorDialog: " + component.errorString())
            }
            linecolordialog = null
            if (component.status == Component.Ready) {
                linecolordialog = component.createObject(root);
                linecolordialog.color = lvGuideLine_color
                linecolordialog.onColorChanged.connect(function() {
                    lvGuideLine_color=linecolordialog.color
                });
                if((arg!=null)&&(arg)) {
                    linecolordialog.visible = true
                }
            } else {
                component.onStatusChanged = function(status) {
                    if (status == Component.Ready) {
                        linecolordialog = component.createObject(root);
                        linecolordialog.color = lvGuideLine_color
                        linecolordialog.onColorChanged.connect(function() {
                            lvGuideLine_color=linecolordialog.color
                        });
                        if((arg!=null)&&(arg)) {
                            linecolordialog.visible = true
                        }
                    }
                }
            }
        }
    }

    /*
        背景

        ボタンを表示する領域の外部全体を暗くして，マウス操作に反応しないようにします．
        また，クリックされると選択パネルを閉じます．
     */
    Rectangle {
        anchors {
            fill: parent
        }
        // ivc >> start >> fix UI overlap
        id: back
        // ivc << end << fix UI overlap
        color: "#000000"
        border.color: "#d8d8d8"
        Column{
            x:1
            y:1
            //////////////////////////////////////////////////// 画面ここから ////////////////////////////////////////////////////
            //////////////////////////////////////////////////// タイトル ////////////////////////////////////////////////////
            Rectangle {
                // ivc >> start >> fix UI overlap
                //width: 215
                width: back.width - 2
                // ivc << end << fix UI overlap
                height: 39
                color: "#000000"
                border.color: "#202022"

                LTStylishText {
                    id: text1
                    x: 14
                    //y: 10
                    anchors.verticalCenter: parent.verticalCenter

                    type: text_style_lvItemPopupTitle
                    text: qsTr("guideline")
                    visible: true
                }
                /*
                    ExitButton
                 */
                LTRectangleButton {
                    id: exitbutton
                    x: 185
                    y: 10
                    width: 20
                    height: 20
                    mainImg.sourceSize.width: 12
                    mainImg.sourceSize.height: 12
                    type: "action"
                    source: "qrc:/images/exitbutton.svg"
                    enabled: true
                    visible: true

                    logCol: ltLog
                    logScrTagID: LT.TagDef.RTScr_Usage_LiveView_GuidelineClose
                    logFile: "exitbutton"

                    onClicked: {
                        dismiss()
                    }
                }
            }
            //////////////////////////////////////////////////// 水平方向１ ////////////////////////////////////////////////////
            Rectangle {
                id: diagonal_id
                visible:true
                // ivc >> start >> fix UI overlap
                //width: parent.width
                width: back.width - 2
                // ivc << end << fix UI overlap
                height: 84
                color: "#000000"
                border.color: "#202022"
                CheckBox {
                    id: checkBox
                    x: 9
                    y: 7
                    width: 12
                    height: 12
                    scale: 0.6
                    checked: lvGuideLine_horizontal1_on_off
                    onCheckedChanged: {
                        lvGuideLine_horizontal1_on_off=checked

                        ltLog.log(LT.TagDef.RecLvl_Info,
                                  LT.TagDef.RTScr_Usage_LiveView_GuidelineVer1ChkBox,
                                  "LTGuidelinePopup Vertical1ChkBox changed",
                                  checked)
                    }
                    onClicked: {
                        ltLog.log(LT.TagDef.RecLvl_Info,
                                  LT.TagDef.RTScr_Usage_LiveView_GuidelineVer1ChkBox,
                                  "LTGuidelinePopup Vertical1ChkBox clicked",
                                  checked)
                    }
                }
                LTStylishText {
                    id: text10
                    x: 38
                    y: 6

                    type: text_style_gLinePopup12
                    text: qsTr("Vertical 1")
                    visible: true
                }
                // 左ボタン
                LTRoundButton {
                    x:14; y:30;
                    source: "qrc:/images/a_l_left.svg"
                    diameter: 22
                    fillColor: "#292b2d"
                    mainImg.sourceSize.width: 22
                    mainImg.sourceSize.height: 22
                    onClicked: {
                        if(lvGuideLine_horizontal1_pos>0)
                            lvGuideLine_horizontal1_pos--

                        ltLog.log(LT.TagDef.RecLvl_Info,
                                  LT.TagDef.RTScr_Usage_LiveView_GuidelineVer1Decrease,
                                  "LTGuidelinePopup Vertical1Decrease clicked",
                                  lvGuideLine_horizontal1_pos)
                    }
                }
                // 右ボタン
                LTRoundButton {
                    x:178; y:30;
                    source: "qrc:/images/a_l_right.svg"
                    diameter: 22
                    fillColor: "#292b2d"
                    mainImg.sourceSize.width: 22
                    mainImg.sourceSize.height: 22
                    onClicked: {
                        if(lvGuideLine_horizontal1_pos<100)
                            lvGuideLine_horizontal1_pos++
                        ltLog.log(LT.TagDef.RecLvl_Info,
                                  LT.TagDef.RTScr_Usage_LiveView_GuidelineVer1Increase,
                                  "LTGuidelinePopup Vertical1Increase clicked",
                                  lvGuideLine_horizontal1_pos)
                    }
                }
                LTStylishText {
                    x: parent.width/2 - 26
                    y: 26
                    property string testwk:lvGuideLine_horizontal1_pos

                    type: text_style_gridPopup20
                    text: qsTr(testwk+"%")
                    visible: true
                }
                Slider {
                    id: control1
                    value : (lvGuideLine_horizontal1_pos)/100
                    x:8
                    y:50
                    background: Rectangle {
                        id: background1
                        x: control1.leftPadding
                        y: control1.topPadding + control1.availableHeight / 2 - height / 2
                        implicitWidth: 190
                        implicitHeight: 4
                        width: control1.availableWidth
                        height: implicitHeight
                        radius: 2
                        color: "#525256"
                        Rectangle {
                            x: control1.visualPosition * parent.width - width/2
                            width: 3
                            height: parent.height
                            // USBTHRV100-72 メモリ、▲とも R,G,B: 255,204,0 でお願い致します。
                            color: Qt.rgba(255, 204, 0);
                            radius: 2
                        }
                    }
                    handle: Rectangle {
                        id:handle1
                        x: control1.leftPadding + (control1.visualPosition * control1.availableWidth) - width/2
                        y: control1.topPadding + control1.availableHeight/2 - height/2
                        implicitWidth: 16
                        implicitHeight: 20
                        visible: false
                    }
                    onValueChanged: {
                        lvGuideLine_horizontal1_pos=value*100

                        ltLog.log(LT.TagDef.RecLvl_Info,
                                  LT.TagDef.RTScr_Usage_LiveView_GuidelineVer1Slider,
                                  "LTGuidelinePopup Vertical1Slider changed",
                                  lvGuideLine_horizontal1_pos)
                    }
                }
                Canvas {
                    id:canvas1
                    x: control1.x + control1.leftPadding + (control1.visualPosition * control1.availableWidth) - width/2
                    y: control1.y + control1.topPadding + control1.availableHeight/2 + background1.height/2 + 1
                    implicitWidth: 16
                    implicitHeight: 10
                    onPaint: {
                        var ctx = getContext("2d");
                        // USBTHRV100-72 メモリ、▲とも R,G,B: 255,204,0 でお願い致します。
                        ctx.fillStyle = Qt.rgba(255, 204, 0);
                        ctx.beginPath();
                        ctx.moveTo(5,10);
                        ctx.lineTo(5,6);
                        ctx.lineTo(8,0);
                        ctx.lineTo(10,6);
                        ctx.lineTo(10,10);
                        ctx.lineTo(5,10);
                        ctx.closePath();
                        ctx.fill();
                    }
                }
            }
            //////////////////////////////////////////////////// 水平方向２ ////////////////////////////////////////////////////
            Rectangle {
                id: diagonal2_id
                visible:true
                // ivc >> start >> fix UI overlap
                //width: parent.width
                width: back.width - 2
                // ivc << end << fix UI overlap
                height: 84
                color: "#000000"
                border.color: "#202022"
                CheckBox {
                    id: checkBox1
                    x: 9
                    y: 7
                    width: 12
                    height: 12
                    scale: 0.6
                    checked: lvGuideLine_horizontal2_on_off
                    onCheckedChanged: {
                        lvGuideLine_horizontal2_on_off=checked

                        ltLog.log(LT.TagDef.RecLvl_Info,
                                  LT.TagDef.RTScr_Usage_LiveView_GuidelineVer2ChkBox,
                                  "LTGuidelinePopup Vertical2ChkBox changed",
                                  checked)
                    }

                    onClicked: {
                        ltLog.log(LT.TagDef.RecLvl_Info,
                                  LT.TagDef.RTScr_Usage_LiveView_GuidelineVer2ChkBox,
                                  "LTGuidelinePopup Vertical2ChkBox clicked",
                                  checked)
                    }
                }
                LTStylishText {
                    id: text101
                    x: 38
                    y: 6

                    type: text_style_gLinePopup12
                    text: qsTr("Vertical 2")
                    visible: true
                }
                // 左ボタン
                LTRoundButton {
                    x:14; y:30;
                    source: "qrc:/images/a_l_left.svg"
                    diameter: 22
                    fillColor: "#292b2d"
                    mainImg.sourceSize.width: 22
                    mainImg.sourceSize.height: 22
                    onClicked: {
                        if(lvGuideLine_horizontal2_pos>0)
                            lvGuideLine_horizontal2_pos--

                        ltLog.log(LT.TagDef.RecLvl_Info,
                                  LT.TagDef.RTScr_Usage_LiveView_GuidelineVer2Decrease,
                                  "LTGuidelinePopup Vertical2Decrease clicked",
                                  lvGuideLine_horizontal2_pos)
                    }
                }
                // 右ボタン
                LTRoundButton {
                    x:178; y:30;
                    source: "qrc:/images/a_l_right.svg"
                    diameter: 22
                    fillColor: "#292b2d"
                    mainImg.sourceSize.width: 22
                    mainImg.sourceSize.height: 22
                    onClicked: {
                        if(lvGuideLine_horizontal2_pos<100)
                            lvGuideLine_horizontal2_pos++

                        ltLog.log(LT.TagDef.RecLvl_Info,
                                  LT.TagDef.RTScr_Usage_LiveView_GuidelineVer2Increase,
                                  "LTGuidelinePopup Vertical2Increase clicked",
                                  lvGuideLine_horizontal2_pos)
                    }
                }
                LTStylishText {
                    x: parent.width/2-26
                    y: 26
                    property string testwk:lvGuideLine_horizontal2_pos

                    type: text_style_gridPopup20
                    text: qsTr(testwk+"%")
                    visible: true
                }

                Slider {
                    id: control2
                    value : lvGuideLine_horizontal2_pos/100
                    x:8
                    y:50
                    background: Rectangle {
                        id: background2
                        x: control2.leftPadding
                        y: control2.topPadding + control2.availableHeight / 2 - height / 2
                        implicitWidth: 190
                        implicitHeight: 4
                        width: control2.availableWidth
                        height: implicitHeight
                        radius: 2
                        color: "#525256"
                        Rectangle {
                            x: control2.visualPosition * parent.width - width/2
                            width:3
                            height: parent.height
                            // USBTHRV100-72 メモリ、▲とも R,G,B: 255,204,0 でお願い致します。
                            color: Qt.rgba(255, 204, 0);
                            radius: 2
                        }
                    }
                    handle: Rectangle {
                        id:handle2
                        x: control2.leftPadding + (control2.visualPosition * control2.availableWidth) - width/2
                        y: control2.topPadding + control2.availableHeight/2 - height/2
                        implicitWidth: 16
                        implicitHeight: 20
                        visible: false
                    }
                    onValueChanged: {
                        lvGuideLine_horizontal2_pos=value*100

                        ltLog.log(LT.TagDef.RecLvl_Info,
                                  LT.TagDef.RTScr_Usage_LiveView_GuidelineVer2Slider,
                                  "LTGuidelinePopup Vertical2Slider changed",
                                  lvGuideLine_horizontal2_pos)
                    }
                }
                Canvas {
                    id:canvas2
                    x: control2.x + control2.leftPadding + (control2.visualPosition * control2.availableWidth) - width/2
                    y: control2.y + control2.topPadding + control2.availableHeight/2 + background2.height/2 + 1
                    implicitWidth: 16
                    implicitHeight: 10
                    onPaint: {
                        var ctx = getContext("2d");
                        // USBTHRV100-72 メモリ、▲とも R,G,B: 255,204,0 でお願い致します。
                        ctx.fillStyle = Qt.rgba(255, 204, 0);
                        ctx.beginPath();
                        ctx.moveTo(5,10);
                        ctx.lineTo(5,6);
                        ctx.lineTo(8,0);
                        ctx.lineTo(10,6);
                        ctx.lineTo(10,10);
                        ctx.lineTo(5,10);
                        ctx.closePath();
                        ctx.fill();
                    }
                }
            }
            //////////////////////////////////////////////////// 垂直方向 ////////////////////////////////////////////////////
            Rectangle{
                id:diagonal301_id
                // ivc >> start >> fix UI overlap
                //width: 212
                width: back.width - 2
                // ivc << end << fix UI overlap
                height: 229
                Row{
                    //////////////////////////////////////////////////// 垂直方向１ ////////////////////////////////////////////////////
                    Rectangle {
                        id: diagonal3_id
                        visible:true
                        width: diagonal301_id.width/2
                        height: 231
                        color: "#000000"
                        border.color: "#202022"
                        CheckBox {
                            id: checkBox3
                            x: 9
                            y: 7
                            width: 12
                            height: 12
                            scale: 0.6
                            checked: lvGuideLine_Vertical1_on_off
                            onCheckedChanged: {
                                lvGuideLine_Vertical1_on_off=checked

                                ltLog.log(LT.TagDef.RecLvl_Info,
                                          LT.TagDef.RTScr_Usage_LiveView_GuidelineHor1ChkBox,
                                          "LTGuidelinePopup Horizontal1ChkBox changed",
                                          checked)
                            }
                            onClicked: {
                                ltLog.log(LT.TagDef.RecLvl_Info,
                                          LT.TagDef.RTScr_Usage_LiveView_GuidelineHor1ChkBox,
                                          "LTGuidelinePopup Horizontal1ChkBox clicked",
                                          checked)
                            }
                        }
                        LTStylishText {
                            id: text103
                            x: 38
                            y: 6

                            type: text_style_gLinePopup12
                            text: qsTr("Holizon 1")
                            visible: true
                        }
                        // 上ボタン
                        LTRoundButton {
                            x:60; y:36;
                            source: "qrc:/images/a_l_up.svg"
                            diameter: 22
                            fillColor: "#292b2d"
                            mainImg.sourceSize.width: 22
                            mainImg.sourceSize.height: 22
                            onClicked: {
                                if(lvGuideLine_Vertical1_pos>0)
                                    lvGuideLine_Vertical1_pos--

                                ltLog.log(LT.TagDef.RecLvl_Info,
                                          LT.TagDef.RTScr_Usage_LiveView_GuidelineHor1Decrease,
                                          "LTGuidelinePopup Horizontal1Decrease clicked",
                                          lvGuideLine_Vertical1_pos)
                            }
                        }
                        // 下ボタン
                        LTRoundButton {
                            x:60; y:190;
                            source: "qrc:/images/a_l_down.svg"
                            diameter: 22
                            fillColor: "#292b2d"
                            mainImg.sourceSize.width: 22
                            mainImg.sourceSize.height: 22
                            onClicked: {
                                if(lvGuideLine_Vertical1_pos<100)
                                    lvGuideLine_Vertical1_pos++

                                ltLog.log(LT.TagDef.RecLvl_Info,
                                          LT.TagDef.RTScr_Usage_LiveView_GuidelineHor1Increase,
                                          "LTGuidelinePopup Horizontal1Increase clicked",
                                          lvGuideLine_Vertical1_pos)
                            }
                        }
                        LTStylishText {
                            x: 48
                            y: parent.height/2-12
                            property string testwk:lvGuideLine_Vertical1_pos

                            type: text_style_gridPopup20
                            text: qsTr(testwk+"%")
                            visible: true
                        }
                        Slider {
                            id: control3
                            value : lvGuideLine_Vertical1_pos/100
                            x:-64
                            y:105
                            rotation: 90
                            background: Rectangle {
                                id: background3
                                x: control3.leftPadding
                                y: control3.topPadding + control3.availableHeight / 2 - height / 2
                                implicitWidth: 190
                                implicitHeight: 4
                                width: control3.availableWidth
                                height: implicitHeight
                                radius: 2
                                color: "#525256"
                                Rectangle {
                                    x:control3.visualPosition * parent.width - width/2
                                    width:3
                                    height: parent.height
                                    // USBTHRV100-72 メモリ、▲とも R,G,B: 255,204,0 でお願い致します。
                                    color: Qt.rgba(255, 204, 0);
                                    radius: 2
                                }
                            }
                            handle: Rectangle {
                                id:handle3
                                x: control3.leftPadding + (control3.visualPosition * control3.availableWidth) - width/2
                                y: control3.topPadding + control3.availableHeight/2 - height/2
                                implicitWidth: 16
                                implicitHeight: 20
                                visible: false
                            }
                            onValueChanged: {
                                lvGuideLine_Vertical1_pos=value*100

                                ltLog.log(LT.TagDef.RecLvl_Info,
                                          LT.TagDef.RTScr_Usage_LiveView_GuidelineHor1Slider,
                                          "LTGuidelinePopup Horizontal1Slider changed",
                                          lvGuideLine_Vertical1_pos)
                            }
                        }
                        Canvas {
                            id:canvas3
                            x: control3.x + (control3.width/2) - background3.height/2 - width - 1
                            y: control3.y - (control3.width/2) + (control3.height/2) + control3.leftPadding + (control3.visualPosition * control3.availableWidth) - height/2
                            implicitWidth: 20
                            implicitHeight: 16
                            onPaint: {
                                var ctx = getContext("2d");
                                // USBTHRV100-72 メモリ、▲とも R,G,B: 255,204,0 でお願い致します。
                                ctx.fillStyle = Qt.rgba(255, 204, 0);
                                ctx.beginPath();
                                ctx.lineTo(9,6);
                                ctx.lineTo(14,6);
                                ctx.lineTo(20,8);
                                ctx.lineTo(14,11);
                                ctx.lineTo(9,11);
                                ctx.lineTo(9,6);
                                ctx.closePath();
                                ctx.fill();
                            }
                        }
                    }
                    //////////////////////////////////////////////////// 垂直方向２ ////////////////////////////////////////////////////
                    Rectangle {
                        id: diagonal4_id
                        visible:true
                        width: diagonal301_id.width/2
                        height: 231
                        x:parent.width/2
                        color: "#000000"
                        border.color: "#202022"
                        CheckBox {
                            id: checkBox4
                            x: 9
                            y: 7
                            width: 12
                            height: 12
                            scale: 0.6
                            checked: lvGuideLine_Vertical2_on_off
                            onCheckedChanged: {
                                lvGuideLine_Vertical2_on_off=checked

                                ltLog.log(LT.TagDef.RecLvl_Info,
                                            LT.TagDef.RTScr_Usage_LiveView_GuidelineHor2ChkBox,
                                            "LTGuidelinePopup Horizontal2ChkBox changed",
                                            checked)
                            }
                            onClicked: {
                                ltLog.log(LT.TagDef.RecLvl_Info,
                                            LT.TagDef.RTScr_Usage_LiveView_GuidelineHor2ChkBox,
                                            "LTGuidelinePopup Horizontal2ChkBox clicked",
                                            checked)
                            }
                        }
                        LTStylishText {
                            id: text104
                            x: 38
                            y: 6

                            type: text_style_gLinePopup12
                            text: qsTr("Holizon 2")
                            visible: true
                        }
                        // 上ボタン
                        LTRoundButton {
                            x:60; y:36;
                            source: "qrc:/images/a_l_up.svg"
                            diameter: 22
                            fillColor: "#292b2d"
                            mainImg.sourceSize.width: 22
                            mainImg.sourceSize.height: 22
                            onClicked: {
                                if(lvGuideLine_Vertical2_pos>0)
                                    lvGuideLine_Vertical2_pos--

                                    ltLog.log(LT.TagDef.RecLvl_Info,
                                                LT.TagDef.RTScr_Usage_LiveView_GuidelineHor2Decrease,
                                                "LTGuidelinePopup Horizontal2Decrease clicked",
                                                lvGuideLine_Vertical2_pos)
                            }
                        }
                        // 下ボタン
                        LTRoundButton {
                            x:60; y:190;
                            source: "qrc:/images/a_l_down.svg"
                            diameter: 22
                            fillColor: "#292b2d"
                            mainImg.sourceSize.width: 22
                            mainImg.sourceSize.height: 22
                            onClicked: {
                                if(lvGuideLine_Vertical2_pos<100)
                                    lvGuideLine_Vertical2_pos++

                                ltLog.log(LT.TagDef.RecLvl_Info,
                                            LT.TagDef.RTScr_Usage_LiveView_GuidelineHor2Increase,
                                            "LTGuidelinePopup Horizontal2Increase clicked",
                                            lvGuideLine_Vertical2_pos)
                            }
                        }
                        LTStylishText {
                            x: 48
                            y: parent.height/2-12
                            property string testwk:lvGuideLine_Vertical2_pos

                            type: text_style_gridPopup20
                            text: qsTr(testwk+"%")
                            visible: true
                        }
                        Slider {
                            id: control4
                            value : lvGuideLine_Vertical2_pos/100
                            x:-64
                            y:105
                            rotation: 90
                            background: Rectangle {
                                id: background4
                                x: control4.leftPadding
                                y: control4.topPadding + control4.availableHeight / 2 - height / 2
                                implicitWidth: 190
                                implicitHeight: 4
                                width: control4.availableWidth
                                height: implicitHeight
                                radius: 2
                                color: "#525256"
                                Rectangle {
                                    x:control4.visualPosition * parent.width - width/2
                                    width:4
                                    height: parent.height
                                    // USBTHRV100-72 メモリ、▲とも R,G,B: 255,204,0 でお願い致します。
                                    color: Qt.rgba(255, 204, 0);
                                    radius: 2
                                }
                            }
                            handle: Rectangle {
                                id:handle4
                                x: control4.leftPadding + (control4.visualPosition * control4.availableWidth) - width/2
                                y: control4.topPadding + control4.availableHeight/2 - height/2
                                implicitWidth: 16
                                implicitHeight: 20
                                visible: false
                            }
                            onValueChanged: {
                                lvGuideLine_Vertical2_pos=value*100

                                ltLog.log(LT.TagDef.RecLvl_Info,
                                          LT.TagDef.RTScr_Usage_LiveView_GuidelineHor2Slider,
                                          "LTGuidelinePopup Horizontal2Slider changed",
                                          lvGuideLine_Vertical2_pos)
                            }
                        }
                        Canvas {
                            id:canvas4
                            x: control4.x + (control4.width/2) - background4.height/2 - width - 1
                            y: control4.y - (control4.width/2) + (control4.height/2) + control4.leftPadding + (control4.visualPosition * control4.availableWidth) - height/2
                            implicitWidth: 20
                            implicitHeight: 16
                            onPaint: {
                                var ctx = getContext("2d");
                                // USBTHRV100-72 メモリ、▲とも R,G,B: 255,204,0 でお願い致します。
                                ctx.fillStyle = Qt.rgba(255, 204, 0);
                                ctx.beginPath();
                                ctx.lineTo(9,6);
                                ctx.lineTo(14,6);
                                ctx.lineTo(20,8);
                                ctx.lineTo(14,11);
                                ctx.lineTo(9,11);
                                ctx.lineTo(9,6);
                                ctx.closePath();
                                ctx.fill();
                            }
                        }
                    }
                }
            }
            //////////////////////////////////////////////////// 太さ ////////////////////////////////////////////////////
            Rectangle {
                id: thickness_id
                // ivc >> start >> fix UI overlap
                //width: parent.width
                width: back.width - 2
                // ivc << end << fix UI overlap
                height: 65
                color: "#000000"
                border.color: "#202022"
                LTStylishText {
                    id: text8
                    x: 14
                    y: 6

                    type: text_style_gLinePopup10
                    text: qsTr("Thickness")
                    visible: true
                }
                Slider {
                    id: control5
                    value: lvGuideLine_thickness
                    x:14
                    y:20
                    from: 1
                    to: 10
                    background: Rectangle {
                        id: background5
                        x: control5.leftPadding
                        y: control5.topPadding + control5.availableHeight / 2 - height / 2
                        implicitWidth: 150
                        implicitHeight: 4
                        width: control5.availableWidth
                        height: implicitHeight
                        radius: 2
                        color: "#525256"
                        Rectangle {
                            width: control5.visualPosition * parent.width
                            height: parent.height
                            // USBTHRV100-72 メモリ、▲とも R,G,B: 255,204,0 でお願い致します。
                            color: Qt.rgba(255, 204, 0);
                            radius: 2
                        }
                    }
                    handle: Rectangle {
                        id:handle5
                        x: control5.leftPadding + (control5.visualPosition * control5.availableWidth) - width/2
                        y: control5.topPadding + control5.availableHeight/2 - height/2
                        implicitWidth: 16
                        implicitHeight: 20
                        visible: false
                    }
                    onValueChanged: {
                        lvGuideLine_thickness=value

//                        ltLog.log(LT.TagDef.RecLvl_Info,
//                                  LT.TagDef.RTScr_Usage_LiveView_GuidelineThckSlider,
//                                  "LTGuidelinePopup ThicknessSlider changed",
//                                  lvGuideLine_thickness)
                    }
                }
                Canvas {
                    id:canvas5
                    x: control5.x + control5.leftPadding + (control5.visualPosition * control5.availableWidth) - width/2
                    y: control5.y + control5.topPadding + control5.availableHeight/2 + background5.height/2 + 1
                    implicitWidth: 16
                    implicitHeight: 10
                    onPaint: {
                        var ctx = getContext("2d");
                        // USBTHRV100-72 メモリ、▲とも R,G,B: 255,204,0 でお願い致します。
                        ctx.fillStyle = Qt.rgba(255, 204, 0);
                        ctx.beginPath();
                        ctx.moveTo(5,10);
                        ctx.lineTo(5,6);
                        ctx.lineTo(8,0);
                        ctx.lineTo(10,6);
                        ctx.lineTo(10,10);
                        ctx.lineTo(5,10);
                        ctx.closePath();
                        ctx.fill();
                    }
                }

                LTStylishText {
                    // ivc mod >> start >> USBTHRV170-28
//                    x: 170
                    x: 161
                    // ivc mod << end << USBTHRV170-28
                    y: 20
                    property string testwk:lvGuideLine_thickness

                    type: text_style_gridPopup20
                    text: qsTr(testwk)
                    visible: true
                }
                // 上ボタン
                LTRoundButton {
                    x:186; y:8;
                    source: "qrc:/images/a_l_up.svg"
                    diameter: 20
                    fillColor: "#292b2d"
                    mainImg.sourceSize.width: 20
                    mainImg.sourceSize.height: 20
                    onClicked: {
                        if(lvGuideLine_thickness<10)
                            lvGuideLine_thickness++

                        ltLog.log(LT.TagDef.RecLvl_Info,
                                  LT.TagDef.RTScr_Usage_LiveView_GuidelineThckIncrease,
                                  "LTGuidelinePopup ThicknessIncrease clicked",
                                  lvGuideLine_thickness)
                    }
                }
                // 下ボタン
                LTRoundButton {
                    x:186; y:39;
                    source: "qrc:/images/a_l_down.svg"
                    diameter: 20
                    fillColor: "#292b2d"
                    mainImg.sourceSize.width: 20
                    mainImg.sourceSize.height: 20
                    onClicked: {
                        if(lvGuideLine_thickness>1)
                        lvGuideLine_thickness--

                        ltLog.log(LT.TagDef.RecLvl_Info,
                                  LT.TagDef.RTScr_Usage_LiveView_GuidelineThckDecrease,
                                  "LTGuidelinePopup ThicknessDecrease clicked",
                                  lvGuideLine_thickness)
                    }
                }
            }
            //////////////////////////////////////////////////// 色 ////////////////////////////////////////////////////
            Rectangle {
                id: color_set_id
                // ivc >> start >> fix UI overlap
                //width: parent.width
                width: back.width - 2
                // ivc << end << fix UI overlap
                height: 29
                color: "#000000"
                border.color: "#202022"
                // 色選択ボタン
                LTRectangleButton {
                    id: colorbutton
                    anchors.fill: color_set_id

                    logCol: ltLog
                    logScrTagID: LT.TagDef.RTScr_Usage_LiveView_GuidelineColor
                    logFile: "colorbutton"

                    onClicked: {
                        //linecolordialog.visible = true
                        showDialog(true)
                    }
                }
                // 色表示ボックス
                Rectangle {
                    x: 7
                    y: 5
                    width: 28
                    height: 20
                    color: lvGuideLine_color
                }
                // 色表示
                LTStylishText {
                    x: 50
                    y: 0
                    height: parent.height
                    color: lvGuideLine_color

                    type: text_style_gLinePopup12
                    text: qsTr("Color")
                    visible: true
                }
            }
        }
        //////////////////////////////////////////////////// 画面ここまで ////////////////////////////////////////////////////

        LTCustomColorDialog {
            id: linecolordialog2
            color: lvGuideLine_color
            onColorChanged: {
                lvGuideLine_color=linecolordialog2.color
            }
            onAccepted: {
                ltLog.log(LT.TagDef.RecLvl_Info,
                          LT.TagDef.RTScr_Usage_LiveView_GuidelineColor,
                          "LTGuidelinePopup Color accepted",
                          color)
            }
            onRejected: {
                ltLog.log(LT.TagDef.RecLvl_Info,
                          LT.TagDef.RTScr_Usage_LiveView_GuidelineColor,
                          "LTGuidelinePopup Color rejected",
                          color)
            }
        }
    }
}
