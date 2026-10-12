import QtQuick 2.6

import "qrc:/qml"
import LT 1.0 as LT

/*! \qmltype LTOptionComponentsProvider
    \inqmlmodule LT

    \brief
    LTOptionButtonPopup に表示するコンポーネントの組を提供するオブジェクトです
 */
QtObject {


///////////////////////////////////////////////////////////////////////////////
/// mainWindow
///////////////////////////////////////////////////////////////////////////////
    /*!
        撮影モードを選択する LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var recordingMode: [
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_IntelligentAuto,
                optionText: qsTr("IntelligentAuto"),
                source: "qrc:/images/16_ia.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_ProgramAE,
                optionText: qsTr("ProgramAE"),
                source: "qrc:/images/18_p.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_AperturePriorityAE,
                optionText: qsTr("AperturePriorityAE"),
                source: "qrc:/images/19_a.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_ShutterPriorityAE,
                optionText: qsTr("ShutterPriorityAE"),
                source: "qrc:/images/20_s.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_ManualExposure,
                optionText: qsTr("ManualExposure"),
                source: "qrc:/images/21_m.svg",
                type: "optionWithImage"
            }
        },
        // IVC >> Ver.1.9 >> start >> No.5
//        {
//            component: optionWithImagetoTextButtonComponent,
//            properties: {
//                value: LT.DeviceAdapter.RM_CreativeVideo,
//                optionText: qsTr("CreativeVideo"),
//                source: "qrc:/images/button_placeholder.svg",
//                type: "optionWithImagetoText"
//            }
//        },
        {
            component: subCreativeVideoAE,
            properties: {
                value: LT.DeviceAdapter.RM_CreativeVideo,
//                notDestroy: true,
                type: "optionWithImage"
            }
        },
        // IVC << Ver.1.9 << end << No.5

        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_Custom1,
                optionText: qsTr("Custom1"),
                source: "qrc:/images/26_c1.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_Custom2,
                optionText: qsTr("Custom2"),
                source: "qrc:/images/27_c2.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_Custom3,
                optionText: qsTr("Custom3"),
                // IVC >> Ver.1.9 >> start >> No.5
                source: "qrc:/images/C3.svg",
                // IVC << Ver.1.9 << end << No.5
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CreativeControl,
                optionText: qsTr("CreativeControl"),
                source: "qrc:/images/button_placeholder.svg",
                type: "optionWithImage"
            }
        },
        //{
        //    component: optionWithImagetoTextButtonComponent,
        //    properties: {
        //        value: LT.DeviceAdapter.RM_SceneGuide,
        //        optionText: qsTr("SceneGuide"),
        //        source: "qrc:/images/button_placeholder.svg",
        //        type: "optionWithImagetoText"
        //    }
        //},
        //{
        //    component: optionWithImagetoTextButtonComponent,
        //    properties: {
        //        value: LT.DeviceAdapter.RM_Panorama,
        //        optionText: qsTr("Panorama"),
        //        source: "qrc:/images/button_placeholder.svg",
        //        type: "optionWithImagetoText"
        //    }
        //},
        // IVC >> Ver.1.9 >> start >> No.5
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_Custom4,
                optionText: qsTr("Custom4"),
                source: "qrc:/images/C4.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_Custom5,
                optionText: qsTr("Custom5"),
                source: "qrc:/images/C5.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_Custom6,
                optionText: qsTr("Custom6"),
                source: "qrc:/images/C6.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_Custom7,
                optionText: qsTr("Custom7"),
                source: "qrc:/images/C7.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_Custom8,
                optionText: qsTr("Custom8"),
                source: "qrc:/images/C8.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_Custom9,
                optionText: qsTr("Custom9"),
                source: "qrc:/images/C9.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_Custom10,
                optionText: qsTr("Custom10"),
                source: "qrc:/images/C10.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_Custom11,
                optionText: qsTr("Custom11"),
                source: "qrc:/images/C11.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_Custom12,
                optionText: qsTr("Custom12"),
                source: "qrc:/images/C12.svg",
                type: "optionWithImage"
            }
        }
        // IVC << Ver.1.9 << end << No.5
    ]

    readonly property var creativeControlFilter: [
        {
            component: optionWithImagetoTextButtonCcComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CC_Pop,
                optionText: qsTr("Pop"),
                source: "qrc:/images/53_pop.svg",
                optionSource: "qrc:/images/31_pop.png",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonCcComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CC_Retro,
                optionText: qsTr("Retro"),
                source: "qrc:/images/54_retro.svg",
                optionSource: "qrc:/images/32_retro.png",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonCcComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CC_OldDays,
                optionText: qsTr("OldDays"),
                source: "qrc:/images/55_old.svg",
                optionSource: "qrc:/images/33_old.png",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonCcComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CC_HighKey,
                optionText: qsTr("HighKey"),
                source: "qrc:/images/56_hkey.svg",
                optionSource: "qrc:/images/34_hkey.png",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonCcComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CC_LowKey,
                optionText: qsTr("LowKey"),
                source: "qrc:/images/57_lkey.svg",
                optionSource: "qrc:/images/35_lkey.png",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonCcComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CC_Sepia,
                optionText: qsTr("Sepia"),
                source: "qrc:/images/58_sepi.svg",
                optionSource: "qrc:/images/36_sepi.png",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonCcComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CC_Monochrome,
                optionText: qsTr("Monochrome"),
                source: "qrc:/images/59_mono.svg",
                optionSource: "qrc:/images/37_mono.png",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonCcComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CC_DynamicMonochrome,
                optionText: qsTr("DynamicMonochrome"),
                source: "qrc:/images/60_dmono.svg",
                optionSource: "qrc:/images/38_dmono.png",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonCcComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CC_RoughMonochrome,
                optionText: qsTr("RoughMonochrome"),
                source: "qrc:/images/61_rmono.svg",
                optionSource: "qrc:/images/39_rmono.png",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonCcComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CC_SilkyMonochrome,
                optionText: qsTr("SilkyMonochrome"),
                source: "qrc:/images/62_smono.svg",
                optionSource: "qrc:/images/40_smono.png",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonCcComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CC_ImpressiveArt,
                optionText: qsTr("ImpressiveArt"),
                source: "qrc:/images/63_iart.svg",
                optionSource: "qrc:/images/41_iart.png",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonCcComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CC_HighDynamic,
                optionText: qsTr("HighDynamic"),
                source: "qrc:/images/64_hdyn.svg",
                optionSource: "qrc:/images/42_hdyn.png",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonCcComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CC_CrossProcess,
                optionText: qsTr("CrossProcess"),
                source: "qrc:/images/65_xpro.svg",
                optionSource: "qrc:/images/43_xpro.png",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonCcComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CC_ToyPhoto,
                optionText: qsTr("ToyPhoto"),
                source: "qrc:/images/66_toy.svg",
                optionSource: "qrc:/images/44_toy.png",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonCcComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CC_ToyPop,
                optionText: qsTr("ToyPop"),
                source: "qrc:/images/67_toyp.svg",
                optionSource: "qrc:/images/45_toyp.png",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonCcComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CC_BleachBypass,
                optionText: qsTr("BleachBypass"),
                source: "qrc:/images/68_blea.svg",
                optionSource: "qrc:/images/46_blea.png",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonCcComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CC_Diorama,
                optionText: qsTr("Diorama"),
                source: "qrc:/images/69_dior.svg",
                optionSource: "qrc:/images/47_dior.png",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonCcComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CC_SoftFocus,
                optionText: qsTr("SoftFocus"),
                source: "qrc:/images/70_soft.svg",
                optionSource: "qrc:/images/48_soft.png",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonCcComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CC_Fantasy,
                optionText: qsTr("Fantasy"),
                source: "qrc:/images/71_fan.svg",
                optionSource: "qrc:/images/49_fan.png",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonCcComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CC_CrossFilter,
                optionText: qsTr("CrossFilter"),
                source: "qrc:/images/72_star.svg",
                optionSource: "qrc:/images/50_star.png",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonCcComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CC_OnePointColor,
                optionText: qsTr("OnePointColor"),
                source: "qrc:/images/73_1clr.svg",
                optionSource: "qrc:/images/51_1clr.png",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonCcComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CC_Sunshine,
                optionText: qsTr("Sunshine"),
                source: "qrc:/images/74_sun.svg",
                optionSource: "qrc:/images/52_sun.png",
                type: "optionWithImagetoText"
            }
        },
    ]

    readonly property var creativeControlFilterRatin: [
        {
            component: optionWithImagetoTextButtonCcComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CC_Pop,
                optionText: qsTr("Pop"),
                source: "qrc:/images/53_pop.svg",
                optionSource: "qrc:/images/31_pop.png",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonCcComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CC_Retro,
                optionText: qsTr("Retro"),
                source: "qrc:/images/54_retro.svg",
                optionSource: "qrc:/images/32_retro.png",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonCcComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CC_OldDays,
                optionText: qsTr("OldDays"),
                source: "qrc:/images/55_old.svg",
                optionSource: "qrc:/images/33_old.png",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonCcComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CC_HighKey,
                optionText: qsTr("HighKey"),
                source: "qrc:/images/56_hkey.svg",
                optionSource: "qrc:/images/34_hkey.png",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonCcComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CC_LowKey,
                optionText: qsTr("LowKey"),
                source: "qrc:/images/57_lkey.svg",
                optionSource: "qrc:/images/35_lkey.png",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonCcComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CC_Sepia,
                optionText: qsTr("Sepia"),
                source: "qrc:/images/58_sepi.svg",
                optionSource: "qrc:/images/36_sepi.png",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonCcComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CC_Monochrome,
                optionText: qsTr("Monochrome"),
                source: "qrc:/images/59_mono.svg",
                optionSource: "qrc:/images/37_mono.png",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonCcComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CC_DynamicMonochrome,
                optionText: qsTr("DynamicMonochrome"),
                source: "qrc:/images/60_dmono.svg",
                optionSource: "qrc:/images/38_dmono.png",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonCcComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CC_RoughMonochrome,
                optionText: qsTr("RoughMonochrome"),
                source: "qrc:/images/61_rmono.svg",
                optionSource: "qrc:/images/39_rmono.png",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonCcComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CC_SilkyMonochrome,
                optionText: qsTr("SilkyMonochrome"),
                source: "qrc:/images/62_smono.svg",
                optionSource: "qrc:/images/40_smono.png",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonCcComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CC_ImpressiveArt,
                optionText: qsTr("ImpressiveArt"),
                source: "qrc:/images/63_iart.svg",
                optionSource: "qrc:/images/41_iart.png",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonCcComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CC_HighDynamic,
                optionText: qsTr("HighDynamic"),
                source: "qrc:/images/64_hdyn.svg",
                optionSource: "qrc:/images/42_hdyn.png",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonCcComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CC_CrossProcess,
                optionText: qsTr("CrossProcess"),
                source: "qrc:/images/65_xpro.svg",
                optionSource: "qrc:/images/43_xpro.png",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonCcComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CC_ToyPhoto,
                optionText: qsTr("ToyPhoto"),
                source: "qrc:/images/66_toy.svg",
                optionSource: "qrc:/images/44_toy.png",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonCcComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CC_ToyPop,
                optionText: qsTr("ToyPop"),
                source: "qrc:/images/67_toyp.svg",
                optionSource: "qrc:/images/45_toyp.png",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonCcComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CC_BleachBypass,
                optionText: qsTr("BleachBypass"),
                source: "qrc:/images/68_blea.svg",
                optionSource: "qrc:/images/46_blea.png",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonCcComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CC_Diorama,
                optionText: qsTr("Diorama"),
                source: "qrc:/images/518_mini.svg",
                optionSource: "qrc:/images/517_mini.png",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonCcComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CC_SoftFocus,
                optionText: qsTr("SoftFocus"),
                source: "qrc:/images/70_soft.svg",
                optionSource: "qrc:/images/48_soft.png",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonCcComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CC_Fantasy,
                optionText: qsTr("Fantasy"),
                source: "qrc:/images/71_fan.svg",
                optionSource: "qrc:/images/49_fan.png",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonCcComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CC_CrossFilter,
                optionText: qsTr("CrossFilter"),
                source: "qrc:/images/72_star.svg",
                optionSource: "qrc:/images/50_star.png",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonCcComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CC_OnePointColor,
                optionText: qsTr("OnePointColor"),
                source: "qrc:/images/73_1clr.svg",
                optionSource: "qrc:/images/51_1clr.png",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonCcComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CC_Sunshine,
                optionText: qsTr("Sunshine"),
                source: "qrc:/images/74_sun.svg",
                optionSource: "qrc:/images/52_sun.png",
                type: "optionWithImagetoText"
            }
        },
    ]

    readonly property var creativeVideoAE: [
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CV_ProgramAE,
                optionText: getCreativeVideoAE_OptionText_P(),
                source: "qrc:/images/22_criative_p.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CV_AperturePriorityAE,
                optionText: getCreativeVideoAE_OptionText_A(),
                source: "qrc:/images/23_criative_a.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CV_ShutterPriorityAE,
                optionText: getCreativeVideoAE_OptionText_S(),
                source: "qrc:/images/24_criative_s.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CV_ManualExposure,
                optionText: getCreativeVideoAE_OptionText_M(),
                source: "qrc:/images/25_criative_m.svg",
                type: "optionWithImage"
            }
        },
    ]
    // IVC >> Ver.1.8 >> start >> No.3
    readonly property var sqMotion: [
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CV_ProgramAE,
                optionText: qsTr("SQMode-P"),
                source:  "qrc:/images/sqmode_p.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CV_AperturePriorityAE,
                optionText: qsTr("SQMode-A"),
                source: "qrc:/images/sqmode_a.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CV_ShutterPriorityAE,
                optionText: qsTr("SQMode-S"),
                source: "qrc:/images/sqmode_s.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_CV_ManualExposure,
                optionText: qsTr("SQMode-M"),
                source: "qrc:/images/sqmode_m.svg",
                type: "optionWithImage"
            }
        },
    ]
    // IVC << Ver.1.8 << end << No.3
    // MC8241 2024/7 start
      readonly property var photoExposure: [
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_PE_ProgramAE,
                optionText: qsTr("ProgramAE"),
                source: "qrc:/images/18_p.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_PE_AperturePriorityAE,
                optionText: qsTr("AperturePriorityAE"),
                source: "qrc:/images/19_a.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_PE_ShutterPriorityAE,
                optionText: qsTr("ShutterPriorityAE"),
                source: "qrc:/images/20_s.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_PE_ManualExposure,
                optionText: qsTr("ManualExposure"),
                source: "qrc:/images/21_m.svg",
                type: "optionWithImage"
            }
        },
    ]
    // MC8241 2024/7 end

    readonly property var sceneGuideScene: [
        {
            component: optionWithImagetoTextButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_SG_Beautiful,
                optionText: qsTr("Beautiful"),
                source: "qrc:/images/button_placeholder.svg",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_SG_SkinBeautiful,
                optionText: qsTr("SkinBeautiful"),
                source: "qrc:/images/button_placeholder.svg",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_SG_AgainstSoft,
                optionText: qsTr("AgainstSoft"),
                source: "qrc:/images/button_placeholder.svg",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_SG_AgainstHard,
                optionText: qsTr("AgainstHard"),
                source: "qrc:/images/button_placeholder.svg",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_SG_Heartwarming,
                optionText: qsTr("Heartwarming"),
                source: "qrc:/images/button_placeholder.svg",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_SG_ChildrenCute,
                optionText: qsTr("ChildrenCute"),
                source: "qrc:/images/button_placeholder.svg",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_SG_Landscape,
                optionText: qsTr("Landscape"),
                source: "qrc:/images/button_placeholder.svg",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_SG_BlueSkyCool,
                optionText: qsTr("BlueSkyCool"),
                source: "qrc:/images/button_placeholder.svg",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_SG_FantasticSunset,
                optionText: qsTr("FantasticSunset"),
                source: "qrc:/images/button_placeholder.svg",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_SG_ImpressiveSunset,
                optionText: qsTr("ImpressiveSunset"),
                source: "qrc:/images/button_placeholder.svg",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_SG_SparklingWater,
                optionText: qsTr("SparklingWater"),
                source: "qrc:/images/button_placeholder.svg",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_SG_NightBeatiful,
                optionText: qsTr("NightBeatiful"),
                source: "qrc:/images/button_placeholder.svg",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_SG_NightCool,
                optionText: qsTr("NightCool"),
                source: "qrc:/images/button_placeholder.svg",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_SG_NightWarm,
                optionText: qsTr("NightWarm"),
                source: "qrc:/images/button_placeholder.svg",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_SG_NightArtistic,
                optionText: qsTr("NightArtistic"),
                source: "qrc:/images/button_placeholder.svg",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_SG_Illumination,
                optionText: qsTr("Illumination"),
                source: "qrc:/images/button_placeholder.svg",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_SG_NightHand,
                optionText: qsTr("NightHand"),
                source: "qrc:/images/button_placeholder.svg",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_SG_NightBack,
                optionText: qsTr("NightBack"),
                source: "qrc:/images/button_placeholder.svg",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_SG_Flower,
                optionText: qsTr("Flower"),
                source: "qrc:/images/button_placeholder.svg",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_SG_Delicious,
                optionText: qsTr("Delicious"),
                source: "qrc:/images/button_placeholder.svg",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_SG_Sweets,
                optionText: qsTr("Sweets"),
                source: "qrc:/images/button_placeholder.svg",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_SG_Pet,
                optionText: qsTr("Pet"),
                source: "qrc:/images/button_placeholder.svg",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_SG_Sports,
                optionText: qsTr("Sports"),
                source: "qrc:/images/button_placeholder.svg",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_SG_Monochrome,
                optionText: qsTr("Monochrome"),
                source: "qrc:/images/button_placeholder.svg",
                type: "optionWithImagetoText"
            }
        },
    ]

    readonly property var intelligentAutoMode: [
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_IA_IntelligentAuto,
                optionText: qsTr("IA_IntelligentAuto"),
                source: "qrc:/images/16_ia.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_IA_IntelligentAutoPlus,
                optionText: qsTr("IA_IntelligentAutoPlus"),
                source: "qrc:/images/17_iaplus.svg",
                type: "optionWithImage"
            }
        },
    ]

    readonly property var custom3Set: [
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_C3_Set1,
                optionText: qsTr("C3_Set1"),
                source: "qrc:/images/27_c3_1.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_C3_Set2,
                optionText: qsTr("C3_Set2"),
                source: "qrc:/images/27_c3_2-01.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_C3_Set3,
                optionText: qsTr("C3_Set3"),
                source: "qrc:/images/27_c3_2-03.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_C3_Set4,
                optionText: qsTr("C3_Set4"),
                source: "qrc:/images/27_c3_2-04.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_C3_Set5,
                optionText: qsTr("C3_Set5"),
                source: "qrc:/images/27_c3_2-05.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_C3_Set6,
                optionText: qsTr("C3_Set6"),
                source: "qrc:/images/27_c3_2-06.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_C3_Set7,
                optionText: qsTr("C3_Set7"),
                source: "qrc:/images/27_c3_2-07.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_C3_Set8,
                optionText: qsTr("C3_Set8"),
                source: "qrc:/images/27_c3_2-08.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_C3_Set9,
                optionText: qsTr("C3_Set9"),
                source: "qrc:/images/27_c3_2-09.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_C3_Set10,
                optionText: qsTr("C3_Set10"),
                source: "qrc:/images/27_c3_2-10.svg",
                type: "optionWithImage"
            }
        },
    ]

    readonly property var custom4Set: [
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_C3_Set1,
                optionText: qsTr("C4_Set1"),
                source: "qrc:/images/c4_1.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_C3_Set2,
                optionText: qsTr("C4_Set2"),
                source: "qrc:/images/c4_2.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_C3_Set3,
                optionText: qsTr("C4_Set3"),
                source: "qrc:/images/c4_3.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_C3_Set4,
                optionText: qsTr("C4_Set4"),
                source: "qrc:/images/c4_4.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_C3_Set5,
                optionText: qsTr("C4_Set5"),
                source: "qrc:/images/c4_5.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_C3_Set6,
                optionText: qsTr("C4_Set6"),
                source: "qrc:/images/c4_6.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_C3_Set7,
                optionText: qsTr("C4_Set7"),
                source: "qrc:/images/c4_7.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_C3_Set8,
                optionText: qsTr("C4_Set8"),
                source: "qrc:/images/c4_8.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_C3_Set9,
                optionText: qsTr("C4_Set9"),
                source: "qrc:/images/c4_9.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_C3_Set10,
                optionText: qsTr("C4_Set10"),
                source: "qrc:/images/c4_10.svg",
                type: "optionWithImage"
            }
        },
    ]

    readonly property var custom5Set: [
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_C3_Set1,
                optionText: qsTr("C5_Set1"),
                source: "qrc:/images/c5_1.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_C3_Set2,
                optionText: qsTr("C5_Set2"),
                source: "qrc:/images/c5_2.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_C3_Set3,
                optionText: qsTr("C5_Set3"),
                source: "qrc:/images/c5_3.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_C3_Set4,
                optionText: qsTr("C5_Set4"),
                source: "qrc:/images/c5_4.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_C3_Set5,
                optionText: qsTr("C5_Set5"),
                source: "qrc:/images/c5_5.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_C3_Set6,
                optionText: qsTr("C5_Set6"),
                source: "qrc:/images/c5_6.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_C3_Set7,
                optionText: qsTr("C5_Set7"),
                source: "qrc:/images/c5_7.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_C3_Set8,
                optionText: qsTr("C5_Set8"),
                source: "qrc:/images/c5_8.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_C3_Set9,
                optionText: qsTr("C5_Set9"),
                source: "qrc:/images/c5_9.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RM_C3_Set10,
                optionText: qsTr("C5_Set10"),
                source: "qrc:/images/c5_10.svg",
                type: "optionWithImage"
            }
        },
    ]

    /*!
        絞りを選択する LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var aperture: [
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_0_0),
                value: LT.Utilities.Ape_F_0_0,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_0_8),
                value: LT.Utilities.Ape_F_0_8,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_0_9),
                value: LT.Utilities.Ape_F_0_9,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_1_0),
                value: LT.Utilities.Ape_F_1_0,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_1_1),
                value: LT.Utilities.Ape_F_1_1,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_1_2),
                value: LT.Utilities.Ape_F_1_2,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_1_3),
                value: LT.Utilities.Ape_F_1_3,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_1_4),
                value: LT.Utilities.Ape_F_1_4,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_1_5),
                value: LT.Utilities.Ape_F_1_5,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_1_6),
                value: LT.Utilities.Ape_F_1_6,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_1_7),
                value: LT.Utilities.Ape_F_1_7,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_1_8),
                value: LT.Utilities.Ape_F_1_8,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_1_9),
                value: LT.Utilities.Ape_F_1_9,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_2_0),
                value: LT.Utilities.Ape_F_2_0,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_2_1),
                value: LT.Utilities.Ape_F_2_1,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_2_2),
                value: LT.Utilities.Ape_F_2_2,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_2_3),
                value: LT.Utilities.Ape_F_2_3,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_2_4),
                value: LT.Utilities.Ape_F_2_4,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_2_5),
                value: LT.Utilities.Ape_F_2_5,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_2_6),
                value: LT.Utilities.Ape_F_2_6,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_2_7),
                value: LT.Utilities.Ape_F_2_7,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_2_8),
                value: LT.Utilities.Ape_F_2_8,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_2_9),
                value: LT.Utilities.Ape_F_2_9,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_3_0),
                value: LT.Utilities.Ape_F_3_0,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_3_1),
                value: LT.Utilities.Ape_F_3_1,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_3_2),
                value: LT.Utilities.Ape_F_3_2,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_3_3),
                value: LT.Utilities.Ape_F_3_3,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_3_4),
                value: LT.Utilities.Ape_F_3_4,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_3_5),
                value: LT.Utilities.Ape_F_3_5,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_3_6),
                value: LT.Utilities.Ape_F_3_6,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_3_7),
                value: LT.Utilities.Ape_F_3_7,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_3_8),
                value: LT.Utilities.Ape_F_3_8,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_3_9),
                value: LT.Utilities.Ape_F_3_9,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_4_0),
                value: LT.Utilities.Ape_F_4_0,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_4_1),
                value: LT.Utilities.Ape_F_4_1,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_4_2),
                value: LT.Utilities.Ape_F_4_2,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_4_3),
                value: LT.Utilities.Ape_F_4_3,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_4_4),
                value: LT.Utilities.Ape_F_4_4,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_4_5),
                value: LT.Utilities.Ape_F_4_5,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_4_6),
                value: LT.Utilities.Ape_F_4_6,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_4_7),
                value: LT.Utilities.Ape_F_4_7,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_4_8),
                value: LT.Utilities.Ape_F_4_8,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_4_9),
                value: LT.Utilities.Ape_F_4_9,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_5_0),
                value: LT.Utilities.Ape_F_5_0,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_5_1),
                value: LT.Utilities.Ape_F_5_1,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_5_2),
                value: LT.Utilities.Ape_F_5_2,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_5_3),
                value: LT.Utilities.Ape_F_5_3,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_5_4),
                value: LT.Utilities.Ape_F_5_4,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_5_5),
                value: LT.Utilities.Ape_F_5_5,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_5_6),
                value: LT.Utilities.Ape_F_5_6,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_5_7),
                value: LT.Utilities.Ape_F_5_7,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_5_8),
                value: LT.Utilities.Ape_F_5_8,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_5_9),
                value: LT.Utilities.Ape_F_5_9,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_6_0),
                value: LT.Utilities.Ape_F_6_0,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_6_1),
                value: LT.Utilities.Ape_F_6_1,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_6_2),
                value: LT.Utilities.Ape_F_6_2,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_6_3),
                value: LT.Utilities.Ape_F_6_3,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_6_4),
                value: LT.Utilities.Ape_F_6_4,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_6_5),
                value: LT.Utilities.Ape_F_6_5,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_6_6),
                value: LT.Utilities.Ape_F_6_6,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_6_7),
                value: LT.Utilities.Ape_F_6_7,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_6_8),
                value: LT.Utilities.Ape_F_6_8,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_6_9),
                value: LT.Utilities.Ape_F_6_9,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_7_0),
                value: LT.Utilities.Ape_F_7_0,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_7_1),
                value: LT.Utilities.Ape_F_7_1,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_7_2),
                value: LT.Utilities.Ape_F_7_2,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_7_3),
                value: LT.Utilities.Ape_F_7_3,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_7_4),
                value: LT.Utilities.Ape_F_7_4,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_7_5),
                value: LT.Utilities.Ape_F_7_5,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_7_6),
                value: LT.Utilities.Ape_F_7_6,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_7_7),
                value: LT.Utilities.Ape_F_7_7,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_7_8),
                value: LT.Utilities.Ape_F_7_8,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_7_9),
                value: LT.Utilities.Ape_F_7_9,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_8_0),
                value: LT.Utilities.Ape_F_8_0,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_8_1),
                value: LT.Utilities.Ape_F_8_1,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_8_2),
                value: LT.Utilities.Ape_F_8_2,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_8_3),
                value: LT.Utilities.Ape_F_8_3,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_8_4),
                value: LT.Utilities.Ape_F_8_4,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_8_5),
                value: LT.Utilities.Ape_F_8_5,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_8_6),
                value: LT.Utilities.Ape_F_8_6,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_8_7),
                value: LT.Utilities.Ape_F_8_7,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_8_8),
                value: LT.Utilities.Ape_F_8_8,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_8_9),
                value: LT.Utilities.Ape_F_8_9,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_9_0),
                value: LT.Utilities.Ape_F_9_0,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_9_1),
                value: LT.Utilities.Ape_F_9_1,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_9_2),
                value: LT.Utilities.Ape_F_9_2,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_9_3),
                value: LT.Utilities.Ape_F_9_3,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_9_4),
                value: LT.Utilities.Ape_F_9_4,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_9_5),
                value: LT.Utilities.Ape_F_9_5,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_9_6),
                value: LT.Utilities.Ape_F_9_6,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_9_7),
                value: LT.Utilities.Ape_F_9_7,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_9_8),
                value: LT.Utilities.Ape_F_9_8,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_9_9),
                value: LT.Utilities.Ape_F_9_9,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_10),
                value: LT.Utilities.Ape_F_10,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_11),
                value: LT.Utilities.Ape_F_11,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_12),
                value: LT.Utilities.Ape_F_12,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_13),
                value: LT.Utilities.Ape_F_13,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_14),
                value: LT.Utilities.Ape_F_14,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_15),
                value: LT.Utilities.Ape_F_15,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_16),
                value: LT.Utilities.Ape_F_16,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_17),
                value: LT.Utilities.Ape_F_17,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_18),
                value: LT.Utilities.Ape_F_18,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_19),
                value: LT.Utilities.Ape_F_19,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_20),
                value: LT.Utilities.Ape_F_20,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_21),
                value: LT.Utilities.Ape_F_21,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_22),
                value: LT.Utilities.Ape_F_22,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_23),
                value: LT.Utilities.Ape_F_23,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_24),
                value: LT.Utilities.Ape_F_24,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_25),
                value: LT.Utilities.Ape_F_25,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_27),
                value: LT.Utilities.Ape_F_27,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_28),
                value: LT.Utilities.Ape_F_28,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_29),
                value: LT.Utilities.Ape_F_29,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_30),
                value: LT.Utilities.Ape_F_30,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_31),
                value: LT.Utilities.Ape_F_31,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_32),
                value: LT.Utilities.Ape_F_32,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_33),
                value: LT.Utilities.Ape_F_33,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_34),
                value: LT.Utilities.Ape_F_34,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_35),
                value: LT.Utilities.Ape_F_35,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_36),
                value: LT.Utilities.Ape_F_36,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_37),
                value: LT.Utilities.Ape_F_37,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_38),
                value: LT.Utilities.Ape_F_38,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_39),
                value: LT.Utilities.Ape_F_39,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_40),
                value: LT.Utilities.Ape_F_40,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_42),
                value: LT.Utilities.Ape_F_42,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_43),
                value: LT.Utilities.Ape_F_43,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_44),
                value: LT.Utilities.Ape_F_44,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_45),
                value: LT.Utilities.Ape_F_45,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_47),
                value: LT.Utilities.Ape_F_47,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_48),
                value: LT.Utilities.Ape_F_48,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_49),
                value: LT.Utilities.Ape_F_49,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_51),
                value: LT.Utilities.Ape_F_51,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_52),
                value: LT.Utilities.Ape_F_52,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_54),
                value: LT.Utilities.Ape_F_54,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_55),
                value: LT.Utilities.Ape_F_55,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_57),
                value: LT.Utilities.Ape_F_57,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_59),
                value: LT.Utilities.Ape_F_59,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_60),
                value: LT.Utilities.Ape_F_60,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_62),
                value: LT.Utilities.Ape_F_62,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_64),
                value: LT.Utilities.Ape_F_64,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_66),
                value: LT.Utilities.Ape_F_66,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_68),
                value: LT.Utilities.Ape_F_68,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_70),
                value: LT.Utilities.Ape_F_70,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_72),
                value: LT.Utilities.Ape_F_72,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_74),
                value: LT.Utilities.Ape_F_74,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_76),
                value: LT.Utilities.Ape_F_76,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_78),
                value: LT.Utilities.Ape_F_78,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_81),
                value: LT.Utilities.Ape_F_81,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_83),
                value: LT.Utilities.Ape_F_83,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_85),
                value: LT.Utilities.Ape_F_85,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_88),
                value: LT.Utilities.Ape_F_88,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: apertureOptionTextFormat(LT.Utilities.Ape_F_90),
                value: LT.Utilities.Ape_F_90,
            }
        },
    ]

    /*!
        シャッタースピードを選択する LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var shutterSpeed: [
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_Bulb"),
                value: LT.Utilities.SS_Bulb,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_Time"),
                value: LT.Utilities.SS_Time,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_Sec_60"),
                value: LT.Utilities.SS_Sec_60,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_Sec_50"),
                value: LT.Utilities.SS_Sec_50,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_Sec_40"),
                value: LT.Utilities.SS_Sec_40,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_Sec_30"),
                value: LT.Utilities.SS_Sec_30,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_Sec_25"),
                value: LT.Utilities.SS_Sec_25,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_Sec_20"),
                value: LT.Utilities.SS_Sec_20,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_Sec_15"),
                value: LT.Utilities.SS_Sec_15,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_Sec_13"),
                value: LT.Utilities.SS_Sec_13,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_Sec_10"),
                value: LT.Utilities.SS_Sec_10,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_Sec_8"),
                value: LT.Utilities.SS_Sec_8,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_Sec_6"),
                value: LT.Utilities.SS_Sec_6,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_Sec_5"),
                value: LT.Utilities.SS_Sec_5,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_Sec_4"),
                value: LT.Utilities.SS_Sec_4,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_Sec_3_2"),
                value: LT.Utilities.SS_Sec_3_2,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_Sec_2_5"),
                value: LT.Utilities.SS_Sec_2_5,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_Sec_2"),
                value: LT.Utilities.SS_Sec_2,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_Sec_1_6"),
                value: LT.Utilities.SS_Sec_1_6,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_Sec_1_3"),
                value: LT.Utilities.SS_Sec_1_3,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_Sec_1"),
                value: LT.Utilities.SS_Sec_1,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_1_3"),
                value: LT.Utilities.SS_1_3,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_1_6"),
                value: LT.Utilities.SS_1_6,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_2"),
                value: LT.Utilities.SS_2,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_2_5"),
                value: LT.Utilities.SS_2_5,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_3_2"),
                value: LT.Utilities.SS_3_2,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_4"),
                value: LT.Utilities.SS_4,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_5"),
                value: LT.Utilities.SS_5,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_6"),
                value: LT.Utilities.SS_6,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_8"),
                value: LT.Utilities.SS_8,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_10"),
                value: LT.Utilities.SS_10,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_13"),
                value: LT.Utilities.SS_13,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_15"),
                value: LT.Utilities.SS_15,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_20"),
                value: LT.Utilities.SS_20,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_25"),
                value: LT.Utilities.SS_25,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_30"),
                value: LT.Utilities.SS_30,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_40"),
                value: LT.Utilities.SS_40,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_50"),
                value: LT.Utilities.SS_50,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_60"),
                value: LT.Utilities.SS_60,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_80"),
                value: LT.Utilities.SS_80,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_100"),
                value: LT.Utilities.SS_100,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_125"),
                value: LT.Utilities.SS_125,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_160"),
                value: LT.Utilities.SS_160,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_200"),
                value: LT.Utilities.SS_200,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_250"),
                value: LT.Utilities.SS_250,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_320"),
                value: LT.Utilities.SS_320,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_400"),
                value: LT.Utilities.SS_400,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_500"),
                value: LT.Utilities.SS_500,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_640"),
                value: LT.Utilities.SS_640,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_800"),
                value: LT.Utilities.SS_800,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_1000"),
                value: LT.Utilities.SS_1000,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_1300"),
                value: LT.Utilities.SS_1300,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_1600"),
                value: LT.Utilities.SS_1600,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_2000"),
                value: LT.Utilities.SS_2000,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_2500"),
                value: LT.Utilities.SS_2500,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_3200"),
                value: LT.Utilities.SS_3200,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_4000"),
                value: LT.Utilities.SS_4000,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_5000"),
                value: LT.Utilities.SS_5000,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_6400"),
                value: LT.Utilities.SS_6400,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_8000"),
                value: LT.Utilities.SS_8000,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_10000"),
                value: LT.Utilities.SS_10000,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_13000"),
                value: LT.Utilities.SS_13000,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_16000"),
                value: LT.Utilities.SS_16000,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_20000"),
                value: LT.Utilities.SS_20000,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_25000"),
                value: LT.Utilities.SS_25000,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_32000"),
                value: LT.Utilities.SS_32000,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_40000"),
                value: LT.Utilities.SS_40000,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_50000"),
                value: LT.Utilities.SS_50000,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_51200"),
                value: LT.Utilities.SS_51200,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SS_64000"),
                value: LT.Utilities.SS_64000,
            }
        },

        //{
        //    component: optionWithRichTextButtonComponent,
        //    properties: {
        //        type: "optionWithRichText",
        //        optionText: '<b><big>' + qsTr("SS_20000") + '<b><big>',
        //        value: LT.Utilities.SS_20000,
        //    }
        //},
    ]

    /*!
        ドライブモードを選択する LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var driveMode: [
        {
            component: optionWithImagetoTextButtonComponent,
            properties: {
                value: LT.DeviceAdapter.DM_Single,
                optionText: qsTr("Single"),
                source: "qrc:/images/126_single.svg",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonComponent,
            properties: {
                value: LT.DeviceAdapter.DM_Burst,
                optionText: qsTr("Burst"),
                source: "qrc:/images/127_burst_h.svg",
                type: "optionWithImagetoText"
            }
        },
        //{
        //    component: optionWithImagetoTextButtonComponent,
        //    properties: {
        //        value: LT.DeviceAdapter.DM_Burst1,
        //        optionText: qsTr("Burst1"),
        //        source: "qrc:/images/button_placeholder.svg",
        //        type: "optionWithImagetoText"
        //    }
        //},
        //{
        //    component: optionWithImagetoTextButtonComponent,
        //    properties: {
        //        value: LT.DeviceAdapter.DM_Burst2,
        //        optionText: qsTr("Burst2"),
        //        source: "qrc:/images/button_placeholder.svg",
        //        type: "optionWithImagetoText"
        //    }
        //},
        {
            component: optionWithImagetoTextButtonComponent,
            properties: {
                value: LT.DeviceAdapter.DM_4K6K,
                optionText: qsTr("4K6K"),
                source: "qrc:/images/button_placeholder.svg",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonComponent,
            properties: {
                value: LT.DeviceAdapter.DM_Focus,
                optionText: qsTr("Focus"),
                source: "qrc:/images/button_placeholder.svg",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonComponent,
            properties: {
                value: LT.DeviceAdapter.DM_SelfTimer,
                optionText: qsTr("SelfTimer"),
                source: "qrc:/images/button_placeholder.svg",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonComponent,
            properties: {
                value: LT.DeviceAdapter.DM_Interval,
                optionText: qsTr("Interval"),
                source: "qrc:/images/523_interval.svg",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonComponent,
            properties: {
                value: LT.DeviceAdapter.DM_Komadori,
                optionText: qsTr("Komadori"),
                source: "qrc:/images/523_lapse.svg",
                type: "optionWithImagetoText"
            }
        },
        //{
        //    component: optionWithImagetoTextButtonComponent,
        //    properties: {
        //        value: LT.DeviceAdapter.DM_Bracket,
        //        optionText: qsTr("Bracket"),
        //        source: "qrc:/images/button_placeholder.svg",
        //        type: "optionWithImagetoText"
        //    }
        //},
        {
            component: optionWithImagetoTextButtonComponent,
            properties: {
                value: LT.DeviceAdapter.DM_HRS,
                optionText: qsTr("HRS"),
                source: "qrc:/images/fn_high_rezolution.svg",
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImagetoTextButtonComponent,
            properties: {
                value: LT.DeviceAdapter.DM_HANDHELD_HRS,
                optionText: qsTr("HANDHELD_HRS"),
                source: "qrc:/images/fn_hand_high_rezolution.svg",
                type: "optionWithImagetoText"
            }
        },
    ]

    /*!
        ドライブモードダイアルを選択する LTOptionButtonPopup に表示するコンポーネントの組です optionWithImageButtonComponent optionWithImagetoTextButtonComponent
     */
    readonly property var driveModeSelect: [
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.DM_Single,
                optionText: qsTr("Single"),
                source: "qrc:/images/126_single.svg",
                type: "optionWithImage",
            }
        },
        {
            component: optionWithImagetoTextButtonComponent,
            properties: {
                value: LT.DeviceAdapter.DM_Burst,
                optionText: qsTr("Burst"),
                source: "qrc:/images/127_burst_h.svg",
                type: "optionWithImage",
            }
        },
        {
            component: optionWithImagetoTextButtonComponent,    // ブラケットは未使用
            properties: {
                value: LT.DeviceAdapter.DM_Bracket,
                optionText: qsTr("Bracket"),
                source: "qrc:/images/button_placeholder.svg",
                type: "optionWithImage",
            }
        },
        {
            component: optionWithImagetoTextButtonComponent,
            properties: {
                value: LT.DeviceAdapter.DM_Burst1,
                optionText: qsTr("Burst1"),
                source: "qrc:/images/button_placeholder.svg",
                type: "optionWithImage",
            }
        },
        {
            component: optionWithImagetoTextButtonComponent,
            properties: {
                value: LT.DeviceAdapter.DM_Burst2,
                optionText: qsTr("Burst"),                      // 連写２だが連写として表示
                source: "qrc:/images/button_placeholder.svg",
                type: "optionWithImage",
            }
        },
        {
            component: optionWithImagetoTextButtonComponent,
            properties: {
                value: LT.DeviceAdapter.DM_HRS,
                optionText: qsTr("HRS"),
                source: "qrc:/images/fn_high_rezolution.svg",
                type: "optionWithImage",
            }
        },
        {
            component: optionWithImagetoTextButtonComponent,
            properties: {
                value: LT.DeviceAdapter.DM_HANDHELD_HRS,
                optionText: qsTr("HANDHELD_HRS"),
                source: "qrc:/images/fn_hand_high_rezolution.svg",
                type: "optionWithImage",
            }
        },
        {
            component: optionWithImagetoTextButtonComponent,
            properties: {
                value: LT.DeviceAdapter.DM_Interval,
                optionText: qsTr("Interval"),
                source: "qrc:/images/523_interval.svg",
                type: "optionWithImage",
            }
        },
        {
            component: optionWithImagetoTextButtonComponent,
            properties: {
                value: LT.DeviceAdapter.DM_Komadori,
                optionText: qsTr("Komadori"),
                source: "qrc:/images/523_lapse.svg",
                type: "optionWithImage",
            }
        },
        {
            component: optionWithImagetoTextButtonComponent,
            properties: {
                value: LT.DeviceAdapter.DM_4K6K,
                optionText: qsTr("4K6K"),
                source: "qrc:/images/button_placeholder.svg",
                type: "optionWithImage",
            }
        },
        {
            component: optionWithImagetoTextButtonComponent,
            properties: {
                value: LT.DeviceAdapter.DM_Focus,
                optionText: qsTr("Focus"),
                source: "qrc:/images/button_placeholder.svg",
                type: "optionWithImage",
            }
        },
        {
            component: optionWithImagetoTextButtonComponent,
            properties: {
                value: LT.DeviceAdapter.DM_SelfTimer,
                optionText: qsTr("SelfTimer"),
                source: "qrc:/images/button_placeholder.svg",
                type: "optionWithImage",
            }
        },
    ]

    /*!
        4K/6Kを選択する LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var picture4K6K: [
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.PQQ_6K_30p_Burst,
                optionText: qsTr("6K_30p_Burst"),
                source: "qrc:/images/175_burst_6k_30fps.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.PQQ_6K_30p_Burst_SS,
                optionText: qsTr("6K_30p_Burst_SS"),
                source: "qrc:/images/176_burst_6k_30fps_ss.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.PQQ_6K_30p_PreBurst,
                optionText: qsTr("6K_30p_PreBurst"),
                source: "qrc:/images/177_burst_6k_30fps_pre.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.PQQ_4K_60p_Burst,
                optionText: qsTr("4K_60p_Burst"),
                source: "qrc:/images/178_burst_4k_60fps.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.PQQ_4K_60p_Burst_SS,
                optionText: qsTr("4K_60p_Burst_SS"),
                source: "qrc:/images/179_burst_4k_60fps_ss.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.PQQ_4K_60p_PreBurst,
                optionText: qsTr("4K_60p_PreBurst"),
                source: "qrc:/images/180_burst_4k_60fps_pre.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.PQQ_4K_30p_Burst,
                optionText: qsTr("4K_30p_Burst"),
                source: "qrc:/images/181_burst_4k_30fps.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.PQQ_4K_30p_Burst_SS,
                optionText: qsTr("4K_30p_Burst_SS"),
                source: "qrc:/images/182_burst_4k_30fps_ss.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.PQQ_4K_30p_PreBurst,
                optionText: qsTr("4K_30p_PreBurst"),
                source: "qrc:/images/183_burst_4k_30fps_pre.svg",
                type: "optionWithImage"
            }
        },
    ]

    /*!
        連写速度を選択する LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var burstSpeed: [
// 2020/02/14 Panasonic Kashihara >> add >> start
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_6K4K,
                optionText: qsTr("6K/4K"),
                source: "qrc:/images/6k_photo.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_EleFastSH,
                optionText: qsTr("burst_SH"),
                source: "qrc:/images/burst_sh.svg",
                type: "optionWithImage"
            }
        },
        // {
        //     component: optionWithImageButtonComponent,
        //     properties: {
        //         value: LT.DeviceAdapter.BS_EleFast90,
        //         optionText: qsTr("SH90"),
        //         source: "qrc:/images/burst_sh_90.svg",
        //         type: "optionWithImage"
        //     }
        // },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_EleFast75,
                optionText: qsTr("SH75"),
                source: "qrc:/images/burst_sh_75.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_EleFast70,
                optionText: qsTr("SH70"),
                source: "qrc:/images/burst_sh_70.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_EleFast60,
                optionText: qsTr("SH60"),
                source: "qrc:/images/burst_sh_60.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_EleFast40,
                optionText: qsTr("SH40"),
                source: "qrc:/images/burst_sh_40.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_EleFast30,
                optionText: qsTr("SH30"),
                source: "qrc:/images/burst_sh_30.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_EleFast20,
                optionText: qsTr("SH20"),
                source: "qrc:/images/burst_sh_20.svg",
                type: "optionWithImage"
            }
        },
        // MC8223/MC8223X 23年10月FwUp（MC5229で前倒し導入）
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_EleFastPreSH,
                optionText: qsTr("burst_SHPre"),
                source: "qrc:/images/burst_sh_pre.svg",
                type: "optionWithImage"
            }
        },
        // {
        //     component: optionWithImageButtonComponent,
        //     properties: {
        //         value: LT.DeviceAdapter.BS_EleFastPre90,
        //         optionText: qsTr("SH90Pre"),
        //         source: "qrc:/images/burst_sh_90_pre.svg",
        //         type: "optionWithImage"
        //     }
        // },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_EleFastPre75,
                optionText: qsTr("SH75Pre"),
                source: "qrc:/images/burst_sh_75_pre.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_EleFastPre70,
                optionText: qsTr("SH70Pre"),
                source: "qrc:/images/burst_sh_70_pre.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_EleFastPre60,
                optionText: qsTr("SH60Pre"),
                source: "qrc:/images/burst_sh_60_pre.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_EleFastPre40,
                optionText: qsTr("SH40Pre"),
                source: "qrc:/images/burst_sh_40_pre.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_EleFastPre30,
                optionText: qsTr("SH30Pre"),
                source: "qrc:/images/burst_sh_30_pre.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_EleFastPre20,
                optionText: qsTr("SH20Pre"),
                source: "qrc:/images/burst_sh_20_pre.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_EleFast3,
                optionText: qsTr("SH3"),
                source: "qrc:/images/131_burst_sh3.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_EleFast2,
                optionText: qsTr("SH2"),
                source: "qrc:/images/132_burst_sh2.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_EleFast,
                optionText: qsTr("SH1"),
                source: "qrc:/images/133_burst_sh1.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_EleFastPre3,
                optionText: qsTr("SH3Pre"),
                source: "qrc:/images/134_burst_sh3_pre.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_EleFastPre2,
                optionText: qsTr("SH2Pre"),
                source: "qrc:/images/135_burst_sh2_pre.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_EleFastPre,
                optionText: qsTr("SH1Pre"),
                source: "qrc:/images/136_burst_sh1_pre.svg",
                type: "optionWithImage"
            }
        },
// 2020/02/14 Panasonic Kashihara >> add >> end
// MC8241/8244
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_HighSpeedPlus,
                optionText: qsTr("HighSpeedPlus"),
                source: "qrc:/images/burst_h_plus.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_HighSpeedPlusLiveView,
                optionText: qsTr("HighSpeedPlusLiveView"),
                source: "qrc:/images/burst_lv_h_plus.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_HighSpeed,
                optionText: qsTr("HighSpeed"),
                source: "qrc:/images/127_burst_h.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_HighSpeedLiveView,
                optionText: qsTr("HighSpeedLiveView"),
                source: "qrc:/images/128_burst_lv_h.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_MiddleSpeedLiveView,
                optionText: qsTr("MiddleSpeedLiveView"),
                source: "qrc:/images/129_burst_lv_m.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_LowSpeedLiveView,
                optionText: qsTr("LowSpeedLiveView"),
                source: "qrc:/images/130_burst_lv_l.svg",
                type: "optionWithImage"
            }
        },
        //{
        //    component: optionWithImageButtonComponent,
        //    properties: {
        //        value: LT.DeviceAdapter.BS_SH3,
        //        optionText: qsTr("SH3"),
        //        source: "qrc:/images/131_burst_sh3.svg",
        //        type: "optionWithImage"
        //    }
        //},
        //{
        //    component: optionWithImageButtonComponent,
        //    properties: {
        //        value: LT.DeviceAdapter.BS_SH2,
        //        optionText: qsTr("SH2"),
        //        source: "qrc:/images/132_burst_sh2.svg",
        //        type: "optionWithImage"
        //    }
        //},
        //{
        //    component: optionWithImageButtonComponent,
        //    properties: {
        //        value: LT.DeviceAdapter.BS_SH1,
        //        optionText: qsTr("SH1"),
        //        source: "qrc:/images/133_burst_sh1.svg",
        //        type: "optionWithImage"
        //    }
        //},
        //{
        //    component: optionWithImageButtonComponent,
        //    properties: {
        //        value: LT.DeviceAdapter.BS_SH3Pre,
        //        optionText: qsTr("SH3Pre"),
        //        source: "qrc:/images/134_burst_sh3_pre.svg",
        //        type: "optionWithImage"
        //    }
        //},
        //{
        //    component: optionWithImageButtonComponent,
        //    properties: {
        //        value: LT.DeviceAdapter.BS_SH2Pre,
        //        optionText: qsTr("SH2Pre"),
        //        source: "qrc:/images/135_burst_sh2_pre.svg",
        //        type: "optionWithImage"
        //    }
        //},
        //{
        //    component: optionWithImageButtonComponent,
        //    properties: {
        //        value: LT.DeviceAdapter.BS_SH1Pre,
        //        optionText: qsTr("SH1Pre"),
        //        source: "qrc:/images/136_burst_sh1_pre.svg",
        //        type: "optionWithImage"
        //    }
        //},
        //{
        //    component: optionWithImageButtonComponent,
        //    properties: {
        //        value: LT.DeviceAdapter.BS_H,
        //        optionText: qsTr("H"),
        //        source: "qrc:/images/button_placeholder.svg",
        //        type: "optionWithImage"
        //    }
        //},
        //{
        //    component: optionWithImageButtonComponent,
        //    properties: {
        //        value: LT.DeviceAdapter.BS_L_8fps,
        //        optionText: qsTr("L_8fps"),
        //        source: "qrc:/images/138_burst_h_8fps.svg",
        //        type: "optionWithImage"
        //    }
        //},
        //{
        //    component: optionWithImageButtonComponent,
        //    properties: {
        //        value: LT.DeviceAdapter.BS_L_5fps,
        //        optionText: qsTr("L_5fps"),
        //        source: "qrc:/images/139_burst_h_5fps.svg",
        //        type: "optionWithImage"
        //    }
        //},
        //{
        //    component: optionWithImageButtonComponent,
        //    properties: {
        //        value: LT.DeviceAdapter.BS_L_4fps,
        //        optionText: qsTr("L_4fps"),
        //        source: "qrc:/images/140_burst_h_4fps.svg",
        //        type: "optionWithImage"
        //    }
        //},
        //{
        //    component: optionWithImageButtonComponent,
        //    properties: {
        //        value: LT.DeviceAdapter.BS_L_3fps,
        //        optionText: qsTr("L_3fps"),
        //        source: "qrc:/images/141_burst_h_3fps.svg",
        //        type: "optionWithImage"
        //    }
        //},
        //{
        //    component: optionWithImageButtonComponent,
        //    properties: {
        //        value: LT.DeviceAdapter.BS_L_2fps,
        //        optionText: qsTr("L_2fps"),
        //        source: "qrc:/images/142_burst_h_2fps.svg",
        //        type: "optionWithImage"
        //    }
        //},
    ]

    /*!
        連写速度1を選択する LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var burstSpeed1: [
        // 2020/02/14 Panasonic Kashihara >> add >> start
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_6K4K,
                        optionText: qsTr("6K/4K"),
                        source: "qrc:/images/6k_photo.svg",
                        type: "optionWithImage"
                    }
                },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_EleFastSH,
                        optionText: qsTr("burst_SH"),
                        source: "qrc:/images/burst_sh.svg",
                        type: "optionWithImage"
                    }
                },
                // {
                //     component: optionWithImageButtonComponent,
                //     properties: {
                //         value: LT.DeviceAdapter.BS_EleFast90,
                //         optionText: qsTr("SH90"),
                //         source: "qrc:/images/burst_sh_90.svg",
                //         type: "optionWithImage"
                //     }
                // },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_EleFast75,
                        optionText: qsTr("SH75"),
                        source: "qrc:/images/burst_sh_75.svg",
                        type: "optionWithImage"
                    }
                },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_EleFast70,
                        optionText: qsTr("SH70"),
                        source: "qrc:/images/burst_sh_70.svg",
                        type: "optionWithImage"
                    }
                },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_EleFast60,
                        optionText: qsTr("SH60"),
                        source: "qrc:/images/burst_sh_60.svg",
                        type: "optionWithImage"
                    }
                },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_EleFast40,
                        optionText: qsTr("SH40"),
                        source: "qrc:/images/burst_sh_40.svg",
                        type: "optionWithImage"
                    }
                },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_EleFast30,
                        optionText: qsTr("SH30"),
                        source: "qrc:/images/burst_sh_30.svg",
                        type: "optionWithImage"
                    }
                },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_EleFast20,
                        optionText: qsTr("SH20"),
                        source: "qrc:/images/burst_sh_20.svg",
                        type: "optionWithImage"
                    }
                },
                // MC8223/MC8223X 23年10月FwUp（MC5229で前倒し導入）
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_EleFastPreSH,
                        optionText: qsTr("burst_SHPre"),
                        source: "qrc:/images/burst_sh_pre.svg",
                        type: "optionWithImage"
                    }
                },
                // {
                //     component: optionWithImageButtonComponent,
                //     properties: {
                //         value: LT.DeviceAdapter.BS_EleFastPre90,
                //         optionText: qsTr("SH90Pre"),
                //         source: "qrc:/images/burst_sh_90_pre.svg",
                //         type: "optionWithImage"
                //     }
                // },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_EleFastPre75,
                        optionText: qsTr("SH75Pre"),
                        source: "qrc:/images/burst_sh_75_pre.svg",
                        type: "optionWithImage"
                    }
                },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_EleFastPre70,
                        optionText: qsTr("SH70Pre"),
                        source: "qrc:/images/burst_sh_70_pre.svg",
                        type: "optionWithImage"
                    }
                },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_EleFastPre60,
                        optionText: qsTr("SH60Pre"),
                        source: "qrc:/images/burst_sh_60_pre.svg",
                        type: "optionWithImage"
                    }
                },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_EleFastPre40,
                        optionText: qsTr("SH40Pre"),
                        source: "qrc:/images/burst_sh_40_pre.svg",
                        type: "optionWithImage"
                    }
                },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_EleFastPre30,
                        optionText: qsTr("SH30Pre"),
                        source: "qrc:/images/burst_sh_30_pre.svg",
                        type: "optionWithImage"
                    }
                },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_EleFastPre20,
                        optionText: qsTr("SH20Pre"),
                        source: "qrc:/images/burst_sh_20_pre.svg",
                        type: "optionWithImage"
                    }
                },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_EleFast3,
                        optionText: qsTr("SH3"),
                        source: "qrc:/images/131_burst_sh3.svg",
                        type: "optionWithImage"
                    }
                },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_EleFast2,
                        optionText: qsTr("SH2"),
                        source: "qrc:/images/132_burst_sh2.svg",
                        type: "optionWithImage"
                    }
                },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_EleFast,
                        optionText: qsTr("SH1"),
                        source: "qrc:/images/133_burst_sh1.svg",
                        type: "optionWithImage"
                    }
                },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_EleFastPre3,
                        optionText: qsTr("SH3Pre"),
                        source: "qrc:/images/134_burst_sh3_pre.svg",
                        type: "optionWithImage"
                    }
                },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_EleFastPre2,
                        optionText: qsTr("SH2Pre"),
                        source: "qrc:/images/135_burst_sh2_pre.svg",
                        type: "optionWithImage"
                    }
                },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_EleFastPre,
                        optionText: qsTr("SH1Pre"),
                        source: "qrc:/images/136_burst_sh1_pre.svg",
                        type: "optionWithImage"
                    }
                },
        // 2020/02/14 Panasonic Kashihara >> add >> end
        // MC8241/8244
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_HighSpeedPlus,
                        optionText: qsTr("HighSpeedPlus"),
                        source: "qrc:/images/burst_h_plus.svg",
                        type: "optionWithImage"
                    }
                },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_HighSpeedPlusLiveView,
                        optionText: qsTr("HighSpeedPlusLiveView"),
                        source: "qrc:/images/burst_lv_h_plus.svg",
                        type: "optionWithImage"
                    }
                },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_HighSpeed,
                        optionText: qsTr("HighSpeed"),
                        source: "qrc:/images/127_burst_h.svg",
                        type: "optionWithImage"
                    }
                },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_HighSpeedLiveView,
                        optionText: qsTr("HighSpeedLiveView"),
                        source: "qrc:/images/128_burst_lv_h.svg",
                        type: "optionWithImage"
                    }
                },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_MiddleSpeedLiveView,
                        optionText: qsTr("MiddleSpeedLiveView"),
                        source: "qrc:/images/129_burst_lv_m.svg",
                        type: "optionWithImage"
                    }
                },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_LowSpeedLiveView,
                        optionText: qsTr("LowSpeedLiveView"),
                        source: "qrc:/images/130_burst_lv_l.svg",
                        type: "optionWithImage"
                    }
                },
                //{
                //    component: optionWithImageButtonComponent,
                //    properties: {
                //        value: LT.DeviceAdapter.BS_SH3,
                //        optionText: qsTr("SH3"),
                //        source: "qrc:/images/131_burst_sh3.svg",
                //        type: "optionWithImage"
                //    }
                //},
                //{
                //    component: optionWithImageButtonComponent,
                //    properties: {
                //        value: LT.DeviceAdapter.BS_SH2,
                //        optionText: qsTr("SH2"),
                //        source: "qrc:/images/132_burst_sh2.svg",
                //        type: "optionWithImage"
                //    }
                //},
                //{
                //    component: optionWithImageButtonComponent,
                //    properties: {
                //        value: LT.DeviceAdapter.BS_SH1,
                //        optionText: qsTr("SH1"),
                //        source: "qrc:/images/133_burst_sh1.svg",
                //        type: "optionWithImage"
                //    }
                //},
                //{
                //    component: optionWithImageButtonComponent,
                //    properties: {
                //        value: LT.DeviceAdapter.BS_SH3Pre,
                //        optionText: qsTr("SH3Pre"),
                //        source: "qrc:/images/134_burst_sh3_pre.svg",
                //        type: "optionWithImage"
                //    }
                //},
                //{
                //    component: optionWithImageButtonComponent,
                //    properties: {
                //        value: LT.DeviceAdapter.BS_SH2Pre,
                //        optionText: qsTr("SH2Pre"),
                //        source: "qrc:/images/135_burst_sh2_pre.svg",
                //        type: "optionWithImage"
                //    }
                //},
                //{
                //    component: optionWithImageButtonComponent,
                //    properties: {
                //        value: LT.DeviceAdapter.BS_SH1Pre,
                //        optionText: qsTr("SH1Pre"),
                //        source: "qrc:/images/136_burst_sh1_pre.svg",
                //        type: "optionWithImage"
                //    }
                //},
                //{
                //    component: optionWithImageButtonComponent,
                //    properties: {
                //        value: LT.DeviceAdapter.BS_H,
                //        optionText: qsTr("H"),
                //        source: "qrc:/images/button_placeholder.svg",
                //        type: "optionWithImage"
                //    }
                //},
                //{
                //    component: optionWithImageButtonComponent,
                //    properties: {
                //        value: LT.DeviceAdapter.BS_L_8fps,
                //        optionText: qsTr("L_8fps"),
                //        source: "qrc:/images/138_burst_h_8fps.svg",
                //        type: "optionWithImage"
                //    }
                //},
                //{
                //    component: optionWithImageButtonComponent,
                //    properties: {
                //        value: LT.DeviceAdapter.BS_L_5fps,
                //        optionText: qsTr("L_5fps"),
                //        source: "qrc:/images/139_burst_h_5fps.svg",
                //        type: "optionWithImage"
                //    }
                //},
                //{
                //    component: optionWithImageButtonComponent,
                //    properties: {
                //        value: LT.DeviceAdapter.BS_L_4fps,
                //        optionText: qsTr("L_4fps"),
                //        source: "qrc:/images/140_burst_h_4fps.svg",
                //        type: "optionWithImage"
                //    }
                //},
                //{
                //    component: optionWithImageButtonComponent,
                //    properties: {
                //        value: LT.DeviceAdapter.BS_L_3fps,
                //        optionText: qsTr("L_3fps"),
                //        source: "qrc:/images/141_burst_h_3fps.svg",
                //        type: "optionWithImage"
                //    }
                //},
                //{
                //    component: optionWithImageButtonComponent,
                //    properties: {
                //        value: LT.DeviceAdapter.BS_L_2fps,
                //        optionText: qsTr("L_2fps"),
                //        source: "qrc:/images/142_burst_h_2fps.svg",
                //        type: "optionWithImage"
                //    }
                //},
    ]

    /*!
        連写速度2を選択する LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var burstSpeed2: [
        // 2020/02/14 Panasonic Kashihara >> add >> start
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_6K4K,
                        optionText: qsTr("6K/4K"),
                        source: "qrc:/images/6k_photo.svg",
                        type: "optionWithImage"
                    }
                },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_EleFastSH,
                        optionText: qsTr("burst_SH"),
                        source: "qrc:/images/burst_sh.svg",
                        type: "optionWithImage"
                    }
                },
                // {
                //     component: optionWithImageButtonComponent,
                //     properties: {
                //         value: LT.DeviceAdapter.BS_EleFast90,
                //         optionText: qsTr("SH90"),
                //         source: "qrc:/images/burst_sh_90.svg",
                //         type: "optionWithImage"
                //     }
                // },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_EleFast75,
                        optionText: qsTr("SH75"),
                        source: "qrc:/images/burst_sh_75.svg",
                        type: "optionWithImage"
                    }
                },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_EleFast70,
                        optionText: qsTr("SH70"),
                        source: "qrc:/images/burst_sh_70.svg",
                        type: "optionWithImage"
                    }
                },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_EleFast60,
                        optionText: qsTr("SH60"),
                        source: "qrc:/images/burst_sh_60.svg",
                        type: "optionWithImage"
                    }
                },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_EleFast40,
                        optionText: qsTr("SH40"),
                        source: "qrc:/images/burst_sh_40.svg",
                        type: "optionWithImage"
                    }
                },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_EleFast30,
                        optionText: qsTr("SH30"),
                        source: "qrc:/images/burst_sh_30.svg",
                        type: "optionWithImage"
                    }
                },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_EleFast20,
                        optionText: qsTr("SH20"),
                        source: "qrc:/images/burst_sh_20.svg",
                        type: "optionWithImage"
                    }
                },
                // MC8223/MC8223X 23年10月FwUp（MC5229で前倒し導入）
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_EleFastPreSH,
                        optionText: qsTr("burst_SHPre"),
                        source: "qrc:/images/burst_sh_pre.svg",
                        type: "optionWithImage"
                    }
                },
                // {
                //     component: optionWithImageButtonComponent,
                //     properties: {
                //         value: LT.DeviceAdapter.BS_EleFastPre90,
                //         optionText: qsTr("SH90Pre"),
                //         source: "qrc:/images/burst_sh_90_pre.svg",
                //         type: "optionWithImage"
                //     }
                // },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_EleFastPre75,
                        optionText: qsTr("SH75Pre"),
                        source: "qrc:/images/burst_sh_75_pre.svg",
                        type: "optionWithImage"
                    }
                },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_EleFastPre70,
                        optionText: qsTr("SH70Pre"),
                        source: "qrc:/images/burst_sh_70_pre.svg",
                        type: "optionWithImage"
                    }
                },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_EleFastPre60,
                        optionText: qsTr("SH60Pre"),
                        source: "qrc:/images/burst_sh_60_pre.svg",
                        type: "optionWithImage"
                    }
                },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_EleFastPre40,
                        optionText: qsTr("SH40Pre"),
                        source: "qrc:/images/burst_sh_40_pre.svg",
                        type: "optionWithImage"
                    }
                },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_EleFastPre30,
                        optionText: qsTr("SH30Pre"),
                        source: "qrc:/images/burst_sh_30_pre.svg",
                        type: "optionWithImage"
                    }
                },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_EleFastPre20,
                        optionText: qsTr("SH20Pre"),
                        source: "qrc:/images/burst_sh_20_pre.svg",
                        type: "optionWithImage"
                    }
                },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_EleFast3,
                        optionText: qsTr("SH3"),
                        source: "qrc:/images/131_burst_sh3.svg",
                        type: "optionWithImage"
                    }
                },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_EleFast2,
                        optionText: qsTr("SH2"),
                        source: "qrc:/images/132_burst_sh2.svg",
                        type: "optionWithImage"
                    }
                },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_EleFast,
                        optionText: qsTr("SH1"),
                        source: "qrc:/images/133_burst_sh1.svg",
                        type: "optionWithImage"
                    }
                },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_EleFastPre3,
                        optionText: qsTr("SH3Pre"),
                        source: "qrc:/images/134_burst_sh3_pre.svg",
                        type: "optionWithImage"
                    }
                },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_EleFastPre2,
                        optionText: qsTr("SH2Pre"),
                        source: "qrc:/images/135_burst_sh2_pre.svg",
                        type: "optionWithImage"
                    }
                },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_EleFastPre,
                        optionText: qsTr("SH1Pre"),
                        source: "qrc:/images/136_burst_sh1_pre.svg",
                        type: "optionWithImage"
                    }
                },
        // 2020/02/14 Panasonic Kashihara >> add >> end
        // MC8241/8244
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_HighSpeedPlus,
                        optionText: qsTr("HighSpeedPlus"),
                        source: "qrc:/images/burst_h_plus.svg",
                        type: "optionWithImage"
                    }
                },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_HighSpeedPlusLiveView,
                        optionText: qsTr("HighSpeedPlusLiveView"),
                        source: "qrc:/images/burst_lv_h_plus.svg",
                        type: "optionWithImage"
                    }
                },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_HighSpeed,
                        optionText: qsTr("HighSpeed"),
                        source: "qrc:/images/127_burst_h.svg",
                        type: "optionWithImage"
                    }
                },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_HighSpeedLiveView,
                        optionText: qsTr("HighSpeedLiveView"),
                        source: "qrc:/images/128_burst_lv_h.svg",
                        type: "optionWithImage"
                    }
                },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_MiddleSpeedLiveView,
                        optionText: qsTr("MiddleSpeedLiveView"),
                        source: "qrc:/images/129_burst_lv_m.svg",
                        type: "optionWithImage"
                    }
                },
                {
                    component: optionWithImageButtonComponent,
                    properties: {
                        value: LT.DeviceAdapter.BS_LowSpeedLiveView,
                        optionText: qsTr("LowSpeedLiveView"),
                        source: "qrc:/images/130_burst_lv_l.svg",
                        type: "optionWithImage"
                    }
                },
                //{
                //    component: optionWithImageButtonComponent,
                //    properties: {
                //        value: LT.DeviceAdapter.BS_SH3,
                //        optionText: qsTr("SH3"),
                //        source: "qrc:/images/131_burst_sh3.svg",
                //        type: "optionWithImage"
                //    }
                //},
                //{
                //    component: optionWithImageButtonComponent,
                //    properties: {
                //        value: LT.DeviceAdapter.BS_SH2,
                //        optionText: qsTr("SH2"),
                //        source: "qrc:/images/132_burst_sh2.svg",
                //        type: "optionWithImage"
                //    }
                //},
                //{
                //    component: optionWithImageButtonComponent,
                //    properties: {
                //        value: LT.DeviceAdapter.BS_SH1,
                //        optionText: qsTr("SH1"),
                //        source: "qrc:/images/133_burst_sh1.svg",
                //        type: "optionWithImage"
                //    }
                //},
                //{
                //    component: optionWithImageButtonComponent,
                //    properties: {
                //        value: LT.DeviceAdapter.BS_SH3Pre,
                //        optionText: qsTr("SH3Pre"),
                //        source: "qrc:/images/134_burst_sh3_pre.svg",
                //        type: "optionWithImage"
                //    }
                //},
                //{
                //    component: optionWithImageButtonComponent,
                //    properties: {
                //        value: LT.DeviceAdapter.BS_SH2Pre,
                //        optionText: qsTr("SH2Pre"),
                //        source: "qrc:/images/135_burst_sh2_pre.svg",
                //        type: "optionWithImage"
                //    }
                //},
                //{
                //    component: optionWithImageButtonComponent,
                //    properties: {
                //        value: LT.DeviceAdapter.BS_SH1Pre,
                //        optionText: qsTr("SH1Pre"),
                //        source: "qrc:/images/136_burst_sh1_pre.svg",
                //        type: "optionWithImage"
                //    }
                //},
                //{
                //    component: optionWithImageButtonComponent,
                //    properties: {
                //        value: LT.DeviceAdapter.BS_H,
                //        optionText: qsTr("H"),
                //        source: "qrc:/images/button_placeholder.svg",
                //        type: "optionWithImage"
                //    }
                //},
                //{
                //    component: optionWithImageButtonComponent,
                //    properties: {
                //        value: LT.DeviceAdapter.BS_L_8fps,
                //        optionText: qsTr("L_8fps"),
                //        source: "qrc:/images/138_burst_h_8fps.svg",
                //        type: "optionWithImage"
                //    }
                //},
                //{
                //    component: optionWithImageButtonComponent,
                //    properties: {
                //        value: LT.DeviceAdapter.BS_L_5fps,
                //        optionText: qsTr("L_5fps"),
                //        source: "qrc:/images/139_burst_h_5fps.svg",
                //        type: "optionWithImage"
                //    }
                //},
                //{
                //    component: optionWithImageButtonComponent,
                //    properties: {
                //        value: LT.DeviceAdapter.BS_L_4fps,
                //        optionText: qsTr("L_4fps"),
                //        source: "qrc:/images/140_burst_h_4fps.svg",
                //        type: "optionWithImage"
                //    }
                //},
                //{
                //    component: optionWithImageButtonComponent,
                //    properties: {
                //        value: LT.DeviceAdapter.BS_L_3fps,
                //        optionText: qsTr("L_3fps"),
                //        source: "qrc:/images/141_burst_h_3fps.svg",
                //        type: "optionWithImage"
                //    }
                //},
                //{
                //    component: optionWithImageButtonComponent,
                //    properties: {
                //        value: LT.DeviceAdapter.BS_L_2fps,
                //        optionText: qsTr("L_2fps"),
                //        source: "qrc:/images/142_burst_h_2fps.svg",
                //        type: "optionWithImage"
                //    }
                //},
    ]

    /*!
        ドライブモードダイアル用　全連写速度を選択する LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var burstSpeedAll: [
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_EleFastSH,
                optionText: qsTr("burst_SH"),
                source: "qrc:/images/burst_sh.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_EleFast40,
                optionText: qsTr("SH40"),
                source: "qrc:/images/burst_sh_40.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_EleFast20,
                optionText: qsTr("SH20"),
                source: "qrc:/images/burst_sh_20.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_EleFast60,
                optionText: qsTr("SH60"),
                source: "qrc:/images/burst_sh_60.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_EleFast30,
                optionText: qsTr("SH30"),
                source: "qrc:/images/burst_sh_30.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_EleFast75,
                optionText: qsTr("SH75"),
                source: "qrc:/images/burst_sh_75.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_EleFast70,
                optionText: qsTr("SH70"),
                source: "qrc:/images/burst_sh_70.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_EleFastPreSH,
                optionText: qsTr("burst_SHPre"),
                source: "qrc:/images/burst_sh_pre.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_EleFastPre40,
                optionText: qsTr("SH40Pre"),
                source: "qrc:/images/burst_sh_40_pre.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_EleFastPre20,
                optionText: qsTr("SH20Pre"),
                source: "qrc:/images/burst_sh_20_pre.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_EleFastPre60,
                optionText: qsTr("SH60Pre"),
                source: "qrc:/images/burst_sh_60_pre.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_EleFastPre30,
                optionText: qsTr("SH30Pre"),
                source: "qrc:/images/burst_sh_30_pre.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_EleFastPre75,
                optionText: qsTr("SH75Pre"),
                source: "qrc:/images/burst_sh_75_pre.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_EleFastPre70,
                optionText: qsTr("SH70Pre"),
                source: "qrc:/images/burst_sh_70_pre.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_HighSpeedPlus,
                optionText: qsTr("HighSpeedPlus"),
                source: "qrc:/images/burst_h_plus.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_HighSpeedPlusLiveView,
                optionText: qsTr("HighSpeedPlusLiveView"),
                source: "qrc:/images/burst_lv_h_plus.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_HighSpeed,
                optionText: qsTr("HighSpeed"),
                source: "qrc:/images/127_burst_h.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_HighSpeedLiveView,
                optionText: qsTr("HighSpeedLiveView"),
                source: "qrc:/images/128_burst_lv_h.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_MiddleSpeedLiveView,
                optionText: qsTr("MiddleSpeedLiveView"),
                source: "qrc:/images/129_burst_lv_m.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_LowSpeedLiveView,
                optionText: qsTr("LowSpeedLiveView"),
                source: "qrc:/images/130_burst_lv_l.svg",
                type: "optionWithImage"
            }
        },
        //value: LT.DeviceAdapter.BS_Mid,
        //value: LT.DeviceAdapter.BS_Low,
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_EleFast,
                optionText: qsTr("SH1"),
                source: "qrc:/images/133_burst_sh1.svg",
                type: "optionWithImage"
            }
        },
        //value: LT.DeviceAdapter.BS_EleFastLiveView,
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_EleFast2,
                optionText: qsTr("SH2"),
                source: "qrc:/images/132_burst_sh2.svg",
                type: "optionWithImage"
            }
        },
        //value: LT.DeviceAdapter.BS_EleFastLiveView2,
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_EleFastPre,
                optionText: qsTr("SH1Pre"),
                source: "qrc:/images/136_burst_sh1_pre.svg",
                type: "optionWithImage"
            }
        },
        //value: LT.DeviceAdapter.BS_EleFastPreLiveView,
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_EleFastPre2,
                optionText: qsTr("SH2Pre"),
                source: "qrc:/images/135_burst_sh2_pre.svg",
                type: "optionWithImage"
            }
        },
        //value: LT.DeviceAdapter.BS_EleFastPreLiveView2,
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_6K4K,
                optionText: qsTr("6K/4K"),
                source: "qrc:/images/6k_photo.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_EleFast3,
                optionText: qsTr("SH3"),
                source: "qrc:/images/131_burst_sh3.svg",
                type: "optionWithImage"
            }
        },
        //value: LT.DeviceAdapter.BS_EleFastLiveView3,
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.BS_EleFastPre3,
                optionText: qsTr("SH3Pre"),
                source: "qrc:/images/134_burst_sh3_pre.svg",
                type: "optionWithImage"
            }
        },
        //value: LT.DeviceAdapter.BS_EleFastPreLiveView3,
        //value: LT.DeviceAdapter.BS_EleFastLiveView20,
        //value: LT.DeviceAdapter.BS_EleFastPreLiveView20,
        //value: LT.DeviceAdapter.BS_EleFastLiveView60,
        //value: LT.DeviceAdapter.BS_EleFastPreLiveView60,
        //value: LT.DeviceAdapter.BS_EleFastLiveView75,
        //value: LT.DeviceAdapter.BS_EleFastPreLiveView75,
        //value: LT.DeviceAdapter.BS_EleFastLiveViewSH,
        //value: LT.DeviceAdapter.BS_EleFastLiveViewPreSH,
    ]

    /*!
        フォーカスセレクトを選択する LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var focusSelect: [
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.FS_6K_18M,
                optionText: qsTr("6K_18M"),
                source: "qrc:/images/184_6k_18m.svg",
                type: "optionWithImage",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.FS_4K_8M,
                optionText: qsTr("4K_8M"),
                source: "qrc:/images/185_4k_8m.svg",
                type: "optionWithImage",
            }
        },
    ]

    /*!
        セルフタイマーを選択する LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var selfTimer: [
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.SFT_10s,
                optionText: qsTr("SFT_10s"),
                source: "qrc:/images/186_selftimer_10m.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.SFT_10s_3,
                optionText: qsTr("SFT_10s_3"),
                source: "qrc:/images/187_selftimer_10m_3.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.SFT_2s,
                optionText: qsTr("SFT_2s"),
                source: "qrc:/images/188_selftimer_2.svg",
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.SFT_Custom,
                optionText: qsTr("SFT_Custom"),
                source: "qrc:/images/selftimer_c3.svg",
                type: "optionWithImage"
            }
        },
    ]

    /*!
        セルフタイマーカスタムを選択する LTOptionButtonPopup に表示するコンポーネントの組です
        optionImage はセルフタイマーを選択する LTOptionButtonPopup で使用する
     */
    readonly property var selfTimerCustom: [
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SFT_10s"),
                optionImage: "qrc:/images/selftimer_c10.svg",
                value: LT.Utilities.SFT_C_10s,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SFT_9s"),
                optionImage: "qrc:/images/selftimer_c9.svg",
                value: LT.Utilities.SFT_C_9s,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SFT_8s"),
                optionImage: "qrc:/images/selftimer_c8.svg",
                value: LT.Utilities.SFT_C_8s,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SFT_7s"),
                optionImage: "qrc:/images/selftimer_c7.svg",
                value: LT.Utilities.SFT_C_7s,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SFT_6s"),
                optionImage: "qrc:/images/selftimer_c6.svg",
                value: LT.Utilities.SFT_C_6s,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SFT_5s"),
                optionImage: "qrc:/images/selftimer_c5.svg",
                value: LT.Utilities.SFT_C_5s,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SFT_4s"),
                optionImage: "qrc:/images/selftimer_c4.svg",
                value: LT.Utilities.SFT_C_4s,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SFT_3s"),
                optionImage: "qrc:/images/selftimer_c3.svg",
                value: LT.Utilities.SFT_C_3s,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("SFT_2s"),
                optionImage: "qrc:/images/selftimer_c2.svg",
                value: LT.Utilities.SFT_C_2s,
            }
        },
    ]

    /*!
        ホワイトバランスを選択する LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var whiteBalance: [
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("WB_Auto"),
                value: LT.Utilities.WB_Auto,
                source: "qrc:/images/189_wb_awb.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("WB_Auto_Cool"),
                value: LT.Utilities.WB_Auto_Cool,
                source: "qrc:/images/190_wb_awbc.svg",
            }
        },
// ivc >> start >> No.5
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("WB_Auto_Warm"),
                value: LT.Utilities.WB_Auto_Warm,
                source: "qrc:/images/awbw.svg",
            }
        },
// ivc << end << No.5
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("WB_Daylight"),
                value: LT.Utilities.WB_Daylight,
                source: "qrc:/images/191_wb_sunny.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("WB_Cloud"),
                value: LT.Utilities.WB_Cloud,
                source: "qrc:/images/192_wb_cloudy.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("WB_Shade"),
                value: LT.Utilities.WB_Shade,
                source: "qrc:/images/193_wb_shadow.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("WB_Tengsten"),
                value: LT.Utilities.WB_Tengsten,
                source: "qrc:/images/194_wb_light.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("WB_Flash"),
                value: LT.Utilities.WB_Flash,
                source: "qrc:/images/195_wb_flash.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("WB_Keep"),
                value: LT.Utilities.WB_Keep,
                source: "qrc:/images/196_wb_wb1.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("WB_Keep2"),
                value: LT.Utilities.WB_Keep2,
                source: "qrc:/images/197_wb_wb2.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("WB_Keep3"),
                value: LT.Utilities.WB_Keep3,
                source: "qrc:/images/198_wb_wb3.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("WB_Keep4"),
                value: LT.Utilities.WB_Keep4,
                source: "qrc:/images/199_wb_wb4.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("WB_K_Set"),
                value: LT.Utilities.WB_K_Set,
                source: "qrc:/images/200_wb_k1.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("WB_K_Set2"),
                value: LT.Utilities.WB_K_Set2,
                source: "qrc:/images/201_wb_k2.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("WB_K_Set3"),
                value: LT.Utilities.WB_K_Set3,
                source: "qrc:/images/202_wb_k3.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("WB_K_Set4"),
                value: LT.Utilities.WB_K_Set4,
                source: "qrc:/images/203_wb_k4.svg",
            }
        },
    ]

    /*!
        ISO を選択する LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var iso: [
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ISO_Auto"),
                value: LT.Utilities.ISO_Auto,
                source: "qrc:/images/237_iso_auto.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ISO_I_Iso"),
                value: LT.Utilities.ISO_I_Iso,
                source: "qrc:/images/236_iso_i-iso.svg",
            }
        },
        //{
        //    component: optionWithImageButtonComponent,
        //    properties: {
        //        type: "optionWithImage",
        //        optionText: qsTr("ISO_50"),
        //        value: LT.Utilities.ISO_50,
        //        source: "qrc:/images/205_iso_50.svg",
        //    }
        //},
        //{
        //    component: optionWithImageButtonComponent,
        //    properties: {
        //        type: "optionWithImage",
        //        optionText: qsTr("ISO_64"),
        //        value: LT.Utilities.ISO_64,
        //        source: "qrc:/images/206_iso_64.svg",
        //    }
        //},
        //{
        //    component: optionWithImageButtonComponent,
        //    properties: {
        //        type: "optionWithImage",
        //        optionText: qsTr("ISO_80"),
        //        value: LT.Utilities.ISO_80,
        //        source: "qrc:/images/207_iso_80.svg",
        //    }
        //},
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ISO_100"),
                value: LT.Utilities.ISO_100,
                source: "qrc:/images/208_iso_100.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ISO_125"),
                value: LT.Utilities.ISO_125,
                source: "qrc:/images/209_iso_125.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ISO_160"),
                value: LT.Utilities.ISO_160,
                source: "qrc:/images/210_iso_160.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ISO_200"),
                value: LT.Utilities.ISO_200,
                source: "qrc:/images/211_iso_200.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ISO_250"),
                value: LT.Utilities.ISO_250,
                source: "qrc:/images/212_iso_250.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ISO_320"),
                value: LT.Utilities.ISO_320,
                source: "qrc:/images/213_iso_320.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ISO_400"),
                value: LT.Utilities.ISO_400,
                source: "qrc:/images/214_iso_400.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ISO_500"),
                value: LT.Utilities.ISO_500,
                source: "qrc:/images/215_iso_500.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ISO_640"),
                value: LT.Utilities.ISO_640,
                source: "qrc:/images/216_iso_640.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ISO_800"),
                value: LT.Utilities.ISO_800,
                source: "qrc:/images/217_iso_800.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ISO_1000"),
                value: LT.Utilities.ISO_1000,
                source: "qrc:/images/218_iso_1000.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ISO_1250"),
                value: LT.Utilities.ISO_1250,
                source: "qrc:/images/219_iso_1250.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ISO_1600"),
                value: LT.Utilities.ISO_1600,
                source: "qrc:/images/220_iso_1600.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ISO_2000"),
                value: LT.Utilities.ISO_2000,
                source: "qrc:/images/221_iso_2000.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ISO_2500"),
                value: LT.Utilities.ISO_2500,
                source: "qrc:/images/222_iso_2500.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ISO_3200"),
                value: LT.Utilities.ISO_3200,
                source: "qrc:/images/223_iso_3200.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ISO_4000"),
                value: LT.Utilities.ISO_4000,
                source: "qrc:/images/224_iso_4000.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ISO_5000"),
                value: LT.Utilities.ISO_5000,
                source: "qrc:/images/225_iso_5000.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ISO_6400"),
                value: LT.Utilities.ISO_6400,
                source: "qrc:/images/226_iso_6400.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ISO_8000"),
                value: LT.Utilities.ISO_8000,
                source: "qrc:/images/227_iso_8000.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ISO_8500"),
                value: LT.Utilities.ISO_8500,
                source: "qrc:/images/228_iso_8500.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ISO_10000"),
                value: LT.Utilities.ISO_10000,
                source: "qrc:/images/229_iso_10000.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ISO_12500"),
                value: LT.Utilities.ISO_12500,
                source: "qrc:/images/230_iso_12500.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ISO_12800"),
                value: LT.Utilities.ISO_12800,
                source: "qrc:/images/231_iso_12800.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ISO_16000"),
                value: LT.Utilities.ISO_16000,
                source: "qrc:/images/232_iso_16000.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ISO_20000"),
                value: LT.Utilities.ISO_20000,
                source: "qrc:/images/233_iso_20000.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ISO_25000"),
                value: LT.Utilities.ISO_25000,
                source: "qrc:/images/234_iso_25000.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ISO_25600"),
                value: LT.Utilities.ISO_25600,
                source: "qrc:/images/235_iso_25600.svg",
            }
        },
    ]

    /*!
        フォーカスモードを選択する LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var focusMode: [
// IVC >> Ver.1.9 >> start >> No.5.1
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("FM_AF"),
                value: LT.Utilities.FM_AF,
                source: "qrc:/images/AF.svg",
            }
        },
// IVC << Ver.1.9 << end << No.5.1
        //{
        //    component: optionWithImageButtonComponent,
        //    properties: {
        //        type: "optionWithImage",
        //        optionText: qsTr("FM_AF_Macro"),
        //        value: LT.Utilities.FM_AF_Macro,
        //        source: "qrc:/images/button_placeholder.svg",
        //    }
        //},
        //{
        //    component: optionWithImageButtonComponent,
        //    properties: {
        //        type: "optionWithImage",
        //        optionText: qsTr("FM_AF_Macro_Digi"),
        //        value: LT.Utilities.FM_AF_Macro_Digi,
        //        source: "qrc:/images/button_placeholder.svg",
        //    }
        //},
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("FM_AF_S"),
                value: LT.Utilities.FM_AF_S,
                source: "qrc:/images/369_AFS.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("FM_AF_F"),
                value: LT.Utilities.FM_AF_F,
                source: "qrc:/images/370_AFF.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("FM_AF_C"),
                value: LT.Utilities.FM_AF_C,
                source: "qrc:/images/371_AFC.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("FM_MF"),
                value: LT.Utilities.FM_MF,
                source: "qrc:/images/372_MF.svg",
            }
        },
    ]

    /*!
        AF モードを選択する LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var autoFocusMode: [
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                // ivc >> start >> No.3
                //optionText: qsTr("AFM_Face"),
                optionText: getAFM_FaceText(),
                // ivc << end << No.3
                value: LT.Utilities.AFM_Face,
                // ivc >> start >> No.3
                //source: deviceAdapter.afAnimalRecognitionEnable ? "qrc:/images/auto_recognition.svg" : "qrc:/images/374_face.svg",
                source: getAFM_FaceImg(),
                // ivc << end << No.3
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: getAFM_TrackingText(),
                value: LT.Utilities.AFM_Tracking,
                source: getAFM_TrackingImg(),
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("AFM_225Point"),
                value: LT.Utilities.AFM_225Point,
                source: "qrc:/images/376_225point.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: getAFM_FullAreaText(),
                value: LT.Utilities.AFM_FullArea,
                source: getAFM_FullAreaImg(),
            }
        },
        // ivc >> start >> No.3
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: getAFM_VertHoriText(),
                value: LT.Utilities.AFM_VertHori,
                source: getAFM_VertHoriImg(),
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("AFM_Square"),
                value: LT.Utilities.AFM_Square,
                source: "qrc:/images/rectangle.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: getAFM_EllipseText(),
                value: LT.Utilities.AFM_Ellipse,
                source: getAFM_EllipseImg(),
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: getAFM_1PointAuxText(),
                value: LT.Utilities.AFM_1PointAux,
                source: getAFM_1PointAuxImg(),
            }
        },
        // ivc << end << No.3
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("AFM_CustomVertical"),
                value: LT.Utilities.AFM_CustomVertical,
                source: "qrc:/images/532_kstm_length.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("AFM_CustomHorizon"),
                value: LT.Utilities.AFM_CustomHorizon,
                source: "qrc:/images/377_kstm.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("AFM_CustomCenter"),
                value: LT.Utilities.AFM_CustomCenter,
                source: "qrc:/images/533_kstm_center.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("AFM_CustomC1"),
                value: LT.Utilities.AFM_CustomC1,
                source: "qrc:/images/534_kstm_c1.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("AFM_CustomC2"),
                value: LT.Utilities.AFM_CustomC2,
                source: "qrc:/images/535_kstm_c2.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("AFM_CustomC3"),
                value: LT.Utilities.AFM_CustomC3,
                source: "qrc:/images/536_kstm_c3.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: getAFM_1PointText(),
                value: LT.Utilities.AFM_1Point,
                source: getAFM_1PointImg(),
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("AFM_Pinpoint"),
                value: LT.Utilities.AFM_Pinpoint,
                source: "qrc:/images/379_pinpoint.svg",
            }
        },
        // ivc >> start >> No.3
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("AFM_Custom1"),
                value: LT.Utilities.AFM_Custom1,
                source: "qrc:/images/534_kstm_c1.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("AFM_Custom2"),
                value: LT.Utilities.AFM_Custom2,
                source: "qrc:/images/535_kstm_c2.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("AFM_Custom3"),
                value: LT.Utilities.AFM_Custom3,
                source: "qrc:/images/536_kstm_c3.svg",
            }
        },
        // ivc << end << No.3
    ]

    /*!
        WB 色温度を選択する LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var whiteBalanceKSet: [
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_2500),
                value: LT.Utilities.WBK_2500,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_2550),
                value: LT.Utilities.WBK_2550,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_2600),
                value: LT.Utilities.WBK_2600,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_2650),
                value: LT.Utilities.WBK_2650,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_2700),
                value: LT.Utilities.WBK_2700,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_2800),
                value: LT.Utilities.WBK_2800,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_2850),
                value: LT.Utilities.WBK_2850,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_2900),
                value: LT.Utilities.WBK_2900,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_2950),
                value: LT.Utilities.WBK_2950,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_3000),
                value: LT.Utilities.WBK_3000,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_3100),
                value: LT.Utilities.WBK_3100,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_3200),
                value: LT.Utilities.WBK_3200,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_3300),
                value: LT.Utilities.WBK_3300,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_3400),
                value: LT.Utilities.WBK_3400,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_3500),
                value: LT.Utilities.WBK_3500,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_3600),
                value: LT.Utilities.WBK_3600,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_3700),
                value: LT.Utilities.WBK_3700,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_3800),
                value: LT.Utilities.WBK_3800,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_3900),
                value: LT.Utilities.WBK_3900,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_4000),
                value: LT.Utilities.WBK_4000,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_4100),
                value: LT.Utilities.WBK_4100,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_4200),
                value: LT.Utilities.WBK_4200,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_4300),
                value: LT.Utilities.WBK_4300,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_4400),
                value: LT.Utilities.WBK_4400,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_4500),
                value: LT.Utilities.WBK_4500,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_4600),
                value: LT.Utilities.WBK_4600,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_4700),
                value: LT.Utilities.WBK_4700,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_4800),
                value: LT.Utilities.WBK_4800,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_4900),
                value: LT.Utilities.WBK_4900,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_5000),
                value: LT.Utilities.WBK_5000,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_5100),
                value: LT.Utilities.WBK_5100,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_5200),
                value: LT.Utilities.WBK_5200,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_5300),
                value: LT.Utilities.WBK_5300,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_5400),
                value: LT.Utilities.WBK_5400,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_5500),
                value: LT.Utilities.WBK_5500,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_5600),
                value: LT.Utilities.WBK_5600,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_5700),
                value: LT.Utilities.WBK_5700,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_5800),
                value: LT.Utilities.WBK_5800,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_5900),
                value: LT.Utilities.WBK_5900,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_6000),
                value: LT.Utilities.WBK_6000,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_6100),
                value: LT.Utilities.WBK_6100,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_6200),
                value: LT.Utilities.WBK_6200,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_6300),
                value: LT.Utilities.WBK_6300,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_6400),
                value: LT.Utilities.WBK_6400,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_6500),
                value: LT.Utilities.WBK_6500,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_6600),
                value: LT.Utilities.WBK_6600,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_6700),
                value: LT.Utilities.WBK_6700,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_6800),
                value: LT.Utilities.WBK_6800,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_6900),
                value: LT.Utilities.WBK_6900,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_7000),
                value: LT.Utilities.WBK_7000,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_7100),
                value: LT.Utilities.WBK_7100,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_7200),
                value: LT.Utilities.WBK_7200,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_7300),
                value: LT.Utilities.WBK_7300,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_7400),
                value: LT.Utilities.WBK_7400,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_7500),
                value: LT.Utilities.WBK_7500,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_7600),
                value: LT.Utilities.WBK_7600,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_7700),
                value: LT.Utilities.WBK_7700,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_7800),
                value: LT.Utilities.WBK_7800,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_7900),
                value: LT.Utilities.WBK_7900,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_8000),
                value: LT.Utilities.WBK_8000,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_8100),
                value: LT.Utilities.WBK_8100,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_8200),
                value: LT.Utilities.WBK_8200,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_8300),
                value: LT.Utilities.WBK_8300,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_8400),
                value: LT.Utilities.WBK_8400,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_8500),
                value: LT.Utilities.WBK_8500,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_8600),
                value: LT.Utilities.WBK_8600,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_8700),
                value: LT.Utilities.WBK_8700,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_8800),
                value: LT.Utilities.WBK_8800,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_8900),
                value: LT.Utilities.WBK_8900,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_9000),
                value: LT.Utilities.WBK_9000,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_9100),
                value: LT.Utilities.WBK_9100,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_9200),
                value: LT.Utilities.WBK_9200,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_9300),
                value: LT.Utilities.WBK_9300,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_9400),
                value: LT.Utilities.WBK_9400,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_9500),
                value: LT.Utilities.WBK_9500,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_9600),
                value: LT.Utilities.WBK_9600,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_9700),
                value: LT.Utilities.WBK_9700,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_9800),
                value: LT.Utilities.WBK_9800,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_9900),
                value: LT.Utilities.WBK_9900,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: whiteBalanceKSetTextFormat(LT.Utilities.WBK_100000),
                value: LT.Utilities.WBK_100000,
            }
        },
    ]

    /*!
        測光モードを選択する LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var meteringMode: [
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("MM_Pattern"),
                value: LT.Utilities.MM_Pattern,
                source: "qrc:/images/393_multi.svg"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("MM_Center"),
                value: LT.Utilities.MM_Center,
                source: "qrc:/images/394_center.svg"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("MM_Spot"),
                value: LT.Utilities.MM_Spot,
                source: "qrc:/images/395_spot.svg"
            }
        },
// ivc >> start >> No.6
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("MM_Highlight"),
                value: LT.Utilities.MM_Highlight,
                source: "qrc:/images/highlight_weight_metering.svg"
            }
        },
// ivc << end << No.6
    ]

    /*!
        フォトスタイルを選択する LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var photoStyle: [
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_Remote_Camera(UE160)"),
                value: LT.Utilities.PS_Remote_Camera_UE160,
                source: "qrc:/images/ps_ptz.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_Standard"),
                value: LT.Utilities.PS_Standard,
                source: "qrc:/images/380_std..svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_Vivid"),
                value: LT.Utilities.PS_Vivid,
                source: "qrc:/images/381_vivd.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_Natural"),
                value: LT.Utilities.PS_Natural,
                source: "qrc:/images/382_nat.svg",
            }
        },
        //20秋FwUp
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_LClassicNeo"),
                value: LT.Utilities.PS_LClassicNeo,
                source: "qrc:/images/l_clas_n.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_Monochrome"),
                value: LT.Utilities.PS_Monochrome,
                source: "qrc:/images/383_mono.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_LMonochrome"),
                value: LT.Utilities.PS_LMonochrome,
                source: "qrc:/images/384_lmono.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_LandScape"),
                value: LT.Utilities.PS_LandScape,
                source: "qrc:/images/385_scny.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_Portrait"),
                value: LT.Utilities.PS_Portrait,
                source: "qrc:/images/386_port.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_Custom"),
                value: LT.Utilities.PS_Custom,
                source: "qrc:/images/387_cust1.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_Custom2"),
                value: LT.Utilities.PS_Custom2,
                source: "qrc:/images/388_cust2.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_Custom3"),
                value: LT.Utilities.PS_Custom3,
                source: "qrc:/images/389_cust3.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_Custom4"),
                value: LT.Utilities.PS_Custom4,
                source: "qrc:/images/390_cust4.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_CinelikeD"),
                value: LT.Utilities.PS_CinelikeD,
                source: "qrc:/images/391_cned.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_CinelikeV"),
                value: LT.Utilities.PS_CinelikeV,
                source: "qrc:/images/392_cnev.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_Like_709"),
                value: LT.Utilities.PS_Like_709,
                source: "qrc:/images/525_709l.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_Linear_Gamma"),
                value: LT.Utilities.PS_Linear_Gamma,
                source: "qrc:/images/524_hlg.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_V_LogL"),
                value: LT.Utilities.PS_V_Log_L,
                source: "qrc:/images/519_vlogl.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_LMonochromeD"),
                value: LT.Utilities.PS_LMonochromeD,
                source: "qrc:/images/lmono_d.svg",
            }
        },
        //20秋FwUp
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_LMonochromeS"),
                value: LT.Utilities.PS_LMonochromeS,
                source: "qrc:/images/a_l_mono_s.svg",
            }
        },
        // ivc >> start >> No.2
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_Hybrid_Grama"),
                value: LT.Utilities.PS_Hybrid_Grama,
                source: "qrc:/images/hlg.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_Flat"),
                value: LT.Utilities.PS_Flat,
                source: "qrc:/images/flat.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_PhotoStyle1"),
                value: LT.Utilities.PS_PhotoStyle1,
                source: "qrc:/images/ps_01.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_PhotoStyle2"),
                value: LT.Utilities.PS_PhotoStyle2,
                source: "qrc:/images/ps_02.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_PhotoStyle3"),
                value: LT.Utilities.PS_PhotoStyle3,
                source: "qrc:/images/ps_03.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_PhotoStyle4"),
                value: LT.Utilities.PS_PhotoStyle4,
                source: "qrc:/images/ps_04.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_PhotoStyle5"),
                value: LT.Utilities.PS_PhotoStyle5,
                source: "qrc:/images/ps_05.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_PhotoStyle6"),
                value: LT.Utilities.PS_PhotoStyle6,
                source: "qrc:/images/ps_06.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_PhotoStyle7"),
                value: LT.Utilities.PS_PhotoStyle7,
                source: "qrc:/images/ps_07.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_PhotoStyle8"),
                value: LT.Utilities.PS_PhotoStyle8,
                source: "qrc:/images/ps_08.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_PhotoStyle9"),
                value: LT.Utilities.PS_PhotoStyle9,
                source: "qrc:/images/ps_09.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_PhotoStyle10"),
                value: LT.Utilities.PS_PhotoStyle10,
                source: "qrc:/images/ps_10.svg",
            }
        },
        // ivc >> start >> #9860
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_HLG_Standard"),
                value: LT.Utilities.PS_HLG_Standard,
                source: "qrc:/images/hlg_std.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_HLG_Monochrome"),
                value: LT.Utilities.PS_HLG_Monochrome,
                source: "qrc:/images/hlg_mono.svg",
            }
        },
        // ivc << end << #9860
        // ivc << end << No.2
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_V_Log"),
                value: LT.Utilities.PS_V_Log,
                source: "qrc:/images/519_vlog.svg",
            }
        },
        // MC8241 以降　2024/7
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_CineLike_A2"),
                value: LT.Utilities.PS_CineLike_A2,
                source: "qrc:/images/cnea2.svg",
            }
        },
        // IVC >> MC893 >> start >> No.3
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_CineLike_D2"),
                value: LT.Utilities.PS_CineLike_D2,
                source: "qrc:/images/cned2.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_CineLike_V2"),
                value: LT.Utilities.PS_CineLike_V2,
                source: "qrc:/images/cnev2.svg",
            }
        },
        // IVC << MC893 << end << No.3
        {   // 2019/10/16 Panasonic Nakano
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_HLG_For_G_Series"),
                value: LT.Utilities.PS_HLG_For_G_Series,
                source: "qrc:/images/hlg_for_g.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_HLG_FullRange"),
                value: LT.Utilities.PS_HLG_FullRange,
                source: "qrc:/images/hlg_f.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_RealTime_LUT"),
                value: LT.Utilities.PS_RealTime_LUT,
                source: "qrc:/images/ps_realtime_lut.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_Leica_Monochrome"),
                value: LT.Utilities.PS_Leica_Monochrome,
                source: "qrc:/images/leica_mono.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_ARRI_LogC3"),
                value: LT.Utilities.PS_ARRI_LogC3,
                source: "qrc:/images/arri_logc3.svg",
            }
        },
    ]

    /*!
        記録画素数を選択する LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var pictureSize4by3: [
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_4by3_L"),
                value: LT.Utilities.PS_4by3_L,
                source: "qrc:/images/473_l_20m.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_4by3_M"),
                value: LT.Utilities.PS_4by3_M,
                source: "qrc:/images/474_m_10m.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_4by3_S"),
                value: LT.Utilities.PS_4by3_S,
                source: "qrc:/images/475_s_5m.svg",
            }
        },
    ]
    readonly property var pictureSize4by3Ex: [
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_4by3Ex_L"),
                value: LT.Utilities.PS_4by3Ex_L,
                source: "qrc:/images/473_l_20m.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_4by3Ex_M"),
                value: LT.Utilities.PS_4by3Ex_M,
                source: "qrc:/images/476_ex_m_10m.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_4by3Ex_S"),
                value: LT.Utilities.PS_4by3Ex_S,
                source: "qrc:/images/477_ex_s_5m.svg",
            }
        },
    ]
    readonly property var pictureSize3by2: [
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_3by2_L"),
                value: LT.Utilities.PS_3by2_L,
                source: "qrc:/images/478_l_17m.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_3by2_M"),
                value: LT.Utilities.PS_3by2_M,
                source: "qrc:/images/479_m_9m.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_3by2_S"),
                value: LT.Utilities.PS_3by2_S,
                source: "qrc:/images/480_s_45m.svg",
            }
        },
    ]
    readonly property var pictureSize3by2Ex: [
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_3by2Ex_L"),
                value: LT.Utilities.PS_3by2Ex_L,
                source: "qrc:/images/478_l_17m.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_3by2Ex_M"),
                value: LT.Utilities.PS_3by2Ex_M,
                source: "qrc:/images/481_m_9m.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_3by2Ex_S"),
                value: LT.Utilities.PS_3by2Ex_S,
                source: "qrc:/images/482_ex_s_45m.svg",
            }
        },
    ]
    readonly property var pictureSize16by9: [
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_16by9_L"),
                value: LT.Utilities.PS_16by9_L,
                source: "qrc:/images/483_l_145m.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_16by9_M"),
                value: LT.Utilities.PS_16by9_M,
                source: "qrc:/images/484_m_8m.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_16by9_S"),
                value: LT.Utilities.PS_16by9_S,
                source: "qrc:/images/485_s_2m.svg",
            }
        },
    ]
    readonly property var pictureSize16by9Ex: [
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_16by9Ex_L"),
                value: LT.Utilities.PS_16by9Ex_L,
                source: "qrc:/images/483_l_145m.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_16by9Ex_M"),
                value: LT.Utilities.PS_16by9Ex_M,
                source: "qrc:/images/486_m_8m.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_16by9Ex_S"),
                value: LT.Utilities.PS_16by9Ex_S,
                source: "qrc:/images/487_ex_s_2m.svg",
            }
        },
    ]
    readonly property var pictureSize1by1: [
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_1by1_L"),
                value: LT.Utilities.PS_1by1_L,
                source: "qrc:/images/488_l_145m.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_1by1_M"),
                value: LT.Utilities.PS_1by1_M,
                source: "qrc:/images/489_m_75m.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_1by1_S"),
                value: LT.Utilities.PS_1by1_S,
                source: "qrc:/images/490_s_35m.svg",
            }
        },
    ]
    readonly property var pictureSize1by1Ex: [
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_1by1Ex_L"),
                value: LT.Utilities.PS_1by1Ex_L,
                source: "qrc:/images/488_l_145m.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_1by1Ex_M"),
                value: LT.Utilities.PS_1by1Ex_M,
                source: "qrc:/images/491_ex_m_75m.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("PS_1by1Ex_S"),
                value: LT.Utilities.PS_1by1Ex_S,
                source: "qrc:/images/492_ex_s_35m.svg",
            }
        },
    ]

    /*!
        クオリティを選択する LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var imgInfoQuality: [
// IVC >> Ver.1.8 >> start >> No.4
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ImgInfoQ_Interlock"),
                value: LT.Utilities.ImgInfoQ_Interlock,
                source: (utilities.getLanguageType() === LT.QLocale.Japanese) ? "qrc:/images/combined_jp.svg" : "qrc:/images/combined.svg",
            }
        },
// IVC << Ver.1.8 << end << No.4
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ImgInfoQ_Fine"),
                value: LT.Utilities.ImgInfoQ_Fine,
                source: "qrc:/images/244_fine.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ImgInfoQ_Std"),
                value: LT.Utilities.ImgInfoQ_Std,
                source: "qrc:/images/245_sta.svg",
            }
        },
        //{
        //    component: optionWithImageButtonComponent,
        //    properties: {
        //        type: "optionWithImage",
        //        optionText: qsTr("ImgInfoQ_Super_Fine"),
        //        value: LT.Utilities.ImgInfoQ_Super_Fine,
        //        source: "qrc:/images/button_placeholder.svg",
        //    }
        //},
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ImgInfoQ_Raw_Fine"),
                value: LT.Utilities.ImgInfoQ_Raw_Fine,
                source: "qrc:/images/246_fine_raw.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ImgInfoQ_Raw_Std"),
                value: LT.Utilities.ImgInfoQ_Raw_Std,
                source: "qrc:/images/247_sta_raw.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ImgInfoQ_Heif_Fine"),
                value: LT.Utilities.ImgInfoQ_Heif_Fine,
                source: "qrc:/images/photo_heif_fine.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ImgInfoQ_Heif_Std"),
                value: LT.Utilities.ImgInfoQ_Heif_Std,
                source: "qrc:/images/photo_heif_std.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ImgInfoQ_Raw_Heif_Fine"),
                value: LT.Utilities.ImgInfoQ_Raw_Heif_Fine,
                source: "qrc:/images/photo_raw_heif_fine.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ImgInfoQ_Raw_Heif_Std"),
                value: LT.Utilities.ImgInfoQ_Raw_Heif_Std,
                source: "qrc:/images/photo_raw_heif_std.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ImgInfoQ_Raw"),
                value: LT.Utilities.ImgInfoQ_Raw,
                source: "qrc:/images/248_raw.svg",
            }
        },
        //{
        //    component: optionWithImageButtonComponent,
        //    properties: {
        //        type: "optionWithImage",
        //        optionText: qsTr("ImgInfoQ_Mpo_Fine"),
        //        value: LT.Utilities.ImgInfoQ_Mpo_Fine,
        //        source: "qrc:/images/button_placeholder.svg",
        //    }
        //},
        //{
        //    component: optionWithImageButtonComponent,
        //    properties: {
        //        type: "optionWithImage",
        //        optionText: qsTr("ImgInfoQ_Mpo_Std"),
        //        value: LT.Utilities.ImgInfoQ_Mpo_Std,
        //        source: "qrc:/images/button_placeholder.svg",
        //    }
        //},
        //{
        //    component: optionWithImageButtonComponent,
        //    properties: {
        //        type: "optionWithImage",
        //        optionText: qsTr("ImgInfoQ_Dng"),
        //        value: LT.Utilities.ImgInfoQ_Dng,
        //        source: "qrc:/images/button_placeholder.svg",
        //    }
        //},
        //{
        //    component: optionWithImageButtonComponent,
        //    properties: {
        //        type: "optionWithImage",
        //        optionText: qsTr("ImgInfoQ_Dng_Fine"),
        //        value: LT.Utilities.ImgInfoQ_Dng_Fine,
        //        source: "qrc:/images/button_placeholder.svg",
        //    }
        //},
        //{
        //    component: optionWithImageButtonComponent,
        //    properties: {
        //        type: "optionWithImage",
        //        optionText: qsTr("ImgInfoQ_Dng_Std"),
        //        value: LT.Utilities.ImgInfoQ_Dng_Std,
        //        source: "qrc:/images/button_placeholder.svg",
        //    }
        //},
    ]

    readonly property var imgInfoQualityJpeg: [
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ImgInfoQ_Jpeg_Fine"),
                value: LT.Utilities.ImgInfoQ_Fine,
                source: "qrc:/images/photo_jpeg_fine.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ImgInfoQ_Jpeg_Std"),
                value: LT.Utilities.ImgInfoQ_Std,
                source: "qrc:/images/photo_jpeg_std.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ImgInfoQ_Raw_Jpeg_Fine"),
                value: LT.Utilities.ImgInfoQ_Raw_Fine,
                source: "qrc:/images/photo_raw_jpeg_fine.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ImgInfoQ_Raw_Jpeg_Std"),
                value: LT.Utilities.ImgInfoQ_Raw_Std,
                source: "qrc:/images/photo_raw_jpeg_std.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ImgInfoQ_Heif_Fine"),
                value: LT.Utilities.ImgInfoQ_Heif_Fine,
                source: "qrc:/images/photo_heif_fine.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ImgInfoQ_Heif_Std"),
                value: LT.Utilities.ImgInfoQ_Heif_Std,
                source: "qrc:/images/photo_heif_std.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ImgInfoQ_Raw_Heif_Fine"),
                value: LT.Utilities.ImgInfoQ_Raw_Heif_Fine,
                source: "qrc:/images/photo_raw_heif_fine.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ImgInfoQ_Raw_Heif_Std"),
                value: LT.Utilities.ImgInfoQ_Raw_Heif_Std,
                source: "qrc:/images/photo_raw_heif_std.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ImgInfoQ_Raw"),
                value: LT.Utilities.ImgInfoQ_Raw,
                source: "qrc:/images/248_raw.svg",
            }
        },
    ]

    readonly property var imgInfoQualityHeif: [
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ImgInfoQ_Jpeg_Fine"),
                value: LT.Utilities.ImgInfoQ_Fine,
                source: "qrc:/images/244_fine.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ImgInfoQ_Jpeg_Std"),
                value: LT.Utilities.ImgInfoQ_Std,
                source: "qrc:/images/245_sta.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ImgInfoQ_Raw_Jpeg_Fine"),
                value: LT.Utilities.ImgInfoQ_Raw_Fine,
                source: "qrc:/images/246_fine_raw.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ImgInfoQ_Raw_Jpeg_Std"),
                value: LT.Utilities.ImgInfoQ_Raw_Std,
                source: "qrc:/images/247_sta_raw.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ImgInfoQ_Heif_Fine"),
                value: LT.Utilities.ImgInfoQ_Heif_Fine,
                source: "qrc:/images/photo_heif_fine.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ImgInfoQ_Heif_Std"),
                value: LT.Utilities.ImgInfoQ_Heif_Std,
                source: "qrc:/images/photo_heif_std.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ImgInfoQ_Raw_Heif_Fine"),
                value: LT.Utilities.ImgInfoQ_Raw_Heif_Fine,
                source: "qrc:/images/photo_raw_heif_fine.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ImgInfoQ_Raw_Heif_Std"),
                value: LT.Utilities.ImgInfoQ_Raw_Heif_Std,
                source: "qrc:/images/photo_raw_heif_std.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("ImgInfoQ_Raw"),
                value: LT.Utilities.ImgInfoQ_Raw,
                source: "qrc:/images/248_raw.svg",
            }
        },

    ]

    /*!
        動画記録方式を選択する LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var motionPictureFormat: [
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.MF_AVCHD,
                optionText: qsTr("MF_AVCHD")
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.MF_MP4,
                optionText: qsTr("MF_MP4")
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.MF_MP4WithLPCM,
                optionText: qsTr("MF_MP4WithLPCM")
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.MF_MOV,
                optionText: qsTr("MF_MOV")
            }
        },
    ]

// IVC >> del >> start >> USBTHRV160-26/USBTHRV160-31
//    /*!
//        動画画質方式を選択する LTOptionButtonPopup に表示するコンポーネントの組です
//     */
//    readonly property var recMovie: [
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_AVCHD_NTSC_1920_1080_60p_28m,
//                optionText: qsTr("RCMV_AVCHD_NTSC_1920_1080_60p_28m"),
//                source: "qrc:/images/249_rec_mov_fhd_28m_60p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_AVCHD_NTSC_1920_1080_60i_17m,
//                optionText: qsTr("RCMV_AVCHD_NTSC_1920_1080_60i_17m"),
//                source: "qrc:/images/250_rec_mov_fhd_17m_60i.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_AVCHD_NTSC_1920_1080_30p_24m,
//                optionText: qsTr("RCMV_AVCHD_NTSC_1920_1080_30p_24m"),
//                source: "qrc:/images/251_rec_mov_fhd_24m_30p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_AVCHD_NTSC_1920_1080_24p_24m,
//                optionText: qsTr("RCMV_AVCHD_NTSC_1920_1080_24p_24m"),
//                source: "qrc:/images/252_rec_mov_fhd_24m_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_AVCHD_PAL_1920_1080_50p_28m,
//                optionText: qsTr("RCMV_AVCHD_PAL_1920_1080_50p_28m"),
//                source: "qrc:/images/253_rec_mov_fhd_28m_50p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_AVCHD_PAL_1920_1080_50i_17m,
//                optionText: qsTr("RCMV_AVCHD_PAL_1920_1080_50i_17m"),
//                source: "qrc:/images/254_rec_mov_fhd_17m_50i.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_AVCHD_PAL_1920_1080_25p_24m,
//                optionText: qsTr("RCMV_AVCHD_PAL_1920_1080_25p_24m"),
//                source: "qrc:/images/255_rec_mov_fhd_24m_25p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_AVCHD_PAL_1920_1080_24p_24m,
//                optionText: qsTr("RCMV_AVCHD_PAL_1920_1080_24p_24m"),
//                source: "qrc:/images/252_rec_mov_fhd_24m_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        //{
//        //    component: optionWithImageButtonComponent,
//        //    properties: {
//        //        value: LT.Utilities.RCMV_MP4_NTSC_3840_2160_60p_150m,
//        //        optionText: qsTr("RCMV_MP4_NTSC_3840_2160_60p_150m"),
//        //        source: "",
//        //        type: "optionWithImage"
//        //    }
//        //},
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_NTSC_3840_2160_30p_100m,
//                optionText: qsTr("RCMV_MP4_NTSC_3840_2160_30p_100m"),
//                source: "qrc:/images/256_rec_mov_4k_100m_30p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_NTSC_3840_2160_24p_100m,
//                optionText: qsTr("RCMV_MP4_NTSC_3840_2160_24p_100m"),
//                source: "qrc:/images/257_rec_mov_4k_100m_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_NTSC_1920_1080_60p_28m,
//                optionText: qsTr("RCMV_MP4_NTSC_1920_1080_60p_28m"),
//                source: "qrc:/images/258_rec_mov_fhd_28m_60p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_NTSC_1920_1080_30p_20m,
//                optionText: qsTr("RCMV_MP4_NTSC_1920_1080_30p_20m"),
//                source: "qrc:/images/259_rec_mov_fhd_20m_30p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_NTSC_1920_1080_24p_24m,
//                optionText: qsTr("RCMV_MP4_NTSC_1920_1080_24p_24m"),
//                source: "qrc:/images/260_rec_mov_fhd_24m_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        //{
//        //    component: optionWithImageButtonComponent,
//        //    properties: {
//        //        value: LT.Utilities.RCMV_MP4_PAL_3840_2160_30p_100m,
//        //        optionText: qsTr("RCMV_MP4_PAL_3840_2160_30p_100m"),
//        //        source: "",
//        //        type: "optionWithImage"
//        //    }
//        //},
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_PAL_3840_2160_60p_150m,
//                optionText: qsTr("RCMV_MP4_PAL_3840_2160_50p_150m"),
//                source: "qrc:/images/291_rec_mov_4k_150m_8bit_50p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_PAL_3840_2160_50p_150m,
//                optionText: qsTr("RCMV_MP4_PAL_3840_2160_50p_150m"),
//                source: "qrc:/images/291_rec_mov_4k_150m_8bit_50p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_PAL_3840_2160_30p_100m,
//                optionText: qsTr("RCMV_MP4_PAL_3840_2160_30p_100m"),
//                source: "qrc:/images/256_rec_mov_4k_100m_30p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_PAL_3840_2160_25p_100m,
//                optionText: qsTr("RCMV_MP4_PAL_3840_2160_25p_100m"),
//                source: "qrc:/images/261_rec_mov_4k_100m_25p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_PAL_3840_2160_24p_100m,
//                optionText: qsTr("RCMV_MP4_PAL_3840_2160_24p_100m"),
//                source: "qrc:/images/257_rec_mov_4k_100m_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        //{
//        //    component: optionWithImageButtonComponent,
//        //    properties: {
//        //        value: LT.Utilities.RCMV_MP4_PAL_3840_2160_24p_100m,
//        //        optionText: qsTr("RCMV_MP4_PAL_3840_2160_24p_100m"),
//        //        source: "",
//        //        type: "optionWithImage"
//        //    }
//        //},
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_PAL_1920_1080_60p_28m,
//                optionText: qsTr("RCMV_MP4_PAL_1920_1080_60p_28m"),
//                source: "qrc:/images/258_rec_mov_fhd_28m_60p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_PAL_1920_1080_50p_28m,
//                optionText: qsTr("RCMV_MP4_PAL_1920_1080_50p_28m"),
//                source: "qrc:/images/262_rec_mov_fhd_28m_50p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_PAL_1920_1080_30p_20m,
//                optionText: qsTr("RCMV_MP4_PAL_1920_1080_30p_20m"),
//                source: "qrc:/images/259_rec_mov_fhd_20m_30p.svg",
//                type: "optionWithImage"
//            }
//        },
//        //{
//        //    component: optionWithImageButtonComponent,
//        //    properties: {
//        //        value: LT.Utilities.RCMV_MP4_PAL_1920_1080_30p_20m,
//        //        optionText: qsTr("RCMV_MP4_PAL_1920_1080_30p_20m"),
//        //        source: "",
//        //        type: "optionWithImage"
//        //    }
//        //},
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_PAL_1920_1080_25p_20m,
//                optionText: qsTr("RCMV_MP4_PAL_1920_1080_25p_20m"),
//                source: "qrc:/images/263_rec_mov_fhd_20m_25p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_CINEMA_1920_1080_24p_24m,
//                optionText: qsTr("RCMV_MP4_CINEMA_1920_1080_24p_24m"),
//                source: "qrc:/images/264_rec_mov_fhd_24m_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_HEVC_NTSC_3840_2160_30p_72m,
//                optionText: qsTr("RCMV_MP4_HEVC_NTSC_3840_2160_30p_72m"),
//                source: "qrc:/images/549_rec_mov_4k_72m_hevc_30p-01.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_HEVC_NTSC_3840_2160_24p_72m,
//                optionText: qsTr("RCMV_MP4_HEVC_NTSC_3840_2160_24p_72m"),
//                source: "qrc:/images/550_rec_mov_4k_72m_hevc_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_HEVC_PAL_3840_2160_25p_72m,
//                optionText: qsTr("RCMV_MP4_HEVC_PAL_3840_2160_25p_72m"),
//                source: "qrc:/images/551_rec_mov_4k_72m_hevc_25p-01.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_4096_2160_24p_10b_400m,
//                optionText: qsTr("RCMV_MP4_LPCM_NTSC_4096_2160_24p_10b_400m"),
//                source: "qrc:/images/265_rec_mov_c4k_400m_i_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_4096_2160_24p_10b_150m,
//                optionText: qsTr("RCMV_MP4_LPCM_NTSC_4096_2160_24p_10b_150m"),
//                source: "qrc:/images/266_rec_mov_c4k_150m_10bit_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_4096_2160_24p_8b_100m,
//                optionText: qsTr("RCMV_MP4_LPCM_NTSC_4096_2160_24p_8b_100m"),
//                source: "qrc:/images/267_rec_mov_c4k_100m_8bit_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_3840_2160_60p_8b_150m,
//                optionText: qsTr("RCMV_MP4_LPCM_NTSC_3840_2160_60p_8b_150m"),
//                source: "qrc:/images/268_rec_mov_4k_150m_8bit_60p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_3840_2160_30p_10b_400m,
//                optionText: qsTr("RCMV_MP4_LPCM_NTSC_3840_2160_30p_10b_400m"),
//                source: "qrc:/images/269_rec_mov_4k_400m_i_30p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_3840_2160_30p_10b_150m,
//                optionText: qsTr("RCMV_MP4_LPCM_NTSC_3840_2160_30p_10b_150m"),
//                source: "qrc:/images/270_rec_mov_4k_150m_10bit_30p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_3840_2160_30p_8b_100m,
//                optionText: qsTr("RCMV_MP4_LPCM_NTSC_3840_2160_30p_8b_100m"),
//                source: "qrc:/images/271_rec_mov_4k_100m_8bit_30p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_3840_2160_24p_10b_400m,
//                optionText: qsTr("RCMV_MP4_LPCM_NTSC_3840_2160_24p_10b_400m"),
//                source: "qrc:/images/272_rec_mov_4k_400m_i_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_3840_2160_24p_10b_150m,
//                optionText: qsTr("RCMV_MP4_LPCM_NTSC_3840_2160_24p_10b_150m"),
//                source: "qrc:/images/273_rec_mov_4k_150m_10bit_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_3840_2160_24p_8b_100m,
//                optionText: qsTr("RCMV_MP4_LPCM_NTSC_3840_2160_24p_8b_100m"),
//                source: "qrc:/images/274_rec_mov_4k_100m_8bit_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_4992_3744_30p_10b_200m_amamo,
//                optionText: qsTr("RCMV_MP4_LPCM_NTSC_4992_3744_30p_10b_200m_amamo"),
//                source: "qrc:/images/554_rec_mov_6k_200m_a_30p-01.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_4992_3744_23p_10b_200m_amamo,
//                optionText: qsTr("RCMV_MP4_LPCM_NTSC_4992_3744_23p_10b_200m_amamo"),
//                source: "qrc:/images/552_rec_mov_6k_200m_a_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_3840_2160_60p_8b_150m_amamo,
//                optionText: qsTr("RCMV_MP4_LPCM_NTSC_3840_2160_60p_8b_150m_amamo"),
//                source: "qrc:/images/275_rec_mov_4k_150m_a_60p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_3840_2160_30p_10b_400m_amamo,
//                optionText: qsTr("RCMV_MP4_LPCM_NTSC_3840_2160_30p_10b_400m_amamo"),
//                source: "qrc:/images/276_rec_mov_4k_400m_a_30p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_3840_2160_30p_10b_150m_amamo,
//                optionText: qsTr("RCMV_MP4_LPCM_NTSC_3840_2160_30p_10b_150m_amamo"),
//                source: "qrc:/images/277_rec_mov_4k_150m_a_30p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_3840_2160_30p_8b_100m_amamo,
//                optionText: qsTr("RCMV_MP4_LPCM_NTSC_3840_2160_30p_8b_100m_amamo"),
//                source: "qrc:/images/278_rec_mov_4k_100m_a_30p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_3840_2160_24p_10b_400m_amamo,
//                optionText: qsTr("RCMV_MP4_LPCM_NTSC_3840_2160_24p_10b_400m_amamo"),
//                source: "qrc:/images/279_rec_mov_4k_400m_a_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_3840_2160_24p_10b_150m_amamo,
//                optionText: qsTr("RCMV_MP4_LPCM_NTSC_3840_2160_24p_10b_150m_amamo"),
//                source: "qrc:/images/280_rec_mov_4k_150m_a_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_3840_2160_24p_8b_100m_amamo,
//                optionText: qsTr("RCMV_MP4_LPCM_NTSC_3840_2160_24p_8b_100m_amamo"),
//                source: "qrc:/images/281_rec_mov_4k_100m_a_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_1920_1080_60p_10b_200m,
//                optionText: qsTr("RCMV_MP4_LPCM_NTSC_1920_1080_60p_10b_200m"),
//                source: "qrc:/images/282_rec_mov_fhd_200m_i_60p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_1920_1080_60p_10b_100m,
//                optionText: qsTr("RCMV_MP4_LPCM_NTSC_1920_1080_60p_10b_100m"),
//                source: "qrc:/images/283_rec_mov_fhd_100m_10bit_60p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_1920_1080_60p_8b_100m,
//                optionText: qsTr("RCMV_MP4_LPCM_NTSC_1920_1080_60p_8b_100m"),
//                source: "qrc:/images/284_rec_mov_fhd_100m_8bit_60p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_1920_1080_30p_10b_200m,
//                optionText: qsTr("RCMV_MP4_LPCM_NTSC_1920_1080_30p_10b_200m"),
//                source: "qrc:/images/285_rec_mov_fhd_200m_i_30p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_1920_1080_30p_10b_100m,
//                optionText: qsTr("RCMV_MP4_LPCM_NTSC_1920_1080_30p_10b_100m"),
//                source: "qrc:/images/286_rec_mov_fhd_100m_10bit_30p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_1920_1080_30p_8b_100m,
//                optionText: qsTr("RCMV_MP4_LPCM_NTSC_1920_1080_30p_8b_100m"),
//                source: "qrc:/images/287_rec_mov_fhd_100m_8bit_30p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_1920_1080_24p_10b_200m,
//                optionText: qsTr("RCMV_MP4_LPCM_NTSC_1920_1080_24p_10b_200m"),
//                source: "qrc:/images/288_rec_mov_fhd_200m_i_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_1920_1080_24p_10b_100m,
//                optionText: qsTr("RCMV_MP4_LPCM_NTSC_1920_1080_24p_10b_100m"),
//                source: "qrc:/images/289_rec_mov_fhd_100m_10bit_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_1920_1080_24p_8b_100m,
//                optionText: qsTr("RCMV_MP4_LPCM_NTSC_1920_1080_24p_8b_100m"),
//                source: "qrc:/images/290_rec_mov_fhd_100m_8bit_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_PAL_3840_2160_50p_8b_150m,
//                optionText: qsTr("RCMV_MP4_LPCM_PAL_3840_2160_50p_8b_150m"),
//                source: "qrc:/images/291_rec_mov_4k_150m_8bit_50p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_PAL_3840_2160_25p_10b_400m,
//                optionText: qsTr("RCMV_MP4_LPCM_PAL_3840_2160_25p_10b_400m"),
//                source: "qrc:/images/292_rec_mov_4k_400m_i_25p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_PAL_3840_2160_25p_10b_150m,
//                optionText: qsTr("RCMV_MP4_LPCM_PAL_3840_2160_25p_10b_150m"),
//                source: "qrc:/images/293_rec_mov_4k_150m_10bit_25p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_PAL_3840_2160_25p_8b_100m,
//                optionText: qsTr("RCMV_MP4_LPCM_PAL_3840_2160_25p_8b_100m"),
//                source: "qrc:/images/294_rec_mov_4k_100m_8bit_25p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_PAL_4992_3744_25p_10b_200m_amamo,
//                optionText: qsTr("RCMV_MP4_LPCM_PAL_4992_3744_25p_10b_200m_amamo"),
//                source: "qrc:/images/553_rec_mov_6k_200m_a_25p-01.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_PAL_3840_2160_50p_8b_150m_amamo,
//                optionText: qsTr("RCMV_MP4_LPCM_PAL_3840_2160_50p_8b_150m_amamo"),
//                source: "qrc:/images/295_rec_mov_4k_150m_50p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_PAL_3840_2160_25p_10b_400m_amamo,
//                optionText: qsTr("RCMV_MP4_LPCM_PAL_3840_2160_25p_10b_400m_amamo"),
//                source: "qrc:/images/296_rec_mov_4k_400m_25p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_PAL_3840_2160_25p_10b_150m_amamo,
//                optionText: qsTr("RCMV_MP4_LPCM_PAL_3840_2160_25p_10b_150m_amamo"),
//                source: "qrc:/images/297_rec_mov_4k_150m_25p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_PAL_3840_2160_25p_8b_100m_amamo,
//                optionText: qsTr("RCMV_MP4_LPCM_PAL_3840_2160_25p_8b_100m_amamo"),
//                source: "qrc:/images/298_rec_mov_4k_100m_25p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_PAL_1920_1080_50p_10b_200m,
//                optionText: qsTr("RCMV_MP4_LPCM_PAL_1920_1080_50p_10b_200m"),
//                source: "qrc:/images/299_rec_mov_fhd_200m_i_50p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_PAL_1920_1080_50p_10b_100m,
//                optionText: qsTr("RCMV_MP4_LPCM_PAL_1920_1080_50p_10b_100m"),
//                source: "qrc:/images/300_rec_mov_fhd_100m_10bit_50p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_PAL_1920_1080_50p_8b_100m,
//                optionText: qsTr("RCMV_MP4_LPCM_PAL_1920_1080_50p_8b_100m"),
//                source: "qrc:/images/301_rec_mov_fhd_100m_8bit_50p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_PAL_1920_1080_25p_10b_200m,
//                optionText: qsTr("RCMV_MP4_LPCM_PAL_1920_1080_25p_10b_200m"),
//                source: "qrc:/images/302_rec_mov_fhd_200m_i_25p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_PAL_1920_1080_25p_10b_100m,
//                optionText: qsTr("RCMV_MP4_LPCM_PAL_1920_1080_25p_10b_100m"),
//                source: "qrc:/images/303_rec_mov_fhd_100m_10bit_25p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_PAL_1920_1080_25p_8b_100m,
//                optionText: qsTr("RCMV_MP4_LPCM_PAL_1920_1080_25p_8b_100m"),
//                source: "qrc:/images/304_rec_mov_fhd_100m_8bit_25p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_CINEMA_4096_2160_24p_10b_400m,
//                optionText: qsTr("RCMV_MP4_LPCM_CINEMA_4096_2160_24p_10b_400m"),
//                source: "qrc:/images/305_rec_mov_c4k_400m_i_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_CINEMA_4096_2160_24p_10b_150m,
//                optionText: qsTr("RCMV_MP4_LPCM_CINEMA_4096_2160_24p_10b_150m"),
//                source: "qrc:/images/306_rec_mov_c4k_150m_10bit_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_CINEMA_4096_2160_24p_8b_100m,
//                optionText: qsTr("RCMV_MP4_LPCM_CINEMA_4096_2160_24p_8b_100m"),
//                source: "qrc:/images/307_rec_mov_c4k_100m_8bit_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_CINEMA_3840_2160_24p_10b_400m,
//                optionText: qsTr("RCMV_MP4_LPCM_CINEMA_3840_2160_24p_10b_400m"),
//                source: "qrc:/images/308_rec_mov_4k_400m_i_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_CINEMA_3840_2160_24p_10b_150m,
//                optionText: qsTr("RCMV_MP4_LPCM_CINEMA_3840_2160_24p_10b_150m"),
//                source: "qrc:/images/309_rec_mov_4k_150m_10bit_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_CINEMA_3840_2160_24p_8b_100m,
//                optionText: qsTr("RCMV_MP4_LPCM_CINEMA_3840_2160_24p_8b_100m"),
//                source: "qrc:/images/310_rec_mov_4k_100m_8bit_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_CINEMA_4992_3744_24p_10b_200m_amamo,
//                optionText: qsTr("RCMV_MP4_LPCM_CINEMA_4992_3744_24p_10b_200m_amamo"),
//                source: "qrc:/images/552_rec_mov_6k_200m_a_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_CINEMA_3840_2160_24p_10b_400m_amamo,
//                optionText: qsTr("RCMV_MP4_LPCM_CINEMA_3840_2160_24p_10b_400m_amamo"),
//                source: "qrc:/images/311_rec_mov_4k_400m_a_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_CINEMA_3840_2160_24p_10b_150m_amamo,
//                optionText: qsTr("RCMV_MP4_LPCM_CINEMA_3840_2160_24p_10b_150m_amamo"),
//                source: "qrc:/images/312_rec_mov_4k_150m_a_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_CINEMA_3840_2160_24p_8b_100m_amamo,
//                optionText: qsTr("RCMV_MP4_LPCM_CINEMA_3840_2160_24p_8b_100m_amamo"),
//                source: "qrc:/images/313_rec_mov_4k_100m_a_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_CINEMA_1920_1080_24p_10b_200m,
//                optionText: qsTr("RCMV_MP4_LPCM_CINEMA_1920_1080_24p_10b_200m"),
//                source: "qrc:/images/314_rec_mov_fhd_200m_i_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_CINEMA_1920_1080_24p_10b_100m,
//                optionText: qsTr("RCMV_MP4_LPCM_CINEMA_1920_1080_24p_10b_100m"),
//                source: "qrc:/images/315_rec_mov_fhd_100m_10bit_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_CINEMA_1920_1080_24p_8b_100m,
//                optionText: qsTr("RCMV_MP4_LPCM_CINEMA_1920_1080_24p_8b_100m"),
//                source: "qrc:/images/316_rec_mov_fhd_100m_8bit_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_4096_2160_24p_10b_400m,
//                optionText: qsTr("RCMV_MOV_NTSC_4096_2160_24p_10b_400m"),
//                source: "qrc:/images/317_rec_mov_c4k_400m_i_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_4096_2160_24p_10b_150m,
//                optionText: qsTr("RCMV_MOV_NTSC_4096_2160_24p_10b_150m"),
//                source: "qrc:/images/318_rec_mov_c4k_150m_10bit_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_4096_2160_24p_8b_100m,
//                optionText: qsTr("RCMV_MOV_NTSC_4096_2160_24p_8b_100m"),
//                source: "qrc:/images/319_rec_mov_c4k_100m_8bit_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_3840_2160_60p_8b_150m,
//                optionText: qsTr("RCMV_MOV_NTSC_3840_2160_60p_8b_150m"),
//                source: "qrc:/images/320_rec_mov_4k_150m_8bit_60p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_3840_2160_30p_10b_400m,
//                optionText: qsTr("RCMV_MOV_NTSC_3840_2160_30p_10b_400m"),
//                source: "qrc:/images/321_rec_mov_4k_400m_i_30p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_3840_2160_30p_10b_150m,
//                optionText: qsTr("RCMV_MOV_NTSC_3840_2160_30p_10b_150m"),
//                source: "qrc:/images/322_rec_mov_4k_150m_10bit_30p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_3840_2160_30p_8b_100m,
//                optionText: qsTr("RCMV_MOV_NTSC_3840_2160_30p_8b_100m"),
//                source: "qrc:/images/323_rec_mov_4k_100m_8bit_30p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_3840_2160_24p_10b_400m,
//                optionText: qsTr("RCMV_MOV_NTSC_3840_2160_24p_10b_400m"),
//                source: "qrc:/images/324_rec_mov_4k_400m_i_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_3840_2160_24p_10b_150m,
//                optionText: qsTr("RCMV_MOV_NTSC_3840_2160_24p_10b_150m"),
//                source: "qrc:/images/325_rec_mov_4k_150m_10bit_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_3840_2160_24p_8b_100m,
//                optionText: qsTr("RCMV_MOV_NTSC_3840_2160_24p_8b_100m"),
//                source: "qrc:/images/326_rec_mov_4k_100m_8bit_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_3840_2160_60p_8b_150m_amamo,
//                optionText: qsTr("RCMV_MOV_NTSC_3840_2160_60p_8b_150m_amamo"),
//                source: "qrc:/images/327_rec_mov_4k_150m_a_60p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_3840_2160_30p_10b_400m_amamo,
//                optionText: qsTr("RCMV_MOV_NTSC_3840_2160_30p_10b_400m_amamo"),
//                source: "qrc:/images/328_rec_mov_4k_400m_a_30p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_3840_2160_30p_10b_150m_amamo,
//                optionText: qsTr("RCMV_MOV_NTSC_3840_2160_30p_10b_150m_amamo"),
//                source: "qrc:/images/329_rec_mov_4k_150m_a_30p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_3840_2160_30p_8b_100m_amamo,
//                optionText: qsTr("RCMV_MOV_NTSC_3840_2160_30p_8b_100m_amamo"),
//                source: "qrc:/images/330_rec_mov_4k_100m_a_30p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_3840_2160_24p_10b_400m_amamo,
//                optionText: qsTr("RCMV_MOV_NTSC_3840_2160_24p_10b_400m_amamo"),
//                source: "qrc:/images/331_rec_mov_4k_400m_a_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_3840_2160_24p_10b_150m_amamo,
//                optionText: qsTr("RCMV_MOV_NTSC_3840_2160_24p_10b_150m_amamo"),
//                source: "qrc:/images/332_rec_mov_4k_150m_a_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_3840_2160_24p_8b_100m_amamo,
//                optionText: qsTr("RCMV_MOV_NTSC_3840_2160_24p_8b_100m_amamo"),
//                source: "qrc:/images/333_rec_mov_4k_100m_a_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_1920_1080_60p_10b_200m,
//                optionText: qsTr("RCMV_MOV_NTSC_1920_1080_60p_10b_200m"),
//                source: "qrc:/images/334_rec_mov_fhd_200m_i_60p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_1920_1080_60p_10b_100m,
//                optionText: qsTr("RCMV_MOV_NTSC_1920_1080_60p_10b_100m"),
//                source: "qrc:/images/335_rec_mov_fhd_100m_10bit_60p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_1920_1080_60p_8b_100m,
//                optionText: qsTr("RCMV_MOV_NTSC_1920_1080_60p_8b_100m"),
//                source: "qrc:/images/336_rec_mov_fhd_100m_8bit_60p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_1920_1080_30p_10b_200m,
//                optionText: qsTr("RCMV_MOV_NTSC_1920_1080_30p_10b_200m"),
//                source: "qrc:/images/337_rec_mov_fhd_200m_i_30p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_1920_1080_30p_10b_100m,
//                optionText: qsTr("RCMV_MOV_NTSC_1920_1080_30p_10b_100m"),
//                source: "qrc:/images/338_rec_mov_fhd_100m_10bit_30p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_1920_1080_30p_8b_100m,
//                optionText: qsTr("RCMV_MOV_NTSC_1920_1080_30p_8b_100m"),
//                source: "qrc:/images/339_rec_mov_fhd_100m_8bit_30p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_1920_1080_24p_10b_200m,
//                optionText: qsTr("RCMV_MOV_NTSC_1920_1080_24p_10b_200m"),
//                source: "qrc:/images/340_rec_mov_fhd_200m_i_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_1920_1080_24p_10b_100m,
//                optionText: qsTr("RCMV_MOV_NTSC_1920_1080_24p_10b_100m"),
//                source: "qrc:/images/341_rec_mov_fhd_100m_10bit_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_1920_1080_24p_8b_100m,
//                optionText: qsTr("RCMV_MOV_NTSC_1920_1080_24p_8b_100m"),
//                source: "qrc:/images/342_rec_mov_fhd_100m_8bit_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_3840_2160_50p_8b_150m,
//                optionText: qsTr("RCMV_MOV_PAL_3840_2160_50p_8b_150m"),
//                source: "qrc:/images/343_rec_mov_4k_150m_8bit_50p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_3840_2160_25p_10b_400m,
//                optionText: qsTr("RCMV_MOV_PAL_3840_2160_25p_10b_400m"),
//                source: "qrc:/images/344_rec_mov_4k_400m_i_25p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_3840_2160_25p_8b_150m,
//                optionText: qsTr("RCMV_MOV_PAL_3840_2160_25p_8b_150m"),
//                source: "qrc:/images/345_rec_mov_4k_150m_10bit_25p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_3840_2160_25p_8b_100m,
//                optionText: qsTr("RCMV_MOV_PAL_3840_2160_25p_8b_100m"),
//                source: "qrc:/images/346_rec_mov_4k_100m_8bit_25p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_3840_2160_50p_8b_150m_amamo,
//                optionText: qsTr("RCMV_MOV_PAL_3840_2160_50p_8b_150m_amamo"),
//                source: "qrc:/images/347_rec_mov_4k_150m_50p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_3840_2160_25p_10b_400m_amamo,
//                optionText: qsTr("RCMV_MOV_PAL_3840_2160_25p_10b_400m_amamo"),
//                source: "qrc:/images/348_rec_mov_4k_400m_25p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_3840_2160_25p_8b_150m_amamo,
//                optionText: qsTr("RCMV_MOV_PAL_3840_2160_25p_8b_150m_amamo"),
//                source: "qrc:/images/349_rec_mov_4k_150m_25p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_3840_2160_25p_8b_100m_amamo,
//                optionText: qsTr("RCMV_MOV_PAL_3840_2160_25p_8b_100m_amamo"),
//                source: "qrc:/images/350_rec_mov_4k_100m_25p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_1920_1080_50p_10b_200m,
//                optionText: qsTr("RCMV_MOV_PAL_1920_1080_50p_10b_200m"),
//                source: "qrc:/images/351_rec_mov_fhd_200m_i_50p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_1920_1080_50p_10b_100m,
//                optionText: qsTr("RCMV_MOV_PAL_1920_1080_50p_10b_100m"),
//                source: "qrc:/images/352_rec_mov_fhd_100m_10bit_50p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_1920_1080_50p_8b_100m,
//                optionText: qsTr("RCMV_MOV_PAL_1920_1080_50p_8b_100m"),
//                source: "qrc:/images/353_rec_mov_fhd_100m_8bit_50p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_1920_1080_25p_10b_200m,
//                optionText: qsTr("RCMV_MOV_PAL_1920_1080_25p_10b_200m"),
//                source: "qrc:/images/354_rec_mov_fhd_200m_i_25p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_1920_1080_25p_10b_100m,
//                optionText: qsTr("RCMV_MOV_PAL_1920_1080_25p_10b_100m"),
//                source: "qrc:/images/355_rec_mov_fhd_100m_10bit_25p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_1920_1080_25p_8b_100m,
//                optionText: qsTr("RCMV_MOV_PAL_1920_1080_25p_8b_100m"),
//                source: "qrc:/images/356_rec_mov_fhd_100m_8bit_25p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_CINEMA_4096_2160_24p_10b_400m,
//                optionText: qsTr("RCMV_MOV_CINEMA_4096_2160_24p_10b_400m"),
//                source: "qrc:/images/357_rec_mov_c4k_400m_i_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_CINEMA_4096_2160_24p_10b_150m,
//                optionText: qsTr("RCMV_MOV_CINEMA_4096_2160_24p_10b_150m"),
//                source: "qrc:/images/358_rec_mov_c4k_150m_10bit_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_CINEMA_4096_2160_24p_8b_100m,
//                optionText: qsTr("RCMV_MOV_CINEMA_4096_2160_24p_8b_100m"),
//                source: "qrc:/images/359_rec_mov_c4k_100m_8bit_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_CINEMA_3840_2160_24p_10b_400m,
//                optionText: qsTr("RCMV_MOV_CINEMA_3840_2160_24p_10b_400m"),
//                source: "qrc:/images/360_rec_mov_4k_400m_i_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_CINEMA_3840_2160_24p_10b_150m,
//                optionText: qsTr("RCMV_MOV_CINEMA_3840_2160_24p_10b_150m"),
//                source: "qrc:/images/361_rec_mov_4k_150m_10bit_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_CINEMA_3840_2160_24p_8b_100m,
//                optionText: qsTr("RCMV_MOV_CINEMA_3840_2160_24p_8b_100m"),
//                source: "qrc:/images/362_rec_mov_4k_100m_8bit_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_CINEMA_3840_2160_24p_10b_400m_amamo,
//                optionText: qsTr("RCMV_MOV_CINEMA_3840_2160_24p_10b_400m_amamo"),
//                source: "qrc:/images/363_rec_mov_4k_400m_a_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_CINEMA_3840_2160_24p_10b_150m_amamo,
//                optionText: qsTr("RCMV_MOV_CINEMA_3840_2160_24p_10b_150m_amamo"),
//                source: "qrc:/images/364_rec_mov_4k_150m_a_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_CINEMA_3840_2160_24p_8b_100m_amamo,
//                optionText: qsTr("RCMV_MOV_CINEMA_3840_2160_24p_8b_100m_amamo"),
//                source: "qrc:/images/365_rec_mov_4k_100m_a_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_CINEMA_1920_1080_24p_10b_200m,
//                optionText: qsTr("RCMV_MOV_CINEMA_1920_1080_24p_10b_200m"),
//                source: "qrc:/images/366_rec_mov_fhd_200m_i_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_CINEMA_1920_1080_24p_10b_100m,
//                optionText: qsTr("RCMV_MOV_CINEMA_1920_1080_24p_10b_100m"),
//                source: "qrc:/images/367_rec_mov_fhd_100m_10bit_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_CINEMA_1920_1080_24p_8b_100m,
//                optionText: qsTr("RCMV_MOV_CINEMA_1920_1080_24p_8b_100m"),
//                source: "qrc:/images/368_rec_mov_fhd_100m_8bit_24p.svg",
//                type: "optionWithImage"
//            }
//        },

