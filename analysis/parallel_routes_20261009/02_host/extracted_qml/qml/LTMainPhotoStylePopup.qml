import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0
import QtQuick.Window 2.3

import "qrc:/qml"
import LT 1.0 as LT
import "LTSubFunction.js" as LTSubFunction

/*! \qmltype LTMainWBPopup
    \inqmlmodule LT

    \brief
    LTOptionButton の状態を選択するポップアップです
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

    signal onOKClicked()

    signal onCancelClicked()

    signal onChangeValue()

    property var value

    property var resetVal

    property var target

    property string popup_target: ""
// IVC >> Ver.1.9 >> start >> [THRBOXV100-165]
    property int savedContentY: 0

    property int savedContentHeight: 0                              // 2024/7 内部エリアの高さ保存

    property var currentSelectedPhotoStyle

    property bool isLoadObject: false
// IVC << Ver.1.9 << end << [THRBOXV100-165]

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


    property alias headerText: lblHeader.text

    readonly property real lblHeaderHeight: 36

    readonly property real btnHeaderHeight: 50

    readonly property real headerHeight: lblHeaderHeight + btnHeaderHeight

    readonly property real titleSize: 36

    readonly property real lineSize: 2

    readonly property real componentNum: 6

    readonly property real componentSpacing: 1

    readonly property real componentHeight: 77

    readonly property real contentHeight: componentHeight*componentNum + componentSpacing*(componentNum-1)

    readonly property real componentWidth: 400//350 //323 //400

    LTMainPSComponentsProvider {
        id: componentsProvider
    }

    LTOptionButtonPopup {
        id: optionPopup
        // ivc >> start >> No.2
        // Content: maximumPopupHeight is 80 percent of popupContent
        maximumPopupHeight: popup.height * 80 / 100

        onVisibleChanged: {
            if (!visible) {
                flickable.interactive = true
            }
            else {
                flickable.interactive = false
            }
        }
        // ivc << end << No.2
        z: 100
    }

    /*
        ボタンを並べて表示する領域
     */
    Rectangle {
        id: popup
        implicitWidth: flickable.width + border.width * 2

        implicitHeight: headerPanel.height + contentHeight + btnPanel.height + border.width * 2
        color: "#000000"

        border {
            width: 2
            color: "#c6c6c6"
        }

        Item {
            id: headerPanel

            x: popup.border.width
            y: popup.border.width
            height: headerHeight
            width: popup.width - popup.border.width * 2

            LTStylishText {
                id: lblHeader

                x: 12
                y: 0
                height: lblHeaderHeight
                width: parent.width

                text: qsTr("Photo Style")
                color: palette.headerText
                type: text_style_wbTuningTitle
            }

            LTOptionButton {
                id: btnHeader

                x: 0
                y: lblHeaderHeight
                height: btnHeaderHeight
                width: parent.width

                type: "optionWithImageAndText"
                fillColor: palette.backgroundLight

                target: "photoStyle"
                componentsProvider: componentsProvider
                popup: optionPopup
                value: LT.Utilities.PS_Unknown

                // ivc >> start >> Support Multi-Language
                //popupX: headerPanel.x + btnHeader.x + (btnHeader.width - 180)/2
                popupX: headerPanel.x + btnHeader.x + (btnHeader.width - 340)/2
                // ivc << end << Support Multi-Language
                popupY: 0
            }
        }

        Rectangle {
            x: popup.border.width
            y: popup.border.width + headerHeight
            width: componentWidth
            height: contentHeight

            color: palette.backgroundLight
        }

        Flickable {
            id: flickable
            x: popup.border.width
            y: popup.border.width + headerHeight
            width: componentWidth
            height: contentHeight
            contentHeight: popupContent.height
            contentWidth: popupContent.width
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            // ivc >> start >> No.2
            onContentYChanged: {
                   componentsProvider.updatePopup = contentY
// IVC >> Ver.1.9 >> start >> [THRBOXV100-165]
                if(!isLoadObject) {
                    savedContentY = contentY;
                } else {
                    isLoadObject = false;
                }
// IVC << Ver.1.9 << end << [THRBOXV100-165]
            }
            // ivc << end << No.2

            ColumnLayout {
                id: popupContent
                spacing: componentSpacing
            }

            // ivc >> start >> No.2
            ScrollBar.vertical: LTScrollBar {
                visible: (Math.min(popupContent.height, contentHeight) < flickable.contentHeight)
            }
            // ivc << end << No.2
        }

        Row {
            id: btnPanel

            x: popup.border.width
            y: popup.border.width + headerHeight + flickable.height
            height: btnCancel.height
            width: popup.width - popup.border.width * 2

            spacing : 2

            LTRectangleButton {
                id: btnOk

                height: 40
                width: (flickable.width - btnPanel.spacing)/2
                type: "action"
                buttonText: qsTr("Ok")

                fillColor: palette.backgroundLight

                onClicked: {
                    // IVC >> Ver.1.9 >> start >> [THRBOXV100-165]
                    savedContentY = 0;
                    // IVC << Ver.1.9 << end << [THRBOXV100-165]
                    root.ok()
                }
            }

            LTRectangleButton {
                id: btnCancel

                height: 40
                width: (flickable.width - btnPanel.spacing)/2
                type: "action"
                buttonText: qsTr("Cancel")

                fillColor: palette.backgroundLight

                onClicked: {
                    // IVC >> Ver.1.9 >> start >> [THRBOXV100-165]
                    savedContentY = 0;
                    // IVC << Ver.1.9 << end << [THRBOXV100-165]
                    root.cancel()
                }
            }
        }
    }

    Component.onCompleted: {
        deviceAdapter.photoStyleCapabilityChanged.connect(root.photoStyleSetting)
        deviceAdapter.photoStyleCompFlgNumChanged.connect(root.photoStyleSetting)
        deviceAdapter.pscPhotoModeChanged.connect(root.photoStyleSetting)
        // IVC >> Ver.1.9 >> start >> [THRBOXV100-130] [THRBOXV100-131]
        deviceAdapter.pscISOChanged.connect(root.photoStyleSetting);
        deviceAdapter.pscDualISOChanged.connect(root.photoStyleSetting);
          // MC5229
        deviceAdapter.pscGainChanged.connect(root.photoStyleSetting);
        // MC8259
        deviceAdapter.pscDensityChanged.connect(root.photoStyleSetting);
        deviceAdapter.pscDensity2Changed.connect(root.photoStyleSetting);
        // IVC << Ver.1.9 << end << [THRBOXV100-130] [THRBOXV100-131]
// IVC >> Ver.1.9 >> start >> [THRBOXV100-165]
        currentSelectedPhotoStyle = deviceAdapter.photoStyle;
// IVC << Ver.1.9 << end << [THRBOXV100-165]
        photoStyleSetting()
    }

    function photoStyleSetting() {
        if (deviceAdapter.photoStyle !== LT.Utilities.PS_Unknown) {
            // IVC >> Ver.1.9 >> start >> [THRBOXV100-94]
//            if (btnHeader.value !== deviceAdapter.photoStyle) {
            // IVC << Ver.1.9 << end << [THRBOXV100-94]
                btnHeader.optionSelect(deviceAdapter.photoStyle)
            // IVC >> Ver.1.9 >> start >> [THRBOXV100-94]
//            }
            // IVC << Ver.1.9 << end << [THRBOXV100-94]
            value = deviceAdapter.photoStyle
            target = targetForValue(deviceAdapter.photoStyle)

            loadObjects()
            // 2024/07 (既存) 内部サイズが変わった時の処理　start
            if (flickable.contentHeight < savedContentHeight){          // 内部エリアの高さが変わった？
                var sabun = savedContentHeight - flickable.contentHeight
                if (savedContentY > sabun){                             // 差分を引くとマイナス値か？
                    savedContentY = savedContentY - sabun
                } else {
                    savedContentY = 0
                }
            }
            // end
// IVC >> Ver.1.9 >> start >> [THRBOXV100-165]
            if(currentSelectedPhotoStyle === deviceAdapter.photoStyle) {
                flickable.contentY = savedContentY;
            } else {
                flickable.contentY = 0;
                savedContentY = 0;
                currentSelectedPhotoStyle = deviceAdapter.photoStyle;
            }
// IVC << Ver.1.9 << end << [THRBOXV100-165]
        }
    }

    function targetForValue(value) {
        switch (value) {
        case LT.Utilities.PS_Standard:
            return componentsProvider.standardCompName
        case LT.Utilities.PS_Vivid:
            return componentsProvider.vividCompName
        case LT.Utilities.PS_Natural:
            return componentsProvider.naturalCompName
        case LT.Utilities.PS_Monochrome:
            return componentsProvider.monoChromeCompName
        case LT.Utilities.PS_LMonochrome:
            return componentsProvider.lMonoChromeCompName
        case LT.Utilities.PS_LandScape:
            return componentsProvider.landScapeCompName
        case LT.Utilities.PS_Portrait:
            return componentsProvider.portraitCompName
        case LT.Utilities.PS_Custom:
            return componentsProvider.customCompName
        case LT.Utilities.PS_Custom2:
            return componentsProvider.custom2CompName
        case LT.Utilities.PS_Custom3:
            return componentsProvider.custom3CompName
        case LT.Utilities.PS_Custom4:
            return componentsProvider.custom4CompName
        case LT.Utilities.PS_CinelikeD:
            return componentsProvider.cinelikeDCompName
        case LT.Utilities.PS_CinelikeV:
            return componentsProvider.cinelikeVCompName
        case LT.Utilities.PS_Like_709:
            return componentsProvider.like709CompName
        case LT.Utilities.PS_Linear_Gamma:
            return componentsProvider.linearGammaCompName
        case LT.Utilities.PS_V_Log_L:
            return componentsProvider.vLogLCompName
        case LT.Utilities.PS_V_Log:
            return componentsProvider.vLogCompName
        // MC8259 start
        case LT.Utilities.PS_ARRI_LogC3:
            return componentsProvider.arriLogC3CompName
        // MC8259 end
        // MC5245, MC8245 start
        case LT.Utilities.PS_Remote_Camera_UE160:
            return componentsProvider.remoteCameraCompName
        // MC5245, MC8245 end
        // IVC >> MC893 >> start >> No.3
        case LT.Utilities.PS_CineLike_D2:
            return componentsProvider.cinelikeD2CompName
        case LT.Utilities.PS_CineLike_V2:
            return componentsProvider.cinelikeV2CompName
        // IVC << MC893 << end << No.3
        case LT.Utilities.PS_CineLike_A2:
            return componentsProvider.cinelikeA2CompName
        case LT.Utilities.PS_LMonochromeD:
            return componentsProvider.lMonoChromeDCompName
        // ivc >> start >> No.2
        case LT.Utilities.PS_Hybrid_Grama:
            return componentsProvider.hybridLogGammaCompName
        case LT.Utilities.PS_Flat:
            return componentsProvider.flatCompName
        case LT.Utilities.PS_PhotoStyle1:
            return componentsProvider.photoStyle1CompName
        case LT.Utilities.PS_PhotoStyle2:
            return componentsProvider.photoStyle2CompName
        case LT.Utilities.PS_PhotoStyle3:
            return componentsProvider.photoStyle3CompName
        case LT.Utilities.PS_PhotoStyle4:
            return componentsProvider.photoStyle4CompName
        case LT.Utilities.PS_PhotoStyle5:
            return componentsProvider.photoStyle5CompName
        case LT.Utilities.PS_PhotoStyle6:
            return componentsProvider.photoStyle6CompName
        case LT.Utilities.PS_PhotoStyle7:
            return componentsProvider.photoStyle7CompName
        case LT.Utilities.PS_PhotoStyle8:
            return componentsProvider.photoStyle8CompName
        case LT.Utilities.PS_PhotoStyle9:
            return componentsProvider.photoStyle9CompName
        case LT.Utilities.PS_PhotoStyle10:
            return componentsProvider.photoStyle10CompName
        // ivc << end << No.2
        // ivc >> start >> #9860
        case LT.Utilities.PS_HLG_Standard:
            return componentsProvider.hlgStandardCompName
        case LT.Utilities.PS_HLG_Monochrome:
            return componentsProvider.hlgMonochromeCompName
        // ivc << end << #9860
        case LT.Utilities.PS_HLG_For_G_Series:  // 2019/10/16 Panasonic Nakano
            return componentsProvider.hlgForGSeriesCompName
        //20秋FwUp
        case LT.Utilities.PS_LMonochromeS:
            return componentsProvider.lMonoChromeSCompName
        case LT.Utilities.PS_LClassicNeo:
            return componentsProvider.lClassicNeoCompName
        case LT.Utilities.PS_HLG_FullRange:
            return componentsProvider.hlgFullRangeCompName
        case LT.Utilities.PS_RealTime_LUT:
            return componentsProvider.realtimeLUTCompName
        case LT.Utilities.PS_Leica_Monochrome:
            return componentsProvider.leicaMonochromeCompName
        default:
            return ""
        }
    }

    /*!
        ポップアップを表示します
     */
    function present(x, y, vX, vY, popupTitle, targetValue) {
        deviceAdapter.adp_LMX_func_api_Rec_Ctrl_Backup_PhotoStyle_Req()

        lblHeader.text = popupTitle

        value = targetValue
        root.photoStyleSetting()

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

        root.width = popup.width
        root.height = popup.height

        visible = true
    }

    function loadObjects() {
        if (objects.length > 0) {
            root.clearObjects()
        }
// IVC >> Ver.1.9 >> start >> [THRBOXV100-165]
        isLoadObject = true;
// IVC << Ver.1.9 << end << [THRBOXV100-165]

        savedContentHeight = popupContent.height                // 2024/07 (既存) 現在の内部の高さ保存、サイズが変わればスクロールポイントを変更
        // ivc >> start >> No.2
        popupContent.height = 0
        flickable.height = contentHeight
        // ivc << end << No.2

        var components = componentsProvider[target]
        var capability = deviceAdapter["photoStyleCompCapability"]
//        var data = []

        for (var i = 0; i < components.length; i++) {
            if (capability(components[i].properties.value) != LT.DeviceAdapter.Ternary_True) {
                continue;
            }

            var obj = components[i].component.createObject(popupContent, components[i].properties)
            objects.push(obj)

            var compTarget = components[i].properties.target
            var curVal = deviceAdapter[compTarget]

            var child
            var j
            // sliderComponent
            if (obj.objectName === "sliderComponent" || obj.objectName === "sliderComponentPositive") {

                var maxVal = deviceAdapter[compTarget + "Max"]
                var minVal = deviceAdapter[compTarget + "Min"]
                var step = deviceAdapter[compTarget + "Step"]
                var changedSignal = deviceAdapter[compTarget + "Changed"]

                for (j = 0; j < obj.children.length; j++) {
                    child = obj.children[j]
                    if (child.objectName === "lblTitle") {
                        child.text = components[i].properties.text

                        if (components[i].properties.target === "pscDensity"){
                            // pscDensity の時 pscDensity2 が利用可能なら
                            if (deviceAdapter.pscDensity2Available() === true && target !== "psRealTimeLUT"){
                                child.text = qsTr("PSC_Density1")
                            }
                        }

                    } else if (child.objectName === "lblImg") {
                        child.source = components[i].properties.source

                        if (components[i].properties.target === "pscDensity"){
                            // pscDensity の時 pscDensity2 が利用可能なら
                            if (deviceAdapter.pscDensity2Available() === true && target !== "psRealTimeLUT"){
                                child.source = "qrc:/images/ps_lut1_concentration.svg"
                            }
                        }

                    } else if (child.objectName === "slider") {
                        child.target = components[i].properties.target
                        child.maxVal = maxVal()
                        child.minVal = minVal()
                        child.stepVal = step()

                        child.curValSetting(curVal)
                        changedSignal.connect(child.curValSetting)
//                        data.push({
//                                      target: child.target,
//                                      value: curVal,
//                                  })
                    }
                }
                // ivc >> start >> No.2
                popupContent.height += (obj.height + componentSpacing)
                // ivc << end << No.2

            // popupBtnComponent
            } else if (obj.objectName === "popupBtnComponent") {
                for (j = 0; j < obj.children.length; j++) {
                    child = obj.children[j]

                    if (child.objectName === "lblTitle") {
                        child.text = components[i].properties.text

                        if (components[i].properties.target === "pscLUT"){
                            // pscLUT の時 pscLUT2 が利用可能なら
                            if (deviceAdapter.pscLUT2Available() === true && target !== "psRealTimeLUT"){
                                child.text = qsTr("PSC_LUT1")
                            }
                        }

                    } else if (child.objectName === "lblImg") {
                        child.source = components[i].properties.source

                        if (components[i].properties.target === "pscLUT"){
                            // pscLUT の時 pscLUT2 が利用可能なら
                            if (deviceAdapter.pscLUT2Available() === true && target !== "psRealTimeLUT"){
                                child.source = "qrc:/images/ps_lut1.svg"
                            }
                        }

                    } else if (child.objectName === "btnOption") {
                        child.target = components[i].properties.target
                        child.componentsProvider = componentsProvider
                        child.popup = optionPopup

                        child.popupX = flickable.x + child.x + (child.width - 107)/2
                        child.popupY = flickable.y + child.y + (child.height - 36)/2

                        // ivc >> start >> No.2
                        componentsProvider.savePopupY = child.popupY
                        // ivc << end << No.2

                        child.optionSelect(curVal)

//                        data.push({
//                                      target: child.target,
//                                      value: curVal,
//                                  })
                    }
                }

                // ivc >> start >> No.2
                popupContent.height += (obj.height + componentSpacing)
                // ivc << end << No.2
            }
        }

        // Fill blank component
        for (i = objects.length; i < root.componentNum; i++) {
            var blankObj = Qt.createQmlObject("import QtQuick 2.6; Rectangle {width: 400; height: 77; color: \"#07090d\"}",
                                              popupContent, "blankComponent")
            objects.push(blankObj)
        }
    }

    function clearObjects() {
        var n = objects.length;
        for (var i = 0; i < n; ++i) {
            //  objects に格納されたオブジェクトを取出して破棄する
            var object = objects.pop();
            if(object.objectName === "sliderComponent"){
                var compTarget = null
                for (var j = 0; j < object.children.length; j++) {
                    var child = object.children[j]
                    if (child.objectName === "slider") {
                        compTarget = child.target
                        var changedSignal = deviceAdapter[compTarget + "Changed"]
                        changedSignal.disconnect(child.curValSetting)
                    }
                }
            }
            object.destroy();
        }
    }

    function ok() {
        deviceAdapter.adp_LMX_func_api_Rec_Ctrl_Del_Backup_Req()

        root.onOKClicked();
        root.dismiss();
    }

    function cancel() {
        deviceAdapter.adp_LMX_func_api_Rec_Ctrl_Restore_PhotoStyle_Req()
        deviceAdapter.adp_LMX_func_api_Rec_Ctrl_Del_Backup_Req()

        root.onCancelClicked();
        root.dismiss();
    }

    function forceClose(){
        deviceAdapter.adp_LMX_func_api_Rec_Ctrl_Del_Backup_Req()
        root.dismiss();
    }

    /*!
        ポップアップを隠します
     */
    function dismiss() {
        visible = false
        root.clearObjects()
    }

    /*!
        ポップアップに表示する，動的に生成したボタン

        \internal
     */
    property var objects: [ ]
//    property var bkData: [ ]
}
