import QtQuick 2.6

import "qrc:/qml"
import LT 1.0 as LT

/*! \qmltype LTOptionButton
    \inqmlmodule LT

    \brief
    状態を保持するボタンです

    LTOptionButtonPopup によって状態を選択する機能を提供します．
 */
LTRectangleButton {
    id: root

    /*!
        flashAdapter オブジェクト，ならびに LTOptionButton::componentsProvider のプロパティ名です
     */
    property string target
    onValueChanged: {
        //  状態を設定する
        flashAdapter[target] = value;
    }

    /*!
        状態を選択するポップアップ LTOptionButtonPopup です
     */
    property var popup

    /*!
        ポップアップに表示するコンポーネントの組を提供するオブジェクトです
     */
    property var componentsProvider

    function onOkSelected() {
//        //  状態と表示内容を設定する
//        root.value = object.value;
//        switch (object.type) {
//        case "optionWithImage":
//            root.source = object.source;
//            break;
//        case "optionWithText":
//            root.optionText = object.optionText;
//            break;
//        }
        //  ポップアップを非表示にする
        popup.dismiss();
    }

    function onCancelSelected() {
        //  ポップアップを非表示にする
        popup.dismiss();
    }

    onClicked: {
        //  コンポーネントのプロパティを設定する
        var components = componentsProvider[target];
        for (var i = 0; i < components.length; ++i) {
            //  状態に合わせて LTAbstractButton::checked を設定する
            components[i].properties.checked = (components[i].properties.value == value);
        }
        //  ポップアップの表示位置を決定する
        var preferX;
        var preferY;
        switch (type) {
        case "optionWithImage":
            preferX = parent.parent.x + x;
            preferY = parent.parent.y + y;
            break;
        case "optionWithText":
            preferX = parent.parent.width;
            preferY = parent.parent.y + y;
            break;
        }
        //  ポップアップを表示する
        popup.present(preferX, preferY, componentsProvider[target], onOkSelected(), onCancelSelected());
    }

    value: flashAdapter[target]

    type: "optionWithImage"
    fillColor: palette.backgroundDark

}