//        // --> 2019/04/17 ADD Panasonic Nakano
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_3840_2160_50p_150m,
//                optionText: qsTr("RCMV_MOV_PAL_3840_2160_50p_150m"),
//                source: "qrc:/images/291_rec_mov_4k_150m_8bit_50p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_3840_2160_25p_150m,
//                optionText: qsTr("RCMV_MOV_PAL_3840_2160_25p_150m"),
//                source: "qrc:/images/293_rec_mov_4k_150m_10bit_25p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_1920_1080_50p_100m,
//                optionText: qsTr("RCMV_MOV_PAL_1920_1080_50p_100m"),
//                source: "qrc:/images/300_rec_mov_fhd_100m_10bit_50p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_1920_1080_25p_100m,
//                optionText: qsTr("RCMV_MOV_PAL_1920_1080_25p_100m"),
//                source: "qrc:/images/303_rec_mov_fhd_100m_10bit_25p.svg",
//                type: "optionWithImage"
//            }
//        },
//        // <-- 2019/04/17 ADD Panasonic Nakano
//    ]
// IVC << del << end << USBTHRV160-26/USBTHRV160-31

    /*!
        プレビューを選択する LTOptionButtonPopup に表示するコンポーネントの組です
     */
     readonly property var recPreviewMode: [
        {
            component: optionWithImageButtonComponentForPreview,//optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RecPreviw_Expousure,
                source: "qrc:/images/431_iris.svg",
                optionText: qsTr("RecPreviw_Expousure"),
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponentForPreview,//optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RecPreviw_Exp_SS,
                source: "qrc:/images/432_iris_ss.svg",
                optionText: qsTr("RecPreviw_Exp_SS"),
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponentForPreview,//optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.RecPreviw_Off,
                source: "qrc:/images/433_off.svg",
                optionText: qsTr("RecPreviw_Off"),
                type: "optionWithImage"
            }
        },
    ]

     // IVC >> Ver.1.7 >> start >> No.1
     /*!
         ライブビュー画質を選択する LTOptionButtonPopup
      */
      readonly property var imageQuality: [
         {
             component: optionWithImageButtonComponentForImgQuality,
             properties: {
                 value: LT.Utilities.LvImgQ_Fine,
                 source: "qrc:/images/lv_quality_fine.svg",
                 optionText: qsTr("LvImgQ_Fine"),
                 optionOriginalText: qsTr("LvImgQ_Fine"),
                 type: "optionWithImage"
             }
         },
         {
             component: optionWithImageButtonComponentForImgQuality,
             properties: {
                 value: LT.DeviceAdapter.LvImgQ_Std,
                 source: "qrc:/images/lv_quality_std.svg",
                 optionText: qsTr("LvImgQ_Std"),
                 optionOriginalText: qsTr("LvImgQ_Std"),
                 type: "optionWithImage"
             }
         },
         {
             component: optionWithImageButtonComponentForImgQuality,
             properties: {
                 value: LT.DeviceAdapter.LvImgQ_Low,
                 source: "qrc:/images/lv_quality_low.svg",
                 optionText: qsTr("LvImgQ_Low"),
                 optionOriginalText: qsTr("LvImgQ_Low"),
                 type: "optionWithImage"
             }
         }
     ]
     // IVC << Ver.1.7 << end << No.1

     /*!
        アスペクト比を選択する LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var imgInfoAspect: [
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.Utilities.ImgInfoA_Normal_4_3,
                source: "qrc:/images/445_4_3.svg",
                optionText: qsTr("AR_Nomal_4_3"),
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
               value: LT.Utilities.ImgInfoA_Film_3_2,
                source: "qrc:/images/446_3_2.svg",
                optionText: qsTr("AR_Film_3_2"),
                type: "optionWithImagetoText"
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.Utilities.ImgInfoA_Hdtv_16_9,
                source: "qrc:/images/447_16_9.svg",
                optionText: qsTr("AR_Hdtv_16_9"),
                type: "optionWithImagetoText"
            }
        },
        {
             component: optionWithImageButtonComponent,
             properties: {
                value: LT.Utilities.ImgInfoA_Blog_1_1,
                source: "qrc:/images/448_1_1.svg",
                optionText: qsTr("AR_Blog_1_1"),
                type: "optionWithImagetoText"
            }
        },
    ]

    /*!
         アスペクト比を選択する LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var aspectRatio: [
// ivc >> start >> No.7  
        {
            component: optionWithImageButtonComponentForAspect,
            properties: {
                value: LT.DeviceAdapter.AR_Error,
                source: "qrc:/images/button_placeholder.svg",
                optionText: qsTr("AR_Error"),
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponentForAspect,
            properties: {
                value: LT.DeviceAdapter.AR_Nomal_4_3,
                source: "qrc:/images/445_4_3.svg",
                optionText: qsTr("AR_Nomal_4_3"),
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponentForAspect,
            properties: {
                value: LT.DeviceAdapter.AR_Film_3_2,
                source: "qrc:/images/446_3_2.svg",
                optionText: qsTr("AR_Film_3_2"),
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponentForAspect,
            properties: {
                value: LT.DeviceAdapter.AR_Hdtv_16_9,
                source: "qrc:/images/447_16_9.svg",
                optionText: qsTr("AR_Hdtv_16_9"),
                type: "optionWithImage"
            }
        },
        {
            component: optionWithImageButtonComponentForAspect,
            properties: {
                value: LT.DeviceAdapter.AR_Blog_1_1,
                source: "qrc:/images/448_1_1.svg",
                optionText: qsTr("AR_Blog_1_1"),
                type: "optionWithImage"
            }
        },
        {
             component: optionWithImageButtonComponentForAspect,
             properties: {
                value: LT.DeviceAdapter.AR_65_24,
                source: "qrc:/images/65_24.svg",
                optionText: qsTr("AR_Blog_65_24"),
                type: "optionWithImage"
            }
        },
        {
             component: optionWithImageButtonComponentForAspect,
             properties: {
                value: LT.DeviceAdapter.AR_2_1,
                source: "qrc:/images/2_1.svg",
                optionText: qsTr("AR_Blog_2_1"),
                type: "optionWithImage"
            }
        },
// ivc << end << No.7
    ]

///////////////////////////////////////////////////////////////////////////////
/// flashWindow
///////////////////////////////////////////////////////////////////////////////
    /*!
        FlashDimmer LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var flashDimmer: [
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                value: LT.Utilities.FlshDim_TTL,
                optionText: qsTr("FlshDim_TTL")
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                value: LT.Utilities.FlshDim_Manual,
                optionText: qsTr("FlshDim_Manual")
            }
        }
    ]

    /*!
        FlashMode LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var flashMode: [
        {   // 2019/10/25 Panasonic Nakano
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("FlshM_Auto"),
                value: LT.Utilities.FlshM_Auto,
                source: "qrc:/images/flash_auto.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("FlshM_Forced"),
                value: LT.Utilities.FlshM_Forced,
                source: "qrc:/images/403_frash.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("FlshM_ForcedRedEye"),
                value: LT.Utilities.FlshM_ForcedRedEye,
                source: "qrc:/images/404_redeye.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("FlshM_SlowSync"),
                value: LT.Utilities.FlshM_SlowSync,
                source: "qrc:/images/405_slow.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("FlshM_SlowRedEye"),
                value: LT.Utilities.FlshM_SlowRedEye,
                source: "qrc:/images/406_redeye_slow.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage",
                optionText: qsTr("FlshM_Forbid"),
                value: LT.Utilities.FlshM_Forbid,
                source: "qrc:/images/407_no_frash.svg",
            }
        },
    ]

    /*!
        FlashSync LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var flashSync: [
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                value: LT.Utilities.FlshS_Front,
                optionText: qsTr("FlshS_Front")
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                value: LT.Utilities.FlshS_Rear,
                optionText: qsTr("FlshS_Rear")
            }
        }
    ]

    /*!
        ExposureLink LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var exposureLink: [
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                value: LT.Utilities.ExpL_On,
                optionText: qsTr("ExpL_On")
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                value: LT.Utilities.ExpL_Off,
                optionText: qsTr("ExpL_Off")
            }
        }
    ]

    /*!
        WirelessMode LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var wirelessMode: [
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.WirM_On,
                source: "qrc:/images/button_placeholder.svg",
                optionText: qsTr("WirM_On")
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                value: LT.DeviceAdapter.WirM_Off,
                source: "qrc:/images/button_placeholder.svg",
                optionText: qsTr("WirM_Off")
            }
        },
    ]

    /*!
        WirelessChannel LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var wirelessChannel: [
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                value: LT.Utilities.WirC_Ch1,
                optionText: qsTr("WirC_Ch1")
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                value: LT.Utilities.WirC_Ch2,
                optionText: qsTr("WirC_Ch2")
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                value: LT.Utilities.WirC_Ch3,
                optionText: qsTr("WirC_Ch3")
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                value: LT.Utilities.WirC_Ch4,
                optionText: qsTr("WirC_Ch4")
            }
        }
    ]

    /*!
        WirelessFP LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var wirelessFP: [
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                value: LT.Utilities.WirFP_On,
                optionText: qsTr("WirFP_On")
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                value: LT.Utilities.WirFP_Off,
                optionText: qsTr("WirFP_Off")
            }
        }
    ]

    /*!
        WirelessComPower LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var wirelessComPower: [
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                value: LT.Utilities.WirCP_High,
                optionText: qsTr("WirCP_High")
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                value: LT.Utilities.WirCP_Mid,
                optionText: qsTr("WirCP_Mid")
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                value: LT.Utilities.WirCP_Low,
                optionText: qsTr("WirCP_Low")
            }
        }
    ]

    /*!
        BuildInFlashMode LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var buildInFlashDimmer: [
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("BIFD_TTL"),
                value: LT.Utilities.BIFD_TTL,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                //Fixed for translated external dimmer (USBTHRV140-95)
                optionText: qsTr("GFD_Auto"),
                value: LT.Utilities.BIFD_Signal,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("BIFD_Manual"),
                value: LT.Utilities.BIFD_Manual,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("BIFD_Off"),
                value: LT.Utilities.BIFD_Off,
            }
        }
    ]

    /*!
        AGroupMode LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var aGroupDimmer: [
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("GFD_TTL"),
                value: LT.Utilities.GFD_TTL,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("GFD_Auto"),
                value: LT.Utilities.GFD_Auto,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("GFD_Manual"),
                value: LT.Utilities.GFD_Manual,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("GFD_Off"),
                value: LT.Utilities.GFD_Off,
            }
        }
    ]

    /*!
        BGroupMode LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var bGroupDimmer: [
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("GFD_TTL"),
                value: LT.Utilities.GFD_TTL,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("GFD_Auto"),
                value: LT.Utilities.GFD_Auto,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("GFD_Manual"),
                value: LT.Utilities.GFD_Manual,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("GFD_Off"),
                value: LT.Utilities.GFD_Off,
            }
        }
    ]

    /*!
        CGroupMode LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var cGroupDimmer: [
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("GFD_TTL"),
                value: LT.Utilities.GFD_TTL,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("GFD_Auto"),
                value: LT.Utilities.GFD_Auto,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("GFD_Manual"),
                value: LT.Utilities.GFD_Manual,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledText",
                optionText: qsTr("GFD_Off"),
                value: LT.Utilities.GFD_Off,
            }
        }
    ]

///////////////////////////////////////////////////////////////////////////////
/// preferenceWindow
///////////////////////////////////////////////////////////////////////////////
    /*!
        Image viewer LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var imageViewerType: [
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.ApplicationSettings.ImageViewerType_Std,
                optionText: qsTr("Standard Viewer")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.ApplicationSettings.ImageViewerType_Ext,
                optionText: qsTr("External Viewer")
            }
        },
    ]

    /*!
        Store Location LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var storeLocationType: [
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.ApplicationSettings.StoLocType_SdCard,
                optionText: qsTr("SD Card")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.ApplicationSettings.StoLocType_SdCardPc,
                optionText: qsTr("SD Card + PC")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.ApplicationSettings.StoLocType_Pc,
                optionText: qsTr("PC")
            }
        },
    ]

    /*!
        Store Folder LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var storeFolderType: [
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.ApplicationSettings.StoFolderType_Default,
                optionText: utilities.isMac() ? qsTr("Default Folder(Mac)") : qsTr("Default Folder(Win)")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.ApplicationSettings.StoFolderType_User,
                optionText: qsTr("User Setting")
            }
        },
    ]

    /*!
        Store Folder LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var storeFolderDate: [
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.ApplicationSettings.StoFolderDate_On,
                optionText: qsTr("ON")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.ApplicationSettings.StoFolderDate_Off,
                optionText: qsTr("OFF")
            }
        },
    ]

    /*!
        Store Folder LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var storeFolderCamera: [
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.ApplicationSettings.StoFolderCamera_On,
                optionText: qsTr("ON")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.ApplicationSettings.StoFolderCamera_Off,
                optionText: qsTr("OFF")
            }
        },
    ]

    /*!
        Store File LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var storeFileNameCamera: [
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.ApplicationSettings.StoFileNameCamera_On,
                optionText: qsTr("ON")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.ApplicationSettings.StoFileNameCamera_Off,
                optionText: qsTr("OFF")
            }
        },
    ]

// ivc >> start >> No.4
        /*!
            JPEG Transfer LTOptionButtonPopup に表示するコンポーネントの組です
         */
    /*
        readonly property var jpgTransferType: [
            {
                component: optionWithTextButtonComponent,
                properties: {
                    type: "optionWithText",
                    value: LT.ApplicationSettings.JpgTransType_RAW_JPG,
                    optionText: qsTr("RAW+JPEG")
                }
            },
            {
                component: optionWithTextButtonComponent,
                properties: {
                    type: "optionWithText",
                    value: LT.ApplicationSettings.JpgTransType_JPG,
                    optionText: qsTr("JPEGONLY")
                }
            },
        ]
    */
