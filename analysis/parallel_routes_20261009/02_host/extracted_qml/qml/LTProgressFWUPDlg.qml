import QtQuick 2.2
import QtQuick.Controls 2.15
import QtQuick.Window 2.2

// IVC >> Ver.1.9 >> start >> No.3
Window {
    id: progressFWUPdlg
    x: Screen.width / 2 - progressFWUPdlg.width / 2
    y: Screen.height / 2 - progressFWUPdlg.height / 2
    maximumWidth: 600
    maximumHeight: 260
    minimumWidth: maximumWidth
    minimumHeight: maximumHeight

    flags:Qt.Window | Qt.CustomizeWindowHint | Qt.WindowTitleHint | Qt.WindowSystemMenuHint | Qt.MSWindowsFixedSizeDialogHint//| Qt. WindowCloseButtonHint
    modality: Qt.ApplicationModal

    title: "LUMIX Tether"
    visible: false

    readonly property var palette: {
        "dialogBackground": "#ffffff",
        "dialogButtonFieldBackground": "#f0f0f0",
        "dialogBorder": "#dfdfdf"

    }

    property alias dialogTitle: progressFWUPdlg.title

//    property alias dialogText: dialogText.text

    property alias dialogWidth: progressFWUPdlg.maximumWidth

    property alias dialogHeight: progressFWUPdlg.maximumHeight

//    property bool btnNoFocus

    function dismiss() {
        progressFWUPdlg.visible = false;
        progressFWUPdlg.destroy()
    }

    function setProgressFWUPText1(arg) {
        progressFWUPText1.text = arg
    }

    LTStylishText {
        id: progressFWUPText1
        x: progressFWUPdlg.width / 2 - progressFWUPText1.width / 2
        y: 30
//        font.bold : true
        //font.pointSize : 20
        type: text_style_wbmainProgressTitle
        horizontalAlignment: Text.AlignHCenter
        text: ""
    }

    function setProgressFWUPText2(arg) {
        progressFWUPText2.text = arg
    }
    LTStylishText {
        id: progressFWUPText2
        x: progressFWUPdlg.width / 2 - progressFWUPText2.width / 2
        y: progressFWUPText1.y + progressFWUPText1.height + 30
//        font.bold : true
        //font.pointSize : 16
        type: text_style_wbmainProgressContent
        text: ""
    }

    function setProgressFWUPBar(arg) {
        progressFWUPBar.value = arg
    }

    ProgressBar {
        id: progressFWUPBar
        x: (progressFWUPdlg.width) / 2 - progressFWUPBar.width / 2
        y: progressFWUPText2.y + progressFWUPText2.height + 25
        width: progressFWUPdlg.width - 100
        value: 0
        background: Rectangle {                                                 // 外枠エリア
            implicitWidth: progressFWUPBar.width
            implicitHeight: progressFWUPText2.height - 6
            color: "#e6e6e6"
            border.color: "#bcbcbc"
            border.width: 1
        }

        contentItem: Item {
            anchors.fill: parent
            anchors.margins: 1

            Rectangle {                                                         // full状態
                width: progressFWUPBar.visualPosition * parent.width
                height: parent.height
                color: "#17a81a"
                visible: !progressFWUPBar.indeterminate
            }

            Item {
                anchors.fill: parent
                anchors.margins: 1
                visible: progressFWUPBar.indeterminate
                clip: true
                Row {
                    spacing: 20
                    Repeater {
                        model: progressFWUPBar.width / 40 * 1

                        Rectangle {
                            color: "#17a81a"
                            width: 20
                            height: parent.height
                        }
                    }
                    XAnimator on x {
                        loops: Animation.Infinite
                        running: progressFWUPBar.indeterminate
                    }
                }
            }
        }
    }
}
// IVC >> Ver.1.9 >> start >> No.3
