import QtQuick 2.0
import "LTSubFunction.js" as LTSubFunction

///AF枠ドラッグ時にドラッグできないエリアの表示

Item {
    id: root

    readonly property string bgColor: "#77777777"

    property real minX: 0
    property real minY: 0
    property real maxX: 0
    property real maxY: 0

    property real minDragX: 0
    property real minDragY: 0
    property real maxDragX: 0
    property real maxDragY: 0

    property real areaW: 0
    property real areaH: 0

    function dragFrameSetting(aw, ah, minx, maxx, miny, maxy) {
        LTSubFunction.console_debug.out("dragFrameSetting aw= "+aw+" ah= "+ah
                                        +" minx = "+minx+" miny= "+miny
                                        +" maxx ="+maxx+" maxy= "+maxy)
        root.areaH = ah
        root.areaW = aw

        root.minDragX = minx
        root.minDragY = miny
        root.maxDragX = maxx
        root.maxDragY = maxy

        root.dragFrameUpdate()
    }

    function dragFrameUpdate() {
        LTSubFunction.console_debug.out("dragFrameUpdate root.width = "+root.width
                                        +" root.height= "+root.height)

        root.minX = (root.minDragX - root.areaW/2) * afframe.width /1000
        root.minY = (root.minDragY - root.areaH/2) * afframe.height /1000
        root.maxX = (root.maxDragX + root.areaW/2) * afframe.width /1000
        root.maxY = (root.maxDragY + root.areaH/2) * afframe.height /1000

        top.x = 0
        top.y = 0
        top.width = afframe.width
        top.height = root.minY

        left.x = 0
        left.y = root.minY
        left.width = root.minX
        left.height = root.maxY-root.minY

        bottom.x = 0
        bottom.y = root.maxY
        bottom.width = afframe.width
        bottom.height = afframe.height - root.maxY

        right.x = root.maxX
        right.y = root.minY
        right.width = afframe.width - root.maxX
        right.height = root.maxY-root.minY
    }

    Component.onCompleted: {
    }

    Rectangle {
        id: top
        color: bgColor
    }

    Rectangle {
        id: left
        color: bgColor
    }

    Rectangle {
        id: bottom
        color: bgColor
    }

    Rectangle {
        id: right
        color: bgColor
    }

    Connections {
        target: imageLV

        function onSourceSizeChanged() {
            root.dragFrameUpdate()
        }
    }
}
