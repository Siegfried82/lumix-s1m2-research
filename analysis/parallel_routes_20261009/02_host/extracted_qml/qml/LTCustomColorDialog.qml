import QtQuick 2.2
import QtQuick.Controls 2.0
import Qt.labs.platform 1.0

ColorDialog {
    id: colorDialog
    title: "Please choose a color"
    //modality: Qt::WindowModality
    modality: Qt.ApplicationModal

    signal colorChanged()

    signal onCancelClicked()

    function cancel() {
        colorDialog.onCancelClicked();
        colorDialog.dismiss();
    }
    function dismiss() {
        visible = false;
        if(!utilities.isMac()) {
            colorDialog.destroy()
        }
    }

    onAccepted: {
        //console.log("You chose: " + colorDialog.color)
        colorDialog.colorChanged()
        if(!utilities.isMac()) {
            colorDialog.destroy()
        }
        //Qt.quit()
    }
    onRejected: {
        //console.log("Canceled")
        if(!utilities.isMac()) {
            colorDialog.destroy()
        }
        //Qt.quit()
    }
    Component.onCompleted: visible = false
}
