import QtQuick 2.2
import QtQuick.Window 2.2
import QtQuick.Controls 2.0

Window {
    id: progress6K4KDlg
    x: Screen.width / 2 - progress6K4KDlg.width / 2
    y: Screen.height / 2 - progress6K4KDlg.height / 2
    width: 600
    height: 230
    flags: Qt.Window | Qt.CustomizeWindowHint | Qt.WindowTitleHint | Qt.WindowSystemMenuHint | Qt.MSWindowsFixedSizeDialogHint//| Qt. WindowCloseButtonHint

    //Windowサイズを変更できなくする
    minimumWidth: width
    minimumHeight: height
    maximumWidth: width
    maximumHeight: height

    modality: Qt.ApplicationModal
    //standardButtons: StandardButton.Cancel
    title: "LUMIX Tether"
    visible: false

    signal confirmCancel6K4KDlg_showDialog(variant arg)
    signal confirmCancel6K4KDlg_dismiss()

    function dismiss() {
        progress6K4KDlg.visible = false;
        progress6K4KDlg.destroy()
    }

    function setProgress6K4KText1(arg) {
        progress6K4KText1.text = arg
    }
    LTStylishText {
        id: progress6K4KText1
        x: progress6K4KDlg.width / 2 - progress6K4KText1.width / 2
        y: 30
        //font.bold : true
        //font.pointSize : 20
        type: text_style_mainProgressTitle
        text: "" //qsTr("confirm_message_7")//"取り込み中"
    }
    function setProgress6K4KText2(arg) {
        progress6K4KText2.text = arg
    }
    LTStylishText {
        id: progress6K4KText2
        x: progress6K4KDlg.width / 2 - progress6K4KText2.width / 2
        y: progress6K4KText1.y + progress6K4KText1.height + 20

        //font.pointSize : 16
        type: text_style_mainProgressContent
        text: "" //"(経過時間 転送済サイズ/全体サイズ)"
    }
    function setProgress6K4KBar(arg) {
        progress6K4KBar.value = arg
    }

    ProgressBar {
        id: progress6K4KBar
        x: progress6K4KDlg.width / 2 - progress6K4KBar.width / 2
        y: progress6K4KText2.y + progress6K4KText2.height + 20
        width: progress6K4KDlg.width - 100
        value: 0
        background: Rectangle {                                                 // 外枠エリア
            implicitWidth: progress6K4KDlg.width
            implicitHeight: progress6K4KText2.height - 6
            color: "#e6e6e6"
            border.color: "#bcbcbc"
            border.width: 1
        }

        contentItem: Item {
            anchors.fill: parent
            anchors.margins: 1

            Rectangle {                                                         // full状態
                width: progress6K4KBar.visualPosition * parent.width
                height: parent.height
                color: "#17a81a"
                visible: !progress6K4KBar.indeterminate
            }

            Item {
                anchors.fill: parent
                anchors.margins: 1
                visible: progress6K4KBar.indeterminate
                clip: true
                Row {
                    spacing: 20
                    Repeater {
                        model: progress6K4KBar.width / 40 * 1
                        Rectangle {
                            color: "#17a81a"
                            width: 20
                            height: parent.height
                        }
                    }
                    XAnimator on x {
                        loops: Animation.Infinite
                        running: progress6K4KBar.indeterminate
                    }
                }
            }
        }
    }
    function setProgress6K4KCancel(arg) {
        progress6K4KCancel.text = arg
    }

    LTProgressButton {
        id: progress6K4KCancel
        x: progress6K4KDlg.width / 2 - progress6K4KCancel.width / 2
        y: progress6K4KDlg.height - progress6K4KCancel.height - 10

        text: "" //qsTr("confirm_message_10")//"キャンセル"

        onClicked: {
            confirmCancel6K4KDlg_showDialog(true)//confirmCancel6K4KDlg1.visible = true
        }
    }
}
