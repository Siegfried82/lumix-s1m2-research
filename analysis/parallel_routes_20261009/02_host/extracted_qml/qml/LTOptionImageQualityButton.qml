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
        if(root.valueChangeFlg == true) {
            //  状態を設定する
            deviceAdapter[target] = value;
        }
    }

    mainImg {
        height: 22
        sourceSize {
            height: 22
        }
        fillMode: Image.PreserveAspectFit
        anchors {
            centerIn: undefined
            horizontalCenter: undefined
            verticalCenter: verticalCenter
            right: root.right
        }
        y: height * 2.0 / 5.0 + 7
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

    onClicked: {
        clickSub();
    }

    function clickSub() {
        //  コンポーネントのプロパティを設定する
        //    * 使用可否と，状態に合わせた LTAbstractButton::checked を設定する
        var components = componentsProvider[target];
        if(!root.optionOpen) {
            return;
        }

        for (var i = 0; i < components.length; ++i) {
            if (deviceAdapter.lv_image_quality_list_data_display(components[i].properties.value) === LT.DeviceAdapter.Ternary_True ) {
                components[i].properties.capable = true;
                components[i].properties.enabled = true;
                components[i].properties.optionText = deviceAdapter.lv_image_quality_list_data_resolution(components[i].properties.value);
                components[i].properties.checked = components[i].properties.value == value;
            }
        }
        //  ポップアップの表示位置を決定する
        var preferX = parent.width;
        var preferY = parent.y + popupY;

        if (popup === null) {
            return
        }

        //  ポップアップを表示する
        popup.present(preferX, preferY, popupTitle, componentsProvider[target], target, function (object) {
            //log record
            if (logCol){
                logCol.log(logLevel, logScrTagID, logFile + " selected", object.value);
            }
            /*
            var text1 = "<HTML>"
            var text2 = popupTitle
            var text3 = "<br>"
            var text4 = object.optionOriginalText
            var text5 = "</HTML>"
            var disp_text = text1 + text2 + text3 + text4 + text5
            LTSubFunction.console_debug.out(disp_text)
            */

            // IVC >> Ver.1.8 >> start >> USBTHRV180-16
            if (deviceAdapter.lvShootingStatus ==  LT.Utilities.LCST_SHOOTING ||
                (deviceAdapter.lvShootingStatus ==  LT.Utilities.LCST_PREPARE &&
                deviceAdapter.cameraStatus == LT.Utilities.CamStatus_Noise_Reduction))
            {} else
            // IVC << Ver.1.8 << end << USBTHRV180-16
            {
                //  状態と表示内容を設定する
                root.valueChangeFlg = true
                root.value = object.value;
                root.source = object.source;
                //root.optionTextTooltip = disp_text;
            }

            //  ポップアップを非表示にする
            popup.dismiss();
        });
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
           (deviceAdapter.cameraStatus == LT.Utilities.CamStatus_Processing))) {
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
        for (var i = 0; i < components.length; ++i) {
            components[i].properties.capable = false;
            components[i].properties.checked = false;
        }

        //[ボタン状態]
        var button_type = btn_type_other;

        if (deviceAdapter.imageQualityFlagNum() > 0) {
            button_type = btn_type_disp_val_enable;
        }

        root.source = ""
        root.optionTextTooltip = ""
        root.optionText = ""
        for (var i = 0; i < components.length; ++i) {
            if(components[i].properties.value == value) {
                components[i].properties.capable = true;
                components[i].properties.checked = true;
                components[i].properties.optionText = components[i].properties.optionOriginalText
                var text1 = "<HTML>"
                var text2 = popupTitle
                var text3 = "<br>"
                var text4 = components[i].properties.optionText
                var text5 = "</HTML>"
                var disp_text = text1 + text2 + text3 + text4 + text5
                if(components[i].properties.checked) {
                    switch (components[i].properties.type) {
                    case "optionWithImage":
                        root.source = components[i].properties.source;
                        root.optionTextTooltip = disp_text;
                        break;
                    default:
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
            break;
        // (b) 現在値表示有り & 無効(クリック不可)
        case btn_type_disp_val_disable:
            root.enabled = false
            break;
        // (c) 現在値表示無し & 無効(クリック不可)
        case btn_type_nondisp_val_disable:
            root.enabled = false
            root.optionText = "-"
            break;
        // それ以外はF/Wの不具合
        default:
            root.enabled = false
            root.optionText = "-"
            break;
        }

        if (isForcedDisable) {
            root.enabled = false
        }
    }

    value: deviceAdapter[target];
    type: "optionWithImage"

}
