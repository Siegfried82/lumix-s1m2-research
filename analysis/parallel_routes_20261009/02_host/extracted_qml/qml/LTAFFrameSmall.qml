import QtQuick 2.0
import "LTSubFunction.js" as LTSubFunction

Item {
    id: root

    property int normal_width:              4
    readonly property int small_width:               2

    property int index: 0
    property int sm_mode: afmode_sm_init
    readonly property int afmode_sm_init:           0
    readonly property int afmode_sm_normal_green:   1
    readonly property int afmode_sm_small_yellow:   2
    readonly property int afmode_sm_both:           3
    readonly property int afmode_sm_num:            4
    property variant afmode_sm:
    [
        //'init' :
        {
            'value': afmode_sm_init, 'name': qsTr("init"),
            'normal_green': false, 'small_yellow': false
        },
        //'normal_green' :
        {
            'value': afmode_sm_normal_green, 'name': qsTr("normal_green"),
            'normal_green': true, 'small_yellow': false
        },
        //'small_yellow' :
        {
            'value': afmode_sm_small_yellow, 'name': qsTr("small_yellow"),
            'normal_green': false, 'small_yellow': true
        },
        //'both' :
        {
            'value': afmode_sm_both, 'name': qsTr("both"),
            'normal_green': true, 'small_yellow': true
        }
    ];

    property int outer_x: 0
    property int outer_y: 0
    property int outer_w: 0
    property int outer_h: 0

    property int mag_x: 0
    property int mag_y: 0
    property int mag_w: 0
    property int mag_h: 0

    Component.onCompleted: {
    }

    function changeMode(arg) {
        LTSubFunction.console_debug.out("LTAFFrameSmall changeMode arg="+arg)
        root.sm_mode = arg
        normal_green_disp.visible = afmode_sm[arg].normal_green
        small_yellow_disp.visible = afmode_sm[arg].small_yellow

        smallFrameUpdate()
    }

    function smallFrameUpdate(){
        // 2023/07 tsutsumi 枠がずれるので対処療法 画面が広い場合枠線も広げる
        root.x = (root.outer_x - root.outer_w/2) * afframe.width / 1000
        root.y = (small_frame.outer_y - small_frame.outer_h/2) * afframe.height / 1000
        root.width = root.outer_w * afframe.width / 1000
        root.height = root.outer_h * afframe.height / 1000

        if (afframe.width > 1000 )
        {
            normal_width = 8
            root.x -= 1;
            root.y -= 1;
            root.width += 3;
            root.height += 2;
        } else {
            normal_width = 5
            root.width += 1;
        }

        var magW = root.mag_w * afframe.width / 1000
        var magH = root.mag_h * afframe.height / 1000

        var magX = (root.mag_x - root.mag_w/2) * afframe.width / 1000 - root.x
        magX = magX < 0 ? 0 : magX
        magX = magX > root.width - magW ? root.width - magW : magX

        var magY = (root.mag_y - root.mag_h/2) * afframe.height / 1000 - root.y
        magY = magY < 0 ? 0 : magY
        magY = magY > root.height - magH ? root.height - magH : magY

        small_yellow_disp.x = magX
        small_yellow_disp.y = magY
        small_yellow_disp.width = magW
        small_yellow_disp.height = magH
    }

    //small_yellow
    Rectangle {
        id: small_yellow_disp
        visible: false

        color: "transparent"
        border.color: LTSubFunction.afFrameColorPalette.yellow//"yellow"
        border.width: small_width
    }

    //normal_green
    Rectangle {
        id: normal_green_disp

        anchors.fill: parent
        visible: false

        color: "transparent"
        border.color: LTSubFunction.afFrameColorPalette.green//"green"
        border.width: normal_width
    }

    Connections {
        target: afframe

        function onWidthChanged() {
            smallFrameUpdate()
        }

        function onHeightChanged() {
            smallFrameUpdate()
        }
    }
}
