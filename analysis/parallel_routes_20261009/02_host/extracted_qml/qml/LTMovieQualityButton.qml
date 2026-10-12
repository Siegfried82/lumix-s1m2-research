import QtQuick 2.6
import QtQuick.Controls 2.1
import Qt5Compat.GraphicalEffects

import "qrc:/qml"
import LT 1.0 as LT

/*! \qmltype LTMovieQualityButton
    \inqmlmodule LT

    \brief
    矩形のボタンです
 */
LTAbstractButton {
    id: root

    /*!
        デザインを制御する値です

        \table
        \header
            \li 値
            \li 説明
        \row
            \li \tt action
            \li 中央にラベルのテキストを表示します
        \row
            \li \tt optionDetailWithRow
            \li Display image-Pixel-FrameRate-CompressionMethod-VFR-HLG
        \row
            \li \tt optionDetailWithImagePopup
            \li 中央に状態を示す画像を，左上にラベルのテキストを表示します
        \endtable
     */
    property string type: "action"

    /*!
        状態を示す値です
     */
    property var value

    /*!
        ラベルのテキストです
     */
    property alias labelText: label.text

    /*!
        ボタンのテキストです
     */
    property alias buttonText: button.text

    /*!
        状態を示すテキストです
     */
    property alias optionText: option.text

    /*!
        状態を示すテキストです
     */
    property alias optionTextTooltip: root.toolTipText

    /*!
        For option image
     */

    property alias optionImage:                         optionImg.source
    property alias pixelText:                           lblPixel.text
    property alias fpsText:                             lblFps.text
    property alias compressMethodText:                  lblCompressMethod.text
    property alias bitrateText:                         lblBitrate.text
    property alias vfrText:                             lblVFR.text
    property alias hlgText:                             lblHLG.text
    // IVC >> Ver.1.8 >> start >> No.3
    property alias sqText:                              lblSQ.text
    // IVC << Ver.1.8 << end << No.3
    property alias pixelVisible:                        lblPixel.visible
    property alias fpsVisible:                          lblFps.visible
    property alias compressMethodVisible:               lblCompressMethod.visible
    property alias bitrateVisible:                      lblBitrate.visible
    property alias vfrVisbile:                          lblVFR.visible
    property alias hlgVisible:                          lblHLG.visible
    // IVC >> Ver.1.8 >> start >> No.3
    property alias sQVisible:                           lblSQ.visible
    // IVC << Ver.1.8 << end << No.3


    readonly property int option_string_top_margin:     30
    readonly property real imgageWidth:                 75
    readonly property real pixelWidth:                  75
    readonly property real fpsWidth:                    65
    readonly property real compressionWidth:            120
    readonly property real bitRateWidth:                60
    readonly property real vfrWidth:                    50
    readonly property real hlgWidth:                    65
    // IVC >> Ver.1.8 >> start >> No.3
    readonly property real sQWidth:                     65
    // IVC << Ver.1.8 << end << No.3
    /*!
        テキストの色です
     */
    property color textColor: {
        if (type == "optionDetailWithRow") {
              return enabled ? (checked ? "#000000" : "#dddddd") : "#646464";
        } else if ( type == "optionDetailWithTextPref" ) {
              return enabled ? (checked ? "#000000" : "#ffffff") : "#646464";
        } else {
              return enabled ? (checked ? "#ffbf1f" : "#dddddd") : "#646464";
        }
    }
    /*!
        フォントの属性です
     */
    property var fontLabel: {
        switch (type) {
        case "action":
            return {
                "pixelSize": 12,
                "weight": Font.Bold,
                "family": utilities.getFontFamily(),
            };
        case "optionDetailWithImagePopup":
            return {
                "pixelSize": 12,
                "family": utilities.getFontFamily(),
            };
        case "optionDetailWithTextPref":
            return {
                "pixelSize": 12,
                "family": utilities.getFontFamily(),
            };
        default:
            return {
                "pixelSize": 14,
                "family": utilities.getFontFamily(),
            };
        }
    }
    property var fontButton: {
        switch (type) {
        case "action":
            return {
                "pixelSize": 13,
                "weight": Font.Bold,
                "family": utilities.getFontFamily(),
            };
        case "optionDetailWithImagePopup":
            return {
                "pixelSize": 13,
                "family": utilities.getFontFamily(),
            };
        case "optionDetailWithTextPref":
            return {
                "pixelSize": 14,
            };
        default:
            return {
                "pixelSize": 14,
                "family": utilities.getFontFamily(),
            };
        }
    }
    property var fontOption: {
        switch (type) {
        case "action":
            return {
                "pixelSize": 13,
                "weight": Font.Bold,
                "family": utilities.getFontFamily(),
            };
        case "optionDetailWithImagePopup":
            return {
                "pixelSize": 13,
                "family": utilities.getFontFamily(),
            };
        case "optionDetailWithTextPref":
            return {
                "pixelSize": 14,
                "family": utilities.getFontFamily(),
            };
        default:
            return {
                "pixelSize": 14,
                "family": utilities.getFontFamily(),
            };
        }
    }
    onFontLabelChanged: {
        label.font = Qt.font(fontLabel)
    }
    onFontButtonChanged: {
        button.font = Qt.font(fontButton)
    }
    onFontOptionChanged: {
        option.font = Qt.font(fontOption)
    }

    /*!
        境界線の角を丸める半径です
     */
    property alias radius: rectangle.radius

    /*
        ラベルのテキスト
     */
    Text {
        id: label
        x: {
            switch (type) {
            case "optionDetailWithImagePopup":
                return 6;
            case "optionDetailWithTextPref":
                return 14;
            default:
                return 0;
            }
        }
        y: {
            switch (type) {
            case "optionDetailWithImagePopup":
                return 6;
            case "optionDetailWithTextPref":
                return parseInt((parent.height - label.height)/2)
            default:
                return 0;
            }
        }
        z: 30
        width: parent.width - x * 2
        color: textColor
        horizontalAlignment: {
            switch (type) {
            case "optionDetailWithImagePopup":
                return Text.AlignLeft
            case "optionDetailWithTextPref":
                return Text.AlignLeft
            default:
                return Text.AlignLeft
            }
        }
        verticalAlignment: {
            switch (type) {
            case "optionDetailWithImagePopup":
                return Text.AlignTop
            case "optionDetailWithTextPref":
                return Text.AlignVCenter
            default:
                return Text.AlignTop
            }
        }
        visible: {
            switch (type) {
            case "action":
                return false
            case "optionDetailWithImagePopup":
            case "optionDetailWithTextPref":
                return true
            default:
                return false
            }
        }
    }

    /*
        ボタンのテキスト
     */
    Text {
        id: button
        x: {
            switch (type) {
            case "action":
                return 0
            case "optionDetailWithImagePopup":
                return 6
            case "optionDetailWithTextPref":
                return 14
            default:
                return 0
            }
        }
        y: {
            switch (type) {
            case "action":
                return 0
            case "optionDetailWithImagePopup":
                return 6
            case "optionDetailWithTextPref":
                return 0
            default:
                return 0
            }
        }
        z: 30
        width: parent.width - x * 2
        height: parent.height - y * 2
        color: textColor
        horizontalAlignment: {
            switch (type) {
            case "action":
                return Text.AlignHCenter
            case "optionDetailWithImagePopup":
                return Text.AlignLeft
            case "optionDetailWithTextPref":
                return Text.AlignLeft
            default:
                return Text.AlignLeft
            }
        }
        verticalAlignment: {
            switch (type) {
            case "action":
                return Text.AlignVCenter
            case "optionDetailWithImagePopup":
                return Text.AlignTop
            case "optionDetailWithTextPref":
                return Text.AlignVCenter
            default:
                return Text.AlignTop
            }
        }
        visible: {
            switch (type) {
            case "action":
                return true
            case "optionDetailWithImagePopup":
            case "optionDetailWithTextPref":
                return false
            default:
                return false
            }
        }
    }

    /*
        状態を示すテキスト
     */
    Text {
        id: option
        visible: ( (type == "optionDetailWithTextPref")
                 || ((type == "optionDetailWithImagePopup") && (source == "")) )
                && (type != "optionDetailWithRow")
        x: 14
        y: {
            if(type == "optionDetailWithImagePopup") {
                return 10
            } else {
                return 0
            }
        }
        z: 30
        width: parent.width - x * 2
        height: parent.height
        color: textColor
        horizontalAlignment: {
            switch (type) {
            case "optionDetailWithImagePopup":
                return Text.AlignHCenter
            default:
                return Text.AlignRight
            }
        }
        verticalAlignment: Text.AlignVCenter
        textFormat: {
            return Text.AutoText
        }
    }

    Image {
        id: optionImg
        fillMode: Image.PreserveAspectFit
        anchors {
            verticalCenter: parent.verticalCenter
            leftMargin: 6
        }
        x: 6
        y: 36
        z: 20
        height: parent.height
        source: "qrc:/images/button_placeholder.svg"
        visible: (type == "optionDetailWithRow")
    }
    Image {
        id: optionDisableImg
        fillMode: optionImg.fillMode
        x: optionImg.x
        y: optionImg.y
        z: optionImg.z
        height: optionImg.height
        width: optionImg.width
        visible: false
    }
    Image {
        id: optionCheckedImg
        fillMode: optionImg.fillMode
        x: optionImg.x
        y: optionImg.y
        z: optionImg.z
        height: optionImg.height
        width: optionImg.width
        visible: false
    }
    Row { /* inner row */
        id: detailRow
        anchors {
            fill: parent
        }
        x: 2
        z: 20
        spacing : 1
        visible: (type == "optionDetailWithRow")
        Rectangle {
            x: 2
            z: 20
            width: imgageWidth
            height: parent.height
            color: "transparent"
        }
        // IVC >> Ver.1.9 >> start >> [THRBOXV100-152]
        //Text {
        LTStylishText {
        // IVC << Ver.1.9 << end << [THRBOXV100-152]
            id: lblPixel
            z: 30
            visible: false

            width: pixelWidth
            height: parent.height
            color: textColor
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            textFormat: Text.AutoText
            // IVC >> Ver.1.9 >> start >> [THRBOXV100-152]
            type: text_style_MovieQualityButton
            // IVC << Ver.1.9 << end << [THRBOXV100-152]
        }
        // IVC >> Ver.1.9 >> start >> [THRBOXV100-152]
        //Text {
        LTStylishText {
        // IVC << Ver.1.9 << end << [THRBOXV100-152]
            id: lblFps
            z: 30
            visible: false
            width: fpsWidth
            height: parent.height
            color: textColor
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            textFormat: Text.AutoText
            // IVC >> Ver.1.9 >> start >> [THRBOXV100-152]
            type: text_style_MovieQualityButton
            // IVC << Ver.1.9 << end << [THRBOXV100-152]
        }
        // IVC >> Ver.1.9 >> start >> [THRBOXV100-152]
        //Text {
        LTStylishText {
        // IVC << Ver.1.9 << end << [THRBOXV100-152]
            id: lblCompressMethod
            z: 30
            visible: false
            width: compressionWidth
            height: parent.height
            color: textColor
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            textFormat: Text.AutoText
            // IVC >> Ver.1.9 >> start >> [THRBOXV100-152]
            type: text_style_MovieQualityButton
            // IVC << Ver.1.9 << end << [THRBOXV100-152]
        }
        // IVC >> Ver.1.9 >> start >> [THRBOXV100-152]
        //Text {
        LTStylishText {
        // IVC << Ver.1.9 << end << [THRBOXV100-152]
            id: lblBitrate
            z: 30
            visible: false
            width: bitRateWidth
            height: parent.height
            color: textColor
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            textFormat: Text.AutoText
            // IVC >> Ver.1.9 >> start >> [THRBOXV100-152]
            type: text_style_MovieQualityButton
            // IVC << Ver.1.9 << end << [THRBOXV100-152]
        }
        // IVC >> Ver.1.9 >> start >> [THRBOXV100-152]
        //Text {
        LTStylishText {
        // IVC << Ver.1.9 << end << [THRBOXV100-152]
            id: lblVFR
            z: 30
            visible: false
            width: vfrWidth
            height: parent.height
            color: textColor
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            textFormat: Text.AutoText
            // IVC >> Ver.1.9 >> start >> [THRBOXV100-152]
            type: text_style_MovieQualityButton
            // IVC << Ver.1.9 << end << [THRBOXV100-152]
        }
        // IVC >> Ver.1.9 >> start >> [THRBOXV100-152]
        //Text {
        LTStylishText {
        // IVC << Ver.1.9 << end << [THRBOXV100-152]
            id: lblHLG
            z: 40
            visible: false
            width: hlgWidth
            height: parent.height
            color: textColor
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            textFormat: Text.AutoText
            wrapMode: Text.Wrap
            // IVC >> Ver.1.9 >> start >> [THRBOXV100-152]
            type: text_style_MovieQualityButton
            // IVC << Ver.1.9 << end << [THRBOXV100-152]
        }
        // IVC >> Ver.1.8 >> start >> No.3
        // IVC >> Ver.1.9 >> start >> [THRBOXV100-152]
        //Text {
        LTStylishText {
        // IVC << Ver.1.9 << end << [THRBOXV100-152]
            id: lblSQ
            z: 40
            visible: false
            width: sQWidth
            height: parent.height
            color: textColor
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            textFormat: Text.AutoText
            wrapMode: Text.Wrap
            // IVC >> Ver.1.9 >> start >> [THRBOXV100-152]
            type: text_style_MovieQualityButton
            // IVC << Ver.1.9 << end << [THRBOXV100-152]
        }
        // IVC << Ver.1.8 << end << No.3
    }
    /*
        境界線と背景ぬりつぶし
     */
    Rectangle {
        id: rectangle
        z: 10
        implicitWidth: parent.width
        implicitHeight: root.height
        color: fillColor
        border {
            width: strokeWidth
            color: strokeColor
        }
        radius: 0
    }
    /*
        マウス操作領域
     */
    MouseArea {
        id: mouseArea
        z: 50
        anchors {
            fill: parent
        }
        hoverEnabled: true
        onClicked:(mouse)=> {
            root.clicked(mouse, root)
        }
        onPressAndHold:(mouse)=>{ root.pressAndHold(mouse, root) }
        onEntered: {
            root.entered();
        }
        onExited: {
            root.exited();
        }
        onCanceled: {
            root.canceled();
        }
        onPressed:(mouse)=> {
            root.pressed(mouse, root);
        }
        onReleased: {
            root.released(0);
        }
    }

    /*
        ボタンが選択状態、ボタンが無効状態のSVG描画カスタマイズ
     */
    onSourceChanged: {
        //OpenGLの場合は動作しないようにする
        if( isOpenGLMode === "true" ){
            return
        }
        setDisableImg()

        visibleCheck()
    }

    onEnabledChanged: {
        //OpenGLの場合は動作しないようにする
        if( isOpenGLMode === "true" ){
            return
        }
        setDisableImg()

        visibleCheck()
    }

    onCheckedChanged: {
        //OpenGLの場合は動作しないようにする
        if( isOpenGLMode === "true" ){
            return
        }
        setDisableImg()

        visibleCheck()
    }

    function setDisableImg()
    {
        //OpenGLの場合は動作しないようにする
        if( isOpenGLMode === "true" ){
            return
        }
        //輝度変更してDisable用のイメージを作成
        if( mainDisableImg.source != "image://brightnessChg/" + mainImg.source + "?y=140" &&
            mainImg.source.toLocaleString() )
        {
            mainDisableImg.source = "image://brightnessChg/" + mainImg.source + "?y=140"
        }
        //輝度変更してChecked用のイメージを作成
        if( mainCheckedImg.source != "image://brightnessChg/" + mainImg.source + "?y=0" &&
            mainImg.source.toLocaleString() )
        {
            mainCheckedImg.source = "image://brightnessChg/" + mainImg.source + "?y=0"
        }
        //輝度変更してDisable用のイメージを作成
        if( optionDisableImg.source != "image://brightnessChg/" + optionImg.source + "?y=140" &&
            optionImg.source.toLocaleString() )
        {
            optionDisableImg.source = "image://brightnessChg/" + optionImg.source + "?y=140"
        }
        //輝度変更してChecked用のイメージを作成
        if( optionCheckedImg.source != "image://brightnessChg/" + optionImg.source + "?y=0" &&
            optionImg.source.toLocaleString() )
        {
            optionCheckedImg.source = "image://brightnessChg/" + optionImg.source + "?y=0"
        }
    }

    function visibleCheck()
    {
        //OpenGLの場合は動作しないようにする
        if( isOpenGLMode === "true" ){
            return
        }
        //表示状態を管理
        var mainEffect = false
        var optionEffect = false
        //mainImg
        if(type == "optionDetailWithImagePopup" || type == "optionDetailWithRow") {
            if(!enabled) {
                mainEffect = true
            }else{
                mainEffect = checked
            }
        } else if ( type == "action") {
            if(!enabled) {
                mainEffect = true
            } else {
                mainEffect = false
            }
        }
        if(type == "optionDetailWithImagePopup" || type == "optionDetailWithRow" || type == "action") {
            if( mainEffect == true ){
                if( enabled === false){
                    //無効状態
                    mainImg.visible = false

                    mainDisableImg.visible = true
                    mainCheckedImg.visible = false
                }else{
                    //チェック状態
                    mainImg.visible = false

                    mainDisableImg.visible = false
                    mainCheckedImg.visible = true
                }
            }else{
                //通常
                mainImg.visible = true

                mainDisableImg.visible = false
                mainCheckedImg.visible = false
            }
        }else{
            //イメージの表示しないtype
            mainImg.visible = false

            mainDisableImg.visible = false
            mainCheckedImg.visible = false
        }

        //optionImg
        if(type == "optionDetailWithRow") {
            if(!enabled) {
                optionEffect = true
            }else{
                optionEffect = checked
            }

            if( optionEffect == true ){
                if( enabled === false){
                    //無効状態
                    optionImg.visible = false

                    optionDisableImg.visible = true
                    optionCheckedImg.visible = false
                }else{
                    //チェック状態
                    optionImg.visible = false

                    optionDisableImg.visible = false
                    optionCheckedImg.visible = true
                }
            }else{
                //通常
                optionImg.visible = true

                optionDisableImg.visible = false
                optionCheckedImg.visible = false
            }
        }else{
            //イメージの表示しないtype
            optionImg.visible = false

            optionDisableImg.visible = false
            optionCheckedImg.visible = false
        }
    }

    BrightnessContrast {
        z: 30
        anchors.fill: mainImg
        source: mainImg
        brightness: {
            if(!enabled) {
                return -0.3
            }
            return -1
        }
        contrast: 0
        visible: {
            //OpenGL以外の場合は表示しないようにする
            if( isOpenGLMode === "false" ){
                return false
            }
            if(type == "optionDetailWithImagePopup" || type == "optionDetailWithRow") {
                if(!enabled) {
                    mainImg.visible = false
                    return true
                }
                mainImg.visible = !checked
                return checked
            } else if ( type == "action") {
                if(!enabled) {
                    mainImg.visible = false
                    return true
                } else {
                    mainImg.visible = true
                    return false
                }
            }
            return false
        }
    }
    BrightnessContrast {
        z: 30
        anchors.fill: optionImg
        source: optionImg
        brightness: {
            if(!enabled) {
                return -0.3
            }
            return -1
        }
        contrast: 0
        visible: {
            //OpenGL以外の場合は表示しないようにする
            if( isOpenGLMode === "false" ){
                return false
            }
            if(type == "optionDetailWithRow") {
                if(!enabled) {
                    optionImg.visible = false
                    return true
                }
                optionImg.visible = !checked
                return checked
            }
            return false
        }
    }
    /*!
        チェック状態の背景色
     */
    checkedColor: "#ffbf1f"

    /*!
        Setting for log record
     */
    property LTLogCollector logCol

    property int logLevel: LT.TagDef.RecLvl_Info
    property int logScrTagID
    property string logFile: ""
    property string logText: ""
    property bool logEnable: true

    onClicked: {
        //log record
        if (logCol && logEnable) {
            logCol.log(logLevel, logScrTagID, logFile + " clicked", logText)
        }
    }

// IVC >> Ver.1.8 >> start >> No.3
    //function showDetail(pixel, fps, compresion, bitrate, vfr, hlg) {
    function showDetail(pixel, fps, compresion, bitrate, vfr, hlg, sq) {
// IVC << Ver.1.8 << end << No.3
        var width = imgageWidth + 13
        if (pixel) {
            lblPixel.visible = pixel
            width += pixelWidth
        }
        if (fps) {
            lblFps.visible = fps
            width += hlgWidth
        }
        if (compresion) {
            lblCompressMethod.visible = compresion
            width += compressionWidth
        }
        if (bitrate) {
            lblBitrate.visible = bitrate
            width += bitRateWidth
        }
        if (vfr) {
            lblVFR.visible = vfr
            width += vfrWidth
        }
        if (hlg) {
            lblHLG.visible = hlg
            width += hlgWidth
        }
        // IVC >> Ver.1.8 >> start >> No.3
        if (sq) {
            lblSQ.visible = sq
            width += sQWidth
        }
        // IVC << Ver.1.8 << end << No.3
        rectangle.width = width
        root.width = rectangle.width
    }
}
