import QtQuick 2.6

import "qrc:/qml"
import LT 1.0 as LT

/*! \qmltype LTMainPSComponentsProvider
    \inqmlmodule LT

    \brief
    LTMainPhotoStylePopup に表示するコンポーネントの組を提供するオブジェクトです
 */
QtObject {
    // object names
    readonly property string sliderComponentName:   "sliderComponent"
    // MC8259 tsutsumi 追加
    readonly property string sliderComponentPositiveName:   "sliderComponentPositive"
    readonly property string popupBtnComponentName: "popupBtnComponent"
    readonly property string blankComponentName:    "blankComponent"
    readonly property string lblImgName:            "lblImg"
    readonly property string lblTitleName:          "lblTitle"
    readonly property string btnOptionName:         "btnOption"
    readonly property string sliderName:            "slider"

    // photo style components
    readonly property string standardCompName:      "psStandard"
    readonly property string vividCompName:         "psVivid"
    readonly property string naturalCompName:       "psNatural"
    readonly property string monoChromeCompName:    "psMonoChrome"
    readonly property string lMonoChromeCompName:   "psLMonoChrome"
    readonly property string landScapeCompName:     "psLandScape"
    readonly property string portraitCompName:      "psPortrait"
    readonly property string customCompName:        "psCustom"
    readonly property string custom2CompName:       "psCustom2"
    readonly property string custom3CompName:       "psCustom3"
    readonly property string custom4CompName:       "psCustom4"
    readonly property string cinelikeDCompName:     "psCinelikeD"
    readonly property string cinelikeVCompName:     "psCinelikeV"
    readonly property string like709CompName:       "psLike709"
    readonly property string linearGammaCompName:   "psLinearGamma"
    readonly property string vLogLCompName:         "psVLogL"
    readonly property string vLogCompName:          "psVLog"
    // MC8259 tsutsumi 追加 start
    readonly property string arriLogC3CompName:     "psARRILogC3"
    // MC8259 tsutsumi 追加 snd
    readonly property string remoteCameraCompName:  "psRemoteCamera"    // MC5245, MC8245 2024/09

    // IVC >> MC893 >> start >> No.3
    readonly property string cinelikeD2CompName:    "psCinelikeD2"
    readonly property string cinelikeV2CompName:    "psCinelikeV2"
    // IVC << MC893 << end << No.3
    readonly property string cinelikeA2CompName:    "psCinelikeA2"      // 2024/06/04 仕様
    readonly property string lMonoChromeDCompName:  "psLMonoChromeD"

    // ivc >> start >> No.2
    readonly property string hybridLogGammaCompName:"psHybridLogGamma"
    readonly property string flatCompName:          "psFlat"
    readonly property string photoStyle1CompName:   "psPhotoStyle1"
    readonly property string photoStyle2CompName:   "psPhotoStyle2"
    readonly property string photoStyle3CompName:   "psPhotoStyle3"
    readonly property string photoStyle4CompName:   "psPhotoStyle4"
    readonly property string photoStyle5CompName:   "psPhotoStyle5"
    readonly property string photoStyle6CompName:   "psPhotoStyle6"
    readonly property string photoStyle7CompName:   "psPhotoStyle7"
    readonly property string photoStyle8CompName:   "psPhotoStyle8"
    readonly property string photoStyle9CompName:   "psPhotoStyle9"
    readonly property string photoStyle10CompName:  "psPhotoStyle10"
    // ivc >> start >> #9860
    readonly property string hlgStandardCompName:   "psHLGStandard"
    readonly property string hlgMonochromeCompName: "psHLGMonochrome"
    // ivc << end << #9860
    // ivc << end << No.2
    readonly property string hlgForGSeriesCompName: "psHLGForGSeries"   // 2019/10/16 Panasonic Nakano
    //20秋FwUp
    readonly property string lMonoChromeSCompName:  "psLMonoChromeS"
    readonly property string lClassicNeoCompName:  "psLClassicNeo"
    readonly property string hlgFullRangeCompName:  "psHLGFullRange"
    readonly property string realtimeLUTCompName:  "psRealTimeLUT"
    readonly property string leicaMonochromeCompName: "psLeicaMonochrome"

    // photo style targets
    // ivc >> start >> No.2
    readonly property string basePhotoStyleTargetName:"pscBasePhotoStyle"
    // ivc << end << No.2
    // MC8259 tsutsumi 追加
    readonly property string basePhotoStyle2TargetName:"pscBasePhotoStyle2"

    readonly property string contrastTargetName:    "pscContrast"
    readonly property string sharpnessTargetName:   "pscSharpness"
    readonly property string noiseRedTargetName:    "pscNoiseReduction"
    readonly property string saturationTargetName:  "pscSaturation"
    readonly property string chrPhaseTargetName:    "pscChromaPhase"
    readonly property string filterTargetName:      "pscFilter"
    readonly property string grainTargetName:       "pscGrain"
    readonly property string kneeModeTargetName:    "pscKneeMode"
    readonly property string colorToneTargetName:   "pscColorTone"

    // ivc >> start >> No.2
    readonly property string highLightTargetName:   "pscHighLight"
    readonly property string shadowTargetName:      "pscShadow"
    readonly property string isoTargetName:         "pscISO"
    readonly property string wbTargetName:          "pscWB"

    // MC5229
    readonly property string gainTargetName:        "pscGain"

    // MC8259 tsutsumi 追加
    readonly property string densityTargetName:     "pscDensity"
    readonly property string density2TargetName:    "pscDensity2"

    // IVC >> Ver.1.7 >> start >> No.2
    readonly property string dualISOTargetName:     "pscDualISO"
    // IVC << Ver.1.7 << end << No.2
    readonly property string colorNoiseTargetName:  "pscColorNoise"
    readonly property string lutTargetName:  "pscLUT"
    // M8259 tsutsumi 追加
    readonly property string lut2TargetName: "pscLUT2"

    property real updatePopup:                      0
    property real savePopupY:                       0
    // ivc << end << No.2

    readonly property var componentList: [
        // ivc >> start >> No.2
        {
            target: basePhotoStyleTargetName,
            value: LT.Utilities.PSC_BasePhotoStyle,
        },
        // ivc << end << No.2
        {
            target: contrastTargetName,
            value: LT.Utilities.PSC_Contrast,
        },
        {
            target: sharpnessTargetName,
            value: LT.Utilities.PSC_Sharpness,
        },
        {
            target: noiseRedTargetName,
            value: LT.Utilities.PSC_NR,
        },
        {
            target: saturationTargetName,
            value: LT.Utilities.PSC_Saturation,
        },
        {
            target: chrPhaseTargetName,
            value: LT.Utilities.PSC_ChromaPhase,
        },
        {
            target: filterTargetName,
            value: LT.Utilities.PSC_Filter,
        },
        {
            target: grainTargetName,
            value: LT.Utilities.PSC_Grain,
        },
        {
            target: kneeModeTargetName,
            value: LT.Utilities.PSC_KneeMode,
        },
        {
            target: colorToneTargetName,
            value: LT.Utilities.PSC_ColorTone,
        },
        // ivc >> start >> No.2
        {
            target: highLightTargetName,
            value: LT.Utilities.PSC_HighLight,
        },
        {
            target: shadowTargetName,
            value: LT.Utilities.PSC_Shadow,
        },
        // 2020/08/25 Panasonic Kashihara Dual Native ISO > ISO > WB
        // ivc << end << No.2
        // IVC >> Ver.1.7 >> start >> No.2
        {
            target: dualISOTargetName,
            value: LT.Utilities.PSC_DualISO,
        },
        // IVC << Ver.1.7 << end << No.2
        {
            target: isoTargetName,
            value: LT.Utilities.PSC_ISO,
        },
        {
            target: wbTargetName,
            value: LT.Utilities.PSC_WB,
        },
        // ivc << end << No.2
        {
            target: colorNoiseTargetName,
            value: LT.Utilities.PSC_ColorNoise,
        },
        {
            target: lutTargetName,
            value: LT.Utilities.PSC_LUT,
        },
        // MC5229
        {
            target: gainTargetName,
            value: LT.Utilities.PSC_Gain,
        },
        // MC8259 tsutsumi 追加
        {
            target: basePhotoStyle2TargetName,
            value: LT.Utilities.PSC_BasePhotoStyle2,
        },
        {
            target: lut2TargetName,
            value: LT.Utilities.PSC_LUT2,
        },
        {
           target: densityTargetName,
            value: LT.Utilities.PSC_Density,
        },
        {
           target: density2TargetName,
           value: LT.Utilities.PSC_Density2,
        },
    ]

    /*!
        フォトスタイルを選択する LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var photoStyle: [
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_Remote_Camera(UE160)"),
                value: LT.Utilities.PS_Remote_Camera_UE160,
                optionImage: "qrc:/images/ps_ptz.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_Standard"),
                value: LT.Utilities.PS_Standard,
                optionImage: "qrc:/images/380_std..svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_Vivid"),
                value: LT.Utilities.PS_Vivid,
                optionImage: "qrc:/images/381_vivd.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_Natural"),
                value: LT.Utilities.PS_Natural,
                optionImage: "qrc:/images/382_nat.svg",
            }
        },
        //20秋FwUp
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTranslate("LTOptionComponentsProvider", "PS_LClassicNeo"),
                value: LT.Utilities.PS_LClassicNeo,
                optionImage: "qrc:/images/l_clas_n.svg",
            }
        },
        // nakhuong >> start >> No.2
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_Flat"),
                value: LT.Utilities.PS_Flat,
                optionImage: "qrc:/images/flat.svg",
            }
        },
        // nakhuong << end << No.2
        // '20秋FwUp（Gシリーズ → Sシリーズに合わせる：人物、風景をフラットの後ろに配置）
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_LandScape"),
                value: LT.Utilities.PS_LandScape,
                optionImage: "qrc:/images/385_scny.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_Portrait"),
                value: LT.Utilities.PS_Portrait,
                optionImage: "qrc:/images/386_port.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_Monochrome"),
                value: LT.Utilities.PS_Monochrome,
                optionImage: "qrc:/images/383_mono.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_LMonochrome"),
                value: LT.Utilities.PS_LMonochrome,
                optionImage: "qrc:/images/384_lmono.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_LMonochromeD"),
                value: LT.Utilities.PS_LMonochromeD,
                optionImage: "qrc:/images/lmono_d.svg",
            }
        },
        //20秋FwUp
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTranslate("LTOptionComponentsProvider", "PS_LMonochromeS"),
                value: LT.Utilities.PS_LMonochromeS,
                optionImage: "qrc:/images/a_l_mono_s.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTranslate("LTOptionComponentsProvider", "PS_Leica_Monochrome"),
                value: LT.Utilities.PS_Leica_Monochrome,
                optionImage: "qrc:/images/leica_mono.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_Custom"),
                value: LT.Utilities.PS_Custom,
                optionImage: "qrc:/images/387_cust1.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_Custom2"),
                value: LT.Utilities.PS_Custom2,
                optionImage: "qrc:/images/388_cust2.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_Custom3"),
                value: LT.Utilities.PS_Custom3,
                optionImage: "qrc:/images/389_cust3.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_Custom4"),
                value: LT.Utilities.PS_Custom4,
                optionImage: "qrc:/images/390_cust4.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_CinelikeD"),
                value: LT.Utilities.PS_CinelikeD,
                optionImage: "qrc:/images/391_cned.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_CinelikeV"),
                value: LT.Utilities.PS_CinelikeV,
                optionImage: "qrc:/images/392_cnev.svg",
            }
        },
        // MC8241 以降　2024/7
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_CineLike_A2"),
                value: LT.Utilities.PS_CineLike_A2,
                optionImage: "qrc:/images/cnea2.svg",
            }
        },
        // '20秋FwUp（Gシリーズ → Sシリーズに合わせる：シネライクD2、シネライクV2は、709ライクの前に配置）
// IVC >> MC893 >> start >> No.3
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_CineLike_D2"),
                value: LT.Utilities.PS_CineLike_D2,
                optionImage: "qrc:/images/cned2.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_CineLike_V2"),
                value: LT.Utilities.PS_CineLike_V2,
                optionImage: "qrc:/images/cnev2.svg",
            }
        },
// IVC << MC893 << end << No.3
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_Like_709"),
                value: LT.Utilities.PS_Like_709,
                optionImage: "qrc:/images/525_709l.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_Linear_Gamma"),
                value: LT.Utilities.PS_Linear_Gamma,
                optionImage: "qrc:/images/524_hlg.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_V_LogL"),
                value: LT.Utilities.PS_V_Log_L,
                optionImage: "qrc:/images/519_vlogl.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_V_Log"),
                value: LT.Utilities.PS_V_Log,
                optionImage: "qrc:/images/519_vlog.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_ARRI_LogC3"),
                value: LT.Utilities.PS_ARRI_LogC3,
                optionImage: "qrc:/images/arri_logc3.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_RealTime_LUT"),
                value: LT.Utilities.PS_RealTime_LUT,
                optionImage: "qrc:/images/ps_realtime_lut.svg",
            }
        },
        // '20秋FwUp（Gシリーズ：ハイブリッドログガンマ）
        // MC5229 にて、ハイブリッドログガンマ の位置を MC551以降にあわせて変更
        {   // 2019/10/16 Panasonic Nakano
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_HLG_For_G_Series"),
                value: LT.Utilities.PS_HLG_For_G_Series,
                optionImage: "qrc:/images/hlg_for_g.svg",
            }
        },
        // '20秋FwUp（Sシリーズ：2100ライク(HLG)）
        // ivc >> start >> No.2
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_Hybrid_Grama"),
                value: LT.Utilities.PS_Hybrid_Grama,
                optionImage: "qrc:/images/hlg.svg",
            }
        },
        // ivc << end << No.2
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_HLG_FullRange"),
                value: LT.Utilities.PS_HLG_FullRange,
                optionImage: "qrc:/images/hlg_f.svg",
            }
        },
        // ivc >> start >> No.2
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_PhotoStyle1"),
                value: LT.Utilities.PS_PhotoStyle1,
                optionImage: "qrc:/images/ps_01.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_PhotoStyle2"),
                value: LT.Utilities.PS_PhotoStyle2,
                optionImage: "qrc:/images/ps_02.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_PhotoStyle3"),
                value: LT.Utilities.PS_PhotoStyle3,
                optionImage: "qrc:/images/ps_03.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_PhotoStyle4"),
                value: LT.Utilities.PS_PhotoStyle4,
                optionImage: "qrc:/images/ps_04.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_PhotoStyle5"),
                value: LT.Utilities.PS_PhotoStyle5,
                optionImage: "qrc:/images/ps_05.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_PhotoStyle6"),
                value: LT.Utilities.PS_PhotoStyle6,
                optionImage: "qrc:/images/ps_06.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_PhotoStyle7"),
                value: LT.Utilities.PS_PhotoStyle7,
                optionImage: "qrc:/images/ps_07.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_PhotoStyle8"),
                value: LT.Utilities.PS_PhotoStyle8,
                optionImage: "qrc:/images/ps_08.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_PhotoStyle9"),
                value: LT.Utilities.PS_PhotoStyle9,
                optionImage: "qrc:/images/ps_09.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_PhotoStyle10"),
                value: LT.Utilities.PS_PhotoStyle10,
                optionImage: "qrc:/images/ps_10.svg",
            }
        },
        // ivc << end << No.2
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_HLG_Standard"),
                value: LT.Utilities.PS_HLG_Standard,
                optionImage: "qrc:/images/hlg_std.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_HLG_Monochrome"),
                value: LT.Utilities.PS_HLG_Monochrome,
                optionImage: "qrc:/images/hlg_mono.svg",
            }
        },
    ]

    // ivc >> start >> No.2
    /*!
        フォトスタイルを選択する LTOptionButtonPopup に表示するコンポーネントの組です
     */
    // ivc >> start >> USBTHRV140-13
    readonly property var pscBasePhotoStyle: [
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_Remote_Camera(UE160)"),
                value: LT.Utilities.PS_Remote_Camera_UE160,
                optionImage: "qrc:/images/ps_ptz.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_Standard"),
                value: LT.Utilities.PS_Standard,
                optionImage: "qrc:/images/380_std..svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_Vivid"),
                value: LT.Utilities.PS_Vivid,
                optionImage: "qrc:/images/381_vivd.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_Natural"),
                value: LT.Utilities.PS_Natural,
                optionImage: "qrc:/images/382_nat.svg",
            }
        },
        //20秋FwUp
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTranslate("LTOptionComponentsProvider", "PS_LClassicNeo"),
                value: LT.Utilities.PS_LClassicNeo,
                optionImage: "qrc:/images/l_clas_n.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_Flat"),
                value: LT.Utilities.PS_Flat,
                optionImage: "qrc:/images/flat.svg",
            }
        },
        // '20秋FwUp（Gシリーズ → Sシリーズに合わせる：人物、風景をフラットの後ろに配置）
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_LandScape"),
                value: LT.Utilities.PS_LandScape,
                optionImage: "qrc:/images/385_scny.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_Portrait"),
                value: LT.Utilities.PS_Portrait,
                optionImage: "qrc:/images/386_port.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_Monochrome"),
                value: LT.Utilities.PS_Monochrome,
                optionImage: "qrc:/images/383_mono.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_LMonochrome"),
                value: LT.Utilities.PS_LMonochrome,
                optionImage: "qrc:/images/384_lmono.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_LMonochromeD"),
                value: LT.Utilities.PS_LMonochromeD,
                optionImage: "qrc:/images/lmono_d.svg",
            }
        },
        //20秋FwUp
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTranslate("LTOptionComponentsProvider", "PS_LMonochromeS"),
                value: LT.Utilities.PS_LMonochromeS,
                optionImage: "qrc:/images/a_l_mono_s.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTranslate("LTOptionComponentsProvider", "PS_Leica_Monochrome"),
                value: LT.Utilities.PS_Leica_Monochrome,
                optionImage: "qrc:/images/leica_mono.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_Custom"),
                value: LT.Utilities.PS_Custom,
                optionImage: "qrc:/images/387_cust1.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_Custom2"),
                value: LT.Utilities.PS_Custom2,
                optionImage: "qrc:/images/388_cust2.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_Custom3"),
                value: LT.Utilities.PS_Custom3,
                optionImage: "qrc:/images/389_cust3.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_Custom4"),
                value: LT.Utilities.PS_Custom4,
                optionImage: "qrc:/images/390_cust4.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_CinelikeD"),
                value: LT.Utilities.PS_CinelikeD,
                optionImage: "qrc:/images/391_cned.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_CinelikeV"),
                value: LT.Utilities.PS_CinelikeV,
                optionImage: "qrc:/images/392_cnev.svg",
            }
        },
        // MC8241 以降　2024/7
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_CineLike_A2"),
                value: LT.Utilities.PS_CineLike_A2,
                optionImage: "qrc:/images/cnea2.svg",
            }
        },
        // '20秋FwUp（Gシリーズ → Sシリーズに合わせる）
        // IVC >> MC893 >> start >> No.3
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_CineLike_D2"),
                value: LT.Utilities.PS_CineLike_D2,
                optionImage: "qrc:/images/cned2.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_CineLike_V2"),
                value: LT.Utilities.PS_CineLike_V2,
                optionImage: "qrc:/images/cnev2.svg",
            }
        },
        // IVC << MC893 << end << No.3
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_Like_709"),
                value: LT.Utilities.PS_Like_709,
                optionImage: "qrc:/images/525_709l.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_Linear_Gamma"),
                value: LT.Utilities.PS_Linear_Gamma,
                optionImage: "qrc:/images/524_hlg.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_V_LogL"),
                value: LT.Utilities.PS_V_Log_L,
                optionImage: "qrc:/images/519_vlogl.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_V_Log"),
                value: LT.Utilities.PS_V_Log,
                optionImage: "qrc:/images/519_vlog.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_ARRI_LogC3"),
                value: LT.Utilities.PS_ARRI_LogC3,
                optionImage: "qrc:/images/arri_logc3.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_RealTime_LUT"),
                value: LT.Utilities.PS_RealTime_LUT,
                optionImage: "qrc:/images/ps_realtime_lut.svg",
            }
        },
        // '20秋FwUp（Gシリーズ：ハイブリッドログガンマ）
        // MC5229 にて、ハイブリッドログガンマ の位置を MC551以降にあわせて変更
        {   // 2019/10/16 Panasonic Nakano
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_HLG_For_G_Series"),
                value: LT.Utilities.PS_HLG_For_G_Series,
                optionImage: "qrc:/images/hlg_for_g.svg",
            }
        },
        // '20秋FwUp（Sシリーズ：2100ライク(HLG)）
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_Hybrid_Grama"),
                value: LT.Utilities.PS_Hybrid_Grama,
                optionImage: "qrc:/images/hlg.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_HLG_FullRange"),
                value: LT.Utilities.PS_HLG_FullRange,
                optionImage: "qrc:/images/hlg_f.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_HLG_Standard"),
                value: LT.Utilities.PS_HLG_Standard,
                optionImage: "qrc:/images/hlg_std.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_HLG_Monochrome"),
                value: LT.Utilities.PS_HLG_Monochrome,
                optionImage: "qrc:/images/hlg_mono.svg",
            }
        },
    ]
    // ivc << end << USBTHRV140-13
    // ivc << end << No.2

    /*!
      　　2023 tsutsumi 追加
        フォトスタイルを選択する LTOptionButtonPopup に表示するコンポーネントの組です
        アプリからは操作できないがプログラム的準備
     */
    readonly property var pscBasePhotoStyle2: [
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_Remote_Camera(UE160)"),
                value: LT.Utilities.PS_Remote_Camera_UE160,
                optionImage: "qrc:/images/ps_ptz.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_Standard"),
                value: LT.Utilities.PS_Standard,
                optionImage: "qrc:/images/380_std..svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_Vivid"),
                value: LT.Utilities.PS_Vivid,
                optionImage: "qrc:/images/381_vivd.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_Natural"),
                value: LT.Utilities.PS_Natural,
                optionImage: "qrc:/images/382_nat.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTranslate("LTOptionComponentsProvider", "PS_LClassicNeo"),
                value: LT.Utilities.PS_LClassicNeo,
                optionImage: "qrc:/images/l_clas_n.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_Flat"),
                value: LT.Utilities.PS_Flat,
                optionImage: "qrc:/images/flat.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_LandScape"),
                value: LT.Utilities.PS_LandScape,
                optionImage: "qrc:/images/385_scny.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_Portrait"),
                value: LT.Utilities.PS_Portrait,
                optionImage: "qrc:/images/386_port.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_Monochrome"),
                value: LT.Utilities.PS_Monochrome,
                optionImage: "qrc:/images/383_mono.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_LMonochrome"),
                value: LT.Utilities.PS_LMonochrome,
                optionImage: "qrc:/images/384_lmono.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_LMonochromeD"),
                value: LT.Utilities.PS_LMonochromeD,
                optionImage: "qrc:/images/lmono_d.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTranslate("LTOptionComponentsProvider", "PS_LMonochromeS"),
                value: LT.Utilities.PS_LMonochromeS,
                optionImage: "qrc:/images/a_l_mono_s.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTranslate("LTOptionComponentsProvider", "PS_Leica_Monochrome"),
                value: LT.Utilities.PS_Leica_Monochrome,
                optionImage: "qrc:/images/leica_mono.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_Custom"),
                value: LT.Utilities.PS_Custom,
                optionImage: "qrc:/images/387_cust1.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_Custom2"),
                value: LT.Utilities.PS_Custom2,
                optionImage: "qrc:/images/388_cust2.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_Custom3"),
                value: LT.Utilities.PS_Custom3,
                optionImage: "qrc:/images/389_cust3.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_Custom4"),
                value: LT.Utilities.PS_Custom4,
                optionImage: "qrc:/images/390_cust4.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_CinelikeD"),
                value: LT.Utilities.PS_CinelikeD,
                optionImage: "qrc:/images/391_cned.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_CinelikeV"),
                value: LT.Utilities.PS_CinelikeV,
                optionImage: "qrc:/images/392_cnev.svg",
            }
        },
        // MC8241 以降　2024/7
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_CineLike_A2"),
                value: LT.Utilities.PS_CineLike_A2,
                optionImage: "qrc:/images/cnea2.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_CineLike_D2"),
                value: LT.Utilities.PS_CineLike_D2,
                optionImage: "qrc:/images/cned2.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_CineLike_V2"),
                value: LT.Utilities.PS_CineLike_V2,
                optionImage: "qrc:/images/cnev2.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_Like_709"),
                value: LT.Utilities.PS_Like_709,
                optionImage: "qrc:/images/525_709l.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_Linear_Gamma"),
                value: LT.Utilities.PS_Linear_Gamma,
                optionImage: "qrc:/images/524_hlg.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_V_LogL"),
                value: LT.Utilities.PS_V_Log_L,
                optionImage: "qrc:/images/519_vlogl.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_V_Log"),
                value: LT.Utilities.PS_V_Log,
                optionImage: "qrc:/images/519_vlog.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_RealTime_LUT"),
                value: LT.Utilities.PS_RealTime_LUT,
                optionImage: "qrc:/images/ps_realtime_lut.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_HLG_For_G_Series"),
                value: LT.Utilities.PS_HLG_For_G_Series,
                optionImage: "qrc:/images/hlg_for_g.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_Hybrid_Grama"),
                value: LT.Utilities.PS_Hybrid_Grama,
                optionImage: "qrc:/images/hlg.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_HLG_FullRange"),
                value: LT.Utilities.PS_HLG_FullRange,
                optionImage: "qrc:/images/hlg_f.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_HLG_Standard"),
                value: LT.Utilities.PS_HLG_Standard,
                optionImage: "qrc:/images/hlg_std.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_HLG_Monochrome"),
                value: LT.Utilities.PS_HLG_Monochrome,
                optionImage: "qrc:/images/hlg_mono.svg",
            }
        },
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImageAndTextPopup",
                optionText: qsTr("PS_ARRI_LogC3"),
                value: LT.Utilities.PS_ARRI_LogC3,
                optionImage: "qrc:/images/arri_logc3.svg",
            }
        },
    ]
    // ivc << end << USBTHRV140-13
    // ivc << end << No.2

    /*!
        standard を選択する LTMainPhotoStylePopup に表示するコンポーネントの組です
     */
    readonly property var psStandard: [
        // '20秋FwUp（Gシリーズ → Sシリーズに合わせる）
        {
            component: sliderComponent,
            properties: {
                target: contrastTargetName,
                value: LT.Utilities.PSC_Contrast,
                text: qsTr("PSC_Contrast"),
                source: "qrc:/images/ps_contrast.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: highLightTargetName,
                value: LT.Utilities.PSC_HighLight,
                text: qsTr("PSC_HighLight"),
                source: "qrc:/images/highlight.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: shadowTargetName,
                value: LT.Utilities.PSC_Shadow,
                text: qsTr("PSC_Shadow"),
                source: "qrc:/images/shadow.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: saturationTargetName,
                value: LT.Utilities.PSC_Saturation,
                text: qsTr("PSC_Saturation"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: colorToneTargetName,
                value: LT.Utilities.PSC_ColorTone,
                text: qsTr("PSC_ColorTone"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: chrPhaseTargetName,
                value: LT.Utilities.PSC_ChromaPhase,
                text: qsTr("PSC_ChromaPhase"),
                source: "qrc:/images/ps_saturation2.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: filterTargetName,
                value: LT.Utilities.PSC_Filter,
                text: qsTr("PSC_Filter"),
                source: "qrc:/images/ps_filter.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: grainTargetName,
                value: LT.Utilities.PSC_Grain,
                text: qsTr("PSC_Grain"),
                source: "qrc:/images/ps_granular.svg"
            }
        },
        //20秋FwUp
        {
            component: popupBtnComponent,
            properties: {
                target: colorNoiseTargetName,
                value: LT.Utilities.PSC_ColorNoise,
                text: qsTr("PSC_Grain_Color"),
                source: "qrc:/images/ps_granular_color.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: sharpnessTargetName,
                value: LT.Utilities.PSC_Sharpness,
                text: qsTr("PSC_Sharpness"),
                source: "qrc:/images/ps_sharpness.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: noiseRedTargetName,
                value: LT.Utilities.PSC_NR,
                text: qsTr("PSC_NoiseReduct"),
                source: "qrc:/images/ps_noisereduction.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: kneeModeTargetName,
                value: LT.Utilities.PSC_KneeMode,
                text: qsTr("PSC_KneeMode"),
                source: "qrc:/images/ps_knee.svg"
            }
        },
        // ivc >> start >> No.2
        {
            component: popupBtnComponent,
            properties: {
                target: isoTargetName,
                value: LT.Utilities.PSC_ISO,
                text: qsTr("PSC_ISO"),
                source: "qrc:/images/iso.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: wbTargetName,
                value: LT.Utilities.PSC_WB,
                text: qsTr("PSC_WB"),
                source: "qrc:/images/wb.svg"
            }
        },
        // ivc << end << No.2
        // MC5229
        {
            component: popupBtnComponent,
            properties: {
                target: gainTargetName,
                value: LT.Utilities.PSC_Gain,
                text: qsTr("PSC_GainSetting"),
                source: "qrc:/images/gain.svg"
            }
        },
    ]

    /*!
        vivid を選択する LTMainPhotoStylePopup に表示するコンポーネントの組です
     */
    readonly property var psVivid: [
        // '20秋FwUp（Gシリーズ → Sシリーズに合わせる）
        {
            component: sliderComponent,
            properties: {
                target: contrastTargetName,
                value: LT.Utilities.PSC_Contrast,
                text: qsTr("PSC_Contrast"),
                source: "qrc:/images/ps_contrast.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: highLightTargetName,
                value: LT.Utilities.PSC_HighLight,
                text: qsTr("PSC_HighLight"),
                source: "qrc:/images/highlight.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: shadowTargetName,
                value: LT.Utilities.PSC_Shadow,
                text: qsTr("PSC_Shadow"),
                source: "qrc:/images/shadow.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: saturationTargetName,
                value: LT.Utilities.PSC_Saturation,
                text: qsTr("PSC_Saturation"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: colorToneTargetName,
                value: LT.Utilities.PSC_ColorTone,
                text: qsTr("PSC_ColorTone"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: chrPhaseTargetName,
                value: LT.Utilities.PSC_ChromaPhase,
                text: qsTr("PSC_ChromaPhase"),
                source: "qrc:/images/ps_saturation2.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: filterTargetName,
                value: LT.Utilities.PSC_Filter,
                text: qsTr("PSC_Filter"),
                source: "qrc:/images/ps_filter.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: grainTargetName,
                value: LT.Utilities.PSC_Grain,
                text: qsTr("PSC_Grain"),
                source: "qrc:/images/ps_granular.svg"
            }
        },
        //20秋FwUp
        {
            component: popupBtnComponent,
            properties: {
                target: colorNoiseTargetName,
                value: LT.Utilities.PSC_ColorNoise,
                text: qsTr("PSC_Grain_Color"),
                source: "qrc:/images/ps_granular_color.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: sharpnessTargetName,
                value: LT.Utilities.PSC_Sharpness,
                text: qsTr("PSC_Sharpness"),
                source: "qrc:/images/ps_sharpness.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: noiseRedTargetName,
                value: LT.Utilities.PSC_NR,
                text: qsTr("PSC_NoiseReduct"),
                source: "qrc:/images/ps_noisereduction.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: kneeModeTargetName,
                value: LT.Utilities.PSC_KneeMode,
                text: qsTr("PSC_KneeMode"),
                source: "qrc:/images/ps_knee.svg"
            }
        },
        // ivc >> start >> No.2
        {
            component: popupBtnComponent,
            properties: {
                target: isoTargetName,
                value: LT.Utilities.PSC_ISO,
                text: qsTr("PSC_ISO"),
                source: "qrc:/images/iso.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: wbTargetName,
                value: LT.Utilities.PSC_WB,
                text: qsTr("PSC_WB"),
                source: "qrc:/images/wb.svg"
            }
        },
        // ivc << end << No.2
        // MC5229
        {
            component: popupBtnComponent,
            properties: {
                target: gainTargetName,
                value: LT.Utilities.PSC_Gain,
                text: qsTr("PSC_GainSetting"),
                source: "qrc:/images/gain.svg"
            }
        },
    ]

    /*!
        natural を選択する LTMainPhotoStylePopup に表示するコンポーネントの組です
     */
    readonly property var psNatural: [
        // '20秋FwUp（Gシリーズ → Sシリーズに合わせる）
        {
            component: sliderComponent,
            properties: {
                target: contrastTargetName,
                value: LT.Utilities.PSC_Contrast,
                text: qsTr("PSC_Contrast"),
                source: "qrc:/images/ps_contrast.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: highLightTargetName,
                value: LT.Utilities.PSC_HighLight,
                text: qsTr("PSC_HighLight"),
                source: "qrc:/images/highlight.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: shadowTargetName,
                value: LT.Utilities.PSC_Shadow,
                text: qsTr("PSC_Shadow"),
                source: "qrc:/images/shadow.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: saturationTargetName,
                value: LT.Utilities.PSC_Saturation,
                text: qsTr("PSC_Saturation"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: colorToneTargetName,
                value: LT.Utilities.PSC_ColorTone,
                text: qsTr("PSC_ColorTone"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: chrPhaseTargetName,
                value: LT.Utilities.PSC_ChromaPhase,
                text: qsTr("PSC_ChromaPhase"),
                source: "qrc:/images/ps_saturation2.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: filterTargetName,
                value: LT.Utilities.PSC_Filter,
                text: qsTr("PSC_Filter"),
                source: "qrc:/images/ps_filter.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: grainTargetName,
                value: LT.Utilities.PSC_Grain,
                text: qsTr("PSC_Grain"),
                source: "qrc:/images/ps_granular.svg"
            }
        },
        //20秋FwUp
        {
            component: popupBtnComponent,
            properties: {
                target: colorNoiseTargetName,
                value: LT.Utilities.PSC_ColorNoise,
                text: qsTr("PSC_Grain_Color"),
                source: "qrc:/images/ps_granular_color.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: sharpnessTargetName,
                value: LT.Utilities.PSC_Sharpness,
                text: qsTr("PSC_Sharpness"),
                source: "qrc:/images/ps_sharpness.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: noiseRedTargetName,
                value: LT.Utilities.PSC_NR,
                text: qsTr("PSC_NoiseReduct"),
                source: "qrc:/images/ps_noisereduction.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: kneeModeTargetName,
                value: LT.Utilities.PSC_KneeMode,
                text: qsTr("PSC_KneeMode"),
                source: "qrc:/images/ps_knee.svg"
            }
        },
        // ivc >> start >> No.2
        {
            component: popupBtnComponent,
            properties: {
                target: isoTargetName,
                value: LT.Utilities.PSC_ISO,
                text: qsTr("PSC_ISO"),
                source: "qrc:/images/iso.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: wbTargetName,
                value: LT.Utilities.PSC_WB,
                text: qsTr("PSC_WB"),
                source: "qrc:/images/wb.svg"
            }
        },
        // ivc << end << No.2
        // MC5229
        {
            component: popupBtnComponent,
            properties: {
                target: gainTargetName,
                value: LT.Utilities.PSC_Gain,
                text: qsTr("PSC_GainSetting"),
                source: "qrc:/images/gain.svg"
            }
        },
    ]

    /*!
        monoChrome を選択する LTMainPhotoStylePopup に表示するコンポーネントの組です
     */
    readonly property var psMonoChrome: [
        // '20秋FwUp（Gシリーズ → Sシリーズに合わせる）
        {
            component: sliderComponent,
            properties: {
                target: contrastTargetName,
                value: LT.Utilities.PSC_Contrast,
                text: qsTr("PSC_Contrast"),
                source: "qrc:/images/ps_contrast.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: highLightTargetName,
                value: LT.Utilities.PSC_HighLight,
                text: qsTr("PSC_HighLight"),
                source: "qrc:/images/highlight.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: shadowTargetName,
                value: LT.Utilities.PSC_Shadow,
                text: qsTr("PSC_Shadow"),
                source: "qrc:/images/shadow.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: saturationTargetName,
                value: LT.Utilities.PSC_Saturation,
                text: qsTr("PSC_Saturation"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: colorToneTargetName,
                value: LT.Utilities.PSC_ColorTone,
                text: qsTr("PSC_ColorTone"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: chrPhaseTargetName,
                value: LT.Utilities.PSC_ChromaPhase,
                text: qsTr("PSC_ChromaPhase"),
                source: "qrc:/images/ps_saturation2.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: filterTargetName,
                value: LT.Utilities.PSC_Filter,
                text: qsTr("PSC_Filter"),
                source: "qrc:/images/ps_filter.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: grainTargetName,
                value: LT.Utilities.PSC_Grain,
                text: qsTr("PSC_Grain"),
                source: "qrc:/images/ps_granular.svg"
            }
        },
        //20秋FwUp
        {
            component: popupBtnComponent,
            properties: {
                target: colorNoiseTargetName,
                value: LT.Utilities.PSC_ColorNoise,
                text: qsTr("PSC_Grain_Color"),
                source: "qrc:/images/ps_granular_color.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: sharpnessTargetName,
                value: LT.Utilities.PSC_Sharpness,
                text: qsTr("PSC_Sharpness"),
                source: "qrc:/images/ps_sharpness.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: noiseRedTargetName,
                value: LT.Utilities.PSC_NR,
                text: qsTr("PSC_NoiseReduct"),
                source: "qrc:/images/ps_noisereduction.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: kneeModeTargetName,
                value: LT.Utilities.PSC_KneeMode,
                text: qsTr("PSC_KneeMode"),
                source: "qrc:/images/ps_knee.svg"
            }
        },
        // ivc >> start >> No.2
        {
            component: popupBtnComponent,
            properties: {
                target: isoTargetName,
                value: LT.Utilities.PSC_ISO,
                text: qsTr("PSC_ISO"),
                source: "qrc:/images/iso.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: wbTargetName,
                value: LT.Utilities.PSC_WB,
                text: qsTr("PSC_WB"),
                source: "qrc:/images/wb.svg"
            }
        },
        // ivc << end << No.2
        // MC5229
        {
            component: popupBtnComponent,
            properties: {
                target: gainTargetName,
                value: LT.Utilities.PSC_Gain,
                text: qsTr("PSC_GainSetting"),
                source: "qrc:/images/gain.svg"
            }
        },
    ]

    /*!
        lMonoChrome を選択する LTMainPhotoStylePopup に表示するコンポーネントの組です
     */
    readonly property var psLMonoChrome: [
        // '20秋FwUp（Gシリーズ → Sシリーズに合わせる）
        {
            component: sliderComponent,
            properties: {
                target: contrastTargetName,
                value: LT.Utilities.PSC_Contrast,
                text: qsTr("PSC_Contrast"),
                source: "qrc:/images/ps_contrast.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: highLightTargetName,
                value: LT.Utilities.PSC_HighLight,
                text: qsTr("PSC_HighLight"),
                source: "qrc:/images/highlight.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: shadowTargetName,
                value: LT.Utilities.PSC_Shadow,
                text: qsTr("PSC_Shadow"),
                source: "qrc:/images/shadow.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: saturationTargetName,
                value: LT.Utilities.PSC_Saturation,
                text: qsTr("PSC_Saturation"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: colorToneTargetName,
                value: LT.Utilities.PSC_ColorTone,
                text: qsTr("PSC_ColorTone"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: chrPhaseTargetName,
                value: LT.Utilities.PSC_ChromaPhase,
                text: qsTr("PSC_ChromaPhase"),
                source: "qrc:/images/ps_saturation2.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: filterTargetName,
                value: LT.Utilities.PSC_Filter,
                text: qsTr("PSC_Filter"),
                source: "qrc:/images/ps_filter.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: grainTargetName,
                value: LT.Utilities.PSC_Grain,
                text: qsTr("PSC_Grain"),
                source: "qrc:/images/ps_granular.svg"
            }
        },
        //20秋FwUp
        {
            component: popupBtnComponent,
            properties: {
                target: colorNoiseTargetName,
                value: LT.Utilities.PSC_ColorNoise,
                text: qsTr("PSC_Grain_Color"),
                source: "qrc:/images/ps_granular_color.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: sharpnessTargetName,
                value: LT.Utilities.PSC_Sharpness,
                text: qsTr("PSC_Sharpness"),
                source: "qrc:/images/ps_sharpness.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: noiseRedTargetName,
                value: LT.Utilities.PSC_NR,
                text: qsTr("PSC_NoiseReduct"),
                source: "qrc:/images/ps_noisereduction.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: kneeModeTargetName,
                value: LT.Utilities.PSC_KneeMode,
                text: qsTr("PSC_KneeMode"),
                source: "qrc:/images/ps_knee.svg"
            }
        },
        // ivc >> start >> No.2
        {
            component: popupBtnComponent,
            properties: {
                target: isoTargetName,
                value: LT.Utilities.PSC_ISO,
                text: qsTr("PSC_ISO"),
                source: "qrc:/images/iso.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: wbTargetName,
                value: LT.Utilities.PSC_WB,
                text: qsTr("PSC_WB"),
                source: "qrc:/images/wb.svg"
            }
        },
        // ivc << end << No.2
        // MC5229
        {
            component: popupBtnComponent,
            properties: {
                target: gainTargetName,
                value: LT.Utilities.PSC_Gain,
                text: qsTr("PSC_GainSetting"),
                source: "qrc:/images/gain.svg"
            }
        },
    ]

    /*!
        landScape を選択する LTMainPhotoStylePopup に表示するコンポーネントの組です
     */
    readonly property var psLandScape: [
        // '20秋FwUp（Gシリーズ → Sシリーズに合わせる）
        {
            component: sliderComponent,
            properties: {
                target: contrastTargetName,
                value: LT.Utilities.PSC_Contrast,
                text: qsTr("PSC_Contrast"),
                source: "qrc:/images/ps_contrast.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: highLightTargetName,
                value: LT.Utilities.PSC_HighLight,
                text: qsTr("PSC_HighLight"),
                source: "qrc:/images/highlight.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: shadowTargetName,
                value: LT.Utilities.PSC_Shadow,
                text: qsTr("PSC_Shadow"),
                source: "qrc:/images/shadow.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: saturationTargetName,
                value: LT.Utilities.PSC_Saturation,
                text: qsTr("PSC_Saturation"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: colorToneTargetName,
                value: LT.Utilities.PSC_ColorTone,
                text: qsTr("PSC_ColorTone"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: chrPhaseTargetName,
                value: LT.Utilities.PSC_ChromaPhase,
                text: qsTr("PSC_ChromaPhase"),
                source: "qrc:/images/ps_saturation2.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: filterTargetName,
                value: LT.Utilities.PSC_Filter,
                text: qsTr("PSC_Filter"),
                source: "qrc:/images/ps_filter.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: grainTargetName,
                value: LT.Utilities.PSC_Grain,
                text: qsTr("PSC_Grain"),
                source: "qrc:/images/ps_granular.svg"
            }
        },
        //20秋FwUp
        {
            component: popupBtnComponent,
            properties: {
                target: colorNoiseTargetName,
                value: LT.Utilities.PSC_ColorNoise,
                text: qsTr("PSC_Grain_Color"),
                source: "qrc:/images/ps_granular_color.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: sharpnessTargetName,
                value: LT.Utilities.PSC_Sharpness,
                text: qsTr("PSC_Sharpness"),
                source: "qrc:/images/ps_sharpness.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: noiseRedTargetName,
                value: LT.Utilities.PSC_NR,
                text: qsTr("PSC_NoiseReduct"),
                source: "qrc:/images/ps_noisereduction.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: kneeModeTargetName,
                value: LT.Utilities.PSC_KneeMode,
                text: qsTr("PSC_KneeMode"),
                source: "qrc:/images/ps_knee.svg"
            }
        },
        // ivc >> start >> No.2
        {
            component: popupBtnComponent,
            properties: {
                target: isoTargetName,
                value: LT.Utilities.PSC_ISO,
                text: qsTr("PSC_ISO"),
                source: "qrc:/images/iso.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: wbTargetName,
                value: LT.Utilities.PSC_WB,
                text: qsTr("PSC_WB"),
                source: "qrc:/images/wb.svg"
            }
        },
        // ivc << end << No.2
        // MC5229
        {
            component: popupBtnComponent,
            properties: {
                target: gainTargetName,
                value: LT.Utilities.PSC_Gain,
                text: qsTr("PSC_GainSetting"),
                source: "qrc:/images/gain.svg"
            }
        },
    ]

    /*!
        portrait を選択する LTMainPhotoStylePopup に表示するコンポーネントの組です
     */
    readonly property var psPortrait: [
        // '20秋FwUp（Gシリーズ → Sシリーズに合わせる）
        {
            component: sliderComponent,
            properties: {
                target: contrastTargetName,
                value: LT.Utilities.PSC_Contrast,
                text: qsTr("PSC_Contrast"),
                source: "qrc:/images/ps_contrast.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: highLightTargetName,
                value: LT.Utilities.PSC_HighLight,
                text: qsTr("PSC_HighLight"),
                source: "qrc:/images/highlight.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: shadowTargetName,
                value: LT.Utilities.PSC_Shadow,
                text: qsTr("PSC_Shadow"),
                source: "qrc:/images/shadow.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: saturationTargetName,
                value: LT.Utilities.PSC_Saturation,
                text: qsTr("PSC_Saturation"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: colorToneTargetName,
                value: LT.Utilities.PSC_ColorTone,
                text: qsTr("PSC_ColorTone"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: chrPhaseTargetName,
                value: LT.Utilities.PSC_ChromaPhase,
                text: qsTr("PSC_ChromaPhase"),
                source: "qrc:/images/ps_saturation2.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: filterTargetName,
                value: LT.Utilities.PSC_Filter,
                text: qsTr("PSC_Filter"),
                source: "qrc:/images/ps_filter.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: grainTargetName,
                value: LT.Utilities.PSC_Grain,
                text: qsTr("PSC_Grain"),
                source: "qrc:/images/ps_granular.svg"
            }
        },
        //20秋FwUp
        {
            component: popupBtnComponent,
            properties: {
                target: colorNoiseTargetName,
                value: LT.Utilities.PSC_ColorNoise,
                text: qsTr("PSC_Grain_Color"),
                source: "qrc:/images/ps_granular_color.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: sharpnessTargetName,
                value: LT.Utilities.PSC_Sharpness,
                text: qsTr("PSC_Sharpness"),
                source: "qrc:/images/ps_sharpness.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: noiseRedTargetName,
                value: LT.Utilities.PSC_NR,
                text: qsTr("PSC_NoiseReduct"),
                source: "qrc:/images/ps_noisereduction.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: kneeModeTargetName,
                value: LT.Utilities.PSC_KneeMode,
                text: qsTr("PSC_KneeMode"),
                source: "qrc:/images/ps_knee.svg"
            }
        },
        // ivc >> start >> No.2
        {
            component: popupBtnComponent,
            properties: {
                target: isoTargetName,
                value: LT.Utilities.PSC_ISO,
                text: qsTr("PSC_ISO"),
                source: "qrc:/images/iso.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: wbTargetName,
                value: LT.Utilities.PSC_WB,
                text: qsTr("PSC_WB"),
                source: "qrc:/images/wb.svg"
            }
        },
        // ivc << end << No.2
        // MC5229
        {
            component: popupBtnComponent,
            properties: {
                target: gainTargetName,
                value: LT.Utilities.PSC_Gain,
                text: qsTr("PSC_GainSetting"),
                source: "qrc:/images/gain.svg"
            }
        },
    ]

    /*!
        custom を選択する LTMainPhotoStylePopup に表示するコンポーネントの組です
     */
    readonly property var psCustom: [
        // '20秋FwUp（Gシリーズ → Sシリーズに合わせる）
        {
            component: sliderComponent,
            properties: {
                target: contrastTargetName,
                value: LT.Utilities.PSC_Contrast,
                text: qsTr("PSC_Contrast"),
                source: "qrc:/images/ps_contrast.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: highLightTargetName,
                value: LT.Utilities.PSC_HighLight,
                text: qsTr("PSC_HighLight"),
                source: "qrc:/images/highlight.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: shadowTargetName,
                value: LT.Utilities.PSC_Shadow,
                text: qsTr("PSC_Shadow"),
                source: "qrc:/images/shadow.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: saturationTargetName,
                value: LT.Utilities.PSC_Saturation,
                text: qsTr("PSC_Saturation"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: colorToneTargetName,
                value: LT.Utilities.PSC_ColorTone,
                text: qsTr("PSC_ColorTone"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: chrPhaseTargetName,
                value: LT.Utilities.PSC_ChromaPhase,
                text: qsTr("PSC_ChromaPhase"),
                source: "qrc:/images/ps_saturation2.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: filterTargetName,
                value: LT.Utilities.PSC_Filter,
                text: qsTr("PSC_Filter"),
                source: "qrc:/images/ps_filter.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: grainTargetName,
                value: LT.Utilities.PSC_Grain,
                text: qsTr("PSC_Grain"),
                source: "qrc:/images/ps_granular.svg"
            }
        },
        //20秋FwUp
        {
            component: popupBtnComponent,
            properties: {
                target: colorNoiseTargetName,
                value: LT.Utilities.PSC_ColorNoise,
                text: qsTr("PSC_Grain_Color"),
                source: "qrc:/images/ps_granular_color.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: sharpnessTargetName,
                value: LT.Utilities.PSC_Sharpness,
                text: qsTr("PSC_Sharpness"),
                source: "qrc:/images/ps_sharpness.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: noiseRedTargetName,
                value: LT.Utilities.PSC_NR,
                text: qsTr("PSC_NoiseReduct"),
                source: "qrc:/images/ps_noisereduction.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: kneeModeTargetName,
                value: LT.Utilities.PSC_KneeMode,
                text: qsTr("PSC_KneeMode"),
                source: "qrc:/images/ps_knee.svg"
            }
        },
        // ivc >> start >> No.2
        {
            component: popupBtnComponent,
            properties: {
                target: isoTargetName,
                value: LT.Utilities.PSC_ISO,
                text: qsTr("PSC_ISO"),
                source: "qrc:/images/iso.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: wbTargetName,
                value: LT.Utilities.PSC_WB,
                text: qsTr("PSC_WB"),
                source: "qrc:/images/wb.svg"
            }
        },
        // ivc << end << No.2
        // MC5229
        {
            component: popupBtnComponent,
            properties: {
                target: gainTargetName,
                value: LT.Utilities.PSC_Gain,
                text: qsTr("PSC_GainSetting"),
                source: "qrc:/images/gain.svg"
            }
        },
    ]

    /*!
        custom2 を選択する LTMainPhotoStylePopup に表示するコンポーネントの組です
     */
    readonly property var psCustom2: [
        // '20秋FwUp（Gシリーズ → Sシリーズに合わせる）
        {
            component: sliderComponent,
            properties: {
                target: contrastTargetName,
                value: LT.Utilities.PSC_Contrast,
                text: qsTr("PSC_Contrast"),
                source: "qrc:/images/ps_contrast.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: highLightTargetName,
                value: LT.Utilities.PSC_HighLight,
                text: qsTr("PSC_HighLight"),
                source: "qrc:/images/highlight.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: shadowTargetName,
                value: LT.Utilities.PSC_Shadow,
                text: qsTr("PSC_Shadow"),
                source: "qrc:/images/shadow.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: saturationTargetName,
                value: LT.Utilities.PSC_Saturation,
                text: qsTr("PSC_Saturation"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: colorToneTargetName,
                value: LT.Utilities.PSC_ColorTone,
                text: qsTr("PSC_ColorTone"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: chrPhaseTargetName,
                value: LT.Utilities.PSC_ChromaPhase,
                text: qsTr("PSC_ChromaPhase"),
                source: "qrc:/images/ps_saturation2.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: filterTargetName,
                value: LT.Utilities.PSC_Filter,
                text: qsTr("PSC_Filter"),
                source: "qrc:/images/ps_filter.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: grainTargetName,
                value: LT.Utilities.PSC_Grain,
                text: qsTr("PSC_Grain"),
                source: "qrc:/images/ps_granular.svg"
            }
        },
        //20秋FwUp
        {
            component: popupBtnComponent,
            properties: {
                target: colorNoiseTargetName,
                value: LT.Utilities.PSC_ColorNoise,
                text: qsTr("PSC_Grain_Color"),
                source: "qrc:/images/ps_granular_color.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: sharpnessTargetName,
                value: LT.Utilities.PSC_Sharpness,
                text: qsTr("PSC_Sharpness"),
                source: "qrc:/images/ps_sharpness.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: noiseRedTargetName,
                value: LT.Utilities.PSC_NR,
                text: qsTr("PSC_NoiseReduct"),
                source: "qrc:/images/ps_noisereduction.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: kneeModeTargetName,
                value: LT.Utilities.PSC_KneeMode,
                text: qsTr("PSC_KneeMode"),
                source: "qrc:/images/ps_knee.svg"
            }
        },
        // ivc >> start >> No.2
        {
            component: popupBtnComponent,
            properties: {
                target: isoTargetName,
                value: LT.Utilities.PSC_ISO,
                text: qsTr("PSC_ISO"),
                source: "qrc:/images/iso.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: wbTargetName,
                value: LT.Utilities.PSC_WB,
                text: qsTr("PSC_WB"),
                source: "qrc:/images/wb.svg"
            }
        },
        // ivc << end << No.2
        // MC5229
        {
            component: popupBtnComponent,
            properties: {
                target: gainTargetName,
                value: LT.Utilities.PSC_Gain,
                text: qsTr("PSC_GainSetting"),
                source: "qrc:/images/gain.svg"
            }
        },
    ]

    /*!
        custom3 を選択する LTMainPhotoStylePopup に表示するコンポーネントの組です
     */
    readonly property var psCustom3: [
        // '20秋FwUp（Gシリーズ → Sシリーズに合わせる）
        {
            component: sliderComponent,
            properties: {
                target: contrastTargetName,
                value: LT.Utilities.PSC_Contrast,
                text: qsTr("PSC_Contrast"),
                source: "qrc:/images/ps_contrast.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: highLightTargetName,
                value: LT.Utilities.PSC_HighLight,
                text: qsTr("PSC_HighLight"),
                source: "qrc:/images/highlight.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: shadowTargetName,
                value: LT.Utilities.PSC_Shadow,
                text: qsTr("PSC_Shadow"),
                source: "qrc:/images/shadow.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: saturationTargetName,
                value: LT.Utilities.PSC_Saturation,
                text: qsTr("PSC_Saturation"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: colorToneTargetName,
                value: LT.Utilities.PSC_ColorTone,
                text: qsTr("PSC_ColorTone"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: chrPhaseTargetName,
                value: LT.Utilities.PSC_ChromaPhase,
                text: qsTr("PSC_ChromaPhase"),
                source: "qrc:/images/ps_saturation2.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: filterTargetName,
                value: LT.Utilities.PSC_Filter,
                text: qsTr("PSC_Filter"),
                source: "qrc:/images/ps_filter.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: grainTargetName,
                value: LT.Utilities.PSC_Grain,
                text: qsTr("PSC_Grain"),
                source: "qrc:/images/ps_granular.svg"
            }
        },
        //20秋FwUp
        {
            component: popupBtnComponent,
            properties: {
                target: colorNoiseTargetName,
                value: LT.Utilities.PSC_ColorNoise,
                text: qsTr("PSC_Grain_Color"),
                source: "qrc:/images/ps_granular_color.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: sharpnessTargetName,
                value: LT.Utilities.PSC_Sharpness,
                text: qsTr("PSC_Sharpness"),
                source: "qrc:/images/ps_sharpness.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: noiseRedTargetName,
                value: LT.Utilities.PSC_NR,
                text: qsTr("PSC_NoiseReduct"),
                source: "qrc:/images/ps_noisereduction.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: kneeModeTargetName,
                value: LT.Utilities.PSC_KneeMode,
                text: qsTr("PSC_KneeMode"),
                source: "qrc:/images/ps_knee.svg"
            }
        },
        // ivc >> start >> No.2
        {
            component: popupBtnComponent,
            properties: {
                target: isoTargetName,
                value: LT.Utilities.PSC_ISO,
                text: qsTr("PSC_ISO"),
                source: "qrc:/images/iso.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: wbTargetName,
                value: LT.Utilities.PSC_WB,
                text: qsTr("PSC_WB"),
                source: "qrc:/images/wb.svg"
            }
        },
        // ivc << end << No.2
        // MC5229
        {
            component: popupBtnComponent,
            properties: {
                target: gainTargetName,
                value: LT.Utilities.PSC_Gain,
                text: qsTr("PSC_GainSetting"),
                source: "qrc:/images/gain.svg"
            }
        },
    ]

    /*!
        custom4 を選択する LTMainPhotoStylePopup に表示するコンポーネントの組です
     */
    readonly property var psCustom4: [
        // '20秋FwUp（Gシリーズ → Sシリーズに合わせる）
        {
            component: sliderComponent,
            properties: {
                target: contrastTargetName,
                value: LT.Utilities.PSC_Contrast,
                text: qsTr("PSC_Contrast"),
                source: "qrc:/images/ps_contrast.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: highLightTargetName,
                value: LT.Utilities.PSC_HighLight,
                text: qsTr("PSC_HighLight"),
                source: "qrc:/images/highlight.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: shadowTargetName,
                value: LT.Utilities.PSC_Shadow,
                text: qsTr("PSC_Shadow"),
                source: "qrc:/images/shadow.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: saturationTargetName,
                value: LT.Utilities.PSC_Saturation,
                text: qsTr("PSC_Saturation"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: colorToneTargetName,
                value: LT.Utilities.PSC_ColorTone,
                text: qsTr("PSC_ColorTone"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: chrPhaseTargetName,
                value: LT.Utilities.PSC_ChromaPhase,
                text: qsTr("PSC_ChromaPhase"),
                source: "qrc:/images/ps_saturation2.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: filterTargetName,
                value: LT.Utilities.PSC_Filter,
                text: qsTr("PSC_Filter"),
                source: "qrc:/images/ps_filter.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: grainTargetName,
                value: LT.Utilities.PSC_Grain,
                text: qsTr("PSC_Grain"),
                source: "qrc:/images/ps_granular.svg"
            }
        },
        //20秋FwUp
        {
            component: popupBtnComponent,
            properties: {
                target: colorNoiseTargetName,
                value: LT.Utilities.PSC_ColorNoise,
                text: qsTr("PSC_Grain_Color"),
                source: "qrc:/images/ps_granular_color.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: sharpnessTargetName,
                value: LT.Utilities.PSC_Sharpness,
                text: qsTr("PSC_Sharpness"),
                source: "qrc:/images/ps_sharpness.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: noiseRedTargetName,
                value: LT.Utilities.PSC_NR,
                text: qsTr("PSC_NoiseReduct"),
                source: "qrc:/images/ps_noisereduction.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: kneeModeTargetName,
                value: LT.Utilities.PSC_KneeMode,
                text: qsTr("PSC_KneeMode"),
                source: "qrc:/images/ps_knee.svg"
            }
        },
        // ivc >> start >> No.2
        {
            component: popupBtnComponent,
            properties: {
                target: isoTargetName,
                value: LT.Utilities.PSC_ISO,
                text: qsTr("PSC_ISO"),
                source: "qrc:/images/iso.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: wbTargetName,
                value: LT.Utilities.PSC_WB,
                text: qsTr("PSC_WB"),
                source: "qrc:/images/wb.svg"
            }
        },
        // ivc << end << No.2
        // MC5229
        {
            component: popupBtnComponent,
            properties: {
                target: gainTargetName,
                value: LT.Utilities.PSC_Gain,
                text: qsTr("PSC_GainSetting"),
                source: "qrc:/images/gain.svg"
            }
        },
    ]

    // ivc >> start >> No.2
    /*!
        flat を選択する LTMainPhotoStylePopup に表示するコンポーネントの組です
    */
    readonly property var psFlat: [
        // '20秋FwUp（Gシリーズ → Sシリーズに合わせる）
        {
            component: sliderComponent,
            properties: {
                target: contrastTargetName,
                value: LT.Utilities.PSC_Contrast,
                text: qsTr("PSC_Contrast"),
                source: "qrc:/images/ps_contrast.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: highLightTargetName,
                value: LT.Utilities.PSC_HighLight,
                text: qsTr("PSC_HighLight"),
                source: "qrc:/images/highlight.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: shadowTargetName,
                value: LT.Utilities.PSC_Shadow,
                text: qsTr("PSC_Shadow"),
                source: "qrc:/images/shadow.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: saturationTargetName,
                value: LT.Utilities.PSC_Saturation,
                text: qsTr("PSC_Saturation"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: colorToneTargetName,
                value: LT.Utilities.PSC_ColorTone,
                text: qsTr("PSC_ColorTone"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: chrPhaseTargetName,
                value: LT.Utilities.PSC_ChromaPhase,
                text: qsTr("PSC_ChromaPhase"),
                source: "qrc:/images/ps_saturation2.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: filterTargetName,
                value: LT.Utilities.PSC_Filter,
                text: qsTr("PSC_Filter"),
                source: "qrc:/images/ps_filter.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: grainTargetName,
                value: LT.Utilities.PSC_Grain,
                text: qsTr("PSC_Grain"),
                source: "qrc:/images/ps_granular.svg"
            }
        },
        //20秋FwUp
        {
            component: popupBtnComponent,
            properties: {
                target: colorNoiseTargetName,
                value: LT.Utilities.PSC_ColorNoise,
                text: qsTr("PSC_Grain_Color"),
                source: "qrc:/images/ps_granular_color.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: sharpnessTargetName,
                value: LT.Utilities.PSC_Sharpness,
                text: qsTr("PSC_Sharpness"),
                source: "qrc:/images/ps_sharpness.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: noiseRedTargetName,
                value: LT.Utilities.PSC_NR,
                text: qsTr("PSC_NoiseReduct"),
                source: "qrc:/images/ps_noisereduction.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: kneeModeTargetName,
                value: LT.Utilities.PSC_KneeMode,
                text: qsTr("PSC_KneeMode"),
                source: "qrc:/images/ps_knee.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: isoTargetName,
                value: LT.Utilities.PSC_ISO,
                text: qsTr("PSC_ISO"),
                source: "qrc:/images/iso.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: wbTargetName,
                value: LT.Utilities.PSC_WB,
                text: qsTr("PSC_WB"),
                source: "qrc:/images/wb.svg"
            }
        },
        // MC5229
        {
            component: popupBtnComponent,
            properties: {
                target: gainTargetName,
                value: LT.Utilities.PSC_Gain,
                text: qsTr("PSC_GainSetting"),
                source: "qrc:/images/gain.svg"
            }
        },
    ]

    /*!
        photoStyle1 を選択する LTMainPhotoStylePopup に表示するコンポーネントの組です
    */
    readonly property var psPhotoStyle1: [
        // '20秋FwUp（Gシリーズ → Sシリーズに合わせる）
        {
            component: popupBtnComponent,
            properties: {
                target: basePhotoStyleTargetName,
                value: LT.Utilities.PSC_BasePhotoStyle,
                text: qsTr("PSC_BasePhotoStyle"),
                source: "qrc:/images/button_placeholder.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: contrastTargetName,
                value: LT.Utilities.PSC_Contrast,
                text: qsTr("PSC_Contrast"),
                source: "qrc:/images/ps_contrast.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: highLightTargetName,
                value: LT.Utilities.PSC_HighLight,
                text: qsTr("PSC_HighLight"),
                source: "qrc:/images/highlight.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: shadowTargetName,
                value: LT.Utilities.PSC_Shadow,
                text: qsTr("PSC_Shadow"),
                source: "qrc:/images/shadow.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: saturationTargetName,
                value: LT.Utilities.PSC_Saturation,
                text: qsTr("PSC_Saturation"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: colorToneTargetName,
                value: LT.Utilities.PSC_ColorTone,
                text: qsTr("PSC_ColorTone"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: chrPhaseTargetName,
                value: LT.Utilities.PSC_ChromaPhase,
                text: qsTr("PSC_ChromaPhase"),
                source: "qrc:/images/ps_saturation2.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: filterTargetName,
                value: LT.Utilities.PSC_Filter,
                text: qsTr("PSC_Filter"),
                source: "qrc:/images/ps_filter.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: grainTargetName,
                value: LT.Utilities.PSC_Grain,
                text: qsTr("PSC_Grain"),
                source: "qrc:/images/ps_granular.svg"
            }
        },
        //20秋FwUp
        {
            component: popupBtnComponent,
            properties: {
                target: colorNoiseTargetName,
                value: LT.Utilities.PSC_ColorNoise,
                text: qsTr("PSC_Grain_Color"),
                source: "qrc:/images/ps_granular_color.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: sharpnessTargetName,
                value: LT.Utilities.PSC_Sharpness,
                text: qsTr("PSC_Sharpness"),
                source: "qrc:/images/ps_sharpness.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: noiseRedTargetName,
                value: LT.Utilities.PSC_NR,
                text: qsTr("PSC_NoiseReduct"),
                source: "qrc:/images/ps_noisereduction.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: kneeModeTargetName,
                value: LT.Utilities.PSC_KneeMode,
                text: qsTr("PSC_KneeMode"),
                source: "qrc:/images/ps_knee.svg"
            }
        },
        // 2020/08/25 Panasonic Kashihara Dual Native ISO > ISO > WB
        // IVC >> Ver.1.7 >> start >> No.2
        {
            component: popupBtnComponent,
            properties: {
                target: dualISOTargetName,
                value: LT.Utilities.PSC_DualISO,
                text: qsTr("PSC_DualISO"),
                source: "qrc:/images/ps_dual.svg"
            }
        },
        // IVC << Ver.1.7 << end << No.2
        {
            component: popupBtnComponent,
            properties: {
                target: isoTargetName,
                value: LT.Utilities.PSC_ISO,
                text: qsTr("PSC_ISO"),
                source: "qrc:/images/iso.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: wbTargetName,
                value: LT.Utilities.PSC_WB,
                text: qsTr("PSC_WB"),
                source: "qrc:/images/wb.svg"
            }
        },
        // MC5229
        {
            component: popupBtnComponent,
            properties: {
                target: gainTargetName,
                value: LT.Utilities.PSC_Gain,
                text: qsTr("PSC_GainSetting"),
                source: "qrc:/images/gain.svg"
            }
        },
        // MC8259 tsutsumi start
        {
            component: popupBtnComponent,
            properties: {
                target: lutTargetName,
                value: LT.Utilities.PSC_LUT,
                text: qsTr("PSC_LUT"),
                source: "qrc:/images/ps_lut.svg"
            }
        },
        {
            component: sliderComponentPositive,
            properties: {
                target: densityTargetName,
                value: LT.Utilities.PSC_Density,
                text: qsTr("PSC_Density"),
                source: "qrc:/images/ps_lut_concentration.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: lut2TargetName,
                value: LT.Utilities.PSC_LUT2,
                text: qsTr("PSC_LUT2"),
                source: "qrc:/images/ps_lut2.svg"
            }
        },
        {
            component: sliderComponentPositive,
            properties: {
                target: density2TargetName,
                value: LT.Utilities.PSC_Density2,
                text: qsTr("PSC_Density2"),
                source: "qrc:/images/ps_lut2_concentration.svg"
            }
        },
        // MC8259 tsutsumi end
    ]

    /*!
        photoStyle2 を選択する LTMainPhotoStylePopup に表示するコンポーネントの組です
    */
    readonly property var psPhotoStyle2: [
        // '20秋FwUp（Gシリーズ → Sシリーズに合わせる）
        {
            component: popupBtnComponent,
            properties: {
                target: basePhotoStyleTargetName,
                // ivc >> start >> USBTHRV140-50
                value: LT.Utilities.PSC_BasePhotoStyle,
                text: qsTr("PSC_BasePhotoStyle"),
                // ivc << end << USBTHRV140-50
                source: "qrc:/images/button_placeholder.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: contrastTargetName,
                value: LT.Utilities.PSC_Contrast,
                text: qsTr("PSC_Contrast"),
                source: "qrc:/images/ps_contrast.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: highLightTargetName,
                value: LT.Utilities.PSC_HighLight,
                text: qsTr("PSC_HighLight"),
                source: "qrc:/images/highlight.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: shadowTargetName,
                value: LT.Utilities.PSC_Shadow,
                text: qsTr("PSC_Shadow"),
                source: "qrc:/images/shadow.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: saturationTargetName,
                value: LT.Utilities.PSC_Saturation,
                text: qsTr("PSC_Saturation"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: colorToneTargetName,
                value: LT.Utilities.PSC_ColorTone,
                text: qsTr("PSC_ColorTone"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: chrPhaseTargetName,
                value: LT.Utilities.PSC_ChromaPhase,
                text: qsTr("PSC_ChromaPhase"),
                source: "qrc:/images/ps_saturation2.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: filterTargetName,
                value: LT.Utilities.PSC_Filter,
                text: qsTr("PSC_Filter"),
                source: "qrc:/images/ps_filter.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: grainTargetName,
                value: LT.Utilities.PSC_Grain,
                text: qsTr("PSC_Grain"),
                source: "qrc:/images/ps_granular.svg"
            }
        },
        //20秋FwUp
        {
            component: popupBtnComponent,
            properties: {
                target: colorNoiseTargetName,
                value: LT.Utilities.PSC_ColorNoise,
                text: qsTr("PSC_Grain_Color"),
                source: "qrc:/images/ps_granular_color.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: sharpnessTargetName,
                value: LT.Utilities.PSC_Sharpness,
                text: qsTr("PSC_Sharpness"),
                source: "qrc:/images/ps_sharpness.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: noiseRedTargetName,
                value: LT.Utilities.PSC_NR,
                text: qsTr("PSC_NoiseReduct"),
                source: "qrc:/images/ps_noisereduction.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: kneeModeTargetName,
                value: LT.Utilities.PSC_KneeMode,
                text: qsTr("PSC_KneeMode"),
                source: "qrc:/images/ps_knee.svg"
            }
        },
        // 2020/08/25 Panasonic Kashihara Dual Native ISO > ISO > WB
        // IVC >> Ver.1.7 >> start >> No.2
        {
            component: popupBtnComponent,
            properties: {
                target: dualISOTargetName,
                value: LT.Utilities.PSC_DualISO,
                text: qsTr("PSC_DualISO"),
                source: "qrc:/images/ps_dual.svg"
            }
        },
        // IVC << Ver.1.7 << end << No.2
        {
            component: popupBtnComponent,
            properties: {
                target: isoTargetName,
                value: LT.Utilities.PSC_ISO,
                text: qsTr("PSC_ISO"),
                source: "qrc:/images/iso.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: wbTargetName,
                value: LT.Utilities.PSC_WB,
                text: qsTr("PSC_WB"),
                source: "qrc:/images/wb.svg"
            }
        },
        // MC5229
        {
            component: popupBtnComponent,
            properties: {
                target: gainTargetName,
                value: LT.Utilities.PSC_Gain,
                text: qsTr("PSC_GainSetting"),
                source: "qrc:/images/gain.svg"
            }
        },
        // MC8259 tsutsumi start
        {
            component: popupBtnComponent,
            properties: {
                target: lutTargetName,
                value: LT.Utilities.PSC_LUT,
                text: qsTr("PSC_LUT"),
                source: "qrc:/images/ps_lut.svg"
            }
        },
        {
            component: sliderComponentPositive,
            properties: {
                target: densityTargetName,
                value: LT.Utilities.PSC_Density,
                text: qsTr("PSC_Density"),
                source: "qrc:/images/ps_lut_concentration.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: lut2TargetName,
                value: LT.Utilities.PSC_LUT2,
                text: qsTr("PSC_LUT2"),
                source: "qrc:/images/ps_lut2.svg"
            }
        },
        {
            component: sliderComponentPositive,
            properties: {
                target: density2TargetName,
                value: LT.Utilities.PSC_Density2,
                text: qsTr("PSC_Density2"),
                source: "qrc:/images/ps_lut2_concentration.svg"
            }
        },
        // MC8259 tsutsumi end
    ]

    /*!
        photoStyle3 を選択する LTMainPhotoStylePopup に表示するコンポーネントの組です
    */
    readonly property var psPhotoStyle3: [
        // '20秋FwUp（Gシリーズ → Sシリーズに合わせる）
        {
            component: popupBtnComponent,
            properties: {
                target: basePhotoStyleTargetName,
                // ivc >> start >> USBTHRV140-50
                value: LT.Utilities.PSC_BasePhotoStyle,
                text: qsTr("PSC_BasePhotoStyle"),
                // ivc << end << USBTHRV140-50
                source: "qrc:/images/button_placeholder.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: contrastTargetName,
                value: LT.Utilities.PSC_Contrast,
                text: qsTr("PSC_Contrast"),
                source: "qrc:/images/ps_contrast.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: highLightTargetName,
                value: LT.Utilities.PSC_HighLight,
                text: qsTr("PSC_HighLight"),
                source: "qrc:/images/highlight.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: shadowTargetName,
                value: LT.Utilities.PSC_Shadow,
                text: qsTr("PSC_Shadow"),
                source: "qrc:/images/shadow.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: saturationTargetName,
                value: LT.Utilities.PSC_Saturation,
                text: qsTr("PSC_Saturation"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: colorToneTargetName,
                value: LT.Utilities.PSC_ColorTone,
                text: qsTr("PSC_ColorTone"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: chrPhaseTargetName,
                value: LT.Utilities.PSC_ChromaPhase,
                text: qsTr("PSC_ChromaPhase"),
                source: "qrc:/images/ps_saturation2.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: filterTargetName,
                value: LT.Utilities.PSC_Filter,
                text: qsTr("PSC_Filter"),
                source: "qrc:/images/ps_filter.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: grainTargetName,
                value: LT.Utilities.PSC_Grain,
                text: qsTr("PSC_Grain"),
                source: "qrc:/images/ps_granular.svg"
            }
        },
        //20秋FwUp
        {
            component: popupBtnComponent,
            properties: {
                target: colorNoiseTargetName,
                value: LT.Utilities.PSC_ColorNoise,
                text: qsTr("PSC_Grain_Color"),
                source: "qrc:/images/ps_granular_color.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: sharpnessTargetName,
                value: LT.Utilities.PSC_Sharpness,
                text: qsTr("PSC_Sharpness"),
                source: "qrc:/images/ps_sharpness.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: noiseRedTargetName,
                value: LT.Utilities.PSC_NR,
                text: qsTr("PSC_NoiseReduct"),
                source: "qrc:/images/ps_noisereduction.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: kneeModeTargetName,
                value: LT.Utilities.PSC_KneeMode,
                text: qsTr("PSC_KneeMode"),
                source: "qrc:/images/ps_knee.svg"
            }
        },
        // 2020/08/25 Panasonic Kashihara Dual Native ISO > ISO > WB
        // IVC >> Ver.1.7 >> start >> No.2
        {
            component: popupBtnComponent,
            properties: {
                target: dualISOTargetName,
                value: LT.Utilities.PSC_DualISO,
                text: qsTr("PSC_DualISO"),
                source: "qrc:/images/ps_dual.svg"
            }
        },
        // IVC << Ver.1.7 << end << No.2
        {
            component: popupBtnComponent,
            properties: {
                target: isoTargetName,
                value: LT.Utilities.PSC_ISO,
                text: qsTr("PSC_ISO"),
                source: "qrc:/images/iso.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: wbTargetName,
                value: LT.Utilities.PSC_WB,
                text: qsTr("PSC_WB"),
                source: "qrc:/images/wb.svg"
            }
        },
        // MC5229
        {
            component: popupBtnComponent,
            properties: {
                target: gainTargetName,
                value: LT.Utilities.PSC_Gain,
                text: qsTr("PSC_GainSetting"),
                source: "qrc:/images/gain.svg"
            }
        },
        // MC8259 tsutsumi start
        {
            component: popupBtnComponent,
            properties: {
                target: lutTargetName,
                value: LT.Utilities.PSC_LUT,
                text: qsTr("PSC_LUT"),
                source: "qrc:/images/ps_lut.svg"
            }
        },
        {
            component: sliderComponentPositive,
            properties: {
                target: densityTargetName,
                value: LT.Utilities.PSC_Density,
                text: qsTr("PSC_Density"),
                source: "qrc:/images/ps_lut_concentration.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: lut2TargetName,
                value: LT.Utilities.PSC_LUT2,
                text: qsTr("PSC_LUT2"),
                source: "qrc:/images/ps_lut2.svg"
            }
        },
        {
            component: sliderComponentPositive,
            properties: {
                target: density2TargetName,
                value: LT.Utilities.PSC_Density2,
                text: qsTr("PSC_Density2"),
                source: "qrc:/images/ps_lut2_concentration.svg"
            }
        },
        // MC8259 tsutsumi end
    ]

    /*!
        photoStyle4 を選択する LTMainPhotoStylePopup に表示するコンポーネントの組です
    */
    readonly property var psPhotoStyle4: [
        // '20秋FwUp（Gシリーズ → Sシリーズに合わせる）
        {
            component: popupBtnComponent,
            properties: {
                target: basePhotoStyleTargetName,
                value: LT.Utilities.PSC_BasePhotoStyle,
                text: qsTr("PSC_BasePhotoStyle"),
                source: "qrc:/images/button_placeholder.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: contrastTargetName,
                value: LT.Utilities.PSC_Contrast,
                text: qsTr("PSC_Contrast"),
                source: "qrc:/images/ps_contrast.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: highLightTargetName,
                value: LT.Utilities.PSC_HighLight,
                text: qsTr("PSC_HighLight"),
                source: "qrc:/images/highlight.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: shadowTargetName,
                value: LT.Utilities.PSC_Shadow,
                text: qsTr("PSC_Shadow"),
                source: "qrc:/images/shadow.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: saturationTargetName,
                value: LT.Utilities.PSC_Saturation,
                text: qsTr("PSC_Saturation"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: colorToneTargetName,
                value: LT.Utilities.PSC_ColorTone,
                text: qsTr("PSC_ColorTone"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: chrPhaseTargetName,
                value: LT.Utilities.PSC_ChromaPhase,
                text: qsTr("PSC_ChromaPhase"),
                source: "qrc:/images/ps_saturation2.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: filterTargetName,
                value: LT.Utilities.PSC_Filter,
                text: qsTr("PSC_Filter"),
                source: "qrc:/images/ps_filter.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: grainTargetName,
                value: LT.Utilities.PSC_Grain,
                text: qsTr("PSC_Grain"),
                source: "qrc:/images/ps_granular.svg"
            }
        },
        //20秋FwUp
        {
            component: popupBtnComponent,
            properties: {
                target: colorNoiseTargetName,
                value: LT.Utilities.PSC_ColorNoise,
                text: qsTr("PSC_Grain_Color"),
                source: "qrc:/images/ps_granular_color.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: sharpnessTargetName,
                value: LT.Utilities.PSC_Sharpness,
                text: qsTr("PSC_Sharpness"),
                source: "qrc:/images/ps_sharpness.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: noiseRedTargetName,
                value: LT.Utilities.PSC_NR,
                text: qsTr("PSC_NoiseReduct"),
                source: "qrc:/images/ps_noisereduction.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: kneeModeTargetName,
                value: LT.Utilities.PSC_KneeMode,
                text: qsTr("PSC_KneeMode"),
                source: "qrc:/images/ps_knee.svg"
            }
        },
        // 2020/08/25 Panasonic Kashihara Dual Native ISO > ISO > WB
        // IVC >> Ver.1.7 >> start >> No.2
        {
            component: popupBtnComponent,
            properties: {
                target: dualISOTargetName,
                value: LT.Utilities.PSC_DualISO,
                text: qsTr("PSC_DualISO"),
                source: "qrc:/images/ps_dual.svg"
            }
        },
        // IVC << Ver.1.7 << end << No.2
        {
            component: popupBtnComponent,
            properties: {
                target: isoTargetName,
                value: LT.Utilities.PSC_ISO,
                text: qsTr("PSC_ISO"),
                source: "qrc:/images/iso.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: wbTargetName,
                value: LT.Utilities.PSC_WB,
                text: qsTr("PSC_WB"),
                source: "qrc:/images/wb.svg"
            }
        },
        // MC5229
        {
            component: popupBtnComponent,
            properties: {
                target: gainTargetName,
                value: LT.Utilities.PSC_Gain,
                text: qsTr("PSC_GainSetting"),
                source: "qrc:/images/gain.svg"
            }
        },
        // MC8259 tsutsumi start
        {
            component: popupBtnComponent,
            properties: {
                target: lutTargetName,
                value: LT.Utilities.PSC_LUT,
                text: qsTr("PSC_LUT"),
                source: "qrc:/images/ps_lut.svg"
            }
        },
        {
            component: sliderComponentPositive,
            properties: {
                target: densityTargetName,
                value: LT.Utilities.PSC_Density,
                text: qsTr("PSC_Density"),
                source: "qrc:/images/ps_lut_concentration.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: lut2TargetName,
                value: LT.Utilities.PSC_LUT2,
                text: qsTr("PSC_LUT2"),
                source: "qrc:/images/ps_lut2.svg"
            }
        },
        {
            component: sliderComponentPositive,
            properties: {
                target: density2TargetName,
                value: LT.Utilities.PSC_Density2,
                text: qsTr("PSC_Density2"),
                source: "qrc:/images/ps_lut2_concentration.svg"
            }
        },
        // MC8259 tsutsumi end
    ]

    /*!
        photoStyle5 を選択する LTMainPhotoStylePopup に表示するコンポーネントの組です
    */
    readonly property var psPhotoStyle5: [
        // '20秋FwUp（Gシリーズ → Sシリーズに合わせる）
        {
            component: popupBtnComponent,
            properties: {
                target: basePhotoStyleTargetName,
                value: LT.Utilities.PSC_BasePhotoStyle,
                text: qsTr("PSC_BasePhotoStyle"),
                source: "qrc:/images/button_placeholder.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: contrastTargetName,
                value: LT.Utilities.PSC_Contrast,
                text: qsTr("PSC_Contrast"),
                source: "qrc:/images/ps_contrast.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: highLightTargetName,
                value: LT.Utilities.PSC_HighLight,
                text: qsTr("PSC_HighLight"),
                source: "qrc:/images/highlight.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: shadowTargetName,
                value: LT.Utilities.PSC_Shadow,
                text: qsTr("PSC_Shadow"),
                source: "qrc:/images/shadow.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: saturationTargetName,
                value: LT.Utilities.PSC_Saturation,
                text: qsTr("PSC_Saturation"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: colorToneTargetName,
                value: LT.Utilities.PSC_ColorTone,
                text: qsTr("PSC_ColorTone"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: chrPhaseTargetName,
                value: LT.Utilities.PSC_ChromaPhase,
                text: qsTr("PSC_ChromaPhase"),
                source: "qrc:/images/ps_saturation2.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: filterTargetName,
                value: LT.Utilities.PSC_Filter,
                text: qsTr("PSC_Filter"),
                source: "qrc:/images/ps_filter.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: grainTargetName,
                value: LT.Utilities.PSC_Grain,
                text: qsTr("PSC_Grain"),
                source: "qrc:/images/ps_granular.svg"
            }
        },
        //20秋FwUp
        {
            component: popupBtnComponent,
            properties: {
                target: colorNoiseTargetName,
                value: LT.Utilities.PSC_ColorNoise,
                text: qsTr("PSC_Grain_Color"),
                source: "qrc:/images/ps_granular_color.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: sharpnessTargetName,
                value: LT.Utilities.PSC_Sharpness,
                text: qsTr("PSC_Sharpness"),
                source: "qrc:/images/ps_sharpness.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: noiseRedTargetName,
                value: LT.Utilities.PSC_NR,
                text: qsTr("PSC_NoiseReduct"),
                source: "qrc:/images/ps_noisereduction.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: kneeModeTargetName,
                value: LT.Utilities.PSC_KneeMode,
                text: qsTr("PSC_KneeMode"),
                source: "qrc:/images/ps_knee.svg"
            }
        },
        // 2020/08/25 Panasonic Kashihara Dual Native ISO > ISO > WB
        // IVC >> Ver.1.7 >> start >> No.2
        {
            component: popupBtnComponent,
            properties: {
                target: dualISOTargetName,
                value: LT.Utilities.PSC_DualISO,
                text: qsTr("PSC_DualISO"),
                source: "qrc:/images/ps_dual.svg"
            }
        },
        // IVC << Ver.1.7 << end << No.2
        {
            component: popupBtnComponent,
            properties: {
                target: isoTargetName,
                value: LT.Utilities.PSC_ISO,
                text: qsTr("PSC_ISO"),
                source: "qrc:/images/iso.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: wbTargetName,
                value: LT.Utilities.PSC_WB,
                text: qsTr("PSC_WB"),
                source: "qrc:/images/wb.svg"
            }
        },
        // MC5229
        {
            component: popupBtnComponent,
            properties: {
                target: gainTargetName,
                value: LT.Utilities.PSC_Gain,
                text: qsTr("PSC_GainSetting"),
                source: "qrc:/images/gain.svg"
            }
        },
        // MC8259 tsutsumi start
        {
            component: popupBtnComponent,
            properties: {
                target: lutTargetName,
                value: LT.Utilities.PSC_LUT,
                text: qsTr("PSC_LUT"),
                source: "qrc:/images/ps_lut.svg"
            }
        },
        {
            component: sliderComponentPositive,
            properties: {
                target: densityTargetName,
                value: LT.Utilities.PSC_Density,
                text: qsTr("PSC_Density"),
                source: "qrc:/images/ps_lut_concentration.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: lut2TargetName,
                value: LT.Utilities.PSC_LUT2,
                text: qsTr("PSC_LUT2"),
                source: "qrc:/images/ps_lut2.svg"
            }
        },
        {
            component: sliderComponentPositive,
            properties: {
                target: density2TargetName,
                value: LT.Utilities.PSC_Density2,
                text: qsTr("PSC_Density2"),
                source: "qrc:/images/ps_lut2_concentration.svg"
            }
        },
        // MC8259 tsutsumi end
    ]

    /*!
        photoStyle6 を選択する LTMainPhotoStylePopup に表示するコンポーネントの組です
    */
    readonly property var psPhotoStyle6: [
        // '20秋FwUp（Gシリーズ → Sシリーズに合わせる）
        {
            component: popupBtnComponent,
            properties: {
                target: basePhotoStyleTargetName,
                value: LT.Utilities.PSC_BasePhotoStyle,
                text: qsTr("PSC_BasePhotoStyle"),
                source: "qrc:/images/button_placeholder.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: contrastTargetName,
                value: LT.Utilities.PSC_Contrast,
                text: qsTr("PSC_Contrast"),
                source: "qrc:/images/ps_contrast.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: highLightTargetName,
                value: LT.Utilities.PSC_HighLight,
                text: qsTr("PSC_HighLight"),
                source: "qrc:/images/highlight.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: shadowTargetName,
                value: LT.Utilities.PSC_Shadow,
                text: qsTr("PSC_Shadow"),
                source: "qrc:/images/shadow.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: saturationTargetName,
                value: LT.Utilities.PSC_Saturation,
                text: qsTr("PSC_Saturation"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: colorToneTargetName,
                value: LT.Utilities.PSC_ColorTone,
                text: qsTr("PSC_ColorTone"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: chrPhaseTargetName,
                value: LT.Utilities.PSC_ChromaPhase,
                text: qsTr("PSC_ChromaPhase"),
                source: "qrc:/images/ps_saturation2.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: filterTargetName,
                value: LT.Utilities.PSC_Filter,
                text: qsTr("PSC_Filter"),
                source: "qrc:/images/ps_filter.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: grainTargetName,
                value: LT.Utilities.PSC_Grain,
                text: qsTr("PSC_Grain"),
                source: "qrc:/images/ps_granular.svg"
            }
        },
        //20秋FwUp
        {
            component: popupBtnComponent,
            properties: {
                target: colorNoiseTargetName,
                value: LT.Utilities.PSC_ColorNoise,
                text: qsTr("PSC_Grain_Color"),
                source: "qrc:/images/ps_granular_color.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: sharpnessTargetName,
                value: LT.Utilities.PSC_Sharpness,
                text: qsTr("PSC_Sharpness"),
                source: "qrc:/images/ps_sharpness.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: noiseRedTargetName,
                value: LT.Utilities.PSC_NR,
                text: qsTr("PSC_NoiseReduct"),
                source: "qrc:/images/ps_noisereduction.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: kneeModeTargetName,
                value: LT.Utilities.PSC_KneeMode,
                text: qsTr("PSC_KneeMode"),
                source: "qrc:/images/ps_knee.svg"
            }
        },
        // 2020/08/25 Panasonic Kashihara Dual Native ISO > ISO > WB
        // IVC >> Ver.1.7 >> start >> No.2
        {
            component: popupBtnComponent,
            properties: {
                target: dualISOTargetName,
                value: LT.Utilities.PSC_DualISO,
                text: qsTr("PSC_DualISO"),
                source: "qrc:/images/ps_dual.svg"
            }
        },
        // IVC << Ver.1.7 << end << No.2
        {
            component: popupBtnComponent,
            properties: {
                target: isoTargetName,
                value: LT.Utilities.PSC_ISO,
                text: qsTr("PSC_ISO"),
                source: "qrc:/images/iso.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: wbTargetName,
                value: LT.Utilities.PSC_WB,
                text: qsTr("PSC_WB"),
                source: "qrc:/images/wb.svg"
            }
        },
        // MC5229
        {
            component: popupBtnComponent,
            properties: {
                target: gainTargetName,
                value: LT.Utilities.PSC_Gain,
                text: qsTr("PSC_GainSetting"),
                source: "qrc:/images/gain.svg"
            }
        },
        // MC8259 tsutsumi start
        {
            component: popupBtnComponent,
            properties: {
                target: lutTargetName,
                value: LT.Utilities.PSC_LUT,
                text: qsTr("PSC_LUT"),
                source: "qrc:/images/ps_lut.svg"
            }
        },
        {
            component: sliderComponentPositive,
            properties: {
                target: densityTargetName,
                value: LT.Utilities.PSC_Density,
                text: qsTr("PSC_Density"),
                source: "qrc:/images/ps_lut_concentration.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: lut2TargetName,
                value: LT.Utilities.PSC_LUT2,
                text: qsTr("PSC_LUT2"),
                source: "qrc:/images/ps_lut2.svg"
            }
        },
        {
            component: sliderComponentPositive,
            properties: {
                target: density2TargetName,
                value: LT.Utilities.PSC_Density2,
                text: qsTr("PSC_Density2"),
                source: "qrc:/images/ps_lut2_concentration.svg"
            }
        },
        // MC8259 tsutsumi end
    ]

    /*!
        photoStyle7 を選択する LTMainPhotoStylePopup に表示するコンポーネントの組です
    */
    readonly property var psPhotoStyle7: [
        // '20秋FwUp（Gシリーズ → Sシリーズに合わせる）
        {
            component: popupBtnComponent,
            properties: {
                target: basePhotoStyleTargetName,
                value: LT.Utilities.PSC_BasePhotoStyle,
                text: qsTr("PSC_BasePhotoStyle"),
                source: "qrc:/images/button_placeholder.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: contrastTargetName,
                value: LT.Utilities.PSC_Contrast,
                text: qsTr("PSC_Contrast"),
                source: "qrc:/images/ps_contrast.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: highLightTargetName,
                value: LT.Utilities.PSC_HighLight,
                text: qsTr("PSC_HighLight"),
                source: "qrc:/images/highlight.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: shadowTargetName,
                value: LT.Utilities.PSC_Shadow,
                text: qsTr("PSC_Shadow"),
                source: "qrc:/images/shadow.svg"
            }
        },
       {
            component: sliderComponent,
            properties: {
                target: saturationTargetName,
                value: LT.Utilities.PSC_Saturation,
                text: qsTr("PSC_Saturation"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: colorToneTargetName,
                value: LT.Utilities.PSC_ColorTone,
                text: qsTr("PSC_ColorTone"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: chrPhaseTargetName,
                value: LT.Utilities.PSC_ChromaPhase,
                text: qsTr("PSC_ChromaPhase"),
                source: "qrc:/images/ps_saturation2.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: filterTargetName,
                value: LT.Utilities.PSC_Filter,
                text: qsTr("PSC_Filter"),
                source: "qrc:/images/ps_filter.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: grainTargetName,
                value: LT.Utilities.PSC_Grain,
                text: qsTr("PSC_Grain"),
                source: "qrc:/images/ps_granular.svg"
            }
        },
        //20秋FwUp
        {
            component: popupBtnComponent,
            properties: {
                target: colorNoiseTargetName,
                value: LT.Utilities.PSC_ColorNoise,
                text: qsTr("PSC_Grain_Color"),
                source: "qrc:/images/ps_granular_color.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: sharpnessTargetName,
                value: LT.Utilities.PSC_Sharpness,
                text: qsTr("PSC_Sharpness"),
                source: "qrc:/images/ps_sharpness.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: noiseRedTargetName,
                value: LT.Utilities.PSC_NR,
                text: qsTr("PSC_NoiseReduct"),
                source: "qrc:/images/ps_noisereduction.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: kneeModeTargetName,
                value: LT.Utilities.PSC_KneeMode,
                text: qsTr("PSC_KneeMode"),
                source: "qrc:/images/ps_knee.svg"
            }
        },
        // 2020/08/25 Panasonic Kashihara Dual Native ISO > ISO > WB
        // IVC >> Ver.1.7 >> start >> No.2
        {
            component: popupBtnComponent,
            properties: {
                target: dualISOTargetName,
                value: LT.Utilities.PSC_DualISO,
                text: qsTr("PSC_DualISO"),
                source: "qrc:/images/ps_dual.svg"
            }
        },
        // IVC << Ver.1.7 << end << No.2
        {
            component: popupBtnComponent,
            properties: {
                target: isoTargetName,
                value: LT.Utilities.PSC_ISO,
                text: qsTr("PSC_ISO"),
                source: "qrc:/images/iso.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: wbTargetName,
                value: LT.Utilities.PSC_WB,
                text: qsTr("PSC_WB"),
                source: "qrc:/images/wb.svg"
            }
        },
        // MC5229
        {
            component: popupBtnComponent,
            properties: {
                target: gainTargetName,
                value: LT.Utilities.PSC_Gain,
                text: qsTr("PSC_GainSetting"),
                source: "qrc:/images/gain.svg"
            }
        },
        // MC8259 tsutsumi start
        {
            component: popupBtnComponent,
            properties: {
                target: lutTargetName,
                value: LT.Utilities.PSC_LUT,
                text: qsTr("PSC_LUT"),
                source: "qrc:/images/ps_lut.svg"
            }
        },
        {
            component: sliderComponentPositive,
            properties: {
                target: densityTargetName,
                value: LT.Utilities.PSC_Density,
                text: qsTr("PSC_Density"),
                source: "qrc:/images/ps_lut_concentration.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: lut2TargetName,
                value: LT.Utilities.PSC_LUT2,
                text: qsTr("PSC_LUT2"),
                source: "qrc:/images/ps_lut2.svg"
            }
        },
        {
            component: sliderComponentPositive,
            properties: {
                target: density2TargetName,
                value: LT.Utilities.PSC_Density2,
                text: qsTr("PSC_Density2"),
                source: "qrc:/images/ps_lut2_concentration.svg"
            }
        },
        // MC8259 tsutsumi end
    ]

    /*!
        photoStyle8 を選択する LTMainPhotoStylePopup に表示するコンポーネントの組です
    */
    readonly property var psPhotoStyle8: [
        // '20秋FwUp（Gシリーズ → Sシリーズに合わせる）
        {
            component: popupBtnComponent,
            properties: {
                target: basePhotoStyleTargetName,
                value: LT.Utilities.PSC_BasePhotoStyle,
                text: qsTr("PSC_BasePhotoStyle"),
                source: "qrc:/images/button_placeholder.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: contrastTargetName,
                value: LT.Utilities.PSC_Contrast,
                text: qsTr("PSC_Contrast"),
                source: "qrc:/images/ps_contrast.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: highLightTargetName,
                value: LT.Utilities.PSC_HighLight,
                text: qsTr("PSC_HighLight"),
                source: "qrc:/images/highlight.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: shadowTargetName,
                value: LT.Utilities.PSC_Shadow,
                text: qsTr("PSC_Shadow"),
                source: "qrc:/images/shadow.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: saturationTargetName,
                value: LT.Utilities.PSC_Saturation,
                text: qsTr("PSC_Saturation"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: colorToneTargetName,
                value: LT.Utilities.PSC_ColorTone,
                text: qsTr("PSC_ColorTone"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: chrPhaseTargetName,
                value: LT.Utilities.PSC_ChromaPhase,
                text: qsTr("PSC_ChromaPhase"),
                source: "qrc:/images/ps_saturation2.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: filterTargetName,
                value: LT.Utilities.PSC_Filter,
                text: qsTr("PSC_Filter"),
                source: "qrc:/images/ps_filter.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: grainTargetName,
                value: LT.Utilities.PSC_Grain,
                text: qsTr("PSC_Grain"),
                source: "qrc:/images/ps_granular.svg"
            }
        },
        //20秋FwUp
        {
            component: popupBtnComponent,
            properties: {
                target: colorNoiseTargetName,
                value: LT.Utilities.PSC_ColorNoise,
                text: qsTr("PSC_Grain_Color"),
                source: "qrc:/images/ps_granular_color.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: sharpnessTargetName,
                value: LT.Utilities.PSC_Sharpness,
                text: qsTr("PSC_Sharpness"),
                source: "qrc:/images/ps_sharpness.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: noiseRedTargetName,
                value: LT.Utilities.PSC_NR,
                text: qsTr("PSC_NoiseReduct"),
                source: "qrc:/images/ps_noisereduction.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: kneeModeTargetName,
                value: LT.Utilities.PSC_KneeMode,
                text: qsTr("PSC_KneeMode"),
                source: "qrc:/images/ps_knee.svg"
            }
        },
        // 2020/08/25 Panasonic Kashihara Dual Native ISO > ISO > WB
        // IVC >> Ver.1.7 >> start >> No.2
        {
            component: popupBtnComponent,
            properties: {
                target: dualISOTargetName,
                value: LT.Utilities.PSC_DualISO,
                text: qsTr("PSC_DualISO"),
                source: "qrc:/images/ps_dual.svg"
            }
        },
        // IVC << Ver.1.7 << end << No.2
        {
            component: popupBtnComponent,
            properties: {
                target: isoTargetName,
                value: LT.Utilities.PSC_ISO,
                text: qsTr("PSC_ISO"),
                source: "qrc:/images/iso.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: wbTargetName,
                value: LT.Utilities.PSC_WB,
                text: qsTr("PSC_WB"),
                source: "qrc:/images/wb.svg"
            }
        },
        // MC5229
        {
            component: popupBtnComponent,
            properties: {
                target: gainTargetName,
                value: LT.Utilities.PSC_Gain,
                text: qsTr("PSC_GainSetting"),
                source: "qrc:/images/gain.svg"
            }
        },
        // MC8259 tsutsumi start
        {
            component: popupBtnComponent,
            properties: {
                target: lutTargetName,
                value: LT.Utilities.PSC_LUT,
                text: qsTr("PSC_LUT"),
                source: "qrc:/images/ps_lut.svg"
            }
        },
        {
            component: sliderComponentPositive,
            properties: {
                target: densityTargetName,
                value: LT.Utilities.PSC_Density,
                text: qsTr("PSC_Density"),
                source: "qrc:/images/ps_lut_concentration.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: lut2TargetName,
                value: LT.Utilities.PSC_LUT2,
                text: qsTr("PSC_LUT2"),
                source: "qrc:/images/ps_lut2.svg"
            }
        },
        {
            component: sliderComponentPositive,
            properties: {
                target: density2TargetName,
                value: LT.Utilities.PSC_Density2,
                text: qsTr("PSC_Density2"),
                source: "qrc:/images/ps_lut2_concentration.svg"
            }
        },
        // MC8259 tsutsumi end
    ]

    /*!
        photoStyle9 を選択する LTMainPhotoStylePopup に表示するコンポーネントの組です
    */
    readonly property var psPhotoStyle9: [
        // '20秋FwUp（Gシリーズ → Sシリーズに合わせる）
        {
            component: popupBtnComponent,
            properties: {
                target: basePhotoStyleTargetName,
                value: LT.Utilities.PSC_BasePhotoStyle,
                text: qsTr("PSC_BasePhotoStyle"),
                source: "qrc:/images/button_placeholder.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: contrastTargetName,
                value: LT.Utilities.PSC_Contrast,
                text: qsTr("PSC_Contrast"),
                source: "qrc:/images/ps_contrast.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: highLightTargetName,
                value: LT.Utilities.PSC_HighLight,
                text: qsTr("PSC_HighLight"),
                source: "qrc:/images/highlight.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: shadowTargetName,
                value: LT.Utilities.PSC_Shadow,
                text: qsTr("PSC_Shadow"),
                source: "qrc:/images/shadow.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: saturationTargetName,
                value: LT.Utilities.PSC_Saturation,
                text: qsTr("PSC_Saturation"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: colorToneTargetName,
                value: LT.Utilities.PSC_ColorTone,
                text: qsTr("PSC_ColorTone"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: chrPhaseTargetName,
                value: LT.Utilities.PSC_ChromaPhase,
                text: qsTr("PSC_ChromaPhase"),
                source: "qrc:/images/ps_saturation2.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: filterTargetName,
                value: LT.Utilities.PSC_Filter,
                text: qsTr("PSC_Filter"),
                source: "qrc:/images/ps_filter.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: grainTargetName,
                value: LT.Utilities.PSC_Grain,
                text: qsTr("PSC_Grain"),
                source: "qrc:/images/ps_granular.svg"
            }
        },
        //20秋FwUp
        {
            component: popupBtnComponent,
            properties: {
                target: colorNoiseTargetName,
                value: LT.Utilities.PSC_ColorNoise,
                text: qsTr("PSC_Grain_Color"),
                source: "qrc:/images/ps_granular_color.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: sharpnessTargetName,
                value: LT.Utilities.PSC_Sharpness,
                text: qsTr("PSC_Sharpness"),
                source: "qrc:/images/ps_sharpness.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: noiseRedTargetName,
                value: LT.Utilities.PSC_NR,
                text: qsTr("PSC_NoiseReduct"),
                source: "qrc:/images/ps_noisereduction.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: kneeModeTargetName,
                value: LT.Utilities.PSC_KneeMode,
                text: qsTr("PSC_KneeMode"),
                source: "qrc:/images/ps_knee.svg"
            }
        },
        // 2020/08/25 Panasonic Kashihara Dual Native ISO > ISO > WB
        // IVC >> Ver.1.7 >> start >> No.2
        {
            component: popupBtnComponent,
            properties: {
                target: dualISOTargetName,
                value: LT.Utilities.PSC_DualISO,
                text: qsTr("PSC_DualISO"),
                source: "qrc:/images/ps_dual.svg"
            }
        },
        // IVC << Ver.1.7 << end << No.2
        {
            component: popupBtnComponent,
            properties: {
                target: isoTargetName,
                value: LT.Utilities.PSC_ISO,
                text: qsTr("PSC_ISO"),
                source: "qrc:/images/iso.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: wbTargetName,
                value: LT.Utilities.PSC_WB,
                text: qsTr("PSC_WB"),
                source: "qrc:/images/wb.svg"
            }
        },
        // MC5229
        {
            component: popupBtnComponent,
            properties: {
                target: gainTargetName,
                value: LT.Utilities.PSC_Gain,
                text: qsTr("PSC_GainSetting"),
                source: "qrc:/images/gain.svg"
            }
        },
        // MC8259 tsutsumi start
        {
            component: popupBtnComponent,
            properties: {
                target: lutTargetName,
                value: LT.Utilities.PSC_LUT,
                text: qsTr("PSC_LUT"),
                source: "qrc:/images/ps_lut.svg"
            }
        },
        {
            component: sliderComponentPositive,
            properties: {
                target: densityTargetName,
                value: LT.Utilities.PSC_Density,
                text: qsTr("PSC_Density"),
                source: "qrc:/images/ps_lut_concentration.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: lut2TargetName,
                value: LT.Utilities.PSC_LUT2,
                text: qsTr("PSC_LUT2"),
                source: "qrc:/images/ps_lut2.svg"
            }
        },
        {
            component: sliderComponentPositive,
            properties: {
                target: density2TargetName,
                value: LT.Utilities.PSC_Density2,
                text: qsTr("PSC_Density2"),
                source: "qrc:/images/ps_lut2_concentration.svg"
            }
        },
        // MC8259 tsutsumi end
    ]

    /*!
        photoStyle10 を選択する LTMainPhotoStylePopup に表示するコンポーネントの組です
    */
    readonly property var psPhotoStyle10: [
        // '20秋FwUp（Gシリーズ → Sシリーズに合わせる）
        {
            component: popupBtnComponent,
            properties: {
                target: basePhotoStyleTargetName,
                value: LT.Utilities.PSC_BasePhotoStyle,
                text: qsTr("PSC_BasePhotoStyle"),
                source: "qrc:/images/button_placeholder.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: contrastTargetName,
                value: LT.Utilities.PSC_Contrast,
                text: qsTr("PSC_Contrast"),
                source: "qrc:/images/ps_contrast.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: highLightTargetName,
                value: LT.Utilities.PSC_HighLight,
                text: qsTr("PSC_HighLight"),
                source: "qrc:/images/highlight.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: shadowTargetName,
                value: LT.Utilities.PSC_Shadow,
                text: qsTr("PSC_Shadow"),
                source: "qrc:/images/shadow.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: saturationTargetName,
                value: LT.Utilities.PSC_Saturation,
                text: qsTr("PSC_Saturation"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: colorToneTargetName,
                value: LT.Utilities.PSC_ColorTone,
                text: qsTr("PSC_ColorTone"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: chrPhaseTargetName,
                value: LT.Utilities.PSC_ChromaPhase,
                text: qsTr("PSC_ChromaPhase"),
                source: "qrc:/images/ps_saturation2.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: filterTargetName,
                value: LT.Utilities.PSC_Filter,
                text: qsTr("PSC_Filter"),
                source: "qrc:/images/ps_filter.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: grainTargetName,
                value: LT.Utilities.PSC_Grain,
                text: qsTr("PSC_Grain"),
                source: "qrc:/images/ps_granular.svg"
            }
        },
        //20秋FwUp
        {
            component: popupBtnComponent,
            properties: {
                target: colorNoiseTargetName,
                value: LT.Utilities.PSC_ColorNoise,
                text: qsTr("PSC_Grain_Color"),
                source: "qrc:/images/ps_granular_color.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: sharpnessTargetName,
                value: LT.Utilities.PSC_Sharpness,
                text: qsTr("PSC_Sharpness"),
                source: "qrc:/images/ps_sharpness.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: noiseRedTargetName,
                value: LT.Utilities.PSC_NR,
                text: qsTr("PSC_NoiseReduct"),
                source: "qrc:/images/ps_noisereduction.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: kneeModeTargetName,
                value: LT.Utilities.PSC_KneeMode,
                text: qsTr("PSC_KneeMode"),
                source: "qrc:/images/ps_knee.svg"
            }
        },
        // 2020/08/25 Panasonic Kashihara Dual Native ISO > ISO > WB
        // IVC >> Ver.1.7 >> start >> No.2
        {
            component: popupBtnComponent,
            properties: {
                target: dualISOTargetName,
                value: LT.Utilities.PSC_DualISO,
                text: qsTr("PSC_DualISO"),
                source: "qrc:/images/ps_dual.svg"
            }
        },
        // IVC << Ver.1.7 << end << No.2
        {
            component: popupBtnComponent,
            properties: {
                target: isoTargetName,
                value: LT.Utilities.PSC_ISO,
                text: qsTr("PSC_ISO"),
                source: "qrc:/images/iso.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: wbTargetName,
                value: LT.Utilities.PSC_WB,
                text: qsTr("PSC_WB"),
                source: "qrc:/images/wb.svg"
            }
        },
        // MC5229
        {
            component: popupBtnComponent,
            properties: {
                target: gainTargetName,
                value: LT.Utilities.PSC_Gain,
                text: qsTr("PSC_GainSetting"),
                source: "qrc:/images/gain.svg"
            }
        },
        // MC8259 tsutsumi start
        {
            component: popupBtnComponent,
            properties: {
                target: lutTargetName,
                value: LT.Utilities.PSC_LUT,
                text: qsTr("PSC_LUT"),
                source: "qrc:/images/ps_lut.svg"
            }
        },
        {
            component: sliderComponentPositive,
            properties: {
                target: densityTargetName,
                value: LT.Utilities.PSC_Density,
                text: qsTr("PSC_Density"),
                source: "qrc:/images/ps_lut_concentration.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: lut2TargetName,
                value: LT.Utilities.PSC_LUT2,
                text: qsTr("PSC_LUT2"),
                source: "qrc:/images/ps_lut2.svg"
            }
        },
        {
            component: sliderComponentPositive,
            properties: {
                target: density2TargetName,
                value: LT.Utilities.PSC_Density2,
                text: qsTr("PSC_Density2"),
                source: "qrc:/images/ps_lut2_concentration.svg"
            }
        },
        // MC8259 tsutsumi end
    ]
    // ivc << end << No.2

    /*!
        cinelikeD を選択する LTMainPhotoStylePopup に表示するコンポーネントの組です
     */
    readonly property var psCinelikeD: [
        // '20秋FwUp（Gシリーズ → Sシリーズに合わせる）
        {
            component: sliderComponent,
            properties: {
                target: contrastTargetName,
                value: LT.Utilities.PSC_Contrast,
                text: qsTr("PSC_Contrast"),
                source: "qrc:/images/ps_contrast.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: highLightTargetName,
                value: LT.Utilities.PSC_HighLight,
                text: qsTr("PSC_HighLight"),
                source: "qrc:/images/highlight.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: shadowTargetName,
                value: LT.Utilities.PSC_Shadow,
                text: qsTr("PSC_Shadow"),
                source: "qrc:/images/shadow.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: saturationTargetName,
                value: LT.Utilities.PSC_Saturation,
                text: qsTr("PSC_Saturation"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: colorToneTargetName,
                value: LT.Utilities.PSC_ColorTone,
                text: qsTr("PSC_ColorTone"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: chrPhaseTargetName,
                value: LT.Utilities.PSC_ChromaPhase,
                text: qsTr("PSC_ChromaPhase"),
                source: "qrc:/images/ps_saturation2.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: filterTargetName,
                value: LT.Utilities.PSC_Filter,
                text: qsTr("PSC_Filter"),
                source: "qrc:/images/ps_filter.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: grainTargetName,
                value: LT.Utilities.PSC_Grain,
                text: qsTr("PSC_Grain"),
                source: "qrc:/images/ps_granular.svg"
            }
        },
        //20秋FwUp
        {
            component: popupBtnComponent,
            properties: {
                target: colorNoiseTargetName,
                value: LT.Utilities.PSC_ColorNoise,
                text: qsTr("PSC_Grain_Color"),
                source: "qrc:/images/ps_granular_color.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: sharpnessTargetName,
                value: LT.Utilities.PSC_Sharpness,
                text: qsTr("PSC_Sharpness"),
                source: "qrc:/images/ps_sharpness.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: noiseRedTargetName,
                value: LT.Utilities.PSC_NR,
                text: qsTr("PSC_NoiseReduct"),
                source: "qrc:/images/ps_noisereduction.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: kneeModeTargetName,
                value: LT.Utilities.PSC_KneeMode,
                text: qsTr("PSC_KneeMode"),
                source: "qrc:/images/ps_knee.svg"
            }
        },
        // ivc >> start >> No.2
        {
            component: popupBtnComponent,
            properties: {
                target: isoTargetName,
                value: LT.Utilities.PSC_ISO,
                text: qsTr("PSC_ISO"),
                source: "qrc:/images/iso.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: wbTargetName,
                value: LT.Utilities.PSC_WB,
                text: qsTr("PSC_WB"),
                source: "qrc:/images/wb.svg"
            }
        },
        // ivc << end << No.2
        // MC5229
        {
            component: popupBtnComponent,
            properties: {
                target: gainTargetName,
                value: LT.Utilities.PSC_Gain,
                text: qsTr("PSC_GainSetting"),
                source: "qrc:/images/gain.svg"
            }
        },
    ]

    /*!
        cinelikeV を選択する LTMainPhotoStylePopup に表示するコンポーネントの組です
     */
    readonly property var psCinelikeV: [
        // '20秋FwUp（Gシリーズ → Sシリーズに合わせる）
        {
            component: sliderComponent,
            properties: {
                target: contrastTargetName,
                value: LT.Utilities.PSC_Contrast,
                text: qsTr("PSC_Contrast"),
                source: "qrc:/images/ps_contrast.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: highLightTargetName,
                value: LT.Utilities.PSC_HighLight,
                text: qsTr("PSC_HighLight"),
                source: "qrc:/images/highlight.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: shadowTargetName,
                value: LT.Utilities.PSC_Shadow,
                text: qsTr("PSC_Shadow"),
                source: "qrc:/images/shadow.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: saturationTargetName,
                value: LT.Utilities.PSC_Saturation,
                text: qsTr("PSC_Saturation"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: colorToneTargetName,
                value: LT.Utilities.PSC_ColorTone,
                text: qsTr("PSC_ColorTone"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: chrPhaseTargetName,
                value: LT.Utilities.PSC_ChromaPhase,
                text: qsTr("PSC_ChromaPhase"),
                source: "qrc:/images/ps_saturation2.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: filterTargetName,
                value: LT.Utilities.PSC_Filter,
                text: qsTr("PSC_Filter"),
                source: "qrc:/images/ps_filter.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: grainTargetName,
                value: LT.Utilities.PSC_Grain,
                text: qsTr("PSC_Grain"),
                source: "qrc:/images/ps_granular.svg"
            }
        },
        //20秋FwUp
        {
            component: popupBtnComponent,
            properties: {
                target: colorNoiseTargetName,
                value: LT.Utilities.PSC_ColorNoise,
                text: qsTr("PSC_Grain_Color"),
                source: "qrc:/images/ps_granular_color.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: sharpnessTargetName,
                value: LT.Utilities.PSC_Sharpness,
                text: qsTr("PSC_Sharpness"),
                source: "qrc:/images/ps_sharpness.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: noiseRedTargetName,
                value: LT.Utilities.PSC_NR,
                text: qsTr("PSC_NoiseReduct"),
                source: "qrc:/images/ps_noisereduction.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: kneeModeTargetName,
                value: LT.Utilities.PSC_KneeMode,
                text: qsTr("PSC_KneeMode"),
                source: "qrc:/images/ps_knee.svg"
            }
        },
        // ivc >> start >> No.2
        {
            component: popupBtnComponent,
            properties: {
                target: isoTargetName,
                value: LT.Utilities.PSC_ISO,
                text: qsTr("PSC_ISO"),
                source: "qrc:/images/iso.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: wbTargetName,
                value: LT.Utilities.PSC_WB,
                text: qsTr("PSC_WB"),
                source: "qrc:/images/wb.svg"
            }
        },
        // ivc << end << No.2
        // MC5229
        {
            component: popupBtnComponent,
            properties: {
                target: gainTargetName,
                value: LT.Utilities.PSC_Gain,
                text: qsTr("PSC_GainSetting"),
                source: "qrc:/images/gain.svg"
            }
        },
    ]

    /*!
        like709 を選択する LTMainPhotoStylePopup に表示するコンポーネントの組です
     */
    readonly property var psLike709: [
        // '20秋FwUp（Gシリーズ → Sシリーズに合わせる）
        {
            component: sliderComponent,
            properties: {
                target: contrastTargetName,
                value: LT.Utilities.PSC_Contrast,
                text: qsTr("PSC_Contrast"),
                source: "qrc:/images/ps_contrast.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: highLightTargetName,
                value: LT.Utilities.PSC_HighLight,
                text: qsTr("PSC_HighLight"),
                source: "qrc:/images/highlight.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: shadowTargetName,
                value: LT.Utilities.PSC_Shadow,
                text: qsTr("PSC_Shadow"),
                source: "qrc:/images/shadow.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: saturationTargetName,
                value: LT.Utilities.PSC_Saturation,
                text: qsTr("PSC_Saturation"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: colorToneTargetName,
                value: LT.Utilities.PSC_ColorTone,
                text: qsTr("PSC_ColorTone"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: chrPhaseTargetName,
                value: LT.Utilities.PSC_ChromaPhase,
                text: qsTr("PSC_ChromaPhase"),
                source: "qrc:/images/ps_saturation2.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: filterTargetName,
                value: LT.Utilities.PSC_Filter,
                text: qsTr("PSC_Filter"),
                source: "qrc:/images/ps_filter.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: grainTargetName,
                value: LT.Utilities.PSC_Grain,
                text: qsTr("PSC_Grain"),
                source: "qrc:/images/ps_granular.svg"
            }
        },
        //20秋FwUp
        {
            component: popupBtnComponent,
            properties: {
                target: colorNoiseTargetName,
                value: LT.Utilities.PSC_ColorNoise,
                text: qsTr("PSC_Grain_Color"),
                source: "qrc:/images/ps_granular_color.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: sharpnessTargetName,
                value: LT.Utilities.PSC_Sharpness,
                text: qsTr("PSC_Sharpness"),
                source: "qrc:/images/ps_sharpness.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: noiseRedTargetName,
                value: LT.Utilities.PSC_NR,
                text: qsTr("PSC_NoiseReduct"),
                source: "qrc:/images/ps_noisereduction.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: kneeModeTargetName,
                value: LT.Utilities.PSC_KneeMode,
                text: qsTr("PSC_KneeMode"),
                source: "qrc:/images/ps_knee.svg"
            }
        },
        // ivc >> start >> No.2
        {
            component: popupBtnComponent,
            properties: {
                target: isoTargetName,
                value: LT.Utilities.PSC_ISO,
                text: qsTr("PSC_ISO"),
                source: "qrc:/images/iso.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: wbTargetName,
                value: LT.Utilities.PSC_WB,
                text: qsTr("PSC_WB"),
                source: "qrc:/images/wb.svg"
            }
        },
        // ivc << end << No.2
        // MC5229
        {
            component: popupBtnComponent,
            properties: {
                target: gainTargetName,
                value: LT.Utilities.PSC_Gain,
                text: qsTr("PSC_GainSetting"),
                source: "qrc:/images/gain.svg"
            }
        },
    ]

    /*!
        linearGamma を選択する LTMainPhotoStylePopup に表示するコンポーネントの組です
     */
    readonly property var psLinearGamma: [
        // '20秋FwUp（Gシリーズ → Sシリーズに合わせる）
        {
            component: sliderComponent,
            properties: {
                target: contrastTargetName,
                value: LT.Utilities.PSC_Contrast,
                text: qsTr("PSC_Contrast"),
                source: "qrc:/images/ps_contrast.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: highLightTargetName,
                value: LT.Utilities.PSC_HighLight,
                text: qsTr("PSC_HighLight"),
                source: "qrc:/images/highlight.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: shadowTargetName,
                value: LT.Utilities.PSC_Shadow,
                text: qsTr("PSC_Shadow"),
                source: "qrc:/images/shadow.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: saturationTargetName,
                value: LT.Utilities.PSC_Saturation,
                text: qsTr("PSC_Saturation"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: colorToneTargetName,
                value: LT.Utilities.PSC_ColorTone,
                text: qsTr("PSC_ColorTone"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: chrPhaseTargetName,
                value: LT.Utilities.PSC_ChromaPhase,
                text: qsTr("PSC_ChromaPhase"),
                source: "qrc:/images/ps_saturation2.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: filterTargetName,
                value: LT.Utilities.PSC_Filter,
                text: qsTr("PSC_Filter"),
                source: "qrc:/images/ps_filter.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: grainTargetName,
                value: LT.Utilities.PSC_Grain,
                text: qsTr("PSC_Grain"),
                source: "qrc:/images/ps_granular.svg"
            }
        },
        //20秋FwUp
        {
            component: popupBtnComponent,
            properties: {
                target: colorNoiseTargetName,
                value: LT.Utilities.PSC_ColorNoise,
                text: qsTr("PSC_Grain_Color"),
                source: "qrc:/images/ps_granular_color.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: sharpnessTargetName,
                value: LT.Utilities.PSC_Sharpness,
                text: qsTr("PSC_Sharpness"),
                source: "qrc:/images/ps_sharpness.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: noiseRedTargetName,
                value: LT.Utilities.PSC_NR,
                text: qsTr("PSC_NoiseReduct"),
                source: "qrc:/images/ps_noisereduction.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: kneeModeTargetName,
                value: LT.Utilities.PSC_KneeMode,
                text: qsTr("PSC_KneeMode"),
                source: "qrc:/images/ps_knee.svg"
            }
        },
        // ivc >> start >> No.2
        {
            component: popupBtnComponent,
            properties: {
                target: isoTargetName,
                value: LT.Utilities.PSC_ISO,
                text: qsTr("PSC_ISO"),
                source: "qrc:/images/iso.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: wbTargetName,
                value: LT.Utilities.PSC_WB,
                text: qsTr("PSC_WB"),
                source: "qrc:/images/wb.svg"
            }
        },
        // ivc << end << No.2
        // MC5229
        {
            component: popupBtnComponent,
            properties: {
                target: gainTargetName,
                value: LT.Utilities.PSC_Gain,
                text: qsTr("PSC_GainSetting"),
                source: "qrc:/images/gain.svg"
            }
        },
    ]

    /*!
        vLogL を選択する LTMainPhotoStylePopup に表示するコンポーネントの組です
     */
    readonly property var psVLogL: [
        // '20秋FwUp（Gシリーズ → Sシリーズに合わせる）
        {
            component: sliderComponent,
            properties: {
                target: contrastTargetName,
                value: LT.Utilities.PSC_Contrast,
                text: qsTr("PSC_Contrast"),
                source: "qrc:/images/ps_contrast.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: highLightTargetName,
                value: LT.Utilities.PSC_HighLight,
                text: qsTr("PSC_HighLight"),
                source: "qrc:/images/highlight.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: shadowTargetName,
                value: LT.Utilities.PSC_Shadow,
                text: qsTr("PSC_Shadow"),
                source: "qrc:/images/shadow.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: saturationTargetName,
                value: LT.Utilities.PSC_Saturation,
                text: qsTr("PSC_Saturation"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: colorToneTargetName,
                value: LT.Utilities.PSC_ColorTone,
                text: qsTr("PSC_ColorTone"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: chrPhaseTargetName,
                value: LT.Utilities.PSC_ChromaPhase,
                text: qsTr("PSC_ChromaPhase"),
                source: "qrc:/images/ps_saturation2.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: filterTargetName,
                value: LT.Utilities.PSC_Filter,
                text: qsTr("PSC_Filter"),
                source: "qrc:/images/ps_filter.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: grainTargetName,
                value: LT.Utilities.PSC_Grain,
                text: qsTr("PSC_Grain"),
                source: "qrc:/images/ps_granular.svg"
            }
        },
        //20秋FwUp
        {
            component: popupBtnComponent,
            properties: {
                target: colorNoiseTargetName,
                value: LT.Utilities.PSC_ColorNoise,
                text: qsTr("PSC_Grain_Color"),
                source: "qrc:/images/ps_granular_color.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: sharpnessTargetName,
                value: LT.Utilities.PSC_Sharpness,
                text: qsTr("PSC_Sharpness"),
                source: "qrc:/images/ps_sharpness.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: noiseRedTargetName,
                value: LT.Utilities.PSC_NR,
                text: qsTr("PSC_NoiseReduct"),
                source: "qrc:/images/ps_noisereduction.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: kneeModeTargetName,
                value: LT.Utilities.PSC_KneeMode,
                text: qsTr("PSC_KneeMode"),
                source: "qrc:/images/ps_knee.svg"
            }
        },
        // ivc >> start >> No.2
        {
            component: popupBtnComponent,
            properties: {
                target: isoTargetName,
                value: LT.Utilities.PSC_ISO,
                text: qsTr("PSC_ISO"),
                source: "qrc:/images/iso.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: wbTargetName,
                value: LT.Utilities.PSC_WB,
                text: qsTr("PSC_WB"),
                source: "qrc:/images/wb.svg"
            }
        },
        // ivc << end << No.2
        // MC5229
        {
            component: popupBtnComponent,
            properties: {
                target: gainTargetName,
                value: LT.Utilities.PSC_Gain,
                text: qsTr("PSC_GainSetting"),
                source: "qrc:/images/gain.svg"
            }
        },
    ]

    /*!
        vLog を選択する LTMainPhotoStylePopup に表示するコンポーネントの組です
     */
    readonly property var psVLog: [
        // '20秋FwUp（Gシリーズ → Sシリーズに合わせる）
        {
            component: sliderComponent,
            properties: {
                target: contrastTargetName,
                value: LT.Utilities.PSC_Contrast,
                text: qsTr("PSC_Contrast"),
                source: "qrc:/images/ps_contrast.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: highLightTargetName,
                value: LT.Utilities.PSC_HighLight,
                text: qsTr("PSC_HighLight"),
                source: "qrc:/images/highlight.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: shadowTargetName,
                value: LT.Utilities.PSC_Shadow,
                text: qsTr("PSC_Shadow"),
                source: "qrc:/images/shadow.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: saturationTargetName,
                value: LT.Utilities.PSC_Saturation,
                text: qsTr("PSC_Saturation"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: colorToneTargetName,
                value: LT.Utilities.PSC_ColorTone,
                text: qsTr("PSC_ColorTone"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: chrPhaseTargetName,
                value: LT.Utilities.PSC_ChromaPhase,
                text: qsTr("PSC_ChromaPhase"),
                source: "qrc:/images/ps_saturation2.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: filterTargetName,
                value: LT.Utilities.PSC_Filter,
                text: qsTr("PSC_Filter"),
                source: "qrc:/images/ps_filter.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: grainTargetName,
                value: LT.Utilities.PSC_Grain,
                text: qsTr("PSC_Grain"),
                source: "qrc:/images/ps_granular.svg"
            }
        },
        //20秋FwUp
        {
            component: popupBtnComponent,
            properties: {
                target: colorNoiseTargetName,
                value: LT.Utilities.PSC_ColorNoise,
                text: qsTr("PSC_Grain_Color"),
                source: "qrc:/images/ps_granular_color.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: sharpnessTargetName,
                value: LT.Utilities.PSC_Sharpness,
                text: qsTr("PSC_Sharpness"),
                source: "qrc:/images/ps_sharpness.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: noiseRedTargetName,
                value: LT.Utilities.PSC_NR,
                text: qsTr("PSC_NoiseReduct"),
                source: "qrc:/images/ps_noisereduction.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: kneeModeTargetName,
                value: LT.Utilities.PSC_KneeMode,
                text: qsTr("PSC_KneeMode"),
                source: "qrc:/images/ps_knee.svg"
            }
        },
        // ivc >> start >> No.2
        {
            component: popupBtnComponent,
            properties: {
                target: isoTargetName,
                value: LT.Utilities.PSC_ISO,
                text: qsTr("PSC_ISO"),
                source: "qrc:/images/iso.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: wbTargetName,
                value: LT.Utilities.PSC_WB,
                text: qsTr("PSC_WB"),
                source: "qrc:/images/wb.svg"
            }
        },
        // ivc << end << No.2
        // MC5229
        {
            component: popupBtnComponent,
            properties: {
                target: gainTargetName,
                value: LT.Utilities.PSC_Gain,
                text: qsTr("PSC_GainSetting"),
                source: "qrc:/images/gain.svg"
            }
        },
    ]

// MC8259 start
    /*!
        ARRILogC3 を選択する LTMainPhotoStylePopup に表示するコンポーネントの組です
     */
    readonly property var psARRILogC3: [
        // '20秋FwUp（Gシリーズ → Sシリーズに合わせる）
        {
            component: sliderComponent,
            properties: {
                target: contrastTargetName,
                value: LT.Utilities.PSC_Contrast,
                text: qsTr("PSC_Contrast"),
                source: "qrc:/images/ps_contrast.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: highLightTargetName,
                value: LT.Utilities.PSC_HighLight,
                text: qsTr("PSC_HighLight"),
                source: "qrc:/images/highlight.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: shadowTargetName,
                value: LT.Utilities.PSC_Shadow,
                text: qsTr("PSC_Shadow"),
                source: "qrc:/images/shadow.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: saturationTargetName,
                value: LT.Utilities.PSC_Saturation,
                text: qsTr("PSC_Saturation"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: colorToneTargetName,
                value: LT.Utilities.PSC_ColorTone,
                text: qsTr("PSC_ColorTone"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: chrPhaseTargetName,
                value: LT.Utilities.PSC_ChromaPhase,
                text: qsTr("PSC_ChromaPhase"),
                source: "qrc:/images/ps_saturation2.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: filterTargetName,
                value: LT.Utilities.PSC_Filter,
                text: qsTr("PSC_Filter"),
                source: "qrc:/images/ps_filter.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: grainTargetName,
                value: LT.Utilities.PSC_Grain,
                text: qsTr("PSC_Grain"),
                source: "qrc:/images/ps_granular.svg"
            }
        },
        //20秋FwUp
        {
            component: popupBtnComponent,
            properties: {
                target: colorNoiseTargetName,
                value: LT.Utilities.PSC_ColorNoise,
                text: qsTr("PSC_Grain_Color"),
                source: "qrc:/images/ps_granular_color.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: sharpnessTargetName,
                value: LT.Utilities.PSC_Sharpness,
                text: qsTr("PSC_Sharpness"),
                source: "qrc:/images/ps_sharpness.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: noiseRedTargetName,
                value: LT.Utilities.PSC_NR,
                text: qsTr("PSC_NoiseReduct"),
                source: "qrc:/images/ps_noisereduction.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: kneeModeTargetName,
                value: LT.Utilities.PSC_KneeMode,
                text: qsTr("PSC_KneeMode"),
                source: "qrc:/images/ps_knee.svg"
            }
        },
        // ivc >> start >> No.2
        {
            component: popupBtnComponent,
            properties: {
                target: isoTargetName,
                value: LT.Utilities.PSC_ISO,
                text: qsTr("PSC_ISO"),
                source: "qrc:/images/iso.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: wbTargetName,
                value: LT.Utilities.PSC_WB,
                text: qsTr("PSC_WB"),
                source: "qrc:/images/wb.svg"
            }
        },
        // ivc << end << No.2
        // MC5229
        {
            component: popupBtnComponent,
            properties: {
                target: gainTargetName,
                value: LT.Utilities.PSC_Gain,
                text: qsTr("PSC_GainSetting"),
                source: "qrc:/images/gain.svg"
            }
        },
    ]
// MC8259 End

// MC5245, MC8245 start
    /*!
        リモートカメラ(UE160) を選択する LTMainPhotoStylePopup に表示するコンポーネントの組です
     */
    readonly property var psRemoteCamera: [
        {
            component: sliderComponent,
            properties: {
                target: contrastTargetName,
                value: LT.Utilities.PSC_Contrast,
                text: qsTr("PSC_Contrast"),
                source: "qrc:/images/ps_contrast.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: highLightTargetName,
                value: LT.Utilities.PSC_HighLight,
                text: qsTr("PSC_HighLight"),
                source: "qrc:/images/highlight.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: shadowTargetName,
                value: LT.Utilities.PSC_Shadow,
                text: qsTr("PSC_Shadow"),
                source: "qrc:/images/shadow.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: saturationTargetName,
                value: LT.Utilities.PSC_Saturation,
                text: qsTr("PSC_Saturation"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: colorToneTargetName,
                value: LT.Utilities.PSC_ColorTone,
                text: qsTr("PSC_ColorTone"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: chrPhaseTargetName,
                value: LT.Utilities.PSC_ChromaPhase,
                text: qsTr("PSC_ChromaPhase"),
                source: "qrc:/images/ps_saturation2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: sharpnessTargetName,
                value: LT.Utilities.PSC_Sharpness,
                text: qsTr("PSC_Sharpness"),
                source: "qrc:/images/ps_sharpness.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: noiseRedTargetName,
                value: LT.Utilities.PSC_NR,
                text: qsTr("PSC_NoiseReduct"),
                source: "qrc:/images/ps_noisereduction.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: kneeModeTargetName,
                value: LT.Utilities.PSC_KneeMode,
                text: qsTr("PSC_KneeMode"),
                source: "qrc:/images/ps_knee.svg"
            }
        },
    ]
// MC5245, MC8245 End

// IVC >> MC893 >> start >> No.3
    readonly property var psCinelikeD2: [
        // '20秋FwUp（Gシリーズ → Sシリーズに合わせる）
        {
            component: sliderComponent,
            properties: {
                target: contrastTargetName,
                value: LT.Utilities.PSC_Contrast,
                text: qsTr("PSC_Contrast"),
                source: "qrc:/images/ps_contrast.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: highLightTargetName,
                value: LT.Utilities.PSC_HighLight,
                text: qsTr("PSC_HighLight"),
                source: "qrc:/images/highlight.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: shadowTargetName,
                value: LT.Utilities.PSC_Shadow,
                text: qsTr("PSC_Shadow"),
                source: "qrc:/images/shadow.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: saturationTargetName,
                value: LT.Utilities.PSC_Saturation,
                text: qsTr("PSC_Saturation"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: colorToneTargetName,
                value: LT.Utilities.PSC_ColorTone,
                text: qsTr("PSC_ColorTone"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: chrPhaseTargetName,
                value: LT.Utilities.PSC_ChromaPhase,
                text: qsTr("PSC_ChromaPhase"),
                source: "qrc:/images/ps_saturation2.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: filterTargetName,
                value: LT.Utilities.PSC_Filter,
                text: qsTr("PSC_Filter"),
                source: "qrc:/images/ps_filter.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: grainTargetName,
                value: LT.Utilities.PSC_Grain,
                text: qsTr("PSC_Grain"),
                source: "qrc:/images/ps_granular.svg"
            }
        },
        //20秋FwUp
        {
            component: popupBtnComponent,
            properties: {
                target: colorNoiseTargetName,
                value: LT.Utilities.PSC_ColorNoise,
                text: qsTr("PSC_Grain_Color"),
                source: "qrc:/images/ps_granular_color.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: sharpnessTargetName,
                value: LT.Utilities.PSC_Sharpness,
                text: qsTr("PSC_Sharpness"),
                source: "qrc:/images/ps_sharpness.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: noiseRedTargetName,
                value: LT.Utilities.PSC_NR,
                text: qsTr("PSC_NoiseReduct"),
                source: "qrc:/images/ps_noisereduction.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: kneeModeTargetName,
                value: LT.Utilities.PSC_KneeMode,
                text: qsTr("PSC_KneeMode"),
                source: "qrc:/images/ps_knee.svg"
            }
        },
        // ivc >> start >> No.2
        {
            component: popupBtnComponent,
            properties: {
                target: isoTargetName,
                value: LT.Utilities.PSC_ISO,
                text: qsTr("PSC_ISO"),
                source: "qrc:/images/iso.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: wbTargetName,
                value: LT.Utilities.PSC_WB,
                text: qsTr("PSC_WB"),
                source: "qrc:/images/wb.svg"
            }
        },
        // ivc << end << No.2
        // MC5229
        {
            component: popupBtnComponent,
            properties: {
                target: gainTargetName,
                value: LT.Utilities.PSC_Gain,
                text: qsTr("PSC_GainSetting"),
                source: "qrc:/images/gain.svg"
            }
        },
    ]
    readonly property var psCinelikeV2: [
        // '20秋FwUp（Gシリーズ → Sシリーズに合わせる）
        {
            component: sliderComponent,
            properties: {
                target: contrastTargetName,
                value: LT.Utilities.PSC_Contrast,
                text: qsTr("PSC_Contrast"),
                source: "qrc:/images/ps_contrast.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: highLightTargetName,
                value: LT.Utilities.PSC_HighLight,
                text: qsTr("PSC_HighLight"),
                source: "qrc:/images/highlight.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: shadowTargetName,
                value: LT.Utilities.PSC_Shadow,
                text: qsTr("PSC_Shadow"),
                source: "qrc:/images/shadow.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: saturationTargetName,
                value: LT.Utilities.PSC_Saturation,
                text: qsTr("PSC_Saturation"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: colorToneTargetName,
                value: LT.Utilities.PSC_ColorTone,
                text: qsTr("PSC_ColorTone"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: chrPhaseTargetName,
                value: LT.Utilities.PSC_ChromaPhase,
                text: qsTr("PSC_ChromaPhase"),
                source: "qrc:/images/ps_saturation2.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: filterTargetName,
                value: LT.Utilities.PSC_Filter,
                text: qsTr("PSC_Filter"),
                source: "qrc:/images/ps_filter.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: grainTargetName,
                value: LT.Utilities.PSC_Grain,
                text: qsTr("PSC_Grain"),
                source: "qrc:/images/ps_granular.svg"
            }
        },
        //20秋FwUp
        {
            component: popupBtnComponent,
            properties: {
                target: colorNoiseTargetName,
                value: LT.Utilities.PSC_ColorNoise,
                text: qsTr("PSC_Grain_Color"),
                source: "qrc:/images/ps_granular_color.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: sharpnessTargetName,
                value: LT.Utilities.PSC_Sharpness,
                text: qsTr("PSC_Sharpness"),
                source: "qrc:/images/ps_sharpness.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: noiseRedTargetName,
                value: LT.Utilities.PSC_NR,
                text: qsTr("PSC_NoiseReduct"),
                source: "qrc:/images/ps_noisereduction.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: kneeModeTargetName,
                value: LT.Utilities.PSC_KneeMode,
                text: qsTr("PSC_KneeMode"),
                source: "qrc:/images/ps_knee.svg"
            }
        },
        // ivc >> start >> No.2
        {
            component: popupBtnComponent,
            properties: {
                target: isoTargetName,
                value: LT.Utilities.PSC_ISO,
                text: qsTr("PSC_ISO"),
                source: "qrc:/images/iso.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: wbTargetName,
                value: LT.Utilities.PSC_WB,
                text: qsTr("PSC_WB"),
                source: "qrc:/images/wb.svg"
            }
        },
        // ivc << end << No.2
        // MC5229
        {
            component: popupBtnComponent,
            properties: {
                target: gainTargetName,
                value: LT.Utilities.PSC_Gain,
                text: qsTr("PSC_GainSetting"),
                source: "qrc:/images/gain.svg"
            }
        },
    ]

    /*!
        psCinelikeA2 を選択する LTMainPhotoStylePopup に表示するコンポーネントの組です
     */
    //
    // 2024/06/04 仕様追加
    // 項目は V2 に合わせている
    readonly property var psCinelikeA2: [
        {
            component: sliderComponent,
            properties: {
                target: contrastTargetName,
                value: LT.Utilities.PSC_Contrast,
                text: qsTr("PSC_Contrast"),
                source: "qrc:/images/ps_contrast.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: highLightTargetName,
                value: LT.Utilities.PSC_HighLight,
                text: qsTr("PSC_HighLight"),
                source: "qrc:/images/highlight.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: shadowTargetName,
                value: LT.Utilities.PSC_Shadow,
                text: qsTr("PSC_Shadow"),
                source: "qrc:/images/shadow.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: saturationTargetName,
                value: LT.Utilities.PSC_Saturation,
                text: qsTr("PSC_Saturation"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: colorToneTargetName,
                value: LT.Utilities.PSC_ColorTone,
                text: qsTr("PSC_ColorTone"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: chrPhaseTargetName,
                value: LT.Utilities.PSC_ChromaPhase,
                text: qsTr("PSC_ChromaPhase"),
                source: "qrc:/images/ps_saturation2.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: filterTargetName,
                value: LT.Utilities.PSC_Filter,
                text: qsTr("PSC_Filter"),
                source: "qrc:/images/ps_filter.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: grainTargetName,
                value: LT.Utilities.PSC_Grain,
                text: qsTr("PSC_Grain"),
                source: "qrc:/images/ps_granular.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: colorNoiseTargetName,
                value: LT.Utilities.PSC_ColorNoise,
                text: qsTr("PSC_Grain_Color"),
                source: "qrc:/images/ps_granular_color.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: sharpnessTargetName,
                value: LT.Utilities.PSC_Sharpness,
                text: qsTr("PSC_Sharpness"),
                source: "qrc:/images/ps_sharpness.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: noiseRedTargetName,
                value: LT.Utilities.PSC_NR,
                text: qsTr("PSC_NoiseReduct"),
                source: "qrc:/images/ps_noisereduction.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: kneeModeTargetName,
                value: LT.Utilities.PSC_KneeMode,
                text: qsTr("PSC_KneeMode"),
                source: "qrc:/images/ps_knee.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: isoTargetName,
                value: LT.Utilities.PSC_ISO,
                text: qsTr("PSC_ISO"),
                source: "qrc:/images/iso.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: wbTargetName,
                value: LT.Utilities.PSC_WB,
                text: qsTr("PSC_WB"),
                source: "qrc:/images/wb.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: gainTargetName,
                value: LT.Utilities.PSC_Gain,
                text: qsTr("PSC_GainSetting"),
                source: "qrc:/images/gain.svg"
            }
        },
    ]
// IVC << MC893 << end << No.3
    /*!
        lMonoChromeD を選択する LTMainPhotoStylePopup に表示するコンポーネントの組です
     */
    readonly property var psLMonoChromeD: [
        // '20秋FwUp（Gシリーズ → Sシリーズに合わせる）
        {
            component: sliderComponent,
            properties: {
                target: contrastTargetName,
                value: LT.Utilities.PSC_Contrast,
                text: qsTr("PSC_Contrast"),
                source: "qrc:/images/ps_contrast.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: highLightTargetName,
                value: LT.Utilities.PSC_HighLight,
                text: qsTr("PSC_HighLight"),
                source: "qrc:/images/highlight.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: shadowTargetName,
                value: LT.Utilities.PSC_Shadow,
                text: qsTr("PSC_Shadow"),
                source: "qrc:/images/shadow.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: saturationTargetName,
                value: LT.Utilities.PSC_Saturation,
                text: qsTr("PSC_Saturation"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: colorToneTargetName,
                value: LT.Utilities.PSC_ColorTone,
                text: qsTr("PSC_ColorTone"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: chrPhaseTargetName,
                value: LT.Utilities.PSC_ChromaPhase,
                text: qsTr("PSC_ChromaPhase"),
                source: "qrc:/images/ps_saturation2.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: filterTargetName,
                value: LT.Utilities.PSC_Filter,
                text: qsTr("PSC_Filter"),
                source: "qrc:/images/ps_filter.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: grainTargetName,
                value: LT.Utilities.PSC_Grain,
                text: qsTr("PSC_Grain"),
                source: "qrc:/images/ps_granular.svg"
            }
        },
        //20秋FwUp
        {
            component: popupBtnComponent,
            properties: {
                target: colorNoiseTargetName,
                value: LT.Utilities.PSC_ColorNoise,
                text: qsTr("PSC_Grain_Color"),
                source: "qrc:/images/ps_granular_color.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: sharpnessTargetName,
                value: LT.Utilities.PSC_Sharpness,
                text: qsTr("PSC_Sharpness"),
                source: "qrc:/images/ps_sharpness.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: noiseRedTargetName,
                value: LT.Utilities.PSC_NR,
                text: qsTr("PSC_NoiseReduct"),
                source: "qrc:/images/ps_noisereduction.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: kneeModeTargetName,
                value: LT.Utilities.PSC_KneeMode,
                text: qsTr("PSC_KneeMode"),
                source: "qrc:/images/ps_knee.svg"
            }
        },
        // ivc >> start >> No.2
        {
            component: popupBtnComponent,
            properties: {
                target: isoTargetName,
                value: LT.Utilities.PSC_ISO,
                text: qsTr("PSC_ISO"),
                source: "qrc:/images/iso.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: wbTargetName,
                value: LT.Utilities.PSC_WB,
                text: qsTr("PSC_WB"),
                source: "qrc:/images/wb.svg"
            }
        },
        // ivc << end << No.2
        // MC5229
        {
            component: popupBtnComponent,
            properties: {
                target: gainTargetName,
                value: LT.Utilities.PSC_Gain,
                text: qsTr("PSC_GainSetting"),
                source: "qrc:/images/gain.svg"
            }
        },
    ]

    // ivc >> start >> No.2
    /*!
        hybridLogGamma を選択する LTMainPhotoStylePopup に表示するコンポーネントの組です
     */
    readonly property var psHybridLogGamma: [
        // '20秋FwUp（Gシリーズ → Sシリーズに合わせる）
        {
            component: sliderComponent,
            properties: {
                target: contrastTargetName,
                value: LT.Utilities.PSC_Contrast,
                text: qsTr("PSC_Contrast"),
                source: "qrc:/images/ps_contrast.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: highLightTargetName,
                value: LT.Utilities.PSC_HighLight,
                text: qsTr("PSC_HighLight"),
                source: "qrc:/images/highlight.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: shadowTargetName,
                value: LT.Utilities.PSC_Shadow,
                text: qsTr("PSC_Shadow"),
                source: "qrc:/images/shadow.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: saturationTargetName,
                value: LT.Utilities.PSC_Saturation,
                text: qsTr("PSC_Saturation"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: colorToneTargetName,
                value: LT.Utilities.PSC_ColorTone,
                text: qsTr("PSC_ColorTone"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: chrPhaseTargetName,
                value: LT.Utilities.PSC_ChromaPhase,
                text: qsTr("PSC_ChromaPhase"),
                source: "qrc:/images/ps_saturation2.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: filterTargetName,
                value: LT.Utilities.PSC_Filter,
                text: qsTr("PSC_Filter"),
                source: "qrc:/images/ps_filter.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: grainTargetName,
                value: LT.Utilities.PSC_Grain,
                text: qsTr("PSC_Grain"),
                source: "qrc:/images/ps_granular.svg"
            }
        },
        //20秋FwUp
        {
            component: popupBtnComponent,
            properties: {
                target: colorNoiseTargetName,
                value: LT.Utilities.PSC_ColorNoise,
                text: qsTr("PSC_Grain_Color"),
                source: "qrc:/images/ps_granular_color.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: sharpnessTargetName,
                value: LT.Utilities.PSC_Sharpness,
                text: qsTr("PSC_Sharpness"),
                source: "qrc:/images/ps_sharpness.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: noiseRedTargetName,
                value: LT.Utilities.PSC_NR,
                text: qsTr("PSC_NoiseReduct"),
                source: "qrc:/images/ps_noisereduction.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: kneeModeTargetName,
                value: LT.Utilities.PSC_KneeMode,
                text: qsTr("PSC_KneeMode"),
                source: "qrc:/images/ps_knee.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: isoTargetName,
                value: LT.Utilities.PSC_ISO,
                text: qsTr("PSC_ISO"),
                source: "qrc:/images/iso.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: wbTargetName,
                value: LT.Utilities.PSC_WB,
                text: qsTr("PSC_WB"),
                source: "qrc:/images/wb.svg"
            }
        },
        // MC5229
        {
            component: popupBtnComponent,
            properties: {
                target: gainTargetName,
                value: LT.Utilities.PSC_Gain,
                text: qsTr("PSC_GainSetting"),
                source: "qrc:/images/gain.svg"
            }
        },
    ]
    // ivc << end << No.2
    // ivc >> start >> #9860
    /*!
        hlgStandard を選択する LTMainPhotoStylePopup に表示するコンポーネントの組です
     */
    readonly property var psHLGStandard: [
        // '20秋FwUp（Gシリーズ → Sシリーズに合わせる）
        {
            component: sliderComponent,
            properties: {
                target: contrastTargetName,
                value: LT.Utilities.PSC_Contrast,
                text: qsTr("PSC_Contrast"),
                source: "qrc:/images/ps_contrast.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: highLightTargetName,
                value: LT.Utilities.PSC_HighLight,
                text: qsTr("PSC_HighLight"),
                source: "qrc:/images/highlight.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: shadowTargetName,
                value: LT.Utilities.PSC_Shadow,
                text: qsTr("PSC_Shadow"),
                source: "qrc:/images/shadow.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: saturationTargetName,
                value: LT.Utilities.PSC_Saturation,
                text: qsTr("PSC_Saturation"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: colorToneTargetName,
                value: LT.Utilities.PSC_ColorTone,
                text: qsTr("PSC_ColorTone"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: chrPhaseTargetName,
                value: LT.Utilities.PSC_ChromaPhase,
                text: qsTr("PSC_ChromaPhase"),
                source: "qrc:/images/ps_saturation2.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: filterTargetName,
                value: LT.Utilities.PSC_Filter,
                text: qsTr("PSC_Filter"),
                source: "qrc:/images/ps_filter.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: grainTargetName,
                value: LT.Utilities.PSC_Grain,
                text: qsTr("PSC_Grain"),
                source: "qrc:/images/ps_granular.svg"
            }
        },
        //20秋FwUp
        {
            component: popupBtnComponent,
            properties: {
                target: colorNoiseTargetName,
                value: LT.Utilities.PSC_ColorNoise,
                text: qsTr("PSC_Grain_Color"),
                source: "qrc:/images/ps_granular_color.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: sharpnessTargetName,
                value: LT.Utilities.PSC_Sharpness,
                text: qsTr("PSC_Sharpness"),
                source: "qrc:/images/ps_sharpness.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: noiseRedTargetName,
                value: LT.Utilities.PSC_NR,
                text: qsTr("PSC_NoiseReduct"),
                source: "qrc:/images/ps_noisereduction.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: kneeModeTargetName,
                value: LT.Utilities.PSC_KneeMode,
                text: qsTr("PSC_KneeMode"),
                source: "qrc:/images/ps_knee.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: isoTargetName,
                value: LT.Utilities.PSC_ISO,
                text: qsTr("PSC_ISO"),
                source: "qrc:/images/iso.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: wbTargetName,
                value: LT.Utilities.PSC_WB,
                text: qsTr("PSC_WB"),
                source: "qrc:/images/wb.svg"
            }
        },
        // MC5229
        {
            component: popupBtnComponent,
            properties: {
                target: gainTargetName,
                value: LT.Utilities.PSC_Gain,
                text: qsTr("PSC_GainSetting"),
                source: "qrc:/images/gain.svg"
            }
        },
    ]

    // ivc >> start >> #9860
    /*!
        hlgMonochrome を選択する LTMainPhotoStylePopup に表示するコンポーネントの組です
     */
    readonly property var psHLGMonochrome: [
        // '20秋FwUp（Gシリーズ → Sシリーズに合わせる）
        {
            component: sliderComponent,
            properties: {
                target: contrastTargetName,
                value: LT.Utilities.PSC_Contrast,
                text: qsTr("PSC_Contrast"),
                source: "qrc:/images/ps_contrast.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: highLightTargetName,
                value: LT.Utilities.PSC_HighLight,
                text: qsTr("PSC_HighLight"),
                source: "qrc:/images/highlight.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: shadowTargetName,
                value: LT.Utilities.PSC_Shadow,
                text: qsTr("PSC_Shadow"),
                source: "qrc:/images/shadow.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: saturationTargetName,
                value: LT.Utilities.PSC_Saturation,
                text: qsTr("PSC_Saturation"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: colorToneTargetName,
                value: LT.Utilities.PSC_ColorTone,
                text: qsTr("PSC_ColorTone"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: chrPhaseTargetName,
                value: LT.Utilities.PSC_ChromaPhase,
                text: qsTr("PSC_ChromaPhase"),
                source: "qrc:/images/ps_saturation2.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: filterTargetName,
                value: LT.Utilities.PSC_Filter,
                text: qsTr("PSC_Filter"),
                source: "qrc:/images/ps_filter.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: grainTargetName,
                value: LT.Utilities.PSC_Grain,
                text: qsTr("PSC_Grain"),
                source: "qrc:/images/ps_granular.svg"
            }
        },
        //20秋FwUp
        {
            component: popupBtnComponent,
            properties: {
                target: colorNoiseTargetName,
                value: LT.Utilities.PSC_ColorNoise,
                text: qsTr("PSC_Grain_Color"),
                source: "qrc:/images/ps_granular_color.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: sharpnessTargetName,
                value: LT.Utilities.PSC_Sharpness,
                text: qsTr("PSC_Sharpness"),
                source: "qrc:/images/ps_sharpness.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: noiseRedTargetName,
                value: LT.Utilities.PSC_NR,
                text: qsTr("PSC_NoiseReduct"),
                source: "qrc:/images/ps_noisereduction.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: kneeModeTargetName,
                value: LT.Utilities.PSC_KneeMode,
                text: qsTr("PSC_KneeMode"),
                source: "qrc:/images/ps_knee.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: isoTargetName,
                value: LT.Utilities.PSC_ISO,
                text: qsTr("PSC_ISO"),
                source: "qrc:/images/iso.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: wbTargetName,
                value: LT.Utilities.PSC_WB,
                text: qsTr("PSC_WB"),
                source: "qrc:/images/wb.svg"
            }
        },
        // MC5229
        {
            component: popupBtnComponent,
            properties: {
                target: gainTargetName,
                value: LT.Utilities.PSC_Gain,
                text: qsTr("PSC_GainSetting"),
                source: "qrc:/images/gain.svg"
            }
        },
    ]
    // ivc << end << #9860

    /*!
        hlgForGSeries を選択する LTMainPhotoStylePopup に表示するコンポーネントの組です
     */
    readonly property var psHLGForGSeries: [    // 2019/10/16 Panasonic Nakano
        // '20秋FwUp（Gシリーズ → Sシリーズに合わせる）
        {
            component: sliderComponent,
            properties: {
                target: contrastTargetName,
                value: LT.Utilities.PSC_Contrast,
                text: qsTr("PSC_Contrast"),
                source: "qrc:/images/ps_contrast.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: highLightTargetName,
                value: LT.Utilities.PSC_HighLight,
                text: qsTr("PSC_HighLight"),
                source: "qrc:/images/highlight.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: shadowTargetName,
                value: LT.Utilities.PSC_Shadow,
                text: qsTr("PSC_Shadow"),
                source: "qrc:/images/shadow.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: saturationTargetName,
                value: LT.Utilities.PSC_Saturation,
                text: qsTr("PSC_Saturation"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: colorToneTargetName,
                value: LT.Utilities.PSC_ColorTone,
                text: qsTr("PSC_ColorTone"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: chrPhaseTargetName,
                value: LT.Utilities.PSC_ChromaPhase,
                text: qsTr("PSC_ChromaPhase"),
                source: "qrc:/images/ps_saturation2.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: filterTargetName,
                value: LT.Utilities.PSC_Filter,
                text: qsTr("PSC_Filter"),
                source: "qrc:/images/ps_filter.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: grainTargetName,
                value: LT.Utilities.PSC_Grain,
                text: qsTr("PSC_Grain"),
                source: "qrc:/images/ps_granular.svg"
            }
        },
        //20秋FwUp
        {
            component: popupBtnComponent,
            properties: {
                target: colorNoiseTargetName,
                value: LT.Utilities.PSC_ColorNoise,
                text: qsTr("PSC_Grain_Color"),
                source: "qrc:/images/ps_granular_color.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: sharpnessTargetName,
                value: LT.Utilities.PSC_Sharpness,
                text: qsTr("PSC_Sharpness"),
                source: "qrc:/images/ps_sharpness.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: noiseRedTargetName,
                value: LT.Utilities.PSC_NR,
                text: qsTr("PSC_NoiseReduct"),
                source: "qrc:/images/ps_noisereduction.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: kneeModeTargetName,
                value: LT.Utilities.PSC_KneeMode,
                text: qsTr("PSC_KneeMode"),
                source: "qrc:/images/ps_knee.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: isoTargetName,
                value: LT.Utilities.PSC_ISO,
                text: qsTr("PSC_ISO"),
                source: "qrc:/images/iso.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: wbTargetName,
                value: LT.Utilities.PSC_WB,
                text: qsTr("PSC_WB"),
                source: "qrc:/images/wb.svg"
            }
        },
        // MC5229
        {
            component: popupBtnComponent,
            properties: {
                target: gainTargetName,
                value: LT.Utilities.PSC_Gain,
                text: qsTr("PSC_GainSetting"),
                source: "qrc:/images/gain.svg"
            }
        },
    ]

    readonly property var psLMonoChromeS: [
        // '20秋FwUp（Gシリーズ → Sシリーズに合わせる）
        {
            component: sliderComponent,
            properties: {
                target: contrastTargetName,
                value: LT.Utilities.PSC_Contrast,
                text: qsTr("PSC_Contrast"),
                source: "qrc:/images/ps_contrast.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: highLightTargetName,
                value: LT.Utilities.PSC_HighLight,
                text: qsTr("PSC_HighLight"),
                source: "qrc:/images/highlight.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: shadowTargetName,
                value: LT.Utilities.PSC_Shadow,
                text: qsTr("PSC_Shadow"),
                source: "qrc:/images/shadow.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: saturationTargetName,
                value: LT.Utilities.PSC_Saturation,
                text: qsTr("PSC_Saturation"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: colorToneTargetName,
                value: LT.Utilities.PSC_ColorTone,
                text: qsTr("PSC_ColorTone"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: chrPhaseTargetName,
                value: LT.Utilities.PSC_ChromaPhase,
                text: qsTr("PSC_ChromaPhase"),
                source: "qrc:/images/ps_saturation2.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: filterTargetName,
                value: LT.Utilities.PSC_Filter,
                text: qsTr("PSC_Filter"),
                source: "qrc:/images/ps_filter.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: grainTargetName,
                value: LT.Utilities.PSC_Grain,
                text: qsTr("PSC_Grain"),
                source: "qrc:/images/ps_granular.svg"
            }
        },
        //20秋FwUp
        {
            component: popupBtnComponent,
            properties: {
                target: colorNoiseTargetName,
                value: LT.Utilities.PSC_ColorNoise,
                text: qsTr("PSC_Grain_Color"),
                source: "qrc:/images/ps_granular_color.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: sharpnessTargetName,
                value: LT.Utilities.PSC_Sharpness,
                text: qsTr("PSC_Sharpness"),
                source: "qrc:/images/ps_sharpness.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: noiseRedTargetName,
                value: LT.Utilities.PSC_NR,
                text: qsTr("PSC_NoiseReduct"),
                source: "qrc:/images/ps_noisereduction.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: kneeModeTargetName,
                value: LT.Utilities.PSC_KneeMode,
                text: qsTr("PSC_KneeMode"),
                source: "qrc:/images/ps_knee.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: isoTargetName,
                value: LT.Utilities.PSC_ISO,
                text: qsTr("PSC_ISO"),
                source: "qrc:/images/iso.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: wbTargetName,
                value: LT.Utilities.PSC_WB,
                text: qsTr("PSC_WB"),
                source: "qrc:/images/wb.svg"
            }
        },
        // MC5229
        {
            component: popupBtnComponent,
            properties: {
                target: gainTargetName,
                value: LT.Utilities.PSC_Gain,
                text: qsTr("PSC_GainSetting"),
                source: "qrc:/images/gain.svg"
            }
        },
    ]

    readonly property var psLeicaMonochrome: [
        // '20秋FwUp（Gシリーズ → Sシリーズに合わせる）
        {
            component: sliderComponent,
            properties: {
                target: contrastTargetName,
                value: LT.Utilities.PSC_Contrast,
                text: qsTr("PSC_Contrast"),
                source: "qrc:/images/ps_contrast.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: highLightTargetName,
                value: LT.Utilities.PSC_HighLight,
                text: qsTr("PSC_HighLight"),
                source: "qrc:/images/highlight.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: shadowTargetName,
                value: LT.Utilities.PSC_Shadow,
                text: qsTr("PSC_Shadow"),
                source: "qrc:/images/shadow.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: saturationTargetName,
                value: LT.Utilities.PSC_Saturation,
                text: qsTr("PSC_Saturation"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: colorToneTargetName,
                value: LT.Utilities.PSC_ColorTone,
                text: qsTr("PSC_ColorTone"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: chrPhaseTargetName,
                value: LT.Utilities.PSC_ChromaPhase,
                text: qsTr("PSC_ChromaPhase"),
                source: "qrc:/images/ps_saturation2.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: filterTargetName,
                value: LT.Utilities.PSC_Filter,
                text: qsTr("PSC_Filter"),
                source: "qrc:/images/ps_filter.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: grainTargetName,
                value: LT.Utilities.PSC_Grain,
                text: qsTr("PSC_Grain"),
                source: "qrc:/images/ps_granular.svg"
            }
        },
        //20秋FwUp
        {
            component: popupBtnComponent,
            properties: {
                target: colorNoiseTargetName,
                value: LT.Utilities.PSC_ColorNoise,
                text: qsTr("PSC_Grain_Color"),
                source: "qrc:/images/ps_granular_color.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: sharpnessTargetName,
                value: LT.Utilities.PSC_Sharpness,
                text: qsTr("PSC_Sharpness"),
                source: "qrc:/images/ps_sharpness.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: noiseRedTargetName,
                value: LT.Utilities.PSC_NR,
                text: qsTr("PSC_NoiseReduct"),
                source: "qrc:/images/ps_noisereduction.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: kneeModeTargetName,
                value: LT.Utilities.PSC_KneeMode,
                text: qsTr("PSC_KneeMode"),
                source: "qrc:/images/ps_knee.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: isoTargetName,
                value: LT.Utilities.PSC_ISO,
                text: qsTr("PSC_ISO"),
                source: "qrc:/images/iso.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: wbTargetName,
                value: LT.Utilities.PSC_WB,
                text: qsTr("PSC_WB"),
                source: "qrc:/images/wb.svg"
            }
        },
        // MC5229
        {
            component: popupBtnComponent,
            properties: {
                target: gainTargetName,
                value: LT.Utilities.PSC_Gain,
                text: qsTr("PSC_GainSetting"),
                source: "qrc:/images/gain.svg"
            }
        },
    ]

    readonly property var psLClassicNeo: [
        // '20秋FwUp（Gシリーズ → Sシリーズに合わせる）
        {
            component: sliderComponent,
            properties: {
                target: contrastTargetName,
                value: LT.Utilities.PSC_Contrast,
                text: qsTr("PSC_Contrast"),
                source: "qrc:/images/ps_contrast.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: highLightTargetName,
                value: LT.Utilities.PSC_HighLight,
                text: qsTr("PSC_HighLight"),
                source: "qrc:/images/highlight.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: shadowTargetName,
                value: LT.Utilities.PSC_Shadow,
                text: qsTr("PSC_Shadow"),
                source: "qrc:/images/shadow.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: saturationTargetName,
                value: LT.Utilities.PSC_Saturation,
                text: qsTr("PSC_Saturation"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: colorToneTargetName,
                value: LT.Utilities.PSC_ColorTone,
                text: qsTr("PSC_ColorTone"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: chrPhaseTargetName,
                value: LT.Utilities.PSC_ChromaPhase,
                text: qsTr("PSC_ChromaPhase"),
                source: "qrc:/images/ps_saturation2.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: filterTargetName,
                value: LT.Utilities.PSC_Filter,
                text: qsTr("PSC_Filter"),
                source: "qrc:/images/ps_filter.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: grainTargetName,
                value: LT.Utilities.PSC_Grain,
                text: qsTr("PSC_Grain"),
                source: "qrc:/images/ps_granular.svg"
            }
        },
        //20秋FwUp
        {
            component: popupBtnComponent,
            properties: {
                target: colorNoiseTargetName,
                value: LT.Utilities.PSC_ColorNoise,
                text: qsTr("PSC_Grain_Color"),
                source: "qrc:/images/ps_granular_color.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: sharpnessTargetName,
                value: LT.Utilities.PSC_Sharpness,
                text: qsTr("PSC_Sharpness"),
                source: "qrc:/images/ps_sharpness.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: noiseRedTargetName,
                value: LT.Utilities.PSC_NR,
                text: qsTr("PSC_NoiseReduct"),
                source: "qrc:/images/ps_noisereduction.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: kneeModeTargetName,
                value: LT.Utilities.PSC_KneeMode,
                text: qsTr("PSC_KneeMode"),
                source: "qrc:/images/ps_knee.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: isoTargetName,
                value: LT.Utilities.PSC_ISO,
                text: qsTr("PSC_ISO"),
                source: "qrc:/images/iso.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: wbTargetName,
                value: LT.Utilities.PSC_WB,
                text: qsTr("PSC_WB"),
                source: "qrc:/images/wb.svg"
            }
        },
        // MC5229
        {
            component: popupBtnComponent,
            properties: {
                target: gainTargetName,
                value: LT.Utilities.PSC_Gain,
                text: qsTr("PSC_GainSetting"),
                source: "qrc:/images/gain.svg"
            }
        },
    ]

    readonly property var psHLGFullRange: [
        // '20秋FwUp（Gシリーズ → Sシリーズに合わせる）
        {
            component: sliderComponent,
            properties: {
                target: contrastTargetName,
                value: LT.Utilities.PSC_Contrast,
                text: qsTr("PSC_Contrast"),
                source: "qrc:/images/ps_contrast.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: highLightTargetName,
                value: LT.Utilities.PSC_HighLight,
                text: qsTr("PSC_HighLight"),
                source: "qrc:/images/highlight.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: shadowTargetName,
                value: LT.Utilities.PSC_Shadow,
                text: qsTr("PSC_Shadow"),
                source: "qrc:/images/shadow.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: saturationTargetName,
                value: LT.Utilities.PSC_Saturation,
                text: qsTr("PSC_Saturation"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: colorToneTargetName,
                value: LT.Utilities.PSC_ColorTone,
                text: qsTr("PSC_ColorTone"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: chrPhaseTargetName,
                value: LT.Utilities.PSC_ChromaPhase,
                text: qsTr("PSC_ChromaPhase"),
                source: "qrc:/images/ps_saturation2.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: filterTargetName,
                value: LT.Utilities.PSC_Filter,
                text: qsTr("PSC_Filter"),
                source: "qrc:/images/ps_filter.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: grainTargetName,
                value: LT.Utilities.PSC_Grain,
                text: qsTr("PSC_Grain"),
                source: "qrc:/images/ps_granular.svg"
            }
        },
        //20秋FwUp
        {
            component: popupBtnComponent,
            properties: {
                target: colorNoiseTargetName,
                value: LT.Utilities.PSC_ColorNoise,
                text: qsTr("PSC_Grain_Color"),
                source: "qrc:/images/ps_granular_color.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: sharpnessTargetName,
                value: LT.Utilities.PSC_Sharpness,
                text: qsTr("PSC_Sharpness"),
                source: "qrc:/images/ps_sharpness.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: noiseRedTargetName,
                value: LT.Utilities.PSC_NR,
                text: qsTr("PSC_NoiseReduct"),
                source: "qrc:/images/ps_noisereduction.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: kneeModeTargetName,
                value: LT.Utilities.PSC_KneeMode,
                text: qsTr("PSC_KneeMode"),
                source: "qrc:/images/ps_knee.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: isoTargetName,
                value: LT.Utilities.PSC_ISO,
                text: qsTr("PSC_ISO"),
                source: "qrc:/images/iso.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: wbTargetName,
                value: LT.Utilities.PSC_WB,
                text: qsTr("PSC_WB"),
                source: "qrc:/images/wb.svg"
            }
        },
        // MC5229
        {
            component: popupBtnComponent,
            properties: {
                target: gainTargetName,
                value: LT.Utilities.PSC_Gain,
                text: qsTr("PSC_GainSetting"),
                source: "qrc:/images/gain.svg"
            }
        },
    ]

    readonly property var psRealTimeLUT: [
        // ベースフォトスタイルが変更可能   tsutsumi 2023/11
        {
            component: popupBtnComponent,
            properties: {
                target: basePhotoStyle2TargetName,
                value: LT.Utilities.PSC_BasePhotoStyle2,
                text:  qsTr("PSC_LUTBasePhotoStyle"),
                source: "qrc:/images/button_placeholder.svg"
            }
        },
        // MC8259 tsutsumi start
        {
            component: popupBtnComponent,
            properties: {
                target: lutTargetName,
                value: LT.Utilities.PSC_LUT,
                text: qsTr("PSC_LUT"),
                source: "qrc:/images/ps_lut.svg"
            }
        },
        {
            component: sliderComponentPositive,
            properties: {
                target: densityTargetName,
                value: LT.Utilities.PSC_Density,
                text: qsTr("PSC_Density"),
                source: "qrc:/images/ps_lut_concentration.svg"
            }
        },
        // MC8259 tsutsumi end
        // '20秋FwUp（Gシリーズ → Sシリーズに合わせる）
        {
            component: sliderComponent,
            properties: {
                target: contrastTargetName,
                value: LT.Utilities.PSC_Contrast,
                text: qsTr("PSC_Contrast"),
                source: "qrc:/images/ps_contrast.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: highLightTargetName,
                value: LT.Utilities.PSC_HighLight,
                text: qsTr("PSC_HighLight"),
                source: "qrc:/images/highlight.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: shadowTargetName,
                value: LT.Utilities.PSC_Shadow,
                text: qsTr("PSC_Shadow"),
                source: "qrc:/images/shadow.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: saturationTargetName,
                value: LT.Utilities.PSC_Saturation,
                text: qsTr("PSC_Saturation"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: colorToneTargetName,
                value: LT.Utilities.PSC_ColorTone,
                text: qsTr("PSC_ColorTone"),
                source: "qrc:/images/ps_color2.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: chrPhaseTargetName,
                value: LT.Utilities.PSC_ChromaPhase,
                text: qsTr("PSC_ChromaPhase"),
                source: "qrc:/images/ps_saturation2.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: filterTargetName,
                value: LT.Utilities.PSC_Filter,
                text: qsTr("PSC_Filter"),
                source: "qrc:/images/ps_filter.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: grainTargetName,
                value: LT.Utilities.PSC_Grain,
                text: qsTr("PSC_Grain"),
                source: "qrc:/images/ps_granular.svg"
            }
        },
        //20秋FwUp
        {
            component: popupBtnComponent,
            properties: {
                target: colorNoiseTargetName,
                value: LT.Utilities.PSC_ColorNoise,
                text: qsTr("PSC_Grain_Color"),
                source: "qrc:/images/ps_granular_color.svg"
            }
        },
// MC8259 tsutsumi start  リアルタイムLUT には LUT2はないはず
//        {
//            component: popupBtnComponent,
//            properties: {
//                target: lut2TargetName,
//                value: LT.Utilities.PSC_LUT2,
//                text: "PSC_LUT2",
//                source: "qrc:/images/ps_lut.svg"
//            }
//        },
//        {
//            component: sliderComponentPositive,
//            properties: {
//                target: density2TargetName,
//                value: LT.Utilities.PSC_Density2,
//                text: "PSC_DENSITY2",
//                source: ""
//            }
//        },
// MC8259 tsutsumi end
        {
            component: sliderComponent,
            properties: {
                target: sharpnessTargetName,
                value: LT.Utilities.PSC_Sharpness,
                text: qsTr("PSC_Sharpness"),
                source: "qrc:/images/ps_sharpness.svg"
            }
        },
        {
            component: sliderComponent,
            properties: {
                target: noiseRedTargetName,
                value: LT.Utilities.PSC_NR,
                text: qsTr("PSC_NoiseReduct"),
                source: "qrc:/images/ps_noisereduction.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: kneeModeTargetName,
                value: LT.Utilities.PSC_KneeMode,
                text: qsTr("PSC_KneeMode"),
                source: "qrc:/images/ps_knee.svg"
            }
        },
        // ivc >> start >> No.2
        {
            component: popupBtnComponent,
            properties: {
                target: isoTargetName,
                value: LT.Utilities.PSC_ISO,
                text: qsTr("PSC_ISO"),
                source: "qrc:/images/iso.svg"
            }
        },
        {
            component: popupBtnComponent,
            properties: {
                target: wbTargetName,
                value: LT.Utilities.PSC_WB,
                text: qsTr("PSC_WB"),
                source: "qrc:/images/wb.svg"
            }
        },
        // ivc << end << No.2
        // MC5229
        {
            component: popupBtnComponent,
            properties: {
                target: gainTargetName,
                value: LT.Utilities.PSC_Gain,
                text: qsTr("PSC_GainSetting"),
                source: "qrc:/images/gain.svg"
            }
        },
    ]



    /*!
        Filterを選択する LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var pscFilter: [
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledTextPs",
                optionText: optionTextFormat(qsTr("PF_Off")),
                value: LT.Utilities.PF_Off,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledTextPs",
                optionText: optionTextFormat(qsTr("PF_Yellow")),
                value: LT.Utilities.PF_Yellow,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledTextPs",
                optionText: optionTextFormat(qsTr("PF_Orange")),
                value: LT.Utilities.PF_Orange,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledTextPs",
                optionText: optionTextFormat(qsTr("PF_Red")),
                value: LT.Utilities.PF_Red,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledTextPs",
                optionText: optionTextFormat(qsTr("PF_Green")),
                value: LT.Utilities.PF_Green,
            }
        },
    ]

    /*!
        Grainを選択する LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var pscGrain: [
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledTextPs",
                optionText: optionTextFormat(qsTr("PG_Off")),
                value: LT.Utilities.PG_Off,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledTextPs",
                optionText: optionTextFormat(qsTr("PG_Low")),
                value: LT.Utilities.PG_Low,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledTextPs",
                optionText: optionTextFormat(qsTr("PG_Standard")),
                value: LT.Utilities.PG_Standard,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledTextPs",
                optionText: optionTextFormat(qsTr("PG_High")),
                value: LT.Utilities.PG_High,
            }
        },
    ]

    /*!
        KneeModeを選択する LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var pscKneeMode: [
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledTextPs",
                optionText: optionTextFormat(qsTr("PKM_Off")),
                value: LT.Utilities.PKM_Off,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledTextPs",
                optionText: optionTextFormat(qsTr("PKM_Auto")),
                value: LT.Utilities.PKM_Auto,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledTextPs",
                optionText: optionTextFormat(qsTr("PKM_Manual")),
                value: LT.Utilities.PKM_Manual,
            }
        },
    ]

    // ivc >> start >> No.2
    /*!
        ホワイトバランスを選択する LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var pscWB: [
        {
            component: optionWithImageButtonComponentWB,
            properties: {
                type: "optionWithImage",
                optionText: optionTextFormat(qsTr("WB_Auto")),
                value: LT.Utilities.WB_Auto,
                source: "qrc:/images/189_wb_awb.svg",
            }
        },
        {
            component: optionWithImageButtonComponentWB,
            properties: {
                type: "optionWithImage",
                optionText: optionTextFormat(qsTr("WB_Auto_Cool")),
                value: LT.Utilities.WB_Auto_Cool,
                source: "qrc:/images/190_wb_awbc.svg",
            }
        },
        {
            component: optionWithImageButtonComponentWB,
            properties: {
                type: "optionWithImage",
                optionText: optionTextFormat(qsTr("WB_Auto_Warm")),
                value: LT.Utilities.WB_Auto_Warm,
                // ivc >> start >> USBTHRV140-41
                //source: "qrc:/images/button_placeholder.svg",
                source: "qrc:/images/awbw.svg",
                // ivc << end << USBTHRV140-41
            }
        },
        {
            component: optionWithImageButtonComponentWB,
            properties: {
                type: "optionWithImage",
                optionText: optionTextFormat(qsTr("WB_Daylight")),
                value: LT.Utilities.WB_Daylight,
                source: "qrc:/images/191_wb_sunny.svg",
            }
        },
        {
            component: optionWithImageButtonComponentWB,
            properties: {
                type: "optionWithImage",
                optionText: optionTextFormat(qsTr("WB_Cloud")),
                value: LT.Utilities.WB_Cloud,
                source: "qrc:/images/192_wb_cloudy.svg",
            }
        },
        {
            component: optionWithImageButtonComponentWB,
            properties: {
                type: "optionWithImage",
                optionText: optionTextFormat(qsTr("WB_Shade")),
                value: LT.Utilities.WB_Shade,
                source: "qrc:/images/193_wb_shadow.svg",
            }
        },
        {
            component: optionWithImageButtonComponentWB,
            properties: {
                type: "optionWithImage",
                optionText: optionTextFormat(qsTr("WB_Tengsten")),
                value: LT.Utilities.WB_Tengsten,
                source: "qrc:/images/194_wb_light.svg",
            }
        },
        {
            component: optionWithImageButtonComponentWB,
            properties: {
                type: "optionWithImage",
                optionText: optionTextFormat(qsTr("WB_Flash")),
                value: LT.Utilities.WB_Flash,
                source: "qrc:/images/195_wb_flash.svg",
            }
        },
        {
            component: optionWithImageButtonComponentWB,
            properties: {
                type: "optionWithImage",
                optionText: optionTextFormat(qsTr("WB_Keep")),
                value: LT.Utilities.WB_Keep,
                source: "qrc:/images/196_wb_wb1.svg",
            }
        },
        {
            component: optionWithImageButtonComponentWB,
            properties: {
                type: "optionWithImage",
                optionText: optionTextFormat(qsTr("WB_Keep2")),
                value: LT.Utilities.WB_Keep2,
                source: "qrc:/images/197_wb_wb2.svg",
            }
        },
        {
            component: optionWithImageButtonComponentWB,
            properties: {
                type: "optionWithImage",
                optionText: optionTextFormat(qsTr("WB_Keep3")),
                value: LT.Utilities.WB_Keep3,
                source: "qrc:/images/198_wb_wb3.svg",
            }
        },
        {
            component: optionWithImageButtonComponentWB,
            properties: {
                type: "optionWithImage",
                optionText: optionTextFormat(qsTr("WB_Keep4")),
                value: LT.Utilities.WB_Keep4,
                source: "qrc:/images/199_wb_wb4.svg",
            }
        },
        {
            component: optionWithImageButtonComponentWB,
            properties: {
                type: "optionWithImage",
                optionText: optionTextFormat(qsTr("WB_K_Set")),
                value: LT.Utilities.WB_K_Set,
                source: "qrc:/images/200_wb_k1.svg",
            }
        },
        {
            component: optionWithImageButtonComponentWB,
            properties: {
                type: "optionWithImage",
                optionText: optionTextFormat(qsTr("WB_K_Set2")),
                value: LT.Utilities.WB_K_Set2,
                source: "qrc:/images/201_wb_k2.svg",
            }
        },
        {
            component: optionWithImageButtonComponentWB,
            properties: {
                type: "optionWithImage",
                optionText: optionTextFormat(qsTr("WB_K_Set3")),
                value: LT.Utilities.WB_K_Set3,
                source: "qrc:/images/202_wb_k3.svg",
            }
        },
        {
            component: optionWithImageButtonComponentWB,
            properties: {
                type: "optionWithImage",
                optionText: optionTextFormat(qsTr("WB_K_Set4")),
                value: LT.Utilities.WB_K_Set4,
                source: "qrc:/images/203_wb_k4.svg",
            }
        },
    ]
    // ivc << end << No.2
    // IVC >> Ver.1.7 >> start >> No.2
    /*!
        DualISOを選択する LTOptionButtonPopup に表示するコンポーネントの組です
     */
    readonly property var pscDualISO: [
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledTextPs",
                optionText: optionTextFormat(qsTr("PD_Auto")),
                value: LT.Utilities.PD_Auto,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledTextPs",
                optionText: optionTextFormat(qsTr("PD_Low")),
                value: LT.Utilities.PD_Low,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledTextPs",
                optionText: optionTextFormat(qsTr("PD_High")),
                value: LT.Utilities.PD_High,
            }
        },
    ]
    // IVC << Ver.1.7 << end << No.2

    readonly property var pscColorNoise: [
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledTextPs",
                optionText: optionTextFormat(qsTranslate("LTOptionComponentsProvider", "OFF")),
                value: LT.Utilities.PCN_OFF,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledTextPs",
                optionText: optionTextFormat(qsTranslate("LTOptionComponentsProvider", "ON")),
                value: LT.Utilities.PCN_ON,
            }
        },
    ]

    readonly property var pscLUT: [
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledTextPs",
                optionText: optionTextFormat(qsTranslate("LTOptionComponentsProvider", "OFF")),
                value: LT.Utilities.PLUT_OFF,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledTextPs",
                optionText: optionTextFormat(qsTranslate("LTOptionComponentsProvider", "ON")),
                value: LT.Utilities.PLUT_ON,
            }
        },
    ]

    readonly property var pscLUT2: [
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledTextPs",
                optionText: optionTextFormat(qsTranslate("LTOptionComponentsProvider", "OFF")),
                value: LT.Utilities.PLUT_OFF,
            }
        },
        {
            component: optionWithStyledTextButtonComponent,
            properties: {
                type: "optionWithStyledTextPs",
                optionText: optionTextFormat(qsTranslate("LTOptionComponentsProvider", "ON")),
                value: LT.Utilities.PLUT_ON,
            }
        },
    ]

    /*!
        Component for slider component
     */
    readonly property Component sliderComponent: Component {
        Item {
            objectName: sliderComponentName
            width: 400 //350 //323 //400
            height: 77
            property alias target: slider.target
            property var value
            property alias text: lblTitle.text
            property alias source: lblImg.source

            Rectangle {
                id: background
                anchors.fill: parent
                color: "#07090d"
            }

            Image {
                id: lblImg
                objectName: lblImgName

                x: lblTitle.x
                y: lblTitle.height + lblTitle.x/2
                height: parent.height - lblTitle.height - lblTitle.x
                width: lblImg.height
                fillMode: Image.PreserveAspectFit

                source: "qrc:/images/button_placeholder.svg"
            }

            LTFlashSlider {
                id: slider
                objectName: sliderName

                x: lblImg.width + lblTitle.x*2
                y: 0
                height: parent.height
                width: parent.width - slider.x

                type: slider_type_free
                texttype: slider_texttype_decimals  // 2019/01/07 Panasonic Nakano
                windowType: slider_window_photoStyle
                curIndex: 6 // set to reduce animation
                // ivc >> start >> No.2
                modelNum: (maxVal - minVal) + 1
                // ivc << end << No.2
                txtSliderValTopMargin: 10
            }

            LTStylishText {
                id: lblTitle
                objectName: lblTitleName

                x: 12
                y: 0
                height: 30
                width: parent.width
            }
        }
    }

    /*!
        Component for slider component 正数
     */
    readonly property Component sliderComponentPositive: Component {
        Item {
            objectName: sliderComponentPositiveName
            width: 400 //350 //323 //400
            height: 77
            property alias target: slider.target
            property var value
            property alias text: lblTitle.text
            property alias source: lblImg.source

            Rectangle {
                id: background
                anchors.fill: parent
                color: "#07090d"
            }

            Image {
                id: lblImg
                objectName: lblImgName

                x: lblTitle.x
                y: lblTitle.height + lblTitle.x/2
                height: parent.height - lblTitle.height - lblTitle.x
                width: lblImg.height
                fillMode: Image.PreserveAspectFit

                source: "qrc:/images/button_placeholder.svg"
            }

            LTFlashSlider {
                id: slider
                objectName: sliderName

                x: lblImg.width + lblTitle.x*2
                y: 0
                height: parent.height
                width: parent.width - slider.x

                type: slider_type_free
                texttype: slider_texttype_positive
                windowType: slider_window_photoStyle
                curIndex: 6 // set to reduce animation
                // ivc >> start >> No.2
                modelNum: (maxVal - minVal) + 1
                // ivc << end << No.2
                txtSliderValTopMargin: 10
            }

            LTStylishText {
                id: lblTitle
                objectName: lblTitleName

                x: 12
                y: 0
                height: 30
                width: parent.width
            }
        }
    }


    /*!
        Component for popup button component
     */
    readonly property Component popupBtnComponent: Component {
        Item {
            id: itemName
            objectName: popupBtnComponentName
            width: 400//350 //323 //400
            height: 77
            property alias target: btnOption.target
            property var value
            property alias text: lblTitle.text
            property alias source: lblImg.source

            Rectangle {
                id: background
                anchors.fill: parent
                color: "#07090d"
            }

            Image {
                id: lblImg
                objectName: lblImgName

                x: lblTitle.x
                y: lblTitle.height + lblTitle.x/2
                height: parent.height - lblTitle.height - lblTitle.x
                width: lblImg.height
                fillMode: Image.PreserveAspectFit
                source: "qrc:/images/button_placeholder.svg"
            }

            LTOptionButton {
                id: btnOption
                objectName: btnOptionName
                // ivc >> start >> Update for Base Photo Style
                //x: lblImg.width + lblTitle.x*2
                x: (target==basePhotoStyleTargetName || target==basePhotoStyle2TargetName)? 0 : lblImg.width + lblTitle.x*2
                // ivc << end << Update for Base Photo Style
                y: lblTitle.height
                height: parent.height - btnOption.y
                width: parent.width - btnOption.x
                // nakhuong >> start >> No.2
                //type: "optionWithRichTextPs"
                // ivc >> start >> USBTHRV140-13
                //target=="pscISO"? "optionWithTextRealPs":"optionWithRichTextPs"
                type: {
                    if(target == isoTargetName || target == gainTargetName) {
                        //return "optionWithTextRealPs"
                        return "optionWithStyledTextRealPs"
                    } else if(target == basePhotoStyleTargetName || target == basePhotoStyle2TargetName) {
                        return "optionWithImageAndText"
                    } else {
                        //return "optionWithRichTextPs"
                        return "optionWithStyledTextPs"
                    }
                }
                // ivc << end << USBTHRV140-13
                // nakhuong << end << No.2

                // ivc >> start >> No.2
                onReleased: {
                    popupY = savePopupY
                    popupY = popupY - updatePopup

                    if (target === basePhotoStyleTargetName || target === basePhotoStyle2TargetName)
                    {
                        // ivc >> start >> Support Multi-Language
                        //btnOption.popupX = btnOption.x + (width - 170)/2
                        btnOption.popupX = btnOption.x + (width - 340)/2
                        // ivc << end << Support Multi-Language
                    }
                }
                // ivc << end << No.2
            }

            LTStylishText {
                id: lblTitle
                objectName: lblTitleName

                x: 12
                y: 0
                height: 30
                width: parent.width

                text: qsTr("Contrast Contrast")
            }
        }
    }

    // nakhuong >> start >> No.2
    /*!
        矩形のボタンを動的に生成するコンポーネントです 画像-White balance
     */
    readonly property Component optionWithImageButtonComponentWB: Component {
        LTRectangleButton {
            width: 107
            height: 77
            type: "optionWithImage"
            property bool capable: false
        }
    }

    /*!
        矩形のボタンを動的に生成するコンポーネントです 画像-Base Photo Style
     */
    readonly property Component optionWithRichTextButtonComponentPS: Component {
        LTRectangleButton {
            width: 170
            height: 36
            type: "optionWithRichTextPs"
            property bool capable: false
        }
    }
    // nakhuong << end << No.2

    /*!
        矩形のボタンを動的に生成するコンポーネントです 画像
     */
    readonly property Component optionWithImageButtonComponent: Component {
        LTRectangleButton {
            // ivc >> start >> Support Multi-Language
            //width: 220 //214 // 285
            width: 360
            // ivc << end << Support Multi-Language
            height: 36
            type: "optionWithImageAndText"
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
            type: "optionWithRichTextPs"
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
            type: "optionWithStyledTextPs"
            property bool capable: false
        }
    }

    function optionTextFormat(val) {
        return val
//        var str = '<b><big>' + val + '</big></b>';

//        return str;
    }
}
