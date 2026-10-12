import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0

import "qrc:/qml"
import "LTSubFunction.js" as LTSubFunction
// IVC >> Ver.1.9 >> start >> No.1
import LT 1.0 as LT
// IVC << Ver.1.9 << end << No.1

/*! \qmltype LTOptionButtonPopup
    \inqmlmodule LT

    \brief
    LTOptionButton の状態を選択するポップアップです
 */
Item {
    id: root

    visible: false
    anchors {
        fill: parent
    }

    /*!
        ボタンを並べて表示する領域の高さの上限です
     */
    property real maximumPopupHeight: 380-overHeight

    property real overHeight: 0

    readonly property int titile_height: 36

    property string popup_target: ""

    //ボタンクリックされて処理中かどうか
    property bool isClicking: false

    /*
        背景

        ボタンを表示する領域の外部全体を暗くして，マウス操作に反応しないようにします．
        また，クリックされると選択パネルを閉じます．
     */
    Rectangle {
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
                root.dismiss();
            }
        }
    }

    /*
        ボタンを並べて表示する領域
     */
    Rectangle {
        id: popup
        property int start_y: 0
        property int end_y: 0
        property int start_height: 0
        property int end_height: 0
        implicitWidth: flickable.width + border.width * 2
        //implicitHeight: flickable.height + border.width * 2 + title.height
        color: "#000000"
        border {
            width: 2
            color: "#c6c6c6"
        }
        Timer {
            id: animation1
            interval: 20
            running: false
            repeat: true
            property int mode: 0
            readonly property int duration: 100
            property int index: 0
            property int p_y: 0
            property int p_h: 0
            property int f_h_i: 0
            property int f_h_c: 0
            onTriggered: {
                if(mode == 0) {
                    interval = 20
                    p_y = popup.start_y
                    p_h = popup.start_height
                    f_h_i = flickable.start_height_i
                    f_h_c = flickable.start_height_c
                    index = 0
                    mode = 1
                    //flickable.visible = true
                } else {
                    index = index + 1
                    p_y += parseInt((interval*(popup.end_y-popup.start_y))/duration)
                    p_h += parseInt((interval*(popup.end_height-popup.start_height))/duration)
                    f_h_i += parseInt((interval*(flickable.end_height_i-flickable.start_height_i))/duration)
                    f_h_c += parseInt((interval*(flickable.end_height_c-flickable.start_height_c))/duration)
                }
                if(interval*index >= duration) {
                    running=false
                    mode=0
                    p_y = popup.end_y
                    p_h = popup.end_height
                    f_h_i = flickable.end_height_i
                    f_h_c = flickable.end_height_c
                    var n = objects.length;
                    for (var i = 0; i < n; ++i) {
                        objects[i].optionTextTooltip = objects[i].optionText;
                    }
                    popup.enabled = true   // アニメーション中にマウスイベントの発生を防ぐため
                }
                popup.y = p_y
                popup.implicitHeight = p_h
                flickable.implicitHeight = f_h_i
                flickable.height = f_h_i
                //flickable.contentHeight = f_h_c
                if(maximumPopupHeight < flickable.sel_y) {
                    if(popupContent.height - maximumPopupHeight / 2 < flickable.sel_y) {
                        flickable.contentY = popupContent.height - maximumPopupHeight / 2 - f_h_i / 2
                        //LTSubFunction.console_debug.out("flickable.contentY 1 = "+flickable.contentY)
                    } else {
                        flickable.contentY = flickable.sel_y - f_h_i / 2
                        //LTSubFunction.console_debug.out("flickable.contentY 2 = "+flickable.contentY)
                    }
                } else if(maximumPopupHeight < popupContent.height) {
                    flickable.contentY = maximumPopupHeight / 2 - f_h_i / 2
                    //LTSubFunction.console_debug.out("flickable.contentY 3 = "+flickable.contentY)
                } else {
                    flickable.contentY = popupContent.height / 2 - f_h_i / 2
                    //LTSubFunction.console_debug.out("flickable.contentY 4 = "+flickable.contentY)
                }
                //LTSubFunction.console_debug.out("flickable.contentY = "+flickable.contentY)
            }
        }
        Rectangle {
            id: title
            x: popup.border.width
            y: popup.border.width

            width: flickable.width
            height: titile_height

            color: "#07090d"

            LTStylishText {
                id: titleLabel

                x: 6
                y: 6
                width: parent.width - x * 2
                height: parent.height - y * 2

                type: text_style_buttonTitle
            }
        }

        Flickable {
            id: flickable
            property int start_height_i: 0
            property int end_height_i: 0
            property int start_height_c: 0
            property int end_height_c: 0
            property int sel_y: 0
            x: popup.border.width
            y: popup.border.width + title.height
            implicitWidth: popupContent.width + (ScrollBar.vertical.visible ? ScrollBar.vertical.width : 0)
            //implicitHeight: Math.min(popupContent.height, maximumPopupHeight)
            //Behavior on implicitHeight { NumberAnimation { duration: 150; easing.type: Easing.OutBounce }}
            contentHeight: popupContent.height
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            ColumnLayout {
                //  QtQuick モジュールの Column でも同様のことは実現できるが，生成から表示するあたりの制御が異なるらしく，
                //  状態を明示せずに生成した LTAbstractButton の状態が (配置された位置にかかわらず) "hoverred" になって
                //  しまう
                id: popupContent
                spacing: 0
            }
            ScrollBar.vertical: LTScrollBar {
//                visible: (flickable.height == Math.min(popupContent.height, maximumPopupHeight))&&(flickable.height < flickable.contentHeight)
                visible: (Math.min(popupContent.height, maximumPopupHeight) < flickable.contentHeight)
//                visible: (Math.min(popupContent.height, maximumPopupHeight) < flickable.end_height_c)
            }
        }
    }

    /*!
        ポップアップを表示します
     */
    function present(x, y, label, components, target, onSelected) {
        popupContent.width = 0;
        popupContent.height = 0;
        var sel_pos = 0;
        //var sel_y = 0;
        flickable.sel_y = 0;
        var sel_h = 0;
        var num = 0;

        popup_target = target
        // IVC >> Ver.1.9 >> start >> No.5
        popupContent.children = []
        if(target=="recordingMode") {
            maximumPopupHeight = 457
        }
        // IVC << Ver.1.9 << end << No.5

        for (var i = 0; i < components.length; ++i) {
            //  使用可能でなければ，オブジェクトの生成をスキップする
            if (!components[i].properties.capable) {
                continue;
            }
            // Heif対応機は ここでポップアップに表示する項目を制限する                                             // MC8241
            if(deviceAdapter.imgInfoHeifModeAvailable() === true) {                                 // Heif 対応機かどうか判定
                if(target === "imgInfoQuality") {
                    if(deviceAdapter.imgInfoJpegHeifMode === LT.Utilities.ImgInfoJHM_JPEG){         // imgInfoJpegHeifMode !== LT.Utilities.ImgInfoJHM_JPEG Mode の値が正しく返って来ないので(JPEGのみ)
                        switch (components[i].properties.value){                                    // JPEG なら
                        case LT.Utilities.ImgInfoQ_Heif_Fine:
                        case LT.Utilities.ImgInfoQ_Heif_Std:
                        case LT.Utilities.ImgInfoQ_Raw_Heif_Fine:
                        case LT.Utilities.ImgInfoQ_Raw_Heif_Std:
                            continue;
                        default:
                            break;
                        }
                    } else {
                        switch (components[i].properties.value){                                    // HEIF なら
                        case LT.Utilities.ImgInfoQ_Fine:
                        case LT.Utilities.ImgInfoQ_Std:
                        case LT.Utilities.ImgInfoQ_Raw_Fine:
                        case LT.Utilities.ImgInfoQ_Raw_Std:
                            continue;
                        default:
                            break;
                        }
                    }
                }
            }
            //  コンポーネントからオブジェクトを生成して，objects に格納する
            var object = components[i].component.createObject(popupContent, components[i].properties);
            objects.push(object);
            //object.optionTextTooltip = object.optionText;
            //  生成したオブジェクトが clicked シグナルを発行できる場合，シグナルハンドラを設定する
            if (object.clicked && onSelected) {
                object.clicked.connect(function (event, source) {
                    isClicking = true
                    onSelected(source, true)
                    isClicking = false
                });
            }
            // IVC >> Ver.1.9 >> start >> No.1.1
            if(target === "storeLocationType") {
                // IVC >> Ver.1.9 >> start >> [THRBOXV100-96]
                if(btnOptionStoLoc.currentSerialNo !== LT.DeviceAdapter.CameraID_ALL &&
                   btnOptionStoLoc.currentSerialNo !== LT.DeviceAdapter.CameraID_SELECTED) {

                    if(deviceAdapter.btnAllCameraStatus === LT.Utilities.BtnAllCameraStatus_Checked)
                    {
                        object.checked = object.value == LT.DeviceAdapter.CameraID_ALL;
                    }
                    else {
                        object.checked = object.value == deviceAdapter.camera_list_get_selected_camera_uuid();
                    }
                    if(object.value === applicationSettings.getStoreLocationTypeFromList(btnOptionStoLoc.currentSerialNo)) {
                        object.checked = true;
                    }



                }
                else {
                    if(object.value === btnOptionStoLoc.allCameraStoLoc) {
                        object.checked = true;
                    }
                    else {
                        if(deviceAdapter.btnAllCameraStatus === LT.Utilities.BtnAllCameraStatus_Checked)
                        {
                            object.checked = object.value == LT.DeviceAdapter.CameraID_ALL;
                        }

                        else {
                            if(object.value === applicationSettings.getStoreLocationTypeFromList(btnOptionStoLoc.currentSerialNo)) {
                                object.checked = true;
                            }
                            else {
                                object.checked = object.value == deviceAdapter.camera_list_get_selected_camera_uuid();
                            }
                        }
                    }
                }
                // IVC << Ver.1.9 << end << [THRBOXV100-96]
            }
            // IVC << Ver.1.9 << end << No.1.1
            if(target==="focusSelect") {
                //Macでフォーカスセレクトの文字が枠をはみ出るので、フォーカスセレクトの時だけ枠サイズを広げる
                object.implicitWidth = 127;
                object.width = 127;
            }
            if(object.checked) {
                sel_pos = i
                flickable.sel_y = popupContent.height
                sel_h = object.height
            }
            //  ボタンを表示する領域を，生成して配置したオブジェクトにあわせて拡げる
            popupContent.width = Math.max(popupContent.width, object.width);
            popupContent.height += object.height;
        }

        //Setup title label
        if (label && objects.length > 0) {
            titleLabel.text = label;
            title.visible = true;
            title.height = titile_height;
        } else {
            title.visible = false;
            title.height = 0;
        }

        //Popup coordinate
        //popupの表示位置を微調整
        //スクロールバーがありそうな場合とか
        x -= (popup.border.width + (popupContent.height > maximumPopupHeight)? 15: 0);
        x = Math.max(x, 0);
        x = Math.min(x, root.width - popup.implicitWidth - ((popupContent.height > maximumPopupHeight)? 15: 0) );
        x = Math.max(x, 0);
        y -= popup.border.width;
        y = Math.max(y, 0);
        //y = Math.min(y, root.height - popup.implicitHeight);
        y = Math.min(y, root.height - (Math.min(popupContent.height, maximumPopupHeight) + popup.border.width * 2 + title.height));
        if(y < 0) {
            overHeight = y * (-1)
            y = 0
        } else {
            overHeight = 0
        }
        popup.x = x;
        //popup.y = y;
        //if(maximumPopupHeight < sel_y) {
        //    flickable.contentY = Math.min(popupContent.height - maximumPopupHeight, sel_y - maximumPopupHeight / 2)
        //}
        popup.start_y = y+(Math.min(popupContent.height, maximumPopupHeight))/2
        popup.y = popup.start_y
        popup.end_y = y
        popup.start_height = popup.border.width * 2 + title.height
        popup.implicitHeight = popup.start_height
        popup.end_height = Math.min(popupContent.height, maximumPopupHeight) + popup.border.width * 2 + title.height
        flickable.start_height_i = 0
        //flickable.implicitHeight = flickable.start_height_i
        flickable.implicitHeight = Math.min(popupContent.height, maximumPopupHeight)
        flickable.end_height_i = Math.min(popupContent.height, maximumPopupHeight)
        //flickable.start_height_c = 0
        //flickable.contentHeight = flickable.start_height_c
        //flickable.end_height_c = popupContent.height
        //flickable.visible = false
        animation1.interval = 10
        animation1.running = true
        popup.enabled = false   // アニメーション中にマウスイベントの発生を防ぐため
        visible = true;
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

    function presentReal(x, y, label, components, target, value, onSelected) {
        popupContent.width = 0;
        popupContent.height = 0;
        var sel_pos = 0;
        //var sel_y = 0;
        flickable.sel_y = 0;
        var sel_h = 0;
        var num = 0;

        popup_target = target
        // IVC >> Ver.1.9 >> start >> No.5
        popupContent.children = []
        // IVC << Ver.1.9 << end << No.5

        var component = Qt.createComponent("LTRectangleButton.qml");
        if (component.status === Component.Error) {
            console.log("Err createComponent LTRectangleButton: " + component.errorString())
        }
        LTSubFunction.console_debug.out("presentReal length="+components.length)
        for (var i = 0; i < components.length; ++i) {
            var object = component.createObject(popupContent);
            object.width = 107
            object.height = 36
            //object.type = target == "pscISO"?"optionWithRichTextPs":"optionWithRichText"
            //object.type = target == "pscISO"?"optionWithStyledTextPs":"optionWithStyledText"
            if (target == "pscISO" || target == "pscGain") {
                object.type = "optionWithStyledTextPs"
            } else {
                object.type = "optionWithStyledText"
            }
            object.value = components[i]
            // nakhuong >> start >> No.2
            //if(target == "iso") {
            if((target === "iso") || (target === "pscISO")) {
            // nakhuong << end << No.2
                object.optionText = makeIsoText(components[i])
            // IVC >> Ver.1.9 >> start >> No.6
            } else if(target === "isoGain" || target == "pscGain") {
                object.optionText = makeIsoGainText(components[i])
            } else if(target === "shutterSpeedAngle") {
                object.optionText = makeSSAngleText(components[i])
            // IVC << Ver.1.9 << end << No.6
            } else if(target === "isoAuto") {
                object.optionText = makeIsoAutoText(components[i])
            } else if(target === "pictureSize") {
                object.optionText = makePictureSizeText(components[i])
            } else if(target === "aperture") {
                object.optionText = makeApertureText(components[i])
            } else {
                object.optionText = components[i]
            }
            LTSubFunction.console_debug.out("clickTextRealSub optionText="+object.optionText)
            object.checked = ((components[i] == value)? true: false)
            objects.push(object)

            //object.optionTextTooltip = object.optionText;
            //  生成したオブジェクトが clicked シグナルを発行できる場合，シグナルハンドラを設定する
            if (object.clicked && onSelected) {
                object.clicked.connect(function (event, source) {
                    isClicking = true
                    onSelected(source);
                    isClicking = false
                });
            }
            if(object.checked) {
                sel_pos = i
                flickable.sel_y = popupContent.height
                sel_h = object.height
            }
            //  ボタンを表示する領域を，生成して配置したオブジェクトにあわせて拡げる
            popupContent.width = Math.max(popupContent.width, object.width);
            popupContent.height += object.height;
        }

        //Setup title label
        if (label && objects.length > 0) {
            titleLabel.text = label;
            title.visible = true;
            title.height = titile_height;
        } else {
            title.visible = false;
            title.height = 0;
        }

        //Popup coordinate
        x -= (popup.border.width + (popupContent.height > maximumPopupHeight)? 15: 0);
        x = Math.max(x, 0);
        x = Math.min(x, root.width - popup.implicitWidth);
        y -= popup.border.width;
        y = Math.max(y, 0);
        //y = Math.min(y, root.height - popup.implicitHeight);
        y = Math.min(y, root.height - (Math.min(popupContent.height, maximumPopupHeight) + popup.border.width * 2 + title.height));
        if(y < 0) {
            overHeight = y * (-1)
            y = 0
        } else {
            overHeight = 0
        }
        popup.x = x;
        //popup.y = y;
        //if(maximumPopupHeight < sel_y) {
        //    flickable.contentY = Math.min(popupContent.height - maximumPopupHeight, sel_y - maximumPopupHeight / 2)
        //}
        popup.start_y = y+(Math.min(popupContent.height, maximumPopupHeight))/2
        popup.y = popup.start_y
        popup.end_y = y
        popup.start_height = popup.border.width * 2 + title.height
        popup.implicitHeight = popup.start_height
        popup.end_height = Math.min(popupContent.height, maximumPopupHeight) + popup.border.width * 2 + title.height
        flickable.start_height_i = 0
        //flickable.implicitHeight = flickable.start_height_i
        flickable.implicitHeight = Math.min(popupContent.height, maximumPopupHeight)
        flickable.end_height_i = Math.min(popupContent.height, maximumPopupHeight)
        //flickable.start_height_c = 0
        //flickable.contentHeight = flickable.start_height_c
        //flickable.end_height_c = popupContent.height
        //flickable.visible = false
        animation1.interval = 10
        animation1.running = true
        visible = true;
    }

    /*!
        ポップアップを隠します
     */
    function dismiss() {
        visible = false
        overHeight = 0
        //popup.start_y = 0
        //popup.end_y = 0
        //popup.start_height = 0
        //popup.end_height = 0
        //flickable.start_height_i = 0
        //flickable.end_height_i = 0
        var n = objects.length;
        for (var i = 0; i < n; ++i) {
            //  objects に格納されたオブジェクトを取出して破棄する
            var object = objects.pop();
            object.destroy();
        }
    }

    // IVC >> Ver.1.9 >> start >> No.5
    function dismissRecordingMode() {
        visible = false
        overHeight = 0
        var n = objects.length;
        for (var i = 0; i < n; ++i) {
            var object = objects.pop();
            if (object.target !== "creativeVideoAE") {
                object.destroy();
            }
        }
    }
    // IVC << Ver.1.9 << end << No.5

    /*!
        ポップアップに表示する，動的に生成したボタン

        \internal
     */
    property var objects: [ ]

}
