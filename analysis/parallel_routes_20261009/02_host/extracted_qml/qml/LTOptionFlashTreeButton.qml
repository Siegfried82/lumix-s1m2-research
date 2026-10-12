import QtQuick 2.7

import "qrc:/qml"
import LT 1.0 as LT
import "LTSubFunction.js" as LTSubFunction

/*! \qmltype LTOptionFlashTreeButton
    \inqmlmodule LT

    \brief
    状態を保持するボタンです(LTFlashThreeButton用)

    LTOptionButtonPopup によって状態を選択する機能を提供します．
 */
LTRectangleButton {
    id: root

    readonly property int btn_type_other                    : -1    // それ以外はF/Wの不具合
    readonly property int btn_type_disp_val_enable          : 0     // (a) 現在値表示有り & 有効(クリックすると選択肢を表示)
    readonly property int btn_type_disp_val_disable         : 1     // (b) 現在値表示有り & 無効(クリック不可)
    readonly property int btn_type_nondisp_val_disable      : 2     // (c) 現在値表示無し & 無効(クリック不可)

    property bool isForcedDisable: false

    property real popupX: 0

    property real popupY: 0

    property bool isDetail: false

    property bool valueChangeFlg: false

    /*!
        DeviceAdapter オブジェクト，ならびに LTOptionButton::componentsProvider のプロパティ名です
     */
    property string target
    onValueChanged: {
        flashAdapter[target] = value;
        return;
    }

    onTargetChanged: {
        mainImg.sourceSize.width = 75;
        mainImg.sourceSize.height = 75;
    }

    mainImg {
        anchors {
            centerIn: undefined
            horizontalCenter: horizontalCenter
        }
    }

    /*!
        Setting to show popup title (hidden if not setting)
     */
    property string popupTitle

    /*!
        状態を選択するポップアップ LTOptionButtonPopup です
     */
    property var popup

    /*!
        ポップアップに表示するコンポーネントの組を提供するオブジェクトです
     */
    property var componentsProvider

    /*!
        プルダウン用のImage
     */
    property bool optionOpen: true

    /*!
        Flag for keep popup open while value changed
     */
    property bool keepPopupOpen: false


    // LTOptionButtonPopup.present()のonSelected用
    function onSelectedPopupButton(object) {
        //log record
        if (logCol){
            logCol.log(logLevel, logScrTagID, logFile + " selected", object.value);
        }
        var disp_text = LTSubFunction.createPopupHTMLText(popupTitle, object.optionText);
        
        LTSubFunction.console_debug.out(disp_text)
        
        //  状態と表示内容を設定する
        switch (object.type) {
        case "optionWithImage":
        case "optionWithImagePopup":
            root.source = object.source;
            root.optionTextTooltip = disp_text;
            break;
        case "optionWithImageAndText":
        case "optionWithImageAndTextPopup":
            root.optionImage = object.optionImage;
            root.optionText = object.optionText;
            break;
        case "optionWithRichTextPs":
            // nakhuong >> start >>
        case "optionWithTextRealPs":
            // nakhuong << end <<
        case "optionWithRichText":
        case "optionWithTextReal":
        case "optionWithRichSelectedText":
        case "optionWithStyledTextPs":
        case "optionWithStyledTextRealPs":
        case "optionWithStyledText":
        case "optionWithStyledTextReal":
        case "optionWithStyledSelectedText":
            root.optionText = object.optionText;
            root.optionTextTooltip = disp_text;
            break;
        case "optionWithText":
            root.optionText = object.optionText;
            break;
        case "optionWithImagetoText":
        case "optionWithImagetoTextCc":
            root.optionTextTooltip = disp_text;
            root.source = object.source;
            break;
        case "optionWithImagetoText_dm":
            driveModeIcon= object.source;
            break;
        }
        root.valueChangeFlg = true;
        root.value = object.value;
        popup.dismiss();
    }


    function optionSelect(select, isClicked){
        if (isClicked === undefined) {
            isClicked = false
        }
        optionSelectSub(select, isClicked)
    }

    function optionSelectSub(select, isClicked){
        //log record
        if (logCol && (root.valueChangeFlg || root.value !== select)) {
            logCol.log(logLevel, logScrTagID, logFile + " optionSelectSub", select);
        }
        if((popup != null) &&
           ((target == popup.popup_target) ||
           (deviceAdapter.cameraStatus == LT.Utilities.CamStatus_MovRec_Others) ||
           (deviceAdapter.cameraStatus == LT.Utilities.CamStatus_Playing) ||
           (deviceAdapter.cameraStatus == LT.Utilities.CamStatus_Processing) ||
// IVC >> Ver.1.9 >> start >> [THRBOXV100-170]
           (deviceAdapter.cameraStatus == LT.Utilities.CamStatus_Menu_Displayed))) {
// IVC << Ver.1.9 << end << [THRBOXV100-170]
            if (!keepPopupOpen || isClicked) {
                popup.dismiss();
            }
        }

        //  状態と表示内容を設定する
        root.valueChangeFlg = false
        root.value = select;

        //  コンポーネントのプロパティを設定する
        //    * 使用可否と，状態に合わせた LTAbstractButton::checked を設定する
        var components = componentsProvider[target];
        var capability = flashAdapter[target + "Capability"];
        var capabilityNumFunc = flashAdapter[target + "CapabilityNum"];
        var capabilityNum = capabilityNumFunc()
        for (var i = 0; i < components.length; ++i) {
            components[i].properties.capable = false;
            components[i].properties.checked = false;
        }

        //[ボタン状態]
        var button_type = btn_type_other

        root.source = ""
        root.optionTextTooltip = ""
        root.optionText = ""
        for (var i = 0; i < components.length; ++i) {
            if(components[i].properties.value == value) {
                var judge = (capability(components[i].properties.value) == LT.DeviceAdapter.Ternary_True)
                //・(Capabilityの数 >= 2 && 現在値が有効) ⇒ (a) -> type=0
                if ( (capabilityNum >= 2) && (judge) ) {
                    //console.log("optionSelect button type 0 capabilityNum = " + capabilityNum);
                    button_type = btn_type_disp_val_enable
                //・(Capabilityの数 <  2 && 現在値が有効) ⇒ (b) -> type=1
                } else if ( (capabilityNum < 2) && (judge) ) {
                    //console.log("optionSelect button type 1 capabilityNum = " + capabilityNum + " isDetail" + isDetail);
                    if(isDetail) {
                        button_type = btn_type_disp_val_enable
                    } else {
                        button_type = btn_type_disp_val_disable
                    }
                //・(Capabilityの数 <  2 && 現在値が無効) ⇒ (c) -> type=2
                } else if ( (capabilityNum < 2) && !(judge) ) {
                    //console.log("optionSelect button type 2 capabilityNum = " + capabilityNum);
                    button_type = btn_type_nondisp_val_disable
                // それ以外はF/Wの不具合
                } else {
                    //console.log("optionSelect button type error capabilityNum" + capabilityNum);
                    break;
                }
                components[i].properties.capable = true;
                components[i].properties.checked = components[i].properties.value == value;
                var disp_text = LTSubFunction.createPopupHTMLText(popupTitle, components[i].properties.optionText);

                if(components[i].properties.checked) {
                    //console.log("optionSelect components[i].properties.type", components[i].properties.type);
                    switch (components[i].properties.type) {
                    case "optionWithImage":
                    case "optionWithImagePopup":
                        root.source = components[i].properties.source;
                        root.optionTextTooltip = disp_text//components[i].properties.optionText;
                        break;
                    case "optionWithImageAndText":
                    case "optionWithImageAndTextPopup":
                        root.optionImage = components[i].properties.optionImage;
                        root.optionText = components[i].properties.optionText;
                        break;
                    case "optionWithRichTextPs":
                    // nakhuong >> start >> No.2
                    case "optionWithTextRealPs":
                    // nakhuong << end << No.2
                    case "optionWithRichText":
                    case "optionWithTextReal":
                    case "optionWithRichSelectedText":
                    case "optionWithStyledTextPs":
                    case "optionWithStyledTextRealPs":
                    case "optionWithStyledText":
                    case "optionWithStyledTextReal":
                    case "optionWithStyledSelectedText":
                        root.optionText = components[i].properties.optionText;
                        root.optionTextTooltip = disp_text//components[i].properties.optionText;
                        //console.log("optionSelect optionWithRichText", components[i].properties.optionText);
                        break;
                    case "optionWithText":
                        root.optionText = components[i].properties.optionText;
                        //console.log("optionSelect optionWithText", components[i].properties.optionText);
                        break;
                    case "optionWithImagetoText":
        //                recordingModeIcon= components[i].properties.source;
                        root.source = components[i].properties.source;
                        root.optionTextTooltip = disp_text//components[i].properties.optionText;
        //                root.source = object.source;
                        //console.log("optionSelect optionWithImagetoText", components[i].properties.optionText);
                        break;
                    case "optionWithImagetoTextCc":
                        recordingModeIcon= components[i].properties.source;
                        root.optionTextTooltip = disp_text//components[i].properties.optionText;
        //                root.source = object.source;
                        //console.log("optionSelect optionWithImagetoTextCc", components[i].properties.optionText);
                        break;
                    case "optionWithImagetoText_dm":
                        driveModeIcon= components[i].properties.source;
        //                root.source = object.source;
                        //console.log("optionSelect optionWithImagetoText_dm", components[i].properties.optionText);
                        break;
                    default:
                        //console.log("optionSelect default", components[i].properties.optionText);
                        break;
                    }
                }
                break;
            }
        }
        //[ボタン状態]
        switch(button_type) {
        // (a) 現在値表示有り & 有効(クリックすると選択肢を表示)
        case btn_type_disp_val_enable:
            root.enabled = true
            root.disabled = false
            break;
        // (b) 現在値表示有り & 無効(クリック不可)
        case btn_type_disp_val_disable:
            root.enabled = false
            root.disabled = true
            break;
        // (c) 現在値表示無し & 無効(クリック不可)
        case btn_type_nondisp_val_disable:
            root.enabled = false
            root.optionText = "-"
            root.disabled = true
            break;
        // それ以外はF/Wの不具合
        default:
            root.enabled = false
            root.optionText = "-"
            root.optionTextTooltip = "<html>" + popupTitle + "</HTML>"  // とりあえず設定
            root.disabled = true
            break;
        }

        if (isForcedDisable) {
            root.enabled = false
        }
    }

    function forceClosePopup() {
        if (popup.visible && target == popup.popup_target) {
            popup.dismiss();
        }
    }

    value: {
        return flashAdapter[target];
    }
    type: "optionWithImage"
//    fillColor: palette.backgroundDark

}
