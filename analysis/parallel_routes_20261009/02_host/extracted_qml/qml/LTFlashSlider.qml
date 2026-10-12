import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0

import LT 1.0 as LT

// Minimal slider implementation
Item {
    id: root

    Accessible.role: Accessible.Slider

    /*
        Label text
     */
    property alias optionText: label.text

    /*
        Text color for label and value
     */
    property color textColor: palette.textColor

    readonly property var palette: {
        "defaultColor": "#525356",
        "selectedColor": "#FFD600",
        "textColor": "#808080",
    }

    /*
        Tickmark width
     */
    readonly property int tmWidth: 3

    property int tmStep: 3

    // max value for free style
    property real maxVal: 0
    onMaxValChanged: {
        //reset indicator
        indicator.model = 0
        indicator.model = (maxVal - minVal) + 1
    }

    // min value for free style
    property real minVal: 0
    onMinValChanged: {
        //reset indicator
        indicator.model = 0
        indicator.model = (maxVal - minVal) + 1
    }

    // step value for free style
    property real stepVal: 3
    onStepValChanged: {
        tmStep = stepVal
        //reset indicator
        indicator.model = 0
        indicator.model = (maxVal - minVal) + 1
    }

    // current index value for free style
    property real curVal: 0.0
    onCurValChanged: {
        curIndex = (curVal - minVal)
    }
    function curValSetting(val) {
        if (curVal === undefined){
            return                      // 不正なCall 対策
        }
        if (curVal !== val) {
            curVal = val
        }
        curIndex = (curVal - minVal)
    }

    /*!
        Slider type

        \table
        \header
            \li 値
            \li 説明
        \row
            \li \tt ev
            \li Normal type for EV with step 1/3
        \row
            \li \tt manual
            \li Special type for flash manual from 1/128 to 1/1 in flash window
        \row
            \li \tt exposure
            \li Special type for exposure in main window.
        \row
            \li \tt adjust
            \li Special type for flash adjust in flash window
        \endtable
     */
    readonly property int slider_type_adjust:   0
    readonly property int slider_type_manual:   1
    readonly property int slider_type_exposure: 2
    readonly property int slider_type_free:     3
    property int type: slider_type_adjust

    // 2019/01/07 Panasonic Nakano
    readonly property int slider_texttype_fraction: 0   // 分数表示
    readonly property int slider_texttype_decimals: 1   // 少数表示
    readonly property int slider_texttype_positive: 2   // 正数表示 MC8259 tsutsumi 追加
    property int texttype: slider_texttype_fraction     // デフォルトは分数表示

    /*!
        Slider window type

        \table
        \header
            \li 値
            \li 説明
        \row
            \li \tt flash
            \li For flash window
        \row
            \li \tt main
            \li For main window
        \row
            \li \tt flashPopup
            \li For flash popup
        \endtable
     */
    readonly property int slider_window_flash:      0
    readonly property int slider_window_flashPopup: 1
    readonly property int slider_window_main:       2
    readonly property int slider_window_photoStyle: 3
    property int windowType: slider_window_flash
    onWindowTypeChanged: {
        if (windowType == slider_window_flashPopup) {
            root.state = "popup"
        } else if (windowType == slider_window_photoStyle) {
            root.state = "lbl_image"
        } else {
            root.state = "normal"
        }
    }

    property string target: ""

    /*
        Current step value
     */
    property alias curIndex: indicator.currentIndex
    onCurIndexChanged: {
        setIndexToPos(curIndex);
        //console.log("onCurIndexChanged curIndex:", curIndex)
    }

    /*
        API value
     */
    property int value: -1
    function sliderValueChanged(val) {
        value = val
        if (windowType == slider_window_main) {
            deviceAdapter[target] = val;
            //console.log("sliderValueChanged slider_window_main", val)
        } else if (windowType == slider_window_flash) {
            flashAdapter[target] = val;
            //console.log("sliderValueChanged slider_window_flash", val)
        } else if (windowType == slider_window_flashPopup){
            //do nothing
        } else if (windowType == slider_window_photoStyle){
            var ret = val + minVal
            ret = (ret < minVal) ? minVal : ret
            ret = (ret > maxVal) ? maxVal : ret
            deviceAdapter[target] = ret;
            //console.log("sliderValueChanged slider_window_photoStyle", ret)
        }
    }


    /*
        Root slide step
     */
    property int rootIndex: {
        var idx;	// 2019/10/31 Panasonic Kashihara
        var tmpVal;

        switch (type) {
        case slider_type_manual:
            return modelNum-1;

        case slider_type_free:
        case slider_type_exposure:
        case slider_type_adjust:
        default:
            // MC8259 tsutsumi 追加
            if (minVal > 0){                    // 0が存在しないとき　無条件をRootを0にする
                return 0;
            }
        	// 2019/10/31 Panasonic Kashihara
            if ((minVal != maxVal) && (stepVal > 0)) {
                // 値が0になる場所を探す
                for (idx = 0; idx < modelNum; idx++) {
                    tmpVal = minVal + idx;
                    if (tmpVal == 0) {
                        return idx;
                    }
                }
            }
//          そのため、やむを得ず↓の方法で一旦対応   // 2019/05/23 Panasonic Nakano
//			2019/10/31 恐らく通らないが、念のため残す。 
            if (minVal == 0 && maxVal > 0) {
                return 0;
            }
            return (modelNum-1)/2;
        }
    }

    /*
        Minimum slide range
     */
    property int minRange: 0

    /*
        Maximum slide range
     */
    property int maxRange: modelNum-1

    /*
        List tickmark objects
     */
//    property var stepList: indicator.view.children

    /*
        Number of step model
     */
    property int modelNum: {
        switch (type) {
        case slider_type_manual:
            return LT.Utilities.FlshManual_Max;

        case slider_type_exposure:
            return LT.Utilities.Expo_Max;

        case slider_type_free:
            return (maxVal - minVal)/stepVal + 1

        case slider_type_adjust:
        default:
            return LT.Utilities.FlshAdj_Max;
        }
    }

    // スライダー値のTOPマージンを追加できるようにしておく
    // フォトスタイルポップアップで使用
    property int txtSliderValTopMargin: 0

    /*
        Convert slide value to display text
     */
    function textValue(index) {
        var txtValue = ""
        var val = index
        var rem
        var div
        var txtSig
        var txtDiv
        var txtRem

        if (type == slider_type_free) {
            var realVal = val + minVal

            if (realVal == 0) {
                return "0";
            }

            if (texttype == slider_texttype_fraction) { // 2019/01/07 Panasonic Nakano
                rem = realVal%stepVal;
                div = Math.abs((realVal-rem)/stepVal);
                rem = Math.abs(rem);

                txtSig = (realVal < 0) ? "-" : (realVal > 0) ? "+" : "";
                txtDiv = (div != 0 ? txtSig + div + " " : txtSig);
                txtRem = (rem != 0 ? "<sup>"+rem+"</sup>&frasl;<sub>"+stepVal+"</sub>" : "");

                txtValue = txtDiv + txtRem;
            } else if (texttype == slider_texttype_positive) {
// とりあえず符号なし-値そのまま
                txtSig = "%";
                txtValue = realVal * 10 + txtSig;
//                console.debug("slider RealVal ", realVal ," ", stepVal)
            } else {  // 2019/01/07 Panasonic Nakano
                // 少数表示の場合
                txtSig = (realVal < 0) ? "-" : (realVal > 0) ? "+" : "";
                txtValue = txtSig + (Math.floor((Math.abs(realVal) / stepVal) * 10) / 10);  // 小数点以下2桁目以降切り捨て
            }
        } else if (type == slider_type_manual) {
            val = utilities.enumFlashManualToVal(index);
            if (val == 0) {
                return "<sup>1</sup>&frasl;<sub>1</sub>";
            }
            txtValue = "<sup>1</sup>&frasl;<sub>"+(val/10)+"</sub>";
        } else {
            if (type == slider_type_exposure) {
                val = hexToDec(utilities.enumExposureToVal(index));
            } else if (type == slider_type_adjust) {
                val = hexToDec(utilities.enumFlashAdjToVal(index));
            }

            if (val == 0) {
                return "0 EV";
            }

            rem = val%3;
            div = Math.abs((val-rem)/3);
            rem = Math.abs(rem);

            txtSig = (val < 0) ? "-" : (val > 0) ? "+" : "";
            txtDiv = (div != 0 ? txtSig + div + " " : txtSig);
            txtRem = (rem != 0 ? "<sup>"+rem+"</sup>&frasl;<sub>3</sub> " : "");

            txtValue = txtDiv + txtRem + "EV";
        }

        return txtValue;
    }

    /*
        Check the tickmark color
     */
    function tmColor(stepIndex) {
        if(!root.enabled)
            return "#808080"

        if (stepIndex == rootIndex || stepIndex == curIndex) {
            return palette.selectedColor;
        }

        if (stepIndex > rootIndex) {
            return stepIndex > curIndex ? palette.defaultColor : palette.selectedColor;
        }

        return stepIndex < curIndex ? palette.defaultColor : palette.selectedColor;
    }

    /*
        Calculate tichmark spacing
     */
    function stepSpacing() {
        return indicator.width/(modelNum-1);
    }

    function hexToDec(hexVal) {
        var sig = (hexVal >> 15) ? -1 : 1;
        var ret = sig * (hexVal & ~(1 << 15));

        return ret;
    }

    function tmEnabled(stepIndex) {
        return (minRange <= stepIndex && stepIndex <= maxRange);
    }

    function setHandlePosition(stepIndex) {
        var item = indicator.currentItem;

        var handlePoint;
        var maxPoint;
        if (stepIndex == 0) {
            handlePoint = item.mapToItem(slider, 0, 5);
            //console.log("setHandlePosition handlePoint1.x:", handlePoint.x)
        } else if (stepIndex == modelNum-1) {
            handlePoint = item.mapToItem(slider, item.width, 5);
            //console.log("setHandlePosition handlePoint2.x:", handlePoint.x)
        } else {
            handlePoint = item.mapToItem(slider, item.width/2, 5);
            //console.log("setHandlePosition handlePoint3.x:", handlePoint.x)
        }

        handle.x = handlePoint.x-handle.width/2;
        //console.log("setHandlePosition handle.x", handle.x)
        //console.log("setHandlePosition indicator.x", indicator.x)
        //console.log("setHandlePosition indicator.width", indicator.width)
        //console.log("setHandlePosition handle.width", handle.width)
        if(Math.abs(handle.x + handle.width/2 - indicator.x - indicator.width) <= handle.width) {
            indicator.currentIndex = maxRange
        }
    }

    function setIndexToPos(stepIndex) {
        var per = stepIndex/(modelNum-1);
        var point = indicator.mapToItem(slider, indicator.width*per, 0);

        handle.x = point.x-handle.width/2;
    }

    Component.onCompleted: {
        curIndex = rootIndex;

        //Calculate handle position (using percentage, not 100% accurately)
        setIndexToPos(curIndex);
    }

    Item {
        id: labelPanel
        anchors {
            top: parent.top
            left: parent.left
        }
        height: parent.height/2
        width: parent.width/2 - 6

        LTStylishText {
            id: label
            color: (root.enabled? "#FFFFFF": "#808080")

            anchors {
                fill:parent
                margins: 6
            }

            type: text_style_sliderTitle

            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignTop
        }
    }

    Item {
        id:sliderValuePanel

        anchors {
            top: parent.top
            right: parent.right
        }
        height: parent.height/2
        width: parent.width/2 - 6

        LTStylishText {
            id: txtSliderValue
            color: (root.enabled? "#FFFFFF": "#808080")

            anchors {
                fill:parent
                topMargin:{
                    if( isOpenGLMode === "false" ){
                        return -6 + txtSliderValTopMargin
                    }else{
                        return 6 + txtSliderValTopMargin
                    }
                }
                rightMargin: 6
                bottomMargin:{
                    if( isOpenGLMode === "false" ){
                        return -6
                    }else{
                        return 0
                    }
                }
            }
            verticalAlignment: {
                if( isOpenGLMode === "false" ){
                    return Text.AlignVCenter
                }else{
                    return Text.AlignTop
                }
            }

            textFormat:Text.RichText
            text: textValue(indicator.currentIndex)
            type:text_style_sliderValue

            Connections {
                target: indicator
                function onCurrentIndexChanged() {
                    txtSliderValue.text = textValue(indicator.currentIndex);
                }
            }

            PropertyAnimation {
                properties: "text"
                duration: 100
            }
        }
    }

    Item {
        id: slider

        anchors {
            top: sliderValuePanel.bottom

            left: parent.left
            right: parent.right
        }
        height: parent.height/2

        ListView {
            id: indicator

            x: 12
            y: 6
            height: parent.height - y
            width: parent.width - x*2

            spacing: 0

            orientation: ListView.Horizontal
            layoutDirection: Qt.LeftToRight

            interactive: false

            model: modelNum
            delegate: Item {
                id: delegateRoot

                width: {
                    if (index == 0 || index == modelNum-1) {
                        return stepSpacing()/2;
                    } else {
                        return stepSpacing();
                    }
                }
                height: indicator.height

                Rectangle {
                    id: recTm

                    x: {
                        if (index == 0) {
                            return -tmWidth/2;
                        } else if (index == modelNum-1) {
                            return parent.width-tmWidth/2;
                        } else {
                            return (parent.width-tmWidth)/2;
                        }
                    }
                    y: {
                        if (type == slider_type_free && tmStep == 1) {
                            return (index == 0 || index == modelNum - 1 || index == rootIndex) ? 0 : 5
                        }
                        return !(index % tmStep) ? 0 : 5
                    }


                    width: tmWidth
                    height: {
                        if (type == slider_type_free && tmStep == 1) {
                            return (index == 0 || index == modelNum - 1 || index == rootIndex) ? 10 : 5
                        }
                        return !(index % tmStep) ? 10 : 5
                    }

                    color: tmColor(index)

                    visible: tmEnabled(index)

                    Connections{
                        target: indicator
                        function onCurrentIndexChanged() {
                            color: tmColor(index)
                        }
                    }

                    ColorAnimation on color {
                        duration: 50
                    }
                }

                MouseArea {
                    id: delegateMsArea

                    enabled: tmEnabled(index)

                    anchors {
//                        top: parent.top
                        bottom: parent.bottom
                        left: {(index == 0) ? undefined : parent.left}
                        right: {(index == modelNum - 1) ? undefined : parent.right}
                    }
                    width: {
                        ((index == 0) || (index == modelNum - 1)) ? parent.width*2 : parent.width
                    }
                    height: parent.height + 6

                    onPressed: {
                        curIndex = index
                        sliderValueChanged(index)
                    }
                }

                DropArea {
                    id: delegateDropArea

                    anchors {
                        top: recTm.bottom
                        right: parent.right
                        left: parent.left
                        bottom: parent.bottom
                    }

                    onEntered: {
                        //console.log("onEntered", index)
                        curIndex = index;
                    }

                    onDropped: {
                        //console.log("delegateDropArea onDropped setHandlePosition:", index , " curIndex:" + curIndex)
                        if(curIndex != index) {
                            curIndex = index;
                            setHandlePosition(index);

                            sliderValueChanged(index)
                        }
                    }
                }
            }
        }

        Rectangle {
            id: handle

            property real preX

            y: 10 + indicator.y
            width: 8
            height: 10

            color: "transparent"

            Drag.active: handleMsArea.drag.active
            Drag.source: handleMsArea
            Drag.hotSpot.x: handle.width/2
            Drag.hotSpot.y: 0

            //handle drawing
            Canvas {
                id: canvas

                anchors {
                    fill:parent
                }

                onPaint: {
                    var ctx = canvas.getContext("2d");

                    ctx.save();
                    ctx.globalAlpha = canvas.alpha;

                    ctx.beginPath();
                    ctx.moveTo(1,10);
                    ctx.lineTo(1,6);
                    ctx.lineTo(4,0);
                    ctx.lineTo(7,6);
                    ctx.lineTo(7,10);
                    ctx.lineTo(1,10);
                    ctx.closePath();

                    ctx.fillStyle = (root.enabled ? palette.selectedColor: "#808080");
                    ctx.fill();

                    ctx.restore();
                }
            }

            MouseArea {
                id: handleMsArea

                anchors.fill: parent

                drag{
                    target: parent
                    axis: Drag.XAxis
                    minimumX: {
                        var adjust = minRange/(modelNum-1)*indicator.width;
                        return (indicator.x-tmWidth)+adjust;
                    }
                    maximumX: {
                        var adjust = ((modelNum-1)-maxRange)/(modelNum-1)*indicator.width+1;
                        return indicator.x+indicator.width-tmWidth-adjust;
                    }
                }

                onReleased: {
                    //console.log("handleMsArea onReleased:", indicator.currentIndex)
                    setHandlePosition(indicator.currentIndex);

                    sliderValueChanged(indicator.currentIndex);
                    parent.Drag.drop()
                }
            }

        }
    }

    onEnabledChanged: {
        canvas.requestPaint()
    }

    states: [
        State {
            name: "popup"

            AnchorChanges {
                target: labelPanel
                anchors.right: parent.right
            }

            AnchorChanges {
                target: sliderValuePanel
                anchors.top: labelPanel.bottom
                anchors.left: parent.left
            }

            PropertyChanges {
                target: labelPanel
                height: parent.height/4
                width: parent.width
            }

            PropertyChanges {
                target: sliderValuePanel
                height: parent.height/4
                width: parent.width
            }

            PropertyChanges {
                target: txtSliderValue
                type: text_style_sliderVal_pu
            }
        },
        State {
            name: "lbl_image"

            AnchorChanges {
                target: labelPanel
                anchors.right: parent.right
            }

            AnchorChanges {
                target: sliderValuePanel
                anchors.top: labelPanel.bottom
                anchors.left: parent.left
            }

            PropertyChanges {
                target: labelPanel
                height: 0
                width: 0
            }

            PropertyChanges {
                target: sliderValuePanel
                height: parent.height/2 + 6
                width: parent.width
            }

            PropertyChanges {
                target: txtSliderValue
                type: text_style_sliderVal_ps
                anchors.rightMargin: 0
            }

            PropertyChanges {
                target: slider
                height: parent.height - sliderValuePanel.height
            }
        }
    ]
}
