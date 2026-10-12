import QtQuick 2.7

import "qrc:/qml"
import LT 1.0 as LT
import "LTSubFunction.js" as LTSubFunction

/*! \qmltype LTOptionButton
    \inqmlmodule LT

    \brief
    状態を保持するボタンです

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

    property int virtualX: 0

    property int virtualY: 0

    property bool isDetail: false

    /*!
        Setting for window type
     */
    property string windowType: "main"

    property bool valueChangeFlg: false

    /*!
        DeviceAdapter オブジェクト，ならびに LTOptionButton::componentsProvider のプロパティ名です
     */
    property string target
    onValueChanged: {
        // IVC >> Ver.1.7 >> start >> No.1
        if (target === "aspectRatio" && value === LT.DeviceAdapter.AR_Error) {
            mainImg.anchors.rightMargin = 8;
        }
        // IVC << Ver.1.7 << end << No.1

        if (windowType == "flash") {
            flashAdapter[target] = value;
            return;
        } else {
            if(root.valueChangeFlg == true) {
                //  状態を設定する
                deviceAdapter[target] = value;
            }
            return;
        }
    }

    // IVC >> Ver.1.7 >> start >> No.1
    onTargetChanged: {
        switch(target) {
        case "aspectRatio":
        case "recPreviewMode":
            mainImg.height = 25
            mainImg.sourceSize.height = 25;
            mainImg.sourceSize.width = 25;
            mainImg.anchors.horizontalCenter = undefined;
            mainImg.anchors.right = root.right;
            mainImg.anchors.verticalCenter = verticalCenter;
            mainImg.fillMode = Image.PreserveAspectFit;
            break;
        // IVC >> Ver.1.9 >> start >> No.5
        case "creativeVideoAE":
        // 2024/7
            //mainImg.anchors.verticalCenter = verticalCenter;      // 強制的に中央に表示　[Excel31] 関連、Box時のポップアップに影響
            //mainImg.y = 0;                                        // 元々意味の無い設定
            break;
        // IVC << Ver.1.9 << end << No.5
         default:
             mainImg.sourceSize.width = 75;
//             mainImg.sourceSize.height = 75;
             break;
        }
    }
    // IVC << Ver.1.7 << end << No.1

    mainImg {       // H.NAKANO from here
// IVC >> Ver.1.9 >> start >> No.5
        //sourceSize: {
        //    width : 75
        //    height : 75
        //}
// IVC << Ver.1.9 << end << No.5
        anchors {
            centerIn: undefined
            horizontalCenter: horizontalCenter
        }
        // nakhuong >> start >> No.2
        //y: height * 2.0 / 5.0 + 7   // H.NAKANO 2017.07.21
        y: (target=="pscWB")? (height * 1.0 / 7.0): (height * 2.0 / 5.0 + 7)
        // nakhuong << end << No.2
    }               // H.NAKANO to here

    /*!
        オプションテキストのY座標。mainImgに合わせる
     */
    option_string_top_margin: (height * 2.0 / 5.0 + 7)

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

    onClicked: {
        if (type == "optionWithImagePopup") {
            //do nothing (parent handle)
//            clickCustomSub()
        // nakhuong >> start >> No.2
        //} else if (type == "optionWithTextReal") {
        } else if ((type == "optionWithTextReal") || (type == "optionWithTextRealPs") ||
                   (type == "optionWithStyledTextReal") || (type == "optionWithStyledTextRealPs") ||
                   (type == "optionWithStyledTextPictureSize")){
        // nakhuong << end << No.2
            clickTextRealSub()
        } else {
            clickSub()
        }
    }

    function clickTextRealSub() {
        var components = new Array

        var comp = 0
// IVC >> Ver.1.9 >> start >> [THRBOXV100-82]
        if (target == "isoGain" || target == "pscGain") {
            comp = -1
            var capabilityNumFunc = deviceAdapter[target + "CapabilityNum"];
            var capabilityNum = capabilityNumFunc();
            for (var i=0; i<capabilityNum; i++) {
                var capabilityValue = deviceAdapter[target + "CapabilityValue"];
                var cap_value = capabilityValue(i)
                if(cap_value == comp) {
                    break
                }
                comp = cap_value
                LTSubFunction.console_debug.out("clickTextRealSub cap_value="+cap_value)
                components.push(cap_value)
            }
        }
        else if(target == "aperture"){
            var capabilityNum = deviceAdapter.apertureCapabilityNum()
            comp = -1
            for (var i=0; i<capabilityNum; i++) {
                var capabilityValue = deviceAdapter[target + "CapabilityValue"];
                var cap_value = capabilityValue(i)
                if(cap_value == comp) {
                    break
                } else if (cap_value === 0 ) {
                    continue
                } else if (cap_value === -1 ) {
                    break
                }
                comp = cap_value
                LTSubFunction.console_debug.out("clickTextRealSub cap_value="+cap_value)
                components.push(cap_value)
            }
        }
        else {
            for (var i=0; i<512; i++) {
                var capabilityValue = deviceAdapter[target + "CapabilityValue"];
                if (windowType == "flash") {
                    capabilityValue = flashAdapter[target + "CapabilityValue"];
                }
                var cap_value = capabilityValue(i)
                if(cap_value == comp) {
                    break
                } else if (cap_value == 0) {
                    break
                }
                comp = cap_value
                LTSubFunction.console_debug.out("clickTextRealSub cap_value="+cap_value)
                components.push(cap_value)
            }
        }
// IVC << Ver.1.9 << end << [THRBOXV100-82]

        //  ポップアップの表示位置を決定する
        // nakhuong >> start >> No.2
//        var preferX = parent.parent.x + x;
//        var preferY = parent.parent.y + y;
        var preferX;
        var preferY
        if(type == "optionWithTextRealPs" || type == "optionWithStyledTextRealPs") {
            preferX = parent.x + popupX;
            preferY = parent.y + popupY;
        } else {
            preferX = parent.parent.x + x;
            preferY = parent.parent.y + y;
        }
        // nakhuong << end << No.2

        //  ポップアップを表示する
        popup.presentReal(preferX, preferY, popupTitle, components, target, value, function (object) {
            //log record
            if (logCol){
                logCol.log(logLevel, logScrTagID, logFile + " selected", object.value);
            }
            var disp_text = LTSubFunction.createPopupHTMLText(popupTitle, object.optionText);
            LTSubFunction.console_debug.out(disp_text)

            //  状態と表示内容を設定する
            root.valueChangeFlg = true
            root.value = object.value;
            if(root.value == object.value) {
                root.optionText = object.optionText;
                root.optionTextTooltip = disp_text;
            }
            //  ポップアップを非表示にする
            popup.dismiss();
        });
    }

    function clickSub() {
        //  コンポーネントのプロパティを設定する
        //    * 使用可否と，状態に合わせた LTAbstractButton::checked を設定する
        var components = componentsProvider[target];
        if(deviceAdapter.imgInfoHeifModeAvailable() === true) {                                 // Heif 対応機かどうか判定
            if(target === "imgInfoQuality") {
                if(deviceAdapter.imgInfoJpegHeifMode === LT.Utilities.ImgInfoJHM_JPEG){
                    components = componentsProvider["imgInfoQualityJpeg"];                      // Jpeg
                } else {
                    components = componentsProvider["imgInfoQualityHeif"];                      // Heif
                }
            }
        }
        if(!root.optionOpen) {
            return;
        }

        var capability = deviceAdapter[target + "Capability"];
        if (windowType == "flash") {
            capability = flashAdapter[target + "Capability"];
        }

        for (var i = 0; i < components.length; ++i) {
            if (capability(components[i].properties.value) == LT.DeviceAdapter.Ternary_True) {
                components[i].properties.capable = true;
                components[i].properties.enabled = true;
                components[i].properties.checked = components[i].properties.value == value;
            } else {
                components[i].properties.capable = false;
                components[i].properties.enabled = false;
                components[i].properties.checked = false;
            }
        }
        //  ポップアップの表示位置を決定する
        var preferX;
        var preferY;
        switch (type) {
        case "optionWithImage":
        case "optionWithImagePopup":
            // nakhuong >> start >> No.2
//            preferX = parent.parent.x + x;
//            preferY = parent.parent.y + y;
            // IVC >> Ver.1.7 >> start >> No.1
            switch(target) {
            case "pscWB":
            case "recPreviewMode":
                preferX = parent.width - 96;
                preferY = parent.y + popupY;
                break;
            case "aspectRatio":
                preferX = components.length > 5 ? parent.width - 104 : parent.width - 96;
                preferY = parent.y + popupY;
                break;
            // IVC >> Ver.1.9 >> start >> No.5
            case "creativeVideoAE":
                if(deviceAdapter.recordingModeCapabilityNum() > 0){
                    // IVC >> Ver.1.9 >> start >> [THRBOXV100-32]
                    var capabilityNumFuncT = deviceAdapter["creativeVideoAECapabilityNum"];
                    var capabilityNumT = capabilityNumFuncT();
                    if (capabilityNumT >=2){
                        preferX = parent.parent.parent.parent.x;
                        preferY = parent.parent.parent.parent.y;
                    }
                    else {
                        return
                    }
                    // IVC << Ver.1.9 << end << [THRBOXV100-32]
                }else{
                    preferX = parent.parent.x + x;
                    preferY = parent.parent.y + y;
                }
                break;
            // IVC << Ver.1.9 << end << No.5
            default:
                preferX = parent.parent.x + x;
                preferY = parent.parent.y + y;
                break;
            }
            // IVC << Ver.1.7 << end << No.1
            // nakhuong << end << No.2
            break;
        case "optionWithImageAndText":
            preferX = popupX;
            preferY = popupY;
            break;
        case "optionWithRichTextPs":
        // nakhuong >> start >> No.2
        case "optionWithTextRealPs":
        // nakhuong << end << No.2
        case "optionWithStyledTextPs":
        case "optionWithStyledTextRealPs":
            preferX = parent.x + popupX;
            preferY = parent.y + popupY;
            break;
        case "optionWithRichText":
        case "optionWithTextReal":
        case "optionWithRichSelectedText":
        case "optionWithStyledText":
        case "optionWithStyledTextReal":
        case "optionWithStyledTextPictureSize":
        case "optionWithStyledSelectedText":
            preferX = parent.parent.x + x;
            preferY = parent.parent.y + y;
            break;
        case "optionWithText":
            preferX = parent.parent.width;
            preferY = parent.parent.y + y;
            break;
        case "optionWithImagetoText":
        case "optionWithImagetoText_dm":
            preferX = parent.parent.width;
            preferY = parent.parent.y + y;
            break;
        case "optionWithImagetoTextCc":
            preferX = parent.parent.parent.x + x;
            preferY = parent.parent.parent.y + y;
            break;
        }

        if (popup === null) {
            return
        }

        //  ポップアップを表示する
//        popup.present(preferX, preferY, popupTitle, componentsProvider[target], target, function (object) {
        popup.present(preferX, preferY, popupTitle, components, target, function (object) {
            //log record
            if (logCol){
                logCol.log(logLevel, logScrTagID, logFile + " selected", object.value);
            }
            switch (target) {
            case "intelligentAutoMode":
            case "creativeVideoAE":
            case "sqMotion":
            case "custom3Set":
            case "custom4Set":
            case "custom5Set":
            case "photoExposure":
                var disp_text　= LTSubFunction.createPopupHTMLText( qsTr("ShootingMode") , object.optionText,true, true);
                break;
            case "creativeControlFilter":
                disp_text　= LTSubFunction.createPopupHTMLText( qsTr("ShootingMode") , qsTr("CreativeControl") + " " + object.optionText,true, true);
                break;
            default:
                disp_text　= LTSubFunction.createPopupHTMLText(popupTitle, object.optionText,true, true);
                break;
            }
            LTSubFunction.console_debug.out(disp_text)

            //  状態と表示内容を設定する
// IVC >> Ver.1.9 >> start >> No.5
            if (object.target === "creativeVideoAE") {
// IVC >> Ver.1.9 >> start >> [THRBOXV100-64]
                setOption(object, true);
// IVC << Ver.1.9 << end << [THRBOXV100-64]
            } else {
                switch (object.type) {
                case "optionWithImage":
                case "optionWithImagePopup":
                    root.source = object.source;
                    root.optionTextTooltip = disp_text;
                    if (target === "creativeVideoAE") {
                        root.optionText = object.optionText;
                    }
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
                case "optionWithStyledTextPictureSize":
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
                if (root.target === "recordingMode") {
                    if ( object.target !== "creativeVideoAE") {
                        root.valueChangeFlg = true;
                        root.value = object.value;
                    }
                }
                else {
                    root.valueChangeFlg = true;
                    root.value = object.value;
                }
            }
            if (target === "recordingMode") {
                popup.dismissRecordingMode();
            } else {
                popup.dismiss();
            }
// IVC << Ver.1.9 << end << No.5
        });
    }

// IVC >> Ver.1.9 >> start >> No.5
    function setOption(object, isClicked) {
        var text1 = "<HTML>"
        var text2 = popupTitle
        var text3 = "<br>"
        var text4 = object.optionText
        var text5 = "</HTML>"
        var disp_text = text1 + text2 + text3 + text4 + text5

        // IVC << Ver.1.9 >> start >> [THRBOXV100-64]
        var isCreativeVideo = false;
        if (object.target === "creativeVideoAE") {
            var capabilityNumFuncT = deviceAdapter[object.target+ "CapabilityNum"];
            var capabilityNumT = capabilityNumFuncT();
            if(capabilityNumT === 0){
                isCreativeVideo = true;
            }
        }
        // IVC << Ver.1.9 << end << [THRBOXV100-64]

        root.source = object.source;
        root.valueChangeFlg = isClicked;
        if (target === "recordingMode") {
            root.value = LT.DeviceAdapter.RM_CreativeVideo;
        } else {
            root.value = object.value;
        }
        root.optionTextTooltip = disp_text;
        // IVC << Ver.1.9 >> start >> [THRBOXV100-64]
        if (object.target === "creativeVideoAE") {
            if(deviceAdapter.updateCreativeVideoMode()) {
                if (isCreativeVideo)
                    object.clickSub()
                // IVC >> Ver.1.9 >> start >> [THRBOXV100-161]
                object.valueChangeFlg = true
                object.value = object.value
                // IVC << Ver.1.9 << end << [THRBOXV100-161]
            }
        }
        // IVC << Ver.1.9 << end << [THRBOXV100-64]
    }
// IVC << Ver.1.9 << end << No.5

    function clickCustomSub() {
        //  コンポーネントのプロパティを設定する
        //    * 使用可否と，状態に合わせた LTAbstractButton::checked を設定する
        var components = componentsProvider[target];
        if(!root.optionOpen) {
            return;
        }

        var capability = deviceAdapter[target + "Capability"];

        for (var i = 0; i < components.length; ++i) {
            if (capability(components[i].properties.value) == LT.DeviceAdapter.Ternary_True) {
                components[i].properties.capable = true;
                components[i].properties.enabled = true;
                components[i].properties.checked = components[i].properties.value == value;
            } else {
                components[i].properties.capable = false;
                components[i].properties.enabled = false;
                components[i].properties.checked = false;
            }
        }
        //  ポップアップの表示位置を決定する
        var preferX;
        var preferY;
        switch (type) {
        case "optionWithImagePopup":
            preferX = popupX
            preferY = popupY
            break;
        // nakhuong >> start >>
        case "optionWithTextRealPs":
        // nakhuong << end <<
        case "optionWithRichTextPs":
        case "optionWithImage":
        case "optionWithImageAndText":
        case "optionWithRichText":
        case "optionWithTextReal":
        case "optionWithRichSelectedText":
        case "optionWithText":
        case "optionWithImagetoText":
        case "optionWithImagetoText_dm":
        case "optionWithImagetoTextCc":
        case "optionWithStyledTextPs":
        case "optionWithStyledText":
        case "optionWithStyledTextRealPs":
        case "optionWithStyledTextReal":
        case "optionWithStyledTextPictureSize":
        case "optionWithStyledSelectedText":
            break;
        }

        //  ポップアップを表示する
        if (popup !== null) {
            popup.popup_target = target
            popup.present(preferX, preferY, virtualX, virtualY, popupTitle, value);
        }
    }

    function optionSelect(select, isClicked){
        if (isClicked === undefined) {
            isClicked = false
        }

        // nakhuong >> start >> No.2
        //if(type == "optionWithTextReal") {
        if((type == "optionWithTextReal") || (type == "optionWithTextRealPs") ||
           (type == "optionWithStyledTextReal") || (type == "optionWithStyledTextRealPs") ||
           (type == "optionWithStyledTextPictureSize")) {
        // nakhuong << end << No.2
            optionSelectTextRealSub(select, isClicked)
// IVC >> Ver.1.9 >> start >> No.5
        } else if (target === "recordingMode") {
            optionSelectRecordingMode(select, isClicked);
// IVC << Ver.1.9 << end << No.5
        } else {
            optionSelectSub(select, isClicked)
        }
    }

// IVC >> Ver.1.9 >> start >> No.5
    function optionSelectRecordingMode(select, isClicked) {
        //log record
        if (logCol && (root.valueChangeFlg || root.value !== select)) {
            logCol.log(logLevel, logScrTagID, logFile + " optionSelectRecordingMode", select);
        }
        if((popup !== null) &&
           ((target === popup.popup_target) ||
           (deviceAdapter.cameraStatus == LT.Utilities.CamStatus_MovRec_Others) ||
           (deviceAdapter.cameraStatus == LT.Utilities.CamStatus_Playing) ||
           (deviceAdapter.cameraStatus == LT.Utilities.CamStatus_Processing) ||
// IVC >> Ver.1.9 >> start >> [THRBOXV100-170]
           (deviceAdapter.cameraStatus == LT.Utilities.CamStatus_Menu_Displayed))) {
// IVC << Ver.1.9 << end << [THRBOXV100-170]
            if (!keepPopupOpen || isClicked) {
                //popupでクリック処理中にきたイベントでpopup閉じると落ちるので処理しない
                if(popup.isClicking === false){
                    popup.dismiss();
                }
            }
        }

        root.valueChangeFlg = false
        root.value = select;
        var creativeVideoComponents = componentsProvider["creativeVideoAE"];
        var components = componentsProvider[target];
        var capability = deviceAdapter[target + "Capability"];
        var capabilityNumFunc = deviceAdapter[target + "CapabilityNum"];

        var capabilityNum = capabilityNumFunc();
        for (var i = 0; i < components.length; ++i) {
            components[i].properties.capable = false;
            components[i].properties.checked = false;
        }

        var button_type = btn_type_other

        root.source = ""
        root.optionTextTooltip = ""
        root.optionText = ""
        for (i = 0; i < components.length; ++i) {
            if(components[i].properties.value === value) {
                var judge = (capability(components[i].properties.value) === LT.DeviceAdapter.Ternary_True)
                if ( (capabilityNum >= 2) && (judge) ) {
                    button_type = btn_type_disp_val_enable
                } else if ( (capabilityNum < 2) && (judge) ) {
                    if(isDetail) {
                        button_type = btn_type_disp_val_enable
                    } else {
                        button_type = btn_type_disp_val_disable
                    }
                } else if ( (capabilityNum < 2) && !(judge) ) {
                    button_type = btn_type_nondisp_val_disable
                } else {
                    break;
                }
                components[i].properties.capable = true;
                components[i].properties.checked = components[i].properties.value === value;
                var text1 = "<HTML>";
                var text2 = popupTitle;
                var text3 = "<br>";
                var text4 = components[i].properties.optionText;
                var text5 = "</HTML>";
                var disp_text = text1 + text2 + text3 + text4 + text5;
                if(components[i].properties.checked) {
                    switch (components[i].properties.type) {
                    case "optionWithImage":
                    case "optionWithImagetoText":
                        if (value === LT.Utilities.RM_CreativeVideo) {
                            for(i = 0; i < creativeVideoComponents.length; i += 1) {
                                if (creativeVideoComponents[i].properties.value === deviceAdapter.creativeVideoAE) {
                                    text4 = creativeVideoComponents[i].properties.optionText;
                                    disp_text = text1 + text2 + text3 + text4 + text5;
                                    root.source = creativeVideoComponents[i].properties.source;
                                    root.optionTextTooltip = disp_text;
                                    break;
                                }
                            }
                        } else {
                            root.source = components[i].properties.source;
                            root.optionTextTooltip = disp_text
                        }
                        break;
                    default:
                        break;
                    }
                }
                break;
            }
        }

        switch(button_type) {
        case btn_type_disp_val_enable:
            root.enabled = true
            root.disabled = false                       // 2024/7 Qt6.2 Hover時のアニメを明示的に指定
            break;
        case btn_type_disp_val_disable:
            root.enabled = false
            root.disabled = true                        // 2024/7 Qt6.2 Hover時のアニメを明示的に指定
            break;
        case btn_type_nondisp_val_disable:
            root.enabled = false
            root.optionText = "-"
            root.disabled = true                        // 2024/7 Qt6.2 Hover時のアニメを明示的に指定
            break;
        default:
            root.enabled = false
            root.optionText = "-"
            root.disabled = true                        // 2024/7 Qt6.2 Hover時のアニメを明示的に指定
            break;
        }

        if (isForcedDisable) {
            root.enabled = false
        }
    }
// IVC << Ver.1.9 << end << No.5

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

//        if (target === "sqMotion" || target === "creativeVideoAE" || target === "photoExposure"){
//            console.debug("button Select ", select);
//        }

        //  コンポーネントのプロパティを設定する
        //    * 使用可否と，状態に合わせた LTAbstractButton::checked を設定する
        var components = componentsProvider[target];
        if(deviceAdapter.imgInfoHeifModeAvailable() === true) {                                 // Heif 対応機かどうか判定
            if(target === "imgInfoQuality") {
                if(deviceAdapter.imgInfoJpegHeifMode === LT.Utilities.ImgInfoJHM_JPEG){
                    components = componentsProvider["imgInfoQualityJpeg"];                      // Jpeg
                } else {
                    components = componentsProvider["imgInfoQualityHeif"];                      // Heif
                }
            }
        }
        var capability = deviceAdapter[target + "Capability"];
        var capabilityNumFunc = deviceAdapter[target + "CapabilityNum"];
        if (windowType == "flash") {
            capability = flashAdapter[target + "Capability"];
            capabilityNumFunc = flashAdapter[target + "CapabilityNum"];
        }
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
                    if (capabilityNum === 0 && target === "pscBasePhotoStyle2"){
                        button_type = btn_type_disp_val_disable         // capabilityNum=0、ベースフォトスタイル２のみ対応
                    } else {
                        button_type = btn_type_nondisp_val_disable
                    }
                // それ以外はF/Wの不具合
                } else {
                    //console.log("optionSelect button type error capabilityNum" + capabilityNum);
                    break;
                }
                components[i].properties.capable = true;
                components[i].properties.checked = components[i].properties.value == value;
                if (button_type === btn_type_nondisp_val_disable && (target === "whiteBalanceKSet" || target === "flashSync")){
                    var disp_text　= LTSubFunction.createPopupHTMLText("", popupTitle, true);    //  WB色温度・フラッシュシンクロが無効の時のツールチップ表示
                } else {
                    switch (target) {
                    case "intelligentAutoMode":
                    case "creativeVideoAE":
                    case "sqMotion":
                    case "custom3Set":
                    case "custom4Set":
                    case "custom5Set":
                    case "photoExposure":
                        disp_text　= LTSubFunction.createPopupHTMLText( qsTr("ShootingMode") , components[i].properties.optionText, true);
                        break;
                    case "creativeControlFilter":
                        disp_text　= LTSubFunction.createPopupHTMLText( qsTr("ShootingMode") , qsTr("CreativeControl") + " " + components[i].properties.optionText, true);
                        break;
                    default:
                        disp_text　= LTSubFunction.createPopupHTMLText(popupTitle, components[i].properties.optionText, true);
                        break;
                    }
                }
                if(components[i].properties.checked) {
                    //console.log("optionSelect components[i].properties.type", components[i].properties.type);
                    switch (components[i].properties.type) {
                    case "optionWithImage":
                    case "optionWithImagePopup":
                        root.source = components[i].properties.source;
                        root.optionTextTooltip = disp_text//components[i].properties.optionText;
                        // IVC >> Ver.1.9 >> start >> No.5
                        if (target === "creativeVideoAE" && deviceAdapter.shotModeStatus === LT.Utilities.Shot_Mode_Status_Unknown) {  // 以下の処理がBOX系などで、切替レバー有り機 で強制的にEnableではだめ
                            // if (deviceAdapter.shotModeStatus === LT.Utilities.Shot_Mode_Status_Unknown){
                                // IVC >> Ver.1.9 >> start >> [THRBOXV100-32]
                                //クリエイティブ動画系の撮影モードになっていないと、ケーパビリティで一覧が0として取れてしまい、MC551とかBox系だとDisable表示になってしまう
                                //カスタムとかのクリエイティブ動画系の撮影モードになっているとケーパビリティで一覧は取れている
                                //ライブストリーミング中以外は強制的にEnable状態にする
                                if(deviceAdapter.cameraStatus != LT.Utilities.CamStatus_IP_LiveStreaming &&
                                   deviceAdapter.cameraStatus != LT.Utilities.CamStatus_LiveStreamingRemoteRec){
                                    button_type = btn_type_disp_val_enable;
                                }
                            //}
                            // IVC << Ver.1.9 << end << [THRBOXV100-32]
                            root.optionText = components[i].properties.optionText;
                        }
                        // IVC << Ver.1.9 << end << No.5
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
                    case "optionWithStyledTextPictureSize":
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
            } else {
                if (target === "flashDimmer") {                                 //  発光モードが無効の時のツールチップ表示
                    button_type = btn_type_nondisp_val_disable;
                    root.optionTextTooltip = LTSubFunction.createPopupHTMLText("", popupTitle, true);
                }
            }
        }
        //[ボタン状態]
        switch(button_type) {
        // (a) 現在値表示有り & 有効(クリックすると選択肢を表示)
        case btn_type_disp_val_enable:
            root.enabled = true
            root.disabled = false                       // 2024/7 Qt6.2 Hover時のアニメを明示的に指定
            break;
        // (b) 現在値表示有り & 無効(クリック不可)
        case btn_type_disp_val_disable:
            root.enabled = false
            root.disabled = true                        // 2024/7 Qt6.2 Hover時のアニメを明示的に指定
            break;
        // (c) 現在値表示無し & 無効(クリック不可)
        case btn_type_nondisp_val_disable:
            root.enabled = false
            root.optionText = "-"
            root.disabled = true                        // 2024/7 Qt6.2 Hover時のアニメを明示的に指定
            break;
        // それ以外はF/Wの不具合
        default:
            root.enabled = false
            root.optionText = "-"
            root.disabled = true                        // 2024/7 Qt6.2 Hover時のアニメを明示的に指定
            break;
        }

        if (isForcedDisable) {
            root.enabled = false
        }
    }

    function makeIsoText(value) {
        //・ISO AUTO → "AUTO"
        //    LMX_DEF_ISO_AUTO	0xFFFFFFFF	ISO Auto
        if(value == -1) {
            return qsTr("ISO_Auto")
        }
        //・iISO → "iISO" ('i'と'I'の間が付きすぎて見にくい場合、半角スペースを入れて頂くかもしれません)
        //    LMX_DEF_ISO_I_ISO	0xFFFFFFFE	ISO i-ISO
        else if(value == -2) {
            return qsTr("ISO_I_Iso")
        }

        // H.NAKANO from here   2017.07.24
        // ISO値の最上位4bitで"H." or "L."表示を判定
        //   0 ... "L."/"H."の表示なし
        //   1 ... "L."追加表示
        //   2 ... "H."追加表示
        var l_or_h = (value & 0xF0000000) >> 28
        var iso_value = value & 0x0FFFFFFF
        if (l_or_h == 1) {
            return "L." + String(iso_value)
        }
        else if (l_or_h == 2) {
            return "H." + String(iso_value)
        }
        else {
            return String(iso_value)
        }
        // H.NAKANO to here   2017.07.24
        /*
        //・ISO値が200未満の場合、"L."+数値(例えば、ISO 100 → "L.100"。'L'の後ろに'.'ピリオドが付きます。)
        else if( (0 < value) && (value < 200) ) {
            return '<b><big>' + "L." + String(value) + '</big></b>'
        }
        //・その他数値 → 数値のみ(例えば、ISO 200 → "200")
        return '<b><big>' + String(value) + '</big></b>'
        */
    }

    function makeIsoAutoText(value) {
        // H.NAKANO from here   2017.07.24
        // ISO値の最上位4bitで"H." or "L."表示を判定
        //   0 ... "L."/"H."の表示なし
        //   1 ... "L."追加表示
        //   2 ... "H."追加表示
        var l_or_h = (value & 0xF0000000) >> 28
        var iso_value = value & 0x0FFFFFFF
        if (l_or_h == 1) {
            return "L." + String(iso_value)
        }
        else if (l_or_h == 2) {
            return "H." + String(iso_value)
        }
        else {
            return String(iso_value)
        }
        // H.NAKANO to here   2017.07.24
        /*
        //・ISO値が200未満の場合、"L."+数値(例えば、ISO 100 → "L.100"。'L'の後ろに'.'ピリオドが付きます。)
        if( (0 < value) && (value < 200) ) {
            return '<b><big>' + "L." + String(value) + '</big></b>'
        }
        //・その他数値 → 数値のみ(例えば、ISO 200 → "200")
        return '<b><big>' + String(value) + '</big></b>'
        */
    }

