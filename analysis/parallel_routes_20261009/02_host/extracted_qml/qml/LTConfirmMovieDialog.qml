import QtQuick 2.2
import QtQuick.Controls 2.0
import LT 1.0 as LT

//LabPlat.MessageDialog {
LT.MessageBox{

// IVC >> Ver.1.9 >> start >> [THRBOXV100-157]
    signal movieRecStatusUpdate()
// IVC << Ver.1.9 << end << [THRBOXV100-157]

    id: root
// IVC >> Ver.1.9 >> start >> [THRBOXV100-157]
    //modality: Qt.ApplicationModal
    modality: (deviceAdapter.msgDisplayed) ? Qt.WindowModal : Qt.ApplicationModal
// IVC << Ver.1.9 << end << [THRBOXV100-157]
    icon: LT.StandardIcon.Question
    standardButtons: LT.StandardButton.Yes | LT.StandardButton.No
    title: "LUMIX Tether"
    visible: false
    property int movieHandle: 0
    property double objectAddDataSize: 0
    //property int objectAddDataSize: 0

    function dismiss() {
        root.visible = false;
        root.destroy()
    }
// IVC >> Ver.1.9 >> start >> [THRBOXV100-157]
    onVisibleChanged: {
        if(root.visible === false) {
            root.movieRecStatusUpdate();
        }
    }
// IVC << Ver.1.9 << end << [THRBOXV100-157]
}

