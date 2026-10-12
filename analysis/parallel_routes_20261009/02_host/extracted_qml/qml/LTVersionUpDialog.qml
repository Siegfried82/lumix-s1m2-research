import QtQuick 2.6
import QtQuick.Window 2.3
import QtQuick.Controls 2.0
import QtQuick.Controls.Basic

import "qrc:/qml"
import LT 1.0 as LT
import "LTSubFunction.js" as LTSubFunction

/*! \qmltype LTVersionUpDialog

    \brief
    Version up Dialog
 */
//Dialog {
Window {
    id: root
    title: versionData.now_appName
    visible: false

    flags:
//        Qt.Window
        Qt.Dialog
      | Qt.CustomizeWindowHint
      | Qt.WindowTitleHint
//      | Qt.WindowSystemMenuHint
//      | Qt.WindowMinimizeButtonHint
//    | Qt.WindowMaximizeButtonHint
      | Qt. WindowCloseButtonHint
      | Qt.WindowStaysOnTopHint

    readonly property int pixel: 17

    width: utilities.isMac()? 700: 600
    height: 370

    //Windowサイズを変更できなくする
    minimumWidth: width
    minimumHeight: height
    maximumWidth: width
    maximumHeight: height

    /*!
        LiveViewの動画撮影ストップします。
     */
    signal versionUpExec()

//    contentItem: Rectangle {
    Rectangle {
//        color: "lightskyblue"
        color: "white"
        implicitWidth: utilities.isMac()? 700: 600
        implicitHeight: 370
        Image {
            id: importantImage
            x: 20
            y: 30
            width: 50
            height: 80
            visible: true
            fillMode: Image.Pad
        }
        LTStylishText {
            id: openText
            x: importantImage.x + importantImage.width + 3
            y: importantImage.y
            width: parent.width - 150
            height: 20

            type: text_style_verUpDlg
            visible: true
        }
        LTStylishText {
            id: nowVersionText
            x: openText.x + 30
            y: openText.y + openText.height + 3
            width: parent.width - 150
            height: openText.height

            type: text_style_verUpDlg
            visible: true
        }
        LTStylishText {
            id: newVersionText
            x: openText.x + 30
            y: nowVersionText.y + nowVersionText.height + 3
            width: parent.width - 150
            height: openText.height

            type: text_style_verUpDlg
            visible: true
        }
        LTStylishText {
            id: noticeText
            x: openText.x
            y: importantImage.y + importantImage.height + 10
            width: parent.width - 150
            height: questionText.y - importantImage.y - importantImage.height - 10

            type: text_style_verUpDlg
            visible: true
        }
        LTStylishText {
            id: questionText
            x: yesButton.x
            y: yesButton.y - 60
            width: parent.width - 150
            height: openText.height * 2

            type: text_style_verUpDlg
            visible: true
        }
        Button {
            id: yesButton
            x: (parent.width / 3) - (yesButton.width / 2)
            y: parent.height - yesButton.height - 10
            width: 150
            height: 40
            visible: true
            contentItem: Text {
                id: yesButtonText
                renderType: Text.NativeRendering
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                font: root.font
                text: qsTr("Yes_Button")
            }
            onClicked: {
                root.versionUpExec();
                root.visible = false
            }
        }
        Button {
            id: noButton
            x: ((2 * parent.width) / 3) - (noButton.width / 2)
            y: yesButton.y
            width: yesButton.width
            height: yesButton.height
            visible: true
            contentItem: Text {
                id: noButtonText
                renderType: Text.NativeRendering
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                font: root.font
                text: qsTr("No_Button")
            }
            onClicked: {
                root.visible = false
            }
        }
    }
    /*!
        フォントの属性です
     */
    property var font: {
        return Qt.font({
            "pixelSize": pixel,
            "family": utilities.getFontFamily(),
            "weight": Font.Bold
        });
    }

    Component.onCompleted: {
        versionData.update_xmlFileReadCompletedChanged.connect( root.onXmlFileReadCompleted );
        //dialogSetting();
        versionData.checkStart()
    }
    function onXmlFileReadCompleted() {
        dialogSetting();
    }
    function dialogSetting() {
        if(root.visible)
        {
            return;
        }
        if(versionData.update_xmlFileReadCompleted == true)
        {
            if(versionData.update_versionUpCheck == true)
            {
                root.visible = true

                // 重要度
                if (versionData.update_importance == LT.VersionData.VersionImportance_High) {
                    importantImage.source = "qrc:/images/496_level_high.png"
                } else if (versionData.update_importance == LT.VersionData.VersionImportance_Middle) {
                    importantImage.source = "qrc:/images/497_level_middle.png"
                } else if (versionData.update_importance == LT.VersionData.VersionImportance_Low) {
                    importantImage.source = "qrc:/images/498_level_low.png"
                }

                // 「アプリ名」のアップデートプログラムが公開されました。
                var str1_1 = qsTr("open_program_top")
                var str1_2 = versionData.now_appName
                var str1_3 = qsTr("open_program_bottom")
                openText.text = str1_1 + str1_2 + str1_3

                // 現在のバージョン : xx.xx
                var str2_1 = qsTr("now_version_top")
                var str2_2 = versionData.now_version
                var str2_3 = qsTr("now_version_bottom")
                nowVersionText.text = str2_1 + str2_2 + str2_3

                // 最新のバージョン : xx.xx
                var str3_1 = qsTr("new_version_top")
                var str3_2 = versionData.update_majorVersion
                var str3_3 = qsTr("new_version_sep1")
                var str3_4 = versionData.update_minorVersion
                //var str3_5 = qsTr("new_version_sep2")
                //var str3_6 = versionData.update_buildVersion
                //var str3_7 = qsTr("new_version_sep3")
                //var str3_8 = versionData.update_revision
                //var str3_9 = qsTr("new_version_bottom")
                newVersionText.text = str3_1 + str3_2 + str3_3 + str3_4// + str3_5 + str3_6 + str3_7 + str3_8 + str3_9

                // 通知文
                LTSubFunction.console_debug.out(versionData.update_notice);
                var notice = versionData.update_notice
                noticeText.text = "<HTML>" + replaceAll("\\n", "<br>", notice) + "</HTML>"

                // アプリケーションを終了して、今すぐダウンロードページを開きますか？
                var str4_1 = qsTr("open_web_page1")
                var str4_2 = qsTr("open_web_page2")
                questionText.text = "<HTML>" + str4_1 + "<br>" + str4_2 + "</HTML>"

                // はい
                yesButton.text = qsTr("Yes_Button")

                // いいえ
                noButton.text = qsTr("No_Button")
            }
            else
            {
                root.visible = false
            }
        }
        else
        {
            root.visible = false
        }
    }
    function replaceAll(find, replace, str) {
        while( str.indexOf(find) > -1)
        {
            str = str.replace(find, replace);
        }
        return str;
    }
}
