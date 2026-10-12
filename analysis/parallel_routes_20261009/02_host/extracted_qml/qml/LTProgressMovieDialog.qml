import QtQuick 2.2
import QtQuick.Window 2.2
import QtQuick.Controls 2.0

Window {
    id: progressMovieDlg
    x: Screen.width / 2 - progressMovieDlg.width / 2
    y: Screen.height / 2 - progressMovieDlg.height / 2
    // IVC >> MC893 >>
    width: 650
    height: 285                        // 2024/10 Qt6.5_障害一覧-41 ダイアログの高さ変更 280

    //Windowサイズを変更できなくする
    minimumWidth: width
    minimumHeight: height
    maximumWidth: width
    maximumHeight: height

    // IVC << MC893 <<
    flags: Qt.Window | Qt.CustomizeWindowHint | Qt.WindowTitleHint | Qt.WindowSystemMenuHint | Qt.MSWindowsFixedSizeDialogHint//| Qt. WindowCloseButtonHint

    modality: Qt.ApplicationModal
    //standardButtons: StandardButton.Cancel
    title: "LUMIX Tether"
    visible: false

    signal confirmCancelMovieDlg_showDialog(variant arg)
    signal confirmCancelMovieDlg_dismiss()

    function dismiss() {
        progressMovieDlg.visible = false;
        progressMovieDlg.destroy()
    }

    function setProgressMovieText1(arg) {
        progressMovieText1.text = arg
    }
    LTStylishText {
        id: progressMovieText1
        x: progressMovieDlg.width / 2 - progressMovieText1.width / 2
        y: 30
        //font.bold : true
        //font.pointSize : 20
        type: text_style_mainProgressTitle
        text: "" //qsTr("confirm_message_7")//"取り込み中"
    }
    function setProgressMovieText2(arg) {
        progressMovieText2.text = arg
    }
    LTStylishText {
        id: progressMovieText2
        x: progressMovieDlg.width / 2 - progressMovieText2.width / 2
        y: progressMovieText1.y + progressMovieText1.height + 20

        //font.pointSize : 16
        type: text_style_mainProgressContent
        text: "" //"(経過時間 転送済サイズ/全体サイズ)"
    }
    function setProgressMovieBar(arg) {
        progressMovieBar.value = arg
    }

    // IVC >> MC893 >>
    ProgressBar {
        id: progressMovieBar
        x: (progressMovieDlg.width - 100) / 2 - progressMovieBar.width / 2
        y: progressMovieText2.y + progressMovieText2.height + 20
        width: progressMovieDlg.width - 200
        value: 0
        background: Rectangle {                                                 // 外枠エリア
            implicitWidth: progressMovieBar.width
            implicitHeight: progressMovieTextSizeOne.height + 4
            color: "#e6e6e6"
            border.color: "#bcbcbc"
            border.width: 1
        }

        contentItem: Item {
            anchors.fill: parent
            anchors.margins: 1

            Rectangle {                                                         // full状態
                width: progressMovieBar.visualPosition * parent.width
                height: parent.height
                color: "#17a81a"
                visible: !progressMovieBar.indeterminate
            }

            Item {
                anchors.fill: parent
                anchors.margins: 1
                visible: progressMovieBar.indeterminate
                clip: true
                Row {
                    spacing: 20
                    Repeater {
                        model: progressMovieBar.width / 40 * 1

                        Rectangle {
                            color: "#17a81a"
                            width: 20
                            height: parent.height
                        }
                    }
                    XAnimator on x {
                        loops: Animation.Infinite
                        running: progressMovieBar.indeterminate
                    }
                }
            }
        }
    }

    LTStylishText {
        id: progressMovieTextSizeOne
        x: progressMovieBar.x + progressMovieBar.width + 5
        y: progressMovieBar.y + 2

        type: text_style_mainProgressSize
        text: ""
    }

    function setProgressMovieTextSizeOne(arg) {
        progressMovieTextSizeOne.text = arg
    }

    // Total progress bar
    function setProgressMovieBarTotal(arg) {
        progressMovieBarTotal.value = arg
    }
    ProgressBar {
        id: progressMovieBarTotal
        x: progressMovieBar.x
        y: progressMovieBar.y + progressMovieBar.height + 10
        width: progressMovieBar.width
        value: 0
        background: Rectangle {                                                 // 外枠エリア
            implicitWidth: progressMovieBar.width
            implicitHeight: progressMovieTextSizeAll.height + 4
            color: "#e6e6e6"
            border.color: "#bcbcbc"
            border.width: 1
        }

        contentItem: Item {
            anchors.fill: parent
            anchors.margins: 1

            Rectangle {                                                         // full状態
                width: progressMovieBarTotal.visualPosition * parent.width
                height: parent.height
                color: "#17a81a"
                visible: !progressMovieBarTotal.indeterminate
            }

            Item {
                anchors.fill: parent
                anchors.margins: 1
                visible: progressMovieBarTotal.indeterminate
                clip: true
                Row {
                    spacing: 20
                    Repeater {
                        model: progressMovieBarTotal.width / 40 * 1
                        Rectangle {
                            color: "#17a81a"
                            width: 20
                            height: parent.height
                        }
                    }
                    XAnimator on x {
                        loops: Animation.Infinite
                        running: progressMovieBarTotal.indeterminate
                    }
                }
            }
        }
    }

    LTStylishText {
        id: progressMovieTextSizeAll
        x: progressMovieBarTotal.x + progressMovieBarTotal.width + 5
        y: progressMovieBarTotal.y + 2

        type: text_style_mainProgressSize
        text: ""
    }

    function setProgressMovieTextSizeAll(arg) {
        progressMovieTextSizeAll.text = arg
    }

    LTStylishText {
        id: progressMovieTextTotalCount
        x: progressMovieBar.x + progressMovieBar.width - width
        y: progressMovieBarTotal.y + progressMovieBarTotal.height + 10

        type: text_style_mainProgressSize
        text: ""
    }

    function setMovieTextTotalCount(arg) {
        progressMovieTextTotalCount.text = arg
    }

    LTStylishText {
        id: progressMovieTextCurCount
        x: progressMovieTextTotalCount.x - width - 10
        y: progressMovieBarTotal.y + progressMovieBarTotal.height + 10

        type: text_style_mainProgressSize
        text: ""
    }

    function setProgressMovieTextCurCount(arg) {
        progressMovieTextCurCount.text = arg
    }

    LTStylishText {
        id: progressMovieTextFileCount
        x: progressMovieTextCurCount.x - width - 10
        y: progressMovieBarTotal.y + progressMovieBarTotal.height + 10

        type: text_style_mainProgressSize
        text: "" //"(ファイル数)"
    }

    function setProgressMovieTextFileCount(arg) {
        progressMovieTextFileCount.text = arg
    }
    // IVC << MC893 <<

    function setProgressMovieCancel(arg) {
        progressMovieCancel.text = arg
    }

    LTProgressButton {
        id: progressMovieCancel
        x: progressMovieDlg.width / 2 - progressMovieCancel.width / 2
        y: progressMovieDlg.height - progressMovieCancel.height - 10

        text: "" //qsTr("confirm_message_10")//"キャンセル"

        onClicked: {
            confirmCancelMovieDlg_showDialog(true)//confirmCancelMovieDlg1.visible = true
        }
    }
}
