import QtQuick 2.0
import LT 1.0 as LT
import "LTSubFunction.js" as LTSubFunction

Item {
    id: root
    property real frame_width: root.width
    property real frame_height: root.height
    property real margin_x: 0
    property real margin_y: 0
    
    readonly property int mode_init:        0
    readonly property int mode_gray:        1
    readonly property int mode_lightgray:   2
    readonly property int mode_yellow:      3
    readonly property int mode_green:       4
    readonly property int mode_green_b:     5  // border
    readonly property int mode_num:         6
    property int mode: 0
    property int index: 0
    property variant frameType:
    [
        //'init' :
        {
            'value': mode_init, 'name': qsTr("init"),
            'rect_gray': false, 'rect_lightgray': false, 'rect_yellow': false, 'rect_green': false,
            'rect_green_b': false,
        },
        //'gray' :
        {
            'value': mode_gray, 'name': qsTr("gray"),
            'rect_gray': true, 'rect_lightgray': false, 'rect_yellow': false, 'rect_green': false,
            'rect_green_b': false,
        },
        //'lightgray' :
        {
            'value': mode_lightgray, 'name': qsTr("lightgray"),
            'rect_gray': false, 'rect_lightgray': true, 'rect_yellow': false, 'rect_green': false,
            'rect_green_b': false,
        },
        //'yellow' :
        {
            'value': mode_yellow, 'name': qsTr("yellow"),
            'rect_gray': false, 'rect_lightgray': false, 'rect_yellow': true, 'rect_green': false,
            'rect_green_b': false,
        },
        //'green' :
        {
            'value': mode_green, 'name': qsTr("green"),
            'rect_gray': false, 'rect_lightgray': false, 'rect_yellow': false, 'rect_green': true,
            'rect_green_b': false,
        },
        //'green_b' :
        {
            'value': mode_green_b, 'name': qsTr("green_b"),
            'rect_gray': false, 'rect_lightgray': false, 'rect_yellow': false, 'rect_green': false,
            'rect_green_b': true,
        },
    ];
    function changeMode(arg) {
        mode = arg
        if(frameType[mode].rect_gray) {
            gray_rect.visible = true
        } else {
            gray_rect.visible = false
        }
        if(frameType[mode].rect_lightgray) {
            lightgray_rect.visible = true
        } else {
            lightgray_rect.visible = false
        }
        if(frameType[mode].rect_yellow) {
            yellow_rect.visible = true
        } else {
            yellow_rect.visible = false
        }
        if(frameType[mode].rect_green) {
            green_rect.visible = true
        } else {
            green_rect.visible = false
        }
        if(frameType[mode].rect_green_b) {
            green_rect_b.visible = true
        } else {
            green_rect_b.visible = false
        }
    }
    Rectangle {
        id: gray_rect
        x: 1+margin_x
        y: 1+margin_y
        width: frame_width - 2
        height: frame_height - 2
        color: "transparent"
        border.color: "gray"
        border.width: 2
    }
    Rectangle {
        id: lightgray_rect
        x: 1+margin_x
        y: 1+margin_y
        width: frame_width - 2
        height: frame_height - 2
        color: "transparent"
        border.color: "lightgray"
        border.width: 2
    }
    Item {
        id: yellow_rect
        anchors.fill: parent
        Rectangle {
            x: margin_x
            y: margin_y
            width: frame_width
            height: frame_height
            color: "transparent"
            border.color: "black"
            border.width: 1
        }
        Rectangle {
            x: 1+margin_x
            y: 1+margin_y
            width: frame_width - 2
            height: frame_height - 2
            color: "transparent"
            //border.color: "yellow"
            border.color: LTSubFunction.afFrameColorPalette.yellow//"#FFD600"
            border.width: 2
        }
        Rectangle {
            x: 3+margin_x
            y: 3+margin_y
            width: frame_width - 6
            height: frame_height - 6
            color: "transparent"
            border.color: "black"
            border.width: 1
        }
    }
    Rectangle {
        id: green_rect
        x: margin_x
        y: margin_y
        width: frame_width
        height: frame_height
        color: "transparent"
        border.color: LTSubFunction.afFrameColorPalette.green//"green"
        border.width: 2
    }
    Item {
        id: green_rect_b
        anchors.fill: parent
        Rectangle {
            x: margin_x
            y: margin_y
            width: frame_width
            height: frame_height
            color: "transparent"
            border.color: "black"
            border.width: 1
        }
        Rectangle {
            x: 1+margin_x
            y: 1+margin_y
            width: frame_width - 2
            height: frame_height - 2
            color: "transparent"
            border.color: LTSubFunction.afFrameColorPalette.green//"green"
            border.width: 2
        }
        Rectangle {
            x: 3+margin_x
            y: 3+margin_y
            width: frame_width - 6
            height: frame_height - 6
            color: "transparent"
            border.color: "black"
            border.width: 1
        }
    }
}

/*
Image {
    id: root
    property int mode: 0
    source: "/r_g.svg"
    sourceSize.width: 30
    sourceSize.height: 20
    property variant frameType:
    [
        //'gray' :
        {
            'value': 0, 'name': qsTr("gray"),
            'color': "gray",
            'source': "/r_g.svg",
        },
        //'lightgray' :
        {
            'value': 1, 'name': qsTr("lightgray"),
            'color': "lightgray",
            'source': "/r_l.svg",
        },
        //'yellow' :
        {
            'value': 2, 'name': qsTr("yellow"),
            'color': "yellow",
            'source': "/r_y.svg",
        }
    ];
    function changeMode(arg) {
        mode = arg
        root.source = frameType[mode].source
    }
}
*/
