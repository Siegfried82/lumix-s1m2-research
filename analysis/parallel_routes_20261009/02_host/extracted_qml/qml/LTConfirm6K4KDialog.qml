import QtQuick 2.2
import QtQuick.Controls 2.0
import LT 1.0 as LT

//MessageDialog {
LT.MessageBox{
    id: root
    modality: Qt.ApplicationModal
    icon: LT.StandardIcon.Question
    standardButtons: LT.StandardButton.Yes | LT.StandardButton.No
    title: "LUMIX Tether"
    visible: false

    function dismiss() {
        root.visible = false;
        root.destroy()
    }
}
