import QtQuick 2.6
import QtQuick.Controls 2.1
import Qt5Compat.GraphicalEffects

import "qrc:/qml"
import LT 1.0 as LT

/*! \qmltype LTRectangleButton
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
            \li \tt action_left
            \li 右端にラベルのテキストを表示します
        \row
            \li \tt optionWithImage
            \li 中央に状態を示す画像を，左上にラベルのテキストを表示します
        \row
            \li \tt optionWithText
            \li 中央に左寄せでラベルのテキストを，右寄せで状態を示すテキストを表示します
        \row
            \li \tt checkableWithText
            \li 中央に左寄せで，LTAbstractButton::checked に応じて色が変化する，ラベルのテキストを表示します
        \row
            \li \tt checkableWithImage
            \li 中央に，LTAbstractButton::checked に応じて色が変化する，ラベルのアイコンを表示します
        \row
            \li \tt radioWithImage
            \li 中央に，LTAbstractButton::checked に応じて色が変化する，ラベルのアイコンを表示します
        \row
            \li \tt radioWithText
            \li 中央に，LTAbstractButton::checked に応じて色が変化する，ラベルのテキストを表示します
        \row
            \li \tt checkableWithImageAndText
            \li Image in right side and Text in left side change color with LTAbstractButton::checked
        \endtable
     */
    property string type: "action"

    /*!
        状態を示す値です
     */
    property var value

// IVC >> Ver.1.9 >> start >> Enhance Security
    property var value2