// ivc << end << No.4

// ivc >> start >> No.4
    /*!
        RAWの転送 LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var rawTransferType: [
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.ApplicationSettings.RawTransType_ON,
                optionText: qsTr("ON")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.ApplicationSettings.RawTransType_OFF,
                optionText: qsTr("OFF")
            }
        },
    ]

    /*!
        HLG撮影 LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var hlgShootingType: [
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.DeviceAdapter.HlgShootingType_8K,
                optionText: qsTr("8K-Res.")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.DeviceAdapter.HlgShootingType_Full,
                optionText: qsTr("Full-Res.")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.DeviceAdapter.HlgShootingType_4K,
                optionText: qsTr("4K-Res.")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {           
                type: "optionWithText",
                value: LT.DeviceAdapter.HlgShootingType_OFF,
                optionText: qsTr("OFF")
            }
        },
    ]

    /*!
        //HLGの転送 LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var hlgTransferType: [
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.ApplicationSettings.HlgTransType_ON,
                optionText: qsTr("ON")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.ApplicationSettings.HlgTransType_OFF,
                optionText: qsTr("OFF")
            }
        },
    ]
// ivc << end << No.4

    /*!
        Display review LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var displayReviewType: [
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.ApplicationSettings.DisRevType_On,
                optionText: qsTr("ON")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.ApplicationSettings.DisRevType_Off,
                optionText: qsTr("OFF")
            }
        },
    ]

    /*!
        転送確認ダイアログの表示切り替え LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var transConfirmDlgType: [
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.ApplicationSettings.ConfirmDlgType_ON,
                optionText: qsTr("ON")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.ApplicationSettings.ConfirmDlgType_OFF,
                optionText: qsTr("OFF")
            }
        },
    ]

    /*!
        Version Check at Startup LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var versionCheckType: [
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.ApplicationSettings.VerChkType_On,
                optionText: qsTr("ON")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.ApplicationSettings.VerChkType_Off,
                optionText: qsTr("OFF")
            }
        },
    ]

    /*!
        Folder Name LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var folderNameType: [
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.ApplicationSettings.FolNameType_Default,
                optionText: qsTr("Default File Name")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.ApplicationSettings.FolNameType_User,
                optionText: qsTr("User Setting")
            }
        },
    ]

    /*!
        Display review LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var logPermission: [
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.ApplicationSettings.LogPer_On,
                optionText: qsTr("ON")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.ApplicationSettings.LogPer_Off,
                optionText: qsTr("OFF")
            }
        },
    ]

///////////////////////////////////////////////////////////////////////////////
/// Components
///////////////////////////////////////////////////////////////////////////////
    /*!
        矩形のボタンを動的に生成するコンポーネントです 画像
     */
    readonly property Component optionWithImageButtonComponent: Component {
        LTRectangleButton {
            width: 107
            height: 77
            type: "optionWithImage"
            property bool capable: false
        }
    }
