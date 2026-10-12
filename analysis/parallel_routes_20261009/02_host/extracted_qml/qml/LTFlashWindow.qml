//ndtri - add - LTFlashWindow
import QtQuick 2.6
import QtQuick.Window 2.3
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.1

import "qrc:/qml"
import LT 1.0 as LT
import "LTSubFunction.js" as LTSubFunction

/*! \qmltype LTFlashWindow
    \inqmlmodule LT

    \brief
    Flash setting window
 */
Window {
    id: root

    LTLogCollector {
        id: ltLog

        logMajTagID: LT.TagDef.RTMajor_Usage
        logMedTagID: LT.TagDef.RTMed_Usage_Flash
        logWindowName: "LTFlashWindow"
    }

    LTWindowStateSaver {
        id:windowState
        window: root
        defaultWidth: minimumWidth
        defaultHeight: minimumHeight
        targetWindow: LT.ApplicationSettings.WinList_Flash
    }
    property bool lastMaximised: windowState.curMaximised

    /*!
        Item size: width
     */
    readonly property real flItemWidth: 107

    /*!
        Item size: height
     */
    readonly property real flItemHeight: 77

    /*!
        Separator button size: height
     */
    readonly property real flLineBtnHeight: 40

    /*!
        Window size: width
     */
    readonly property real flWindowWidth: 323

    /*!
        Window size: compact height: 3 rows + separator button
     */
    readonly property real flWindowCompactHeight: flItemHeight * 3 + flLineBtnHeight

    /*!
        Window size: default height: 3 rows + separator button + 5 rows + separator button
     */
    readonly property real flWindowDefaultHeight: flItemHeight * 3 + flLineBtnHeight + flItemHeight * 5 + flLineBtnHeight

    /*!
        必要最小表示か否かを示します
     */
    property bool compact: (flashAdapter.wirelessMode == LT.Utilities.WirM_Off) ? true: false//applicationSettings.flashWindowSize == LT.ApplicationSettings.WindowShrinked

    readonly property int panelBuildInFlashBtn2: 100
    readonly property int panelBuildInFlashBtn3: 101	// USBTHRV140-97
    readonly property int panelAGroupBtn2:       102
    readonly property int panelAGroupBtn3:       103	// (USBTHRV140-97, 参照元)
    readonly property int panelBGroupBtn2:       104
    readonly property int panelBGroupBtn3:       105
    readonly property int panelCGroupBtn2:       106
    readonly property int panelCGroupBtn3:       107

    flags:
//        Qt.Window
        Qt.Dialog
      | Qt.CustomizeWindowHint
      | Qt.WindowTitleHint
//      | Qt.WindowSystemMenuHint
      | Qt.WindowMinimizeButtonHint
//    | Qt.WindowMaximizeButtonHint
      | Qt. WindowCloseButtonHint
    |Qt.MSWindowsFixedSizeDialogHint

    minimumWidth: flWindowWidth
    maximumWidth: minimumWidth

    //minimumHeight: compact ? flWindowCompactHeight : flWindowDefaultHeight
    //Behavior on minimumHeight { NumberAnimation { duration: 150; easing.type: Easing.Linear}}//OutBounce }}
    //maximumHeight: minimumHeight
    //Behavior on maximumHeight { NumberAnimation { duration: 150; easing.type: Easing.Linear}}//OutBounce }}

    width: minimumWidth
    //height: minimumHeight
    height: flWindowDefaultHeight
    //Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.Linear}}//OutBounce }}

    Timer {
        id: animation_timer
        interval: 50
        running: false
        repeat: true

        readonly property int mode_ini: 0
        readonly property int mode_normal: 1
        readonly property int mode_compact: 2
        property int mode: mode_ini

        readonly property int resize: 150
        onTriggered: {
            var h = root.height
            if(mode == mode_compact) {
                h -= resize
                if(h <= flWindowCompactHeight) {
                    h = flWindowCompactHeight
                    root.maximumHeight = flWindowCompactHeight

                    wirelessModeButton.disabled = false
                    wirelessModeButton.enabled = true

                    mode = mode_ini
                    running = false
                }
                root.height = h
            } else if(mode == mode_normal) {
                h += resize
                if(h >= flWindowDefaultHeight) {
                    h = flWindowDefaultHeight
                    root.minimumHeight = flWindowDefaultHeight

                    wirelessModeButton.disabled = false
                    wirelessModeButton.enabled = true

                    mode = mode_ini
                    running = false
                }
                root.height = h
            }
        }
    }

    title: qsTr("Flash")
    color: palette.backgroundLight//"transparent"

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
        "defaultColor": "#525356",
        "selectedColor": "#FFD600"
    }

    /*!
        Receive flashDimmerChanged event
     */
    function flashDimmerSetting() {
        //console.log("flashDimmerSetting start: ", flashAdapter.flashDimmer);
        btnOptionFlshDimmer.optionSelect(flashAdapter.flashDimmer);
        //flashAdjust.enabled = (((flashAdapter.wirelessMode == LT.Utilities.WirM_Off) && (flashAdapter.flashDimmer == LT.Utilities.FlshDim_TTL))? true: false)
        //flashManual.enabled = (((flashAdapter.wirelessMode == LT.Utilities.WirM_Off) && (flashAdapter.flashDimmer == LT.Utilities.FlshDim_Manual))? true: false)
    }

    /*!
        Receive flashModeChanged event
     */
    function flashModeSetting() {
        //console.log("flashModeSetting start: ", flashAdapter.flashMode);
        btnOptionFlshMode.optionSelect(flashAdapter.flashMode);
    }

    /*!
        Receive flashSyncChanged event
     */
    function flashSyncSetting() {
        //console.log("flashSyncSetting start: ", flashAdapter.flashSync);
        btnOptionFlshSync.optionSelect(flashAdapter.flashSync);
    }

    /*!
        Receive exposureLinkChanged event
     */
    function exposureLinkSetting() {
        //console.log("exposureLinkSetting start: ", flashAdapter.exposureLink);
        btnOptionExpLink.optionSelect(flashAdapter.exposureLink);
    }

    /*!
        Receive wirelessModeChanged event
     */
    function wirelessModeSetting() {
        LTSubFunction.console_debug.out("wirelessModeSetting start: ", flashAdapter.wirelessMode);

        // ポップアップクローズ
        optionButtonPopupClose()
        flashSliderPopupClose()

        wirelessModeButton.checked = (flashAdapter.wirelessMode == LT.Utilities.WirM_Off) ? false: true;
        wirelessModeButton.enabled = true

        compact = (flashAdapter.wirelessMode == LT.Utilities.WirM_Off) ? true: false;
        root.minimumHeight = compact ? flWindowCompactHeight : flWindowDefaultHeight;
        root.maximumHeight = compact ? flWindowCompactHeight : flWindowDefaultHeight;
        root.height = compact ? flWindowCompactHeight : flWindowDefaultHeight;

        //btnOptionFlshDimmer.enabled = ((flashAdapter.wirelessMode == LT.Utilities.WirM_Off)? true: false)
        //btnOptionFlshSync.enabled = ((flashAdapter.wirelessMode == LT.Utilities.WirM_Off)? true: false)
        //flashAdjust.enabled = (((flashAdapter.wirelessMode == LT.Utilities.WirM_Off) && (flashAdapter.flashDimmer == LT.Utilities.FlshDim_TTL))? true: false)
        //flashManual.enabled = (((flashAdapter.wirelessMode == LT.Utilities.WirM_Off) && (flashAdapter.flashDimmer == LT.Utilities.FlshDim_Manual))? true: false)
    }
    function wirelessModeInnerSetting() {
        LTSubFunction.console_debug.out("wirelessModeInnerSetting start: ", flashAdapter.wirelessMode);

        compact = (flashAdapter.wirelessMode == LT.Utilities.WirM_Off)? true: false;
        wirelessModeButton.checked = compact ? false: true

        if(!animation_timer.mode) {
            if(root.height == flWindowDefaultHeight) {
                animation_timer.mode = animation_timer.mode_compact
                root.minimumHeight = flWindowCompactHeight
                wirelessModeButton.disabled = true
            } else if(root.height == flWindowCompactHeight) {
                animation_timer.mode = animation_timer.mode_normal
                root.maximumHeight = flWindowDefaultHeight
                wirelessModeButton.disabled = true
            }
            animation_timer.running = true
        } else {
            wirelessModeButton.enabled = true
        }
    }

    /*!
        Receive wirelessChannelChanged event
     */
    function wirelessChannelSetting() {
        //console.log("wirelessChannelSetting start: ", flashAdapter.wirelessChannel);
        btnOptionWirChannel.optionSelect(flashAdapter.wirelessChannel);
    }

    /*!
        Receive wirelessFPChanged event
     */
    function wirelessFpSetting() {
        //console.log("wirelessFpSetting start: ", flashAdapter.wirelessFP);
        btnOptionWirFp.optionSelect(flashAdapter.wirelessFP);
    }

    /*!
        Receive wirelessComPowerChanged event
     */
    function wirelessComPowerSetting() {
        //console.log("wirelessComPowerSetting start: ", flashAdapter.wirelessComPower);
        btnOptionWirComPower.optionSelect(flashAdapter.wirelessComPower);
    }

    function flashAdjustSetting() {
        //console.log("flashAdjustSetting start: ", flashAdapter.flashAdjust);

        if(flashAdapter.flashAdjustCapabilityNum() == 0) {
            flashAdjust.enabled = false
        } else {
            flashAdjust.enabled = true
        }

        sliderFlashAdjust.curIndex = flashAdapter.flashAdjust;
    }

    function flashManualSetting() {
        //console.log("flashManualSetting start: ", flashAdapter.flashManual);

        if(flashAdapter.flashManualCapabilityNum() == 0) {
            flashManual.enabled = false
        } else {
            flashManual.enabled = true
        }

        sliderFlashManual.curIndex = flashAdapter.flashManual;
    }

    function buildInFlashDimmerSetting() {
        //console.log("buildInFlashDimmerSetting start: ", flashAdapter.buildInFlashDimmer);
        panelBuildInFlash.btn1.optionSelect(flashAdapter.buildInFlashDimmer);
    }

    function aGroupDimmerSetting() {
        //console.log("aGroupDimmerSetting start: ", flashAdapter.aGroupDimmer);
        panelAGroup.btn1.optionSelect(flashAdapter.aGroupDimmer);
        switch(flashAdapter.aGroupDimmer) {
        case LT.FlashAdapter.GFD_TTL:
            //panelAGroup.btn2.enabled = true
            //panelAGroup.btn3.enabled = false
            break;
        case LT.FlashAdapter.GFD_Manual:
            //panelAGroup.btn2.enabled = false
            //panelAGroup.btn3.enabled = true
            break;
        case LT.FlashAdapter.GFD_Off:
        case LT.FlashAdapter.GFD_Auto:
        case LT.FlashAdapter.GFD_Unknown:// = -1,
        case LT.FlashAdapter.GFD_Max:
        default:
            //panelAGroup.btn2.enabled = false
            //panelAGroup.btn3.enabled = false
            break;
        }
    }

    function bGroupDimmerSetting() {
        //console.log("bGroupDimmerSetting start: ", flashAdapter.bGroupDimmer);
        panelBGroup.btn1.optionSelect(flashAdapter.bGroupDimmer);
        switch(flashAdapter.bGroupDimmer) {
        case LT.FlashAdapter.GFD_TTL:
            //panelBGroup.btn2.enabled = true
            //panelBGroup.btn3.enabled = false
            break;
        case LT.FlashAdapter.GFD_Manual:
            //panelBGroup.btn2.enabled = false
            //panelBGroup.btn3.enabled = true
            break;
        case LT.FlashAdapter.GFD_Off:
        case LT.FlashAdapter.GFD_Auto:
        case LT.FlashAdapter.GFD_Unknown:// = -1,
        case LT.FlashAdapter.GFD_Max:
        default:
            //panelBGroup.btn2.enabled = false
            //panelBGroup.btn3.enabled = false
            break;
        }
    }

    function cGroupDimmerSetting() {
        //console.log("cGroupDimmerSetting start: ", flashAdapter.cGroupDimmer);
        panelCGroup.btn1.optionSelect(flashAdapter.cGroupDimmer);
        switch(flashAdapter.cGroupDimmer) {
        case LT.FlashAdapter.GFD_TTL:
            //panelCGroup.btn2.enabled = true
            //panelCGroup.btn3.enabled = false
            break;
        case LT.FlashAdapter.GFD_Manual:
            //panelCGroup.btn2.enabled = false
            //panelCGroup.btn3.enabled = true
            break;
        case LT.FlashAdapter.GFD_Off:
        case LT.FlashAdapter.GFD_Auto:
        case LT.FlashAdapter.GFD_Unknown:// = -1,
        case LT.FlashAdapter.GFD_Max:
        default:
            //panelCGroup.btn2.enabled = false
            //panelCGroup.btn3.enabled = false
            break;
        }
    }

    function buildInFlashAdjustSetting() {
        //console.log("buildInFlashAdjustSetting start: ", flashAdapter.buildInFlashAdjust);

        if(flashAdapter.buildInFlashAdjustCapabilityNum() == 0) {
            panelBuildInFlash.btn2.enabled = false
            panelBuildInFlash.btn2.disabled = true
        } else {
            panelBuildInFlash.btn2.enabled = true
            panelBuildInFlash.btn2.disabled = false
        }

        panelBuildInFlash.btn2.value = flashAdapter.buildInFlashAdjust;
        panelBuildInFlash.btn2.optionText = textValueFormat(flashAdapter.buildInFlashAdjust, "adjust");
        var text1 = "<HTML>"
        var text2 = qsTr("Built-in Flash")
        var text3 = "<br>"
        var text4 = qsTr("Flash Light Adjustment")
        var text5 = "<br>"
        var text6 = panelBuildInFlash.btn2.optionText
        var text7 = "</HTML>"
        var disp_text = text1 + text2 + text3 + text4 + text5 + text6 + text7
        panelBuildInFlash.btn2.optionTextTooltip = disp_text

        if (flashSliderPopup.source == panelBuildInFlash.btn2) {
            flashSliderPopup.sliderObj.curIndex = flashAdapter.buildInFlashAdjust;
        }
    }

    function aGroupFlashAdjustSetting() {
        //console.log("aGroupFlashAdjustSetting start: ", flashAdapter.aGroupFlashAdjust);

        if(flashAdapter.aGroupFlashAdjustCapabilityNum() == 0) {
            panelAGroup.btn2.enabled = false
            panelAGroup.btn2.disabled = true
        } else {
            panelAGroup.btn2.enabled = true
            panelAGroup.btn2.disabled = false
        }

        panelAGroup.btn2.value = flashAdapter.aGroupFlashAdjust;
        panelAGroup.btn2.optionText = textValueFormat(flashAdapter.aGroupFlashAdjust, "adjust");
        var text1 = "<HTML>"
        var text2 = qsTr("A Group")
        var text3 = "<br>"
        var text4 = qsTr("Flash Light Adjustment")
        var text5 = "<br>"
        var text6 = panelAGroup.btn2.optionText
        var text7 = "</HTML>"
        var disp_text = text1 + text2 + text3 + text4 + text5 + text6 + text7
        panelAGroup.btn2.optionTextTooltip = disp_text

        if (flashSliderPopup.source == panelAGroup.btn2) {
            flashSliderPopup.sliderObj.curIndex = flashAdapter.aGroupFlashAdjust;
        }
    }

    function bGroupFlashAdjustSetting() {
        //console.log("bGroupFlashAdjustSetting start: ", flashAdapter.bGroupFlashAdjust);

        if(flashAdapter.bGroupFlashAdjustCapabilityNum() == 0) {
            panelBGroup.btn2.enabled = false
            panelBGroup.btn2.disabled =true
        } else {
            panelBGroup.btn2.enabled = true
            panelBGroup.btn2.disabled = false
        }

        panelBGroup.btn2.value = flashAdapter.bGroupFlashAdjust;
        panelBGroup.btn2.optionText = textValueFormat(flashAdapter.bGroupFlashAdjust, "adjust");
        var text1 = "<HTML>"
        var text2 = qsTr("B Group")
        var text3 = "<br>"
        var text4 = qsTr("Flash Light Adjustment")
        var text5 = "<br>"
        var text6 = panelBGroup.btn2.optionText
        var text7 = "</HTML>"
        var disp_text = text1 + text2 + text3 + text4 + text5 + text6 + text7
        panelBGroup.btn2.optionTextTooltip = disp_text

        if (flashSliderPopup.source == panelBGroup.btn2) {
            flashSliderPopup.sliderObj.curIndex = flashAdapter.bGroupFlashAdjust;
        }

    }

    function cGroupFlashAdjustSetting() {
        //console.log("cGroupFlashAdjust start: ", flashAdapter.cGroupFlashAdjust);

        if(flashAdapter.cGroupFlashAdjustCapabilityNum() == 0) {
            panelCGroup.btn2.enabled = false
            panelCGroup.btn2.disabled = true
        } else {
            panelCGroup.btn2.enabled = true
            panelCGroup.btn2.disabled = false
        }

        panelCGroup.btn2.value = flashAdapter.cGroupFlashAdjust;
        panelCGroup.btn2.optionText = textValueFormat(flashAdapter.cGroupFlashAdjust, "adjust");
        var text1 = "<HTML>"
        var text2 = qsTr("C Group")
        var text3 = "<br>"
        var text4 = qsTr("Flash Light Adjustment")
        var text5 = "<br>"
        var text6 = panelCGroup.btn2.optionText
        var text7 = "</HTML>"
        var disp_text = text1 + text2 + text3 + text4 + text5 + text6 + text7
        panelCGroup.btn2.optionTextTooltip = disp_text

        if (flashSliderPopup.source == panelCGroup.btn2) {
            flashSliderPopup.sliderObj.curIndex = flashAdapter.cGroupFlashAdjust;
        }
    }

    function buildInFlashManualSetting() {	// USBTHRV140-97 >>
        //console.log("buildInFlashManualSetting start: ", flashAdapter.buildInFlashManual);

        if(flashAdapter.buildInFlashManualCapabilityNum() == 0) {
            panelBuildInFlash.btn3.enabled = false
            panelBuildInFlash.btn3.disabled = true
        } else {
            panelBuildInFlash.btn3.enabled = true
            panelBuildInFlash.btn3.disabled = false
        }

        panelBuildInFlash.btn3.value = flashAdapter.buildInFlashManual;
        panelBuildInFlash.btn3.optionText = textValueFormat(flashAdapter.buildInFlashManual, "manual");
        var text1 = "<HTML>"
        var text2 = qsTr("Built-in Flash")
        var text3 = "<br>"
        var text4 = qsTr("Flash Light Manual")
        var text5 = "<br>"
        var text6 = panelBuildInFlash.btn3.optionText
        var text7 = "</HTML>"
        var disp_text = text1 + text2 + text3 + text4 + text5 + text6 + text7
        panelBuildInFlash.btn3.optionTextTooltip = disp_text

        if (flashSliderPopup.source == panelBuildInFlash.btn3) {
            flashSliderPopup.sliderObj.curIndex = flashAdapter.buildInFlashManual;
        }
    }	// << USBTHRV140-97

    function aGroupFlashManualSetting() {	// (USBTHRV140-97, 参照元) >>
        //console.log("aGroupFlashManualSetting start: ", flashAdapter.aGroupFlashManual);

        if(flashAdapter.aGroupFlashManualCapabilityNum() == 0) {
            panelAGroup.btn3.enabled = false
            panelAGroup.btn3.disabled = true
        } else {
            panelAGroup.btn3.enabled = true
            panelAGroup.btn3.disabled = false
        }

        panelAGroup.btn3.value = flashAdapter.aGroupFlashManual;
        panelAGroup.btn3.optionText = textValueFormat(flashAdapter.aGroupFlashManual, "manual");
        var text1 = "<HTML>"
        var text2 = qsTr("A Group")
        var text3 = "<br>"
        var text4 = qsTr("Flash Light Manual")
        var text5 = "<br>"
        var text6 = panelAGroup.btn3.optionText
        var text7 = "</HTML>"
        var disp_text = text1 + text2 + text3 + text4 + text5 + text6 + text7
        panelAGroup.btn3.optionTextTooltip = disp_text

        if (flashSliderPopup.source == panelAGroup.btn3) {
            flashSliderPopup.sliderObj.curIndex = flashAdapter.aGroupFlashManual;
        }
    }	// << (USBTHRV140-97, 参照元)

    function bGroupFlashManualSetting() {
        //console.log("bGroupFlashManualSetting start: ", flashAdapter.bGroupFlashManual);

        if(flashAdapter.bGroupFlashManualCapabilityNum() == 0) {
            panelBGroup.btn3.enabled = false
            panelBGroup.btn3.disabled = true
        } else {
            panelBGroup.btn3.enabled = true
            panelBGroup.btn3.disabled = false
        }

        panelBGroup.btn3.value = flashAdapter.bGroupFlashManual;
        panelBGroup.btn3.optionText = textValueFormat(flashAdapter.bGroupFlashManual, "manual");
        var text1 = "<HTML>"
        var text2 = qsTr("B Group")
        var text3 = "<br>"
        var text4 = qsTr("Flash Light Manual")
        var text5 = "<br>"
        var text6 = panelBGroup.btn3.optionText
        var text7 = "</HTML>"
        var disp_text = text1 + text2 + text3 + text4 + text5 + text6 + text7
        panelBGroup.btn3.optionTextTooltip = disp_text

        if (flashSliderPopup.source == panelBGroup.btn3) {
            flashSliderPopup.sliderObj.curIndex = flashAdapter.bGroupFlashManual;
        }
    }

    function cGroupFlashManualSetting() {
        //console.log("cGroupFlashManual start: ", flashAdapter.cGroupFlashManual);

        if(flashAdapter.cGroupFlashManualCapabilityNum() == 0) {
            panelCGroup.btn3.enabled = false
            panelCGroup.btn3.disabled = true
        } else {
            panelCGroup.btn3.enabled = true
            panelCGroup.btn3.disabled = false
        }

        panelCGroup.btn3.value = flashAdapter.cGroupFlashManual;
        panelCGroup.btn3.optionText = textValueFormat(flashAdapter.cGroupFlashManual, "manual");
        var text1 = "<HTML>"
        var text2 = qsTr("C Group")
        var text3 = "<br>"
        var text4 = qsTr("Flash Light Manual")
        var text5 = "<br>"
        var text6 = panelCGroup.btn3.optionText
        var text7 = "</HTML>"
        var disp_text = text1 + text2 + text3 + text4 + text5 + text6 + text7
        panelCGroup.btn3.optionTextTooltip = disp_text

        if (flashSliderPopup.source == panelCGroup.btn3) {
            flashSliderPopup.sliderObj.curIndex = flashAdapter.cGroupFlashManual;
        }
    }

    function textValueFormat(index, type) {
        var txtValue = "";
        var val = index;

        if (type == "manual") {
            val = utilities.enumFlashManualToVal(index);
            if (val == 0) {
                return "1/1";
            }
            txtValue = "1/"+(val/10);
            return txtValue;

        } else if (type == "exposure") {
            val = hexToDec(utilities.enumExposureToVal(index));
        } else if (type == "adjust") {
            val = hexToDec(utilities.enumFlashAdjToVal(index));
        }

        if (val == 0) {
            return "0 EV";
        }

        var rem = val%3;
        var div = Math.abs((val-rem)/3);
        rem = Math.abs(rem);

        var txtSig = (val < 0) ? "-" : "";
        var txtDiv = (div != 0 ? div + " " : "");
        var txtRem = (rem != 0 ? rem + "/3 " : "");

        txtValue = txtSig + txtDiv + txtRem + "EV";

        return txtValue;
    }

    function hexToDec(hexVal) {
        var sig = (hexVal >> 15) ? -1 : 1;
        var ret = sig * (hexVal & ~(1 << 15));

        return ret;
    }

    function cameraValueGetComplete() {
        flashDimmerSetting();
        flashModeSetting();
        flashSyncSetting();
        exposureLinkSetting();
        wirelessModeSetting();
        wirelessChannelSetting();
        wirelessFpSetting();
        wirelessComPowerSetting();

        flashAdjustSetting();
        flashManualSetting();

        buildInFlashDimmerSetting();
        aGroupDimmerSetting();
        bGroupDimmerSetting();
        cGroupDimmerSetting();

        buildInFlashAdjustSetting();
        aGroupFlashAdjustSetting();
        bGroupFlashAdjustSetting();
        cGroupFlashAdjustSetting();

        buildInFlashManualSetting();    // USBTHRV140-97
        aGroupFlashManualSetting();     // (USBTHRV140-97, 参照元)
        bGroupFlashManualSetting();
        cGroupFlashManualSetting();
    }

    function onFlashPopupOKClicked(btnId) {
        LTSubFunction.console_debug.out("LTFlashWindow::onFlashPopupOKClicked", btnId)
        switch(btnId) {
        case panelBuildInFlashBtn2:// 100
            ltLog.log(LT.TagDef.RecLvl_Info,
                      LT.TagDef.RTScr_Usage_Flash_BuildinFlashAdjust,
                      "buildInFlashAdjust Ok",
                      "");

            buildInFlashAdjustSetting()
            break;
        case panelBuildInFlashBtn3://       101	// USBTHRV140-97 >>
            ltLog.log(LT.TagDef.RecLvl_Info,
                      LT.TagDef.RTScr_Usage_Flash_BuildinFlashManual,
                      "buildInFlashManual Ok",
                      "");

            buildInFlashManualSetting()
            break;	// << USBTHRV140-97
        case panelAGroupBtn2://       102
            ltLog.log(LT.TagDef.RecLvl_Info,
                      LT.TagDef.RTScr_Usage_Flash_GroupAFlashAdjust,
                      "aGroupFlashAdjust Ok",
                      "");

            aGroupFlashAdjustSetting()
            break;
        case panelAGroupBtn3://       103	// (USBTHRV140-97, 参照元) >>
            ltLog.log(LT.TagDef.RecLvl_Info,
                      LT.TagDef.RTScr_Usage_Flash_GroupAFlashManual,
                      "aGroupFlashManual Ok",
                      "");

            aGroupFlashManualSetting()
            break;	// << (USBTHRV140-97, 参照元)
        case panelBGroupBtn2://       104
            ltLog.log(LT.TagDef.RecLvl_Info,
                      LT.TagDef.RTScr_Usage_Flash_GroupBFlashAdjust,
                      "bGroupFlashAdjust Ok",
                      "");

            bGroupFlashAdjustSetting()
            break;
        case panelBGroupBtn3://       105
            ltLog.log(LT.TagDef.RecLvl_Info,
                      LT.TagDef.RTScr_Usage_Flash_GroupBFlashManual,
                      "bGroupFlashManual Ok",
                      "");

            bGroupFlashManualSetting()
            break;
        case panelCGroupBtn2://       106
            ltLog.log(LT.TagDef.RecLvl_Info,
                      LT.TagDef.RTScr_Usage_Flash_GroupCFlashAdjust,
                      "cGroupFlashAdjust Ok",
                      "");

            cGroupFlashAdjustSetting()
            break;
        case panelCGroupBtn3://       107
            ltLog.log(LT.TagDef.RecLvl_Info,
                      LT.TagDef.RTScr_Usage_Flash_GroupCFlashManual,
                      "cGroupFlashManual Ok",
                      "");

            cGroupFlashManualSetting()
            break;
        default:
            break;
        }
        //object.changedValue(flashSliderPopup.sliderObj.value);
    }

    function onFlashPopupCancelClicked(btnId) {
        LTSubFunction.console_debug.out("LTFlashWindow::onFlashPopupCancelClicked", btnId)

        switch(btnId) {
        case panelBuildInFlashBtn2:// 100
            ltLog.log(LT.TagDef.RecLvl_Info,
                      LT.TagDef.RTScr_Usage_Flash_BuildinFlashAdjust,
                      "buildInFlashAdjust Cancel",
                      "");
            break;
        case panelBuildInFlashBtn3://       101	// USBTHRV140-97 >>
            ltLog.log(LT.TagDef.RecLvl_Info,
                      LT.TagDef.RTScr_Usage_Flash_BuildinFlashManual,
                      "buildInFlashManual Cancel",
                      "");
            break;	// << USBTHRV140-97
        case panelAGroupBtn2://       102
            ltLog.log(LT.TagDef.RecLvl_Info,
                      LT.TagDef.RTScr_Usage_Flash_GroupAFlashAdjust,
                      "aGroupFlashAdjust Cancel",
                      "");
            break;
        case panelAGroupBtn3://       103	// (USBTHRV140-97, 参照元) >>
            ltLog.log(LT.TagDef.RecLvl_Info,
                      LT.TagDef.RTScr_Usage_Flash_GroupAFlashManual,
                      "aGroupFlashManual Cancel",
                      "");
            break;	// <<  (USBTHRV140-97, 参照元)
        case panelBGroupBtn2://       104
            ltLog.log(LT.TagDef.RecLvl_Info,
                      LT.TagDef.RTScr_Usage_Flash_GroupBFlashAdjust,
                      "bGroupFlashAdjust Cancel",
                      "");
            break;
        case panelBGroupBtn3://       105
            ltLog.log(LT.TagDef.RecLvl_Info,
                      LT.TagDef.RTScr_Usage_Flash_GroupBFlashManual,
                      "bGroupFlashManual Cancel",
                      "");
            break;
        case panelCGroupBtn2://       106
            ltLog.log(LT.TagDef.RecLvl_Info,
                      LT.TagDef.RTScr_Usage_Flash_GroupCFlashAdjust,
                      "cGroupFlashAdjust Cancel",
                      "");
            break;
        case panelCGroupBtn3://       107
            ltLog.log(LT.TagDef.RecLvl_Info,
                      LT.TagDef.RTScr_Usage_Flash_GroupCFlashManual,
                      "cGroupFlashManual Cancel",
                      "");
            break;
        default:
            break;
        }
    }

    function cameraStatusSetting() {
        var flg = false
        //---------------------------------
        //撮影スタンバイ 　　　→0
        //動画記録中(4K/6Kフォト含む) →1
        //動画再生中（4K/6Kフォト除く） →2
        //その他処理中 →3
        //動画以外再生中 →4
        //---------------------------------
        //テザー側で、カメラの状態が{ 2, 3, 4 }の時に操作中を表示するように
        //ご対応をお願いいたします
        if((deviceAdapter.cameraStatus === LT.Utilities.CamStatus_MovRec_Others) ||
           (deviceAdapter.cameraStatus === LT.Utilities.CamStatus_Playing) ||
           (deviceAdapter.cameraStatus === LT.Utilities.CamStatus_Processing) ||
// IVC >> Ver.1.9 >> start >> [THRBOXV100-162]
           (deviceAdapter.cameraStatus === LT.Utilities.CamStatus_Menu_Displayed)
// IVC << Ver.1.9 << end << [THRBOXV100-162]
           ){
            LTSubFunction.console_debug.out("FlashView::cameraStatusSetting cameraStatus " + deviceAdapter.cameraStatus)
            if(deviceAdapter.cameraStatus === LT.Utilities.CamStatus_Menu_Displayed) {
                maskpanel.mode |= maskpanel.mode_live_view_menu
                maskpanel.mode &= ~maskpanel.mode_camera
            } else {
                maskpanel.mode |= maskpanel.mode_camera
                maskpanel.mode &= ~maskpanel.mode_live_view_menu
            }
            updateMaskPanel()
        } else {
            LTSubFunction.console_debug.out("FlashView::cameraStatusSetting cameraStatus " + deviceAdapter.cameraStatus)
        }
    }

    function cameraStatusCompleteNotify() {
        LTSubFunction.console_debug.out("FlashView::cameraStatusCompleteNotify")
        if((deviceAdapter.cameraStatus !== LT.Utilities.CamStatus_MovRec_Others) &&
           (deviceAdapter.cameraStatus !== LT.Utilities.CamStatus_Playing) &&
           (deviceAdapter.cameraStatus !== LT.Utilities.CamStatus_Processing) &&
// IVC >> Ver.1.9 >> start >> [THRBOXV100-162]
           (deviceAdapter.cameraStatus !== LT.Utilities.CamStatus_Menu_Displayed)
// IVC << Ver.1.9 << end << [THRBOXV100-162]
           ){
            maskpanel.mode &= ~maskpanel.mode_camera
            maskpanel.mode &= ~maskpanel.mode_live_view_menu
            updateMaskPanel()
        }
    }

    function preferenceWindowVisibleSetting(flg) {
        LTSubFunction.console_debug.out("FlashView::preferenceWindowVisibleSetting flg=" + flg)
        if(flg) {
            maskpanel.mode |= maskpanel.mode_pref
        } else {
            maskpanel.mode &= ~maskpanel.mode_pref
        }
        updateMaskPanel()
    }

    function searchCamWindowVisibleSetting(flg){
        if(flg) {
            maskpanel.mode |= maskpanel.mode_searchWindow
        } else {
            maskpanel.mode &= ~maskpanel.mode_searchWindow
        }
        updateMaskPanel()
    }

    function connectCameraSetting() {
        if(deviceAdapter.camConnectStatus === LT.Utilities.CamConnectSts_Connecting) {
            // show Panel Mask
            maskpanel.mode |= maskpanel.mode_Connecting
        }
        else if(deviceAdapter.camConnectStatus === LT.Utilities.CamConnectSts_Unknown ||
                deviceAdapter.camConnectStatus === LT.Utilities.CamConnectSts_Success ||
                deviceAdapter.camConnectStatus === LT.Utilities.CamConnectSts_SuccessBackground
                ) {
            // hide Panel Mask
            maskpanel.mode &= ~maskpanel.mode_Connecting
        }
        updateMaskPanel()
    }

    function updateMaskPanel()
    {
        if(maskpanel.mode == maskpanel.mode_init )
        {
            maskpanel.visible = false
        }else{
            optionButtonPopupClose()
            flashSliderPopupClose()
            maskpanel.visible = true
        }
    }

    onActiveChanged: {
        //LTSubFunction.console_debug.out("FlashView::onActiveChanged")
        if(maskpanel.visible) {
            if(root.active) {
                utilities.preferenceWindowActive()
            }
        }
    }

    Component.onCompleted: {
        deviceAdapter.cameraStatusChanged.connect(root.cameraStatusSetting)
        deviceAdapter.cameraStatusCompleteNotify.connect(cameraStatusCompleteNotify)
        deviceAdapter.initSetupTetherModeChanged.connect(root.initSetupTetherMode);
        deviceAdapter.switchCameraNotify.connect(root.initSetupTetherMode)
        deviceAdapter.camConnectStatusChanged.connect(root.connectCameraSetting);
        utilities.preferenceWindowVisibleChangedNotify.connect(root.preferenceWindowVisibleSetting);
        utilities.searchCamWindowVisibleChangedNotify.connect(root.searchCamWindowVisibleSetting);

        flashAdapter.flashDimmerChanged.connect(root.flashDimmerSetting);
        flashAdapter.flashDimmerInnerChanged.connect(root.flashDimmerSetting);
        flashAdapter.flashModeChanged.connect(root.flashModeSetting);
        flashAdapter.flashSyncChanged.connect(root.flashSyncSetting);
        flashAdapter.exposureLinkChanged.connect(root.exposureLinkSetting);
        flashAdapter.wirelessModeChanged.connect(root.wirelessModeSetting);
        flashAdapter.wirelessModeInnerChanged.connect(root.wirelessModeInnerSetting);
        flashAdapter.wirelessChannelChanged.connect(root.wirelessChannelSetting);
        flashAdapter.wirelessFPChanged.connect(root.wirelessFpSetting);
        flashAdapter.wirelessComPowerChanged.connect(root.wirelessComPowerSetting);
        flashAdapter.flashAdjustChanged.connect(root.flashAdjustSetting);
        flashAdapter.flashManualChanged.connect(root.flashManualSetting);
        flashAdapter.buildInFlashDimmerChanged.connect(root.buildInFlashDimmerSetting);
        flashAdapter.aGroupDimmerChanged.connect(root.aGroupDimmerSetting);
        flashAdapter.aGroupDimmerInnerChanged.connect(root.aGroupDimmerSetting);
        flashAdapter.bGroupDimmerChanged.connect(root.bGroupDimmerSetting);
        flashAdapter.bGroupDimmerInnerChanged.connect(root.bGroupDimmerSetting);
        flashAdapter.cGroupDimmerChanged.connect(root.cGroupDimmerSetting);
        flashAdapter.cGroupDimmerInnerChanged.connect(root.cGroupDimmerSetting);
        flashAdapter.buildInFlashAdjustChanged.connect(root.buildInFlashAdjustSetting);
        flashAdapter.aGroupFlashAdjustChanged.connect(root.aGroupFlashAdjustSetting);
        flashAdapter.bGroupFlashAdjustChanged.connect(root.bGroupFlashAdjustSetting);
        flashAdapter.cGroupFlashAdjustChanged.connect(root.cGroupFlashAdjustSetting);
        flashAdapter.buildInFlashManualChanged.connect(root.buildInFlashManualSetting);	// USBTHRV140-97
        flashAdapter.aGroupFlashManualChanged.connect(root.aGroupFlashManualSetting);	// (USBTHRV140-97, 参照元)
        flashAdapter.bGroupFlashManualChanged.connect(root.bGroupFlashManualSetting);
        flashAdapter.cGroupFlashManualChanged.connect(root.cGroupFlashManualSetting);

        flashAdapter.flashDimFlgNumChanged.connect(root.flashDimmerSetting);
        flashAdapter.flashModeFlgNumChanged.connect(root.flashModeSetting);
        flashAdapter.flashSyncFlgNumChanged.connect(root.flashSyncSetting);
        flashAdapter.flashAdjustFlgNumChanged.connect(root.flashAdjustSetting);
        flashAdapter.flashManualFlgNumChanged.connect(root.flashManualSetting);
        flashAdapter.expoLinkFlgNumChanged.connect(root.exposureLinkSetting);
        flashAdapter.wirModeFlgNumChanged.connect(root.wirelessModeSetting);
        flashAdapter.wirChFlgNumChanged.connect(root.wirelessChannelSetting);
        flashAdapter.wirFPFlgNumChanged.connect(root.wirelessFpSetting);
        flashAdapter.wirComPowerFlgNumChanged.connect(root.wirelessComPowerSetting);
        flashAdapter.buildInFlashDimFlgNumChanged.connect(root.buildInFlashDimmerSetting);
        flashAdapter.buildInFlashAdjustFlgNumChanged.connect(root.buildInFlashAdjustSetting);
        flashAdapter.buildInFlashManualFlgNumChanged.connect(root.buildInFlashManualSetting);	// USBTHRV140-97
        flashAdapter.aGroupDimFlgNumChanged.connect(root.aGroupDimmerSetting);
        flashAdapter.aGroupFlashAdjustFlgNumChanged.connect(root.aGroupFlashAdjustSetting);
        flashAdapter.aGroupFlashManualFlgNumChanged.connect(root.aGroupFlashManualSetting);	// (USBTHRV140-97, 参照元)
        flashAdapter.bGroupDimFlgNumChanged.connect(root.bGroupDimmerSetting);
        flashAdapter.bGroupFlashAdjustFlgNumChanged.connect(root.bGroupFlashAdjustSetting);
        flashAdapter.bGroupFlashManualFlgNumChanged.connect(root.bGroupFlashManualSetting);
        flashAdapter.cGroupDimFlgNumChanged.connect(root.cGroupDimmerSetting);
        flashAdapter.cGroupFlashAdjustFlgNumChanged.connect(root.cGroupFlashAdjustSetting);
        flashAdapter.cGroupFlashManualFlgNumChanged.connect(root.cGroupFlashManualSetting);

        utilities.activateWindowNotify.connect(root.activateWindowNotify);

        flashSliderPopup.onOKClicked.connect(root.onFlashPopupOKClicked);
        flashSliderPopup.onCancelClicked.connect(root.onFlashPopupCancelClicked);
    }

    function activateWindowNotify() {
        if(root.visibility == Window.Minimized) {
            root.visibility = Window.Windowed
        }
        root.active = true
    }

    function initSetupTetherMode(){
        // ポップアップクローズ
        optionButtonPopupClose()
        flashSliderPopupClose()
    }

    function optionButtonPopupClose(){
        if(optionButtonPopup.visible === true){
            optionButtonPopup.dismiss()
        }
    }

    function flashSliderPopupClose(){
        if(flashSliderPopup.visible === true){
            flashSliderPopup.dismiss()
        }
    }

    /*
        LTOptionButton の状態を選択するポップアップ
     */
    LTOptionButtonPopup {
        z: 50
        id: optionButtonPopup

        /*!
            Call option popup
         */
        function showOptionPopup(btn, componentsProvider, target, popupTitle) {
            var components = componentsProvider[target];
            var capability = flashAdapter[target+"Capability"];

            for (var i = 0; i < components.length; ++i) {
                if (capability(components[i].properties.value) == LT.FlashAdapter.Ternary_True) {
                    components[i].properties.capable = true;
                    components[i].properties.checked = (components[i].properties.value == btn.value);
                } else {
                    components[i].properties.capable = false;
                    components[i].properties.checked = false;
                }
            }

            var point = rootColumn.mapFromItem(btn, btn.x, btn.y);

            optionButtonPopup.present(
                point.x + btn.x,
                point.y + btn.y,
                popupTitle,
                componentsProvider[target],
                target,
                btn.onSelectedPopupButton);
        }
    }

    /*
        LTOptionComponentsProvider に表示するコンポーネントの組を提供するオブジェクト
     */
    LTOptionComponentsProvider {
        id: optionComponentsProvider
    }

    /*
        LTFlashSliderPopup の状態を選択するポップアップ
     */
    LTFlashSliderPopup {
        z:50
        id: flashSliderPopup

        /*!
            Call slider popup
         */
        function showSlidePopup(btn, componentsProvider, target, btnId) {
            var point = rootColumn.mapFromItem(btn, btn.x, btn.y);
            var preX = point.x;
            var preY = point.y + btn.height

            flashSliderPopup.present(preX, preY, btn, componentsProvider[target], btnId);
        }
    }

    /*
        LTFlashComponentsProvider に表示するコンポーネントの組を提供するオブジェクト
     */
    LTFlashComponentsProvider {
        id: flashComponentsProvider
    }

    Column {
        id: rootColumn

        anchors {
            fill: parent
        }

        //The first panel
        Item {
            anchors {
                left: parent.left
                right: parent.right
            }
            height: grid1.height

            z: 20

            /*
                背景 - Background
             */
            Rectangle {
                anchors {
                    fill: parent
                }
                color: palette.backgroundLight
            }

            LTFlashGridLayout {
                colMulti: flItemWidth
                rowMulti: flItemHeight

                id: grid1
                columns: 3
                rows: 3
                rowSpacing: 1
                columnSpacing: 1

                /*
                    発光モード
                 */
                LTOptionButton {
                    id: btnOptionFlshDimmer

                    Layout.rowSpan: 1
                    Layout.columnSpan: 1

                    width: grid1.prefWidth(this)
                    height: grid1.prefHeight(this)

                    type: "optionWithStyledSelectedText"
                    labelText: qsTr("Flash Dimmer")
                    popupTitle: qsTr("Flash Dimmer")
                    windowType: "flash"
                    target: "flashDimmer"
                    popup: optionButtonPopup
                    componentsProvider: optionComponentsProvider

                    logCol: ltLog
                    logScrTagID: LT.TagDef.RTScr_Usage_Flash_FlashDimmer
                    logFile: btnOptionFlshDimmer.target
                }

                /*
                    フラッシュモード
                 */
                LTOptionButton {
                    id: btnOptionFlshMode

                    Layout.rowSpan: 1
                    Layout.columnSpan: 1
                    width: grid1.prefWidth(this)
                    height: grid1.prefHeight(this)

                    type: "optionWithImage"
                    labelText: qsTr("Flash Mode")
                    popupTitle: qsTr("Flash Mode")
                    target: "flashMode"
                    windowType: "flash"
                    popup: optionButtonPopup
                    componentsProvider: optionComponentsProvider

                    logCol: ltLog
                    logScrTagID: LT.TagDef.RTScr_Usage_Flash_FlashMode
                    logFile: btnOptionFlshMode.target
                }

                /*
                    フラッシュシンクロ
                 */
                LTOptionButton {
                    id: btnOptionFlshSync

                    Layout.rowSpan: 1
                    Layout.columnSpan: 1
                    width: grid1.prefWidth(this)
                    height: grid1.prefHeight(this)

                    type: "optionWithStyledSelectedText"
                    labelText: qsTr("Flash Sync")
                    popupTitle: qsTr("Flash Sync")
                    windowType: "flash"
                    target: "flashSync"
                    popup: optionButtonPopup
                    componentsProvider: optionComponentsProvider

                    logCol: ltLog
                    logScrTagID: LT.TagDef.RTScr_Usage_Flash_FlashSync
                    logFile: btnOptionFlshSync.target
                }

                /*
                    露出補正連動
                 */
                LTOptionButton {
                    id: btnOptionExpLink

                    Layout.rowSpan: 1
                    Layout.columnSpan: 1
                    width: grid1.prefWidth(this)
                    height: grid1.prefHeight(this)

                    type: "optionWithStyledSelectedText"
                    labelText: qsTr("Exposure Link")
                    popupTitle: qsTr("Exposure Link")
                    windowType: "flash"
                    target: "exposureLink"
                    popup: optionButtonPopup
                    componentsProvider: optionComponentsProvider

                    logCol: ltLog
                    logScrTagID: LT.TagDef.RTScr_Usage_Flash_ExposureLink
                    logFile: btnOptionExpLink.target

                }

                /*
                    フラッシュ光量調整
                 */
                Rectangle {
                    id: flashAdjust

                    Layout.rowSpan: 1
                    Layout.columnSpan: 2
                    width: grid1.prefWidth(this)
                    height: grid1.prefHeight(this)
                    color: palette.backgroundDark

                    LTFlashSlider {
                        id: sliderFlashAdjust
                        anchors {
                            fill: parent
                        }

                        optionText: qsTr("Flash Intensity Setting")
                        type: slider_type_adjust
                        windowType: slider_window_flash
                        target: "flashAdjust"

                        onValueChanged: {
                            ltLog.log(LT.TagDef.RecLvl_Info,
                                      LT.TagDef.RTScr_Usage_Flash_FlashAdjust,
                                      "flashAdjust",
                                      sliderFlashAdjust.value);
                        }
                    }
                }

                /*
                    マニュアル発光量設定
                 */
                Rectangle {
                    id: flashManual

                    Layout.rowSpan: 1
                    Layout.columnSpan: 3
                    width: grid1.prefWidth(this)
                    height: grid1.prefHeight(this)
                    color: palette.backgroundDark

                    LTFlashSlider {
                        id: sliderFlashManual

                        anchors {
                            fill: parent
                        }

                        optionText: qsTr("Manual Flash Emission Setting")
                        type: slider_type_manual
                        windowType: slider_window_flash
                        target: "flashManual"

                        onValueChanged: {
                            ltLog.log(LT.TagDef.RecLvl_Info,
                                      LT.TagDef.RTScr_Usage_Flash_ManualFlash,
                                      "flashManual",
                                      sliderFlashManual.value);
                        }
                    }
                }
            }
        }

        Item {
            id: btnCompact

            anchors {
                left: parent.left
                right: parent.right
            }
            height: flLineBtnHeight

            z: 20

            /*
                背景
             */
            Rectangle {
                anchors {
                    fill: parent
                }
                color: palette.backgroundLight
            }

            LTRectangleButton {
                id: wirelessModeButton
                anchors {
                    left: parent.left
                    right: parent.right
                }
                height: flLineBtnHeight

                fillColor: palette.backgroundLight

                type: "checkableWithImageAndText"

                buttonText: qsTr("Wireless Mode") + (compact ? " " + qsTr("OFF") : " " + qsTr("ON"))
                checkedImage: compact ? "qrc:/images/button_expand.svg" : "qrc:/images/button_shrink.svg"
                checked: compact ? false: true

                logCol: ltLog
                logScrTagID: LT.TagDef.RTScr_Usage_Flash_WirelessMode
                logFile: "wirelessMode"

                onClicked: {
                    wirelessModeButton.enabled = false
                    flashAdapter.wirelessMode = compact ? LT.Utilities.WirM_On : LT.Utilities.WirM_Off;
                }
            }
        }

        Item {
            id: wirelessModePanel

            z: 10

            //visible: !compact
            anchors {
                left: parent.left
                right: parent.right
            }
            height: grid2.height

            /*
                背景
             */
            Rectangle {
                anchors {
                    fill: parent
                }
                color: palette.backgroundLight
            }

            LTFlashGridLayout {
                id: grid2

                colMulti: flItemWidth
                rowMulti: flItemHeight

                columns: 3
                rows: 5
                rowSpacing: 1
                columnSpacing: 1

                /*
                    ワイヤレスチャンネル
                 */
                LTOptionButton {
                    id: btnOptionWirChannel

                    Layout.rowSpan   : 1
                    Layout.columnSpan: 1
                    width: grid2.prefWidth(this)
                    height: grid2.prefHeight(this)

                    type: "optionWithStyledSelectedText"
                    labelText: qsTr("Wireless Channel")
                    popupTitle: qsTr("Wireless Channel")
                    windowType: "flash"

                    target: "wirelessChannel"
                    popup: optionButtonPopup
                    componentsProvider: optionComponentsProvider

                    logCol: ltLog
                    logScrTagID: LT.TagDef.RTScr_Usage_Flash_WirelessChannel
                    logFile: btnOptionWirChannel.target
                }

                /*
                    ワイヤレスFP
                 */
                LTOptionButton {
                    id: btnOptionWirFp

                    Layout.rowSpan   : 1
                    Layout.columnSpan: 1
                    width: grid2.prefWidth(this)
                    height: grid2.prefHeight(this)

                    type: "optionWithStyledSelectedText"
                    labelText: qsTr("Wireless FP")
                    popupTitle: qsTr("Wireless FP")
                    windowType: "flash"

                    target: "wirelessFP"
                    popup: optionButtonPopup
                    componentsProvider: optionComponentsProvider

                    logCol: ltLog
                    logScrTagID: LT.TagDef.RTScr_Usage_Flash_WirelessFP
                    logFile: btnOptionWirFp.target
                }

                /*
                    ワイヤレス通信光量
                 */
                LTOptionButton {
                    id: btnOptionWirComPower

                    Layout.rowSpan   : 1
                    Layout.columnSpan: 1
                    width: grid2.prefWidth(this)
                    height: grid2.prefHeight(this)

                    type: "optionWithStyledSelectedText"
                    labelText: qsTr("Wireless Light Intensity")
                    popupTitle: qsTr("Wireless Light Intensity")
                    windowType: "flash"

                    target: "wirelessComPower"
                    popup: optionButtonPopup
                    componentsProvider: optionComponentsProvider

                    logCol: ltLog
                    logScrTagID: LT.TagDef.RTScr_Usage_Flash_WirelessComPower
                    logFile: btnOptionWirComPower.target
                }

                /*
                    内蔵フラッシュ
                 */
                LTFlashThreeButton {
                    id: panelBuildInFlash

                    Layout.rowSpan   : 1
                    Layout.columnSpan: 3
                    width: grid2.prefWidth(this)
                    height: grid2.prefHeight(this)
                    fillColor: palette.backgroundDark

                    label3BText: qsTr("Built-in Flash")

                    btn1 {
                        type: "optionWithStyledSelectedText"
                        popupTitle: qsTr("Built-in Flash")
                        target: "buildInFlashDimmer"
                        popup: optionButtonPopup
                        componentsProvider: optionComponentsProvider

                        logCol: ltLog
                        logScrTagID: LT.TagDef.RTScr_Usage_Flash_BuildinFlash
                        logFile: panelBuildInFlash.btn1.target

                        onClicked: {
                            optionButtonPopup.showOptionPopup(panelBuildInFlash.btn1, panelBuildInFlash.btn1.componentsProvider, panelBuildInFlash.btn1.target, panelBuildInFlash.btn1.popupTitle);
                        }
                    }

                    btn2 {
                        type: "optionWithStyledSelectedText"

                        logCol: ltLog
                        logScrTagID: LT.TagDef.RTScr_Usage_Flash_BuildinFlashAdjust
                        logFile: "buildInFlashAdjust"

                        onClicked: {
                            panelBuildInFlash.btn2.button_id = panelBuildInFlashBtn2
                            flashSliderPopup.showSlidePopup(panelBuildInFlash.btn2, flashComponentsProvider, "buildInFlashAdjust", panelBuildInFlashBtn2);
                        }
                    }

                    btn3 {	// (USBTHRV140-97, 参照元) >>
                        type: "optionWithStyledSelectedText"

                        logCol: ltLog
                        logScrTagID: LT.TagDef.RTScr_Usage_Flash_BuildinFlashManual
                        logFile: "buildInFlashManual"

                        onClicked: {
                            panelBuildInFlash.btn3.button_id = panelBuildInFlashBtn3
                            flashSliderPopup.showSlidePopup(panelBuildInFlash.btn3, flashComponentsProvider, "buildInFlashManual", panelBuildInFlashBtn3);
                        }
                    }		// << (USBTHRV140-97, 参照元)
                }

                /*
                    Aグループ
                 */
                LTFlashThreeButton {
                    id: panelAGroup

                    Layout.rowSpan   : 1
                    Layout.columnSpan: 3
                    width: grid2.prefWidth(this)
                    height: grid2.prefHeight(this)
                    fillColor: palette.backgroundDark

                    label3BText: qsTr("A Group")

                    btn1 {
                        type: "optionWithStyledSelectedText"
                        popupTitle: qsTr("A Group")
                        target: "aGroupDimmer"
                        popup: optionButtonPopup
                        componentsProvider: optionComponentsProvider

                        logCol: ltLog
                        logScrTagID: LT.TagDef.RTScr_Usage_Flash_GroupAFlash
                        logFile: panelAGroup.btn1.target

                        onClicked: {
                            optionButtonPopup.showOptionPopup(panelAGroup.btn1, panelAGroup.btn1.componentsProvider, panelAGroup.btn1.target, panelAGroup.btn1.popupTitle);
                        }
                    }

                    btn2 {
                        type: "optionWithStyledSelectedText"

                        logCol: ltLog
                        logScrTagID: LT.TagDef.RTScr_Usage_Flash_GroupAFlashAdjust
                        logFile: "aGroupFlashAdjust"

                        onClicked: {
                            panelAGroup.btn2.button_id = panelAGroupBtn2
                            flashSliderPopup.showSlidePopup(panelAGroup.btn2, flashComponentsProvider, "aGroupFlashAdjust", panelAGroupBtn2);
                        }
                    }

                    btn3 {	// (USBTHRV140-97, 参照元) >>
                        type: "optionWithStyledSelectedText"

                        logCol: ltLog
                        logScrTagID: LT.TagDef.RTScr_Usage_Flash_GroupAFlashManual
                        logFile: "aGroupFlashManual"

                        onClicked: {
                            panelAGroup.btn3.button_id = panelAGroupBtn3
                            flashSliderPopup.showSlidePopup(panelAGroup.btn3, flashComponentsProvider, "aGroupFlashManual", panelAGroupBtn3);
                        }
                    }		// << (USBTHRV140-97, 参照元)
                }

                /*
                    Bグループ
                 */
                LTFlashThreeButton {
                    id: panelBGroup

                    Layout.rowSpan   : 1
                    Layout.columnSpan: 3
                    width: grid2.prefWidth(this)
                    height: grid2.prefHeight(this)
                    fillColor: palette.backgroundDark

                    label3BText: qsTr("B Group")

                    btn1 {
                        type: "optionWithStyledSelectedText"
                        popupTitle: qsTr("B Group")
                        target: "bGroupDimmer"
                        popup: optionButtonPopup
                        componentsProvider: optionComponentsProvider

                        logCol: ltLog
                        logScrTagID: LT.TagDef.RTScr_Usage_Flash_GroupBFlash
                        logFile: panelBGroup.btn1.target

                        onClicked: {
                            optionButtonPopup.showOptionPopup(panelBGroup.btn1, panelBGroup.btn1.componentsProvider, panelBGroup.btn1.target, panelBGroup.btn1.popupTitle);
                        }
                    }

                    btn2 {
                        type: "optionWithStyledSelectedText"

                        logCol: ltLog
                        logScrTagID: LT.TagDef.RTScr_Usage_Flash_GroupBFlashAdjust
                        logFile: "bGroupFlashAdjust"

                        onClicked: {
                            panelBGroup.btn2.button_id = panelBGroupBtn2
                            flashSliderPopup.showSlidePopup(panelBGroup.btn2, flashComponentsProvider, "bGroupFlashAdjust", panelBGroupBtn2);
                        }
                    }

                    btn3 {
                        type: "optionWithStyledSelectedText"

                        logCol: ltLog
                        logScrTagID: LT.TagDef.RTScr_Usage_Flash_GroupBFlashManual
                        logFile: "bGroupFlashManual"

                        onClicked: {
                            panelBGroup.btn3.button_id = panelBGroupBtn3
                            flashSliderPopup.showSlidePopup(panelBGroup.btn3, flashComponentsProvider, "bGroupFlashManual", panelBGroupBtn3);
                        }
                    }
                }

                /*
                    Cグループ
                 */
                LTFlashThreeButton {
                    id: panelCGroup

                    Layout.rowSpan   : 1
                    Layout.columnSpan: 3
                    width: grid2.prefWidth(this)
                    height: grid2.prefHeight(this)
                    fillColor: palette.backgroundDark

                    label3BText: qsTr("C Group")

                    btn1 {
                        type: "optionWithStyledSelectedText"
                        popupTitle: qsTr("C Group")
                        target: "cGroupDimmer"
                        popup: optionButtonPopup
                        componentsProvider: optionComponentsProvider

                        logCol: ltLog
                        logScrTagID: LT.TagDef.RTScr_Usage_Flash_GroupCFlash
                        logFile: panelCGroup.btn1.target

                        onClicked: {
                            optionButtonPopup.showOptionPopup(panelCGroup.btn1, panelCGroup.btn1.componentsProvider, panelCGroup.btn1.target, panelCGroup.btn1.popupTitle);
                        }
                    }

                    btn2 {
                        type: "optionWithStyledSelectedText"

                        logCol: ltLog
                        logScrTagID: LT.TagDef.RTScr_Usage_Flash_GroupCFlashAdjust
                        logFile: "cGroupFlashAdjust"

                        onClicked: {
                            panelCGroup.btn2.button_id = panelCGroupBtn2
                            flashSliderPopup.showSlidePopup(panelCGroup.btn2, flashComponentsProvider, "cGroupFlashAdjust", panelCGroupBtn2);
                        }
                    }

                    btn3 {
                        type: "optionWithStyledSelectedText"

                        logCol: ltLog
                        logScrTagID: LT.TagDef.RTScr_Usage_Flash_GroupCFlashManual
                        logFile: "cGroupFlashManual"

                        onClicked: {
                            panelCGroup.btn3.button_id = panelCGroupBtn3
                            flashSliderPopup.showSlidePopup(panelCGroup.btn3, flashComponentsProvider, "cGroupFlashManual", panelCGroupBtn3);
                        }
                    }
                }
            }
        }

        /*
            テスト発光
         */
        Item {
            id: btnDone

            z: 10

            //visible: !compact
            anchors {
                left: parent.left
                right: parent.right
            }
            height: flLineBtnHeight

            //Background
            Rectangle {
                anchors {
                    fill: parent
                }
                color: palette.backgroundDark
            }

            LTRectangleButton {
                x: 1
                y: 5
                width: parent.width - x*2
                height: flLineBtnHeight - y*2

                type: "action"
                buttonText: qsTr("Test Emission")
                fillColor: palette.backgroundLight
                onClicked: {
                    //console.log("Test Emission clicked")

                    deviceAdapter.adp_LMX_func_api_Rec_Ctrl_Other_FLASH_TEST()

                    ltLog.log(LT.TagDef.RecLvl_Info,
                              LT.TagDef.RTScr_Usage_Flash_TestEmission,
                              "TestEmission clicked",
                              "");
                }
            }

            /*
                Compact state and transition
             */
            //states: State {
            //    name: "compacted"
            //    when: compact == true
            //}

            //transitions: Transition {
            //    NumberAnimation {
            //        properties: "y,visible"
            //        easing.type: Easing.InOutQuad
            //        duration: 100
            //    }
            //}
        }
    }

    /*
      カメラ操作中に全てのコントロールを押せなくする。
     */
    Rectangle {
        id: maskpanel

        property int mode: mode_init //状態をビットフラグでもつ
        readonly property int mode_init: 0
        readonly property int mode_camera: 1 //再生モード
        readonly property int mode_pref: 2 //アプリの設定画面開いている
        readonly property int mode_streaming: 4 //ストリーミング中
        readonly property int mode_live_view_menu : 8 //ライブビューMENU中
        readonly property int mode_searchWindow: 16 //起動カメラウインド
        readonly property int mode_Connecting: 32 //カメラ接続中

        visible: false
        anchors {
            fill: parent
        }
        color: "#000000"
        opacity: 0.5
        MouseArea {
            anchors {
                fill: parent
            }
            hoverEnabled: true
            onClicked: {
                //root.dismiss();
            }
        }
    }
}