// IVC << Ver.1.9 << end << Enhance Security

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
        プルダウン用のImage
     */
    property string optionSource: ""

    /*!
        For check image
     */
    property alias checkedImage: checkedImg.source

    /*!
        For option image
     */
    property alias optionImage: optionImg.source
    property alias optionDisableImage: optionDisableImg.source
    property alias optionCheckedImage: optionCheckedImg.source

    property int option_string_top_margin: 30

    /*!
        テキストの色です
     */
    property color textColor: {
        if (type == "optionWithRichTextPs"
                // nakhuong >> start >> No.2
                || type == "optionWithTextRealPs"
                // nakhuong << end << No.2
                || type == "optionWithRichText"
                || type == "optionWithText"
                || type == "optionWithTextReal"
                || type == "optionWithTextPref"
                // IVC >> Ver.1.9 >> start >> No.1
                || type == "optionWithDynamicText"
                // IVC << Ver.1.9 << end << No.1
                || type == "optionWithImageAndText"
                || type == "optionWithImageAndTextPopup"
                || type == "optionWithStyledTextPs"
                || type == "optionWithStyledText"
                || type == "optionWithStyledTextRealPs"
                || type == "optionWithStyledTextReal"
                || type == "optionWithStyledTextPictureSize") {
//            return checked ? "#000000" : "#808080";
//            return checked ? "#dddddd" : "#dddddd"  // H.NAKANO
              return enabled ? (checked ? "#000000" : "#dddddd") : "#646464";
        } else {
//            return checked ? "#ffbf1f" : "#808080";
//            return checked ? "#dddddd" : "#dddddd"  // H.NAKANO
              return enabled ? (checked ? "#ffbf1f" : "#dddddd") : "#646464";
        }
    }

    //ISO、絞り、シャッタースピードでフォントサイズを個別に指定するため
    //targetでは継承して作られた方に存在しない可能性がある
    property int fontPixelSize : -1;

    /*!
        フォントの属性です
     */
    property var fontLabel: {
        switch (type) {
        case "action":
        case "optionWithImageAndText":
        case "optionWithImageAndTextPopup":
            return {
                "pixelSize": 12,
                "weight": Font.Bold,
                "family": utilities.getFontFamily(),
            };
        case "action_small":
            return {
                "pixelSize": 12,
                "weight": Font.Bold,
                "family": utilities.getFontFamily(),
            };
        case "action_smaller":
            return {
                "pixelSize": 10,
                "weight": Font.Bold,
                "family": utilities.getFontFamily(),
            };
        case "action_halfSize": // 半角用
            return {
                "pixelSize": 12,
                "weight": Font.Bold,
                "family": "Tahoma",
            };
// IVC >> Ver.1.9 >> start >> No.1
        case "action_noBold":
// IVC << Ver.1.9 << end << No.1
        case "action_left":
            return {
                "pixelSize": 12,
                "family": utilities.getFontFamily(),
            };
        case "optionWithImage":
        case "optionWithImagePopup":
            return {
                "pixelSize": 12,
                "family": utilities.getFontFamily(),
            };
        case "optionWithRichTextPs":
        // nakhuong >> start >> No.2
        case "optionWithTextRealPs":
        // nakhuong << end << No.2
        case "optionWithRichText":
        case "optionWithTextReal":
        case "optionWithRichSelectedText":
        case "optionWithStyledTextPs":
        case "optionWithStyledTextRealPs":
        case "optionWithStyledText":
        case "optionWithStyledTextReal":
        case "optionWithStyledTextPictureSize":
        case "optionWithStyledSelectedText":
            return {
                "pixelSize": 12,
                "family": utilities.getFontFamily(),
            };
        case "optionWithText":
        // IVC >> Ver.1.9 >> start >> No.1
        case "optionWithDynamicText":
        // IVC << Ver.1.9 << end << No.1
        case "optionWithTextPref":
            return {
                "pixelSize": 12,
                "family": utilities.getFontFamily(),
            };
        case "checkableWithText":
        case "radioWithText":
            return {
                "pixelSize": 13,
                "family": utilities.getFontFamily(),
            };
        case "checkableWithImage":
        case "radioWithImage":
            return {
                "pixelSize": 14,
                "family": utilities.getFontFamily(),
            };
        case "checkableWithImageAndText":
            return {
                "pixelSize": 14,
                "weight": Font.Bold,
                "family": utilities.getFontFamily(),
            };
        case "checkableWithImageAndTextLv":
            return {
                "pixelSize": 13,
                "weight": Font.Bold,
                "family": utilities.getFontFamily(),
            };
        case "optionWithImagetoText":
        case "optionWithImagetoTextCc":
        case "optionWithImagetoText_dm":
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
    property var fontButton: {
        switch (type) {
        case "action":
        case "optionWithImageAndText":
        case "optionWithImageAndTextPopup":
            return {
                "pixelSize": 13,
                "weight": Font.Bold,
                "family": utilities.getFontFamily(),
            };
        case "action_small":
            return {
                "pixelSize": 12,
                "weight": Font.Bold,
                "family": utilities.getFontFamily(),
            };
        case "action_smaller":
            return {
                "pixelSize": 10,
                "weight": Font.Bold,
                "family": utilities.getFontFamily(),
            };
        case "action_halfSize": // 半角用
            return {
                "pixelSize": 13,
                "weight": Font.Bold,
                "family": "Tahoma",
            };
// IVC >> Ver.1.9 >> start >> No.1
        case "action_noBold":
// IVC << Ver.1.9 << end << No.1
        case "action_left":
            return {
                "pixelSize": 13,
                "family": utilities.getFontFamily(),
            };
        case "optionWithImage":
        case "optionWithImagePopup":
            return {
                "pixelSize": 13,
                "family": utilities.getFontFamily(),
            };
        case "optionWithRichTextPs":
        // nakhuong >> start >> No.2
        case "optionWithTextRealPs":
        // nakhuong << end << No.2
        case "optionWithRichText":
        case "optionWithTextReal":
        case "optionWithRichSelectedText":
        case "optionWithStyledTextPs":
        case "optionWithStyledTextRealPs":
        case "optionWithStyledText":
        case "optionWithStyledTextReal":
        case "optionWithStyledTextPictureSize":
        case "optionWithStyledSelectedText":
            return {
                "pixelSize": 14,
                "family": utilities.getFontFamily(),
            };
        case "optionWithText":
        // IVC >> Ver.1.9 >> start >> No.1
        case "optionWithDynamicText":
        // IVC << Ver.1.9 << end << No.1
        case "optionWithTextPref":
            return {
                "pixelSize": 14,
            };
        case "checkableWithText":
            return {
                "pixelSize": 13,
                "family": utilities.getFontFamily(),
            };
        case "radioWithText":
            return {
                "pixelSize": 13,
                "family": utilities.getFontFamily(),
            };
        case "checkableWithImage":
        case "radioWithImage":
            return {
                "pixelSize": 14,
                "family": utilities.getFontFamily(),
            };
        case "checkableWithImageAndText":
            return {
                "pixelSize": 14,
                "weight": Font.Bold,
                "family": utilities.getFontFamily(),
            };
        case "checkableWithImageAndTextLv":
            return {
                "pixelSize": 13,
                "weight": Font.Bold,
                "family": utilities.getFontFamily(),
            };
        case "optionWithImagetoText":
        case "optionWithImagetoTextCc":
        case "optionWithImagetoText_dm":
            return {
                "pixelSize": 14,
                "family": utilities.getFontFamily(),
            };
        case "progress":
            return {
                "family": utilities.getFontFamily(),
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
        case "optionWithImageAndText":
        case "optionWithImageAndTextPopup":
            return {
                "pixelSize": 13,
                "weight": Font.Bold,
                "family": utilities.getFontFamily(),
            };
        case "action_small":
            return {
                "pixelSize": 12,
                "weight": Font.Bold,
                "family": utilities.getFontFamily(),
            };
        case "action_smaller":
            return {
                "pixelSize": 10,
                "weight": Font.Bold,
                "family": utilities.getFontFamily(),
            };
        case "action_halfSize": // 半角用
            return {
                "pixelSize": 13,
                "weight": Font.Bold,
                "family": "Tahoma",
            };
// IVC >> Ver.1.9 >> start >> No.1
        case "action_noBold":
// IVC << Ver.1.9 << end << No.1
        case "action_left":
            return {
                "pixelSize": 13,
                "family": utilities.getFontFamily(),
            };
        case "optionWithImage":
        case "optionWithImagePopup":
            return {
                "pixelSize": 13,
                "family": utilities.getFontFamily(),
            };
        case "optionWithRichTextPs":
        // ivc >> start >> USBTHRV140-45
//        // nakhuong >> start >> No.2
//        case "optionWithTextRealPs":
//        // nakhuong << end << No.2
        // ivc << end << USBTHRV140-45
        case "optionWithRichText":
            return {
                "pixelSize": 14,
                "family": utilities.getFontFamily(),
            };
        // ivc >> start >> USBTHRV140-45
        case "optionWithTextRealPs":
        // ivc << end << USBTHRV140-45
        case "optionWithTextReal":
        case "optionWithRichSelectedText":
            return {
                "pixelSize": 18,
                "weight": Font.Bold,
                "family": utilities.getFontFamily(),
            };
        case "optionWithText":
        // IVC >> Ver.1.9 >> start >> No.1
        case "optionWithDynamicText":
        // IVC << Ver.1.9 << end << No.1
        case "optionWithTextPref":
            return {
                "pixelSize": 13,
                "family": utilities.getFontFamily(),
            };
        case "checkableWithText":
        case "radioWithText":
            return {
                "pixelSize": 13,
                "family": utilities.getFontFamily(),
            };
        case "checkableWithImage":
        case "radioWithImage":
            return {
                "pixelSize": 14,
                "family": utilities.getFontFamily(),
            };
        case "checkableWithImageAndText":
            return {
                "pixelSize": 14,
                "weight": Font.Bold,
                "family": utilities.getFontFamily(),
            };
        case "checkableWithImageAndTextLv":
            return {
                "pixelSize": 13,
                "weight": Font.Bold,
                "family": utilities.getFontFamily(),
            };
        case "optionWithImagetoText":
        case "optionWithImagetoTextCc":
        case "optionWithImagetoText_dm":
            return {
                "pixelSize": 14,
                "family": utilities.getFontFamily(),
            };
        case "optionWithStyledTextPs":
        case "optionWithStyledText":
            return {
                "pixelSize": 17,
                "weight": Font.Bold,
                "family": utilities.getFontFamily(),
            };
        case "optionWithStyledTextRealPs":
        case "optionWithStyledTextReal":
        case "optionWithStyledSelectedText":
            if(fontPixelSize !== -1 ){
                //ISOで桁数増えて文字切れするものあるのでサイズを小さくする
                return {
                    "pixelSize": fontPixelSize,
                    "weight": Font.Bold,
                    "family": utilities.getFontFamily(),
                };
            }else{
                return {
                    "pixelSize": 21,
                    "weight": Font.Bold,
                    "family": utilities.getFontFamily(),
                };
            }
        case "optionWithStyledTextPictureSize":
            return {
                "pixelSize": 26,
                "weight": Font.Bold,
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
        label.font = Qt.font(fontLabel);
    }
    onFontButtonChanged: {
        button.font = Qt.font(fontButton);
    }
    onFontOptionChanged: {
        option.font = Qt.font(fontOption);
    }

    /*!
        境界線の角を丸める半径です
     */
    property alias radius: rectangle.radius

    /*
        チェックインジケータ

        LTAbstractButton::type が \tt checkableWithText, radioWithText の場合にのみ表示します
     */
    Rectangle {
        id: indicator
        visible: ((type == "checkableWithText")||(type == "radioWithText")) && checked
        x: 0
        y: 2
        z: 30
        width: 4
        height: parent.height - y * 2
        color: textColor
    }

    /*
        ラベルのテキスト
     */
    Text {
        id: label
        x: {
            switch (type) {
            case "optionWithImage":
            case "optionWithImagePopup":
            case "optionWithImageAndText":
            case "optionWithImageAndTextPopup":
                return 6;
            case "optionWithRichTextPs":
            // nakhuong >> start >> No.2
            case "optionWithTextRealPs":
            // nakhuong << end << No.2
            case "optionWithRichText":
            case "optionWithTextReal":
            case "optionWithRichSelectedText":
            case "optionWithStyledTextPs":
            case "optionWithStyledTextRealPs":
            case "optionWithStyledText":
            case "optionWithStyledTextReal":
            case "optionWithStyledTextPictureSize":
            case "optionWithStyledSelectedText":
                return 6;
            case "optionWithText":
            // IVC >> Ver.1.9 >> start >> No.1
            case "optionWithDynamicText":
            // IVC << Ver.1.9 << end << No.1
            case "optionWithTextPref":
                return 14;
            case "optionWithImagetoText":
            case "optionWithImagetoTextCc":
            case "optionWithImagetoText_dm":
                return 14;
            default:
                return 0;
            }
        }
        y: {
            switch (type) {
            case "optionWithImage":
            case "optionWithImagePopup":
            case "optionWithImageAndText":
            case "optionWithImageAndTextPopup":
                return 6;
            case "optionWithRichTextPs":
            // nakhuong >> start >> No.2
            case "optionWithTextRealPs":
            // nakhuong << end << No.2
            case "optionWithRichText":
            case "optionWithTextReal":
            case "optionWithRichSelectedText":
            case "optionWithStyledTextPs":
            case "optionWithStyledTextRealPs":
            case "optionWithStyledText":
            case "optionWithStyledTextReal":
            case "optionWithStyledTextPictureSize":
            case "optionWithStyledSelectedText":
                return 6;
            // IVC >> Ver.1.9 >> start >> No.1
            case "optionWithDynamicText":
            // IVC << Ver.1.9 << end << No.1
            case "optionWithText":
                return 0;
            case "optionWithTextPref":
                return parseInt((parent.height - label.height)/2);
            case "optionWithImagetoText":
            case "optionWithImagetoTextCc":
            case "optionWithImagetoText_dm":
                return 0;
            default:
                return 0;
            }
        }
        z: 30
        width: parent.width - x * 2
        //height: parent.height - y * 2
        color: textColor
        horizontalAlignment: {
            switch (type) {
            case "optionWithImage":
            case "optionWithImagePopup":
            case "optionWithImageAndText":
            case "optionWithImageAndTextPopup":
                return Text.AlignLeft;
            case "optionWithRichTextPs":
            // nakhuong >> start >> No.2
            case "optionWithTextRealPs":
            // nakhuong << end << No.2
            case "optionWithRichText":
            case "optionWithTextReal":
            case "optionWithRichSelectedText":
            case "optionWithStyledTextPs":
            case "optionWithStyledTextRealPs":
            case "optionWithStyledText":
            case "optionWithStyledTextReal":
            case "optionWithStyledTextPictureSize":
            case "optionWithStyledSelectedText":
                return Text.AlignLeft;
            case "optionWithText":
            // IVC >> Ver.1.9 >> start >> No.1
            case "optionWithDynamicText":
            // IVC << Ver.1.9 << end << No.1
            case "optionWithTextPref":
                return Text.AlignLeft;
            case "optionWithImagetoText":
            case "optionWithImagetoTextCc":
            case "optionWithImagetoText_dm":
                return Text.AlignLeft;
            default:
                return Text.AlignLeft;
            }
        }
        verticalAlignment: {
            switch (type) {
            case "optionWithImage":
            case "optionWithImagePopup":
            case "optionWithImageAndText":
            case "optionWithImageAndTextPopup":
                return Text.AlignTop;
            case "optionWithRichTextPs":
            // nakhuong >> start >> No.2
            case "optionWithTextRealPs":
            // nakhuong << end << No.2
            case "optionWithRichText":
            case "optionWithTextReal":
            case "optionWithRichSelectedText":
            case "optionWithStyledTextPs":
            case "optionWithStyledTextRealPs":
            case "optionWithStyledText":
            case "optionWithStyledTextReal":
            case "optionWithStyledTextPictureSize":
            case "optionWithStyledSelectedText":
                return Text.AlignTop;
            case "optionWithText":
            // IVC >> Ver.1.9 >> start >> No.1
            case "optionWithDynamicText":
            // IVC << Ver.1.9 << end << No.1
            case "optionWithTextPref":
                return Text.AlignVCenter;
            case "optionWithImagetoText":
            case "optionWithImagetoTextCc":
            case "optionWithImagetoText_dm":
                return Text.AlignVCenter;
            default:
                return Text.AlignTop;
            }
        }
        visible: {
            switch (type) {
            case "action":
            case "action_small":
            case "action_smaller":
            case "action_halfSize": // 半角用
// IVC >> Ver.1.9 >> start >> No.1
            case "action_noBold":
// IVC << Ver.1.9 << end << No.1
            case "action_left":
                return false;
            case "optionWithImage":
            case "optionWithImagePopup":
            case "optionWithRichTextPs":
            // nakhuong >> start >> No.2
            case "optionWithTextRealPs":
            // nakhuong << end << No.2
            case "optionWithRichText":
            case "optionWithRichSelectedText":
            case "optionWithText":
            case "optionWithTextReal":
            // IVC >> Ver.1.9 >> start >> No.1
            case "optionWithDynamicText":
            // IVC << Ver.1.9 << end << No.1
            case "optionWithTextPref":
            case "optionWithStyledTextPs":
            case "optionWithStyledText":
            case "optionWithStyledTextRealPs":
            case "optionWithStyledTextReal":
            case "optionWithStyledTextPictureSize":
            case "optionWithStyledSelectedText":
                return true;
            case "optionWithImageAndText":
            case "optionWithImageAndTextPopup":
                return false;
            case "checkableWithText":
            case "checkableWithImage":
            case "radioWithImage":
            case "radioWithText":
            case "checkableWithImageAndText":
            case "checkableWithImageAndTextLv":
                return false;
            case "optionWithImagetoText":
            case "optionWithImagetoTextCc":
            case "optionWithImagetoText_dm":
            default:
                return true;
            }
        }
        // font.family: "Arial"				// H.NAKANO
        // font.family: "Times New Roman"	// H.NAKANO
        // font.family: "Courier"			// H.NAKANO
        // font.family: "Verdana"			// H.NAKANO
        // font.family: "Tahoma"			// H.NAKANO
    }

    /*
        ボタンのテキスト
     */
    Text {
        id: button
        x: {
            switch (type) {
// IVC >> Ver.1.9 >> start >> No.1
            case "action_noBold":
// IVC << Ver.1.9 << end << No.1
            case "action":
            case "action_small":
            case "action_smaller":
            case "action_halfSize": // 半角用
                return 0;
            case "action_left":
                return 14;
            case "optionWithImage":
            case "optionWithImagePopup":
            case "optionWithImageAndText":
            case "optionWithImageAndTextPopup":
                return 6;
            case "optionWithRichTextPs":
            // nakhuong >> start >> No.2
            case "optionWithTextRealPs":
            // nakhuong << end << No.2
            case "optionWithRichText":
            case "optionWithTextReal":
            case "optionWithRichSelectedText":
            case "optionWithStyledTextPs":
            case "optionWithStyledTextRealPs":
            case "optionWithStyledText":
            case "optionWithStyledTextReal":
            case "optionWithStyledTextPictureSize":
            case "optionWithStyledSelectedText":
                return 6;
            case "optionWithText":
            // IVC >> Ver.1.9 >> start >> No.1
            case "optionWithDynamicText":
            // IVC << Ver.1.9 << end << No.1
            case "optionWithTextPref":
                return 14;
            case "checkableWithText":
            case "radioWithText":
                return 14;
            case "checkableWithImage":
            case "radioWithImage":
                return 14;
            case "checkableWithImageAndText":
            case "checkableWithImageAndTextLv":
                return 14;
            case "optionWithImagetoText":
            case "optionWithImagetoTextCc":
            case "optionWithImagetoText_dm":
                return 14;
            default:
                return 0;
            }
        }
        y: {
            switch (type) {
            case "action":
            case "action_small":
            case "action_smaller":
            case "action_halfSize": // 半角用
                return 0;
// IVC >> Ver.1.9 >> start >> No.1
            case "action_noBold":
// IVC << Ver.1.9 << end << No.1
            case "action_left":
                return 0;
            case "optionWithImage":
            case "optionWithImagePopup":
            case "optionWithImageAndText":
            case "optionWithImageAndTextPopup":
                return 6;
            case "optionWithRichTextPs":
            // nakhuong >> start >> No.2
            case "optionWithTextRealPs":
            // nakhuong << end << No.2
            case "optionWithRichText":
            case "optionWithTextReal":
            case "optionWithRichSelectedText":
            case "optionWithStyledTextPs":
            case "optionWithStyledTextRealPs":
            case "optionWithStyledText":
            case "optionWithStyledTextReal":
            case "optionWithStyledTextPictureSize":
            case "optionWithStyledSelectedText":
                return 6;
            case "optionWithText":
            // IVC >> Ver.1.9 >> start >> No.1
            case "optionWithDynamicText":
            // IVC << Ver.1.9 << end << No.1
            case "optionWithTextPref":
                return 0;
            case "checkableWithText":
            case "radioWithText":
                return 0;
            case "checkableWithImage":
            case "radioWithImage":
                return 0;
            case "checkableWithImageAndText":
            case "checkableWithImageAndTextLv":
                return 0;
            case "optionWithImagetoText":
            case "optionWithImagetoTextCc":
            case "optionWithImagetoText_dm":
                return 0;
            default:
                return 0;
            }
        }
        z: 30
        width: parent.width - x * 2
        height: parent.height - y * 2
        color: textColor
        horizontalAlignment: {
            switch (type) {
// IVC >> Ver.1.9 >> start >> No.1
            case "action_noBold":
// IVC << Ver.1.9 << end << No.1
            case "action":
            case "action_small":
            case "action_smaller":
            case "action_halfSize": // 半角用
                return Text.AlignHCenter;
            case "action_left":
                return Text.AlignLeft;
            case "optionWithImage":
            case "optionWithImagePopup":
                return Text.AlignLeft;
            case "optionWithRichTextPs":
            // nakhuong >> start >> No.2
            case "optionWithTextRealPs":
            // nakhuong << end << No.2
            case "optionWithRichText":
            case "optionWithTextReal":
            case "optionWithRichSelectedText":
            case "optionWithStyledTextPs":
            case "optionWithStyledTextRealPs":
            case "optionWithStyledText":
            case "optionWithStyledTextReal":
            case "optionWithStyledTextPictureSize":
            case "optionWithStyledSelectedText":
                return Text.AlignLeft;
            case "optionWithText":
            // IVC >> Ver.1.9 >> start >> No.1
            case "optionWithDynamicText":
            // IVC << Ver.1.9 << end << No.1
            case "optionWithTextPref":
                return Text.AlignLeft;
            case "checkableWithText":
            case "checkableWithImage":
            case "radioWithImage":
            case "radioWithText":
                return Text.AlignLeft;
            case "checkableWithImageAndText":
            case "checkableWithImageAndTextLv":
                return Text.AlignLeft;
            case "optionWithImagetoText":
            case "optionWithImagetoTextCc":
            case "optionWithImagetoText_dm":
                return Text.AlignLeft;
            default:
                return Text.AlignLeft;
            }
        }
        verticalAlignment: {
            switch (type) {
// IVC >> Ver.1.9 >> start >> No.1
            case "action_noBold":
// IVC << Ver.1.9 << end << No.1
            case "action":
            case "action_small":
            case "action_smaller":
            case "action_halfSize": // 半角用
                return Text.AlignVCenter;
            case "action_left":
                return Text.AlignVCenter;
            case "optionWithImage":
            case "optionWithImagePopup":
                return Text.AlignTop;
            case "optionWithRichTextPs":
            // nakhuong >> start >> No.2
            case "optionWithTextRealPs":
            // nakhuong << end << No.2
            case "optionWithRichText":
            case "optionWithTextReal":
            case "optionWithRichSelectedText":
            case "optionWithStyledTextPs":
            case "optionWithStyledTextRealPs":
            case "optionWithStyledText":
            case "optionWithStyledTextReal":
            case "optionWithStyledTextPictureSize":
            case "optionWithStyledSelectedText":
                return Text.AlignTop;
            case "optionWithText":
            // IVC >> Ver.1.9 >> start >> No.1
            case "optionWithDynamicText":
            // IVC << Ver.1.9 << end << No.1
            case "optionWithTextPref":
                return Text.AlignVCenter;
            case "checkableWithText":
            case "checkableWithImage":
            case "radioWithImage":
            case "radioWithText":
                return Text.AlignVCenter;
            case "checkableWithImageAndText":
            case "checkableWithImageAndTextLv":
                return Text.AlignVCenter;
            case "optionWithImagetoText":
            case "optionWithImagetoTextCc":
            case "optionWithImagetoText_dm":
                return Text.AlignVCenter;
            default:
                return Text.AlignTop;
            }
        }
        visible: {
            switch (type) {
            case "action":
            case "action_small":
            case "action_smaller":
            case "action_halfSize": // 半角用
// IVC >> Ver.1.9 >> start >> No.1
            case "action_noBold":
// IVC << Ver.1.9 << end << No.1
            case "action_left":
                return true;
            case "optionWithImage":
            case "optionWithImagePopup":
            case "optionWithImageAndText":
            case "optionWithImageAndTextPopup":
            case "optionWithRichTextPs":
            // nakhuong >> start >> No.2
            case "optionWithTextRealPs":
            // nakhuong << end << No.2
            case "optionWithRichText":
            case "optionWithRichSelectedText":
            case "optionWithText":
            case "optionWithTextReal":
            // IVC >> Ver.1.9 >> start >> No.1
            case "optionWithDynamicText":
            // IVC << Ver.1.9 << end << No.1
            case "optionWithTextPref":
            case "optionWithStyledTextPs":
            case "optionWithStyledText":
            case "optionWithStyledTextRealPs":
            case "optionWithStyledTextReal":
            case "optionWithStyledTextPictureSize":
            case "optionWithStyledSelectedText":
                return false;
            case "checkableWithText":
            case "checkableWithImageAndText":
            case "checkableWithImageAndTextLv":
            case "radioWithText":
                return true;
            case "checkableWithImage":
            case "radioWithImage":
                return false;
            case "optionWithImagetoText":
            case "optionWithImagetoTextCc":
            case "optionWithImagetoText_dm":
            default:
                return false;
            }
        }
        // font.family: "Arial"				// H.NAKANO
        // font.family: "Times New Roman"	// H.NAKANO
        // font.family: "Courier"			// H.NAKANO
        // font.family: "Verdana"			// H.NAKANO
        // font.family: "Tahoma"			// H.NAKANO
    }

    /*
        For checked image

        LTAbstractButton::type が \tt checkableWithImageAndText の場合にのみ表示します
     */
    Image {
        id: checkedImg
        visible: (type == "checkableWithImageAndText" || type == "checkableWithImageAndTextLv")
        z: 20

        anchors {
//            centerIn: parent
            verticalCenter: parent.verticalCenter
            right: parent.right
            rightMargin: 14
        }
    }

    /*
        For option image

        LTAbstractButton::type が \tt optionWithImageAndText の場合にのみ表示します
     */
    Image {
        id: optionImg
        visible: (type == "optionWithImageAndText" || type == "optionWithImageAndTextPopup")
        z: 20

        fillMode: Image.PreserveAspectFit
        anchors {
//            centerIn: parent
            verticalCenter: parent.verticalCenter
            right: option.left
            rightMargin: 6
        }
        height: parent.height
        width: {
            if (type == "optionWithImageAndTextPopup") {
                return parent.width - option.width - 6
            }

            return undefined
        }
    }
    Image {
        id: optionDisableImg
        visible: false

        z: 20

        //anchors.verticalCenter: optionImg.anchors.verticalCenter
        //anchors.right: optionImg.anchors.right
        //anchors.rightMargin: optionImg.anchors.rightMargin
        height: optionImg.height
        width: optionImg.width
        fillMode: optionImg.fillMode
        x: optionImg.x
        y: optionImg.y
        sourceSize: optionImg.sourceSize
    }
    Image {
        id: optionCheckedImg
        visible: false

        z: 20

        //anchors.verticalCenter: optionImg.anchors.verticalCenter
        //anchors.right: optionImg.anchors.right
        //anchors.rightMargin: optionImg.anchors.rightMargin
        height: optionImg.height
        width: optionImg.width
        fillMode: optionImg.fillMode
        x: optionImg.x
        y: optionImg.y
        sourceSize: optionImg.sourceSize
    }

    /*
        状態を示すテキスト

        LTAbstractButton::type が \tt optionWithText の場合にのみ表示します
     */
    Text {
        id: option
//        visible: (type == "optionWithText")||(type == "optionWithImagetoText")||(type == "optionWithImagetoTextCc")||(type == "optionWithImagetoText_dm")
        visible: (type == "optionWithText"
                  || type == "optionWithTextReal"
                  || type == "optionWithRichText"
                  || type == "optionWithRichTextPs"
                  // nakhuong >> start >> No.2
                  || type == "optionWithTextRealPs"
                  // nakhuong << end << No.2
                  || type == "optionWithRichSelectedText"
                  // IVC >> Ver.1.9 >> start >> No.1
                  || type == "optionWithDynamicText"
                  // IVC << Ver.1.9 << end << No.1
                  || type == "optionWithTextPref")
                 || ((type == "optionWithImage") && (source == ""))
                 || ((type == "optionWithImagePopup") && (source == ""))
                 || (type == "optionWithImageAndText")
                 || (type == "optionWithImageAndTextPopup")
                 || (type == "optionWithStyledTextPs")
                 || (type == "optionWithStyledText")
                 || (type == "optionWithStyledTextRealPs")
                 || (type == "optionWithStyledTextReal")
                 || (type == "optionWithStyledTextPictureSize")
                 || (type == "optionWithStyledSelectedText")
        x: {
            if (type == "optionWithImageAndTextPopup") {
                return parent.width/2
            } else if (type == "optionWithImageAndText") {
                return parent.width/2
            } else {
                return 14
            }
        }
        y: {
            if((type == "optionWithText" || type == "optionWithTextReal" || type == "optionWithRichSelectedText" ||
                type == "optionWithStyledTextReal" || type == "optionWithStyledTextPictureSize" || type == "optionWithStyledSelectedText") && (label.text != "")) {
                return option_string_top_margin
            } else if(type == "optionWithImage" || type == "optionWithImagePopup") {
                return 10
            } else {
                return 0
            }
        }
        z: 30
        width: {
            if (type == "optionWithImageAndText" || type == "optionWithImageAndTextPopup") {
                return parent.width - x - 6
            } else {
                return parent.width - x * 2
            }
        }
        height: {
            if((type == "optionWithText" || type == "optionWithTextReal" || type == "optionWithRichSelectedText" ||
                type == "optionWithStyledTextReal" || type == "optionWithStyledTextPictureSize" || type == "optionWithStyledSelectedText") && (label.text != "")) {
                return parent.height - option_string_top_margin
            } else {
                return parent.height
            }
        }
        color: textColor
        horizontalAlignment: {
            switch (type) {
            case "optionWithImage":
            case "optionWithImagePopup":
            case "optionWithRichTextPs":
            // nakhuong >> start >> No.2
            case "optionWithTextRealPs":
            // nakhuong << end << No.2
            case "optionWithRichText":
            case "optionWithTextReal":
            case "optionWithRichSelectedText":
            case "optionWithImageAndTextPopup":
            case "optionWithStyledTextPs":
            case "optionWithStyledTextRealPs":
            case "optionWithStyledText":
            case "optionWithStyledTextReal":
            case "optionWithStyledTextPictureSize":
            case "optionWithStyledSelectedText":
                return Text.AlignHCenter;
            // IVC >> Ver.1.9 >> start >> No.1
            case "optionWithDynamicText":
            // IVC << Ver.1.9 << end << No.1
            case "optionWithImageAndText":
                return Text.AlignLeft;
            default:
                return Text.AlignRight;
            }
        }

        verticalAlignment: Text.AlignVCenter

        textFormat: {
            switch (type) {
            //case "optionWithImageAndTextPopup":
            case "optionWithRichTextPs":
            // nakhuong >> start >> No.2
            case "optionWithTextRealPs":
            // nakhuong << end << No.2
            case "optionWithRichText":
            case "optionWithTextReal":
            case "optionWithRichSelectedText":
                return Text.RichText;
            case "optionWithImageAndTextPopup":
            case "optionWithStyledTextPs":
            case "optionWithStyledTextRealPs":
            case "optionWithStyledText":
            case "optionWithStyledTextReal":
            case "optionWithStyledTextPictureSize":
            case "optionWithStyledSelectedText":
                return Text.StyledText;
            default:
                return Text.AutoText;
            }
        }
    }
    /*
        境界線と背景ぬりつぶし
     */
    Rectangle {
        id: rectangle
        z: 10
        anchors {
            fill: parent
        }
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
            if (type == "checkableWithText" || type == "checkableWithImageAndText" || type == "checkableWithImageAndTextLv" || type == "checkableWithImage") {
                checked = !checked;
            }
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
        if(type == "optionWithImage" || type == "optionWithImagePopup") {
            if(!enabled) {
                mainEffect = true;
            }else{
                mainEffect = checked;
            }
        } else if ( (type == "action") || (type == "action_small") || (type == "action_smaller") || (type == "action_halfSize") || (type == "checkableWithImage" || type == "radioWithImage") ) {
            if(!enabled) {
                mainEffect = true;
            } else {
                mainEffect = false;
            }
        }
        if(type == "optionWithImage" || type == "optionWithImagePopup" ||
           type == "action" || type == "action_small" || type == "action_smaller" || (type == "action_halfSize") || type == "checkableWithImage" || type == "radioWithImage" ||
           type === "optionWithImagetoText") {
            if( mainEffect === true ){
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
        if(type == "optionWithImageAndText" || type == "optionWithImageAndTextPopup") {
            if(!enabled) {
                optionEffect = true;
            }else{
                optionEffect = checked;
            }

            if( optionEffect === true ){
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
            if(type == "optionWithImage" || type == "optionWithImagePopup") {
                if(!enabled) {
                    mainImg.visible = false;
                    return true;
                }
                mainImg.visible = !checked;
                return checked;
            } else if ( (type == "action") || (type == "action_small") || (type == "action_smaller") || (type == "action_halfSize") || (type == "checkableWithImage" || type == "radioWithImage") ) {
                if(!enabled) {
                    mainImg.visible = false;
                    return true;
                } else {
                    mainImg.visible = true;
                    return false;
                }
            }
            return false;
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
            if(type == "optionWithImageAndText" || type == "optionWithImageAndTextPopup") {
                if(!enabled) {
                    optionImg.visible = false;
                    return true;
                }
                optionImg.visible = !checked;
                return checked;
            }
            return false;
        }
    }

    /*!
        チェック状態の背景色
     */
    checkedColor: (type == "checkableWithText" || type == "radioWithText" || type == "checkableWithImageAndText" || type == "checkableWithImageAndTextLv" || type == "checkableWithImage" || type == "radioWithImage") ? "#00000000" : "#ffbf1f"

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
            logCol.log(logLevel, logScrTagID, logFile + " clicked", logText);
        }
    }
}
