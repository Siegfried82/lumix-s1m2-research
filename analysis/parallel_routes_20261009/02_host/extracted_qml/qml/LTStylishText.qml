import QtQuick 2.6

Text {

    /*!
        デザインを制御する値です

        \table
        \header
            \li 値
            \li 説明
        \row
            \li \tt normal
            \li 中央にラベルのテキストを表示します
        \row
            \li \tt header
            \li Text for header
        \row
            \li \tt buttonTitle
            \li Text for header
        \endtable
     */
    readonly property int text_style_normal:                000
    readonly property int text_style_header:                001
    readonly property int text_style_buttonTitle:           002
    readonly property int text_style_halfSize:              003 // 半角用

    readonly property int text_style_threeButton:           100

    readonly property int text_style_wbTuningTitle:         200
    readonly property int text_style_wbTuningLabel:         201
    readonly property int text_style_wbTuningText:          202

    readonly property int text_style_agreementTitle:        300
    readonly property int text_style_agreementContent:      301

    readonly property int text_style_preferSubline:         310
    readonly property int text_style_preferMark:            311

    readonly property int text_style_sliderTitle:           400
    readonly property int text_style_sliderValue:           401
    readonly property int text_style_sliderVal_pu:          402
    readonly property int text_style_sliderVal_ps:          403

    readonly property int text_style_connectionMsg:         500

    readonly property int text_style_liveViewLabel:         600
    readonly property int text_style_liveViewLabelHis:      601
    readonly property int text_style_liveViewDispTime:      602
    readonly property int text_style_liveViewCamOp:         603

    readonly property int text_style_mainProgressTitle:     700
    readonly property int text_style_mainProgressContent:   701
    // IVC >> MC893 >>
    readonly property int text_style_mainProgressSize:      702
    // IVC << MC893 <<

    readonly property int text_style_gridPopup10:           800
    readonly property int text_style_gridPopup12:           801
    readonly property int text_style_gridPopup14:           802
    readonly property int text_style_gridPopup16:           803
    readonly property int text_style_gridPopup20:           804

    readonly property int text_style_afFrameIndicator:      810

    readonly property int text_style_gLineIndicator:        820

    readonly property int text_style_gLinePopup10:          830
    readonly property int text_style_gLinePopup12:          831
    readonly property int text_style_gLinePopup14:          832
    readonly property int text_style_gLinePopup16:          833
    readonly property int text_style_gLinePopup22:          834
    readonly property int text_style_gLinePopup24:          835
    // ivc add >> start >> USBTHRV170-28
    readonly property int text_style_gLinePopup21:          836
    // ivc add << end << USBTHRV170-28

    readonly property int text_style_lvItemPopupTitle:      837

    readonly property int text_style_verUpDlg:              900

// ivc >> start >> No.8
    readonly property int text_style_liveViewBulbDispTime:  901
// ivc << end << No.8
// ivc >> start >> No.1
    readonly property int text_style_overlayPopup10:        902
    readonly property int text_style_overlayPopup12:        903
// ivc << end << No.1

// IVC >> Ver.1.9 >> start >> No.3
    readonly property int text_style_wbmainProgressTitle:     904
    readonly property int text_style_wbmainProgressContent:   905
// IVC << Ver.1.9 << end << No.3
// IVC >> Ver.1.9 >> start >> [THRBOXV100-152]
    readonly property int text_style_MovieQualityButton:        906
// IVC << Ver.1.9 << end << [THRBOXV100-152]

    property int type: text_style_normal

    /*!
        各部の描画色を定義するパレットです
     */
    readonly property var paletteText: {
        "backgroundDark": "#07090d",
        "backgroundLight": "#292b2d",
        "foregroundDark": "#808080",
        "foregroundLight": "#c6c6c6",
        "hovered": "#434343",
        "pressed": "#5c5c5c",
        "checked": "#000000",
        "unchecked": "#dddddd",
        "disabled": "#646464",

        "ligtGray": "#9c9c9c",
        "darkGray": "#505050",
        "white": "#ffffff",
        "black": "#000000",

    }

    font: {
        switch (type) {
        case text_style_normal:
        case text_style_wbTuningTitle:
        case text_style_wbTuningLabel:
        case text_style_agreementTitle:
        case text_style_agreementContent:
        case text_style_connectionMsg:
            return Qt.font({"pixelSize": 14, "family": utilities.getFontFamily()})

        case text_style_header:
        case text_style_wbTuningText:
            return Qt.font({"pixelSize": 18, "weight": Font.Bold, "family": utilities.getFontFamily()});

        case text_style_halfSize:
            return Qt.font({"pixelSize": 14, "family": "Tahoma"})

        case text_style_sliderValue:
        case text_style_sliderVal_pu:
        case text_style_sliderVal_ps:
        {
            // スライダーの値は分数表記のためText.textFormatはText.RichText。
            // 日本語は表示しないのでTahomaを指定。
            //   MacのQt5.9で日本語は、
            //     Tahomaだと線が細くて見えずらい。
            //     ヒラギノゴシックでRichTextだと中央に配置されない。上にずれる。
            if( isOpenGLMode === "false" ){
                return Qt.font({"pixelSize": 20, "weight": Font.Bold, "family": "Tahoma"});
//                return Qt.font({"pixelSize": 20, "weight": Font.Bold, "family": utilities.getFontFamily()});
            }else{
                return Qt.font({"pixelSize": 22, "weight": Font.Bold, "family": "Tahoma"});
//                return Qt.font({"pixelSize": 22, "weight": Font.Bold, "family": utilities.getFontFamily()});
            }
        }
        case text_style_sliderTitle:

        case text_style_threeButton:
            return Qt.font({"pixelSize": 12, "family": utilities.getFontFamily()})

        case text_style_preferSubline:
            return Qt.font({"pixelSize": 12, "family": utilities.getFontFamily()})

        case text_style_preferMark:
            return Qt.font({"pixelSize": 12, "family": utilities.getFontFamily()})

        case text_style_liveViewLabel:
        case text_style_liveViewLabelHis:
            return Qt.font({"pixelSize": 13, "family": utilities.getFontFamily()})
        case text_style_liveViewCamOp:
            return Qt.font({"pixelSize": 14, "family": utilities.getFontFamily()})
        case text_style_liveViewDispTime:
            return Qt.font({"pixelSize": 25, "family": utilities.getFontFamily()})
// ivc >> start >> No.8
        case text_style_liveViewBulbDispTime:
            return Qt.font({"pixelSize": 25, "family": utilities.getFontFamily()})
// ivc << end << No.8
        case text_style_mainProgressTitle:
            return Qt.font({"pixelSize": 35, "family": utilities.getFontFamily()})
        // IVC >> MC893 >>
        case text_style_mainProgressSize:
            return Qt.font({"pixelSize": 15, "family": utilities.getFontFamily()})
        // IVC << MC893 <<
        case text_style_mainProgressContent:
            return Qt.font({"pixelSize": 25, "family": utilities.getFontFamily()})

        case text_style_gridPopup10:
            return Qt.font({"pixelSize": 10, "family": utilities.getFontFamily()})
        case text_style_gridPopup12:
            return Qt.font({"pixelSize": 12, "family": utilities.getFontFamily()})
        case text_style_gridPopup14:
            return Qt.font({"pixelSize": 14, "family": utilities.getFontFamily()})
        case text_style_gridPopup16:
            return Qt.font({"pixelSize": 16, "family": utilities.getFontFamily()})
        case text_style_gridPopup20:
            return Qt.font({"pixelSize": 20, "family": utilities.getFontFamily()})

        case text_style_afFrameIndicator:
            return Qt.font({"pixelSize": 10, "family": utilities.getFontFamily()})
        case text_style_gLineIndicator:
            return Qt.font({"pixelSize": 16, "family": utilities.getFontFamily()})

        case text_style_gLinePopup10:
            return Qt.font({"pixelSize": 10, "family": utilities.getFontFamily()})
        case text_style_gLinePopup12:
            return Qt.font({"pixelSize": 12, "family": utilities.getFontFamily()})
        case text_style_gLinePopup14:
            return Qt.font({"pixelSize": 14, "family": utilities.getFontFamily()})
        case text_style_gLinePopup16:
            return Qt.font({"pixelSize": 16, "family": utilities.getFontFamily()})
        case text_style_gLinePopup22:
            return Qt.font({"pixelSize": 22, "family": utilities.getFontFamily()})
        case text_style_gLinePopup24:
            return Qt.font({"pixelSize": 24, "family": utilities.getFontFamily()})
        // ivc add >> start >> USBTHRV170-28
        case text_style_gLinePopup21:
            return Qt.font({"pixelSize": 21, "family": utilities.getFontFamily()})
        // ivc add << end << USBTHRV170-28

        case text_style_verUpDlg:
            return Qt.font({"pixelSize": 17, "family": utilities.getFontFamily()})
// ivc >> start >> No.1
        case text_style_overlayPopup10:
            return Qt.font({"pixelSize": 10, "family": utilities.getFontFamily()})
        case text_style_overlayPopup12:
            return Qt.font({"pixelSize": 12, "family": utilities.getFontFamily()})
// ivc << end << No.1
// IVC >> Ver.1.9 >> start >> No.3
        case text_style_wbmainProgressTitle:
            return Qt.font({"pixelSize": 35, "weight": Font.Bold, "family": utilities.getFontFamily()})
        case text_style_wbmainProgressContent:
            return Qt.font({"pixelSize": 25, "weight": Font.Bold, "family": utilities.getFontFamily()})
// IVC << Ver.1.9 << end << No.3
// IVC >> Ver.1.9 >> start >> [THRBOXV100-152]
        case text_style_MovieQualityButton:
            return Qt.font({"pixelSize": 11, "family": utilities.getFontFamily()})
// IVC << Ver.1.9 << end << [THRBOXV100-152]

        case text_style_lvItemPopupTitle:
            return Qt.font({"pixelSize": 14, "weight": Font.Bold, "family": utilities.getFontFamily()});

        default:
            return Qt.font({"pixelSize": 12, "family": utilities.getFontFamily()})
        }
    }


    color: {
        switch (type) {
            case text_style_normal:
            case text_style_header:
            case text_style_buttonTitle:
            case text_style_halfSize:
            case text_style_sliderTitle:
            case text_style_sliderValue:
            case text_style_sliderVal_pu:
            case text_style_sliderVal_ps:
            case text_style_threeButton:
                return paletteText.unchecked;
///////////////////////////
            case text_style_liveViewLabelHis:
                return paletteText.foregroundDark
            case text_style_liveViewCamOp:
            case text_style_liveViewDispTime:
                return paletteText.white
// ivc >> start >> No.8
            case text_style_liveViewBulbDispTime:
                return paletteText.white
// ivc << end << No.8
///////////////////////////
           case text_style_preferMark:
                return paletteText.darkGray
///////////////////////////
            case text_style_gridPopup10:
            case text_style_gridPopup12:
            case text_style_gridPopup14:
            case text_style_gridPopup16:
            case text_style_gridPopup20:

            case text_style_afFrameIndicator:

            case text_style_gLinePopup10:
            case text_style_gLinePopup12:
            case text_style_gLinePopup16:
            case text_style_gLinePopup22:
            case text_style_gLinePopup24:
            // ivc add >> start >> USBTHRV170-28
            case text_style_gLinePopup21:
            // ivc add << end << USBTHRV170-28
            case text_style_lvItemPopupTitle:
                return paletteText.ligtGray
///////////////////////////
            case text_style_gLineIndicator:
                return paletteText.white
///////////////////////////
// IVC >> Ver.1.9 >> start >> No.3
            case text_style_wbmainProgressTitle:
            case text_style_wbmainProgressContent:
// IVC << Ver.1.9 << end << No.3
// IVC >> Ver.1.9 >> start >> [THRBOXV100-152]
            case text_style_MovieQualityButton:
// IVC << Ver.1.9 << end << [THRBOXV100-152]
            case text_style_mainProgressTitle:
            case text_style_mainProgressSize:
            case text_style_mainProgressContent:
            case text_style_verUpDlg:
                return paletteText.black
            case text_style_connectionMsg:
                return paletteText.white
// ivc >> start >> No.1
            case text_style_overlayPopup10:
            case text_style_overlayPopup12:
                return paletteText.ligtGray
// ivc << end << No.1
            default:
                //console.debug("Stylish Text Undef " + text)
                return;
        }
    }

    horizontalAlignment: {
        switch (type) {
            case text_style_normal:
            case text_style_header:
            case text_style_buttonTitle:
            case text_style_halfSize:
            case text_style_threeButton:
            case text_style_agreementTitle:
            case text_style_agreementContent:
            case text_style_wbTuningTitle:
            case text_style_sliderTitle:
            case text_style_liveViewLabel:
            case text_style_liveViewLabelHis:
            case text_style_verUpDlg:
// IVC >> Ver.1.9 >> start >> [THRBOXV100-152]
            case text_style_MovieQualityButton:
// IVC << Ver.1.9 << end << [THRBOXV100-152]
                return Text.AlignLeft

            case text_style_sliderValue:
            case text_style_preferMark:
                return Text.AlignRight

            case text_style_sliderVal_pu:
            case text_style_sliderVal_ps:
            case text_style_wbTuningLabel:
            case text_style_wbTuningText:
            case text_style_connectionMsg:
                return Text.AlignHCenter
            default:
                return Text.AlignLeft
        }
    }

    verticalAlignment: {
        switch (type) {
            case text_style_sliderValue:
            case text_style_liveViewLabelHis:
                return Text.AlignTop

            case text_style_sliderVal_ps:
                return Text.AlignBottom

            case text_style_sliderVal_pu:
            case text_style_normal:
            case text_style_header:
            case text_style_buttonTitle:
            case text_style_halfSize:
            case text_style_threeButton:
            case text_style_agreementTitle:
            case text_style_agreementContent:
            case text_style_wbTuningTitle:
            case text_style_wbTuningLabel:
            case text_style_wbTuningText:
            case text_style_preferSubline:
            case text_style_sliderTitle:
            case text_style_connectionMsg:
            case text_style_liveViewLabel:
            case text_style_preferMark:
            case text_style_gridPopup12:
            case text_style_gLinePopup12:
            case text_style_verUpDlg:
// IVC >> Ver.1.9 >> start >> [THRBOXV100-152]
            case text_style_MovieQualityButton:
// IVC << Ver.1.9 << end << [THRBOXV100-152]
            default:
                return Text.AlignVCenter

        }
    }
}