// IVC >> Ver.1.9 >> start >> No.5
    readonly property Component subCreativeVideoAE: Component {
        LTOptionButton {
            id: subCreativeVideoAE
            width: 107
            height: 77
            type: "optionWithImage"
            popupTitle: qsTr("CreativeVideo")
            target: "creativeVideoAE"
            popup: optionSubButtonPopup
            componentsProvider: optionComponentsProvider
            optionOpen: true
            disabled: false
            property bool capable: false
// IVC >> Ver.1.9 >> start >> [THRBOXV100-161]
//            onValueChanged: {
//                if (valueChangeFlg) {
//// IVC >> Ver.1.9 >> start >> [THRBOXV100-64]
//                   //btnOptionRecordingMode.setOption(subCreativeVideoAE);
//                   subCreativeVideoAE.setOption(subCreativeVideoAE, false);
//// IVC << Ver.1.9 << end << [THRBOXV100-64]
//                }
//            }
// IVC << Ver.1.9 << end << [THRBOXV100-161]

            Component.onCompleted: {
                mainImg.anchors.verticalCenter = verticalCenter;                            //　2024/7 ボックスタイプの時 クリエイティブ動画のアイコンがずれる事に対応
                subCreativeVideoAE.optionSelect(deviceAdapter.creativeVideoAE);
                deviceAdapter.creativeVideoAEChanged.connect(function () {
// IVC >> Ver.1.9 >> start >> [THRBOXV100-161]
                    if(subCreativeVideoAE) {
                        if(deviceAdapter.recordingMode === LT.Utilities.RM_CreativeVideo) {
                            //subCreativeVideoAE.optionSelect(deviceAdapter.creativeVideoAE);
                            if(!subCreativeVideoAE.popup.visible) {
                                subCreativeVideoAE.optionSelect(deviceAdapter.creativeVideoAE);
                            }
                        }
                    }
// IVC << Ver.1.9 << end << [THRBOXV100-161]
                });
// IVC >> Ver.1.9 >> start >> [THRBOXV100-170]
                deviceAdapter.cameraStatusChanged.connect(function() {
                    if(subCreativeVideoAE) {
                        if(deviceAdapter.cameraStatus === LT.Utilities.CamStatus_Menu_Displayed) {
                            if(subCreativeVideoAE.popup.visible) {
                                subCreativeVideoAE.popup.dismiss();
                            }
                        }
                    }
                });
// IVC << Ver.1.9 << end << [THRBOXV100-170]
            }
        }
    }
