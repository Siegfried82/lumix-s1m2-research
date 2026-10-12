import QtQuick
import QtQml 2.2

Timer {
    id: root
    interval: 100
    running: false
    signal finishTimer()
    onTriggered: {
        root.finishTimer()
    }
}
