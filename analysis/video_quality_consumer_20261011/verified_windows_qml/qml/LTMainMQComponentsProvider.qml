import QtQuick 2.6

import "qrc:/qml"
import LT 1.0 as LT

/*! \qmltype LTMainMQComponentsProvider
    \inqmlmodule LT

    \brief
    LTMainMovieQualityPopup,LTMainMovieQualityFilterDetailPopup,LTMainMovieQualityFilterPopup に表示するコンポーネントの組を提供するオブジェクトです
 */
QtObject {
    // object names
    readonly property string optionDetailWithImageButtonComponentName:   "optionDetailWithImageButtonComponent"

    // Movie Quality components
    readonly property string recMovieCompName:              "recMovie"
// IVC >> del >> start >> USBTHRV160-26
//    readonly property string recMovieDetailCompName:        "recMovieDetail"
// IVC << del << end << USBTHRV160-26
    readonly property string recMovieBuiltInCompName:       "recMovieBuiltIn"

    // Movie Filter components
    readonly property string movieFrameRateCompName:        "movieFrameRate"
    readonly property string moviePixelCompName:            "moviePixel"
    readonly property string movieCompressMethodCompName:   "movieCompressMethod"
    readonly property string movieBitRateCompName:          "movieBitRate"
    readonly property string movieVFRFixedCompName:         "movieVFRFixed"
    readonly property string movieVFRCompName:              "movieVFR"
    readonly property string movieHLGFixedCompName:         "movieHLGFixed"
    readonly property string movieHLGCompName:              "movieHLG"
    // IVC >> Ver.1.8 >> start >> No.3
    readonly property string movieSQCompName:               "movieSQ"
    // IVC << Ver.1.8 << end << No.3

// IVC >> mod >> start >> USBTHRV160-26
//    // Compression Method
//    readonly property int compMethod_422_10bit_All_I:       0x1100	// 422 10bit All-I
//    readonly property int compMethod_422_8bit_All_I:        0x1000  // 422 8bit All-I
//    readonly property int compMethod_422_10bit_LongGOP:     0x1110	// 422 10bit Long-GOP
//    readonly property int compMethod_420_10bit_LongGOP:     0x0110	// 420 10bit Long-GOP
//    readonly property int compMethod_420_8bit_LongGOP:      0x0010	// 420 8bit Long-GOP

//    /*!
//        動画画質方式を選択する LTMainWindow,LTMainMovieQualityPopup に表示するコンポーネントの組です
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
//                source: "qrc:/images/rec_mov_4k_72m_30p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_HEVC_NTSC_3840_2160_24p_72m,
//                optionText: qsTr("RCMV_MP4_HEVC_NTSC_3840_2160_24p_72m"),
//                source: "qrc:/images/rec_mov_4k_72m_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_HEVC_PAL_3840_2160_25p_72m,
//                optionText: qsTr("RCMV_MP4_HEVC_PAL_3840_2160_25p_72m"),
//                source: "qrc:/images/rec_mov_4k_72m_25p.svg",
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
//                source: "qrc:/images/rec_mov_4k-a_400_10_30p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_3840_2160_30p_10b_150m_amamo,
//                optionText: qsTr("RCMV_MP4_LPCM_NTSC_3840_2160_30p_10b_150m_amamo"),
//                source: "qrc:/images/rec_mov_4k-a_150_10_30p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_3840_2160_30p_8b_100m_amamo,
//                optionText: qsTr("RCMV_MP4_LPCM_NTSC_3840_2160_30p_8b_100m_amamo"),
//                source: "qrc:/images/rec_mov_4k-a_100_8_30p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_3840_2160_24p_10b_400m_amamo,
//                optionText: qsTr("RCMV_MP4_LPCM_NTSC_3840_2160_24p_10b_400m_amamo"),
//                source: "qrc:/images/rec_mov_4k-a_400_10_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_3840_2160_24p_10b_150m_amamo,
//                optionText: qsTr("RCMV_MP4_LPCM_NTSC_3840_2160_24p_10b_150m_amamo"),
//                source: "qrc:/images/rec_mov_4k-a_150_10_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_3840_2160_24p_8b_100m_amamo,
//                optionText: qsTr("RCMV_MP4_LPCM_NTSC_3840_2160_24p_8b_100m_amamo"),
//                source: "qrc:/images/rec_mov_4k-a_100_8_24p.svg",
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
//                source: "qrc:/images/rec_mov_4k-a_150_8_50p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_PAL_3840_2160_25p_10b_400m_amamo,
//                optionText: qsTr("RCMV_MP4_LPCM_PAL_3840_2160_25p_10b_400m_amamo"),
//                source: "qrc:/images/rec_mov_4k-a_400_10_25p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_PAL_3840_2160_25p_10b_150m_amamo,
//                optionText: qsTr("RCMV_MP4_LPCM_PAL_3840_2160_25p_10b_150m_amamo"),
//                source: "qrc:/images/rec_mov_4k-a_150_10_25p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_PAL_3840_2160_25p_8b_100m_amamo,
//                optionText: qsTr("RCMV_MP4_LPCM_PAL_3840_2160_25p_8b_100m_amamo"),
//                source: "qrc:/images/rec_mov_4k-a_100_8_25p.svg",
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
//                source: "qrc:/images/rec_mov_4k-a_400_10_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_CINEMA_3840_2160_24p_10b_150m_amamo,
//                optionText: qsTr("RCMV_MP4_LPCM_CINEMA_3840_2160_24p_10b_150m_amamo"),
//                source: "qrc:/images/rec_mov_4k-a_150_10_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_CINEMA_3840_2160_24p_8b_100m_amamo,
//                optionText: qsTr("RCMV_MP4_LPCM_CINEMA_3840_2160_24p_8b_100m_amamo"),
//                source: "qrc:/images/rec_mov_4k-a_100_8_24p.svg",
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
//                source: "qrc:/images/rec_mov_4k-a_400_10_30p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_3840_2160_30p_10b_150m_amamo,
//                optionText: qsTr("RCMV_MOV_NTSC_3840_2160_30p_10b_150m_amamo"),
//                source: "qrc:/images/rec_mov_4k-a_150_10_30p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_3840_2160_30p_8b_100m_amamo,
//                optionText: qsTr("RCMV_MOV_NTSC_3840_2160_30p_8b_100m_amamo"),
//                source: "qrc:/images/rec_mov_4k-a_100_8_30p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_3840_2160_24p_10b_400m_amamo,
//                optionText: qsTr("RCMV_MOV_NTSC_3840_2160_24p_10b_400m_amamo"),
//                source: "qrc:/images/rec_mov_4k-a_400_10_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_3840_2160_24p_10b_150m_amamo,
//                optionText: qsTr("RCMV_MOV_NTSC_3840_2160_24p_10b_150m_amamo"),
//                source: "qrc:/images/rec_mov_4k-a_150_10_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_3840_2160_24p_8b_100m_amamo,
//                optionText: qsTr("RCMV_MOV_NTSC_3840_2160_24p_8b_100m_amamo"),
//                source: "qrc:/images/rec_mov_4k-a_100_8_24p.svg",
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
//                source: "qrc:/images/rec_mov_4k-a_150_8_50p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_3840_2160_25p_10b_400m_amamo,
//                optionText: qsTr("RCMV_MOV_PAL_3840_2160_25p_10b_400m_amamo"),
//                source: "qrc:/images/rec_mov_4k-a_400_10_25p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_3840_2160_25p_8b_150m_amamo,
//                optionText: qsTr("RCMV_MOV_PAL_3840_2160_25p_8b_150m_amamo"),
//                source: "qrc:/images/rec_mov_4k-a_150_10_25p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_3840_2160_25p_8b_100m_amamo,
//                optionText: qsTr("RCMV_MOV_PAL_3840_2160_25p_8b_100m_amamo"),
//                source: "qrc:/images/rec_mov_4k-a_100_8_25p.svg",
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
//                source: "qrc:/images/rec_mov_4k-a_400_10_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_CINEMA_3840_2160_24p_10b_150m_amamo,
//                optionText: qsTr("RCMV_MOV_CINEMA_3840_2160_24p_10b_150m_amamo"),
//                source: "qrc:/images/rec_mov_4k-a_150_10_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_CINEMA_3840_2160_24p_8b_100m_amamo,
//                optionText: qsTr("RCMV_MOV_CINEMA_3840_2160_24p_8b_100m_amamo"),
//                source: "qrc:/images/rec_mov_4k-a_100_8_24p.svg",
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
//        {
//            component: optionWithImageButtonComponent,               //366
//            properties: {
//                value: LT.Utilities.RCMV_MP4_HEVC_PAL_3840_2160_30p_72m,
//                optionText: qsTr("RCMV_MP4_HEVC_PAL_3840_2160_30P_72m"),
//                source: "qrc:/images/rec_mov_4k_72m_30p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,               //367
//            properties: {
//                value: LT.Utilities.RCMV_MP4_HEVC_PAL_3840_2160_24p_72m,
//                optionText: qsTr("RCMV_MP4_HEVC_PAL_3840_2160_24P_72m"),
//                source: "qrc:/images/rec_mov_4k_72m_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,               //371-NTSC
//            properties: {
//                value: LT.Utilities.RCMV_MP4_NTSC_4096_2160_60p_150m,
//                optionText: qsTr("RCMV_MP4_NTSC_4096_2160_60P_150m"),
//                source: "qrc:/images/rec_mov_c4k_150m_8bit_60p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,               //371
//            properties: {
//                value: LT.Utilities.RCMV_MP4_PAL_4096_2160_50p_150m,
//                optionText: qsTr("RCMV_MP4_PAL_4096_2160_50P_150m"),
//                source: "qrc:/images/rec_mov_c4k_150m_8bit_50p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,               //372-NTSC
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_4096_2160_30p_8b_100m,
//                optionText: qsTr("RCMV_MP4_LPCM_NTSC_4096_2160_30p_8b_100m"),
//                source: "qrc:/images/rec_mov_c4k_100m_8bit_30p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,               //372
//            properties: {
//                value: LT.Utilities.RCMV_MP4_PAL_4096_2160_25p_100m,
//                optionText: qsTr("RCMV_MP4_PAL_4096_2160_25P_100m"),
//                source: "qrc:/images/rec_mov_c4k_100m_8bit_25p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,               //373-NTSC
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_4096_2160_30p_10b_100m,
//                optionText: qsTr("RCMV_MP4_LPCM_NTSC_4096_2160_30p_10b_100m"),
//                source: "qrc:/images/rec_mov_c4k_150m_10bit_30p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,               //373
//            properties: {
//                value: LT.Utilities.RCMV_MP4_PAL_4096_2160_25p_150m,
//                optionText: qsTr("RCMV_MP4_PAL_4096_2160_25p_150m"),
//                source: "qrc:/images/rec_mov_c4k_150m_10bit_25p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,               //378
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_4096_2160_25p_10b_400m,
//                optionText: qsTr("RCMV_MOV_PAL_4096_2160_25p_10b_400m"),
//                source: "qrc:/images/rec_mov_c4k_400_10_25p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,               //378-NTSC
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_4096_2160_30p_10b_400m,
//                optionText: qsTr("RCMV_MOV_NTSC_4096_2160_30p_10b_400m"),
//                source: "qrc:/images/rec_mov_c4k_400_10_30p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,               //379-NTSC
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_4096_2160_60p_8b_150m,
//                optionText: qsTr("RCMV_MOV_NTSC_4096_2160_60p_8b_150m"),
//                source: "qrc:/images/rec_mov_c4k_150m_8bit_60p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,               //379
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_4096_2160_50p_150m,
//                optionText: qsTr("RCMV_MOV_PAL_4096_2160_50p_150m"),
//                source: "qrc:/images/rec_mov_c4k_150m_8bit_50p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,               //380-NTSC
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_4096_2160_30p_8b_100m,
//                optionText: qsTr("RCMV_MOV_NTSC_4096_2160_30p_8b_100m"),
//                source: "qrc:/images/rec_mov_c4k_100m_8bit_30p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,               //380
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_4096_2160_25p_100m,
//                optionText: qsTr("RCMV_MOV_PAL_4096_2160_25p_100m"),
//                source: "qrc:/images/rec_mov_c4k_100m_8bit_25p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,               //381-NTSC
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_4096_2160_30p_10b_150m,
//                optionText: qsTr("RCMV_MOV_NTSC_4096_2160_30p_10b_150m"),
//                source: "qrc:/images/rec_mov_c4k_150m_10bit_30p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,               //381
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_4096_2160_25p_150m,
//                optionText: qsTr("RCMV_MOV_PAL_4096_2160_25p_150m"),
//                source: "qrc:/images/rec_mov_c4k_150m_10bit_25p.svg",
//                type: "optionWithImage"
//            }
//        },
//        // 2019/06/05 ADD(402-461)
//        {
//            component: optionWithImageButtonComponent,               //402
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_4096_2160_60p_10b_200m,
//                optionText: qsTr("RCMV_MOV_NTSC_4096_2160_60p_10b_200m"),
//                source: "qrc:/images/rec_mov_c4k_200_10_60p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,               //403
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_4096_2160_50_00p_10b_200m,
//                optionText: qsTr("RCMV_MOV_PAL_4096_2160_50_00p_10b_200m"),
//                source: "qrc:/images/rec_mov_c4k_200_10_50p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,               //404
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_4096_2160_47_95p_10b_200m,
//                optionText: qsTr("RCMV_MOV_NTSC_4096_2160_47_95p_10b_200m"),
//                source: "qrc:/images/rec_mov_c4k_200_10_48p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,               //405
//            properties: {
//                value: LT.Utilities.RCMV_MOV_CINEMA_4096_2160_48_00p_10b_200m,
//                optionText: qsTr("RCMV_MOV_CINEMA_4096_2160_48_00p_10b_200m"),
//                source: "qrc:/images/rec_mov_c4k_200_10_48p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,               //406
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_3840_2160_59_94p_10b_200m,
//                optionText: qsTr("RCMV_MOV_PAL_3840_2160_59_94p_10b_200m"),
//                source: "qrc:/images/rec_mov_4k_200_10_60p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,               //407
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_3840_2160_50_00p_10b_200m,
//                optionText: qsTr("RCMV_MOV_PAL_3840_2160_50_00p_10b_200m"),
//                source: "qrc:/images/rec_mov_4k_200_10_50p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,               //408
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_3840_2160_47_95p_10b_200m,
//                optionText: qsTr("RCMV_MOV_NTSC_3840_2160_47_95p_10b_200m"),
//                source: "qrc:/images/rec_mov_4k_200_10_48p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,               //409
//            properties: {
//                value: LT.Utilities.RCMV_MOV_CINEMA_3840_2160_48_00p_10b_200m,
//                optionText: qsTr("RCMV_MOV_CINEMA_3840_2160_48_00p_10b_200m"),
//                source: "qrc:/images/rec_mov_4k_200_10_48p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,               //411
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_3328_2496_50_00p_10b_200m,
//                optionText: qsTr("RCMV_MOV_PAL_3328_2496_50_00p_10b_200m"),
//                source: "qrc:/images/rec_mov_4k-a_200_10_50p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,               //412
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_3328_2496_47_95p_10b_200m,
//                optionText: qsTr("RCMV_MOV_NTSC_3328_2496_47_95p_10b_200m"),
//                source: "qrc:/images/rec_mov_4k-a_200_10_48p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,               //413
//            properties: {
//                value: LT.Utilities.RCMV_MOV_CINEMA_3328_2496_48_00p_10b_200m,
//                optionText: qsTr("RCMV_MOV_CINEMA_3328_2496_48_00p_10b_200m"),
//                source: "qrc:/images/rec_mov_4k-a_200_10_48p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,               //414
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_1920_1080_59_94i_10b_100m,
//                optionText: qsTr("RCMV_MOV_NTSC_1920_1080_59_94i_10b_100m"),
//                source: "qrc:/images/rec_mov_fhd_100_10_60i.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,               //415
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_1920_1080_59_94i_10b_50m,
//                optionText: qsTr("RCMV_MOV_NTSC_1920_1080_59_94i_10b_50m"),
//                source: "qrc:/images/rec_mov_fhd_50_10_60i.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,               //416
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_1920_1080_50_00i_10b_100m,
//                optionText: qsTr("RCMV_MOV_PAL_1920_1080_50_00i_10b_100m"),
//                source: "qrc:/images/rec_mov_fhd_100_10_50i.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,               //417
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_1920_1080_50_00i_10b_50m,
//                optionText: qsTr("RCMV_MOV_PAL_1920_1080_50_00i_10b_50m"),
//                source: "qrc:/images/rec_mov_fhd_50_10_50i.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,               //418
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_1920_1080_119_88p_10b_150m,
//                optionText: qsTr("RCMV_MOV_NTSC_1920_1080_119_88p_10b_150m"),
//                source: "qrc:/images/rec_mov_fhd_150_10_120p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,               //419
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_1920_1080_100_00p_10b_150m,
//                optionText: qsTr("RCMV_MOV_PAL_1920_1080_100_00p_10b_150m"),
//                source: "qrc:/images/rec_mov_fhd_150_10_100p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,               //420
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_1920_1080_47_95p_10b_100m,
//                optionText: qsTr("RCMV_MOV_NTSC_1920_1080_47_95p_10b_100m"),
//                source: "qrc:/images/rec_mov_fhd_100_10_48p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,               //421
//            properties: {
//                value: LT.Utilities.RCMV_MOV_CINEMA_1920_1080_48_00p_10b_100m,
//                optionText: qsTr("RCMV_MOV_CINEMA_1920_1080_48_00p_10b_100m"),
//                source: "qrc:/images/rec_mov_fhd_100_10_48p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,               //422
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_5952_3968_23_98p_10b_200m,
//                optionText: qsTr("RCMV_MOV_NTSC_5952_3968_23_98p_10b_200m"),
//                source: "qrc:/images/rec_mov_6k_200_10_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,               //423
//            properties: {
//                value: LT.Utilities.RCMV_MOV_CINEMA_5952_3968_24_00p_10b_200m,
//                optionText: qsTr("RCMV_MOV_CINEMA_5952_3968_24_00p_10b_200m"),
//                source: "qrc:/images/rec_mov_6k_200_10_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,               //424
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_5376_3584_25_00p_10b_200m,
//                optionText: qsTr("RCMV_MOV_PAL_5376_3584_25_00p_10b_200m"),
//                source: "qrc:/images/rec_mov_54k_200_10_25p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,               //425
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_5376_3584_29_97p_10b_200m,
//                optionText: qsTr("RCMV_MOV_NTSC_5376_3584_29_97p_10b_200m"),
//                source: "qrc:/images/rec_mov_54k_200_10_30p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,               //426
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_5888_3312_23_98p_10b_200m,
//                optionText: qsTr("RCMV_MOV_NTSC_5888_3312_23_98p_10b_200m"),
//                source: "qrc:/images/rec_mov_59k_200_10_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,               //427
//            properties: {
//                value: LT.Utilities.RCMV_MOV_CINEMA_5888_3312_24_00p_10b_200m,
//                optionText: qsTr("RCMV_MOV_CINEMA_5888_3312_24_00p_10b_200m"),
//                source: "qrc:/images/rec_mov_59k_200_10_24p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,               //428
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_5888_3312_25_00p_10b_200m,
//                optionText: qsTr("RCMV_MOV_PAL_5888_3312_25_00p_10b_200m"),
//                source: "qrc:/images/rec_mov_59k_200_10_25p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,               //429
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_5888_3312_29_97p_10b_200m,
//                optionText: qsTr("RCMV_MOV_NTSC_5888_3312_29_97p_10b_200m"),
//                source: "qrc:/images/rec_mov_59k_200_10_30p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,               //430
//            properties: {
//                value: LT.Utilities.RCMV_MP4_NTSC_3840_2160_59_94p_10b_100m,
//                optionText: qsTr("RCMV_MP4_NTSC_3840_2160_59_94p_10b_100m"),
//                source: "qrc:/images/rec_mov_4k_100_10_60p.svg",
//                type: "optionWithImage"
//            }
//        },
//        {
//            component: optionWithImageButtonComponent,               //431
//            properties: {
//                value: LT.Utilities.RCMV_MP4_PAL_3840_2160_50_00p_10b_100m,
//                optionText: qsTr("RCMV_MP4_PAL_3840_2160_50_00p_10b_100m"),
//                source: "qrc:/images/rec_mov_4k_100_10_50p.svg",
//                type: "optionWithImage"
//            }
//        },
//    ]

//    /*!
//        動画画質方式を選択する LTMainMovieQualityPopup に表示するコンポーネントの組です
//     */
//    readonly property var recMovieDetail: [
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_AVCHD_NTSC_1920_1080_60p_28m,
//                optionImage: "qrc:/images/249_rec_mov_fhd_28m_60p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_AVCHD_NTSC_1920_1080_60i_17m,
//                optionImage: "qrc:/images/250_rec_mov_fhd_17m_60i.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_AVCHD_NTSC_1920_1080_30p_24m,
//                optionImage: "qrc:/images/251_rec_mov_fhd_24m_30p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_AVCHD_NTSC_1920_1080_24p_24m,
//                optionImage: "qrc:/images/252_rec_mov_fhd_24m_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_AVCHD_PAL_1920_1080_50p_28m,
//                optionImage: "qrc:/images/253_rec_mov_fhd_28m_50p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_AVCHD_PAL_1920_1080_50i_17m,
//                optionImage: "qrc:/images/254_rec_mov_fhd_17m_50i.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_AVCHD_PAL_1920_1080_25p_24m,
//                optionImage: "qrc:/images/255_rec_mov_fhd_24m_25p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_AVCHD_PAL_1920_1080_24p_24m,
//                optionImage: "qrc:/images/252_rec_mov_fhd_24m_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_NTSC_3840_2160_30p_100m,
//                optionImage: "qrc:/images/256_rec_mov_4k_100m_30p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_NTSC_3840_2160_24p_100m,
//                optionImage: "qrc:/images/257_rec_mov_4k_100m_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_NTSC_1920_1080_60p_28m,
//                optionImage: "qrc:/images/258_rec_mov_fhd_28m_60p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_NTSC_1920_1080_30p_20m,
//                optionImage: "qrc:/images/259_rec_mov_fhd_20m_30p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_NTSC_1920_1080_24p_24m,
//                optionImage: "qrc:/images/260_rec_mov_fhd_24m_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_PAL_3840_2160_60p_150m,
//                optionImage: "qrc:/images/291_rec_mov_4k_150m_8bit_50p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_PAL_3840_2160_50p_150m,
//                optionImage: "qrc:/images/291_rec_mov_4k_150m_8bit_50p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_PAL_3840_2160_30p_100m,
//                optionImage: "qrc:/images/256_rec_mov_4k_100m_30p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_PAL_3840_2160_25p_100m,
//                optionImage: "qrc:/images/261_rec_mov_4k_100m_25p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_PAL_3840_2160_24p_100m,
//                optionImage: "qrc:/images/257_rec_mov_4k_100m_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_PAL_1920_1080_60p_28m,
//                optionImage: "qrc:/images/258_rec_mov_fhd_28m_60p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_PAL_1920_1080_50p_28m,
//                optionImage: "qrc:/images/262_rec_mov_fhd_28m_50p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_PAL_1920_1080_30p_20m,
//                optionImage: "qrc:/images/259_rec_mov_fhd_20m_30p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_PAL_1920_1080_25p_20m,
//                optionImage: "qrc:/images/263_rec_mov_fhd_20m_25p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_CINEMA_1920_1080_24p_24m,
//                optionImage: "qrc:/images/264_rec_mov_fhd_24m_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_HEVC_NTSC_3840_2160_30p_72m,
//                optionImage: "qrc:/images/rec_mov_4k_72m_30p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_HEVC_NTSC_3840_2160_24p_72m,
//                optionImage: "qrc:/images/rec_mov_4k_72m_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_HEVC_PAL_3840_2160_25p_72m,
//                optionImage: "qrc:/images/rec_mov_4k_72m_25p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_4096_2160_24p_10b_400m,
//                optionImage: "qrc:/images/265_rec_mov_c4k_400m_i_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_4096_2160_24p_10b_150m,
//                optionImage: "qrc:/images/266_rec_mov_c4k_150m_10bit_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_4096_2160_24p_8b_100m,
//                optionImage: "qrc:/images/267_rec_mov_c4k_100m_8bit_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_3840_2160_60p_8b_150m,
//                optionImage: "qrc:/images/268_rec_mov_4k_150m_8bit_60p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_3840_2160_30p_10b_400m,
//                optionImage: "qrc:/images/269_rec_mov_4k_400m_i_30p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_3840_2160_30p_10b_150m,
//                optionImage: "qrc:/images/270_rec_mov_4k_150m_10bit_30p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_3840_2160_30p_8b_100m,
//                optionImage: "qrc:/images/271_rec_mov_4k_100m_8bit_30p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_3840_2160_24p_10b_400m,
//                optionImage: "qrc:/images/272_rec_mov_4k_400m_i_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_3840_2160_24p_10b_150m,
//                optionImage: "qrc:/images/273_rec_mov_4k_150m_10bit_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_3840_2160_24p_8b_100m,
//                optionImage: "qrc:/images/274_rec_mov_4k_100m_8bit_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_4992_3744_30p_10b_200m_amamo,
//                optionImage: "qrc:/images/554_rec_mov_6k_200m_a_30p-01.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_4992_3744_23p_10b_200m_amamo,
//                optionImage: "qrc:/images/552_rec_mov_6k_200m_a_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_3840_2160_60p_8b_150m_amamo,
//                optionImage: "qrc:/images/275_rec_mov_4k_150m_a_60p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_3840_2160_30p_10b_400m_amamo,
//                optionImage: "qrc:/images/rec_mov_4k-a_400_10_30p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_3840_2160_30p_10b_150m_amamo,
//                optionImage: "qrc:/images/rec_mov_4k-a_150_10_30p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_3840_2160_30p_8b_100m_amamo,
//                optionImage: "qrc:/images/rec_mov_4k-a_100_8_30p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_3840_2160_24p_10b_400m_amamo,
//                optionImage: "qrc:/images/rec_mov_4k-a_400_10_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_3840_2160_24p_10b_150m_amamo,
//                optionImage: "qrc:/images/rec_mov_4k-a_150_10_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_3840_2160_24p_8b_100m_amamo,
//                optionImage: "qrc:/images/rec_mov_4k-a_100_8_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_1920_1080_60p_10b_200m,
//                optionImage: "qrc:/images/282_rec_mov_fhd_200m_i_60p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_1920_1080_60p_10b_100m,
//                optionImage: "qrc:/images/283_rec_mov_fhd_100m_10bit_60p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_1920_1080_60p_8b_100m,
//                optionImage: "qrc:/images/284_rec_mov_fhd_100m_8bit_60p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_1920_1080_30p_10b_200m,
//                optionImage: "qrc:/images/285_rec_mov_fhd_200m_i_30p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_1920_1080_30p_10b_100m,
//                optionImage: "qrc:/images/286_rec_mov_fhd_100m_10bit_30p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_1920_1080_30p_8b_100m,
//                optionImage: "qrc:/images/287_rec_mov_fhd_100m_8bit_30p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_1920_1080_24p_10b_200m,
//                optionImage: "qrc:/images/288_rec_mov_fhd_200m_i_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_1920_1080_24p_10b_100m,
//                optionImage: "qrc:/images/289_rec_mov_fhd_100m_10bit_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_1920_1080_24p_8b_100m,
//                optionImage: "qrc:/images/290_rec_mov_fhd_100m_8bit_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_PAL_3840_2160_50p_8b_150m,
//                optionImage: "qrc:/images/291_rec_mov_4k_150m_8bit_50p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_PAL_3840_2160_25p_10b_400m,
//                optionImage: "qrc:/images/292_rec_mov_4k_400m_i_25p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_PAL_3840_2160_25p_10b_150m,
//                optionImage: "qrc:/images/293_rec_mov_4k_150m_10bit_25p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_PAL_3840_2160_25p_8b_100m,
//                optionImage: "qrc:/images/294_rec_mov_4k_100m_8bit_25p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_PAL_4992_3744_25p_10b_200m_amamo,
//                optionImage: "qrc:/images/553_rec_mov_6k_200m_a_25p-01.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_PAL_3840_2160_50p_8b_150m_amamo,
//                optionImage: "qrc:/images/rec_mov_4k-a_150_8_50p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_PAL_3840_2160_25p_10b_400m_amamo,
//                optionImage: "qrc:/images/rec_mov_4k-a_400_10_25p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_PAL_3840_2160_25p_10b_150m_amamo,
//                optionImage: "qrc:/images/rec_mov_4k-a_150_10_25p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_PAL_3840_2160_25p_8b_100m_amamo,
//                optionImage: "qrc:/images/rec_mov_4k-a_100_8_25p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_PAL_1920_1080_50p_10b_200m,
//                optionImage: "qrc:/images/299_rec_mov_fhd_200m_i_50p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_PAL_1920_1080_50p_10b_100m,
//                optionImage: "qrc:/images/300_rec_mov_fhd_100m_10bit_50p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_PAL_1920_1080_50p_8b_100m,
//                optionImage: "qrc:/images/301_rec_mov_fhd_100m_8bit_50p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_PAL_1920_1080_25p_10b_200m,
//                optionImage: "qrc:/images/302_rec_mov_fhd_200m_i_25p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_PAL_1920_1080_25p_10b_100m,
//                optionImage: "qrc:/images/303_rec_mov_fhd_100m_10bit_25p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_PAL_1920_1080_25p_8b_100m,
//                optionImage: "qrc:/images/304_rec_mov_fhd_100m_8bit_25p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_CINEMA_4096_2160_24p_10b_400m,
//                optionImage: "qrc:/images/305_rec_mov_c4k_400m_i_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_CINEMA_4096_2160_24p_10b_150m,
//                optionImage: "qrc:/images/306_rec_mov_c4k_150m_10bit_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_CINEMA_4096_2160_24p_8b_100m,
//                optionImage: "qrc:/images/307_rec_mov_c4k_100m_8bit_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_CINEMA_3840_2160_24p_10b_400m,
//                optionImage: "qrc:/images/308_rec_mov_4k_400m_i_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_CINEMA_3840_2160_24p_10b_150m,
//                optionImage: "qrc:/images/309_rec_mov_4k_150m_10bit_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_CINEMA_3840_2160_24p_8b_100m,
//                optionImage: "qrc:/images/310_rec_mov_4k_100m_8bit_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_CINEMA_4992_3744_24p_10b_200m_amamo,
//                optionImage: "qrc:/images/552_rec_mov_6k_200m_a_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_CINEMA_3840_2160_24p_10b_400m_amamo,
//                optionImage: "qrc:/images/rec_mov_4k-a_400_10_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_CINEMA_3840_2160_24p_10b_150m_amamo,
//                optionImage: "qrc:/images/rec_mov_4k-a_150_10_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_CINEMA_3840_2160_24p_8b_100m_amamo,
//                optionImage: "qrc:/images/rec_mov_4k-a_100_8_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_CINEMA_1920_1080_24p_10b_200m,
//                optionImage: "qrc:/images/314_rec_mov_fhd_200m_i_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_CINEMA_1920_1080_24p_10b_100m,
//                optionImage: "qrc:/images/315_rec_mov_fhd_100m_10bit_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_CINEMA_1920_1080_24p_8b_100m,
//                optionImage: "qrc:/images/316_rec_mov_fhd_100m_8bit_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_4096_2160_24p_10b_400m,
//                optionImage: "qrc:/images/317_rec_mov_c4k_400m_i_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_4096_2160_24p_10b_150m,
//                optionImage: "qrc:/images/318_rec_mov_c4k_150m_10bit_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_4096_2160_24p_8b_100m,
//                optionImage: "qrc:/images/319_rec_mov_c4k_100m_8bit_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_3840_2160_60p_8b_150m,
//                optionImage: "qrc:/images/320_rec_mov_4k_150m_8bit_60p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_3840_2160_30p_10b_400m,
//                optionImage: "qrc:/images/321_rec_mov_4k_400m_i_30p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_3840_2160_30p_10b_150m,
//                optionImage: "qrc:/images/322_rec_mov_4k_150m_10bit_30p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_3840_2160_30p_8b_100m,
//                optionImage: "qrc:/images/323_rec_mov_4k_100m_8bit_30p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_3840_2160_24p_10b_400m,
//                optionImage: "qrc:/images/324_rec_mov_4k_400m_i_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_3840_2160_24p_10b_150m,
//                optionImage: "qrc:/images/325_rec_mov_4k_150m_10bit_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_3840_2160_24p_8b_100m,
//                optionImage: "qrc:/images/326_rec_mov_4k_100m_8bit_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_3840_2160_60p_8b_150m_amamo,
//                optionImage: "qrc:/images/327_rec_mov_4k_150m_a_60p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_3840_2160_30p_10b_400m_amamo,
//                optionImage: "qrc:/images/rec_mov_4k-a_400_10_30p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_3840_2160_30p_10b_150m_amamo,
//                optionImage: "qrc:/images/rec_mov_4k-a_150_10_30p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_3840_2160_30p_8b_100m_amamo,
//                optionImage: "qrc:/images/rec_mov_4k-a_100_8_30p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_3840_2160_24p_10b_400m_amamo,
//                optionImage: "qrc:/images/rec_mov_4k-a_400_10_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_3840_2160_24p_10b_150m_amamo,
//                optionImage: "qrc:/images/rec_mov_4k-a_150_10_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_3840_2160_24p_8b_100m_amamo,
//                optionImage: "qrc:/images/rec_mov_4k-a_100_8_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_1920_1080_60p_10b_200m,
//                optionImage: "qrc:/images/334_rec_mov_fhd_200m_i_60p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_1920_1080_60p_10b_100m,
//                optionImage: "qrc:/images/335_rec_mov_fhd_100m_10bit_60p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_1920_1080_60p_8b_100m,
//                optionImage: "qrc:/images/336_rec_mov_fhd_100m_8bit_60p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_1920_1080_30p_10b_200m,
//                optionImage: "qrc:/images/337_rec_mov_fhd_200m_i_30p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_1920_1080_30p_10b_100m,
//                optionImage: "qrc:/images/338_rec_mov_fhd_100m_10bit_30p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_1920_1080_30p_8b_100m,
//                optionImage: "qrc:/images/339_rec_mov_fhd_100m_8bit_30p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_1920_1080_24p_10b_200m,
//                optionImage: "qrc:/images/340_rec_mov_fhd_200m_i_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_1920_1080_24p_10b_100m,
//                optionImage: "qrc:/images/341_rec_mov_fhd_100m_10bit_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_1920_1080_24p_8b_100m,
//                optionImage: "qrc:/images/342_rec_mov_fhd_100m_8bit_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_3840_2160_50p_8b_150m,
//                optionImage: "qrc:/images/343_rec_mov_4k_150m_8bit_50p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_3840_2160_25p_10b_400m,
//                optionImage: "qrc:/images/344_rec_mov_4k_400m_i_25p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_3840_2160_25p_8b_150m,
//                optionImage: "qrc:/images/345_rec_mov_4k_150m_10bit_25p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_3840_2160_25p_8b_100m,
//                optionImage: "qrc:/images/346_rec_mov_4k_100m_8bit_25p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_3840_2160_50p_8b_150m_amamo,
//                optionImage: "qrc:/images/rec_mov_4k-a_150_8_50p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_3840_2160_25p_10b_400m_amamo,
//                optionImage: "qrc:/images/rec_mov_4k-a_400_10_25p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_3840_2160_25p_8b_150m_amamo,
//                optionImage: "qrc:/images/rec_mov_4k-a_150_10_25p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_3840_2160_25p_8b_100m_amamo,
//                optionImage: "qrc:/images/rec_mov_4k-a_100_8_25p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_1920_1080_50p_10b_200m,
//                optionImage: "qrc:/images/351_rec_mov_fhd_200m_i_50p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_1920_1080_50p_10b_100m,
//                optionImage: "qrc:/images/352_rec_mov_fhd_100m_10bit_50p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_1920_1080_50p_8b_100m,
//                optionImage: "qrc:/images/353_rec_mov_fhd_100m_8bit_50p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_1920_1080_25p_10b_200m,
//                optionImage: "qrc:/images/354_rec_mov_fhd_200m_i_25p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_1920_1080_25p_10b_100m,
//                optionImage: "qrc:/images/355_rec_mov_fhd_100m_10bit_25p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_1920_1080_25p_8b_100m,
//                optionImage: "qrc:/images/356_rec_mov_fhd_100m_8bit_25p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_CINEMA_4096_2160_24p_10b_400m,
//                optionImage: "qrc:/images/357_rec_mov_c4k_400m_i_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_CINEMA_4096_2160_24p_10b_150m,
//                optionImage: "qrc:/images/358_rec_mov_c4k_150m_10bit_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_CINEMA_4096_2160_24p_8b_100m,
//                optionImage: "qrc:/images/359_rec_mov_c4k_100m_8bit_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_CINEMA_3840_2160_24p_10b_400m,
//                optionImage: "qrc:/images/360_rec_mov_4k_400m_i_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_CINEMA_3840_2160_24p_10b_150m,
//                optionImage: "qrc:/images/361_rec_mov_4k_150m_10bit_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_CINEMA_3840_2160_24p_8b_100m,
//                optionImage: "qrc:/images/362_rec_mov_4k_100m_8bit_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_CINEMA_3840_2160_24p_10b_400m_amamo,
//                optionImage: "qrc:/images/rec_mov_4k-a_400_10_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_CINEMA_3840_2160_24p_10b_150m_amamo,
//                optionImage: "qrc:/images/rec_mov_4k-a_150_10_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_CINEMA_3840_2160_24p_8b_100m_amamo,
//                optionImage: "qrc:/images/rec_mov_4k-a_100_8_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_CINEMA_1920_1080_24p_10b_200m,
//                optionImage: "qrc:/images/366_rec_mov_fhd_200m_i_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_CINEMA_1920_1080_24p_10b_100m,
//                optionImage: "qrc:/images/367_rec_mov_fhd_100m_10bit_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_CINEMA_1920_1080_24p_8b_100m,
//                optionImage: "qrc:/images/368_rec_mov_fhd_100m_8bit_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_3840_2160_50p_150m,
//                optionImage: "qrc:/images/291_rec_mov_4k_150m_8bit_50p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_3840_2160_25p_150m,
//                optionImage: "qrc:/images/293_rec_mov_4k_150m_10bit_25p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_1920_1080_50p_100m,
//                optionImage: "qrc:/images/300_rec_mov_fhd_100m_10bit_50p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_1920_1080_25p_100m,
//                optionImage: "qrc:/images/303_rec_mov_fhd_100m_10bit_25p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_HEVC_PAL_3840_2160_30p_72m,
//                optionImage: "qrc:/images/rec_mov_4k_72m_30p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_HEVC_PAL_3840_2160_24p_72m,
//                optionImage: "qrc:/images/rec_mov_4k_72m_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_NTSC_4096_2160_60p_150m,
//                optionImage: "qrc:/images/rec_mov_c4k_150m_8bit_60p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_PAL_4096_2160_50p_150m,
//                optionImage: "qrc:/images/rec_mov_c4k_150m_8bit_50p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_4096_2160_30p_8b_100m,
//                optionImage: "qrc:/images/rec_mov_c4k_100m_8bit_30p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_PAL_4096_2160_25p_100m,
//                optionImage: "qrc:/images/rec_mov_c4k_100m_8bit_25p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_LPCM_NTSC_4096_2160_30p_10b_100m,
//                optionImage: "qrc:/images/rec_mov_c4k_150m_10bit_30p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_PAL_4096_2160_25p_150m,
//                optionImage: "qrc:/images/rec_mov_c4k_150m_10bit_25p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_4096_2160_25p_10b_400m,
//                optionImage: "qrc:/images/rec_mov_c4k_400_10_25p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_4096_2160_30p_10b_400m,
//                optionImage: "qrc:/images/rec_mov_c4k_400_10_30p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_4096_2160_60p_8b_150m,
//                optionImage: "qrc:/images/rec_mov_c4k_150m_8bit_60p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_4096_2160_50p_150m,
//                optionImage: "qrc:/images/rec_mov_c4k_150m_8bit_50p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_4096_2160_30p_8b_100m,
//                optionImage: "qrc:/images/rec_mov_c4k_100m_8bit_30p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_4096_2160_25p_100m,
//                optionImage: "qrc:/images/rec_mov_c4k_100m_8bit_25p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_4096_2160_30p_10b_150m,
//                optionImage: "qrc:/images/rec_mov_c4k_150m_10bit_30p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_4096_2160_25p_150m,
//                optionImage: "qrc:/images/rec_mov_c4k_150m_10bit_25p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        // 2019/06/05 ADD(402-461)
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_4096_2160_60p_10b_200m,
//                optionImage: "qrc:/images/rec_mov_c4k_200_10_60p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_4096_2160_50_00p_10b_200m,
//                optionImage: "qrc:/images/rec_mov_c4k_200_10_50p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_4096_2160_47_95p_10b_200m,
//                optionImage: "qrc:/images/rec_mov_c4k_200_10_48p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_CINEMA_4096_2160_48_00p_10b_200m,
//                optionImage: "qrc:/images/rec_mov_c4k_200_10_48p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_3840_2160_59_94p_10b_200m,
//                optionImage: "qrc:/images/rec_mov_4k_200_10_60p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_3840_2160_50_00p_10b_200m,
//                optionImage: "qrc:/images/rec_mov_4k_200_10_50p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_3840_2160_47_95p_10b_200m,
//                optionImage: "qrc:/images/rec_mov_4k_200_10_48p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_CINEMA_3840_2160_48_00p_10b_200m,
//                optionImage: "qrc:/images/rec_mov_4k_200_10_48p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_3328_2496_50_00p_10b_200m,
//                optionImage: "qrc:/images/rec_mov_4k-a_200_10_50p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_3328_2496_47_95p_10b_200m,
//                optionImage: "qrc:/images/rec_mov_4k-a_200_10_48p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_CINEMA_3328_2496_48_00p_10b_200m,
//                optionImage: "qrc:/images/rec_mov_4k-a_200_10_48p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_1920_1080_59_94i_10b_100m,
//                optionImage: "qrc:/images/rec_mov_fhd_100_10_60i.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_1920_1080_59_94i_10b_50m,
//                optionImage: "qrc:/images/rec_mov_fhd_50_10_60i.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_1920_1080_50_00i_10b_100m,
//                optionImage: "qrc:/images/rec_mov_fhd_100_10_50i.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_1920_1080_50_00i_10b_50m,
//                optionImage: "qrc:/images/rec_mov_fhd_50_10_50i.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_1920_1080_119_88p_10b_150m,
//                optionImage: "qrc:/images/rec_mov_fhd_150_10_120p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_1920_1080_100_00p_10b_150m,
//                optionImage: "qrc:/images/rec_mov_fhd_150_10_100p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_1920_1080_47_95p_10b_100m,
//                optionImage: "qrc:/images/rec_mov_fhd_100_10_48p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_CINEMA_1920_1080_48_00p_10b_100m,
//                optionImage: "qrc:/images/rec_mov_fhd_100_10_48p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_5952_3968_23_98p_10b_200m,
//                optionImage: "qrc:/images/rec_mov_6k_200_10_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_CINEMA_5952_3968_24_00p_10b_200m,
//                optionImage: "qrc:/images/rec_mov_6k_200_10_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_5376_3584_25_00p_10b_200m,
//                optionImage: "qrc:/images/rec_mov_54k_200_10_25p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_5376_3584_29_97p_10b_200m,
//                optionImage: "qrc:/images/rec_mov_54k_200_10_30p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_5888_3312_23_98p_10b_200m,
//                optionImage: "qrc:/images/rec_mov_59k_200_10_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_CINEMA_5888_3312_24_00p_10b_200m,
//                optionImage: "qrc:/images/rec_mov_59k_200_10_24p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_PAL_5888_3312_25_00p_10b_200m,
//                optionImage: "qrc:/images/rec_mov_59k_200_10_25p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MOV_NTSC_5888_3312_29_97p_10b_200m,
//                optionImage: "qrc:/images/rec_mov_59k_200_10_30p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_NTSC_3840_2160_59_94p_10b_100m,
//                optionImage: "qrc:/images/rec_mov_4k_100_10_60p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//        {
//            component: optionDetailWithImageButtonComponent,
//            properties: {
//                value: LT.Utilities.RCMV_MP4_PAL_3840_2160_50_00p_10b_100m,
//                optionImage: "qrc:/images/rec_mov_4k_100_10_50p.svg",
//                type: "optionDetailWithRow"
//            }
//        },
//    ]


//    /*!
//        動画画質方式を選択する LTMainMovieQualityPopup に表示するコンポーネントの組です (Built-in Data)
//    */
//    readonly property var recMovieBuiltIn: [
//            {
//                component: optionDetailWithImageButtonComponent,               // 0 - AVCHD - NTSC
//                properties_NTSC: {
//                    value: 0,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x8000176A,
//                    frameRate_IgnoreFrequency: 0x80001770,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 28,
//                    type: "optionDetailWithRow"
//                },
//                properties_PAL: {
//                    value: 0,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x80001388,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 28,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 1 - AVCHD - PAL
//                properties_NTSC: {
//                    value: 1,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x176A,
//                    frameRate_IgnoreFrequency: 0x1770,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 17,
//                    type: "optionDetailWithRow"
//                },
//                properties_PAL: {
//                    value: 1,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x1388,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 17,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,
//                properties_PAL: {               								// 27 - AVCHD - PAL
//                    value: 27,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x1388,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 24,
//                    type: "optionDetailWithRow"
//                },
//                properties_NTSC: {               								// 27 - AVCHD - NTSC
//                    value: 27,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x176A,
//                    frameRate_IgnoreFrequency: 0x1770,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 24,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,
//                properties_PAL: {               								// 4 - AVCHD - PAL
//                    value: 4,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x80000960,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 24,
//                    type: "optionDetailWithRow"
//                },
//                properties_NTSC: {               							 	// 4 - AVCHD - NTSC
//                    value: 4,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x8000095E,
//                    frameRate_IgnoreFrequency: 0x80000960,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 24,
//                    type: "optionDetailWithRow"
//                }
//            },
//        /* MP4 */
//            {
//                component: optionDetailWithImageButtonComponent,               // 53 - MP4 - CINEMA
//                properties_CINEMA: {
//                    value: 53,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x80000960,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 24,
//                    type: "optionDetailWithRow"
//                }
//            },
//        /* MOV */
//        /* MP4 */
//            {
//                component: optionDetailWithImageButtonComponent,               // 371 - MP4 - PAL
//                properties_PAL: {
//                    value: 371,
//                    pixels: LT.Utilities.MP_C4K_17_9_4096_2160,
//                    frameRate: 0x80001388,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 150,
//                    type: "optionDetailWithRow"
//                },               												// 371 - MP4 - NTSC
//                properties_NTSC: {
//                    value: 371,
//                    pixels: LT.Utilities.MP_C4K_17_9_4096_2160,
//                    frameRate: 0x8000176A,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 150,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 373 - MP4 - PAL
//                properties_PAL: {
//                    value: 373,
//                    pixels: LT.Utilities.MP_C4K_17_9_4096_2160,
//                    frameRate: 0x800009C4,
//                    compressionMethod: compMethod_422_10bit_LongGOP,
//                    bitRate: 150,
//                    type: "optionDetailWithRow"
//                },               												// 373 - MP4 - NTSC
//                properties_NTSC: {
//                    value: 373,
//                    pixels: LT.Utilities.MP_C4K_17_9_4096_2160,
//                    frameRate: 0x80000BB5,
//                    compressionMethod: compMethod_422_10bit_LongGOP,
//                    bitRate: 150,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 372 - MP4 - PAL
//                properties_PAL: {
//                    value: 372,
//                    pixels: LT.Utilities.MP_C4K_17_9_4096_2160,
//                    frameRate: 0x800009C4,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                },               												// 372 - MP4 - NTSC
//                properties_NTSC: {
//                    value: 372,
//                    pixels: LT.Utilities.MP_C4K_17_9_4096_2160,
//                    frameRate: 0x80000BB5,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 184 - MP4 - NTSC
//                properties_NTSC: {
//                    value: 184,
//                    pixels: LT.Utilities.MP_C4K_17_9_4096_2160,
//                    frameRate: 0x8000095E,
//                    compressionMethod: compMethod_422_10bit_All_I,
//                    bitRate: 400,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 183 - MP4 - NTSC
//                properties_NTSC: {
//                    value: 183,
//                    pixels: LT.Utilities.MP_C4K_17_9_4096_2160,
//                    frameRate: 0x8000095E,
//                    compressionMethod: compMethod_422_10bit_LongGOP,
//                    bitRate: 150,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 182 - MP4 - NTSC
//                properties_NTSC: {
//                    value: 182,
//                    pixels: LT.Utilities.MP_C4K_17_9_4096_2160,
//                    frameRate: 0x8000095E,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 186 - MP4 - CINEMA
//                properties_CINEMA: {
//                    value: 186,
//                    pixels: LT.Utilities.MP_C4K_17_9_4096_2160,
//                    frameRate: 0x80000960,
//                    compressionMethod: compMethod_422_10bit_All_I,
//                    bitRate: 400,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 185 - MP4 - CINEMA
//                properties_CINEMA: {
//                    value: 185,
//                    pixels: LT.Utilities.MP_C4K_17_9_4096_2160,
//                    frameRate: 0x80000960,
//                    compressionMethod: compMethod_422_10bit_LongGOP,
//                    bitRate: 150,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 38 - MP4 - CINEMA
//                properties_CINEMA: {
//                    value: 38,
//                    pixels: LT.Utilities.MP_C4K_17_9_4096_2160,
//                    frameRate: 0x80000960,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 187 - MP4 - PAL
//                properties_PAL: {
//                    value: 187,
//                    pixels: LT.Utilities.MP_4K_16_9_3840_2160,
//                    frameRate: 0x80001388,
//                    frameRate_IgnoreFrequency: 0x80001770,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 150,
//                    type: "optionDetailWithRow"
//                },               												// 187 - MP4 - NTSC
//                properties_NTSC: {
//                    value: 187,
//                    pixels: LT.Utilities.MP_4K_16_9_3840_2160,
//                    frameRate: 0x8000176A,
//                    frameRate_IgnoreFrequency: 0x80001770,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 150,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 386 - MP4 - PAL
//                properties_PAL: {
//                    value: 386,
//                    pixels: LT.Utilities.MP_4K_16_9_3840_2160,
//                    frameRate: 0x80001388,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 150,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 177 - MP4 - PAL
//                properties_PAL: {
//                    value: 177,
//                    pixels: LT.Utilities.MP_4K_16_9_3840_2160,
//                    frameRate: 0x80000BB8,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                },               												// 177 - MP4 - NTSC
//                properties_NTSC: {
//                    value: 177,
//                    pixels: LT.Utilities.MP_4K_16_9_3840_2160,
//                    frameRate: 0x80000BB5,
//                    frameRate_IgnoreFrequency: 0x80000BB8,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 178 - MP4 - PAL
//                properties_PAL: {
//                    value: 178,
//                    pixels: LT.Utilities.MP_4K_16_9_3840_2160,
//                    frameRate: 0x800009C4,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 179 - MP4 - PAL
//                properties_PAL: {
//                    value: 179,
//                    pixels: LT.Utilities.MP_4K_16_9_3840_2160,
//                    frameRate: 0x80000960,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                },               												// 179 - MP4 - NTSC
//                properties_NTSC: {
//                    value: 179,
//                    pixels: LT.Utilities.MP_4K_16_9_3840_2160,
//                    frameRate: 0x8000095E,
//                    frameRate_IgnoreFrequency: 0x80000960,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 189 - MP4 - PAL
//                properties_PAL: {
//                    value: 189,
//                    pixels: LT.Utilities.MP_4K_16_9_3840_2160,
//                    frameRate: 0x800009C4,
//                    compressionMethod: compMethod_422_10bit_All_I,
//                    bitRate: 400,
//                    type: "optionDetailWithRow"
//                },               												// 189 - MP4 - NTSC
//                properties_NTSC: {
//                    value: 189,
//                    pixels: LT.Utilities.MP_4K_16_9_3840_2160,
//                    frameRate: 0x80000BB5,
//                    compressionMethod: compMethod_422_10bit_All_I,
//                    bitRate: 400,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 188 - MP4 - PAL
//                properties_PAL: {
//                    value: 188,
//                    pixels: LT.Utilities.MP_4K_16_9_3840_2160,
//                    frameRate: 0x800009C4,
//                    compressionMethod: compMethod_422_10bit_LongGOP,
//                    bitRate: 150,
//                    type: "optionDetailWithRow"
//                },               												// 188 - MP4 - NTSC
//                properties_NTSC: {
//                    value: 188,
//                    pixels: LT.Utilities.MP_4K_16_9_3840_2160,
//                    frameRate: 0x80000BB5,
//                    compressionMethod: compMethod_422_10bit_LongGOP,
//                    bitRate: 150,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,
//                properties_PAL: {               								// 18 - MP4 - PAL
//                    value: 18,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x80001770,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 28,
//                    type: "optionDetailWithRow"
//                },
//                properties_NTSC: {              								// 18 - MP4 - NTSC
//                    value: 18,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x8000176A,
//                    frameRate_IgnoreFrequency: 0x80001770,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 28,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,
//                properties_PAL: {               								// 19 - MP4 - PAL
//                    value: 19,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x80001388,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 28,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,
//                properties_PAL: {               								// 20 - MP4 - PAL
//                    value: 20,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x80000BB8,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 20,
//                    type: "optionDetailWithRow"
//                },
//                properties_NTSC: {               								// 20 - MP4 - NTSC
//                    value: 20,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x80000BB5,
//                    frameRate_IgnoreFrequency: 0x80000BB8,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 20,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 21 - MP4 - PAL
//                properties_PAL: {
//                    value: 21,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x800009C4,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 20,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 180 - MP4 - NTSC
//                properties_NTSC: {
//                    value: 180,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x8000095E,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 24,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 42 - MP4 - PAL
//                properties_PAL: {
//                    value: 42,
//                    pixels: LT.Utilities.MP_4K_16_9_3840_2160,
//                    frameRate: 0x800009C4,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                },               												// 42 - MP4 - NTSC
//                properties_NTSC: {
//                    value: 42,
//                    pixels: LT.Utilities.MP_4K_16_9_3840_2160,
//                    frameRate: 0x80000BB5,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 191 - MP4 - NTSC
//                properties_NTSC: {
//                    value: 191,
//                    pixels: LT.Utilities.MP_4K_16_9_3840_2160,
//                    frameRate: 0x8000095E,
//                    compressionMethod: compMethod_422_10bit_All_I,
//                    bitRate: 400,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 190 - MP4 - NTSC
//                properties_NTSC: {
//                    value: 190,
//                    pixels: LT.Utilities.MP_4K_16_9_3840_2160,
//                    frameRate: 0x8000095E,
//                    compressionMethod: compMethod_422_10bit_LongGOP,
//                    bitRate: 150,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 46 - MP4 - NTSC
//                properties_NTSC: {
//                    value: 46,
//                    pixels: LT.Utilities.MP_4K_16_9_3840_2160,
//                    frameRate: 0x8000095E,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 193 - MP4 - CINEMA
//                properties_CINEMA: {
//                    value: 193,
//                    pixels: LT.Utilities.MP_4K_16_9_3840_2160,
//                    frameRate: 0x80000960,
//                    compressionMethod: compMethod_422_10bit_All_I,
//                    bitRate: 400,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 192 - MP4 - CINEMA
//                properties_CINEMA: {
//                    value: 192,
//                    pixels: LT.Utilities.MP_4K_16_9_3840_2160,
//                    frameRate: 0x80000960,
//                    compressionMethod: compMethod_422_10bit_LongGOP,
//                    bitRate: 150,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 44 - MP4 - CINEMA
//                properties_CINEMA: {
//                    value: 44,
//                    pixels: LT.Utilities.MP_4K_16_9_3840_2160,
//                    frameRate: 0x80000960,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 205 - MP4 - PAL
//                properties_PAL: {
//                    value: 205,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x80001388,
//                    compressionMethod: compMethod_422_10bit_All_I,
//                    bitRate: 200,
//                    type: "optionDetailWithRow"
//                },               												// 205 - MP4 - NTSC
//                properties_NTSC: {
//                    value: 205,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x8000176A,
//                    compressionMethod: compMethod_422_10bit_All_I,
//                    bitRate: 200,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 206 - MP4 - PAL
//                properties_PAL: {
//                    value: 206,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x80001388,
//                    compressionMethod: compMethod_422_10bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                },               												// 206 - MP4 - NTSC
//                properties_NTSC: {
//                    value: 206,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x8000176A,
//                    compressionMethod: compMethod_422_10bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 48 - MP4 - PAL
//                properties_PAL: {
//                    value: 48,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x80001388,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                },               												// 48 - MP4 - NTSC
//                properties_NTSC: {
//                    value: 48,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x8000176A,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 207 - MP4 - PAL
//                properties_PAL: {
//                    value: 207,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x800009C4,
//                    compressionMethod: compMethod_422_10bit_All_I,
//                    bitRate: 200,
//                    type: "optionDetailWithRow"
//                },               												// 207 - MP4 - NTSC
//                properties_NTSC: {
//                    value: 207,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x80000BB5,
//                    compressionMethod: compMethod_422_10bit_All_I,
//                    bitRate: 200,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 208 - MP4 - PAL
//                properties_PAL: {
//                    value: 208,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x800009C4,
//                    compressionMethod: compMethod_422_10bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                },               												// 208 - MP4 - NTSC
//                properties_NTSC: {
//                    value: 208,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x80000BB5,
//                    compressionMethod: compMethod_422_10bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 51 - MP4 - PAL
//                properties_PAL: {
//                    value: 51,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x800009C4,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                },               												// 51 - MP4 - NTSC
//                properties_NTSC: {
//                    value: 51,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x80000BB5,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 209 - MP4 - NTSC
//                properties_NTSC: {
//                    value: 209,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x8000095E,
//                    compressionMethod: compMethod_422_10bit_All_I,
//                    bitRate: 200,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 210 - MP4 - NTSC
//                properties_NTSC: {
//                    value: 210,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x8000095E,
//                    compressionMethod: compMethod_422_10bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 58 - MP4 - NTSC
//                properties_NTSC: {
//                    value: 58,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x8000095E,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 211 - MP4 - CINEMA
//                properties_CINEMA: {
//                    value: 211,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x80000960,
//                    compressionMethod: compMethod_422_10bit_All_I,
//                    bitRate: 200,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 212 - MP4 - CINEMA
//                properties_CINEMA: {
//                    value: 212,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x80000960,
//                    compressionMethod: compMethod_422_10bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 55 - MP4 - CINEMA
//                properties_CINEMA: {
//                    value: 55,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x80000960,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                }
//            },
//        /* MOV */
//            {
//                component: optionDetailWithImageButtonComponent,               // 379 - MOV - PAL
//                properties_PAL: {
//                    value: 379,
//                    pixels: LT.Utilities.MP_C4K_17_9_4096_2160,
//                    frameRate: 0x80001388,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 150,
//                    type: "optionDetailWithRow"
//                },               												// 379 - MOV - NTSC
//                properties_NTSC: {
//                    value: 379,
//                    pixels: LT.Utilities.MP_C4K_17_9_4096_2160,
//                    frameRate: 0x8000176A,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 150,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 381 - MOV - PAL
//                properties_PAL: {
//                    value: 381,
//                    pixels: LT.Utilities.MP_C4K_17_9_4096_2160,
//                    frameRate: 0x800009C4,
//                    compressionMethod: compMethod_422_10bit_LongGOP,
//                    bitRate: 150,
//                    type: "optionDetailWithRow"
//                },               												// 381 - MOV - NTSC
//                properties_NTSC: {
//                    value: 381,
//                    pixels: LT.Utilities.MP_C4K_17_9_4096_2160,
//                    frameRate: 0x80000BB5,
//                    compressionMethod: compMethod_422_10bit_LongGOP,
//                    bitRate: 150,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 380 - MOV - PAL
//                properties_PAL: {
//                    value: 380,
//                    pixels: LT.Utilities.MP_C4K_17_9_4096_2160,
//                    frameRate: 0x800009C4,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                },               												// 380 - MOV - NTSC
//                properties_NTSC: {
//                    value: 380,
//                    pixels: LT.Utilities.MP_C4K_17_9_4096_2160,
//                    frameRate: 0x80000BB5,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 224 - MOV - NTSC
//                properties_NTSC: {
//                    value: 224,
//                    pixels: LT.Utilities.MP_C4K_17_9_4096_2160,
//                    frameRate: 0x8000095E,
//                    compressionMethod: compMethod_422_10bit_All_I,
//                    bitRate: 400,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 222 - MOV - NTSC
//                properties_NTSC: {
//                    value: 222,
//                    pixels: LT.Utilities.MP_C4K_17_9_4096_2160,
//                    frameRate: 0x8000095E,
//                    compressionMethod: compMethod_422_10bit_LongGOP,
//                    bitRate: 150,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 223 - MOV - NTSC
//                properties_NTSC: {
//                    value: 223,
//                    pixels: LT.Utilities.MP_C4K_17_9_4096_2160,
//                    frameRate: 0x8000095E,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 226 - MOV - CINEMA
//                properties_CINEMA: {
//                    value: 226,
//                    pixels: LT.Utilities.MP_C4K_17_9_4096_2160,
//                    frameRate: 0x80000960,
//                    compressionMethod: compMethod_422_10bit_All_I,
//                    bitRate: 400,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 225 - MOV - CINEMA
//                properties_CINEMA: {
//                    value: 225,
//                    pixels: LT.Utilities.MP_C4K_17_9_4096_2160,
//                    frameRate: 0x80000960,
//                    compressionMethod: compMethod_422_10bit_LongGOP,
//                    bitRate: 150,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 60 - MOV - CINEMA
//                properties_CINEMA: {
//                    value: 60,
//                    pixels: LT.Utilities.MP_C4K_17_9_4096_2160,
//                    frameRate: 0x80000960,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 227 - MOV - PAL
//                properties_PAL: {
//                    value: 227,
//                    pixels: LT.Utilities.MP_4K_16_9_3840_2160,
//                    frameRate: 0x80001388,
//                    frameRate_IgnoreFrequency: 0x80001770,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 150,
//                    type: "optionDetailWithRow"
//                },               												// 227 - MOV - NTSC
//                properties_NTSC: {
//                    value: 227,
//                    pixels: LT.Utilities.MP_4K_16_9_3840_2160,
//                    frameRate: 0x8000176A,
//                    frameRate_IgnoreFrequency: 0x80001770,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 150,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 229 - MOV - PAL
//                properties_PAL: {
//                    value: 229,
//                    pixels: LT.Utilities.MP_4K_16_9_3840_2160,
//                    frameRate: 0x800009C4,
//                    compressionMethod: compMethod_422_10bit_All_I,
//                    bitRate: 400,
//                    type: "optionDetailWithRow"
//                },               												// 229 - MOV - NTSC
//                properties_NTSC: {
//                    value: 229,
//                    pixels: LT.Utilities.MP_4K_16_9_3840_2160,
//                    frameRate: 0x80000BB5,
//                    compressionMethod: compMethod_422_10bit_All_I,
//                    bitRate: 400,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 228 - MOV - PAL
//                properties_PAL: {
//                    value: 228,
//                    pixels: LT.Utilities.MP_4K_16_9_3840_2160,
//                    frameRate: 0x800009C4,
//                    frameRate_IgnoreFrequency: 0x80000BB8,
//                    compressionMethod: compMethod_422_10bit_LongGOP,
//                    bitRate: 150,
//                    type: "optionDetailWithRow"
//                },               												// 228 - MOV - NTSC
//                properties_NTSC: {
//                    value: 228,
//                    pixels: LT.Utilities.MP_4K_16_9_3840_2160,
//                    frameRate: 0x80000BB5,
//                    frameRate_IgnoreFrequency: 0x80000BB8,
//                    compressionMethod: compMethod_422_10bit_LongGOP,
//                    bitRate: 150,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 61 - MOV - PAL
//                properties_PAL: {
//                    value: 61,
//                    pixels: LT.Utilities.MP_4K_16_9_3840_2160,
//                    frameRate: 0x800009C4,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                },               												// 61 - MOV - NTSC
//                properties_NTSC: {
//                    value: 61,
//                    pixels: LT.Utilities.MP_4K_16_9_3840_2160,
//                    frameRate: 0x80000BB5,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 231 - MOV - NTSC
//                properties_NTSC: {
//                    value: 231,
//                    pixels: LT.Utilities.MP_4K_16_9_3840_2160,
//                    frameRate: 0x8000095E,
//                    compressionMethod: compMethod_422_10bit_All_I,
//                    bitRate: 400,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 230 - MOV - NTSC
//                properties_NTSC: {
//                    value: 230,
//                    pixels: LT.Utilities.MP_4K_16_9_3840_2160,
//                    frameRate: 0x8000095E,
//                    frameRate_IgnoreFrequency: 0x80000960,
//                    compressionMethod: compMethod_422_10bit_LongGOP,
//                    bitRate: 150,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 233 - MOV - CINEMA
//                properties_CINEMA: {
//                    value: 233,
//                    pixels: LT.Utilities.MP_4K_16_9_3840_2160,
//                    frameRate: 0x80000960,
//                    compressionMethod: compMethod_422_10bit_All_I,
//                    bitRate: 400,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 232 - MOV - CINEMA
//                properties_CINEMA: {
//                    value: 232,
//                    pixels: LT.Utilities.MP_4K_16_9_3840_2160,
//                    frameRate: 0x80000960,
//                    compressionMethod: compMethod_422_10bit_LongGOP,
//                    bitRate: 150,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 62 - MOV - CINEMA
//                properties_CINEMA: {
//                    value: 62,
//                    pixels: LT.Utilities.MP_4K_16_9_3840_2160,
//                    frameRate: 0x80000960,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 63 - MOV - NTSC
//                properties_NTSC: {
//                    value: 63,
//                    pixels: LT.Utilities.MP_4K_16_9_3840_2160,
//                    frameRate: 0x8000095E,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 245 - MOV - PAL
//                properties_PAL: {
//                    value: 245,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x80001388,
//                    compressionMethod: compMethod_422_10bit_All_I,
//                    bitRate: 200,
//                    type: "optionDetailWithRow"
//                },               												// 245 - MOV - NTSC
//                properties_NTSC: {
//                    value: 245,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x8000176A,
//                    compressionMethod: compMethod_422_10bit_All_I,
//                    bitRate: 200,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 246 - MOV - PAL
//                properties_PAL: {
//                    value: 246,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x80001388,
//                    frameRate_IgnoreFrequency: 0x80001770,
//                    compressionMethod: compMethod_422_10bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                },               												// 246 - MOV - NTSC
//                properties_NTSC: {
//                    value: 246,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x8000176A,
//                    frameRate_IgnoreFrequency: 0x80001770,
//                    compressionMethod: compMethod_422_10bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 65 - MOV - PAL
//                properties_PAL: {
//                    value: 65,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x80001388,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                },               												// 65 - MOV - NTSC
//                properties_NTSC: {
//                    value: 65,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x8000176A,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 247 - MOV - PAL
//                properties_PAL: {
//                    value: 247,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x800009C4,
//                    compressionMethod: compMethod_422_10bit_All_I,
//                    bitRate: 200,
//                    type: "optionDetailWithRow"
//                },               												// 247 - MOV - NTSC
//                properties_NTSC: {
//                    value: 247,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x80000BB5,
//                    compressionMethod: compMethod_422_10bit_All_I,
//                    bitRate: 200,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 248 - MOV - PAL
//                properties_PAL: {
//                    value: 248,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x800009C4,
//                    frameRate_IgnoreFrequency: 0x80000BB8,
//                    compressionMethod: compMethod_422_10bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                },               												// 248 - MOV - NTSC
//                properties_NTSC: {
//                    value: 248,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x80000BB5,
//                    frameRate_IgnoreFrequency: 0x80000BB8,
//                    compressionMethod: compMethod_422_10bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 68 - MOV - PAL
//                properties_PAL: {
//                    value: 68,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x800009C4,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                },               												// 68 - MOV - NTSC
//                properties_NTSC: {
//                    value: 68,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x80000BB5,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 249 - MOV - NTSC
//                properties_NTSC: {
//                    value: 249,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x8000095E,
//                    compressionMethod: compMethod_422_10bit_All_I,
//                    bitRate: 200,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 250 - MOV - NTSC
//                properties_NTSC: {
//                    value: 250,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x8000095E,
//                    compressionMethod: compMethod_422_10bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 74 - MOV - NTSC
//                properties_NTSC: {
//                    value: 74,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x8000095E,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 251 - MOV - CINEMA
//                properties_CINEMA: {
//                    value: 251,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x80000960,
//                    compressionMethod: compMethod_422_10bit_All_I,
//                    bitRate: 200,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 252 - MOV - CINEMA
//                properties_CINEMA: {
//                    value: 252,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x80000960,
//                    compressionMethod: compMethod_422_10bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 71 - MOV - CINEMA
//                properties_CINEMA: {
//                    value: 71,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x80000960,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                }
//            },
//        /* MP4 HEVC*/
//            {
//                component: optionDetailWithImageButtonComponent,               // 366 - MP4 HEVC - PAL
//                properties_PAL: {
//                    value: 366,
//                    pixels: LT.Utilities.MP_4K_16_9_3840_2160,
//                    frameRate: 0x800009C4,
//                    frameRate_IgnoreFrequency: 0x80000BB8,
//                    compressionMethod: compMethod_420_10bit_LongGOP,
//                    bitRate: 72,
//                    type: "optionDetailWithRow"
//                },               												// 366 - MP4 HEVC - NTSC
//                properties_NTSC: {
//                    value: 366,
//                    pixels: LT.Utilities.MP_4K_16_9_3840_2160,
//                    frameRate: 0x80000BB5,
//                    frameRate_IgnoreFrequency: 0x80000BB8,
//                    compressionMethod: compMethod_420_10bit_LongGOP,
//                    bitRate: 72,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 367 - MP4 HEVC - PAL
//                properties_PAL: {
//                    value: 367,
//                    pixels: LT.Utilities.MP_4K_16_9_3840_2160,
//                    frameRate: 0x80000960,
//                    compressionMethod: compMethod_420_10bit_LongGOP,
//                    bitRate: 72,
//                    type: "optionDetailWithRow"
//                },               												// 367 - MP4 HEVC - NTSC
//                properties_NTSC: {
//                    value: 367,
//                    pixels: LT.Utilities.MP_4K_16_9_3840_2160,
//                    frameRate: 0x8000095E,
//                    frameRate_IgnoreFrequency: 0x80000960,
//                    compressionMethod: compMethod_420_10bit_LongGOP,
//                    bitRate: 72,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 388 - MP4 HEVC - PAL
//                properties_PAL: {
//                    value: 388,
//                    pixels: LT.Utilities.MP_4K_16_9_3840_2160,
//                    frameRate: 0x800009C4,
//                    compressionMethod: compMethod_420_10bit_LongGOP,
//                    bitRate: 72,
//                    type: "optionDetailWithRow"
//                }
//            },
//        /* MOV */
//            {
//                component: optionDetailWithImageButtonComponent,               // 394 - MOV - PAL
//                properties_PAL: {
//                    value: 394,
//                    pixels: LT.Utilities.MP_4K_16_9_3840_2160,
//                    frameRate: 0x80001388,
//                    compressionMethod: compMethod_420_8bit_LongGOP,
//                    bitRate: 150,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 395 - MOV - PAL
//                properties_PAL: {
//                    value: 395,
//                    pixels: LT.Utilities.MP_4K_16_9_3840_2160,
//                    frameRate: 0x800009C4,
//                    compressionMethod: compMethod_422_10bit_LongGOP,
//                    bitRate: 150,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 396 - MOV - PAL
//                properties_PAL: {
//                    value: 396,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x80001388,
//                    compressionMethod: compMethod_422_10bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                }
//            },
//            {
//                component: optionDetailWithImageButtonComponent,               // 397 - MOV - PAL
//                properties_PAL: {
//                    value: 397,
//                    pixels: LT.Utilities.MP_FHD_16_9_1920_1080,
//                    frameRate: 0x800009C4,
//                    compressionMethod: compMethod_422_10bit_LongGOP,
//                    bitRate: 100,
//                    type: "optionDetailWithRow"
//                }
//            },
//        ]
    /*!
        動画画質方式を選択する LTMainWindow,LTMainMovieQualityPopup に表示するコンポーネントの組です
     */
    readonly property var recMovie: [
        {
            component: optionWithImageButtonComponent,
            properties: {
                type: "optionWithImage"
            }
        },
    ]

    /*!
        動画画質方式を選択する LTMainMovieQualityPopup に表示するコンポーネントの組です (Built-in Data)
    */
    readonly property var recMovieBuiltIn: [
            {
                component: optionDetailWithImageButtonComponent,
                properties: {
                    type: "optionDetailWithRow"
                }
            }
    ]
// IVC << mod << end << USBTHRV160-26
     /*!
        movieFrameRate LTMainMovieQualityFilterPopup,LTMainMovieQualityFilterPopup に表示するコンポーネントの組です
     */
    readonly property var movieFrameRate: [
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MFR_ALL,
                optionText: qsTr("MQD_ALL")
            }
        },
    ]
    /*!
        movieBitRate LTMainMovieQualityFilterPopup,LTMainMovieQualityFilterPopup に表示するコンポーネントの組です
     */
     /*readonly property var movieBitRate: [
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MBR_ALL,
                optionText: qsTr("MQD_ALL")
            }
        },
    ]*/

    /*!
        moviePixel LTMainMovieQualityFilterPopup,LTMainMovieQualityFilterPopup に表示するコンポーネントの組です
     */
    readonly property var moviePixel: [
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_ALL,
                optionText: qsTr("MQD_ALL")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_6K_3_2_5952_3968,
                optionText: qsTr("MP_6K_3_2_5952_3968")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_5_9K_16_9_5888_3312,
                optionText: qsTr("MP_5_9K_16_9_5888_3312")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_5_4K_3_2_5376_3584,
                optionText: qsTr("MP_5_4K_3_2_5376_3584")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_ANAMO4K_4_3_3328_2496,
                optionText: qsTr("MP_ANAMO4K_4_3_3328_2496")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_C4K_17_9_4096_2160,
                optionText: qsTr("MP_C4K_17_9_4096_2160")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_4K_16_9_3840_2160,
                optionText: qsTr("MP_4K_16_9_3840_2160")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_ANAMO6K_52_39_4992_3744,
                optionText: qsTr("MP_ANAMO6K_52_39_4992_3744")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_QFHD_16_9_3840_2160,
                optionText: qsTr("MP_QFHD_16_9_3840_2160")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_FHD_16_9_1920_1080,
                optionText: qsTr("MP_FHD_16_9_1920_1080")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_HD_16_9_1280_720,
                optionText: qsTr("MP_HD_16_9_1280_720")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_WVGA_4_3_800_480,
                optionText: qsTr("MP_WVGA_4_3_800_480")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_VGA_4_3_640_480,
                optionText: qsTr("MP_VGA_4_3_640_480")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_QVGA_4_3_320_240,
                optionText: qsTr("MP_QVGA_4_3_320_240")
            }
        },
        //20秋FwUp
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_5K_4_3_4992_3744,
                optionText: qsTr("MP_5K_4_3_4992_3744")
            }
        },
        //20冬MC551FwUp
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_RAW4K_17_9_4096_2160,
                optionText: qsTr("MP_RAW4K_17_9_4096_2160")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_RAW3_7K_4_3_3680_2760,
                optionText: qsTr("MP_RAW3_7K_4_3_3680_2760")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_RAW3_5K_4_3_3536_2656,
                optionText: qsTr("MP_RAW3_5K_4_3_3536_2656")
            }
        },
        //MC8215
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_RAW5_9K_16_9_5888_3312,
                optionText: qsTr("MP_RAW5_9K_16_9_5888_3312")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_RAW4K_17_9_4128_2176,
                optionText: qsTr("MP_RAW4K_17_9_4128_2176")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_5_8K_4_3_5760_4320,
                optionText: qsTr("MP_5_8K_4_3_5760_4320")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_5_7K_17_9_5728_3024,
                optionText: qsTr("MP_5_7K_17_9_5728_3024")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_4_4K_4_3_4352_3264,
                optionText: qsTr("MP_4_4K_4_3_4352_3264")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_RAW4K_17_9_4128_2176,
                optionText: qsTr("MP_RAW4K_17_9_4128_2176")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_RAW3_7K_4_3_3680_2760,
                optionText: qsTr("MP_RAW3_7K_4_3_3680_2760")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_RAW3_5K_4_3_3536_2656,
                optionText: qsTr("MP_RAW3_5K_4_3_3536_2656")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_RAW5_8K_4_3_5760_4320,
                optionText: qsTr("MP_RAW5_8K_4_3_5760_4320")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_RAW5_7K_17_9_5728_3024,
                optionText: qsTr("MP_RAW5_7K_17_9_5728_3024")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_RAW4_4K_4_3_4352_3264,
                optionText: qsTr("MP_RAW4_4K_4_3_4352_3264")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_6K_17_9_5952_3136,
                optionText: qsTr("MP_6K_17_9_5952_3136")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_3_3K_4_3_3328_2496,
                optionText: qsTr("MP_3_3K_4_3_3328_2496")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_RAW4_1K_17_9_4128_2176,
                optionText: qsTr("MP_RAW4_1K_17_9_4128_2176")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_5_8K_17_9_5776_3056,
                optionText: qsTr("MP_5_8K_17_9_5776_3056")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_3_8K_3_2_3840_2560,
                optionText: qsTr("MP_3_8K_3_2_3840_2560")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_RAW6K_3_2_6000_4000,
                optionText: qsTr("MP_RAW6K_3_2_6000_4000")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_6K_24_1_1_5952_2512,
                optionText: qsTr("MP_6K_24_1_1_5952_2512")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_CS4K_24_1_1_4096_1728,
                optionText: qsTr("MP_CS4K_24_1_1_4096_1728")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_8_1K_3_2_8064_5376,
                optionText: qsTr("MP_8_1K_3_2_8064_5376")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_8_1K_17_9_8128_4288,
                optionText: qsTr("MP_8_1K_17_9_8128_4288")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_8K_16_9_7680_4320,
                optionText: qsTr("MP_8K_16_9_7680_4320")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_7_2K_3_2_7200_4800,
                optionText: qsTr("MP_7_2K_3_2_7200_4800")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_4_7K_4_3_4736_3552,
                optionText: qsTr("MP_4_7K_4_3_4736_3552")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_5_8K_17_9_5760_3040,
                optionText: qsTr("MP_5_8K_17_9_5760_3040")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_3_8K_4_3_3840_2880,
                optionText: qsTr("MP_3_8K_4_3_3840_2880")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_RAW4_8K_4_3_4800_3600,
                optionText: qsTr("MP_RAW4_8K_4_3_4800_3600")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_RAW8_1K_3_2_8128_5418,
                optionText: qsTr("MP_RAW8_1K_3_2_8128_5418")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_RAW8_1K_17_9_8128_4302,
                optionText: qsTr("MP_RAW8_1K_17_9_8128_4302")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_RAW7_2K_3_2_7232_4820,
                optionText: qsTr("MP_RAW7_2K_3_2_7232_4820")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_RAW4_8K_4_3_4752_3568,
                optionText: qsTr("MP_RAW4_8K_4_3_4752_3568")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_5_1K_3_2_5088_3392,
                optionText: qsTr("MP_5_1K_3_2_5088_3392")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_4_8K_4_3_4800_3600,
                optionText: qsTr("MP_4_8K_4_3_4800_3600")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MP_6_4K_3_2_6432_4288,
                optionText: qsTr("MP_6_4K_3_2_6432_4288")
            }
        },
    ]

    /*!
        movieCompressMethod LTMainMovieQualityFilterPopup,LTMainMovieQualityFilterPopup に表示するコンポーネントの組です
     */
    readonly property var movieCompressMethod: [
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MCPM_ALL,
                optionText: qsTr("MQD_ALL")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MCPM_422,
                optionText: qsTr("MCPM_422")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MCPM_420,
                optionText: qsTr("MCPM_420")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MCPM_10bit,
                optionText: qsTr("MCPM_10bit")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MCPM_8bit,
                optionText: qsTr("MCPM_8bit")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MCPM_LongGOP,
                optionText: qsTr("MCPM_LongGOP")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MCPM_ALL_I,
                optionText: qsTr("MCPM_ALL_I")
            }
        },
        //20冬MC551FwUp
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MCPM_16bit,
                optionText: qsTr("MCPM_16bit")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MCPM_RAW,
                optionText: qsTr("MCPM_RAW")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MCPM_RAWHQ,
                optionText: qsTr("MCPM_RAWHQ")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MCPM_422HQ,
                optionText: qsTr("MCPM_422HQ")
            }
        },
    ]

    /*!
        movieVFRFixed LTMainMovieQualityPopup に表示するコンポーネントの組です
     */
    readonly property var movieVFRFixed: [
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MVFR_ALL,
                optionText: qsTr("MQD_ALL")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MVFR_IMPOSSIBLE,
                optionText: qsTr("MQD_IMPOSSIBLE")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MVFR_POSSIBLE,
                optionText: qsTr("MQD_POSSIBLE")
            }
        },
    ]

    /*!
        movieVFR LTMainMovieQualityFilterPopup に表示するコンポーネントの組です
     */
    readonly property var movieVFR: [
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MVFR_ALL,
                optionText: qsTr("MQD_ALL")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MVFR_POSSIBLE,
                optionText: "ON"
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MVFR_IMPOSSIBLE,
                optionText: "OFF"
            }
        },
    ]

    /*!
        movieHLGFixed LTMainMovieQualityPopup に表示するコンポーネントの組です
     */
    readonly property var movieHLGFixed: [
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MHLG_ALL,
                optionText: qsTr("MQD_ALL")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MHLG_IMPOSSIBLE,
                optionText: qsTr("MQD_IMPOSSIBLE")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MHLG_POSSIBLE,
                optionText: qsTr("MQD_POSSIBLE")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MHLG_HDMI_ONLY_POSSIBLE,
                optionText: qsTr("MQD_HDMI_ONLY_POSSIBLE")
            }
        },
    ]


    /*!
        movieHLG LTMainMovieQualityFilterPopup に表示するコンポーネントの組です
     */
    readonly property var movieHLG: [
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MHLG_ALL,
                optionText: qsTr("MQD_ALL")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MHLG_POSSIBLE,
                optionText: "ON"
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MHLG_IMPOSSIBLE,
                optionText: "OFF"
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MHLG_HDMI_ONLY_POSSIBLE,
                optionText: qsTr("MQD_HDMI_ONLY_POSSIBLE")
            }
        },
    ]

    // IVC >> Ver.1.8 >> start >> No.3
    /*!
        movieSQ LTMainMovieQualityFilterPopup に表示するコンポーネントの組です
     */
    readonly property var movieSQ: [
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MSQ_IMPOSSIBLE,
                optionText: qsTr("-")
            }
        },
        {
            component: optionWithTextButtonComponent,
            properties: {
                type: "optionWithText",
                value: LT.Utilities.MSQ_POSSIBLE,
                optionText: qsTr("MQD_POSSIBLE")
            }
        },
    ]
    // IVC << Ver.1.8 << end << No.3

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

    /*!
        矩形のボタンを動的に生成するコンポーネントです　文字
     */
    readonly property Component optionWithTextButtonComponent: Component {
        LTRectangleButton {
            width: 165
            height: 36
            type: "optionWithText"
            property bool capable: false
        }
    }

    /*!
        LTMovieQualityButtonのボタンを動的に生成するコンポーネントです文字
     */
    readonly property Component optionDetailWithImageButtonComponent: Component {
        LTMovieQualityButton {
// IVC >> Ver.1.8 >> start >> No.3
            //width: 495
            width: 573
// IVC << Ver.1.8 << end << No.3
            height: 65

            type: "optionDetailWithRow"
            objectName: optionDetailWithImageButtonComponentName
            property bool capable: false
        }
    }
}