// IVC << Ver.1.9 << end << No.5

    // IVC >> Ver.1.7 >> start >> No.1
    readonly property Component optionWithImageButtonComponentForAspect: Component {
        LTRectangleButton {
            width: 107
            height: 36
            type: "optionWithImage"
            property bool capable: false
        }
    }

    readonly property Component optionWithImageButtonComponentForPreview: Component {
        LTRectangleButton {
            width: 125
            height: 36
            type: "optionWithImage"
            property bool capable: false
        }
    }

    readonly property Component optionWithImageButtonComponentForImgQuality: Component {
        LTRectangleButton {
            width: 152
            height: 36
            type: "optionWithImage"
            property bool capable: false
            property string optionOriginalText: ""
        }
    }
    // IVC << Ver.1.7 << end << No.1

    /*!
        矩形のボタンを動的に生成するコンポーネントです　文字
     */
    readonly property Component optionWithTextButtonComponent: Component {
        LTRectangleButton {
            width: 158
            height: 36
            type: "optionWithText"
            property bool capable: false
        }
    }

    /*!
        矩形のボタンを動的に生成するコンポーネントです　画像と文字
     */
    readonly property Component optionWithImagetoTextButtonComponent: Component {
        LTRectangleButton {
            width: 107
            height: 77
            type: "optionWithImagetoText"
            property bool capable: false
        }
    }

    /*!
        矩形のボタンを動的に生成するコンポーネントです　画像と文字（クリエイティブコントロール用）
     */
    readonly property Component optionWithImagetoTextButtonCcComponent: Component {
        LTRectangleButton {
            width: 77//107
            height: 77
            type: "optionWithImagetoText"
            property bool capable: false
        }
    }

    /*!
        矩形のボタンを動的に生成するコンポーネントです　画像と文字　擬似カメラで使用
     */
    readonly property Component optionWithImagetoTextButtonComponent_dm: Component {
        LTRectangleButton {
            width: 148
            height: 28
            type: "optionWithImagetoText_dm"
            property bool capable: false
        }
    }

    /*!
        矩形のボタンを動的に生成するコンポーネントです 画像
     */
    readonly property Component optionWithRichTextButtonComponent: Component {
        LTRectangleButton {
            width: 107
            height: 36
            type: "optionWithRichText"
            property bool capable: false
        }
    }

    /*!
        矩形のボタンを動的に生成するコンポーネントです 文字
     */
    readonly property Component optionWithStyledTextButtonComponent: Component {
        LTRectangleButton {
            width: 107
            height: 36
            type: "optionWithStyledText"
            property bool capable: false
        }
    }

