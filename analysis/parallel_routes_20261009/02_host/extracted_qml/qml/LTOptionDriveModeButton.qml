import QtQuick 2.7

import "qrc:/qml"
import LT 1.0 as LT
import "LTSubFunction.js" as LTSubFunction

/*! \qmltype LTOptionDriveModeButton
    \inqmlmodule LT

    \brief
    状態を保持するボタンです

    LTOptionButtonPopup,LTOptionButtonSelfTimerPopup によって状態を選択する機能を提供します．
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

    property bool valueChangeFlg: false

    /*!
        DeviceAdapter オブジェクト，ならびに LTOptionButton::componentsProvider のプロパティ名です
     */
    property string target
    property string subTarget
    property string subComponent
    onValueChanged: {
        if (deviceAdapter.driveModeCapabilityNum() !== 0){
            driveSelect = true;                             // ドライブダイアルなし
        } else {
            driveSelect = false;                            // ドライブダイアルあり
            newDriveMode = -1;
            if(target === "selfTimer") {
                popup = selfTimerPopup
            } else {
                popup = generalPopup
            }
        }

        if(root.valueChangeFlg == true) {
            //  状態を設定する
            if (driveSelect){
                deviceAdapter[subTarget] = value;
            } else {
                if(target === "burstSpeed1" || target === "burstSpeed2"){
                    deviceAdapter["burstSpeed"] = value;        // 連写速度(0x02000141)は連写1でも連写2でも設定先は同じ
                } else {
                    deviceAdapter[target] = value;
                }
            }
        }
        return;
    }

    mainImg {       // H.NAKANO from here
        sourceSize {
            width: 75
//            height: 75
        }
        anchors {
            centerIn: undefined
            horizontalCenter: horizontalCenter
        }
        y: (height * 2.0 / 5.0 + 7)
    }               // H.NAKANO to here

    /*!
        Setting to show popup title (hidden if not setting)
     */
    property string popupTitle

    /*!
        状態を選択するポップアップ LTOptionButtonPopup です
     */
    property var generalPopup
    /*!
        状態を選択するポップアップ LTOptionButtonSelfTimerPopup です
     */
    property var selfTimerPopup
    /*!
        状態を選択するポップアップ LTOptionButtonDriveModePopup です
     */
    property var driveModePopup
    /*!
        状態を選択するポップアップです //readonly
     */
    property var popup: {
        if(target === "selfTimer") {
            selfTimerPopup
        } else {
            generalPopup
        }
    }

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

    /*
        ドライブダイアル 有る無し
     */
    property bool driveSelect: false
    property int newDriveMode: -1               // Tooltip用

    onClicked: {
        clickSub()
    }

    Component.onCompleted: {
        selfTimerPopup.changeCustomTime.connect(updateButtonDisp)
    }


    function clickSub() {
        if (driveSelect){
            driveModeSelector();                    // ドライブモードのダイアルが無い場合は処理を変更
            return;
        }
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
        case "optionWithImage":
        case "optionWithImagePopup":
            preferX = parent.parent.x + x;
            preferY = parent.parent.y + y;
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
        popup.present(preferX, preferY, popupTitle, componentsProvider[target], target, function (object) {
            //log record
            if (logCol){
                logCol.log(logLevel, logScrTagID, logFile + " selected", object.value);
            }

            root.updateButtonDisp(object)

            //  ポップアップを非表示にする
            popup.dismiss();
        });
    }