// IVC >> Ver.1.9 >> start >> No.6
// ISO設定:ゲイン値 仕様変更 2023/07 tsutsumi
    function makeIsoGainText(value) {
        if(value == 0xFFFE) {   // OFF
            return qsTr("IsoGain-Off")
        }
        else if(value == 0xFFFF) {  // AUTO
            return qsTr("IsoGain-Auto")
        }
        var p_or_n = (value & 0x8000)      // 0x0000=正数  0x8000=負数
        var l_or_h = (value & 0x3000) >> 12
        var iso_value = value & 0x0FFF
        if (p_or_n === 0) {
            if (l_or_h === 0) {
                return String(iso_value) + qsTr("Iso-dB")
            }
            else if (l_or_h === 1){
                return "L." + String(iso_value) + qsTr("Iso-dB")
            }
            else {
                return "H." + String(iso_value) + qsTr("Iso-dB")
            }
        } else {
            if (l_or_h === 0) {
                return "-" + String(iso_value) + qsTr("Iso-dB")
            }
            else if (l_or_h === 1) {
                return "L.-" + String(iso_value) + qsTr("Iso-dB")
            }
            else {
                return "H.-" + String(iso_value) + qsTr("Iso-dB")
            }
        }
    }

    function makeSSAngleText(value) {
        var ssangle_value = value / 100
        return String(ssangle_value) + qsTr("ShutterSpeed-Angle")
    }
