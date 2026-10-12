import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0
import QtQuick.Window 2.3

import "qrc:/qml"
import LT 1.0 as LT
import "LTSubFunction.js" as LTSubFunction

/*! \qmltype LTMainMovieQualityPopup
    \inqmlmodule LT

    \brief
    LTOptionMovieQualityButton の状態を選択するポップアップです
 */
Window {
    id: root

    flags:
        Qt.Window
      | Qt.FramelessWindowHint
      | Qt.Tool

    modality: Qt.NonModal

    visible: false

    width: popup.width
    height: popup.height

    //Windowサイズを変更できなくする
    minimumWidth: popup.width
    minimumHeight: popup.height
    maximumWidth: popup.width
    maximumHeight: popup.height

    property int popupX: 0

    property int popupY: 0

    property int virtualX: 0

    property int virtualY: 0

    property var value

    property var target

    property var select_option

    property bool filterClosed: false

    property real componentMax: 8

    property real componentNum: componentMax

    property real contentHeight: componentHeight*componentNum + componentSpacing*(componentNum-1)

    readonly property real componentWidthDefault: 603
// IVC >> Ver.1.8 >> start >> No.3
    //property real componentWidth: 530
    property real componentWidth: componentWidthDefault
// IVC << Ver.1.8 << end << No.3

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
        "titleText": "#808080",
        "valueText": "#ffffff",
        "headerText": "#ffffff",
        "line": "#000000",
    }

    /*!
        ボタンを並べて表示する領域の高さの上限です
     */
    property alias headerText:                  lblHeader.text
    readonly property real headerHeight:        50
    readonly property real nameHeight:          50
    readonly property real filterWidth:         100
    readonly property real componentSpacing:    0
    readonly property real componentHeight:     65

    property var displayMovQuality
    property var systemFrequency

    LTMainMQComponentsProvider {
        id: componentsProvider
    }

    LTMainMovieQualityFilterPopup {
        id: filterPopup
        onClosed:{
            filterClosed = true;
        }
        onSubmit:{
            filterClosed = true;
            movieQualityDetailSetting();
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
        implicitHeight: headerPanel.height + detailPanel.height + contentHeight + border.width * 2
        color: palette.backgroundDark
        border {
            width: 2
            color: palette.foregroundLight
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
                    popup.enabled = true   // アニメーション中にマウスイベントの発生を防ぐため
                }
                if(contentHeight < flickable.sel_y) {
                    if(popupContent.height - contentHeight / 2 < flickable.sel_y) {
                        flickable.contentY = popupContent.height - contentHeight / 2 - f_h_i / 2
                    } else {
                        flickable.contentY = flickable.sel_y - f_h_i / 2
                    }
                } else if(contentHeight < popupContent.height) {
                    flickable.contentY = contentHeight / 2 - f_h_i / 2
                } else {
                    flickable.contentY = popupContent.height / 2 - f_h_i / 2
                }
            }
        }

        /* Header */
        Row {
            id: headerPanel
            x: 12
            y: popup.border.width
            height: headerHeight
            width: popup.width - popup.border.width * 2

            LTStylishText {
                id: lblHeader
                height: parent.height
                width: parent.width - filterWidth - 30
                text: qsTr("Video quality")
                color: palette.headerText
                type: text_style_wbTuningTitle
            }
            Rectangle {
                id: panelFilter
                width: filterWidth
                height:parent.height - 20
                y: headerHeight/2 - 15
                border.color: palette.foregroundLight
                color: "black"
                border.width: 1
                visible: false

                LTStylishText{
                    text: qsTr("Refine")
                    anchors.centerIn: parent
                    z: 2
                    type: text_style_connectionMsg
                }

                LTOptionButton {
                    id: btnFilter
                    width: filterWidth - 2
                    height: parent.height - 2
                    anchors.centerIn:  parent
                    z: 1
                    popupTitle: qsTr("Filter condition")
                    type: "optionWithImagePopup"
                    target: "recMovie"
                    popup: filterPopup
                    componentsProvider: componentsProvider
                    popupX: root.x+root.width/2
                    popupY: root.y+root.height/2
                    keepPopupOpen: true
                    isDetail: true
                    onClicked: {
                        if (!filterPopup.visible) {
                            filterClosed = false
                            btnFilter.virtualX = root.virtualX
                            btnFilter.virtualY = root.virtualY

                            btnFilter.clickCustomSub()
                        } else {
                            filterPopup.dismiss()
                        }
                    }
                }
            }
        }

        /* Body content */
        Row { /* inner row */
           id: detailPanel
            x: popup.border.width
            y: popup.border.width + headerHeight
            height: nameHeight
            width: popup.width - popup.border.width * 2
            spacing : 1

            Rectangle {
                width: 75 - popup.border.width
                height: parent.height
                color: popup.color
            }

            LTStylishText {
                id: lblPixel
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                width: 75
                height: parent.height
                text: qsTr("Number of pixels")
                color: palette.headerText
                type: text_style_wbTuningTitle
            }

            LTStylishText {
                id: lblFps
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                width: 65
                height: parent.height
                text: qsTr("fps")
                color: palette.headerText
                type: text_style_wbTuningTitle
            }

            LTStylishText {
                id: lblCompressMethod
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                width: 120
                height: parent.height
                text: qsTr("Compression method")
                color: palette.headerText
                type: text_style_wbTuningTitle
            }

            LTStylishText {
                id: lblBitrate
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                width: 60
                height: parent.height
                text: qsTr("Bitrate")
                color: palette.headerText
                type: text_style_wbTuningTitle
            }

            LTStylishText {
                id: lblVFR
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                width: 50
                height: parent.height
                text: qsTr("VFR")
                color: palette.headerText
                type: text_style_wbTuningTitle
            }

            LTStylishText {
                id: lblHLG
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                width: 65
                height: parent.height
                text: qsTr("HLG")
                color: palette.headerText
                type: text_style_wbTuningTitle
            }
// IVC >> Ver.1.8 >> start >> No.3
            LTStylishText {
                id: lblSQ
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                width: 65
                height: parent.height
                text: qsTr("SQ")
                color: palette.headerText
                type: text_style_wbTuningTitle
            }
// IVC << Ver.1.8 << end << No.3
        }

        /* popup's background */
        Rectangle {
            id: background
            x: popup.border.width
            y: popup.border.width + headerHeight + nameHeight
            width: componentWidth - popup.border.width*2 - 100
            height: contentHeight
            color: palette.backgroundDark
        }

        Flickable {
            id: flickable
            property int start_height_i: 0
            property int end_height_i: 0
            property int start_height_c: 0
            property int end_height_c: 0
            property int sel_y: 0
            x: popup.border.width
            y: popup.border.width + headerHeight + nameHeight
            width: componentWidth - popup.border.width
            height: contentHeight
            contentHeight: popupContent.height
            contentWidth: popupContent.width
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            ColumnLayout {
                id: popupContent
                spacing: componentSpacing
            }

            ScrollBar.vertical: LTScrollBar {
                visible: (Math.min(popupContent.height, contentHeight) < flickable.contentHeight)
            }
        }
    }
    onVisibleChanged: {
        utilities.movieQualityWindowVisibleChanged(root.visible)
    }
    Component.onCompleted: {
        deviceAdapter.recMovieFlgNumChanged.connect(root.movieQualityDetailSetting);
        // IVC >> add >> start >> USBTHRV160-26
        displayMovQuality = deviceAdapter.adp_LMX_func_api_Mov_Config_Get_Quality_Detail_Display()
        if (displayMovQuality === LT.DeviceAdapter.Ternary_True) {
            // Get Video Quality Detail List
            deviceAdapter.adp_LMX_func_api_Mov_Config_Get_Quality_Detail_List()
        } else {
            // Get Video Quality Detail List Built-In Data
            deviceAdapter.adp_LMX_Mov_Config_Get_Quality_Detail_List_From_Built_In_Data()
        }
        // IVC << add << end << USBTHRV160-26
    }

    function movieQualityDetailSetting() {
        if (!filterClosed) {
            return
        }
        filterClosed = false
        // Check movie quality
// IVC >> mod >> start >> USBTHRV160-26/USBTHRV160-31
//        if (displayMovQuality === LT.DeviceAdapter.Ternary_True) {
//            target = componentsProvider.recMovieDetailCompName
//        } else {
//            target = componentsProvider.recMovieBuiltInCompName
//        }
        target = componentsProvider.recMovieBuiltInCompName
// IVC << mod << end << USBTHRV160-26/USBTHRV160-31
        // Show popup
        showPopup(root.popupX, root.popupY, root.virtualX, root.virtualY, root.select_option)
    }

    /*!
        ポップアップを表示します
     */
    function present(x, y, vX, vY, popupTitle, targetValue, onSelected) {
// IVC >> add >> start >> USBTHRV160-26
        target = componentsProvider.recMovieBuiltInCompName
// IVC << add << end << USBTHRV160-26

        // Get movie config capability information
        deviceAdapter.adp_LMX_func_api_Mov_Config_GetCapability()

        lblHeader.text = popupTitle
        value = targetValue
        select_option = onSelected
        // Get Video Quality Detail Display
        displayMovQuality = deviceAdapter.adp_LMX_func_api_Mov_Config_Get_Quality_Detail_Display()
// IVC >> mod >> start >> USBTHRV160-26
        if (displayMovQuality === LT.DeviceAdapter.Ternary_True) {
//            target = componentsProvider.recMovieDetailCompName
            deviceAdapter.adp_LMX_func_api_Mov_Filter_GetCapability()
//        } else {
//            target = componentsProvider.recMovieBuiltInCompName
        }
// IVC << mod << end << USBTHRV160-26
        // show popup
        showPopup(x, y, vX, vY, onSelected)
    }
    function showPopup(x, y, vX, vY, onSelected) {
        systemFrequency = deviceAdapter.systemFrequency
        /* Load object*/
        root.loadObjects(onSelected)
        //Check objects
// 動画画質で絞り込み　動画画質が変更出来なくなる
// 表示できるリストがなくてもポップアップを閉じない、また開かせる。
//        if (objects.length <= 0) {
//            root.dismiss()
//            return;
//        }
        /* Popup coordinate*/
        root.popupX = x
        root.popupY = y
        var setX = Math.round((Screen.width  - popup.width) / 2)
        var setY = Math.round((Screen.height - popup.height) / 2)
        // resize popup
// IVC >> mod >> start >> USBTHRV160-26/USBTHRV160-31
//        var recordNum = objects.length
//        if (displayMovQuality === LT.DeviceAdapter.Ternary_True) {
//            recordNum = deviceAdapter.mov_quality_list_number_of_quality()
//        }
        var recordNum = deviceAdapter.mov_quality_list_number_of_quality()
// IVC << mod << end << USBTHRV160-26/USBTHRV160-31
// IVC >> Ver.1.8 >> start >> No.3
        var numberOfQuality = recordNum

        for (var i = 0; i < numberOfQuality; i++) {
            if (displayMovQuality === LT.DeviceAdapter.Ternary_True && lblSQ.visible) {
                var sq = deviceAdapter.mov_quality_list_data_sq(i)
                if ( (deviceAdapter.recordingMode === LT.Utilities.RM_SQMotion) && (sq !== LT.Utilities.MSQ_POSSIBLE ) )
                {
                    recordNum -= 1
                    continue
                }
                // MC8241 2024/8 レバー有り機の場合のチェックを追加
                if ((deviceAdapter.shotModeStatus === LT.Utilities.Shot_Mode_Status_Slow_Quick) && (sq !== LT.Utilities.MSQ_POSSIBLE ))
                {
                    recordNum -= 1
                    continue
                }
            }
            // SD不可かつCFExpress不可は非表示
            var sd = deviceAdapter.mov_quality_list_data_sd(i)
            var cfexpress = deviceAdapter.mov_quality_list_data_cfexpress(i)
            if(sd !== LT.Utilities.MSD_POSSIBLE && cfexpress !== LT.Utilities.MCFEXP_POSSIBLE){
                recordNum -= 1
                continue
            }
        }
// IVC << Ver.1.8 << end << No.3
        componentNum = (recordNum >= componentMax) ? componentMax : recordNum
        contentHeight =  componentHeight*componentNum + componentSpacing*(componentNum-1)
        popup.height = headerPanel.height + contentHeight + detailPanel.height + popup.border.width * 2
        // Adjust position
        if (x !== null && y !== null && vX !== null && vY !== null) {
            var virX = utilities.availableDesktopX(vX, vY)
            var virY = utilities.availableDesktopY(vX, vY)
            var w = utilities.availableDesktopWidth(vX, vY)
            var h = utilities.availableDesktopHeight(vX, vY)
            if (x+popup.width/2 > virX + w ) {
                setX = virX + w - popup.width
            } else if (x-popup.width/2 < virX) {
                setX = virX
            } else {
                setX = x-popup.width/2
            }

            if (y+popup.height/2 > virY + h ) {
                setY = virY + h - popup.height
            } else if (y-popup.height/2 < virY) {
                setY = virY
            } else {
                setY = y- popup.height/2
            }
            root.virtualX = vX
            root.virtualY = vY
        }
        root.x = setX
        root.y = setY

        popup.start_y = y+(Math.min(popupContent.height, contentHeight))/2
        popup.end_y = y
        popup.start_height = popup.border.width * 2 + headerHeight + nameHeight
        popup.end_height = Math.min(popupContent.height, contentHeight)
                                + popup.border.width * 2 + headerHeight + nameHeight
        flickable.start_height_i = 0
        flickable.end_height_i = Math.min(popupContent.height, contentHeight)
        flickable.height = contentHeight - popup.border.width
        animation1.interval = 10
        animation1.running = true
        // resize popup if the number of contents <= 8
        if(Math.min(popupContent.height, contentHeight) >= flickable.contentHeight) {
            background.width = componentWidth - popup.border.width * 10
            flickable.width = componentWidth - popup.border.width * 10
            popup.width = flickable.width + popup.border.width * 2
            popupContent.width = flickable.width
            flickable.interactive = false
        }
        else {
            background.width = componentWidth - popup.border.width * 3
            flickable.width = componentWidth - popup.border.width * 2
            popup.width = flickable.width + popup.border.width * 2
            popupContent.width = flickable.width
            flickable.interactive = true
        }
        root.width = popup.width
        root.height = popup.height
        popup.enabled = false   // アニメーション中にマウスイベントの発生を防ぐため
        visible = true
    }

    function loadObjects(onSelected) {
        if (objects.length > 0) {
            root.clearObjects()
        }
        popupContent.height = 0
        flickable.height = contentHeight
        flickable.sel_y = 0

// IVC >> mod >> start >> USBTHRV160-26
//        var components = componentsProvider[target]
//        var capability = deviceAdapter["recMovieCapability"]
//        var changeSystemFreqEnable = deviceAdapter["changeSystemFreqEnable"]
//        var i = 0
//        for (i = 0; i < components.length; ++i) {
//            if ( capability(components[i].properties.value) === LT.DeviceAdapter.Ternary_True ) {
//                components[i].properties.capable = true
//                components[i].properties.enabled = true
//                components[i].properties.checked = components[i].properties.value == value
//            } else {
//                components[i].properties.capable = false
//                components[i].properties.enabled = false
//                components[i].properties.checked = false
//            }
//        }

//        /* check Movie Quality Display param */
//        displayMovieQualityParam()

//        for (i = 0; i < components.length; i++) {
//            if (!components[i].properties.capable) {
//                continue
//            }
//            var optionText = ""
//            var obj = components[i].component.createObject(popupContent, components[i].properties)
//            if (obj.objectName === componentsProvider.optionDetailWithImageButtonComponentName) {
//                /*Read supported data*/
//                if (displayMovQuality === LT.DeviceAdapter.Ternary_True) {
//                    // Pixel
//                    if (lblPixel.visible) {
//                        var px = deviceAdapter.mov_quality_list_data_pixels(components[i].properties.value)
//                        obj.pixelText = optionTextForTarget(componentsProvider.moviePixelCompName, px)
//                        optionText += obj.pixelText + ","
//                    }
//                    // Frame rate
//                    if (lblFps.visible) {
//                        var fr = deviceAdapter.mov_quality_list_data_frame_rate(components[i].properties.value)
//                        obj.fpsText = fr
//                        optionText += obj.fpsText + ","
//                    }
//                    // Compress method
//                    if (lblCompressMethod.visible) {
//                        var cm = deviceAdapter.mov_quality_list_data_compression_method(components[i].properties.value)
//                        obj.compressMethodText = optionTextForTarget(componentsProvider.movieCompressMethodCompName, cm)
//                        optionText += obj.compressMethodText + ","
//                    }
//                    //Bitrate
//                    if (lblBitrate.visible) {
//                        var br = deviceAdapter.mov_quality_list_data_bit_rate(components[i].properties.value)
//                        obj.bitrateText = br
//                        optionText += obj.bitrateText
//                    }
//                    //VFR
//                    if (lblVFR.visible) {
//                        var vfr = deviceAdapter.mov_quality_list_data_vfr(components[i].properties.value)
//                        if ( vfr == LT.Utilities.MVFR_ALL ) {
//                            obj.vfrText = "-"
//                        }
//                        else {
//                            obj.vfrText = optionTextForTarget(componentsProvider.movieVFRFixedCompName, vfr)
//                        }
//                    }
//                    //HLG
//                    if (lblHLG.visible) {
//                        var hlg = deviceAdapter.mov_quality_list_data_hlg(components[i].properties.value)
//                        if ( hlg == LT.Utilities.MHLG_ALL ) {
//                            obj.hlgText = "-"
//                        }
//                        else {
//                            obj.hlgText = optionTextForTarget(componentsProvider.movieHLGFixedCompName, hlg)
//                        }
//                    }
//                    obj.optionText = optionText
//                    // Show detail information and resize button
//                    obj.showDetail(lblPixel.visible,lblFps.visible,lblCompressMethod.visible,lblBitrate.visible,lblVFR.visible,lblHLG.visible)
//                }
//                /* read built-in data */
//                else {
//                    // Pixel
//                    if (lblPixel.visible) {
//                        obj.pixelText = optionTextForTarget(componentsProvider.moviePixelCompName, components[i].properties.pixels)
//                        optionText += obj.pixelText + ","
//                    }
//                    // Frame rate
//                    if (lblFps.visible) {
//                        var fps = components[i].properties.frameRate_IgnoreFrequency
//                        if(fps !== undefined) {
//                            if( changeSystemFreqEnable === false) {
//                            }
//                            // Other devices
//                            else {
//                                fps = components[i].properties.frameRate
//                            }
//                        } else {
//                            fps = components[i].properties.frameRate
//                        }
//                        obj.fpsText += utilities.movieFrameRateToVal(fps)/100
//                        if (utilities.movieFrameRateToVal(fps,true) == 1) {
//                            obj.fpsText += "p"
//                        } else {
//                            obj.fpsText += "i"
//                        }
//                        optionText += obj.fpsText + ","
//                    }
//                    // Compress method
//                    if (lblCompressMethod.visible) {
//                        var cm = utilities.movieCompressionMethodToStr(components[i].properties.compressionMethod)
//                        obj.compressMethodText = optionTextForTarget(componentsProvider.movieCompressMethodCompName, cm)
//                        optionText += obj.compressMethodText + ","
//                    }
//                    //Bitrate
//                    if (lblBitrate.visible) {
//                        obj.bitrateText = components[i].properties.bitRate + "M"
//                        optionText += obj.bitrateText
//                    }
//                    obj.optionText = optionText
//                    // Show detail information and resize button
//                    obj.showDetail(lblPixel.visible,lblFps.visible,lblCompressMethod.visible,lblBitrate.visible,lblVFR.visible,lblHLG.visible)
//                }
//                popupContent.height += (obj.height + componentSpacing)
//            }
//            objects.push(obj)

//            if (obj.clicked && onSelected) {
//                obj.clicked.connect(function (event, source) {
//                    onSelected(source, true)
//                })
//            }
//            if(obj.checked) {
//                flickable.sel_y = popupContent.height
//            }
//        }
//        var changeSystemFreqEnable = deviceAdapter["changeSystemFreqEnable"]

        /* check Movie Quality Display param */
        displayMovieQualityParam()

        var i = 0
        var components = componentsProvider[target]
        var obj = null
        /*Read supported data*/
        var numberOfQuality = deviceAdapter.mov_quality_list_number_of_quality()
        var cmpProperties = components[0].properties
        var format = deviceAdapter.motionPictureFormat
        for (i = 0; i < numberOfQuality; i++) {
            // IVC >> Ver.1.8 >> start >> No.3
            var sq = 0
            if (displayMovQuality === LT.DeviceAdapter.Ternary_True && lblSQ.visible) {
                sq = deviceAdapter.mov_quality_list_data_sq(i)
                if ( (deviceAdapter.recordingMode === LT.Utilities.RM_SQMotion) && (sq !== LT.Utilities.MSQ_POSSIBLE ))
                {
                    continue
                }
                // MC8241 2024/8 レバー有り機の場合のチェックを追加
                if ((deviceAdapter.shotModeStatus === LT.Utilities.Shot_Mode_Status_Slow_Quick) && (sq !== LT.Utilities.MSQ_POSSIBLE ))
                {
                    continue
                }
            }
            // IVC << Ver.1.8 << end << No.3
            // SD不可かつCFExpress不可は非表示
            var sd = deviceAdapter.mov_quality_list_data_sd(i)
            var cfexpress = deviceAdapter.mov_quality_list_data_cfexpress(i)
            if(sd !== LT.Utilities.MSD_POSSIBLE && cfexpress !== LT.Utilities.MCFEXP_POSSIBLE){
                continue
            }

            var optionText = ""
            obj = components[0].component.createObject(popupContent, cmpProperties)
            //非表示でもアイコンを正しく取得するには値は取っておく必要がある
            // Pixel
            var px_val = deviceAdapter.mov_quality_list_data_pixels(i)
            var px = optionTextForTarget(componentsProvider.moviePixelCompName, px_val)
            if (lblPixel.visible) {
                obj.pixelText = px
                optionText += obj.pixelText
            }
            // Frame rate
            var fr = deviceAdapter.mov_quality_list_data_frame_rate(i)
            if (lblFps.visible) {
                obj.fpsText = fr
                if( optionText ){
                    optionText += ","
                }
                optionText += obj.fpsText
            }
            // Compress method
            var cm_val = deviceAdapter.mov_quality_list_data_compression_method(i)
            var cm = optionTextForTarget(componentsProvider.movieCompressMethodCompName, cm_val)
            if (format == LT.Utilities.MPF_ProRes){
                var compMethod = cm.split('/')               // ProRes の時のみ　x1/x2/x3 の x3 のみ抽出
                if (compMethod.length > 0){
                    cm = compMethod[compMethod.length - 1]
                }
            }
            if (lblCompressMethod.visible) {
                obj.compressMethodText = cm
                if( optionText ){
                    optionText += ","
                }
                optionText += obj.compressMethodText
            }
            //Bitrate
            var br = deviceAdapter.mov_quality_list_data_bit_rate(i)
            if (lblBitrate.visible) {
                obj.bitrateText = br
                if( optionText ){
                    optionText += ","
                }
                optionText += obj.bitrateText
            }
            if (displayMovQuality === LT.DeviceAdapter.Ternary_True) {
                //VFR
                if (lblVFR.visible) {
                    var vfr = deviceAdapter.mov_quality_list_data_vfr(i)
                    if ( vfr == LT.Utilities.MVFR_ALL ) {
                        obj.vfrText = "-"
                    }
                    else {
                        obj.vfrText = optionTextForTarget(componentsProvider.movieVFRFixedCompName, vfr)
                    }
                }
                //HLG
                if (lblHLG.visible) {
                    var hlg = deviceAdapter.mov_quality_list_data_hlg(i)
                    if ( hlg == LT.Utilities.MHLG_ALL ) {
                        obj.hlgText = "-"
                    }
                    else {
                        obj.hlgText = optionTextForTarget(componentsProvider.movieHLGFixedCompName, hlg)
                    }
                }
                // IVC >> Ver.1.8 >> start >> No.3
                //S&Q
                if (lblSQ.visible) {
                    obj.sqText = optionTextForTarget(componentsProvider.movieSQCompName, sq)
                }
                // IVC << Ver.1.8 << end << No.3
            }

            obj.value = deviceAdapter.mov_quality_list_data_video_quality(i)
            obj.optionText = optionText
            obj.checked = (obj.value == value)
            obj.optionImage = LTSubFunction.getRecModeImage(format, px_val, br, cm_val, fr)
            // Show detail information and resize button
// IVC >> Ver.1.8 >> start >> No.3
            //obj.showDetail(lblPixel.visible,lblFps.visible,lblCompressMethod.visible,lblBitrate.visible,lblVFR.visible,lblHLG.visible)
            obj.showDetail(lblPixel.visible,lblFps.visible,lblCompressMethod.visible,lblBitrate.visible,lblVFR.visible,lblHLG.visible, lblSQ.visible)
// IVC << Ver.1.8 << end << No.3

            popupContent.height += (obj.height + componentSpacing)
            //====================
            objects.push(obj)

            if (obj.clicked && onSelected) {
                obj.clicked.connect(function (event, source) {
                    onSelected(source, true)
                })
            }
            if(obj.checked) {
                flickable.sel_y = popupContent.height
            }
        }
// IVC << mod << end << USBTHRV160-26
    }

    function clearObjects() {
        var n = objects.length;
        for (var i = 0; i < n; ++i) {
            //  objects に格納されたオブジェクトを取出して破棄する
            var object = objects.pop()
            object.destroy()
        }
    }

    function displayMovieQualityParam()
    {
        // Reset
        componentWidth = componentWidthDefault
        lblFps.visible = true
        lblPixel.visible = true
        lblCompressMethod.visible = true
        lblBitrate.visible = true
        lblVFR.visible = true
        lblHLG.visible = true
        lblSQ.visible = true

        if (displayMovQuality === LT.DeviceAdapter.Ternary_True) {
            // Get Video Quality Detail List
            deviceAdapter.adp_LMX_func_api_Mov_Config_Get_Quality_Detail_List()

            // Check Filter conditions
            checkFilterCondition()

            var capabilityDetail = deviceAdapter["movieDetailDisplay"]
            for (var i = 0; i < LT.Utilities.MVDD_Max; i++) {
                // Check supported params
                var validDisplay = capabilityDetail(i)
                if(!validDisplay) {// hide
                    switch(i) {
                    case LT.Utilities.MVDD_FRAME_RATE:
                        if (lblFps.visible) {
                            lblFps.visible = false
                            componentWidth -= lblFps.width
                        }
                        break;
                    case LT.Utilities.MVDD_PIXELS:
                        if (lblPixel.visible) {
                            lblPixel.visible = false
                            componentWidth -= lblPixel.width
                        }
                        break;
                    case LT.Utilities.MVDD_COMPRESSION_METHOD:
                        if (lblCompressMethod.visible) {
                            lblCompressMethod.visible = false
                            componentWidth -= lblCompressMethod.width
                        }
                        break;
                    case LT.Utilities.MVDD_BIT_RATE:
                        if (lblBitrate.visible) {
                            lblBitrate.visible = false
                            componentWidth -= lblBitrate.width
                        }
                        break;
                    case LT.Utilities.MVDD_VFR:
                        if (lblVFR.visible) {
                            lblVFR.visible = false
                            componentWidth -= lblVFR.width
                        }
                        break;
                    case LT.Utilities.MVDD_HLG:
                        if (lblHLG.visible) {
                            lblHLG.visible = false
                            componentWidth -= lblHLG.width
                        }
                        break;
                // IVC >> Ver.1.8 >> start >> No.3
                    case LT.Utilities.MVDD_SQ:
                        if (lblSQ.visible) {
                            lblSQ.visible = false
                            componentWidth -= lblSQ.width
                        }
                        break;
                // IVC << Ver.1.8 << end << No.3
                    }
                    background.width = componentWidth - popup.border.width * 3
                    flickable.width = componentWidth - popup.border.width * 2
                    popup.width = flickable.width + popup.border.width * 2
                }
                popupContent.width = flickable.width
            }
        } else { // Built-in data
// IVC >> add >> start >> USBTHRV160-26/USBTHRV160-31
            // Get Video Quality Detail List Built-In Data
            deviceAdapter.adp_LMX_Mov_Config_Get_Quality_Detail_List_From_Built_In_Data()
// IVC << add << end << USBTHRV160-26/USBTHRV160-31
            // hide Filter button
            panelFilter.visible = false
            // hide VFR & HLG
            if (lblVFR.visible) {
                lblVFR.visible = false;
                componentWidth -= lblVFR.width
            }
            if (lblHLG.visible) {
                lblHLG.visible = false;
                componentWidth -= lblHLG.width
            }
            // IVC >> Ver.1.8 >> start >> No.3
            if (lblSQ.visible) {
                lblSQ.visible = false;
                componentWidth -= lblSQ.width
            }
            // IVC << Ver.1.8 << end << No.3
            background.width = componentWidth - popup.border.width * 3
            flickable.width = componentWidth - popup.border.width * 2
            popup.width = flickable.width + popup.border.width * 2
            popupContent.width = flickable.width
        }
    }

    function checkFilterCondition()
    {
        var targets = ["movieFrameRate", "moviePixel", "movieCompressMethod", "movieVFR", "movieHLG"];
        for (var i =0 ; i < targets.length; i++)
        {
            var tg = targets[i]
            var capabilityNumFunc = deviceAdapter[tg + "CapabilityNum"]
            var visible = (capabilityNumFunc() > 0) ? true : false
            switch(tg)
            {
            case componentsProvider.movieFrameRateCompName:
                filterPopup.frameRateVisible = visible
                break
            case componentsProvider.moviePixelCompName:
                filterPopup.pixelsVisible = visible
                break
            case componentsProvider.movieCompressMethodCompName:
                filterPopup.compressionVisible = visible
                break
            case componentsProvider.movieVFRCompName:
                filterPopup.vfrVisible = visible
                break
            case componentsProvider.movieHLGCompName:
                filterPopup.hlgVisible = visible
                break
            }
        }

        if( (filterPopup.frameRateVisible == false) && (filterPopup.pixelsVisible == false) &&
            (filterPopup.compressionVisible == false) && (filterPopup.vfrVisible == false) &&
            (filterPopup.hlgVisible == false) ) {
            panelFilter.visible = false
        }
        else {
            panelFilter.visible = true
        }
    }

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

// IVC >> add >> start >> USBTHRV160-25
//optionImageForObjectはLTSubFunction.getRecModeImage()に統一
// IVC << add << end << USBTHRV160-25

    function cancel() {
        if(filterPopup.visible == true) {
            filterPopup.cancel()
        }
        root.dismiss()
    }

    /*!
        ポップアップを隠します
     */
    function dismiss() {
        filterClosed = false
        if(filterPopup.visible == true) {
            filterPopup.dismiss()
        }
        visible = false
        root.clearObjects()
    }

    /*!
        ポップアップに表示する，動的に生成したボタン

        \internal
     */
    property var objects: [ ]
}
