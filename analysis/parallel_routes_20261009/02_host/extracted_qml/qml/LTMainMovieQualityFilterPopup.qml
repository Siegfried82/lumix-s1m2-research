import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0
import QtQuick.Window 2.3

import "qrc:/qml"
import LT 1.0 as LT
import "LTSubFunction.js" as LTSubFunction

/*! \qmltype LTMainMovieQualityFilterPopup
    \inqmlmodule LT

    \brief
    LTOptionMovieQualityButton の状態を選択するポップアップです
 */
Window {
    id: root

    flags:
        Qt.Window
      | Qt.FramelessWindowHint

    modality: Qt.ApplicationModal

    visible: false

    width: popup.width
    height: popup.height

    //Windowサイズを変更できなくする
    minimumWidth: popup.width
    minimumHeight: popup.height
    maximumWidth: popup.width
    maximumHeight: popup.height

    color: palette.foregroundDark

    signal submit()
    signal closed()

    property var value

    property var target

    property string popup_target: ""

    property alias numberText : lblNumber.text

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
        ポップアッププロパティ
     */
    property alias headerText:              lblHeader.text
    property alias frameRateVisible:        frameRate.visible
    property alias pixelsVisible:           pixels.visible
    property alias compressionVisible:      compressMethod.visible
    property alias vfrVisible:              vFR.visible
    property alias hlgVisible:              hLG.visible

    readonly property real headerHeight:    36
    readonly property real footerHeight:    40
    readonly property real numberWidth:     40

    /*!
        Row spacing
     */
    readonly property double prefRowSpacing: 1
    /*!
        Column spacing
     */
    readonly property double prefColSpacing: 1
    /*!
        Column size (1 column)
     */
    readonly property double prefColWidth: 250
    /*!
        Row size
     */
    readonly property double prefRowHeight: 35

    LTMainMQComponentsProvider {
        id: componentsProvider
    }

    LTMainMQFilterDetailPopup {
        id: movieQualityFilterDetailPopup
        z: 30
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
        implicitWidth: prefColWidth + border.width * 2
        implicitHeight: headerPanel.height + footerPanel.height
                        + frameRate.height + pixels.height + compressMethod.height
                        + vFR.height + hLG.height
                        + border.width * 2
        color: palette.foregroundLight
        border {
            width: 2
            color: palette.foregroundLight
        }
        Rectangle {
            x: popup.border.width
            y: popup.border.width
            id: headerPanel
            height: headerHeight
            width: popup.width - popup.border.width * 2
            color: palette.line
            Text {
                id: lblHeader
                x: 12
                height: parent.height
                width: parent.width - numberWidth - 10
                text: qsTr("Filter condition")
                color: palette.headerText
                font: Qt.font({"pixelSize": 12, "family": utilities.getFontFamily()})
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                id: lblNumber
                x: parent.width - numberWidth - 10
                height: parent.height
                width: numberWidth
                text: qsTr("0")
                color: palette.headerText
                font: Qt.font({"pixelSize": 12, "family": utilities.getFontFamily()})
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
            }
            Text {
                id: lblItems
                x: parent.width
                text: qsTr("Items")
                visible: false
            }
        }
        Rectangle {
           id: detailPanel
            x: popup.border.width
            y: popup.border.width*2 + headerHeight - 1
            height: popup.height - headerHeight - footerHeight
            width: popup.width - popup.border.width * 2
            color: palette.foregroundLight
            z : 20
            Column {
                id: panelMain
                x: popup.border.width
                y: popup.border.width + headerHeight
                anchors.fill: parent
                spacing: prefRowSpacing

                Item {
                    id: frameRate
                    visible: false
                    width: parent.width
                    height: panelFrameRate.height

                    LTFlashGridLayout {
                        id: panelFrameRate
                        colMulti: prefColWidth
                        rowMulti: prefRowHeight
                        columns: 1
                        rows: 1
                        rowSpacing: prefRowSpacing
                        columnSpacing: prefColSpacing

                        LTOptionMovieQualityButton {
                            id: btnOptionFrameRate
                            Layout.rowSpan : 1
                            Layout.columnSpan: 1
                            width: panelFrameRate.prefWidth(this)
                            height: panelFrameRate.prefHeight(this)
                            type: "optionDetailWithTextPref"
                            labelText: qsTr("Frame rate")
                            target: "movieFrameRate"
                            popup: movieQualityFilterDetailPopup
                            componentsProvider: componentsProvider
                            rootParent: panelMain
                        }
                    }
                }
                /* Pixels */
                Item {
                    id: pixels
                    visible: false
                    width: parent.width
                    height: panelPixels.height

                    LTFlashGridLayout {
                        id: panelPixels
                        colMulti: prefColWidth
                        rowMulti: prefRowHeight
                        columns: 1
                        rows: 1
                        rowSpacing: prefRowSpacing
                        columnSpacing: prefColSpacing

                        LTOptionMovieQualityButton {
                            id: btnOptionPixels
                            Layout.rowSpan : 1
                            Layout.columnSpan: 1
                            width: panelPixels.prefWidth(this)
                            height: panelPixels.prefHeight(this)
                            type: "optionDetailWithTextPref"
                            labelText: qsTr("Number of pixels")
                            target: "moviePixel"
                            popup: movieQualityFilterDetailPopup
                            componentsProvider: componentsProvider
                            rootParent: panelMain
                        }
                    }
                }
                /* Compress method */
                Item {
                    id: compressMethod
                    visible: false
                    width: parent.width
                    height: panelCompress.height
                    LTFlashGridLayout {
                        id: panelCompress
                        colMulti: prefColWidth
                        rowMulti: prefRowHeight
                        columns: 1
                        rows: 1
                        rowSpacing: prefRowSpacing
                        columnSpacing: prefColSpacing

                        LTOptionMovieQualityButton {
                            id: btnOptionCompress
                            Layout.rowSpan : 1
                            Layout.columnSpan: 1
                            width: panelCompress.prefWidth(this)
                            height: panelCompress.prefHeight(this)
                            type: "optionDetailWithTextPref"
                            labelText: qsTr("Compression method")
                            target: "movieCompressMethod"
                            popup: movieQualityFilterDetailPopup
                            componentsProvider: componentsProvider
                            rootParent: panelMain
                        }
                    }
                }
                /* VFR */
                Item {
                    id: vFR
                    visible: false
                    width: parent.width
                    height: panelVFR.height

                    LTFlashGridLayout {
                        id: panelVFR
                        colMulti: prefColWidth
                        rowMulti: prefRowHeight
                        columns: 1
                        rows: 1
                        rowSpacing: prefRowSpacing
                        columnSpacing: prefColSpacing

                        LTOptionMovieQualityButton {
                            id: btnOptionVFR
                            Layout.rowSpan : 1
                            Layout.columnSpan: 1
                            width: panelVFR.prefWidth(this)
                            height: panelVFR.prefHeight(this)
                            type: "optionDetailWithTextPref"
                            labelText: qsTr("VFR")
                            target: "movieVFR"
                            popup: movieQualityFilterDetailPopup
                            componentsProvider: componentsProvider
                            rootParent: panelMain
                        }
                    }
                }
                /* HLG */
                Item {
                    id: hLG
                    visible: false
                    width: parent.width
                    height: panelHLG.height

                    LTFlashGridLayout {
                        id: panelHLG
                        colMulti: prefColWidth
                        rowMulti: prefRowHeight
                        columns: 1
                        rows: 1
                        rowSpacing: prefRowSpacing
                        columnSpacing: prefColSpacing

                        LTOptionMovieQualityButton {
                            id: btnOptionHLG
                            Layout.rowSpan : 1
                            Layout.columnSpan: 1
                            width: panelHLG.prefWidth(this)
                            height: panelHLG.prefHeight(this)
                            type: "optionDetailWithTextPref"
                            labelText: qsTr("HLG")
                            target: "movieHLG"
                            popup: movieQualityFilterDetailPopup
                            componentsProvider: componentsProvider
                            rootParent: panelMain
                        }
                    }
                }
            }
        }

        /* Footer*/
        Row {
            id: footerPanel
            x: popup.border.width
            y:  popup.border.width*2 + headerHeight + detailPanel.height
            z : 30
            height: footerHeight
            width: popup.width - popup.border.width * 2
            spacing : 2

            LTRectangleButton {
                id: btnOk
                height: parent.height - 6
                width: parent.width/2 - popup.border.width/2
                type: "action"
                buttonText: qsTr("OK")
                fillColor: palette.backgroundLight
                onClicked: {
                    root.ok()
                }
            }

            LTRectangleButton {
                id: btnCancel
                height: parent.height - 6
                width: parent.width/2 - popup.border.width/2
                type: "action"
                buttonText: qsTr("Cancel")
                fillColor: palette.backgroundLight
                onClicked: {
                    root.cancel()
                }
            }
        }
    }

    Component.onCompleted: {
        deviceAdapter.movieFrameRateInnerChanged.connect(root.movieQualityFilterSetting)
        deviceAdapter.moviePixelInnerChanged.connect(root.movieQualityFilterSetting)
        deviceAdapter.movieCompressMethodInnerChanged.connect(root.movieQualityFilterSetting)
        deviceAdapter.movieVFRInnerChanged.connect(root.movieQualityFilterSetting)
        deviceAdapter.movieHLGInnerChanged.connect(root.movieQualityFilterSetting)
    }

    function movieQualityFilterSetting() {
        target = componentsProvider.recMovieDetailCompName
        // Get Movie quality detail list
        deviceAdapter.adp_LMX_func_api_Mov_Config_Get_Quality_Detail_List()
        // Get number of Movie quality
        var recordNum = deviceAdapter.mov_quality_list_number_of_quality()
        if (recordNum <= 0) {
            btnOk.enabled = false;
        } else {
            btnOk.enabled = true;
        }
        // Set text
        root.numberText = lblItems.text.replace('**', recordNum)

        // Select options
        // Frame rate
        btnOptionFrameRate.optionSelect(deviceAdapter.movieFrameRate)
        // Compression Method
        btnOptionCompress.optionSelect(deviceAdapter.movieCompressMethod)
// IVC >> mod >> start >> USBTHRV160-39
        // Pixel
        //if (deviceAdapter.moviePixel !== LT.Utilities.MP_Unknown)
        btnOptionPixels.optionSelect(deviceAdapter.moviePixel)
        // VFR
        //if (deviceAdapter.movieVFR !== LT.Utilities.MVFR_Unknown)
        btnOptionVFR.optionSelect(deviceAdapter.movieVFR)
        // HLG
        //if (deviceAdapter.movieHLG !== LT.Utilities.MHLG_Unknown)
        btnOptionHLG.optionSelect(deviceAdapter.movieHLG)
// IVC << mod << end << USBTHRV160-39
    }

    /*!
        ポップアップを表示します
     */
    function present(x, y, vX, vY, popupTitle, targetValue, onSelected) {
        // Start filter movie quality
        deviceAdapter.adp_LMX_func_api_MovieFilter_Ctrl_Start()

        lblHeader.text = popupTitle
        value = targetValue
        movieQualityFilterSetting()

        /* Popup coordinate*/
        var setX = Math.round((Screen.width  - popup.width) / 2)
        var setY = Math.round((Screen.height - popup.height) / 2)
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
                setY = y-popup.height/2
            }
        }
        root.x = setX
        root.y = setY
        // calculate popup's height
        var popupHeight = headerPanel.height + footerPanel.height + popup.border.width * 2
        if(frameRate.visible) {
            popupHeight += frameRate.height
        }
        if(pixels.visible) {
            popupHeight += pixels.height
        }
        if(compressMethod.visible) {
            popupHeight += compressMethod.height
        }
        if(vFR.visible) {
            popupHeight += vFR.height
        }
        if(hLG.visible) {
            popupHeight += hLG.height
        }
        popup.height = popupHeight
        root.width = popup.width
        root.height = popup.height
        movieQualityFilterDetailPopup.filterPopupHeight = popupHeight

        visible = true
    }

    function ok() {
        //絞り込み条件設定を決定する。
        var ret = deviceAdapter.adp_LMX_func_api_MovieFilter_Ctrl_End(LT.Utilities.MFC_SUBMIT)

        if(ret === LT.DeviceAdapter.Ternary_True){
            root.submit();
            root.dismiss();
        }
    }

    function cancel() {
        //絞り込み条件設定をキャンセルする。
        deviceAdapter.adp_LMX_func_api_MovieFilter_Ctrl_End(LT.Utilities.MFC_CANCEL)

        root.closed();
        root.dismiss();
    }

    /*!
        ポップアップを隠します
     */
    function dismiss() {
        visible = false
    }
}