/*
 * ドライブモードの選択の場合はポップアップの表示意味が他と違う
 * target は 現在選択中の driveMode
 */
    function driveModeSelector (){
        popupTitle = qsTr("Drive Mode");
        var components = componentsProvider["driveModeSelect"];     // コンポーネントプロバイダを変更
        var capability = deviceAdapter["driveModeCapability"];
        var tempComponents;                                         // アイコン取得用
        var selectedDriveMode =  deviceAdapter.driveMode;           // 現在のドライブモード
        var ii = 0;
        var param = 0;
        var subParam = 0;
        var driveValue = 0;
        var subValue = 0;
        var popupCount = 0;
        var i = 0
        for (i = 0; i < components.length; ++i) {
            if (capability(components[i].properties.value) == LT.DeviceAdapter.Ternary_True) {
                components[i].properties.capable = true;
                components[i].properties.enabled = true;
                components[i].properties.checked = components[i].properties.value == selectedDriveMode;
// ここで現在の設定されているアイコンをセットする
                switch (components[i].properties.value){
                case LT.Utilities.DM_Burst:
                case LT.Utilities.DM_Burst1:
                case LT.Utilities.DM_Burst2:
                    param = deviceAdapter.burstSpeed;
                    tempComponents = componentsProvider["burstSpeedAll"];
                    for(ii = 0; ii < LT.Utilities.BS_Max; ii++){
                        if(tempComponents[ii].properties.value === param){
                            components[i].properties.source = tempComponents[ii].properties.source;
                            break;
                        }
                    }
                    break
                case LT.Utilities.DM_Interval:
                    if(deviceAdapter.intervalMode !== LT.Utilities.INTM_Interval){
                        components[i].properties.capable = false;
                        components[i].properties.enabled = false;
                        components[i].properties.checked = false;
                    }
                    break;
                case LT.Utilities.DM_Komadori:
                    if(deviceAdapter.intervalMode !== LT.Utilities.INTM_Komadori){
                        components[i].properties.capable = false;
                        components[i].properties.enabled = false;
                        components[i].properties.checked = false;
                    }
                    break;
                case LT.Utilities.DM_SelfTimer:
                     param = deviceAdapter.selfTimer;
                    if (param !== LT.Utilities.SFT_Custom){
                        tempComponents = componentsProvider["selfTimer"];
                        for(ii = 0; ii < LT.Utilities.SFT_Max; ii++){
                            if(tempComponents[ii].properties.value === param){
                                components[i].properties.source = tempComponents[ii].properties.source;
                                break;
                            }
                        }
                    } else {
                        subParam = deviceAdapter.selfTimerCustom
                        tempComponents = componentsProvider["selfTimerCustom"];
                        for(ii = 0; ii < LT.Utilities.SFT_C_Max; ii++){
                            if(tempComponents[ii].properties.value === subParam){
                                components[i].properties.source = tempComponents[ii].properties.optionImage;
                                break;
                            }
                        }
                   }
                    break
                case LT.Utilities.DM_4K6K:
                    param = deviceAdapter.picture4K6K;
                    tempComponents = componentsProvider["picture4K6K"];
                    for(ii = 0; ii < LT.Utilities.PQQ_Max; ii++){
                        if(tempComponents[ii].properties.value === param){
                            components[i].properties.source = tempComponents[ii].properties.source;
                            break;
                        }
                    }
                    break
                case LT.Utilities.DM_Focus:
                    param = deviceAdapter.focusSelect;
                    tempComponents = componentsProvider["focusSelect"];
                    for(ii = 0; ii < LT.Utilities.FS_Max; ii++){
                        if(tempComponents[ii].properties.value === param){
                            components[i].properties.source = tempComponents[ii].properties.source;
                            break;
                        }
                    }
                    break
                }
            } else {
                components[i].properties.capable = false;
                components[i].properties.enabled = false;
                components[i].properties.checked = false;
            }
        }
        //  ポップアップの表示位置を決定する
        //  ポップアップの表示位置を決定する
        var preferX;
        var preferY;
        switch (type) {
        case "optionWithImage":
        case "optionWithImagePopup":
            preferX = parent.parent.x + x;
            preferY = parent.parent.y + y;
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

        if (driveModePopup === null) {
            return
        }
        //  ポップアップを表示する
        driveModePopup.present(preferX, preferY, popupTitle, componentsProvider["driveModeSelect"], target, function (object) {
            //log record
            if (logCol){
                logCol.log(logLevel, logScrTagID, logFile + " selected", object.value);
            }
            //  ポップアップを非表示にする
            driveModePopup.dismiss();

// ここでSubのポップアップを開く
            driveValue = object.value;                // 新規ドライブモード
            switch(object.value){
            case LT.Utilities.DM_Single:              //単写
                subTarget = "driveMode"
                break;
            case LT.Utilities.DM_Burst:               //連写
                subTarget = "burstSpeed"
                subComponent = "burstSpeedAll"
                deviceAdapter.adp_LMX_func_api_RecInfo_BurstBracket_GetCapability()
                subValue = deviceAdapter.burstSpeed   //現在の連写値
                popupTitle = qsTr("Burst")
                break;
            case LT.Utilities.DM_Bracket:             //ブラケット
                subTarget = "driveMode"
                break;
            case LT.Utilities.DM_SelfTimer:           //セルフタイマー
                subTarget = "selfTimer"
                subComponent = "selfTimer"
                popupTitle = qsTr("SelfTimer")
                deviceAdapter.adp_LMX_func_api_RecInfo_SelfTimer_GetCapability()
                subValue = deviceAdapter.selfTimer    //現在のセルフタイマー値
                break;
            case LT.Utilities.DM_Interval:            //インターバル
                subTarget = "driveMode"
                break;
            case LT.Utilities.DM_4K6K:                //6Kフォト・4Kフォト（連写 / 連写（S/S） / プリ連写） / フォーカスセレクト / セルフタイマー / インターバル・コマ撮りアニメ
                subTarget = "picture4K6K"
                subComponent = "picture4K6K"
                popupTitle = qsTr("4K6K")
                break;
            case LT.Utilities.DM_Focus:               //フォーカスセレクト
                subTarget = "focusSelect"
                subComponent = "focusSelect"
                popupTitle = qsTr("Focus")
                break;
            case LT.Utilities.DM_Burst1:              //連写1
                subTarget = "burstSpeed"
                subComponent = "burstSpeedAll"
                deviceAdapter.adp_LMX_func_api_RecInfo_BurstBracket_GetCapability()
                subValue = deviceAdapter.burstSpeed   //現在の連写値
                popupTitle = qsTr("Burst")
                break;
            case LT.Utilities.DM_Burst2:              //連写2
                subTarget = "burstSpeed"
                subComponent = "burstSpeedAll"
                deviceAdapter.adp_LMX_func_api_RecInfo_BurstBracket_GetCapability()
                subValue = deviceAdapter.burstSpeed   //現在の連写値
                popupTitle = qsTr("Burst")
                break;
            case LT.Utilities.DM_Komadori:            //コマ撮り
                subTarget = "driveMode"
                break;
            case LT.Utilities.DM_HRS:                 //ハイレゾショット
                subTarget = "driveMode"
                break;
            case LT.Utilities.DM_HANDHELD_HRS:        //手持ちハイレゾショット
                subTarget = "driveMode"
                break;
            }
//===================================================
            // これまでの clickSub の処理
            //  コンポーネントのプロパティを設定する
            //    * 使用可否と，状態に合わせた LTAbstractButton::checked を設定する
            if (subTarget == "driveMode") {
                deviceAdapter.setDriveMode(driveValue);        // ドライブモードの更新
                newDriveMode = driveValue;
                root.updateButtonDisp(object)
                return;                                        // 追加の選択 Popupが無い場合は終了
            }

            var components = componentsProvider[subComponent];
            var capability = deviceAdapter[subTarget + "Capability"];
            popupCount = 0;                                     // ポップアップのリストが存在しない時の保険
            for (i = 0; i < components.length; ++i) {
                if (capability(components[i].properties.value) == LT.DeviceAdapter.Ternary_True) {
                    components[i].properties.capable = true;
                    components[i].properties.enabled = true;
                    components[i].properties.checked = components[i].properties.value == subValue;
                    popupCount += 1;
                } else {
                    components[i].properties.capable = false;
                    components[i].properties.enabled = false;
                    components[i].properties.checked = false;
                }
            }
            if (popupCount === 0) {
                return                                          // ポップアップで表示するリストが存在しませんでした。
            }
            //  ポップアップの表示位置を決定する
            var preferX;
            var preferY;
            switch (type) {
            case "optionWithImage":
            case "optionWithImagePopup":
                preferX = parent.parent.x + x;
                preferY = parent.parent.y + y;
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

            //  ポップアップを表示する
            if(subTarget === "selfTimer") {
                popup = selfTimerPopup;
            } else {
                popup = generalPopup;
            }

            popup.present(preferX, preferY, popupTitle, componentsProvider[subComponent], subTarget, function (object) {
                //log record
                if (logCol){
                    logCol.log(logLevel, logScrTagID, logFile + " selected", object.value);
                }
                deviceAdapter.setDriveMode(driveValue);        // ドライブモードの更新
                newDriveMode = driveValue;
                root.updateButtonDisp(object)
                //  ポップアップを非表示にする
                popup.dismiss();
            });
        });
    }

    function updateDriveModeToolTip (title, text) {            // 初期表示、本体側でボタン状態が変わった時のツールチップの表示を変更
        var text4 = "";
        switch (deviceAdapter.driveMode){
        case LT.Utilities.DM_Unknown:
            break;
        case LT.Utilities.DM_Single:              //単写
            text4 = text
            break;
        case LT.Utilities.DM_Burst:               //連写
            text4 = title + " " + text
            break;
        case LT.Utilities.DM_Bracket:             //ブラケット
           text4 = text
            break;
        case LT.Utilities.DM_SelfTimer:           //セルフタイマー
            text4 = title + " " + text
            break;
        case LT.Utilities.DM_Interval:            //インターバル
           text4 = text
            break;
        case LT.Utilities.DM_4K6K:                //6Kフォト・4Kフォト（連写 / 連写（S/S） / プリ連写） / フォーカスセレクト / セルフタイマー / インターバル・コマ撮りアニメ
           text4 = title + " " + text
            break;
        case LT.Utilities.DM_Focus:               //フォーカスセレクト
           text4 = title + " "  + text
            break;
        case LT.Utilities.DM_Burst1:              //連写1
             text4 = title + " " + text
            break;
        case LT.Utilities.DM_Burst2:              //連写2
            text4 = title + " " + text
            break;
        case LT.Utilities.DM_Komadori:            //コマ撮り
           text4 = text
            break;
        case LT.Utilities.DM_HRS:                 //ハイレゾショット
           text4 = text
            break;
        case LT.Utilities.DM_HANDHELD_HRS:        //手持ちハイレゾショット
           text4 = text
            break;
        }

        var text1 = "<HTML>"
        var text2 = qsTr("Drive Mode")
        var text3 = "<br>"
        var text5 = "</HTML>"
        var disp_text = text1 + text2 + text3 + text4 + text5
        return disp_text;
    }

    function updateDriveModeToolTipChange (title, text) {
        //console.debug("updateDriveModeToolTipChange", title, " ", text, " ", deviceAdapter.driveMode)
        var text4 = "";
        switch (newDriveMode){
        case LT.Utilities.DM_Unknown:
            break;
        case LT.Utilities.DM_Single:              //単写
            text4 = text
            break;
        case LT.Utilities.DM_Burst:               //連写
            text4 = title + " " + text
            break;
        case LT.Utilities.DM_Bracket:             //ブラケット
           text4 = text
            break;
        case LT.Utilities.DM_SelfTimer:           //セルフタイマー
            text4 = title + " " + text
            break;
        case LT.Utilities.DM_Interval:            //インターバル
           text4 = text
            break;
        case LT.Utilities.DM_4K6K:                //6Kフォト・4Kフォト（連写 / 連写（S/S） / プリ連写） / フォーカスセレクト / セルフタイマー / インターバル・コマ撮りアニメ
           text4 = text
            break;
        case LT.Utilities.DM_Focus:               //フォーカスセレクト
           text4 = text
            break;
        case LT.Utilities.DM_Burst1:              //連写1
             text4 = title + " " + text
            break;
        case LT.Utilities.DM_Burst2:              //連写2
            text4 = title + " " + text
            break;
        case LT.Utilities.DM_Komadori:            //コマ撮り
           text4 = text
            break;
        case LT.Utilities.DM_HRS:                 //ハイレゾショット
           text4 = text
            break;
        case LT.Utilities.DM_HANDHELD_HRS:        //手持ちハイレゾショット
           text4 = text
            break;
        }

        var text1 = "<HTML>"
        var text2 = qsTr("Drive Mode")
        var text3 = "<br>"
        var text5 = "</HTML>"
        var disp_text = text1 + text2 + text3 + text4 + text5
        return disp_text;
    }

    function updateButtonDisp(object) {
        if (driveSelect !== true){
            //var disp_text = LTSubFunction.createPopupHTMLText(popupTitle, object.optionText);
            var disp_text = updateDriveModeToolTip(popupTitle, object.optionText)
        }else{                                              // アプリ操作時 ドライブモードダイアルが無い場合はツールチップの表示を変更
            disp_text = updateDriveModeToolTipChange(popupTitle, object.optionText)
        }
        LTSubFunction.console_debug.out(disp_text)

        //  状態と表示内容を設定する
        root.valueChangeFlg = true
        root.value = object.value;
        root.disabled = false                           // 2024/7 Qt6.2 Hover時のアニメを明示的に指定
        if(root.value == object.value) {
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
        }
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
           (deviceAdapter.cameraStatus == LT.Utilities.CamStatus_Menu_Displayed))) {
            if (!keepPopupOpen || isClicked) {
                popup.dismiss();
            }
        }

        //  状態と表示内容を設定する
        root.valueChangeFlg = false
        root.value = select;

        if(target == "selfTimer") {
            optionSelectSelfTimerSub(select)
            return
        }

        //  コンポーネントのプロパティを設定する
        //    * 使用可否と，状態に合わせた LTAbstractButton::checked を設定する
        var components = componentsProvider[target];
        var capability = deviceAdapter[target + "Capability"];
        var capabilityNumFunc = deviceAdapter[target + "CapabilityNum"];
        var capabilityNum = capabilityNumFunc()
        var i = 0
        for (i = 0; i < components.length; ++i) {
            components[i].properties.capable = false;
            components[i].properties.checked = false;
        }

        //[ボタン状態]
        var button_type = btn_type_other

        root.source = ""
        root.optionTextTooltip = ""
        root.optionText = ""
        for (i = 0; i < components.length; ++i) {
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
//                if (driveSelect !== true){
//                  if (button_type ===  btn_type_disp_val_disable || button_type === btn_type_nondisp_val_disable ){
//                    var disp_text = LTSubFunction.createPopupHTMLText("", components[i].properties.optionText);     // ダイアル有り機のドライブモードが無効の時のツールチップ表示
//                  } else {
//                    disp_text = LTSubFunction.createPopupHTMLText(popupTitle, components[i].properties.optionText); // ダイアル有り機の通常時のツールチップ表示
//                  }
//                }else{                                                                                              // ドライブモードダイアルが無い場合はツールチップの表示を変更
//                    disp_text = updateDriveModeToolTip(popupTitle, components[i].properties.optionText)
//                }
                var disp_text = updateDriveModeToolTip(popupTitle, components[i].properties.optionText)

                if(components[i].properties.checked) {
                    //console.log("optionSelect components[i].properties.type", components[i].properties.type);
                    switch (components[i].properties.type) {
                    case "optionWithImage":
                    case "optionWithImagePopup":
                        root.source = components[i].properties.source;
                        root.optionTextTooltip = disp_text//components[i].properties.optionText;
                        //console.log("optionSelect optionWithImage", components[i].properties.optionText);
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

    function optionSelectSelfTimerSub(select){
        //  状態と表示内容を設定する
        root.valueChangeFlg = false
        root.value = select;
        //  コンポーネントのプロパティを設定する
        //    * 使用可否と，状態に合わせた LTAbstractButton::checked を設定する
        var components = componentsProvider[target];
        var capability = deviceAdapter[target + "Capability"];
        var capabilityNumFunc = deviceAdapter[target + "CapabilityNum"];
        var capabilityNum = capabilityNumFunc()
        var i = 0
        for (i = 0; i < components.length; ++i) {
            components[i].properties.capable = false;
            components[i].properties.checked = false;
        }

        //[ボタン状態]
        var button_type = btn_type_other

        root.source = ""
        root.optionTextTooltip = ""
        root.optionText = ""
        var j = 0
        for (i = 0; i < components.length; ++i) {
            if(components[i].properties.value == value) {
                // カスタム時
                if(value == LT.Utilities.SFT_Custom) {
                    //  コンポーネントのプロパティを設定する
                    //    * 使用可否と，状態に合わせた LTAbstractButton::checked を設定する
                    var customComponents = componentsProvider["selfTimerCustom"];
                    var customCapability = deviceAdapter["selfTimerCustomCapability"];
                    var customCapabilityNumFunc = deviceAdapter["selfTimerCustomCapabilityNum"];
                    var customCapabilityNum = customCapabilityNumFunc()
                    for (j = 0; j < customComponents.length; ++j) {
                        customComponents[j].properties.capable = false;
                        customComponents[j].properties.checked = false;
                    }

                    var customNo = deviceAdapter.selfTimerCustom
                    for (j = 0; j < customComponents.length; ++j) {
                        if(customComponents[j].properties.value == customNo) {
                            var judge = (customCapability(customComponents[j].properties.value) == LT.DeviceAdapter.Ternary_True)
                            //・(Capabilityの数 >= 2 && 現在値が有効) ⇒ (a) -> type=0
                            if ( (customCapabilityNum >= 2) && (judge) ) {
                                button_type = btn_type_disp_val_enable
                            //・(Capabilityの数 <  2 && 現在値が有効) ⇒ (b) -> type=1
                            } else if ( (customCapabilityNum < 2) && (judge) ) {
                                if(isDetail) {
                                    button_type = btn_type_disp_val_enable
                                } else {
                                    button_type = btn_type_disp_val_disable
                                }
                            //・(Capabilityの数 <  2 && 現在値が無効) ⇒ (c) -> type=2
                            } else if ( (customCapabilityNum < 2) && !(judge) ) {
                                button_type = btn_type_nondisp_val_disable
                            // それ以外はF/Wの不具合
                            } else {
                                break;
                            }
                            components[i].properties.capable = true;
                            components[i].properties.checked = components[i].properties.value == value;
//                            if (driveSelect !== true){
//                                var disp_text = LTSubFunction.createPopupHTMLText(popupTitle, components[i].properties.optionText);
//                            }else{                                    // ドライブモードダイアルが無い場合はツールチップの表示を変更
//                                disp_text = updateDriveModeToolTip(popupTitle, components[i].properties.optionText)
//                            }
                            var disp_text = updateDriveModeToolTip(popupTitle, components[i].properties.optionText)

                            if(components[i].properties.checked) {
                                root.source = customComponents[j].properties.optionImage;
                                root.optionTextTooltip = disp_text
                            }
                            break;
                        }
                    }
                } else {
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
//                    if (driveSelect !== true){
//                        disp_text = LTSubFunction.createPopupHTMLText(popupTitle, components[i].properties.optionText);
//                    }else{                                   // ドライブモードダイアルが無い場合はツールチップの表示を変更
//                        disp_text = updateDriveModeToolTip(popupTitle, components[i].properties.optionText)
//                    }
                    disp_text = updateDriveModeToolTip(popupTitle, components[i].properties.optionText)

                    if(components[i].properties.checked) {
                        root.source = components[i].properties.source;
                        root.optionTextTooltip = disp_text
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

    function forceClosePopup() {
        if (popup.visible && target == popup.popup_target) {
            popup.dismiss();
        }
    }

    value: {
        return deviceAdapter[target];
    }
    type: "optionWithImage"
//    fillColor: palette.backgroundDark

}
