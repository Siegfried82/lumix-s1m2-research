import QtQuick 2.6
import QtQuick.Controls.Basic 2.0 as Basic
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0
import QtQuick.Window 2.3
import Qt.labs.platform 1.0

import "qrc:/qml"
import LT 1.0 as LT
import "LTSubFunction.js" as LTSubFunction

/*! \qmltype LTOverlayPhotoPopup
    \inqmlmodule LT

    \brief
    OverlayPhoto popup
 */
Item {
    id: root

    visible: false
    height: 480//454
    width: 212
    z:30
    readonly property double bottom_btn_height: 38

    property int ratioValue: 10

    property alias sliderRotation1: sliderRotation
    // ivc >> start >> USBTHRV140-35
//    property alias sliderPosYalias: sliderPosY
//    property alias sliderPosXalias: sliderPosX
    property alias spinBoxPosYalias: spinboxPosY
    property alias spinBoxPosXalias: spinboxPosX
    // ivc << end << USBTHRV140-35
    /*!
        Define palette to draw item
     */
    readonly property var palette: {
        "backgroundDark": "#07090d",
        "backgroundLight": "#292b2d",
        "foregroundDark": "#808080",
        "foregroundLight": "#c6c6c6",
        "hovered": "#434343",
        "pressed": "#5c5c5c",
        "checked": "#ffbf1f",
        "defaultColor": "#525356",
        "selectedColor": "#FFD600"
    }

    function dismiss() {
        visible = false;
        // ivc >> start >> #7721
        if((lvOverlayPhotoFrameAlias.overlayImagealias.status == Image.Null) || (lvOverlayPhotoFrameAlias.overlayImagealias.status == Image.Error))
        {
            control.overlayButtonAlias.checked=false
        }
        // ivc << end << #7721

        lvOverlayPhotoFrameAlias.dragAreaphoto1.visible = false
        lvOverlayPhotoFrameAlias.cornerTopLeft1.visible = false
        lvOverlayPhotoFrameAlias.cornerTopRight1.visible = false
        lvOverlayPhotoFrameAlias.cornerBotLeft1.visible = false
        lvOverlayPhotoFrameAlias.cornerBotRight1.visible = false
        lvOverlayPhotoFrameAlias.rotaimage1.visible = false
    }

    function cancelSettingOverlay() {
        if(lvOverlayPhotoFlagSubmit == false ||(lvOverlayPhotoFrameAlias.overlayImagealias.status == Image.Null) || (lvOverlayPhotoFrameAlias.overlayImagealias.status == Image.Error) ) {
            lvOverlayPhotoAspectRatio = 0.5
            sliderPosX.value = 0
            sliderPosY.value = 0
            if(lv_rotation == 270)
            {
                lvOverlayPhotoRotation = -90
            }else{
                lvOverlayPhotoRotation = lv_rotation
            }
            lvOverlayPhotoScaling = lvOverlayPhotoScalingDefault
        } else {
            sliderPosX.value = lvOverlayPhotoSavedPosX / calcuratio()
            sliderPosY.value = lvOverlayPhotoSavedPosY / calcuratio()
            lvOverlayPhotoRotation = lvOverlayPhotoSavedRotation
            lvOverlayPhotoScaling = lvOverlayPhotoSavedScaling
            lvOverlayPhotoAspectRatio = lvOverlayPhotoSavedAspectRatio
        }
        updateRotaOverlayPhoto()
    }

    // File dialog
    FileDialog {
        id: fileDialog
        title: "Please choose a file"
        nameFilters: ["JPEG (*.jpg)", "RAW (*.RW2)", "All Files (*.jpg *.RW2)"]
        visible: false
        //selectFolder:  false
        onAccepted: {
            textField_ImageFile.text = utilities.qUrlToLocalFileWithoutNative(file);
            console.log("Selected file (converted): " + textField_ImageFile.text)
            lvOverSelectedFile = textField_ImageFile.text;
            console.log("Selected file: " + file);
        }
    }

    /*
        Main
     */
    Rectangle {
        anchors {
            fill: parent
        }
        id: back
        color: "#000000"
        border.color: "#d8d8d8"
        Column{
            x:1
            y:1
            //////////////////////////////////////////////////// Screen items ////////////////////////////////////////////////////
            Rectangle {
                width: back.width - 2
                height: 39
                color: "#000000"
                border.color: "#202022"

                LTStylishText {
                    id: text1
                    x: 14
                    // ivc >> start >> Support Multi-Language
                    //y: 10
                    anchors.verticalCenter: parent.verticalCenter
                    // ivc << end << Support Multi-Language

                    type: text_style_lvItemPopupTitle
                    text: qsTr("Overlay")
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
                    logScrTagID: LT.TagDef.RTScr_Usage_LiveView_OverlayPhotoClose
                    logFile: "exitbutton"

                    onClicked: {
                        dismiss()
                        cancelSettingOverlay()
                        updateCursorScale()
                    }
                }
            }

            // Image file
            Rectangle {
                id: imageFile_id
                visible:true
                width: back.width - 2
                height: 84
                color: "#000000"
                border.color: "#202022"

                LTStylishText {
                    id: text_imageFile
                    x: 10
                    y: 6
                    type: text_style_overlayPopup12
                    text: qsTr("Image File")
                    visible: true
                }

                Rectangle {
                    id: select_file_panel
                    x: 5
                    y: 25
                    width: parent.width - 10
                    height: 53
                    color: "transparent"//palette.backgroundDark

                    readonly property double spacing_val: 5
                    readonly property double tf_width: select_file_panel.width*2/3
                    readonly property double btn_width: select_file_panel.width/3-spacing_val

                    Column {
                        anchors.fill: parent
                        spacing: select_file_panel.spacing_val

                        Rectangle {
                            width: parent.width
                            height: 24
                            color: "transparent"

                            Row {
                                anchors.fill: parent
                                width: parent.width
                                height: 24
                                spacing: select_file_panel.spacing_val

                                // Text field
                                LTTextField {
                                    id: textField_ImageFile
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: select_file_panel.tf_width
                                    height: 24

                                    enabled: true
                                    placeholderText: qsTr("Select a file")
                                    font.pixelSize: 10
                                    font.family: utilities.getFontFamily()

                                    onTextChanged: {
                                        lvOverSelectedFile = text
                                    }
                                }

                                // Browser button
                                LTRectangleButton {
                                    id: btnBrowser_ImageFile
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: 24
                                    width: select_file_panel.btn_width
                                    
                                    enabled: true
        
                                    type:"action_smaller"
                                    buttonText: qsTr("Browser")
        
                                    strokeWidth: 1
                                    strokeColor: palette.backgroundLight
                                    fillColor: palette.defaultColor
        
                                    property bool openFlg: false

                                    onClicked: {
                                        // ivc >> start >> USBTHRV140-25
                                        if(utilities.isMac()) {
                                            fileDialog.visible = true
                                        } else {
                                            if(openFlg) {
                                                return
                                            }
                                            openFlg = true
                                            var sel = utilities.selectFileOverLay()
                                            openFlg = false
                                            if(sel.length != 0) {
                                                var path2 = sel.replace(/\\/g, "/");
                                                textField_ImageFile.text = path2
                                                lvOverSelectedFile=textField_ImageFile.text
                                            }
                                        }
                                        // ivc << end << USBTHRV140-25
                                    }
                                }

                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 24
                            color: "transparent"

                            Row {
                                anchors.fill: parent
                                width: parent.width
                                height: parent.height
                                spacing: select_file_panel.spacing_val

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: select_file_panel.tf_width
                                    height: 24

                                    color: "transparent"
                                }

                                // Open button
                                LTRectangleButton {
                                    id: btnOpen_ImageFile
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: 24
                                    width: select_file_panel.btn_width
                                    
                                    enabled: textField_ImageFile.text.length > 0 ? true : false
        
                                    disabled: textField_ImageFile.text.length > 0 ? false : true
                                    type:"action_smaller"
                                    buttonText: qsTr("Open")
        
                                    strokeWidth: 1
                                    strokeColor: palette.backgroundLight
                                    fillColor: palette.defaultColor

                                    function updateValueInitOverlay() {
                                            var newx=imageLV.x + imageLV.width / 2 - overlayPhotoFrame.width / 2
                                            var newy=imageLV.y + imageLV.height / 2 - overlayPhotoFrame.height / 2
                                            if(lv_rotation == 0) {
                                                lvOverlayPhotoFrameAlias.x = newx + lvOverlayPhotoPosX
                                                lvOverlayPhotoFrameAlias.y = newy - lvOverlayPhotoPosY
                                                lvOverlayPhotoFrameOldPosY = overlayPhotoFrame.y
                                                lvOverlayPhotoFrameOldPosX = overlayPhotoFrame.x
                                            } else if(lv_rotation == 270) {
                                                lvOverlayPhotoFrameAlias.x=newx-lvOverlayPhotoPosY
                                                lvOverlayPhotoFrameAlias.y=newy-lvOverlayPhotoPosX
                                                lvOverlayPhotoFrameOldPosY=overlayPhotoFrame.y
                                                lvOverlayPhotoFrameOldPosX=overlayPhotoFrame.x
                                            } else if(lv_rotation == 90) {
                                                lvOverlayPhotoFrameAlias.x=newx+lvOverlayPhotoPosY
                                                lvOverlayPhotoFrameAlias.y=newy+lvOverlayPhotoPosX
                                                lvOverlayPhotoFrameOldPosY=overlayPhotoFrame.y
                                                lvOverlayPhotoFrameOldPosX=overlayPhotoFrame.x
                                            } else if(lv_rotation == 180 || lv_rotation == -180) {
                                                lvOverlayPhotoFrameAlias.x = newx - lvOverlayPhotoPosX
                                                lvOverlayPhotoFrameAlias.y = newy + lvOverlayPhotoPosY
                                                lvOverlayPhotoFrameOldPosY = overlayPhotoFrame.y
                                                lvOverlayPhotoFrameOldPosX = overlayPhotoFrame.x
                                            }
                                    }

                                    onClicked: {
                                        overlayPhotoFrame.loadImageSource();
                                        if((lvOverlayPhotoFrameAlias.overlayImagealias.status != Image.Null) && (lvOverlayPhotoFrameAlias.overlayImagealias.status != Image.Error)) {
                                            updateValueInitOverlay()
                                            lvOverlayPhotoFrameOldHeight = overlayPhotoFrame.height * lvOverlayPhotoFrameAlias.scale
                                            lvOverlayPhotoFrameOldWidth = overlayPhotoFrame.width * lvOverlayPhotoFrameAlias.scale
                                            lvOverlayPhotoFrameAlias.dragAreaphoto1.visible = true
                                            lvOverlayPhotoFrameAlias.cornerTopLeft1.visible = true
                                            lvOverlayPhotoFrameAlias.cornerTopRight1.visible = true
                                            lvOverlayPhotoFrameAlias.cornerBotLeft1.visible = true
                                            lvOverlayPhotoFrameAlias.cornerBotRight1.visible = true
                                            lvOverlayPhotoFrameAlias.rotaimage1.visible = true
                                        } else{
                                            lvOverlayPhotoFrameAlias.dragAreaphoto1.visible = false
                                            lvOverlayPhotoFrameAlias.cornerTopLeft1.visible = false
                                            lvOverlayPhotoFrameAlias.cornerTopRight1.visible = false
                                            lvOverlayPhotoFrameAlias.cornerBotLeft1.visible = false
                                            lvOverlayPhotoFrameAlias.cornerBotRight1.visible = false
                                            lvOverlayPhotoFrameAlias.rotaimage1.visible = false
                                            dialogerror.open()
                                        }
                                    }
                                }
                            }

//                            MessageDialog {
                            LT.MessageBox{
                                id: dialogerror
                                title: "LUMIX Tether"
                                icon:LT.StandardIcon.Warning
                                text: qsTr("error_message_1")
                                standardButtons: LT.StandardButton.Ok
                            }
                        }
                    }
                }
            }

            // Position
            Rectangle {
                id: position_id
                visible:true
                width: back.width - 2
                height: 84
                color: "#000000"
                border.color: "#202022"

                LTStylishText {
                    id: text_Position
                    x: 10
                    y: 6

                    type: text_style_overlayPopup12
                    text: qsTr("Postion")
                    visible: true
                }

                // Position X
                LTStylishText {
                    id: text_PositionX
                    x: 15
                    y: 30

                    type: text_style_overlayPopup10
                    text: qsTr("X")
                    visible: true
                }
                // Position X slider
                Basic.Slider {
                    id: sliderPosX
                    value : 0
                    x:20
                    y:20
                    width: parent.width/3*2-15
                    from:-1000
                    to:1000

                    background: Rectangle {
                        id: backgroundPosX
                        x: sliderPosX.leftPadding
                        y: sliderPosX.topPadding + sliderPosX.availableHeight / 2 - height / 2
                        implicitWidth: 150
                        implicitHeight: 4
                        width: sliderPosX.availableWidth
                        height: implicitHeight
                        radius: 2
                        color: "#525256"
                        Rectangle {
                            // ivc >> start >> USBTHRV140-37
                            //width: sliderPosX.visualPosition * parent.width
                            // ivc >> start >> USBTHRV140-40
                            //x: handlePosX.x - 2
                            id: markPosX
                            x: sliderPosX.visualPosition * parent.width - width/2
                            // ivc << end << USBTHRV140-40
                            width: 3
                            // ivc << end << USBTHRV140-37
                            height: parent.height
                            // USBTHRV100-72 メモリ、▲とも R,G,B: 255,204,0 でお願い致します。
                            color: Qt.rgba(255, 204, 0);
                            radius: 2
                        }
                    }

                    handle: Rectangle {
                        id: handlePosX
                        // ivc >> start >> USBTHRV140-40
//                        // ivc >> start >> USBTHRV140-37
//                        //x: sliderPosX.visualPosition * (sliderPosX.leftPadding + sliderPosX.availableWidth - width)
//                        x: sliderPosX.visualPosition * (sliderPosX.leftPadding + sliderPosX.availableWidth - width/2)
//                        // ivc << end << USBTHRV140-37
                        x: sliderPosX.leftPadding + (sliderPosX.visualPosition * sliderPosX.availableWidth) - width/2
                        // ivc << end << USBTHRV140-40
                        y: sliderPosX.topPadding + sliderPosX.availableHeight/2 - height/2
                        // ivc >> start >> USBTHRV140-40
                        //implicitWidth: 16
                        implicitWidth: 3
                        // ivc << end << USBTHRV140-37
                        implicitHeight: 20
                        visible: false
                    }

                    onValueChanged: {
                        // ivc >> start >> USBTHRV140-35
//                        if(lvOverlayPhotoFrameAlias.mousescale01.drag.active == false
//                            && lvOverlayPhotoFrameAlias.mousescale02.drag.active == false
//                            && lvOverlayPhotoFrameAlias.mousescale03.drag.active == false
//                            && lvOverlayPhotoFrameAlias.mousescale04.drag.active == false
//                            && lvOverlayPhotoFrameAlias.dragAreaphoto1.drag.active == false) {
//                            if(lvOverlayPhotoFlagChangeXY != 1) {
//                                if(lv_rotation == 0) {
//                                    lvOverlayPhotoFrameAlias.x += (value * calcuratio() - lvOverlayPhotoSliderOldPosX * calcuratio())
//                                    lvOverlayPhotoSliderOldPosX = value
//                                    lvOverlayPhotoFrameOldPosX = lvOverlayPhotoFrameAlias.x
//                                } else if(lv_rotation == 270) {
//                                    lvOverlayPhotoFrameAlias.y -= (value * calcuratio() - lvOverlayPhotoSliderOldPosX * calcuratio())
//                                    lvOverlayPhotoSliderOldPosX = value
//                                    lvOverlayPhotoFrameOldPosY = lvOverlayPhotoFrameAlias.y
//                                } else if(lv_rotation == 180) {
//                                    lvOverlayPhotoFrameAlias.x -= (value * calcuratio() - lvOverlayPhotoSliderOldPosX * calcuratio())
//                                    lvOverlayPhotoSliderOldPosX = value
//                                    lvOverlayPhotoFrameOldPosX = lvOverlayPhotoFrameAlias.x
//                                } else if(lv_rotation == 90) {
//                                    lvOverlayPhotoFrameAlias.y += (value * calcuratio() - lvOverlayPhotoSliderOldPosX * calcuratio())
//                                    lvOverlayPhotoSliderOldPosX = value
//                                    lvOverlayPhotoFrameOldPosY = lvOverlayPhotoFrameAlias.y
//                                }

//                                if(value != spinboxPosX.value) {
//                                    lvOverlayPhotoPosX = value * calcuratio()
//                                    spinboxPosX.value = value
//                                }
//                            }
//                        } else {
//                            lvOverlayPhotoSliderOldPosX = value
//                        }

//                        if(value != spinboxPosX.value) {
//                            lvOverlayPhotoPosX = value * calcuratio()
//                            spinboxPosX.value = value
//                        }

//                        ltLog.log(LT.TagDef.RecLvl_Info,
//                                  LT.TagDef.RTScr_Usage_LiveView_GridVerSlider,
//                                  "LTGridPopup VerSlider changed",
//                                  lvGDraw_Vertical_Num)
                        if(value!=lvOverlayPhotoPosX/calcuratio()) {
                            lvOverlayPhotoPosX = value*calcuratio()
                            spinboxPosX.realValue = value
//                            ltLog.log(LT.TagDef.RecLvl_Info,
//                                      LT.TagDef.RTScr_Usage_LiveView_OverlayPhotoPosXSlider,
//                                      "LTOverlayPhotoPopup PosXSlider changed",
//                                      lvOverlayPhotoPosX)
                        }
                        // ivc << end << USBTHRV140-35
                    }
                }

                Canvas {
                    id: canvasPosX
                    // ivc >> start >> USBTHRV140-40
                    //x: sliderPosX.visualPosition * (sliderPosX.leftPadding + sliderPosX.availableWidth - width / 2) + sliderPosX.x
                    x: sliderPosX.x + sliderPosX.leftPadding + (sliderPosX.visualPosition * sliderPosX.availableWidth) - width/2
                    // ivc << end << USBTHRV140-40
                    y: sliderPosX.y + sliderPosX.topPadding + sliderPosX.availableHeight/2 + backgroundPosX.height/2 + 1
                    implicitWidth: 16
                    implicitHeight: 10
                    onPaint: {
                        var ctx = getContext("2d");
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
                // Position X spinbox
                SpinBox {
                    id: spinboxPosX
                    x: sliderPosX.x + sliderPosX.width
                    y: 25
                    width: 62
                    editable: true
                    value:0
                    from: -99999
                    to: 99999
                    property int decimals: 1
                    property real realValue: spinboxPosX.value / 10          // Qt ６から from to が -9999.9 から -99999(from) に変更になっている

                    validator: DoubleValidator {
                        bottom: Math.min(spinboxPosX.from, spinboxPosX.to)
                        top: Math.max(spinboxPosX.from, spinboxPosX.to)
                    }

                    textFromValue: function(value, locale) {
                        return Number(value / 10).toLocaleString(locale, 'f', spinboxPosX.decimals)
                    }
                    valueFromText: function(text, locale) {
                        return Number.fromLocaleString(locale, text) * 10
                    }

                    // ivc >> start >> USBTHRV160-11
                    font.pixelSize: 9
                    // ivc << end << USBTHRV160-11
                    onRealValueChanged: {
                        value = realValue * 10
                    }

                    onValueChanged: {
                        // ivc >> start >> USBTHRV140-35
//                        if(value!=lvOverlayPhotoPosX/calcuratio()) {
//                            if(value <= 1000 && value >= -1000) {
//                                lvOverlayPhotoPosX = value*calcuratio()
//                                sliderPosX.value = value
//                                ltLog.log(LT.TagDef.RecLvl_Info,
//                                          LT.TagDef.RTScr_Usage_LiveView_OverlayPhotoPosXSpinbox,
//                                          "LTOverlayPhotoPopup PosXSpinbox changed",
//                                          lvOverlayPhotoPosX)
//                            }
//                        }
                        realValue = value / 10
                        if(lvOverlayPhotoFrameAlias.mousescale01.drag.active == false
                            && lvOverlayPhotoFrameAlias.mousescale02.drag.active == false
                            && lvOverlayPhotoFrameAlias.mousescale03.drag.active == false
                            && lvOverlayPhotoFrameAlias.mousescale04.drag.active == false
                            && lvOverlayPhotoFrameAlias.dragAreaphoto1.drag.active == false) {
                            if(lvOverlayPhotoFlagChangeXY != 1) {
                                if(lv_rotation == 0) {
                                    lvOverlayPhotoFrameAlias.x += (realValue * calcuratio() - lvOverlayPhotoSpinBoxOldPosX * calcuratio())
                                    lvOverlayPhotoSpinBoxOldPosX = realValue
                                    lvOverlayPhotoFrameOldPosX = lvOverlayPhotoFrameAlias.x
                                } else if(lv_rotation == 270) {
                                    lvOverlayPhotoFrameAlias.y -= (realValue * calcuratio() - lvOverlayPhotoSpinBoxOldPosX * calcuratio())
                                    lvOverlayPhotoSpinBoxOldPosX = realValue
                                    lvOverlayPhotoFrameOldPosY = lvOverlayPhotoFrameAlias.y
                                } else if(lv_rotation == 180) {
                                    lvOverlayPhotoFrameAlias.x -= (realValue * calcuratio() - lvOverlayPhotoSpinBoxOldPosX * calcuratio())
                                    lvOverlayPhotoSpinBoxOldPosX = realValue
                                    lvOverlayPhotoFrameOldPosX = lvOverlayPhotoFrameAlias.x
                                } else if(lv_rotation == 90) {
                                    lvOverlayPhotoFrameAlias.y += (realValue * calcuratio() - lvOverlayPhotoSpinBoxOldPosX * calcuratio())
                                    lvOverlayPhotoSpinBoxOldPosX = realValue
                                    lvOverlayPhotoFrameOldPosY = lvOverlayPhotoFrameAlias.y
                                }
                            }
                        } else {
                            lvOverlayPhotoSpinBoxOldPosX = realValue
                        }

                        lvOverlayPhotoPosX = realValue * calcuratio()

                        // Update slider value
                        if(realValue != sliderPosX.value) {
                            sliderPosX.value = realValue
                        }

//                        ltLog.log(LT.TagDef.RecLvl_Info,
//                                  LT.TagDef.RTScr_Usage_LiveView_OverlayPhotoPosXSpinbox,
//                                  "LTOverlayPhotoPopup PosXSpinbox changed",
//                                  lvOverlayPhotoPosX)
                        // ivc << end << USBTHRV140-35
                    }
                }

                // Position Y
                LTStylishText {
                    id: text_PositionY
                    x: 15
                    y: 55

                    type: text_style_overlayPopup10
                    text: qsTr("Y")
                    visible: true
                }

                // Position Y slider
                Basic.Slider {
                    id: sliderPosY
                    value : 0
                    x:20
                    // ivc >> start >> USBTHRV140-36
                    //y:45
                    y:60
                    // ivc << end << USBTHRV140-36
                    width: parent.width/3*2-15
                    // ivc >> start >> USBTHRV140-36
                    height: 20
                    // ivc << end << USBTHRV140-36
                    from: -1000
                    to: 1000
                    background: Rectangle {
                        id: backgroundPosY
                        x: sliderPosY.leftPadding
                        // ivc >> start >> USBTHRV140-36
                        //y: sliderPosY.topPadding + sliderPosY.availableHeight / 2 - height / 2
                        y: 0
                        // ivc << end << USBTHRV140-36
                        implicitWidth: 150
                        implicitHeight: 4
                        width: sliderPosY.availableWidth
                        height: implicitHeight
                        radius: 2
                        color: "#525256"
                        Rectangle {
                            // ivc >> start >> USBTHRV140-37
                            //width: sliderPosY.visualPosition * parent.width
                            // ivc >> start >> USBTHRV140-40
                            //x: handlePosY.x - 2
                            id: markPosY
                            x: sliderPosY.visualPosition * parent.width - width/2
                            // ivc << end << USBTHRV140-40
                            width: 3
                            // ivc << end << USBTHRV140-37
                            height: parent.height
                            // USBTHRV100-72 メモリ、▲とも R,G,B: 255,204,0 でお願い致します。
                            color: Qt.rgba(255, 204, 0);
                            radius: 2
                        }
                    }

                    handle: Rectangle {
                        id: handlePosY
                        // ivc >> start >> USBTHRV140-40
//                        // ivc >> start >> USBTHRV140-37
//                        //x: sliderPosY.visualPosition * (sliderPosY.leftPadding + sliderPosY.availableWidth - width)
//                        x: sliderPosY.visualPosition * (sliderPosY.leftPadding + sliderPosY.availableWidth - width/2)
//                        // ivc << end << USBTHRV140-37
                        x: sliderPosY.leftPadding + (sliderPosY.visualPosition * sliderPosY.availableWidth) - width/2
                        // ivc << end << USBTHRV140-40
                        // ivc >> start >> USBTHRV140-36
                        //y: sliderPosY.topPadding + sliderPosY.availableHeight + 1
                        //implicitWidth: 16
                        //implicitHeight: 20
                        y: sliderPosY.topPadding + sliderPosY.availableHeight/2 - height/2
                        // ivc >> start >> USBTHRV140-40
                        //implicitWidth: 16
                        implicitWidth: 3
                        // ivc << end << USBTHRV140-40
                        implicitHeight: 15
                        // ivc << end << USBTHRV140-36
                        visible: false
                    }

                    onValueChanged: {
                        // ivc >> start >> USBTHRV140-35
//                        if(lvOverlayPhotoFrameAlias.mousescale01.drag.active == false
//                            && lvOverlayPhotoFrameAlias.mousescale02.drag.active == false
//                            && lvOverlayPhotoFrameAlias.mousescale03.drag.active == false
//                            && lvOverlayPhotoFrameAlias.mousescale04.drag.active == false
//                            && lvOverlayPhotoFrameAlias.dragAreaphoto1.drag.active == false) {
//                            if(lvOverlayPhotoFlagChangeXY != 1) {
//                                if(lv_rotation == 0) {
//                                    lvOverlayPhotoFrameAlias.y -= (value * calcuratio() - lvOverlayPhotoSliderOldPosY * calcuratio())
//                                    lvOverlayPhotoSliderOldPosY = value
//                                    lvOverlayPhotoFrameOldPosY = lvOverlayPhotoFrameAlias.y
//                                } else if(lv_rotation == 270) {
//                                    lvOverlayPhotoFrameAlias.x -= (value * calcuratio() - lvOverlayPhotoSliderOldPosY * calcuratio())
//                                    lvOverlayPhotoSliderOldPosY = value
//                                    lvOverlayPhotoFrameOldPosX = lvOverlayPhotoFrameAlias.x
//                                } else if(lv_rotation == 180) {
//                                    lvOverlayPhotoFrameAlias.y += (value*calcuratio() - lvOverlayPhotoSliderOldPosY * calcuratio())
//                                    lvOverlayPhotoSliderOldPosY = value
//                                    lvOverlayPhotoFrameOldPosY = lvOverlayPhotoFrameAlias.y
//                                } else if(lv_rotation == 90) {
//                                    lvOverlayPhotoFrameAlias.x += (value * calcuratio() - lvOverlayPhotoSliderOldPosY * calcuratio())
//                                    lvOverlayPhotoSliderOldPosY = value
//                                    lvOverlayPhotoFrameOldPosX = lvOverlayPhotoFrameAlias.x
//                                }

//                                if(value != spinboxPosY.value) {
//                                    lvOverlayPhotoPosY = value * calcuratio()
//                                    spinboxPosY.value = value
//                                }
//                            }
//                        } else {
//                            lvOverlayPhotoSliderOldPosY = value
//                        }

//                        if(value != spinboxPosY.value) {
//                            lvOverlayPhotoPosY = value * calcuratio()
//                            spinboxPosY.value = value
//                        }
//                        ltLog.log(LT.TagDef.RecLvl_Info,
//                                  LT.TagDef.RTScr_Usage_LiveView_GridVerSlider,
//                                  "LTGridPopup VerSlider changed",
//                                  lvGDraw_Vertical_Num)
                        if(value != lvOverlayPhotoPosY / calcuratio()) {
                            lvOverlayPhotoPosY = value * calcuratio()
                            spinboxPosY.realValue = value
//                            ltLog.log(LT.TagDef.RecLvl_Info,
//                                      LT.TagDef.RTScr_Usage_LiveView_OverlayPhotoPosYSlider,
//                                      "LTOverlayPhotoPopup PosYSlider changed",
//                                      lvOverlayPhotoPosY)
                        }
                        // ivc << end << USBTHRV140-35
                    }
                }

                Canvas {
                    id: canvasPosY
                    // ivc >> start >> USBTHRV140-40
                    //x: sliderPosY.visualPosition * (sliderPosY.leftPadding + sliderPosY.availableWidth - width / 2) + sliderPosY.x
                    x: sliderPosY.x + sliderPosY.leftPadding + (sliderPosY.visualPosition * sliderPosY.availableWidth) - width/2
                    // ivc << end << USBTHRV140-40
                    // ivc >> start >> USBTHRV140-36
                    //y: sliderPosY.topPadding + sliderPosY.availableHeight + 1 + sliderPosY.y - 8
                    y: sliderPosY.y + backgroundPosY.height + 1
                    // ivc << end << USBTHRV140-36
                    implicitWidth: 16
                    implicitHeight: 10
                    onPaint: {
                        var ctx = getContext("2d");
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
                // Position Y spinbox
                SpinBox {
                    id: spinboxPosY
                    x: sliderPosY.x + sliderPosY.width
                    y: 50
                    width: 62
                    editable: true
                    value:0
                    from: -99999
                    to: 99999
                    property int decimals: 1
                    property real realValue: spinboxPosY.value / 10          // Qt ６から from to が -9999.9 から -99999(from) に変更になっている

                    validator: DoubleValidator {
                        bottom: Math.min(spinboxPosY.from, spinboxPosY.to)
                        top: Math.max(spinboxPosY.from, spinboxPosY.to)
                    }

                    textFromValue: function(value, locale) {
                        return Number(value / 10).toLocaleString(locale, 'f', spinboxPosY.decimals)
                    }
                    valueFromText: function(text, locale) {
                        return Number.fromLocaleString(locale, text) * 10
                    }

                    // ivc >> start >> USBTHRV160-11
                    font.pixelSize: 9
                    // ivc << end << USBTHRV160-11
                    onRealValueChanged: {
                        value = realValue * 10
                    }
                    onValueChanged: {
                        // ivc >> start >> USBTHRV140-35
//                        if(value != lvOverlayPhotoPosY / calcuratio()) {
//                            if(value <= 1000 && value >= -1000) {
//                                lvOverlayPhotoPosY = value * calcuratio()
//                                sliderPosY.value = value
//                            }
//                        }
                        realValue = value / 10
                        if(lvOverlayPhotoFrameAlias.mousescale01.drag.active == false
                            && lvOverlayPhotoFrameAlias.mousescale02.drag.active == false
                            && lvOverlayPhotoFrameAlias.mousescale03.drag.active == false
                            && lvOverlayPhotoFrameAlias.mousescale04.drag.active == false
                            && lvOverlayPhotoFrameAlias.dragAreaphoto1.drag.active == false) {
                            if(lvOverlayPhotoFlagChangeXY != 1) {
                                if(lv_rotation == 0) {
                                    lvOverlayPhotoFrameAlias.y -= (realValue * calcuratio() - lvOverlayPhotoSpinBoxOldPosY * calcuratio())
                                    lvOverlayPhotoSpinBoxOldPosY = realValue
                                    lvOverlayPhotoFrameOldPosY = lvOverlayPhotoFrameAlias.y
                                } else if(lv_rotation == 270) {
                                    lvOverlayPhotoFrameAlias.x -= (realValue * calcuratio() - lvOverlayPhotoSpinBoxOldPosY * calcuratio())
                                    lvOverlayPhotoSpinBoxOldPosY = realValue
                                    lvOverlayPhotoFrameOldPosX = lvOverlayPhotoFrameAlias.x
                                } else if(lv_rotation == 180) {
                                    lvOverlayPhotoFrameAlias.y += (realValue*calcuratio() - lvOverlayPhotoSpinBoxOldPosY * calcuratio())
                                    lvOverlayPhotoSpinBoxOldPosY = realValue
                                    lvOverlayPhotoFrameOldPosY = lvOverlayPhotoFrameAlias.y
                                } else if(lv_rotation == 90) {
                                    lvOverlayPhotoFrameAlias.x += (realValue * calcuratio() - lvOverlayPhotoSpinBoxOldPosY * calcuratio())
                                    lvOverlayPhotoSpinBoxOldPosY = realValue
                                    lvOverlayPhotoFrameOldPosX = lvOverlayPhotoFrameAlias.x
                                }
                            }
                        } else {
                            lvOverlayPhotoSpinBoxOldPosY = realValue
                        }

                        lvOverlayPhotoPosY = realValue * calcuratio()

                        // Update slider value
                        if(realValue != sliderPosY.value) {
                            sliderPosY.value = realValue
                        }

//                        ltLog.log(LT.TagDef.RecLvl_Info,
//                                  LT.TagDef.RTScr_Usage_LiveView_OverlayPhotoPosYSpinbox,
//                                  "LTOverlayPhotoPopup PosYSpinbox changed",
//                                  lvOverlayPhotoPosY)
                        // ivc << end << USBTHRV140-35
                    }
                }
            }

            // Scaling
            Rectangle {
                id: scaling_id
                visible:true
                width: back.width - 2
                height: 65
                color: "#000000"
                border.color: "#202022"

                // Scaling text
                LTStylishText {
                    id: text_Scaling
                    x: 10
                    y: 6

                    type: text_style_overlayPopup12
                    text: qsTr("Scaling(25 - 200%)")
                    visible: true
                }

                // Scaling slider
                Basic.Slider {
                    id: sliderScaling
                    value : lvOverlayPhotoScaling
                    from:25
                    to:200
                    x:20
                    y:20
                    width: parent.width/3*2-15
                    background: Rectangle {
                        id: backgroundScaling
                        x: sliderScaling.leftPadding
                        y: sliderScaling.topPadding + sliderScaling.availableHeight / 2 - height / 2
                        implicitWidth: 150
                        implicitHeight: 4
                        width: sliderScaling.availableWidth
                        height: implicitHeight
                        radius: 2
                        color: "#525256"
                        Rectangle {
                            // ivc >> start >> USBTHRV140-37
                            //width: sliderScaling.visualPosition * parent.width
                            // ivc >> start >> USBTHRV140-40
                            //x: handleScaling.x - 2
                            id: markScaling
                            x: sliderScaling.visualPosition * parent.width - width/2
                            // ivc << end << USBTHRV140-40
                            width: 3
                            // ivc << end << USBTHRV140-37
                            height: parent.height
                            // USBTHRV100-72 メモリ、▲とも R,G,B: 255,204,0 でお願い致します。
                            color: Qt.rgba(255, 204, 0);
                            radius: 2
                        }
                    }
                    handle: Rectangle {
                        id: handleScaling
                        // ivc >> start >> USBTHRV140-40
//                        // ivc >> start >> USBTHRV140-37
//                        //x: sliderScaling.visualPosition * (sliderScaling.leftPadding + sliderScaling.availableWidth - width)
//                        x: sliderScaling.visualPosition * (sliderScaling.leftPadding + sliderScaling.availableWidth - width/2)
//                        // ivc << end << USBTHRV140-37
                        x: sliderPosX.leftPadding + (sliderPosX.visualPosition * sliderPosX.availableWidth) - width/2
                        // ivc << end << USBTHRV140-40
                        y: sliderPosX.topPadding + sliderPosX.availableHeight/2 - height/2
                        // ivc >> start >> USBTHRV140-40
                        //implicitWidth: 16
                        implicitWidth: 3
                        // ivc << end << USBTHRV140-40
                        implicitHeight: 20
                        visible: false
                    }
                    onValueChanged: {
                        if(lvOverlayPhotoFrameAlias.mousescale01.drag.active == false
                            && lvOverlayPhotoFrameAlias.mousescale02.drag.active == false
                            && lvOverlayPhotoFrameAlias.mousescale03.drag.active == false
                            && lvOverlayPhotoFrameAlias.mousescale04.drag.active == false) {
                            lvOverlayPhotoFrameAlias.scale = 1 / lvOverlayPhotoScalingDefault * value
                            lvOverlayPhotoScaling = value
                            lvOverlayPhotoFrameOldHeight = lvOverlayPhotoFrameAlias.height * lvOverlayPhotoFrameAlias.scale
                            lvOverlayPhotoFrameOldWidth = lvOverlayPhotoFrameAlias.width * lvOverlayPhotoFrameAlias.scale
                        }
//                        ltLog.log(LT.TagDef.RecLvl_Info,
//                                  LT.TagDef.RTScr_Usage_LiveView_OverlayPhotoScaleSlider,
//                                  "LTOverlayPhotoPopup ScaleSlider changed",
//                                  lvOverlayPhotoScaling)
                    }
                }

                Canvas {
                    id: canvasScaling
                    // ivc >> start >> USBTHRV140-40
                    //x: sliderScaling.visualPosition * (sliderScaling.leftPadding + sliderScaling.availableWidth - width / 2) + sliderScaling.x
                    x: sliderScaling.x + sliderScaling.leftPadding + (sliderScaling.visualPosition * sliderScaling.availableWidth) - width/2
                    // ivc << end << USBTHRV140-40
                    y: sliderScaling.y + sliderScaling.topPadding + sliderScaling.availableHeight/2 + backgroundScaling.height/2 + 1
                    implicitWidth: 16
                    implicitHeight: 10
                    onPaint: {
                        var ctx = getContext("2d");
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
                // Scaling spinbox
                SpinBox {
                    id: spinboxScaling
                    x: sliderScaling.x + sliderScaling.width
                    y: 25
                    width: 62
                    editable: true
                    value:lvOverlayPhotoScaling
                    from: 25
                    to: 200
                    // ivc >> start >> USBTHRV160-11
                    font.pixelSize: 9
                    // ivc << end << USBTHRV160-11
                    onValueChanged: {
                        sliderScaling.value=value
//                        ltLog.log(LT.TagDef.RecLvl_Info,
//                                  LT.TagDef.RTScr_Usage_LiveView_OverlayPhotoScaleSpinbox,
//                                  "LTOverlayPhotoPopup ScaleSpinbox changed",
//                                  lvOverlayPhotoScaling)
                    }
                }
            }

            // Rotation
            Rectangle {
                id: rotation_id
                visible:true
                width: back.width - 2
                height: 65
                color: "#000000"
                border.color: "#202022"
                LTStylishText {
                    id: text_Rotation
                    x: 10
                    y: 6
                    type: text_style_overlayPopup12
                    text: qsTr("Rotation(-180 - 180°)")
                    visible: true
                }

                Basic.Slider {
                    id: sliderRotation
                    width: parent.width / 3 * 2 - 15
                    value : 0
                    x:20
                    y:20
                    from: -180
                    to: 180
                    background: Rectangle {
                        id: backgroundRotation
                        x: sliderRotation.leftPadding
                        y: sliderRotation.topPadding + sliderRotation.availableHeight / 2 - height / 2
                        implicitWidth: 150
                        implicitHeight: 4
                        width: sliderRotation.availableWidth
                        height: implicitHeight
                        radius: 2
                        color: "#525256"
                        Rectangle {
                            // ivc >> start >> USBTHRV140-37
                            //width: sliderRotation.visualPosition * parent.width
                            // ivc >> start >> USBTHRV140-40
                            //x: handleRotation.x - 2
                            id: markRotation
                            x: sliderRotation.visualPosition * parent.width - width/2
                            // ivc << end << USBTHRV140-40
                            width: 3
                            // ivc << end << USBTHRV140-37
                            height: parent.height
                            // USBTHRV100-72 メモリ、▲とも R,G,B: 255,204,0 でお願い致します。
                            color: Qt.rgba(255, 204, 0);
                            radius: 2
                        }
                    }
                    handle: Rectangle {
                        id: handleRotation
                        // ivc >> start >> USBTHRV140-40
//                        // ivc >> start >> USBTHRV140-37
//                        //x: sliderRotation.visualPosition * (sliderRotation.leftPadding + sliderRotation.availableWidth - width)
//                        x: sliderRotation.visualPosition * (sliderRotation.leftPadding + sliderRotation.availableWidth - width/2)
//                        // ivc << end << USBTHRV140-37
                        x: sliderRotation.leftPadding + (sliderRotation.visualPosition * sliderRotation.availableWidth) - width/2
                        // ivc << end << USBTHRV140-40
                        y: sliderRotation.topPadding + sliderRotation.availableHeight/2 - height/2
                        // ivc >> start >> USBTHRV140-40
                        //implicitWidth: 16
                        implicitWidth: 3
                        // ivc << end << USBTHRV140-40
                        implicitHeight: 20
                        visible: false
                    }
                    onValueChanged: {
                        if(lvOverlayPhotoFlagChangeRotation != 1) {
                            if(lv_rotation == 180){
                                if(lvOverlayPhotoRotation > 0){
                                    lvOverlayPhotoRotation = value + 180
                                }
                                else{
                                    lvOverlayPhotoRotation = value-180
                                }
                            }else if(lv_rotation == 270)
                            {
                                if(lvOverlayPhotoRotation < -90 && lvOverlayPhotoRotation > -180 || lvOverlayPhotoRotation > 90 && lvOverlayPhotoRotation < 180){
                                    if(lvOverlayPhotoRotation < -90 && lvOverlayPhotoRotation > -180){
                                        lvOverlayPhotoRotation = value - 90
                                    }
                                    else if(lvOverlayPhotoRotation > 90 && lvOverlayPhotoRotation < 180) {
                                        lvOverlayPhotoRotation = value + 270
                                    }
                                }else{
                                    lvOverlayPhotoRotation = value - 90
                                }
                            }else if(lv_rotation == 90){
                                if(lvOverlayPhotoRotation < -90 && lvOverlayPhotoRotation > -180 || lvOverlayPhotoRotation > 90 && lvOverlayPhotoRotation < 180){
                                    if(lvOverlayPhotoRotation < -90 && lvOverlayPhotoRotation>-180){
                                        lvOverlayPhotoRotation= value - 270
                                    }
                                    else if(lvOverlayPhotoRotation > 90 && lvOverlayPhotoRotation < 180){
                                        lvOverlayPhotoRotation = value + 90
                                    }
                                }else {
                                    lvOverlayPhotoRotation = value + 90
                                }
                            }else if(lv_rotation == 0){
                                lvOverlayPhotoRotation = value
                            }
                        }
                        if(lvOverlayPhotoFrameAlias.mourorate1.drag.active != true){
                            overlayPhotoFrame.rotation = lvOverlayPhotoRotation
                        }
                        spinboxRotation.realValue = value
                        updateCursorScale()
//                        ltLog.log(LT.TagDef.RecLvl_Info,
//                                  LT.TagDef.RTScr_Usage_LiveView_OverlayPhotoRotationSlider,
//                                  "LTOverlayPhotoPopup RotationSlider changed",
//                                  lvOverlayPhotoRotation)
                    }
                }

                Canvas {
                    id: canvasRotation
                    // ivc >> start >> USBTHRV140-40
                    //x: sliderRotation.visualPosition * (sliderRotation.leftPadding + sliderRotation.availableWidth - width / 2) + sliderRotation.x
                    x: sliderRotation.x + sliderRotation.leftPadding + (sliderRotation.visualPosition * sliderRotation.availableWidth) - width/2
                    // ivc << end << USBTHRV140-40
                    y: sliderRotation.y + sliderRotation.topPadding + sliderRotation.availableHeight/2 + backgroundRotation.height/2 + 1
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

                SpinBox {
                    id: spinboxRotation
                    x: sliderRotation.x + sliderRotation.width
                    y: 25
                    width: 62
                    editable: true
                    value: 0
                    stepSize: 1
                    from: -1800
                    to: 1800
                     property int decimals: 1
                    property real realValue: spinboxRotation.value / 10

                    validator: DoubleValidator {
                        bottom: Math.min(spinboxRotation.from, spinboxRotation.to)
                        top: Math.max(spinboxRotation.from, spinboxRotation.to)
                    }

                    textFromValue: function(value, locale) {
                        return Number(value / 10).toLocaleString(locale, 'f', spinboxRotation.decimals)
                    }
                    valueFromText: function(text, locale) {
                        return Number.fromLocaleString(locale, text) * 10
                    }

                    // ivc >> start >> USBTHRV160-11
                    font.pixelSize: 9
                    // ivc << end << USBTHRV160-11
                    onRealValueChanged: {
                        value = realValue * 10
                    }
                    onValueChanged: {
                        realValue = value / 10
                        sliderRotation.value = realValue
//                        ltLog.log(LT.TagDef.RecLvl_Info,
//                                  LT.TagDef.RTScr_Usage_LiveView_OverlayPhotoRotationSpinbox,
//                                  "LTOverlayPhotoPopup RotationSpinbox changed",
//                                  lvOverlayPhotoRotation)
                    }
                }
            }

            // Aspect ratio
            Rectangle {
                id: ratio_id
                visible:true
                width: back.width - 2
                height: 65
                color: "#000000"
                border.color: "#202022"

                LTStylishText {
                    id: text_Ratio
                    x: 10
                    y: 6

                    type: text_style_overlayPopup12
                    text: qsTr("Ratio(0 - 100%)")
                    visible: true
                }

                Basic.Slider {
                    id: sliderRatio
                    width: parent.width / 3 * 2 - 15
                    value: lvOverlayPhotoAspectRatio
                    x:20
                    y:20
                    from: 1.0
                    to: 0.00
                    stepSize: 0.01
                    background: Rectangle {
                        id: backgroundRatio
                        x: sliderRatio.leftPadding
                        y: sliderRatio.topPadding + sliderRatio.availableHeight / 2 - height / 2
                        implicitWidth: 150
                        implicitHeight: 4
                        width: sliderRatio.availableWidth
                        height: implicitHeight
                        radius: 2
                        color: "#525256"
                        Rectangle {
                            // ivc >> start >> USBTHRV140-37
                            //width: sliderRatio.visualPosition * parent.width
                            // ivc >> start >> USBTHRV140-40
                            //x: handleRatio.x - 2
                            id: markRatio
                            x: sliderRatio.visualPosition * parent.width - width/2
                            // ivc << end << USBTHRV140-40
                            width: 3
                            // ivc << end << USBTHRV140-37
                            height: parent.height
                            // USBTHRV100-72 メモリ、▲とも R,G,B: 255,204,0 でお願い致します。
                            color: Qt.rgba(255, 204, 0);
                            radius: 2
                        }
                    }
                    handle: Rectangle {
                        id: handleRatio
                        // ivc >> start >> USBTHRV140-40
//                        // ivc >> start >> USBTHRV140-37
//                        //x: sliderRatio.visualPosition * (sliderRatio.leftPadding + sliderRatio.availableWidth - width)
//                        x: sliderRatio.visualPosition * (sliderRatio.leftPadding + sliderRatio.availableWidth - width/2)
//                        // ivc << end << USBTHRV140-37
                        x: sliderRatio.leftPadding + (sliderRatio.visualPosition * sliderRatio.availableWidth) - width/2
                        // ivc << end << USBTHRV140-40
                        y: sliderRatio.topPadding + sliderRatio.availableHeight/2 - height/2
                        // ivc >> start >> USBTHRV140-40
                        //implicitWidth: 16
                        implicitWidth: 3
                        // ivc << end << USBTHRV140-40
                        implicitHeight: 20
                        visible: false
                    }
                    onValueChanged: {
                        spinboxRatio.value = (1 - value) * 100
//                        ltLog.log(LT.TagDef.RecLvl_Info,
//                                  LT.TagDef.RTScr_Usage_LiveView_OverlayPhotoRatioSlider,
//                                  "LTOverlayPhotoPopup RatioSlider changed",
//                                  lvOverlayPhotoAspectRatio)
                    }
                }

                Canvas {
                    id: canvasRatio
                    // ivc >> start >> USBTHRV140-40
                    //x: sliderRatio.visualPosition * (sliderRatio.leftPadding + sliderRatio.availableWidth - width/2) + sliderRatio.x
                    x: sliderRatio.x + sliderRatio.leftPadding + (sliderRatio.visualPosition * sliderRatio.availableWidth) - width/2
                    // ivc << end << USBTHRV140-40
                    y: sliderRatio.y + sliderRatio.topPadding + sliderRatio.availableHeight/2 + backgroundRatio.height/2 + 1
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

                SpinBox {
                    id: spinboxRatio
                    x: sliderRatio.x + sliderRatio.width
                    y: 25
                    editable: true
                    stepSize: 1
                    value: 50
                    from: 0
                    to: 100
                    width: 62
                    // ivc >> start >> USBTHRV160-11
                    font.pixelSize: 9
                    // ivc << end << USBTHRV160-11
                    onValueChanged: {
                        lvOverlayPhotoAspectRatio = (100 - value) / 100
                        lvOverlayPhotoFrameAlias.overlayImagealias.opacity = (100 - value) / 100
//                        ltLog.log(LT.TagDef.RecLvl_Info,
//                                  LT.TagDef.RTScr_Usage_LiveView_OverlayPhotoRatioSpinbox,
//                                  "LTOverlayPhotoPopup RatioSpinbox changed",
//                                  lvOverlayPhotoAspectRatio)
                    }
                }
            }

            // Reset button
            Rectangle {
                id: reset_id
                visible:true
                width: back.width - 2
                height: bottom_btn_height
                color: "#000000"
                border.color: "#202022"

                LTRectangleButton {
                    id: btnReset
                    anchors.fill: parent
                    fillColor: palette.defaultColor
                    strokeWidth: 1
                    strokeColor: palette.backgroundLight
                    buttonText: qsTr("Reset setting")
                    type: "action_small"


                    logCol: ltLog
                    logScrTagID: LT.TagDef.RTScr_Usage_LiveView_OverlayPhotoResetSetting
                    logFile: "resetbutton"

                    onClicked: {
                        lvOverlayPhotoAspectRatio = 0.5
                        sliderPosX.value = 0
                        sliderPosY.value = 0
                        lvOverlayPhotoScaling = lvOverlayPhotoScalingDefault
                        //ivc >> start >> #7685
                        sliderRotation.value=0
                        //ivc << end << #7685
                        submitValueOverlaySetting()
                        updateCursorScale()
                    }
                }
            }

            // Confirm button
            Rectangle {
                id: confirm_id
                visible:true
                width: back.width - 2
                height: bottom_btn_height
                color: "#000000"
                border.color: "#202022"

                Row {
                    anchors.fill: parent
                    spacing: 0
                    // OK button
                    LTRectangleButton {
                        id: btnOK
                        width: parent.width / 2
                        height: parent.height
                        fillColor: "#525356"
                        strokeWidth: 1
                        strokeColor: palette.backgroundLight
                        buttonText: qsTr("OK")
                        type: "action_small"
                        logCol: ltLog
                        logScrTagID: LT.TagDef.RTScr_Usage_LiveView_OverlayPhotoSetSetting
                        logFile: "okbutton"
                        function submitValueOverlaySetting() {
                            lvOverlayPhotoSavedPosX = lvOverlayPhotoPosX
                            lvOverlayPhotoSavedPosY = lvOverlayPhotoPosY
                            lvOverlayPhotoSavedRotation = lvOverlayPhotoRotation
                            lvOverlayPhotoSavedScaling = lvOverlayPhotoScaling
                            lvOverlayPhotoSavedAspectRatio = lvOverlayPhotoAspectRatio
                            lvOverlayPhotoFlagSubmit = true
                        }
                        onClicked: {
                            submitValueOverlaySetting()
                            dismiss()
                        }
                    }

                    // Cancel button
                    LTRectangleButton {
                        id: btnCancel
                        width: parent.width / 2
                        height: parent.height
                        fillColor: "#525356"
                        strokeWidth: 1
                        strokeColor: palette.backgroundLight
                        buttonText: qsTr("Cancel")
                        type: "action_small"
                        logCol: ltLog
                        logScrTagID: LT.TagDef.RTScr_Usage_LiveView_OverlayPhotoCancel
                        logFile: "cancelbutton"

                        onClicked: {
                            cancelSettingOverlay()
                            dismiss()
                            updateCursorScale()
                        }
                    }
                }
            }
        }
    }
}