///////////////////////////////////////////////////////////////////////////////
/// Functions
///////////////////////////////////////////////////////////////////////////////
    function apertureOptionTextFormat(val) {
        //var optionVal = utilities.enumApeToVal(val);
        var optionVal = val
        var str
        if(val === 0) {
            str = '<font size="2">F</font>' + "0.0";
        } else {
            str = '<font size="2">F</font>' + (optionVal/10).toFixed(1);
        }

        return str;
    }

    function whiteBalanceKSetTextFormat(val) {
        var optionVal = utilities.enumWbKSetToVal(val);
        var str = optionVal + 'K';

        return str;
    }

    function getAFM_FaceText()
    {
        //デフォルト
        var str = qsTr("AFM_Face");
        //人物認識に対応か
        if(deviceAdapter.afAnimalRecognitionEnable)
        {
            str = qsTr("AFM_AutoRe");
            //動物認識に対応か
            if( deviceAdapter.autoRecognizeAnimalEnable)
            {
                switch(deviceAdapter.autoRecognizeAnimal)
                {
                case LT.Utilities.AR_ANIMAL_ON:
                    str = qsTr("AFM_AutoRe_HumanAnimal");
                    break;
                default:
                    str = qsTr("AFM_AutoRe_Human");
                    break;
                }
            }
        }

        return str;
    }
    function getAFM_FaceImg()
    {
        //デフォルト
        var str = "qrc:/images/374_face.svg";
        //人物認識に対応か
        if(deviceAdapter.afAnimalRecognitionEnable)
        {
            str = "qrc:/images/auto_recognition.svg";
            //動物認識に対応か
            if( deviceAdapter.autoRecognizeAnimalEnable)
            {
                switch(deviceAdapter.autoRecognizeAnimal)
                {
                case LT.Utilities.AR_ANIMAL_ON:
                    str = "qrc:/images/auto_recognition.svg";
                    break;
                default:
                    str = "qrc:/images/af_area_auto_face.svg";
                    break;
                }
            }
        }

        return str;
    }

    function getAFM_1PointAuxText()
    {
        var str = qsTr("AFM_1PointAux");
        //自動認識に対応か
        if(deviceAdapter.automaticRecoEnable) {
            if(deviceAdapter.automaticReco && deviceAdapter.autoRecognizeGeneralEnable)
            {
                switch(deviceAdapter.autoRecognizeGeneral)
                {
                case LT.Utilities.AR_GENERAL_HUMAN:
                    str = qsTr("AFM_1PointAux_Human");
                    break;
                case LT.Utilities.AR_GENERAL_HUMAN_ANIMAL:
                    str = qsTr("AFM_1PointAux_HumanAnimal");
                    break;
                case LT.Utilities.AR_GENERAL_FACE_EYE:
                    str = qsTr("AFM_1PointAux_FaceEye");
                    break;
// MC5229 判定追加 start
                case LT.Utilities.AR_GENERAL_TARGET_HUMAN:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_HUMAN_EYE_FACE_BODY:
                        str = qsTr("AFM_1PointAux_Detection") + "\n" + qsTr("AFM_Detection_HumanEyeFaceBody");
                        break;
                    case LT.Utilities.AR_PARTS_HUMAN_EYE_FACE:
                        str = qsTr("AFM_1PointAux_Detection") + "\n" + qsTr("AFM_Detection_HumanEyeFace");
                        break;
                    case LT.Utilities.AR_PARTS_HUMAN_STREET:
                        str = qsTr("AFM_1PointAux_Detection") + "\n" + qsTr("AFM_Detection_HumanStreet");
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_ANIMAL:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_ANIMAL_BODY:
                            str = qsTr("AFM_1PointAux_Detection") + "\n" + qsTr("AFM_Detection_AnimalBody");
                        break;
                    case LT.Utilities.AR_PARTS_ANIMAL_EYE_BODY:
                            str = qsTr("AFM_1PointAux_Detection") + "\n" + qsTr("AFM_Detection_AnimalEyeBody");
                        break;
                    default:
                        break;
                    }
                    break;
// MC5229 判定追加 - MC5231 追加 start
                case LT.Utilities.AR_GENERAL_TARGET_CAR:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_CAR_WHOLE:
                        str = qsTr("AFM_1PointAux_Detection") + "\n" + qsTr("AFM_Detection_Car_Whole");
                        break;
                    case LT.Utilities.AR_PARTS_CAR_PRIORITY:
                        str = qsTr("AFM_1PointAux_Detection") + "\n" + qsTr("AFM_Detection_Car_Priority");
                        break;
                    default:
                        str = qsTr("AFM_1PointAux_Detection") + "\n" + qsTr("AFM_Detection_Car");
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_BIKE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_BIKE_WHOLE:
                        str = qsTr("AFM_1PointAux_Detection") + "\n" + qsTr("AFM_Detection_Bike_Whole");
                        break;
                    case LT.Utilities.AR_PARTS_BIKE_HELMET:
                        str = qsTr("AFM_1PointAux_Detection") + "\n" + qsTr("AFM_Detection_Bike_Helmet");
                        break;
                    default:
                        str = qsTr("AFM_1PointAux_Detection") + "\n" + qsTr("AFM_Detection_Motorcycle");
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_TRAIN:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_TRAIN_LEADING_VEH:
                            str = qsTr("AFM_1PointAux_Detection") + "\n" + qsTr("AFM_Detection_Train_Leading_Veh");
                        break;
                    case LT.Utilities.AR_PARTS_TRAIN_PRIORITY:
                            str = qsTr("AFM_1PointAux_Detection") + "\n" + qsTr("AFM_Detection_Train_Priority");
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_PLANE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_PLANE_AIRCRAFT:
                            str = qsTr("AFM_1PointAux_Detection") + "\n" + qsTr("AFM_Detection_Plane_Aircraft");
                        break;
                    case LT.Utilities.AR_PARTS_PLANE_NOSE_PRIORITY:
                            str = qsTr("AFM_1PointAux_Detection") + "\n" + qsTr("AFM_Detection_Plane_Nose_Priority");
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_BICYCLE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_BICYCLE_WHOLE:
                            str = qsTr("AFM_1PointAux_Detection") + "\n" + qsTr("AFM_Detection_Bicycle_Whole");
                        break;
                    case LT.Utilities.AR_PARTS_BICYCLE_PRIORITY:
                            str = qsTr("AFM_1PointAux_Detection") + "\n" + qsTr("AFM_Detection_Bicycle_Priority");
                        break;
                    default:
                        break;
                    }
                    break;
// MC5229 判定追加 - MC5231 追加 end
// MC5229 判定追加 end
                default:
                    break;
                }
            }
        } else {
            if( deviceAdapter.autoRecognizeGeneralEnable)
            {
                switch(deviceAdapter.autoRecognizeGeneral)
                {
                case LT.Utilities.AR_GENERAL_HUMAN:
                    str = qsTr("AFM_1PointAux_Human");
                    break;
                case LT.Utilities.AR_GENERAL_HUMAN_ANIMAL:
                    str = qsTr("AFM_1PointAux_HumanAnimal");
                    break;
                case LT.Utilities.AR_GENERAL_FACE_EYE:
                    str = qsTr("AFM_1PointAux_FaceEye");
                    break;
// MC5229 判定追加 start
                case LT.Utilities.AR_GENERAL_TARGET_HUMAN:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_HUMAN_EYE_FACE_BODY:
                        str = qsTr("AFM_1PointAux_Detection") + "\n" + qsTr("AFM_Detection_HumanEyeFaceBody");
                        break;
                    case LT.Utilities.AR_PARTS_HUMAN_EYE_FACE:
                        str = qsTr("AFM_1PointAux_Detection") + "\n" + qsTr("AFM_Detection_HumanEyeFace");
                        break;
                    case LT.Utilities.AR_PARTS_HUMAN_STREET:
                        str = qsTr("AFM_1PointAux_Detection") + "\n" + qsTr("AFM_Detection_HumanStreet");
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_ANIMAL:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_ANIMAL_BODY:
                            str = qsTr("AFM_1PointAux_Detection") + "\n" + qsTr("AFM_Detection_AnimalBody");
                        break;
                    case LT.Utilities.AR_PARTS_ANIMAL_EYE_BODY:
                            str = qsTr("AFM_1PointAux_Detection") + "\n" + qsTr("AFM_Detection_AnimalEyeBody");
                        break;
                    default:
                        break;
                    }
                    break;
// MC5229 判定追加 - MC5231 追加 end
                case LT.Utilities.AR_GENERAL_TARGET_CAR:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_CAR_WHOLE:
                        str = qsTr("AFM_1PointAux_Detection") + "\n" + qsTr("AFM_Detection_Car_Whole");
                        break;
                    case LT.Utilities.AR_PARTS_CAR_PRIORITY:
                        str = qsTr("AFM_1PointAux_Detection") + "\n" + qsTr("AFM_Detection_Car_Priority");
                        break;
                    default:
                        str = qsTr("AFM_1PointAux_Detection") + "\n" + qsTr("AFM_Detection_Car");
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_BIKE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_BIKE_WHOLE:
                        str = qsTr("AFM_1PointAux_Detection") + "\n" + qsTr("AFM_Detection_Bike_Whole");
                        break;
                    case LT.Utilities.AR_PARTS_BIKE_HELMET:
                        str = qsTr("AFM_1PointAux_Detection") + "\n" + qsTr("AFM_Detection_Bike_Helmet");
                        break;
                    default:
                        str = qsTr("AFM_1PointAux_Detection") + "\n" + qsTr("AFM_Detection_Motorcycle");
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_TRAIN:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_TRAIN_LEADING_VEH:
                            str = qsTr("AFM_1PointAux_Detection") + "\n" + qsTr("AFM_Detection_Train_Leading_Veh");
                        break;
                    case LT.Utilities.AR_PARTS_TRAIN_PRIORITY:
                            str = qsTr("AFM_1PointAux_Detection") + "\n" + qsTr("AFM_Detection_Train_Priority");
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_PLANE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_PLANE_AIRCRAFT:
                            str = qsTr("AFM_1PointAux_Detection") + "\n" + qsTr("AFM_Detection_Plane_Aircraft");
                        break;
                    case LT.Utilities.AR_PARTS_PLANE_NOSE_PRIORITY:
                            str = qsTr("AFM_1PointAux_Detection") + "\n" + qsTr("AFM_Detection_Plane_Nose_Priority");
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_BICYCLE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_BICYCLE_WHOLE:
                            str = qsTr("AFM_1PointAux_Detection") + "\n" + qsTr("AFM_Detection_Bicycle_Whole");
                        break;
                    case LT.Utilities.AR_PARTS_BICYCLE_PRIORITY:
                            str = qsTr("AFM_1PointAux_Detection") + "\n" + qsTr("AFM_Detection_Bicycle_Priority");
                        break;
                    default:
                        break;
                    }
                    break;
// MC5229 判定追加 - MC5231 追加 end
// MC5229 判定追加 end
                default:
                    break;
                }
            }
        }
        return str;
    }
    function getAFM_1PointAuxImg()
    {
        var str = "qrc:/images/1p_auxiliary.svg";
        //自動認識に対応か
        if(deviceAdapter.automaticRecoEnable) {
            if(deviceAdapter.automaticReco && deviceAdapter.autoRecognizeGeneralEnable)
            {
                switch(deviceAdapter.autoRecognizeGeneral)
                {
                case LT.Utilities.AR_GENERAL_HUMAN:
                    str = "qrc:/images/af_area_1point_aid_face.svg";
                    break;
                case LT.Utilities.AR_GENERAL_HUMAN_ANIMAL:
                    str = "qrc:/images/af_area_1point_aid_ani.svg";
                    break;
                case LT.Utilities.AR_GENERAL_FACE_EYE:
                    str = "qrc:/images/af_area_1point_aid_eye.svg";
                    break;
// MC5229 判定追加 start
                case LT.Utilities.AR_GENERAL_TARGET_HUMAN:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_HUMAN_EYE_FACE_BODY:
                        str = "qrc:/images/af_1point_aid_hum_body.svg";
                        break;
                    case LT.Utilities.AR_PARTS_HUMAN_EYE_FACE:
                        str = "qrc:/images/af_1point_aid_hum_eyes.svg";
                        break;
                    case LT.Utilities.AR_PARTS_HUMAN_STREET:
                        str = "qrc:/images/af_1point_aid_hum_street.svg";
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_ANIMAL:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_ANIMAL_BODY:
                        str = "qrc:/images/af_1point_aid_ani_body.svg";
                        break;
                    case LT.Utilities.AR_PARTS_ANIMAL_EYE_BODY:
                        str = "qrc:/images/af_1point_aid_ani_eyes.svg";
                        break;
                    default:
                        break;
                    }
                    break;
// MC5229 判定追加 - MC5231 追加 start
                case LT.Utilities.AR_GENERAL_TARGET_CAR:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_CAR_WHOLE:
                        str = "qrc:/images/af_1point_aid_car_whole.svg";
                        break;
                    case LT.Utilities.AR_PARTS_CAR_PRIORITY:
                        str = "qrc:/images/af_1point_aid_car_priority.svg";
                        break;
                    default:
                        str = "qrc:/images/af_1point_aid_car.svg";
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_BIKE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_BIKE_WHOLE:
                        str = "qrc:/images/af_1point_aid_bike_whole.svg";
                        break;
                    case LT.Utilities.AR_PARTS_BIKE_HELMET:
                        str = "qrc:/images/af_1point_aid_bike_helmet.svg";
                        break;
                    default:
                        str = "qrc:/images/af_1point_aid_bike.svg";
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_TRAIN:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_TRAIN_LEADING_VEH:
                        str = "qrc:/images/af_1point_aid_train_leading_veh.svg";
                        break;
                    case LT.Utilities.AR_PARTS_TRAIN_PRIORITY:
                        str = "qrc:/images/af_1point_aid_train_priority.svg";
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_PLANE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_PLANE_AIRCRAFT:
                        str = "qrc:/images/af_1point_aid_plane_aircraft.svg";
                        break;
                    case LT.Utilities.AR_PARTS_PLANE_NOSE_PRIORITY:
                        str = "qrc:/images/af_1point_aid_plane_nose_priority.svg";
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_BICYCLE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_BICYCLE_WHOLE:
                        str = "qrc:/images/af_1point_aid_bike_whole.svg";
                        break;
                    case LT.Utilities.AR_PARTS_BICYCLE_PRIORITY:
                        str = "qrc:/images/af_1point_aid_bike_helmet.svg";
                        break;
                    default:
                        break;
                    }
                    break;
// MC5229 判定追加 - MC5231 追加 end
// MC5229 判定追加 end
                default:
                    break;
                }
            }
        } else {
            if( deviceAdapter.autoRecognizeGeneralEnable)
            {
                switch(deviceAdapter.autoRecognizeGeneral)
                {
                case LT.Utilities.AR_GENERAL_HUMAN:
                    str = "qrc:/images/af_area_1point_aid_face.svg";
                    break;
                case LT.Utilities.AR_GENERAL_HUMAN_ANIMAL:
                    str = "qrc:/images/af_area_1point_aid_ani.svg";
                    break;
                case LT.Utilities.AR_GENERAL_FACE_EYE:
                    str = "qrc:/images/af_area_1point_aid_eye.svg";
                    break;
// MC5229 判定追加 start
                case LT.Utilities.AR_GENERAL_TARGET_HUMAN:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_HUMAN_EYE_FACE_BODY:
                        str = "qrc:/images/af_1point_aid_hum_body.svg";
                        break;
                    case LT.Utilities.AR_PARTS_HUMAN_EYE_FACE:
                        str = "qrc:/images/af_1point_aid_hum_eyes.svg";
                        break;
                    case LT.Utilities.AR_PARTS_HUMAN_STREET:
                        str = "qrc:/images/af_1point_aid_hum_street.svg";
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_ANIMAL:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_ANIMAL_BODY:
                        str = "qrc:/images/af_1point_aid_ani_body.svg";
                        break;
                    case LT.Utilities.AR_PARTS_ANIMAL_EYE_BODY:
                        str = "qrc:/images/af_1point_aid_ani_eyes.svg";
                        break;
                    default:
                        break;
                    }
                    break;
// MC5229 判定追加 - MC5231 追加 start
                case LT.Utilities.AR_GENERAL_TARGET_CAR:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_CAR_WHOLE:
                        str = "qrc:/images/af_1point_aid_car_whole.svg";
                        break;
                    case LT.Utilities. AR_PARTS_CAR_PRIORITY:
                        str = "qrc:/images/af_1point_aid_car_priority.svg";
                        break;
                    default:
                        str = "qrc:/images/af_1point_aid_car.svg";
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_BIKE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_BIKE_WHOLE:
                        str = "qrc:/images/af_1point_aid_bike_whole.svg";
                        break;
                    case LT.Utilities.AR_PARTS_BIKE_HELMET:
                        str = "qrc:/images/af_1point_aid_bike_helmet.svg";
                        break;
                    default:
                        str = "qrc:/images/af_1point_aid_bike.svg";
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_TRAIN:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_TRAIN_LEADING_VEH:
                        str = "qrc:/images/af_1point_aid_train_leading_veh.svg";
                        break;
                    case LT.Utilities.AR_PARTS_TRAIN_PRIORITY:
                        str = "qrc:/images/af_1point_aid_train_priority.svg";
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_PLANE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_PLANE_AIRCRAFT:
                        str = "qrc:/images/af_1point_aid_plane_aircraft.svg";
                        break;
                    case LT.Utilities.AR_PARTS_PLANE_NOSE_PRIORITY:
                        str = "qrc:/images/af_1point_aid_plane_nose_priority.svg";
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_BICYCLE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_BICYCLE_WHOLE:
                        str = "qrc:/images/af_1point_aid_bike_whole.svg";
                        break;
                    case LT.Utilities.AR_PARTS_BICYCLE_PRIORITY:
                        str = "qrc:/images/af_1point_aid_bike_helmet.svg";
                        break;
                    default:
                        break;
                    }
                    break;
// MC5229 判定追加 - MC5231 追加 end
// MC5229 判定追加 end
                default:
                    break;
                }
            }
        }
        return str;
    }

    function getAFM_1PointText()
    {
        var str = qsTr("AFM_1Point");
        //自動認識に対応か
        if(deviceAdapter.automaticRecoEnable) {
            if(deviceAdapter.automaticReco && deviceAdapter.autoRecognizeGeneralEnable)
            {
                switch(deviceAdapter.autoRecognizeGeneral)
                {
                case LT.Utilities.AR_GENERAL_HUMAN:
                    str = qsTr("AFM_1Point_Human");
                    break;
                case LT.Utilities.AR_GENERAL_HUMAN_ANIMAL:
                    str = qsTr("AFM_1Point_HumanAnimal");
                    break;
                case LT.Utilities.AR_GENERAL_FACE_EYE:
                    str = qsTr("AFM_1Point_FaceEye");
                    break;
// MC5229 判定追加 start
                case LT.Utilities.AR_GENERAL_TARGET_HUMAN:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_HUMAN_EYE_FACE_BODY:
                        str = qsTr("AFM_1Point_Detection") + "\n" + qsTr("AFM_Detection_HumanEyeFaceBody");
                        break;
                    case LT.Utilities.AR_PARTS_HUMAN_EYE_FACE:
                        str = qsTr("AFM_1Point_Detection") + "\n" + qsTr("AFM_Detection_HumanEyeFace");
                        break;
                    case LT.Utilities.AR_PARTS_HUMAN_STREET:
                        str = qsTr("AFM_1Point_Detection") + "\n" + qsTr("AFM_Detection_HumanStreet");
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_ANIMAL:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_ANIMAL_BODY:
                            str = qsTr("AFM_1Point_Detection") + "\n" + qsTr("AFM_Detection_AnimalBody");
                        break;
                    case LT.Utilities.AR_PARTS_ANIMAL_EYE_BODY:
                            str = qsTr("AFM_1Point_Detection") + "\n" + qsTr("AFM_Detection_AnimalEyeBody");
                        break;
                    default:
                        break;
                    }
                    break;
// MC5229 判定追加 - MC5231 追加 start
                case LT.Utilities.AR_GENERAL_TARGET_CAR:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_CAR_WHOLE:
                        str = qsTr("AFM_1Point_Detection") + "\n" + qsTr("AFM_Detection_Car_Whole");
                        break;
                    case LT.Utilities.AR_PARTS_CAR_PRIORITY:
                        str = qsTr("AFM_1Point_Detection") + "\n" + qsTr("AFM_Detection_Car_Priority");
                        break;
                    default:
                        str = qsTr("AFM_1Point_Detection") + "\n" + qsTr("AFM_Detection_Car");
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_BIKE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_BIKE_WHOLE:
                            str = qsTr("AFM_1Point_Detection") + "\n" + qsTr("AFM_Detection_Bike_Whole");
                        break;
                    case LT.Utilities.AR_PARTS_BIKE_HELMET:
                            str = qsTr("AFM_1Point_Detection") + "\n" + qsTr("AFM_Detection_Bike_Helmet");
                        break;
                    default:
                            str = qsTr("AFM_1Point_Detection") + "\n" + qsTr("AFM_Detection_Motorcycle");
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_TRAIN:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_TRAIN_LEADING_VEH:
                            str = qsTr("AFM_1Point_Detection") + "\n" + qsTr("AFM_Detection_Train_Leading_Veh");
                        break;
                    case LT.Utilities.AR_PARTS_TRAIN_PRIORITY:
                            str = qsTr("AFM_1Point_Detection") + "\n" + qsTr("AFM_Detection_Train_Priority");
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_PLANE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_PLANE_AIRCRAFT:
                            str = qsTr("AFM_1Point_Detection") + "\n" + qsTr("AFM_Detection_Plane_Aircraft");
                        break;
                    case LT.Utilities.AR_PARTS_PLANE_NOSE_PRIORITY:
                            str = qsTr("AFM_1Point_Detection") + "\n" + qsTr("AFM_Detection_Plane_Nose_Priority");
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_BICYCLE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_BICYCLE_WHOLE:
                            str = qsTr("AFM_1Point_Detection") + "\n" + qsTr("AFM_Detection_Bicycle_Whole");
                        break;
                    case LT.Utilities.AR_PARTS_BICYCLE_PRIORITY:
                            str = qsTr("AFM_1Point_Detection") + "\n" + qsTr("AFM_Detection_Bicycle_Priority");
                        break;
                    default:
                        break;
                    }
                    break;
// MC5229 判定追加 - MC5231 追加 end
// MC5229 判定追加 end
                default:
                    break;
                }
            }
        } else {
            if( deviceAdapter.autoRecognizeGeneralEnable)
            {
                switch(deviceAdapter.autoRecognizeGeneral)
                {
                case LT.Utilities.AR_GENERAL_HUMAN:
                    str = qsTr("AFM_1Point_Human");
                    break;
                case LT.Utilities.AR_GENERAL_HUMAN_ANIMAL:
                    str = qsTr("AFM_1Point_HumanAnimal");
                    break;
                case LT.Utilities.AR_GENERAL_FACE_EYE:
                    str = qsTr("AFM_1Point_FaceEye");
                    break;
// MC5229 判定追加 start
                case LT.Utilities.AR_GENERAL_TARGET_HUMAN:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_HUMAN_EYE_FACE_BODY:
                        str = qsTr("AFM_1Point_Detection") + "\n" + qsTr("AFM_Detection_HumanEyeFaceBody");
                        break;
                    case LT.Utilities.AR_PARTS_HUMAN_EYE_FACE:
                        str = qsTr("AFM_1Point_Detection") + "\n" + qsTr("AFM_Detection_HumanEyeFace");
                        break;
                    case LT.Utilities.AR_PARTS_HUMAN_STREET:
                        str = qsTr("AFM_1Point_Detection") + "\n" + qsTr("AFM_Detection_HumanStreet");
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_ANIMAL:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_ANIMAL_BODY:
                            str = qsTr("AFM_1Point_Detection") + "\n" + qsTr("AFM_Detection_AnimalBody");
                        break;
                    case LT.Utilities.AR_PARTS_ANIMAL_EYE_BODY:
                            str = qsTr("AFM_1Point_Detection") + "\n" + qsTr("AFM_Detection_AnimalEyeBody");
                        break;
                    default:
                        break;
                    }
                    break;
// MC5229 判定追加 - MC5231 追加 start
                case LT.Utilities.AR_GENERAL_TARGET_CAR:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_CAR_WHOLE:
                        str = qsTr("AFM_1Point_Detection") + "\n" + qsTr("AFM_Detection_Car_Whole");
                        break;
                    case LT.Utilities.AR_PARTS_CAR_PRIORITY:
                        str = qsTr("AFM_1Point_Detection") + "\n" + qsTr("AFM_Detection_Car_Priority");
                        break;
                    default:
                        str = qsTr("AFM_1Point_Detection") + "\n" + qsTr("AFM_Detection_Car");
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_BIKE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_BIKE_WHOLE:
                            str = qsTr("AFM_1Point_Detection") + "\n" + qsTr("AFM_Detection_Bike_Whole");
                        break;
                    case LT.Utilities.AR_PARTS_BIKE_HELMET:
                            str = qsTr("AFM_1Point_Detection") + "\n" + qsTr("AFM_Detection_Bike_Helmet");
                        break;
                    default:
                            str = qsTr("AFM_1Point_Detection") + "\n" + qsTr("AFM_Detection_Motorcycle");
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_TRAIN:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_TRAIN_LEADING_VEH:
                            str = qsTr("AFM_1Point_Detection") + "\n" + qsTr("AFM_Detection_Train_Leading_Veh");
                        break;
                    case LT.Utilities.AR_PARTS_TRAIN_PRIORITY:
                            str = qsTr("AFM_1Point_Detection") + "\n" + qsTr("AFM_Detection_Train_Priority");
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_PLANE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_PLANE_AIRCRAFT:
                            str = qsTr("AFM_1Point_Detection") + "\n" + qsTr("AFM_Detection_Plane_Aircraft");
                        break;
                    case LT.Utilities.AR_PARTS_PLANE_NOSE_PRIORITY:
                            str = qsTr("AFM_1Point_Detection") + "\n" + qsTr("AFM_Detection_Plane_Nose_Priority");
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_BICYCLE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_BICYCLE_WHOLE:
                            str = qsTr("AFM_1Point_Detection") + "\n" + qsTr("AFM_Detection_Bicycle_Whole");
                        break;
                    case LT.Utilities.AR_PARTS_BICYCLE_PRIORITY:
                            str = qsTr("AFM_1Point_Detection") + "\n" + qsTr("AFM_Detection_Bicycle_Priority");
                        break;
                    default:
                        break;
                    }
                    break;
// MC5229 判定追加 - MC5231 追加 end
// MC5229 判定追加 end
                default:
                    break;
                }
            }
        }
        return str;
    }
    function getAFM_1PointImg()
    {
        var str = "qrc:/images/378_1point.svg";
        //自動認識に対応か
        if(deviceAdapter.automaticRecoEnable) {
            if(deviceAdapter.automaticReco && deviceAdapter.autoRecognizeGeneralEnable)
            {
                switch(deviceAdapter.autoRecognizeGeneral)
                {
                case LT.Utilities.AR_GENERAL_HUMAN:
                    str = "qrc:/images/af_area_1point_face.svg";
                    break;
                case LT.Utilities.AR_GENERAL_HUMAN_ANIMAL:
                    str = "qrc:/images/af_area_1point_ani.svg";
                    break;
                case LT.Utilities.AR_GENERAL_FACE_EYE:
                    str = "qrc:/images/af_area_1point_eye.svg";
                    break;
// MC5229 判定追加 start
                case LT.Utilities.AR_GENERAL_TARGET_HUMAN:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_HUMAN_EYE_FACE_BODY:
                        str = "qrc:/images/af_1point_hum_body.svg";
                        break;
                    case LT.Utilities.AR_PARTS_HUMAN_EYE_FACE:
                        str = "qrc:/images/af_1point_hum_eyes.svg";
                        break;
                    case LT.Utilities.AR_PARTS_HUMAN_STREET:
                        str = "qrc:/images/af_1point_hum_street.svg";
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_ANIMAL:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_ANIMAL_BODY:
                        str = "qrc:/images/af_1point_ani_body.svg";
                        break;
                    case LT.Utilities.AR_PARTS_ANIMAL_EYE_BODY:
                        str = "qrc:/images/af_1point_ani_eyes.svg";
                        break;
                    default:
                        break;
                    }
                    break;
// MC5229 判定追加 - MC5231 追加 start
                case LT.Utilities.AR_GENERAL_TARGET_CAR:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_CAR_WHOLE:
                        str = "qrc:/images/af_1point_car_whole.svg";
                        break;
                    case LT.Utilities.AR_PARTS_CAR_PRIORITY:
                        str = "qrc:/images/af_1point_car_priority.svg";
                        break;
                    default:
                        str = "qrc:/images/af_1point_car.svg";
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_BIKE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_BIKE_WHOLE:
                        str = "qrc:/images/af_1point_bike_whole.svg";
                        break;
                    case LT.Utilities.AR_PARTS_BIKE_HELMET:
                        str = "qrc:/images/af_1point_bike_helmet.svg";
                        break;
                    default:
                        str = "qrc:/images/af_1point_bike.svg";
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_TRAIN:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_TRAIN_LEADING_VEH:
                        str = "qrc:/images/af_1point_train_leading_veh.svg";
                        break;
                    case LT.Utilities.AR_PARTS_TRAIN_PRIORITY:
                        str = "qrc:/images/af_1point_train_priority.svg";
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_PLANE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_PLANE_AIRCRAFT:
                        str = "qrc:/images/af_1point_plane_aircraft.svg";
                        break;
                    case LT.Utilities.AR_PARTS_PLANE_NOSE_PRIORITY:
                        str = "qrc:/images/af_1point_plane_nose_priority.svg";
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_BICYCLE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_BICYCLE_WHOLE:
                        str = "qrc:/images/af_1point_bike_whole.svg";
                        break;
                    case LT.Utilities.AR_PARTS_BICYCLE_PRIORITY:
                        str = "qrc:/images/af_1point_bike_helmet.svg";
                        break;
                    default:
                        break;
                    }
                    break;
// MC5229 判定追加 - MC5231 追加 end
// MC5229 判定追加 end
                default:
                    break;
                }
            }
        } else {
            if( deviceAdapter.autoRecognizeGeneralEnable)
            {
                switch(deviceAdapter.autoRecognizeGeneral)
                {
                case LT.Utilities.AR_GENERAL_HUMAN:
                    str = "qrc:/images/af_area_1point_face.svg";
                    break;
                case LT.Utilities.AR_GENERAL_HUMAN_ANIMAL:
                    str = "qrc:/images/af_area_1point_ani.svg";
                    break;
                case LT.Utilities.AR_GENERAL_FACE_EYE:
                    str = "qrc:/images/af_area_1point_eye.svg";
                    break;
// MC5229 判定追加 start
                case LT.Utilities.AR_GENERAL_TARGET_HUMAN:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_HUMAN_EYE_FACE_BODY:
                        str = "qrc:/images/af_1point_hum_body.svg";
                        break;
                    case LT.Utilities.AR_PARTS_HUMAN_EYE_FACE:
                        str = "qrc:/images/af_1point_hum_eyes.svg";
                        break;
                    case LT.Utilities.AR_PARTS_HUMAN_STREET:
                        str = "qrc:/images/af_1point_hum_street.svg";
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_ANIMAL:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_ANIMAL_BODY:
                        str = "qrc:/images/af_1point_ani_body.svg";
                        break;
                    case LT.Utilities.AR_PARTS_ANIMAL_EYE_BODY:
                        str = "qrc:/images/af_1point_ani_eyes.svg";
                        break;
                    default:
                        break;
                    }
                    break;
// MC5229 判定追加 - MC5231 追加 start
                case LT.Utilities.AR_GENERAL_TARGET_CAR:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_CAR_WHOLE:
                        str = "qrc:/images/af_1point_car_whole.svg";
                        break;
                    case LT.Utilities.AR_PARTS_CAR_PRIORITY:
                        str = "qrc:/images/af_1point_car_priority.svg";
                        break;
                    default:
                        str = "qrc:/images/af_1point_car.svg";
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_BIKE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_BIKE_WHOLE:
                        str = "qrc:/images/af_1point_bike_whole.svg";
                        break;
                    case LT.Utilities.AR_PARTS_BIKE_HELMET:
                        str = "qrc:/images/af_1point_bike_helmet.svg";
                        break;
                    default:
                        str = "qrc:/images/af_1point_bike.svg";
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_TRAIN:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_TRAIN_LEADING_VEH:
                        str = "qrc:/images/af_1point_train_leading_veh.svg";
                        break;
                    case LT.Utilities.AR_PARTS_TRAIN_PRIORITY:
                        str = "qrc:/images/af_1point_train_priority.svg";
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_PLANE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_PLANE_AIRCRAFT:
                        str = "qrc:/images/af_1point_plane_aircraft.svg";
                        break;
                    case LT.Utilities.AR_PARTS_PLANE_NOSE_PRIORITY:
                        str = "qrc:/images/af_1point_plane_nose_priority.svg";
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_BICYCLE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_BICYCLE_WHOLE:
                        str = "qrc:/images/af_1point_bike_whole.svg";
                        break;
                    case LT.Utilities.AR_PARTS_BICYCLE_PRIORITY:
                        str = "qrc:/images/af_1point_bike_helmet.svg";
                        break;
                    default:
                        break;
                    }
                    break;
// MC5229 判定追加 - MC5231 追加 end
// MC5229 判定追加 end
                default:
                    break;
                }
            }
        }
        return str;
    }

    function getAFM_TrackingText()
    {
        var str = qsTr("AFM_Tracking");
        //自動認識に対応か
        if(deviceAdapter.automaticRecoEnable) {
            if(deviceAdapter.automaticReco && deviceAdapter.autoRecognizeGeneralEnable)
            {
                switch(deviceAdapter.autoRecognizeGeneral)
                {
                case LT.Utilities.AR_GENERAL_HUMAN:
                    str = qsTr("AFM_Tracking_Human");
                    break;
                case LT.Utilities.AR_GENERAL_HUMAN_ANIMAL:
                    str = qsTr("AFM_Tracking_HumanAnimal");
                    break;
                case LT.Utilities.AR_GENERAL_FACE_EYE:
                    str = qsTr("AFM_Tracking_FaceEye");
                    break;
// MC5229 判定追加 start
                case LT.Utilities.AR_GENERAL_TARGET_HUMAN:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_HUMAN_EYE_FACE_BODY:
                        str = qsTr("AFM_Tracking_Detection") + "\n" + qsTr("AFM_Detection_HumanEyeFaceBody");
                        break;
                    case LT.Utilities.AR_PARTS_HUMAN_EYE_FACE:
                        str = qsTr("AFM_Tracking_Detection") + "\n" + qsTr("AFM_Detection_HumanEyeFace");
                        break;
                    case LT.Utilities.AR_PARTS_HUMAN_STREET:
                        str = qsTr("AFM_Tracking_Detection") + "\n" + qsTr("AFM_Detection_HumanStreet");
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_ANIMAL:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_ANIMAL_BODY:
                            str = qsTr("AFM_Tracking_Detection") + "\n" + qsTr("AFM_Detection_AnimalBody");
                        break;
                    case LT.Utilities.AR_PARTS_ANIMAL_EYE_BODY:
                            str = qsTr("AFM_Tracking_Detection") + "\n" + qsTr("AFM_Detection_AnimalEyeBody");
                        break;
                    default:
                        break;
                    }
                    break;
// MC5229 判定追加 - MC5231 追加 start
                case LT.Utilities.AR_GENERAL_TARGET_CAR:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_CAR_WHOLE:
                            str = qsTr("AFM_Tracking_Detection") + "\n" + qsTr("AFM_Detection_Car_Whole");
                        break;
                    case LT.Utilities.AR_PARTS_CAR_PRIORITY:
                            str = qsTr("AFM_Tracking_Detection") + "\n" + qsTr("AFM_Detection_Car_Priority");
                        break;
                    default:
                            str = qsTr("AFM_Tracking_Detection") + "\n" + qsTr("AFM_Detection_Car");
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_BIKE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_BIKE_WHOLE:
                            str = qsTr("AFM_Tracking_Detection") + "\n" + qsTr("AFM_Detection_Bike_Whole");
                        break;
                    case LT.Utilities.AR_PARTS_BIKE_HELMET:
                            str = qsTr("AFM_Tracking_Detection") + "\n" + qsTr("AFM_Detection_Bike_Helmet");
                        break;
                    default:
                            str = qsTr("AFM_Tracking_Detection") + "\n" + qsTr("AFM_Detection_Motorcycle");
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_TRAIN:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_TRAIN_LEADING_VEH:
                            str = qsTr("AFM_Tracking_Detection") + "\n" + qsTr("AFM_Detection_Train_Leading_Veh");
                        break;
                    case LT.Utilities.AR_PARTS_TRAIN_PRIORITY:
                            str = qsTr("AFM_Tracking_Detection") + "\n" + qsTr("AFM_Detection_Train_Priority");
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_PLANE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_PLANE_AIRCRAFT:
                            str = qsTr("AFM_Tracking_Detection") + "\n" + qsTr("AFM_Detection_Plane_Aircraft");
                        break;
                    case LT.Utilities.AR_PARTS_PLANE_NOSE_PRIORITY:
                            str = qsTr("AFM_Tracking_Detection") + "\n" + qsTr("AFM_Detection_Plane_Nose_Priority");
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_BICYCLE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_BICYCLE_WHOLE:
                            str = qsTr("AFM_Tracking_Detection") + "\n" + qsTr("AFM_Detection_Bicycle_Whole");
                        break;
                    case LT.Utilities.AR_PARTS_BICYCLE_PRIORITY:
                            str = qsTr("AFM_Tracking_Detection") + "\n" + qsTr("AFM_Detection_Bicycle_Priority");
                        break;
                    default:
                        break;
                    }
                    break;
// MC5229 判定追加 - MC5231 追加 end
// MC5229 判定追加 end
                default:
                    break;
                }
            }
        }
        return str;
    }
    function getAFM_TrackingImg()
    {
        var str = "qrc:/images/375_tracking.svg";
        //自動認識に対応か
        if(deviceAdapter.automaticRecoEnable) {
            if(deviceAdapter.automaticReco && deviceAdapter.autoRecognizeGeneralEnable)
            {
                switch(deviceAdapter.autoRecognizeGeneral)
                {
                case LT.Utilities.AR_GENERAL_HUMAN:
                    str = "qrc:/images/af_tracking_aid_face.svg";
                    break;
                case LT.Utilities.AR_GENERAL_HUMAN_ANIMAL:
                    str = "qrc:/images/af_tracking_aid_ani.svg";
                    break;
                case LT.Utilities.AR_GENERAL_FACE_EYE:
                    str = "qrc:/images/af_tracking_aid_eye.svg";
                    break;
// MC5229 判定追加 start
                case LT.Utilities.AR_GENERAL_TARGET_HUMAN:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_HUMAN_EYE_FACE_BODY:
                        str = "qrc:/images/af_tracking_hum_body.svg";
                        break;
                    case LT.Utilities.AR_PARTS_HUMAN_EYE_FACE:
                        str = "qrc:/images/af_tracking_hum_eyes.svg";
                        break;
                    case LT.Utilities.AR_PARTS_HUMAN_STREET:
                        str = "qrc:/images/af_tracking_hum_street.svg";
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_ANIMAL:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_ANIMAL_BODY:
                        str = "qrc:/images/af_tracking_ani_body.svg";
                        break;
                    case LT.Utilities.AR_PARTS_ANIMAL_EYE_BODY:
                        str = "qrc:/images/af_tracking_ani_eyes.svg";
                        break;
                    default:
                        break;
                    }
                    break;
// MC5229 判定追加 - MC5231 追加 start
                case LT.Utilities.AR_GENERAL_TARGET_CAR:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_CAR_WHOLE:
                        str = "qrc:/images/af_tracking_car_whole.svg";
                        break;
                    case LT.Utilities.AR_PARTS_CAR_PRIORITY:
                        str = "qrc:/images/af_tracking_car_priority.svg";
                        break;
                    default:
                        str = "qrc:/images/af_tracking_car.svg";
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_BIKE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_BIKE_WHOLE:
                        str = "qrc:/images/af_tracking_bike_whole.svg";
                        break;
                    case LT.Utilities.AR_PARTS_BIKE_HELMET:
                        str = "qrc:/images/af_tracking_bike_helmet.svg";
                        break;
                    default:
                        str = "qrc:/images/af_tracking_bike.svg";
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_TRAIN:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_TRAIN_LEADING_VEH:
                        str = "qrc:/images/af_tracking_train_leading_veh.svg";
                        break;
                    case LT.Utilities.AR_PARTS_TRAIN_PRIORITY:
                        str = "qrc:/images/af_tracking_train_priority.svg";
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_PLANE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_PLANE_AIRCRAFT:
                        str = "qrc:/images/af_tracking_plane_aircraft.svg";
                        break;
                    case LT.Utilities.AR_PARTS_PLANE_NOSE_PRIORITY:
                        str = "qrc:/images/af_tracking_plane_nose_priority.svg";
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_BICYCLE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_BICYCLE_WHOLE:
                        str = "qrc:/images/af_tracking_bike_whole.svg";
                        break;
                    case LT.Utilities.AR_PARTS_BICYCLE_PRIORITY:
                        str = "qrc:/images/af_tracking_bike_helmet.svg";
                        break;
                    default:
                        break;
                    }
                    break;
// MC5229 判定追加 - MC5231 追加 end
// MC5229 判定追加 end
                default:
                    break;
                }
            }
        }
        return str;
    }

    function getAFM_FullAreaText()
    {
        var str = qsTr("AFM_FullArea");
        //自動認識に対応か
        if(deviceAdapter.automaticRecoEnable) {
            if(deviceAdapter.automaticReco && deviceAdapter.autoRecognizeGeneralEnable)
            {
                switch(deviceAdapter.autoRecognizeGeneral)
                {
                case LT.Utilities.AR_GENERAL_HUMAN:
                    str = qsTr("AFM_FullArea_Human");
                    break;
                case LT.Utilities.AR_GENERAL_HUMAN_ANIMAL:
                    str = qsTr("AFM_FullArea_HumanAnimal");
                    break;
                case LT.Utilities.AR_GENERAL_FACE_EYE:
                    str = qsTr("AFM_FullArea_FaceEye");
                    break;
// MC5229 判定追加 start
                case LT.Utilities.AR_GENERAL_TARGET_HUMAN:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_HUMAN_EYE_FACE_BODY:
                        str = qsTr("AFM_FullArea_Detection") + "\n" + qsTr("AFM_Detection_HumanEyeFaceBody");
                        break;
                    case LT.Utilities.AR_PARTS_HUMAN_EYE_FACE:
                        str = qsTr("AFM_FullArea_Detection") + "\n" + qsTr("AFM_Detection_HumanEyeFace");
                        break;
                    case LT.Utilities.AR_PARTS_HUMAN_STREET:
                        str = qsTr("AFM_FullArea_Detection") + "\n" + qsTr("AFM_Detection_HumanStreet");
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_ANIMAL:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_ANIMAL_BODY:
                            str = qsTr("AFM_FullArea_Detection") + "\n" + qsTr("AFM_Detection_AnimalBody");
                        break;
                    case LT.Utilities.AR_PARTS_ANIMAL_EYE_BODY:
                            str = qsTr("AFM_FullArea_Detection") + "\n" + qsTr("AFM_Detection_AnimalEyeBody");
                        break;
                    default:
                        break;
                    }
                    break;
// MC5229 判定追加 - MC5231 追加 start
                case LT.Utilities.AR_GENERAL_TARGET_CAR:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_CAR_WHOLE:
                        str = qsTr("AFM_FullArea_Detection") + "\n" + qsTr("AFM_Detection_Car_Whole");
                        break;
                    case LT.Utilities.AR_PARTS_CAR_PRIORITY:
                        str = qsTr("AFM_FullArea_Detection") + "\n" + qsTr("AFM_Detection_Car_Priority");
                        break;
                    default:
                        str = qsTr("AFM_FullArea_Detection") + "\n" + qsTr("AFM_Detection_Car");
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_BIKE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_BIKE_WHOLE:
                        str = qsTr("AFM_FullArea_Detection") + "\n" + qsTr("AFM_Detection_Bike_Whole");
                        break;
                    case LT.Utilities.AR_PARTS_BIKE_HELMET:
                        str = qsTr("AFM_FullArea_Detection") + "\n" + qsTr("AFM_Detection_Bike_Helmet");
                        break;
                    default:
                        str = qsTr("AFM_FullArea_Detection") + "\n" + qsTr("AFM_Detection_Motorcycle");
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_TRAIN:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_TRAIN_LEADING_VEH:
                        str = qsTr("AFM_FullArea_Detection") + "\n" + qsTr("AFM_Detection_Train_Leading_Veh");
                        break;
                    case LT.Utilities.AR_PARTS_TRAIN_PRIORITY:
                        str = qsTr("AFM_FullArea_Detection") + "\n" + qsTr("AFM_Detection_Train_Priority");
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_PLANE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_PLANE_AIRCRAFT:
                        str = qsTr("AFM_FullArea_Detection") + "\n" + qsTr("AFM_Detection_Plane_Aircraft");
                        break;
                    case LT.Utilities.AR_PARTS_PLANE_NOSE_PRIORITY:
                        str = qsTr("AFM_FullArea_Detection") + "\n" + qsTr("AFM_Detection_Plane_Nose_Priority");
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_BICYCLE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_BICYCLE_WHOLE:
                        str = qsTr("AFM_FullArea_Detection") + "\n" + qsTr("AFM_Detection_Bicycle_Whole");
                        break;
                    case LT.Utilities.AR_PARTS_BICYCLE_PRIORITY:
                        str = qsTr("AFM_FullArea_Detection") + "\n" + qsTr("AFM_Detection_Bicycle_Priority");
                        break;
                    default:
                        break;
                    }
                    break;
// MC5229 判定追加 - MC5231 追加 end
// MC5229 判定追加 end
                default:
                    break;
                }
            }
        }
        return str;
    }
    function getAFM_FullAreaImg()
    {
        var str = "qrc:/images/376_225point.svg";
        //自動認識に対応か
        if(deviceAdapter.automaticRecoEnable) {
            if(deviceAdapter.automaticReco && deviceAdapter.autoRecognizeGeneralEnable)
            {
                switch(deviceAdapter.autoRecognizeGeneral)
                {
                case LT.Utilities.AR_GENERAL_HUMAN:
                    str = "qrc:/images/af_area_225point_aid_face.svg";
                    break;
                case LT.Utilities.AR_GENERAL_HUMAN_ANIMAL:
                    str = "qrc:/images/af_area_225point_aid_ani.svg";
                    break;
                case LT.Utilities.AR_GENERAL_FACE_EYE:
                    str = "qrc:/images/af_area_225point_aid_eye.svg";
                    break;
// MC5229 判定追加 start
                case LT.Utilities.AR_GENERAL_TARGET_HUMAN:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_HUMAN_EYE_FACE_BODY:
                        str = "qrc:/images/af_225_hum_body.svg";
                        break;
                    case LT.Utilities.AR_PARTS_HUMAN_EYE_FACE:
                        str = "qrc:/images/af_225_hum_eyes.svg";
                        break;
                    case LT.Utilities.AR_PARTS_HUMAN_STREET:
                        str = "qrc:/images/af_225_hum_street.svg";
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_ANIMAL:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_ANIMAL_BODY:
                        str = "qrc:/images/af_225_ani_body.svg";
                        break;
                    case LT.Utilities.AR_PARTS_ANIMAL_EYE_BODY:
                        str = "qrc:/images/af_225_ani_eyes.svg";
                        break;
                    default:
                        break;
                    }
                    break;
// MC5229 判定追加 - MC5231 追加 start
                case LT.Utilities.AR_GENERAL_TARGET_CAR:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_CAR_WHOLE:
                        str = "qrc:/images/af_225_car_whole.svg";
                        break;
                    case LT.Utilities.AR_PARTS_CAR_PRIORITY:
                        str = "qrc:/images/af_225_car_priority.svg";
                        break;
                    default:
                        str = "qrc:/images/af_225_car.svg";
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_BIKE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_BIKE_WHOLE:
                        str = "qrc:/images/af_225_bike_whole.svg";
                        break;
                    case LT.Utilities.AR_PARTS_BIKE_HELMET:
                        str = "qrc:/images/af_225_bike_helmet.svg";
                        break;
                    default:
                        str = "qrc:/images/af_225_bike.svg"
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_TRAIN:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_TRAIN_LEADING_VEH:
                        str = "qrc:/images/af_225_train_leading_veh.svg";
                        break;
                    case LT.Utilities.AR_PARTS_TRAIN_PRIORITY:
                        str = "qrc:/images/af_225_train_priority.svg";
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_PLANE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_PLANE_AIRCRAFT:
                        str = "qrc:/images/af_225_plane_aircraft.svg";
                        break;
                    case LT.Utilities.AR_PARTS_PLANE_NOSE_PRIORITY:
                        str = "qrc:/images/af_225_plane_nose_priority.svg";
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_BICYCLE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_BICYCLE_WHOLE:
                        str = "qrc:/images/af_225_bike_whole.svg";
                        break;
                    case LT.Utilities.AR_PARTS_BICYCLE_PRIORITY:
                        str = "qrc:/images/af_225_bike_helmet.svg";
                        break;
                    default:
                        break;
                    }
                    break;
// MC5229 判定追加 - MC5231 追加 end
// MC5229 判定追加 end
                default:
                    break;
                }
            }
        }
        return str;
    }

    function getAFM_VertHoriText()
    {
        var str = qsTr("AFM_VertHori");
        //自動認識に対応か
        if(deviceAdapter.automaticRecoEnable) {
            if(deviceAdapter.automaticReco && deviceAdapter.autoRecognizeGeneralEnable)
            {
                switch(deviceAdapter.autoRecognizeGeneral)
                {
                case LT.Utilities.AR_GENERAL_HUMAN:
                    str = qsTr("AFM_VertHori_Human");
                    break;
                case LT.Utilities.AR_GENERAL_HUMAN_ANIMAL:
                    str = qsTr("AFM_VertHori_HumanAnimal");
                    break;
                case LT.Utilities.AR_GENERAL_FACE_EYE:
                    str = qsTr("AFM_VertHori_FaceEye");
                    break;
// MC5229 判定追加 start
                case LT.Utilities.AR_GENERAL_TARGET_HUMAN:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_HUMAN_EYE_FACE_BODY:
                        str = qsTr("AFM_VertHori_Detection") + "\n" + qsTr("AFM_Detection_HumanEyeFaceBody");
                        break;
                    case LT.Utilities.AR_PARTS_HUMAN_EYE_FACE:
                        str = qsTr("AFM_VertHori_Detection") + "\n" + qsTr("AFM_Detection_HumanEyeFace");
                        break;
                    case LT.Utilities.AR_PARTS_HUMAN_STREET:
                        str = qsTr("AFM_VertHori_Detection") + "\n" + qsTr("AFM_Detection_HumanStreet");
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_ANIMAL:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_ANIMAL_BODY:
                            str = qsTr("AFM_VertHori_Detection") + "\n" + qsTr("AFM_Detection_AnimalBody");
                        break;
                    case LT.Utilities.AR_PARTS_ANIMAL_EYE_BODY:
                            str = qsTr("AFM_VertHori_Detection") + "\n" + qsTr("AFM_Detection_AnimalEyeBody");
                        break;
                    default:
                        break;
                    }
                    break;
// MC5229 判定追加 - MC5231 追加 start
                case LT.Utilities.AR_GENERAL_TARGET_CAR:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_CAR_WHOLE:
                            str = qsTr("AFM_VertHori_Detection") + "\n" + qsTr("AFM_Detection_Car_Whole");
                        break;
                    case LT.Utilities.AR_PARTS_CAR_PRIORITY:
                            str = qsTr("AFM_VertHori_Detection") + "\n" + qsTr("AFM_Detection_Car_Priority");
                        break;
                    default:
                        str = qsTr("AFM_VertHori_Detection") + "\n" + qsTr("AFM_Detection_Car");
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_BIKE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_BIKE_WHOLE:
                            str = qsTr("AFM_VertHori_Detection") + "\n" + qsTr("AFM_Detection_Bike_Whole");
                        break;
                    case LT.Utilities.AR_PARTS_BIKE_HELMET:
                            str = qsTr("AFM_VertHori_Detection") + "\n" + qsTr("AFM_Detection_Bike_Helmet");
                        break;
                    default:
                        str = qsTr("AFM_VertHori_Detection") + "\n" + qsTr("AFM_Detection_Motorcycle");
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_TRAIN:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_TRAIN_LEADING_VEH:
                            str = qsTr("AFM_VertHori_Detection") + "\n" + qsTr("AFM_Detection_Train_Leading_Veh");
                        break;
                    case LT.Utilities.AR_PARTS_TRAIN_PRIORITY:
                            str = qsTr("AFM_VertHori_Detection") + "\n" + qsTr("AFM_Detection_Train_Priority");
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_PLANE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_PLANE_AIRCRAFT:
                            str = qsTr("AFM_VertHori_Detection") + "\n" + qsTr("AFM_Detection_Plane_Aircraft");
                        break;
                    case LT.Utilities.AR_PARTS_PLANE_NOSE_PRIORITY:
                            str = qsTr("AFM_VertHori_Detection") + "\n" + qsTr("AFM_Detection_Plane_Nose_Priority");
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_BICYCLE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_BICYCLE_WHOLE:
                            str = qsTr("AFM_VertHori_Detection") + "\n" + qsTr("AFM_Detection_Bicycle_Whole");
                        break;
                    case LT.Utilities.AR_PARTS_BICYCLE_PRIORITY:
                            str = qsTr("AFM_VertHori_Detection") + "\n" + qsTr("AFM_Detection_Bicycle_Priority");
                        break;
                    default:
                        break;
                    }
                    break;
// MC5229 判定追加 - MC5231 追加 end
// MC5229 判定追加 end
                default:
                    break;
                }
            }
        }
        return str;
    }
    function getAFM_VertHoriImg()
    {
        var str = "qrc:/images/377_kstm.svg";
        //自動認識に対応か
        if(deviceAdapter.automaticRecoEnable) {
            if(deviceAdapter.automaticReco && deviceAdapter.autoRecognizeGeneralEnable)
            {
                switch(deviceAdapter.autoRecognizeGeneral)
                {
                case LT.Utilities.AR_GENERAL_HUMAN:
                    str = "qrc:/images/af_area_kstm_aid_face.svg";
                    break;
                case LT.Utilities.AR_GENERAL_HUMAN_ANIMAL:
                    str = "qrc:/images/af_area_kstm_aid_ani.svg";
                    break;
                case LT.Utilities.AR_GENERAL_FACE_EYE:
                    str = "qrc:/images/af_area_kstm_aid_eye.svg";
                    break;
// MC5229 判定追加 start
                case LT.Utilities.AR_GENERAL_TARGET_HUMAN:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_HUMAN_EYE_FACE_BODY:
                        str = "qrc:/images/af_vh_hum_body.svg";
                        break;
                    case LT.Utilities.AR_PARTS_HUMAN_EYE_FACE:
                        str = "qrc:/images/af_vh_hum_eyes.svg";
                        break;
                    case LT.Utilities.AR_PARTS_HUMAN_STREET:
                        str = "qrc:/images/af_vh_hum_street.svg";
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_ANIMAL:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_ANIMAL_BODY:
                        str = "qrc:/images/af_vh_ani_body.svg";
                        break;
                    case LT.Utilities.AR_PARTS_ANIMAL_EYE_BODY:
                        str = "qrc:/images/af_vh_ani_eyes.svg";
                        break;
                    default:
                        break;
                    }
                    break;
// MC5229 判定追加 - MC5231 追加 start
                case LT.Utilities.AR_GENERAL_TARGET_CAR:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_CAR_WHOLE:
                        str = "qrc:/images/af_vh_car_whole.svg";
                        break;
                    case LT.Utilities.AR_PARTS_CAR_PRIORITY:
                        str = "qrc:/images/af_vh_car_priority.svg";
                        break;
                    default:
                        str = "qrc:/images/af_vh_car.svg";
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_BIKE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_BIKE_WHOLE:
                        str = "qrc:/images/af_vh_bike_whole.svg";
                        break;
                    case LT.Utilities.AR_PARTS_BIKE_HELMET:
                        str = "qrc:/images/af_vh_bike_helmet.svg";
                        break;
                    default:
                        str = "qrc:/images/af_vh_bike.svg";
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_TRAIN:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_TRAIN_LEADING_VEH:
                        str = "qrc:/images/af_vh_train_leading_veh.svg";
                        break;
                    case LT.Utilities.AR_PARTS_TRAIN_PRIORITY:
                        str = "qrc:/images/af_vh_train_priority.svg";
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_PLANE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_PLANE_AIRCRAFT:
                        str = "qrc:/images/af_vh_plane_aircraft.svg";
                        break;
                    case LT.Utilities.AR_PARTS_PLANE_NOSE_PRIORITY:
                        str = "qrc:/images/af_vh_plane_nose_priority.svg";
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_BICYCLE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_BICYCLE_WHOLE:
                        str = "qrc:/images/af_vh_bike_whole.svg";
                        break;
                    case LT.Utilities.AR_PARTS_BICYCLE_PRIORITY:
                        str = "qrc:/images/af_vh_bike_helmet.svg";
                        break;
                    default:
                        break;
                    }
                    break;
// MC5229 判定追加 - MC5231 追加 end
// MC5229 判定追加 end
                default:
                    break;
                }
            }
        }
        return str;
    }

    function getAFM_EllipseText()
    {
        var str = qsTr("AFM_Ellipse");
        //自動認識に対応か
        if(deviceAdapter.automaticRecoEnable) {
            if(deviceAdapter.automaticReco && deviceAdapter.autoRecognizeGeneralEnable)
            {
                switch(deviceAdapter.autoRecognizeGeneral)
                {
                case LT.Utilities.AR_GENERAL_HUMAN:
                    str = qsTr("AFM_Ellipse_Human");
                    break;
                case LT.Utilities.AR_GENERAL_HUMAN_ANIMAL:
                    str = qsTr("AFM_Ellipse_HumanAnimal");
                    break;
                case LT.Utilities.AR_GENERAL_FACE_EYE:
                    str = qsTr("AFM_Ellipse_FaceEye");
                    break;
// MC5229 判定追加 start
                case LT.Utilities.AR_GENERAL_TARGET_HUMAN:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_HUMAN_EYE_FACE_BODY:
                        str = qsTr("AFM_Ellipse_Detection") + "\n" + qsTr("AFM_Detection_HumanEyeFaceBody");
                        break;
                    case LT.Utilities.AR_PARTS_HUMAN_EYE_FACE:
                        str = qsTr("AFM_Ellipse_Detection") + "\n" + qsTr("AFM_Detection_HumanEyeFace");
                        break;
                    case LT.Utilities.AR_PARTS_HUMAN_STREET:
                        str = qsTr("AFM_Ellipse_Detection") + "\n" + qsTr("AFM_Detection_HumanStreet");
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_ANIMAL:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_ANIMAL_BODY:
                            str = qsTr("AFM_Ellipse_Detection") + "\n" + qsTr("AFM_Detection_AnimalBody");
                        break;
                    case LT.Utilities.AR_PARTS_ANIMAL_EYE_BODY:
                            str = qsTr("AFM_Ellipse_Detection") + "\n" + qsTr("AFM_Detection_AnimalEyeBody");
                        break;
                    default:
                        break;
                    }
                    break;
// MC5229 判定追加 - MC5231 追加 start
                case LT.Utilities.AR_GENERAL_TARGET_CAR:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_CAR_WHOLE:
                        str = qsTr("AFM_Ellipse_Detection") + "\n" + qsTr("AFM_Detection_Car_Whole");
                        break;
                    case LT.Utilities.AR_PARTS_CAR_PRIORITY:
                        str = qsTr("AFM_Ellipse_Detection") + "\n" + qsTr("AFM_Detection_Car_Priority");
                        break;
                    default:
                        str = qsTr("AFM_Ellipse_Detection") + "\n" + qsTr("AFM_Detection_Car");
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_BIKE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_BIKE_WHOLE:
                        str = qsTr("AFM_Ellipse_Detection") + "\n" + qsTr("AFM_Detection_Bike_Whole");
                        break;
                    case LT.Utilities.AR_PARTS_BIKE_HELMET:
                        str = qsTr("AFM_Ellipse_Detection") + "\n" + qsTr("AFM_Detection_Bike_Helmet");
                        break;
                    default:
                        str = qsTr("AFM_Ellipse_Detection") + "\n" + qsTr("AFM_Detection_Motorcycle");
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_TRAIN:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_TRAIN_LEADING_VEH:
                        str = qsTr("AFM_Ellipse_Detection") + "\n" + qsTr("AFM_Detection_Train_Leading_Veh");
                        break;
                    case LT.Utilities.AR_PARTS_TRAIN_PRIORITY:
                        str = qsTr("AFM_Ellipse_Detection") + "\n" + qsTr("AFM_Detection_Train_Priority");
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_PLANE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_PLANE_AIRCRAFT:
                        str = qsTr("AFM_Ellipse_Detection") + "\n" + qsTr("AFM_Detection_Plane_Aircraft");
                        break;
                    case LT.Utilities.AR_PARTS_PLANE_NOSE_PRIORITY:
                        str = qsTr("AFM_Ellipse_Detection") + "\n" + qsTr("AFM_Detection_Plane_Nose_Priority");
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_BICYCLE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_BICYCLE_WHOLE:
                        str = qsTr("AFM_Ellipse_Detection") + "\n" + qsTr("AFM_Detection_Bicycle_Whole");
                        break;
                    case LT.Utilities.AR_PARTS_BICYCLE_PRIORITY:
                        str = qsTr("AFM_Ellipse_Detection") + "\n" + qsTr("AFM_Detection_Bicycle_Priority");
                        break;
                    default:
                        break;
                    }
                    break;
// MC5229 判定追加 - MC5231 追加 end
// MC5229 判定追加 end
                default:
                    break;
                }
            }
        }
        return str;
    }
    function getAFM_EllipseImg()
    {
        var str = "qrc:/images/eclipse.svg";
        //自動認識に対応か
        if(deviceAdapter.automaticRecoEnable) {
            if(deviceAdapter.automaticReco && deviceAdapter.autoRecognizeGeneralEnable)
            {
                switch(deviceAdapter.autoRecognizeGeneral)
                {
                case LT.Utilities.AR_GENERAL_HUMAN:
                    str = "qrc:/images/af_area_kstm_center_aid_face.svg";
                    break;
                case LT.Utilities.AR_GENERAL_HUMAN_ANIMAL:
                    str = "qrc:/images/af_area_kstm_center_aid_ani.svg";
                    break;
                case LT.Utilities.AR_GENERAL_FACE_EYE:
                    str = "qrc:/images/af_area_kstm_center_aid_eye.svg";
                    break;
// MC5229 判定追加 start
                case LT.Utilities.AR_GENERAL_TARGET_HUMAN:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_HUMAN_EYE_FACE_BODY:
                        str = "qrc:/images/af_ellipse_hum_body.svg";
                        break;
                    case LT.Utilities.AR_PARTS_HUMAN_EYE_FACE:
                        str = "qrc:/images/af_ellipse_hum_eyes.svg";
                        break;
                    case LT.Utilities.AR_PARTS_HUMAN_STREET:
                        str = "qrc:/images/af_ellipse_hum_street.svg";
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_ANIMAL:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_ANIMAL_BODY:
                        str = "qrc:/images/af_ellipse_ani_body.svg";
                        break;
                    case LT.Utilities.AR_PARTS_ANIMAL_EYE_BODY:
                        str = "qrc:/images/af_ellipse_ani_eyes.svg";
                        break;
                    default:
                        break;
                    }
                    break;
// MC5229 判定追加 - MC5231 追加 start
                case LT.Utilities.AR_GENERAL_TARGET_CAR:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_CAR_WHOLE:
                        str = "qrc:/images/af_ellipse_car_whole.svg";
                        break;
                    case LT.Utilities.AR_PARTS_CAR_PRIORITY:
                        str = "qrc:/images/af_ellipse_car_priority.svg";
                        break;
                    default:
                        str = "qrc:/images/af_ellipse_car.svg";
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_BIKE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_BIKE_WHOLE:
                        str = "qrc:/images/af_ellipse_bike_whole.svg";
                        break;
                    case LT.Utilities.AR_PARTS_BIKE_HELMET:
                        str = "qrc:/images/af_ellipse_bike_helmet.svg";
                        break;
                    default:
                        str = "qrc:/images/af_ellipse_bike.svg";
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_TRAIN:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_TRAIN_LEADING_VEH:
                        str = "qrc:/images/af_ellipse_train_leading_veh.svg";
                        break;
                    case LT.Utilities.AR_PARTS_TRAIN_PRIORITY:
                        str = "qrc:/images/af_ellipse_train_priority.svg";
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_PLANE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_PLANE_AIRCRAFT:
                        str = "qrc:/images/af_ellipse_plane_aircraft.svg";
                        break;
                    case LT.Utilities.AR_PARTS_PLANE_NOSE_PRIORITY:
                        str = "qrc:/images/af_ellipse_plane_nose_priority.svg";
                        break;
                    default:
                        break;
                    }
                    break;
                case LT.Utilities.AR_GENERAL_TARGET_BICYCLE:
                    switch(deviceAdapter.autoRecognizeParts)      // 部位判定
                    {
                    case LT.Utilities.AR_PARTS_BICYCLE_WHOLE:
                        str = "qrc:/images/af_ellipse_bike_whole.svg";
                        break;
                    case LT.Utilities.AR_PARTS_BICYCLE_PRIORITY:
                        str = "qrc:/images/af_ellipse_bike_helmet.svg";
                        break;
                    default:
                        break;
                    }
                    break;
// MC5229 判定追加 - MC5231 追加 end
// MC5229 判定追加 end
                default:
                    break;
                }
            }
        }
        return str;
    }

    function getCreativeVideoAE_OptionText_P()
    {
        var text;
        if(deviceAdapter.shotModeStatus === LT.Utilities.Shot_Mode_Status_Unknown)
        {
            text = qsTr("CreativeVideo-P");
        }else{
            text = qsTr("Video-P");
        }
        return text;
    }
    function getCreativeVideoAE_OptionText_A()
    {
        var text;
        if(deviceAdapter.shotModeStatus === LT.Utilities.Shot_Mode_Status_Unknown)
        {
            text = qsTr("CreativeVideo-A");
        }else{
            text = qsTr("Video-A");
        }
        return text;
    }
    function getCreativeVideoAE_OptionText_S()
    {
        var text;
        if(deviceAdapter.shotModeStatus === LT.Utilities.Shot_Mode_Status_Unknown)
        {
            text = qsTr("CreativeVideo-S");
        }else{
            text = qsTr("Video-S");
        }
        return text;
    }
    function getCreativeVideoAE_OptionText_M()
    {
        var text;
        if(deviceAdapter.shotModeStatus === LT.Utilities.Shot_Mode_Status_Unknown)
        {
            text = qsTr("CreativeVideo-M");
        }else{
            text = qsTr("Video-M");
        }
        return text;
    }
}
