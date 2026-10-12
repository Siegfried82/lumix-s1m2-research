import QtQuick 2.6

import "qrc:/qml"
import LT 1.0 as LT

/*! \qmltype LTOptionComponentsProvider
    \inqmlmodule LT

    \brief
    LTOptionButtonPopup に表示するコンポーネントの組を提供するオブジェクトです
 */
QtObject {
    /*!
        buildInFlashAdjust を選択する LTFlashSliderPopup に表示するコンポーネントの組です
     */
    readonly property var buildInFlashAdjust: [
        {
            component: optionWithSliderComponent,
            properties: {
                type: 0,
                windowType: 1,
                optionText: qsTr("Flash Light Adjustment"),
                target: "buildInFlashAdjust"
            }
        }
    ]

    /*!	//  USBTHRV140-97 >>
        buildInFlashManual を選択する LTFlashSliderPopup に表示するコンポーネントの組です	
     */
    readonly property var buildInFlashManual: [
        {
            component: optionWithSliderComponent,
            properties: {
                type: 1,
                windowType: 1,
                optionText: qsTr("Flash Light Manual"),
                target: "buildInFlashManual"
            }
        }
    ]	// << USBTHRV140-97

    /*!
        aGroupFlashAdjust を選択する LTFlashSliderPopup に表示するコンポーネントの組です
     */
    readonly property var aGroupFlashAdjust: [
        {
            component: optionWithSliderComponent,
            properties: {
                type: 0,
                windowType: 1,
                optionText: qsTr("Flash Light Adjustment"),
                target: "aGroupFlashAdjust"
            }
        }
    ]

    /*!	// (USBTHRV140-97, 参照元) >>
        aGroupFlashManual を選択する LTFlashSliderPopup に表示するコンポーネントの組です
     */
    readonly property var aGroupFlashManual: [
        {
            component: optionWithSliderComponent,
            properties: {
                type: 1,
                windowType: 1,
                optionText: qsTr("Flash Light Manual"),
                target: "aGroupFlashManual"
            }
        }
    ]	// << (USBTHRV140-97, 参照元)

    /*!
        bGroupFlashAdjust を選択する LTFlashSliderPopup に表示するコンポーネントの組です
     */
    readonly property var bGroupFlashAdjust: [
        {
            component: optionWithSliderComponent,
            properties: {
                type: 0,
                windowType: 1,
                optionText: qsTr("Flash Light Adjustment"),
                target: "bGroupFlashAdjust"
            }
        }
    ]

    /*!
        bGroupFlashManual を選択する LTFlashSliderPopup に表示するコンポーネントの組です
     */
    readonly property var bGroupFlashManual: [
        {
            component: optionWithSliderComponent,
            properties: {
                type: 1,
                windowType: 1,
                optionText: qsTr("Flash Light Manual"),
                target: "bGroupFlashManual"
            }
        }
    ]

    /*!
        cGroupFlashAdjust を選択する LTFlashSliderPopup に表示するコンポーネントの組です
     */
    readonly property var cGroupFlashAdjust: [
        {
            component: optionWithSliderComponent,
            properties: {
                type: 0,
                windowType: 1,
                optionText: qsTr("Flash Light Adjustment"),
                target: "cGroupFlashAdjust"
            }
        }
    ]

    /*!
        cGroupFlashManual を選択する LTFlashSliderPopup に表示するコンポーネントの組です
     */
    readonly property var cGroupFlashManual: [
        {
            component: optionWithSliderComponent,
            properties: {
                type: 1,
                windowType: 1,
                optionText: qsTr("Flash Light Manual"),
                target: "cGroupFlashManual"
            }
        }
    ]

    /*!
        Component for OK-Cancel button panel
     */
    readonly property Component optionWithSliderComponent: Component {
        LTFlashSlider{
            objectName: "sliderObj"
            width: 214
            height: 120
        }
    }
}
