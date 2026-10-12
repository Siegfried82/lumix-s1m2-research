import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0

import "qrc:/qml"
import LT 1.0 as LT
import "LTSubFunction.js" as LTSubFunction

/*! \qmltype LTOptionButtonSelfTimerPopup
    \inqmlmodule LT

    \brief
    LTOptionButton のセルフタイマーの状態を選択するポップアップです
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

    /*!
        ポップアップに表示するコンポーネントの組を提供するオブジェクトです
     */
    property var componentsProvider

    // カスタム時間変更シグナル
    signal changeCustomTime(LTRectangleButton source)

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
                }
                popup.y = p_y
                popup.implicitHeight = p_h
                flickable.implicitHeight = f_h_i
                flickable.height = f_h_i
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
                visible: (Math.min(popupContent.height, maximumPopupHeight) < flickable.contentHeight)
            }
        }
    }

    /*
        LTOptionButton の状態を選択するポップアップ
     */
    LTOptionButtonPopup {
        id: optionButtonPopup
        z: 100
    }

    /*! 
        カスタム設定ボタン
     */
    LTRectangleButton {
        id: btnCustomSetting

        width: 107
        height: 77
        disabled: false
        visible: false

        optionText: qsTranslate("LTPreferenceWindow", "Preference")
        optionTextTooltip: qsTranslate("LTPreferenceWindow", "Preference")

        property bool isForcedDisable: false

        property real popupX: 0

        property real popupY: 0

        property bool valueChangeFlg: false

        /*!
            DeviceAdapter オブジェクト，ならびに LTOptionButton::componentsProvider のプロパティ名です
         */
        property string target: "selfTimerCustom"

        onValueChanged: {
            if(btnCustomSetting.valueChangeFlg == true) {
                //  状態を設定する
                deviceAdapter[target] = value;
            }
            return;
        }

        /*!
            Setting to show popup title (hidden if not setting)
         */
        property string popupTitle: qsTranslate("LTOptionComponentsProvider", "SFT_Custom")

        /*!
            状態を選択するポップアップ LTOptionButtonPopup です
         */
        property var customPopup: optionButtonPopup

        /*!
            ポップアップに表示するコンポーネントの組を提供するオブジェクトです
         */
        property var componentsProvider: root.componentsProvider

        property bool optionOpen: true

        onClicked: {
            showPopup()
        }

        function showPopup() {
            //  コンポーネントのプロパティを設定する
            //    * 使用可否と，状態に合わせた LTAbstractButton::checked を設定する
            var components = componentsProvider[target];
            if(!btnCustomSetting.optionOpen) {
                return;
            }

            var capability = deviceAdapter[target + "Capability"];
            var customNo = deviceAdapter.selfTimerCustom

            for (var i = 0; i < components.length; ++i) {
                if (capability(components[i].properties.value) == LT.DeviceAdapter.Ternary_True) {
                    components[i].properties.capable = true;
                    components[i].properties.enabled = true;
                    components[i].properties.checked = components[i].properties.value == customNo;
                } else {
                    components[i].properties.capable = false;
                    components[i].properties.enabled = false;
                    components[i].properties.checked = false;
                }
            }
            //  ポップアップの表示位置を決定する
            var preferX = parent.parent.width;
            var preferY = parent.parent.y + y;

            if (customPopup === null) {
                return
            }

            //  ポップアップを表示する
            customPopup.present(preferX, preferY, popupTitle, componentsProvider[target], target, function (object) {
                //log record
                if (logCol){
                    logCol.log(logLevel, logScrTagID, logFile + " selected", object.value);
                }

                //  状態と表示内容を設定する
                btnCustomSetting.valueChangeFlg = true
                btnCustomSetting.value = object.value;
                switch (customObj.type) {
                case "optionWithImage":
                case "optionWithImagePopup":
                    // カスタムボタンのアイコン変更
                    customObj.source = object.optionImage;
                    break;
                }
                //  ポップアップを非表示にする
                customPopup.dismiss();
                // カスタム選択時は変更を通知
                if(customObj.checked) {
                    root.changeCustomTime(customObj)
                }
            });
        }

        function customPopupClose(){
            if(customPopup.visible === true){
                customPopup.dismiss()
            }
        }

        value: {
            return deviceAdapter[target];
        }
        type: "optionWithStyledText"

    }

    /*!
        ポップアップを表示します
     */
    function present(x, y, label, components, target, onSelected) {
        popupContent.width = 0;
        popupContent.height = 0;
        var sel_pos = 0;
        flickable.sel_y = 0;
        var sel_h = 0;
        var num = 0;
        var customValid = false;

        popup_target = target
        popupContent.children = []

        for (var i = 0; i < components.length; ++i) {
            //  使用可能でなければ，オブジェクトの生成をスキップする
            if (!components[i].properties.capable) {
                continue;
            }
            //  コンポーネントからオブジェクトを生成して，objects に格納する
            var object = components[i].component.createObject(popupContent, components[i].properties);
            // カスタムの場合
            if(components[i].properties.value == LT.Utilities.SFT_Custom) {
                var customNo = deviceAdapter.selfTimerCustom
                
                var customComponents = componentsProvider["selfTimerCustom"];
                var customCapability = deviceAdapter["selfTimerCustomCapability"];

                // 選択しているカスタム時間のコンポーネントを見つける
                for (var j = 0; j < customComponents.length; ++j) {
                    if ((customCapability(customComponents[j].properties.value) == LT.DeviceAdapter.Ternary_True) &&
                        (customComponents[j].properties.value == customNo)) {
                        customComponents[j].properties.checked = true
                        break;
                    }
                }
                
                // アイコン設定
                object.source = customComponents[j].properties.optionImage
                
                customObj = object;
                customValid = true;
            }
            objects.push(object);
            //  生成したオブジェクトが clicked シグナルを発行できる場合，シグナルハンドラを設定する
            if (object.clicked && onSelected) {
                object.clicked.connect(function (event, source) {
                    onSelected(source, true)
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

        // カスタムがある場合、設定ボタンを表示する
        if(customValid) {
            btnCustomSetting.parent = popupContent
            btnCustomSetting.visible = true
            
            // ボタンを表示する領域を，生成して配置したオブジェクトにあわせて拡げる
            popupContent.width = Math.max(popupContent.width, btnCustomSetting.width);
            popupContent.height += btnCustomSetting.height;
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
        popup.start_y = y+(Math.min(popupContent.height, maximumPopupHeight))/2
        popup.y = popup.start_y
        popup.end_y = y
        popup.start_height = popup.border.width * 2 + title.height
        popup.implicitHeight = popup.start_height
        popup.end_height = Math.min(popupContent.height, maximumPopupHeight) + popup.border.width * 2 + title.height
        flickable.start_height_i = 0
        flickable.implicitHeight = Math.min(popupContent.height, maximumPopupHeight)
        flickable.end_height_i = Math.min(popupContent.height, maximumPopupHeight)
        animation1.interval = 10
        animation1.running = true
        visible = true;
    }

    /*!
        ポップアップを隠します
     */
    function dismiss() {
        btnCustomSetting.customPopupClose()
        btnCustomSetting.parent = null
        btnCustomSetting.visible = false

        visible = false
        overHeight = 0
        var n = objects.length;
        for (var i = 0; i < n; ++i) {
            //  objects に格納されたオブジェクトを取出して破棄する
            var object = objects.pop();
            object.destroy();
        }
    }

    /*!
        ポップアップに表示する，動的に生成したボタン

        \internal
     */
    property var objects: [ ]

    /*!
        カスタムボタンを格納する
     */
    property var customObj: ""

}
