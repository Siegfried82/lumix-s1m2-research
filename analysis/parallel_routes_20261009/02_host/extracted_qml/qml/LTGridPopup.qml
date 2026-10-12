import QtQuick 2.6
import QtQuick.Controls.Basic 2.0
import QtQuick.Layouts 1.0
import QtQuick.Window 2.3

import "qrc:/qml"
import LT 1.0 as LT
import "LTSubFunction.js" as LTSubFunction

/*! \qmltype LTGridPopup
    \inqmlmodule LT

    \brief
    GuideLine の状態を選択するポップアップです
 */
Item {
    id: root

    visible: false
    width: 212
//    height: 385+lvGDraw_custom_on_off
    height: 140+lvGDraw_custom_on_off*255
//    x:root.parent.width-root.width-10//840-(deviceAdapter.afFrame_asp_x*3)
//    y:150
    signal grid1ColorChanged(variant value)
    signal grid1SizeChanged(variant value)
    signal grid2SizeChanged(variant value)
    signal grid3SizeChanged(variant value)
    signal grid4SizeChanged(variant value)

    property QtObject line1colordialog: null

    MouseArea {
       anchors.fill: parent
       onClicked: {
           //visible=false
       }
    }

    function dismiss() {
        if(!utilities.isMac()) {
            if(line1colordialog != null) {
                if(line1colordialog.visible == true) {
                    line1colordialog.dismiss()
                }
            }
        } else {
            line2colordialog.visible = false
        }
        visible = false;
    }

    Component.onCompleted: {
        div_3_3_button.checked = lvGDraw_3_3_on_off
        div_2_2_button.checked = lvGDraw_2_2_diagonal_on_off
        customize_button.checked = lvGDraw_custom_on_off

        customize_button.customize_on_off_changed()
    }

    function showDialog(arg) {
        LTSubFunction.console_debug.out("gridPopup showDialog start")
        if(utilities.isMac()) {
            if((arg!=null)&&(arg)) {
                line2colordialog.visible = true
            }
        } else {
            var component = Qt.createComponent("LTCustomColorDialog.qml")
            if (component.status === Component.Error) {
                console.log("Err createComponent LTCustomColorDialog: " + component.errorString())
            }
            line1colordialog = null
            if (component.status == Component.Ready) {
                line1colordialog = component.createObject(null);
                line1colordialog.color = lvGDraw_color
                line1colordialog.onColorChanged.connect(function() {
                    lvGDraw_color=line1colordialog.color
                });
                if((arg!=null)&&(arg)) {
                    line1colordialog.visible = true
                }
            } else {
                component.onStatusChanged = function(status) {
                    if (status == Component.Ready) {
                        line1colordialog = component.createObject(null);
                        line1colordialog.color = lvGDraw_color
                        line1colordialog.onColorChanged.connect(function() {
                            lvGDraw_color=line1colordialog.color
                        });
                        if((arg!=null)&&(arg)) {
                            line1colordialog.visible = true
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
        id: back
        anchors {
            fill: parent
        }
        color: "#000000"
//        opacity: 0.5
        border.color: "#d8d8d8"
        Column{
            x:1
            y:1
            Rectangle {
                width: back.width-2
                height: 39
                color: "#000000"
                border.color: "#202022"

                LTStylishText {
                    id: text1
                    x: 14
                    //y: 10
                    anchors.verticalCenter: parent.verticalCenter

                    type: text_style_lvItemPopupTitle
                    text: qsTr("grid")
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
                    logScrTagID: LT.TagDef.RTScr_Usage_LiveView_GridClose
                    logFile: "exitbutton"

                    onClicked: {
                        dismiss()//root.visible=false
                    }
                }
            }
            /*
                ３×３分割
             */
            LTRectangleButton {
                id: div_3_3_button
                width: back.width-2
                height: 30
                type: "radioWithText"
                buttonText: qsTr("3x3")
                checked: lvGDraw_3_3_on_off

                logCol: ltLog
                logScrTagID: LT.TagDef.RTScr_Usage_LiveView_Grid3x3
                logFile: "div_3_3_button"

                onClicked: {
                    lvGDraw_horizontal_Num = 2
                    lvGDraw_Vertical_Num = 2
                    lvGDraw_thickness = 2
                    lvGDraw_Diagonal_on_off = false

                    div_3_3_button.checked = true
                    div_2_2_button.checked = false
                    customize_button.checked = false

                    lvGDraw_3_3_on_off = true
                    lvGDraw_2_2_diagonal_on_off = false
                    lvGDraw_custom_on_off = false

                    customize_button.customize_on_off_changed()
                }
            }
            /*
                ２×２分割＋対角線
             */
            LTRectangleButton {
                id: div_2_2_button
                width: back.width-2
                height: 29
                type: "radioWithText"
                buttonText: qsTr("2x2")
                checked: lvGDraw_2_2_diagonal_on_off

                logCol: ltLog
                logScrTagID: LT.TagDef.RTScr_Usage_LiveView_Grid2x2Diagonal
                logFile: "div_2_2_button"

                onClicked: {
                    lvGDraw_horizontal_Num = 1
                    lvGDraw_Vertical_Num = 1
                    lvGDraw_thickness = 2
                    lvGDraw_Diagonal_on_off = true

                    div_3_3_button.checked = false
                    div_2_2_button.checked = true
                    customize_button.checked = false

                    lvGDraw_3_3_on_off = false
                    lvGDraw_2_2_diagonal_on_off = true
                    lvGDraw_custom_on_off = false

                    customize_button.customize_on_off_changed()
                }
            }
            /*
                カスタマイズ
             */
            LTRectangleButton {
                id: customize_button
                anchors {
                    left: parent.left
                    right: parent.right
                }
                height: 30
                checked: lvGDraw_custom_on_off
                fillColor: "#292b2d"
                type: "checkableWithImageAndTextLv"

                buttonText: qsTr("Customize")
                checkedImage: checked ? "qrc:/images/button_shrink.svg" : "qrc:/images/button_expand.svg"

                logCol: ltLog
                logScrTagID: LT.TagDef.RTScr_Usage_LiveView_GridCustom
                logFile: "customize_button"

                function customize_on_off_changed() {
                    if(!lvGDraw_custom_on_off){
                        diagonal_id.visible=false
                        color_set_id.visible=false
                        control3.visible=false
                        horizontal_num_id.visible=false
                        vertical_num_id.visible=false
                        thickness_id.visible=false
                        //custom_btn.source = "qrc:/images/a_s_down.svg"
                    }else{
                        diagonal_id.visible=true
                        color_set_id.visible=true
                        control3.visible=true
                        horizontal_num_id.visible=true
                        vertical_num_id.visible=true
                        thickness_id.visible=true
                        //custom_btn.source = "qrc:/images/a_s_up.svg"
                    }
                }

                onClicked: {
                    if(lvGDraw_custom_on_off){
                        lvGDraw_custom_on_off=false
                    }else{
                        div_3_3_button.checked = false
                        div_2_2_button.checked = false

                        lvGDraw_3_3_on_off = false
                        lvGDraw_2_2_diagonal_on_off = false
                        lvGDraw_custom_on_off=true
                    }
                    customize_button.customize_on_off_changed()
                }
            }
            /* 横本数　*/
            Rectangle {
                id: vertical_num_id
                visible:false
                width: back.width-2
                height: 65
                color: "#000000"
                border.color: "#202022"
                LTStylishText {
                    id: text6
                    x: 10
                    y: 6

                    type: text_style_gridPopup10
                    text: qsTr("horizon num")
                    visible: true

                }
                Slider {
                    id: control1
                    value : lvGDraw_Vertical_Num
                    x:8
                    y:20
                    from: 1
                    to: 99
                    background: Rectangle {
                        id: background1
                        x: control1.leftPadding
                        y: control1.topPadding + control1.availableHeight / 2 - height / 2
                        implicitWidth: 150
                        implicitHeight: 4
                        width: control1.availableWidth
                        height: implicitHeight
                        radius: 2
                        color: "#525256"
                        Rectangle {
                            width: control1.visualPosition * parent.width
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
                        lvGDraw_Vertical_Num=value

                        ltLog.log(LT.TagDef.RecLvl_Info,
                                  LT.TagDef.RTScr_Usage_LiveView_GridVerSlider,
                                  "LTGridPopup VerSlider changed",
                                  lvGDraw_Vertical_Num)
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
                LTStylishText {
                    x: 160
                    y: 20

                    type: text_style_gridPopup20
                    text: lvGDraw_Vertical_Num//qsTr(testwk)
                    visible: true
                }
                /*
                    増加ボタン
                 */
                LTRoundButton {
                    x:184
                    y:8
                    source: "qrc:/images/a_l_up.svg"
                    diameter: 20
                    fillColor: "#292b2d"
                    mainImg.sourceSize.width: 20
                    mainImg.sourceSize.height: 20
                    onClicked: {
                        if(lvGDraw_Vertical_Num<99) {
                            lvGDraw_Vertical_Num++
                        }
                        ltLog.log(LT.TagDef.RecLvl_Info,
                                  LT.TagDef.RTScr_Usage_LiveView_GridVerIncrease,
                                  "LTGridPopup VerIncrease clicked",
                                  lvGDraw_Vertical_Num)
                    }
                }
                /*
                    減少ボタン
                 */
                LTRoundButton {
                    x:184; y:39;
                    source: "qrc:/images/a_l_down.svg"
                    diameter: 20
                    fillColor: "#292b2d"
                    mainImg.sourceSize.width: 20
                    mainImg.sourceSize.height: 20
                    onClicked: {
                        if(lvGDraw_Vertical_Num>1) {
                            lvGDraw_Vertical_Num--
                        }
                        ltLog.log(LT.TagDef.RecLvl_Info,
                                  LT.TagDef.RTScr_Usage_LiveView_GridVerDecrease,
                                  "LTGridPopup VerDecrease clicked",
                                  lvGDraw_Vertical_Num)
                    }
                }
            }
            /* 縦本数　*/
            Rectangle {
                id: horizontal_num_id
                visible:false
                width: back.width-2
                height: 65
                color: "#000000"
                border.color: "#202022"
                LTStylishText {
                    id: text7
                    x: 10
                    y: 6

                    type: text_style_gridPopup10
                    text: qsTr("vertical num")
                    visible: true
                }
                Slider {
                    id: control2
                    value: lvGDraw_horizontal_Num
                    x:8
                    y:20
                    from: 1
                    to: 99
                    background: Rectangle {
                        id: background2
                        x: control2.leftPadding
                        y: control2.topPadding + control2.availableHeight / 2 - height / 2
                        implicitWidth: 150
                        implicitHeight: 4
                        width: control2.availableWidth
                        height: implicitHeight
                        radius: 2
                        color: "#525256"
                        Rectangle {
                            width: control2.visualPosition * parent.width
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
                        lvGDraw_horizontal_Num=value

                        ltLog.log(LT.TagDef.RecLvl_Info,
                                LT.TagDef.RTScr_Usage_LiveView_GridHorSlider,
                                "LTGridPopup HorSlider changed",
                                lvGDraw_horizontal_Num)
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
                LTStylishText {
                    x: 160
                    y: 20

                    type: text_style_gridPopup20
                    text: lvGDraw_horizontal_Num//qsTr(testwk)
                    visible: true
                }
                /*
                    増加ボタン
                 */
                LTRoundButton {
                    x:184; y:8;
                    source: "qrc:/images/a_l_up.svg"
                    diameter: 20
                    fillColor: "#292b2d"
                    mainImg.sourceSize.width: 20
                    mainImg.sourceSize.height: 20
                    onClicked: {
                        if(lvGDraw_horizontal_Num<99) {
                            lvGDraw_horizontal_Num++
                        }

                        ltLog.log(LT.TagDef.RecLvl_Info,
                                                  LT.TagDef.RTScr_Usage_LiveView_GridHorIncrease,
                                                  "LTGridPopup HorIncrease clicked",
                                                  lvGDraw_horizontal_Num)
                    }
                }
                /*
                    減少ボタン
                 */
                LTRoundButton {
                    x:184
                    y:39
                    source: "qrc:/images/a_l_down.svg"
                    diameter: 20
                    fillColor: "#292b2d"
                    mainImg.sourceSize.width: 20
                    mainImg.sourceSize.height: 20
                    onClicked: {
                        if(lvGDraw_horizontal_Num>1) {
                            lvGDraw_horizontal_Num--
                        }

                        ltLog.log(LT.TagDef.RecLvl_Info,
                                                  LT.TagDef.RTScr_Usage_LiveView_GridHorDecrease,
                                                  "LTGridPopup HorDecrease clicked",
                                                  lvGDraw_horizontal_Num)
                    }
                }
            }
            /* 太さ　*/
            Rectangle {
                id: thickness_id
                visible:false
                width: back.width-2
                height: 65
                color: "#000000"
                border.color: "#202022"
                LTStylishText {
                    id: text8
                    x: 10
                    y: 6

                    type: text_style_gridPopup10
                    text: qsTr("thickness")
                    visible: true
                }
                Slider {
                    id: control3
                    value: lvGDraw_thickness
                    x:8
                    y:20
                    from: 1
                    to: 10
                    background: Rectangle {
                        id: background3
                        x: control3.leftPadding
                        y: control3.topPadding + control3.availableHeight / 2 - height / 2
                        implicitWidth: 150
                        implicitHeight: 4
                        width: control3.availableWidth
                        height: implicitHeight
                        radius: 2
                        color: "#525256"

                        Rectangle {
                            width: control3.visualPosition * parent.width
                            height: parent.height
                            // USBTHRV100-72 メモリ、▲とも R,G,B: 255,204,0 でお願い致します。
                            color: Qt.rgba(255, 204, 0);
                            radius: 2
                        }
                    }
                    handle: Rectangle {
                        id:handle3
                        x: control3.leftPadding + (control3.visualPosition * control3.availableWidth) - width/2
                        y: control3.topPadding + control3.availableHeight/2 + height/2
                        implicitWidth: 16
                        implicitHeight: 20
                        visible: false
                    }
                    onValueChanged: {
                        lvGDraw_thickness=value

                        ltLog.log(LT.TagDef.RecLvl_Info,
                            LT.TagDef.RTScr_Usage_LiveView_GridThckSlider,
                            "LTGridPopup ThicknessSlider changed",
                            lvGDraw_thickness)
                    }
                }
                Canvas {
                    id:canvas3
                    x: control3.x + control3.leftPadding + (control3.visualPosition * control3.availableWidth) - width/2
                    y: control3.y + control3.topPadding + control3.availableHeight/2 + background3.height/2 + 1
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
                    x: 160
                    y: 20

                    type: text_style_gridPopup20
                    text: lvGDraw_thickness//qsTr(testwk)
                    visible: true
                }
                /*
                    増加ボタン
                 */
                LTRoundButton {
                    x:184; y:8;
                    source: "qrc:/images/a_l_up.svg"
                    diameter: 20
                    fillColor: "#292b2d"
                    mainImg.sourceSize.width: 20
                    mainImg.sourceSize.height: 20
                    onClicked: {
                        if(lvGDraw_thickness<10) {
                            lvGDraw_thickness++
                        }

                        ltLog.log(LT.TagDef.RecLvl_Info,
                                  LT.TagDef.RTScr_Usage_LiveView_GridThckIncrease,
                                  "LTGridPopup ThicknessIncrease clicked",
                                  lvGDraw_thickness)
                    }
                }
                /*
                    減少ボタン
                 */
                LTRoundButton {
                    x:184; y:39;
                    source: "qrc:/images/a_l_down.svg"
                    diameter: 20
                    fillColor: "#292b2d"
                    mainImg.sourceSize.width: 20
                    mainImg.sourceSize.height: 20
                    onClicked: {
                        if(lvGDraw_thickness>1) {
                            lvGDraw_thickness--
                        }

                        ltLog.log(LT.TagDef.RecLvl_Info,
                                  LT.TagDef.RTScr_Usage_LiveView_GridThckIncrease,
                                  "LTGridPopup ThicknessDecrease clicked",
                                  lvGDraw_thickness)
                    }
                }
            }
            Rectangle {
                id: color_set_id
                width: parent.width
                height: 29
                color: "#000000"
                border.color: "#202022"
                // 色選択ボタン
                LTRectangleButton {
                    id: colorbutton
                    anchors.fill: color_set_id

                    logCol: ltLog
                    logScrTagID: LT.TagDef.RTScr_Usage_LiveView_GridColor
                    logFile: "colorbutton"

                    onClicked: {
                        LTSubFunction.console_debug.out("gridpopup colorbutton clicked")
                        //line1colordialog.visible = true
                        showDialog(true)
                    }
                }
                // 色表示ボックス
                Rectangle {
                    x: 7
                    y: 5
                    width: 28
                    height: 20
                    color: lvGDraw_color
                }
                // 色表示
                LTStylishText {
                    x: 50
                    y: 0
                    height: parent.height
                    color: lvGDraw_color

                    type: text_style_gridPopup12
                    text: qsTr("color")
                    visible: true
                }
            }
            /* 対角線　*/
            Rectangle {
                id: diagonal_id
                visible:false
                width: back.width-2
                height: 38
                color: "#000000"
                border.color: "#202022"
                CheckBox {
                    id: checkBox
                    x: 9
                    y: (diagonal_id.height - checkBox.height)/2
                    width: 18
                    height: 18
                    scale: 0.6
                    checked: lvGDraw_Diagonal_on_off
                    onCheckedChanged: {
                        lvGDraw_Diagonal_on_off=checked

                        ltLog.log(LT.TagDef.RecLvl_Info,
                                  LT.TagDef.RTScr_Usage_LiveView_GridDiagonal,
                                  "LTGridPopup GridDiagonal changed",
                                  checked)
                    }

                    onClicked: {
                        ltLog.log(LT.TagDef.RecLvl_Info,
                                  LT.TagDef.RTScr_Usage_LiveView_GridDiagonal,
                                  "LTGridPopup GridDiagonal clicked",
                                  checked)
                    }
                }
                LTStylishText {
                    id: text10
                    x: 38
                    y: 0
                    height: parent.height

                    type: text_style_gridPopup12
                    text: qsTr("cross line")
                    visible: true
                }
            }
        }
    }

    LTCustomColorDialog {
        id: line2colordialog
        color: lvGDraw_color
        onColorChanged: {
            lvGDraw_color=line2colordialog.color
        }

        onAccepted: {
            ltLog.log(LT.TagDef.RecLvl_Info,
                      LT.TagDef.RTScr_Usage_LiveView_GridColor,
                      "LTGridPopup GridColor accepted",
                      color)
        }

        onRejected: {
            ltLog.log(LT.TagDef.RecLvl_Info,
                      LT.TagDef.RTScr_Usage_LiveView_GridColor,
                      "LTGridPopup GridColor rejected",
                      color)
        }
    }
}