// IVC << Ver.1.9 << end << No.6

    function makePictureSizeText(value) {
        //=================================
        //[変更前]
        //ほぼ連番(上位4bitのみアスペクト比)
        //[変更後]
        //0x[A][B][C][D]
        //[A]:アスペクト：1：4:3、2:3:2、3:16:9、4:4K
        //[B]：サイズ   ：0：L、1：M、2：S、3:6K、4:4K、5:XL、6:LL、7:XS
        //[C]-[D]：各アスペクト、サイズでの通し番号の定義
        //=================================
        switch ((value & 0x00000F00) >> 8) {
        case 0:
            return 'L'
        case 1:
            return 'M'
        case 2:
            return 'S'
        // H.NAKANO from here   2017.07.21
        case 3:
            return '6K'
        case 4:
            return '4K'
        case 5:
            return 'XL'
        case 6:
            return 'LL'
        // H.NAKANO to here   2017.07.21
        // Tsutsumi 2023.11 XS追加　MC8259とMC5231 共通
        case 7:
            return 'XS'
        // Tsutsumi end
        default:
            break;
        }
        return '-'
    }

    function makeApertureText(value) {
        var optionVal = value
        var str
        if(value === 0) {
            str = '<font size="2">F</font>' + "0.0";
        } else {
            str = '<font size="2">F</font>' + (optionVal/10).toFixed(1);
        }
        return str;
    }

    function optionSelectTextRealSub(select, isClicked){
        //log record
        if (logCol && (root.valueChangeFlg || root.value !== select)) {
            logCol.log(logLevel, logScrTagID, logFile + " optionSelectTextRealSub", select);
        }

        if((target == popup.popup_target) ||
           (deviceAdapter.cameraStatus == LT.Utilities.CamStatus_MovRec_Others) ||
           (deviceAdapter.cameraStatus == LT.Utilities.CamStatus_Playing) ||
           (deviceAdapter.cameraStatus == LT.Utilities.CamStatus_Processing)) {
            if (!keepPopupOpen || isClicked) {
                popup.dismiss();
            }
        }

        //  状態と表示内容を設定する
        root.valueChangeFlg = false
        root.value = select;

        if(target == "isoAuto") {
            optionSelectTextRealIsoAutoSub(select)
            return
        }

        var components = new Array

        var comp = 0
        var judge = false
        var cap_value = 0
        for (var i=0; i<512; i++) {
            var capabilityValue = deviceAdapter[target + "CapabilityValue"];
            if (windowType == "flash") {
                capabilityValue = flashAdapter[target + "CapabilityValue"];
            }
            cap_value = capabilityValue(i)
            if(cap_value == value) {
                judge = true
                break
            } else if (cap_value == 0) {
                break
            }
            comp = cap_value
            LTSubFunction.console_debug.out("clickTextRealSub cap_value="+cap_value)
            components.push(cap_value)
        }
        // nakhuong >> start >> No.2
        //if(target == "iso") {
        if((target == "iso") || (target == "pscISO")) {
        // nakhuong << end << No.2
            LTSubFunction.console_debug.out("clickTextRealSub iso_value="+value)
            if((value != 0xFFFFFFFD) && (value != -3)) {
                judge = true
                cap_value = value
            }
        }
// IVC >> Ver.1.9 >> start >> No.6
        if((target == "isoGain") || (target == "pscGain")) {
            if(value != 0xFFFFD) {
                judge = true
                cap_value = value
            }
        }

        if(target == "shutterSpeedAngle") {
            if(value > 0) {
                judge = true
                cap_value = value
            }
        }
// IVC << Ver.1.9 << end << No.6
        if(target == "pictureSize") {
            LTSubFunction.console_debug.out("clickTextRealSub pictureSize="+value)
            judge = true
            cap_value = value
        }
        if(target == "aperture") {
            if( value !== 0xFFFF && value !== 0xFFFE){
                judge = true
                cap_value = value
            }
        }
        var capabilityNumFunc = deviceAdapter[target + "CapabilityNum"];
        if (windowType == "flash") {
            capabilityNumFunc = flashAdapter[target + "CapabilityNum"];
        }
        var capabilityNum = capabilityNumFunc()
        //・(Capabilityの数 >= 2 && 現在値が有効) ⇒ (a) -> type=0
        //[ボタン状態]
        // (a) 現在値表示有り & 有効(クリックすると選択肢を表示)
        // (b) 現在値表示有り & 無効(クリック不可)
        // (c) 現在値表示無し & 無効(クリック不可)
        var button_type = btn_type_other
        if ( (capabilityNum >= 2) && (judge) ) {
            //console.log("optionSelectTextRealSub button type 0 capabilityNum = " + capabilityNum);
            button_type = btn_type_disp_val_enable
        //・(Capabilityの数 <  2 && 現在値が有効) ⇒ (b) -> type=1
        } else if ( (capabilityNum < 2) && (judge) ) {
            //console.log("optionSelectTextRealSub button type 1 capabilityNum = " + capabilityNum + " isDetail" + isDetail);
            if(isDetail) {
                button_type = btn_type_disp_val_enable
            } else {
                button_type = btn_type_disp_val_disable
            }
        //・(Capabilityの数 <  2 && 現在値が無効) ⇒ (c) -> type=2
        } else if ( (capabilityNum < 2) && !(judge) ) {
            //console.log("optionSelectTextRealSub button type 2 capabilityNum = " + capabilityNum);
            button_type = btn_type_nondisp_val_disable
        // それ以外はF/Wの不具合
        } else {
            //console.log("optionSelectTextRealSub button type error capabilityNum = " + capabilityNum);
        }

        root.source = ""
        root.optionTextTooltip = ""
        root.optionText = ""
        if(judge) {
            // nakhuong >> start >> No.2
            //if(target == "iso") {
            if((target == "iso") || (target == "pscISO")) {
            // nakhuong << end << No.2
                var text1 = "<HTML>"
                var text2 = popupTitle
                var text3 = "<br>"
                var text4 = makeIsoText(cap_value)
                var text5 = "</HTML>"
                if (text2 === "") {                                         // 2024/07 フォトスタイル ISO感度ツールチップの余白対策 他のパターンも対処
                    var disp_text = text1 + text4 + text5
                } else {
                    disp_text = text1 + text2 + text3 + text4 + text5
                }
                root.optionText = makeIsoText(cap_value)
                root.optionTextTooltip = disp_text
// IVC >> Ver.1.9 >> start >> No.6
            } else if((target == "isoGain") || (target == "pscGain")) {
                text1 = "<HTML>"
                text2 = popupTitle
                text3 = "<br>"
                text4 = makeIsoGainText(cap_value)
                text5 = "</HTML>"
                if (text2 === "") {
                    disp_text = text1 + text4 + text5
                } else {
                    disp_text = text1 + text2 + text3 + text4 + text5
                }
                root.optionText = makeIsoGainText(cap_value)
                root.optionTextTooltip = disp_text
            } else if(target == "shutterSpeedAngle") {
                text1 = "<HTML>"
                text2 = popupTitle
                text3 = "<br>"
                text4 = makeSSAngleText(cap_value)
                text5 = "</HTML>"
                if (text2 === "") {
                    disp_text = text1 + text4 + text5
                } else {
                    disp_text = text1 + text2 + text3 + text4 + text5
                }
                root.optionText = makeSSAngleText(cap_value)
                root.optionTextTooltip = disp_text
// IVC << Ver.1.9 << end << No.6
            } else if(target == "pictureSize") {
                text1 = "<HTML>"
                text2 = popupTitle
                text3 = "<br>"
                text4 = makePictureSizeText(cap_value)
                text5 = "</HTML>"
                if (text2 === "") {
                    disp_text = text1 + text4 + text5
                } else {
                    disp_text = text1 + text2 + text3 + text4 + text5
                }
                root.optionText = makePictureSizeText(cap_value)
                root.optionTextTooltip = disp_text
            } else if(target == "aperture") {
                text1 = "<HTML>"
                text2 = popupTitle
                text3 = "<br>"
                text4 = makeApertureText(cap_value)
                text5 = "</HTML>"
                if (text2 === "") {
                    disp_text = text1 + text4 + text5
                } else {
                    disp_text = text1 + text2 + text3 + text4 + text5
                }
                root.optionText = makeApertureText(cap_value)
                root.optionTextTooltip = disp_text
            } else {
                text1 = "<HTML>"
                text2 = popupTitle
                text3 = "<br>"
                text4 = String(cap_value)
                text5 = "</HTML>"
                if (text2 === "") {
                    disp_text = text1 + text4 + text5
                } else {
                    disp_text = text1 + text2 + text3 + text4 + text5
                }
                root.optionText = String(cap_value)
                root.optionTextTooltip = disp_text
            }
        }
        //[ボタン状態]
        switch(button_type) {
        // (a) 現在値表示有り & 有効(クリックすると選択肢を表示)
        case btn_type_disp_val_enable:
            root.enabled = true
            root.disabled = false                       // 2024/7 Qt6.2 Hover時のアニメを明示的に指定
            break;
        // (b) 現在値表示有り & 無効(クリック不可)
        case btn_type_disp_val_disable:
            root.enabled = false
            root.disabled = true                        // 2024/7 Qt6.2 Hover時のアニメを明示的に指定
            break;
        // (c) 現在値表示無し & 無効(クリック不可)
        case btn_type_nondisp_val_disable:
            root.enabled = false
            root.optionText = "-"
            root.disabled = true                        // 2024/7 Qt6.2 Hover時のアニメを明示的に指定
            break;
        // それ以外はF/Wの不具合
        default:
            root.enabled = false
            root.optionText = "-"
            root.disabled = true                        // 2024/7 Qt6.2 Hover時のアニメを明示的に指定
            break;
        }

        if (isForcedDisable) {
            root.enabled = false
        }
    }

    function optionSelectTextRealIsoAutoSub(select){
        root.enabled = false
        root.source = ""
        var text1 = "<HTML>"
        var text2 = popupTitle
        var text3 = "<br>"
        var text4 = makeIsoAutoText(root.value)
        var text5 = "</HTML>"
        var disp_text = text1 + text2 + text3 + text4 + text5
        root.optionText = makeIsoAutoText(root.value)
        root.optionTextTooltip = disp_text
    }

    function forceClosePopup() {
        if (popup.visible && target == popup.popup_target) {
            popup.dismiss();
        }
    }

    value: {
        if (windowType == "flash") {
            return flashAdapter[target];
        } else {
            return deviceAdapter[target];
        }
    }
    type: "optionWithImage"
//    fillColor: palette.backgroundDark

}
