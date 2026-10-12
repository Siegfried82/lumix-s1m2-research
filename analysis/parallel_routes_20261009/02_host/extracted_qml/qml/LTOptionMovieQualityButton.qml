import QtQuick 2.7

import "qrc:/qml"
import LT 1.0 as LT
import "LTSubFunction.js" as LTSubFunction

/*! \qmltype LTOptionMovieQualityButton
    \inqmlmodule LT

    \brief
    状態を保持するボタンです

    LTMainWindow,LTMainMovieQualityFilterPopup,LTMainMQFilterDetailPopup によって状態を選択する機能を提供します．
 */
LTMovieQualityButton {
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
        DeviceAdapter オブジェクト，ならびに LTOptionMovieQualityButton::componentsProvider のプロパティ名です
     */
    property string target
    onValueChanged: {
        if(root.valueChangeFlg == true) {
            //  状態を設定する
            deviceAdapter[target] = value;
        }
        return;
    }

    mainImg {
        sourceSize {
            width: 75
//            height: 75
        }
        anchors {
            centerIn: undefined
            horizontalCenter: horizontalCenter
        }
        y: (target=="pscWB")? (height * 1.0 / 7.0): (height * 2.0 / 5.0 + 7)
    }

    /*!
        Setting to show popup title (hidden if not setting)
     */
    property string popupTitle

    /*!
        状態を選択するポップアップ LTOptionMovieQualityButton です
     */
    property var popup

    /*!
        root view for calculating popup position
     */
    property var rootParent

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
        if (type === "optionDetailWithTextPref") {
            showPopup()
        }
    }

    function clickCustomSub() {
        //  コンポーネントのプロパティを設定する
        //    * 使用可否と，状態に合わせた LTAbstractButton::checked を設定する
        var components = componentsProvider[target]
        if(!root.optionOpen) {
            return
        }

        var capability = deviceAdapter[target + "Capability"]

        for (var i = 0; i < components.length; ++i) {
            if (capability(components[i].properties.value) == LT.DeviceAdapter.Ternary_True) {
                components[i].properties.capable = true
                components[i].properties.enabled = true
                components[i].properties.checked = components[i].properties.value == value
            } else {
                components[i].properties.capable = false
                components[i].properties.enabled = false
                components[i].properties.checked = false
            }
        }
        //  ポップアップの表示位置を決定する
        var preferX
        var preferY
        switch (type) {
        case "optionDetailWithImagePopup":
            preferX = popupX
            preferY = popupY
            break
        default:
            preferX = 0
            preferY = 0
            break
        }

        if (popup === null) {
            return
        }

        //  ポップアップを表示する
        if(type != "optionDetailWithImagePopup") {
            popup.popup_target = target
            popup.present(preferX, preferY, virtualX, virtualY, popupTitle, value)
        }
        else {
            popup.popup_target = target
            popup.present(preferX, preferY, virtualX, virtualY, popupTitle, value, function (object) {
                //log record
                if (logCol){
                    logCol.log(logLevel, logScrTagID, logFile + " selected", object.value)
                }
                var text1 = "<HTML>"
                var text2 = popupTitle
                var text3 = "<br>"
                var text4 = object.optionText
                var text5 = "</HTML>"
                var disp_text = text1 + text2 + text3 + text4 + text5
                LTSubFunction.console_debug.out(disp_text)

                //  状態と表示内容を設定する
                root.valueChangeFlg = true
                root.value = object.value
                if(root.value == object.value) {
                    root.source = object.optionImage
                    root.optionTextTooltip = disp_text
                }
                //  ポップアップを非表示にする
                popup.dismiss()
            });
        }
    }

    function showPopup() {        
        /* Because "Frame Rate" is a dynamically value,
           their value and text should be get directly ( Same for Bit Rate)
          */
// IVC >> mod >> start >> USBTHRV160-39
        if( (target !== "movieFrameRate") && (target !== "movieCompressMethod") &&
            (target !== "moviePixel") & (target !== "movieVFR") &&
            (target !== "movieHLG")
        ) {
// IVC << mod << end << USBTHRV160-39
            var components = componentsProvider[target]
            var capability = deviceAdapter[target + "Capability"]
            for (var i = 0; i < components.length; ++i) {
                if (capability(components[i].properties.value) == LT.DeviceAdapter.Ternary_True) {
                    components[i].properties.capable = true
                    components[i].properties.enabled = true
                    components[i].properties.checked = components[i].properties.value == value
                } else {
                    components[i].properties.capable = false
                    components[i].properties.enabled = false
                    components[i].properties.checked = false
                }
            }
        }

        //  ポップアップの表示位置を決定する
        var point = rootParent.mapFromItem(root, root.x, root.y)
        var preferX = point.x + root.width
        var preferY = point.y + root.height

        //  ポップアップを表示する
        popup.present(preferX, preferY, null, componentsProvider[target], target, value, function (object) {
            //log record
            if (logCol){
                logCol.log(logLevel, logScrTagID, logFile + " selected", object.value)
            }

            //  状態と表示内容を設定する
            root.valueChangeFlg = true
            root.value = object.value
            switch (object.type) {
            case "optionWithText":
                root.optionText = object.optionText
                break
            default:
                break
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
            logCol.log(logLevel, logScrTagID, logFile + " optionSelectSub", select)
        }
        if((popup != null) &&
           ((target == popup.popup_target) ||
           (deviceAdapter.cameraStatus == LT.Utilities.CamStatus_MovRec_Others) ||
           (deviceAdapter.cameraStatus == LT.Utilities.CamStatus_Playing) ||
           (deviceAdapter.cameraStatus == LT.Utilities.CamStatus_Processing))) {
            if (!keepPopupOpen || isClicked) {
                popup.dismiss()
            }
        }
        //  状態と表示内容を設定する
        root.valueChangeFlg = false
        root.value = select;
        //  コンポーネントのプロパティを設定する
        //    * 使用可否と，状態に合わせた LTAbstractButton::checked を設定する
        var components = componentsProvider[target]
        var capability = deviceAdapter[target + "Capability"]
        var capabilityNumFunc = deviceAdapter[target + "CapabilityNum"]
        var capabilityNum = capabilityNumFunc()
        for (var i = 0; i < components.length; ++i) {
            components[i].properties.capable = false
            components[i].properties.checked = false
        }

        //[ボタン状態]
        var button_type = btn_type_other
        root.source = ""
        root.optionTextTooltip = ""
        root.optionText = ""
        /* Because "Frame Rate" is a dynamically value,
           their value and text should be get directly ( Same for Compression Method, Bit Rate)
          */
// IVC >> mod >> start >> USBTHRV160-39
        if( (target == "movieFrameRate") || (target == "movieCompressMethod") ||
            (target == "moviePixel") || (target == "movieVFR") ||
            (target == "movieHLG")
            ) {
// IVC << mod << end << USBTHRV160-39
            var flgNumFunc = deviceAdapter[target + "CapabilityNum"]
            var num = flgNumFunc()
            if (num >=0) {
                 button_type = btn_type_disp_val_enable
            }

            for (var i = 0; i < num; ++i) {
                var optText = ""
                var optValue
                switch(target) {
                case "movieFrameRate":
                    optValue = deviceAdapter.mov_quality_filter_frame_rate_value(i)
                    if(optValue == 0xFFFFFFFF) {
                        optText = components[0].properties.optionText
                    }
                    else {
                        optText = deviceAdapter.mov_quality_filter_frame_rate_string(i)
                    }
                    break;
                case "movieCompressMethod":
                    optValue = deviceAdapter.mov_quality_filter_compression_method_value(i)
                    if(optValue == LT.Utilities.MCPM_ALL) {
                        optText = components[0].properties.optionText
                    }
                    else {
                        var cmVal = deviceAdapter.mov_quality_filter_compression_method_string(i)
                        var compMethod =  cmVal.split(',')
                        for (var j = 0; j < compMethod.length; j++) {
                            if(deviceAdapter.motionPictureFormat == LT.Utilities.MPF_ProRes){
                                if (j != compMethod.length - 1){  //Prores の 時は j == compMethod.length -1(2) の時のみ
                                    continue;
                                }
                            }
                            for (var k = 0; k < components.length; k++) {
                                if ( components[k].properties.value == compMethod[j] ) {
                                    optText += components[k].properties.optionText
                                    if (j < compMethod.length-1) {
                                        optText += "/"
                                    }
                                    break;
                                }
                            }
                        }
                    }
                    break;
// IVC >> add >> start >> USBTHRV160-39
                case "moviePixel":
                case "movieVFR":
                case "movieHLG":
                    optValue = valueForTarget(target, i)
                    if(optValue == LT.Utilities.MP_ALL) {
                        optText = components[0].properties.optionText
                    }
                    else {
                        optText = optionTextForTarget(target,optValue)
                    }
                    break;
// IVC << add << end << USBTHRV160-39
                }

                var text1 = "<HTML>"
                var text2 = popupTitle
                var text3 = "<br>"
                var text4 = optText
                var text5 = "</HTML>"
                var disp_text = text1 + text2 + text3 + text4 + text5
                if(optValue == value) {
                    root.optionText = optText
                    break
                }
            }
        }
        else
        {
// IVC >> mod >> start >> USBTHRV160-26/USBTHRV160-31
//            for (var i = 0; i < components.length; ++i) {
//                if(components[i].properties.value == value) {
//                    var judge = (capability(components[i].properties.value) == LT.DeviceAdapter.Ternary_True)
//                    //・(Capabilityの数 >= 2 && 現在値が有効) ⇒ (a) -> type=0
//                    if ( (capabilityNum >= 2) && (judge) ) {
//                        button_type = btn_type_disp_val_enable
//                    //・(Capabilityの数 <  2 && 現在値が有効) ⇒ (b) -> type=1
//                    } else if ( (capabilityNum < 2) && (judge) ) {
//                        if(isDetail) {
//                            button_type = btn_type_disp_val_enable
//                        } else {
//                            button_type = btn_type_disp_val_disable
//                        }
//                    //・(Capabilityの数 <  2 && 現在値が無効) ⇒ (c) -> type=2
//                    } else if ( (capabilityNum < 2) && !(judge) ) {
//                        button_type = btn_type_nondisp_val_disable
//                    // それ以外はF/Wの不具合
//                    } else {
//                        break;
//                    }
//                    components[i].properties.capable = true;
//                    components[i].properties.checked = components[i].properties.value == value
//                    var text1 = "<HTML>"
//                    var text2 = popupTitle
//                    var text3 = "<br>"
//                    var text4 = components[i].properties.optionText
//                    var text5 = "</HTML>"
//                    var disp_text = text1 + text2 + text3 + text4 + text5
//                    if(components[i].properties.checked) {
//                        switch (components[i].properties.type) {
//                        case "optionWithImage":
//                            root.source = components[i].properties.source;
//                            root.optionTextTooltip = disp_text//components[i].properties.optionText;
//                            break;
//                        case "optionWithText":
//                            root.optionText = components[i].properties.optionText
//                            break;
//                        default:
//                            break;
//                        }
//                    }
//                    break;
//                }
//            }
            var numberOfQuality = deviceAdapter.mov_quality_list_number_of_quality()
            var cmpProperties = components[0].properties_NTSC
            var format = deviceAdapter.motionPictureFormat
            for (i = 0; i < numberOfQuality; i++) {
                var quality_mode = deviceAdapter.mov_quality_list_data_video_quality(i)
                if (quality_mode == value) {
                    if ( capabilityNum >= 2 ) { //・(Capabilityの数 >= 2 ⇒ (a) -> type=0
                        button_type = btn_type_disp_val_enable
                    } else if ( capabilityNum < 2 ) { //・(Capabilityの数 <  2 ⇒ (b) -> type=1
                        if(isDetail) {
                            button_type = btn_type_disp_val_enable
                        } else {
                            button_type = btn_type_disp_val_disable
                        }
                    } else {
                        break;
                    }
                    var optionSource = ""
                    var optionText = ""
                    // Pixel
                    var px_val = deviceAdapter.mov_quality_list_data_pixels(i)
                    var px = optionTextForTarget(componentsProvider.moviePixelCompName, px_val)
                    optionText +=  px + ","
                    //HDMI RAWの判定  LTSubFunction.getRecModeImage　と同じ判定方法
                    var rawMode = false;
                    if( px_val === LT.Utilities.MP_RAW4K_17_9_4096_2160 ||
                        px_val === LT.Utilities.MP_RAW3_7K_4_3_3680_2760 ||
                        px_val === LT.Utilities.MP_RAW3_5K_4_3_3536_2656 ||
                        px_val === LT.Utilities.MP_RAW5_9K_16_9_5888_3312 ||
                        px_val === LT.Utilities.MP_RAW4K_17_9_4128_2176 ||
                        px_val === LT.Utilities.MP_RAW5_8K_4_3_5760_4320 ||
                        px_val === LT.Utilities.MP_RAW5_7K_17_9_5728_3024 ||
                        px_val === LT.Utilities.MP_RAW4_4K_4_3_4352_3264 ||
                        px_val === LT.Utilities.MP_RAW4_1K_17_9_4128_2176 ||
                        px_val === LT.Utilities.MP_RAW6K_3_2_6000_4000 ||
                        px_val === LT.Utilities.MP_RAW4_8K_4_3_4800_3600 ||
                        px_val === LT.Utilities.MP_RAW8_1K_3_2_8128_5418 ||
                        px_val === LT.Utilities.MP_RAW8_1K_17_9_8128_4302 ||
                        px_val === LT.Utilities.MP_RAW7_2K_3_2_7232_4820 ||
                        px_val === LT.Utilities.MP_RAW4_8K_4_3_4752_3568
                       ){
                        rawMode = true;
                    }
                    // Frame rate
                    var fps = deviceAdapter.mov_quality_list_data_frame_rate(i)
                    optionText += fps

                    // compression method
                    var cm_val = deviceAdapter.mov_quality_list_data_compression_method(i)
                    var cm = optionTextForTarget(componentsProvider.movieCompressMethodCompName, cm_val)
                    if (format === LT.Utilities.MPF_ProRes){
                        var compMethod = cm.split('/')               // ProRes の時のみ　x1/x2/x3 の x3 のみ抽出
                        if (compMethod.length > 0){
                                cm = compMethod[compMethod.length - 1]
                        }
                    }
                    if(rawMode !== true){                           // HDMI RAWの時はToolTipに表示しない
                        optionText += "," + cm + ","
                    }
                    // bit rate
                    var br = deviceAdapter.mov_quality_list_data_bit_rate(i)
                    if(rawMode !== true){                           // HDMI RAWの時はToolTipに表示しない
                        optionText += br
                    }
                    optionSource = LTSubFunction.getRecModeImage(format, px_val, br, cm_val, fps)

                    var text1 = "<HTML>"
                    var text2 = popupTitle
                    var text3 = "<br>"
                    var text4 = optionText
                    var text5 = "</HTML>"
                    var disp_text = text1 + text2 + text3 + text4 + text5
                    root.source = optionSource
                    root.optionTextTooltip = disp_text
                    break;
                }
            }
// IVC << mod << end << USBTHRV160-26/USBTHRV160-31
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

// IVC >> add >> start >> USBTHRV160-39
    function valueForTarget(target, index) {
        var val
        switch(target)
        {
        case "moviePixel":
            val = deviceAdapter.mov_quality_filter_pixel_value(index)
            break;
        case "movieVFR":
            val = deviceAdapter.mov_quality_filter_vfr_value(index)
            break;
        case "movieHLG":
            val = deviceAdapter.mov_quality_filter_hlg_value(index)
            break;
        default:
            break;
        }
        return val
    }
// IVC << add << end << USBTHRV160-39

// IVC >> add >> start >> USBTHRV160-25
//optionImageForObjectはLTSubFunction.getRecModeImage()に統一
// IVC << add << end << USBTHRV160-25

// IVC >> add >> start >> USBTHRV160-26/USBTHRV160-31
    function optionTextForTarget(target, value) {
        var components = componentsProvider[target]
        if(target === componentsProvider.movieCompressMethodCompName) {
            var optText = ""
            var compMethod =  value.split(',')
            for (var i = 0; i < compMethod.length; i++) {
                for (var j = 0; j < components.length; j++) {
                    if ( components[j].properties.value == compMethod[i] ) {
                        optText += components[j].properties.optionText
                        if (i < compMethod.length-1) {
                            optText += "/"
                        }
                        break
                    }
                }
            }
            return optText
        } else {
            for (var i = 0; i < components.length; i++) {
                if ( components[i].properties.value == value ) {
                    return components[i].properties.optionText
                }
            }
        }

        return "";
    }
// IVC << add << end << USBTHRV160-26/USBTHRV160-31

    value: deviceAdapter[target]
    type: "action"
}
