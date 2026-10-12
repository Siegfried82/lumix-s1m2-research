import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0

import "qrc:/qml"
import LT 1.0 as LT
import "LTSubFunction.js" as LTSubFunction

/*! \qmltype LTMainMQFilterDetailPopup
    \inqmlmodule LT

    \brief
    LTOptionMovieQualityButton の状態を選択するポップアップです
 */
Item {
    id: root

    visible: false
    anchors {
        fill: parent
    }

    /*!
        ポップアッププロパティ
     */
    
    property real filterPopupHeight: 253    // フィルタポップアップ（親）の高さ。フィルタポップアップ表示の時にセットする。
    property real maximumPopupHeight: filterPopupHeight-overHeight
    property real minimumPopupWidth: 158

    property real overHeight: 0

    readonly property int titile_height: 36

    property string popup_target: ""

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
                    } else {
                        flickable.contentY = flickable.sel_y - f_h_i / 2
                    }
                } else if(maximumPopupHeight < popupContent.height) {
                    flickable.contentY = maximumPopupHeight / 2 - f_h_i / 2
                } else {
                    flickable.contentY = popupContent.height / 2 - f_h_i / 2
                }
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
                id: popupContent
                spacing: 0
            }
            ScrollBar.vertical: LTScrollBar {
                visible: (Math.min(popupContent.height, maximumPopupHeight) < flickable.contentHeight)
            }
        }
    }

    /*!
        ポップアップを表示します
     */
    function present(x, y, label, components, target, targetValue, onSelected) {
        popupContent.width = 0
        popupContent.height = 0
        flickable.sel_y = 0

        value = targetValue
        popup_target = target
        // Load object
        loadObjects(components, onSelected)
        // resize popup
//        if(Math.min(popupContent.height, maximumPopupHeight) < flickable.contentHeight) {
//            flickable.width = minimumPopupWidth + popup.border.width*4
//            popup.width = flickable.width + popup.border.width * 2
//        }
//        else {
//            flickable.width = minimumPopupWidth
//            popup.width = flickable.width + popup.border.width * 2
//        }
        //Setup title label
        if (label && objects.length > 0) {
            titleLabel.text = label
            title.visible = true
            title.height = titile_height
        } else {
            title.visible = false
            title.height = 0
        }
        //Popup coordinate
        x -= (popup.border.width + (popupContent.height > maximumPopupHeight)? flickable.ScrollBar.vertical.width: 0);
        x = Math.max(x, 0);
        x = Math.min(x, root.width - popup.implicitWidth - ((popupContent.height > maximumPopupHeight)? flickable.ScrollBar.vertical.width: 0) );
        y -= popup.border.width
        y = Math.max(y, 0)
        y = Math.min(y, root.height - (Math.min(popupContent.height, maximumPopupHeight) + popup.border.width * 2 + title.height))
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
        visible = true
    }

    function loadObjects(components, onSelected) {
        if (objects.length > 0) {
            root.clearObjects()
        }
// IVC >> mod >> start >> USBTHRV160-39
//        /* Because "Frame Rate" is a dynamically value,
//           their value and text should be get directly ( Same for Compression method, Bit Rate)
//          */
//        if ( (popup_target == "movieFrameRate") || (popup_target == "movieCompressMethod") )
//        {
//            var object
//            var flgNumFunc = deviceAdapter[popup_target + "CapabilityNum"];
//            var num = flgNumFunc()
//            for (var i = 0; i < num; ++i) {
//                object = components[0].component.createObject(popupContent, components[0].properties);
//                var optionVal
//                var optionText = ""
//                switch(popup_target)
//                {
//                case "movieFrameRate":
//                    optionVal = deviceAdapter.mov_quality_filter_frame_rate_value(i)
//                    if(optionVal == 0xFFFFFFFF) {
//                        optionText = components[0].properties.optionText
//                    }
//                    else {
//                        optionText = deviceAdapter.mov_quality_filter_frame_rate_string(i)
//                    }
//                    object.value = optionVal
//                    object.checked = (object.value == value)
//                    break;
//                case "movieCompressMethod":
//                    optionVal = deviceAdapter.mov_quality_filter_compression_method_value(i)
//                    if(optionVal == LT.Utilities.MCPM_ALL) {
//                        optionText = components[0].properties.optionText
//                    }
//                    else {
//                        var cmVal = deviceAdapter.mov_quality_filter_compression_method_string(i)
//                        var compMethod =  cmVal.split(',')
//                        for (var j = 0; j < compMethod.length; j++) {
//                            for (var k = 0; k < components.length; k++) {
//                                if ( components[k].properties.value == compMethod[j] ) {
//                                    optionText += components[k].properties.optionText
//                                    if (j < compMethod.length-1) {
//                                        optionText += "/"
//                                    }
//                                    break;
//                                }
//                            }
//                        }
//                    }
//                    break;
//                default:
//                    break;
//                }
//                object.value = optionVal
//                object.optionText = optionText
//                object.checked = (object.value == value)
//                objects.push(object)

//                if (object.clicked && onSelected) {
//                    object.clicked.connect(function (event, source) {
//                        onSelected(source, true)
//                    });
//                }
//                if(object.checked) {
//                    flickable.sel_y = popupContent.height
//                }
//                popupContent.width = Math.max(popupContent.width, object.width)
//                popupContent.height += object.height
//            }
//        }
//        else
//        {
//            var capability = deviceAdapter[popup_target + "Capability"]
//            for (var i = 0; i < components.length; ++i) {
//                if ( capability(components[i].properties.value) == LT.DeviceAdapter.Ternary_True ) {
//                    components[i].properties.capable = true
//                    components[i].properties.enabled = true
//                    components[i].properties.checked = components[i].properties.value == value
//                } else {
//                    components[i].properties.capable = false
//                    components[i].properties.enabled = false
//                    components[i].properties.checked = false
//                }
//            }
//            for (var i = 0; i < components.length; ++i) {
//                if (!components[i].properties.capable) {
//                    continue
//                }
//                object = components[i].component.createObject(popupContent, components[i].properties)
//                objects.push(object)

//                if (object.clicked && onSelected) {
//                    object.clicked.connect(function (event, source) {
//                        onSelected(source, true)
//                    })
//                }
//                if(object.checked) {
//                    flickable.sel_y = popupContent.height
//                }
//                popupContent.width = Math.max(popupContent.width, object.width)
//                popupContent.height += object.height
//            }
//        }
        var object
        var flgNumFunc = deviceAdapter[popup_target + "CapabilityNum"];
        var num = flgNumFunc()
        var optionVal
        var optionText = ""

        for (var i = 0; i < num; ++i) {
            object = components[0].component.createObject(popupContent, components[0].properties);
            optionText = ""
            switch(popup_target)
            {
            case "movieFrameRate":
                optionVal = deviceAdapter.mov_quality_filter_frame_rate_value(i)
                if(optionVal == 0xFFFFFFFF) {
                    optionText = components[0].properties.optionText
                }
                else {
                    optionText = deviceAdapter.mov_quality_filter_frame_rate_string(i)
                }
                object.value = optionVal
                object.checked = (object.value == value)
                break;
            case "movieCompressMethod":
                optionVal = deviceAdapter.mov_quality_filter_compression_method_value(i)
                if(optionVal == LT.Utilities.MCPM_ALL) {
                    optionText = components[0].properties.optionText
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
                                optionText += components[k].properties.optionText
                                if (j < compMethod.length-1) {
                                    optionText += "/"
                                }
                                break;
                            }
                        }
                    }
                }
                break;
            case "moviePixel":
            case "movieVFR":
            case "movieHLG":
                optionVal = valueForTarget(popup_target, i)
                if(optionVal == LT.Utilities.MCPM_ALL) {
                    optionText = components[0].properties.optionText
                }
                else {
                    optionText = optionTextForTarget(components, popup_target, optionVal)
                }
                break;
            default:
                break;
            }
            var aaa = optionVal
            var bbbb = optionVal
            object.value = optionVal
            object.optionText = optionText
            object.checked = (object.value == value)
            objects.push(object)

            if (object.clicked && onSelected) {
                object.clicked.connect(function (event, source) {
                    onSelected(source, true)
                });
            }
            if(object.checked) {
                flickable.sel_y = popupContent.height
            }
            popupContent.width = Math.max(popupContent.width, object.width)
            popupContent.height += object.height
        }
// IVC << mod << end << USBTHRV160-39
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

    function optionTextForTarget(components, target, value) {
        for (var i = 0; i < components.length; i++) {
            if ( components[i].properties.value == value ) {
                return components[i].properties.optionText
            }
        }

        return "";
    }
// IVC << add << end << USBTHRV160-39

    function clearObjects() {
        var n = objects.length;
        for (var i = 0; i < n; ++i) {
            //  objects に格納されたオブジェクトを取出して破棄する
            var object = objects.pop()
            object.destroy()
        }
    }
    /*!
        ポップアップを隠します
     */
    function dismiss() {
        visible = false
        overHeight = 0
        clearObjects()
    }

    /*!
        ポップアップに表示する，動的に生成したボタン

        \internal
     */
    property var objects: [ ]

}
