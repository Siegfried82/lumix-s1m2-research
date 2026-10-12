import QtQuick 2.0
import LT 1.0 as LT
import "LTSubFunction.js" as LTSubFunction

Item {
    id: root
    property real afframe_width: 0
    property real afframe_height: 0
    property int index: 0
    property int sq_mode: 0
    readonly property int afmode_sq_init:           0
    readonly property int afmode_sq_normal_white:   1
    readonly property int afmode_sq_normal_green:   2
    readonly property int afmode_sq_normal_red:     3
    readonly property int afmode_sq_normal_yellow:  4
    readonly property int afmode_sq_rect_white:     5
    readonly property int afmode_sq_rect_yellow:    6
    readonly property int afmode_sq_chase_white:    7
    readonly property int afmode_sq_chase_yellow:   8
    readonly property int afmode_sq_chase_green:    9
    readonly property int afmode_sq_chase_red:      10
    readonly property int afmode_sq_minimum_white:  11
    readonly property int afmode_sq_minimum_green:  12
    readonly property int afmode_sq_minimum_red:    13
    readonly property int afmode_sq_minimum_yellow: 14
    readonly property int afmode_sq_num:            15
    property variant afmode_sq:
    [
        //'init' :
        {
            'value': afmode_sq_init, 'name': qsTr("init"),
            'normal': false,
            'rect': false,
            'chase': false,
            'minimum': false,
            'frame_color': LTSubFunction.afFrameColorPalette.white//"white"
        },
        //'normal_white' :
        {
            'value': afmode_sq_normal_white, 'name': qsTr("normal_white"),
            'normal': true,
            'rect': false,
            'chase': false,
            'minimum': false,
            'frame_color': LTSubFunction.afFrameColorPalette.white//"white"
        },
        //'normal_green' :
        {
            'value': afmode_sq_normal_green, 'name': qsTr("normal_green"),
            'normal': true,
            'rect': false,
            'chase': false,
            'minimum': false,
            'frame_color': LTSubFunction.afFrameColorPalette.green//"green"
        },
        //'normal_red' :
        {
            'value': afmode_sq_normal_red, 'name': qsTr("normal_red"),
            'normal': true,
            'rect': false,
            'chase': false,
            'minimum': false,
            'frame_color': LTSubFunction.afFrameColorPalette.red//"red"
        },
        //'normal_yellow' :
        {
            'value': afmode_sq_normal_yellow, 'name': qsTr("normal_yellow"),
            'normal': true,
            'rect': false,
            'chase': false,
            'minimum': false,
            'frame_color': LTSubFunction.afFrameColorPalette.yellow//"yellow"
        },
        //'rect_white' :
        {
            'value': afmode_sq_rect_white, 'name': qsTr("rect_white"),
            'normal': false,
            'rect': true,
            'chase': false,
            'minimum': false,
            'frame_color': LTSubFunction.afFrameColorPalette.white//"white"
        },
        //'rect_yellow' :
        {
            'value': afmode_sq_rect_yellow, 'name': qsTr("rect_yellow"),
            'normal': false,
            'rect': true,
            'chase': false,
            'minimum': false,
            'frame_color': LTSubFunction.afFrameColorPalette.yellow//"yellow"
        },
        //'chase_white' :
        {
            'value': afmode_sq_chase_white, 'name': qsTr("chase_white"),
            'normal': false,
            'rect': false,
            'chase': true,
            'minimum': false,
            'frame_color': LTSubFunction.afFrameColorPalette.white//"white"
        },
        //'chase_yellow' :
        {
            'value': afmode_sq_chase_yellow, 'name': qsTr("chase_yellow"),
            'normal': false,
            'rect': false,
            'chase': true,
            'minimum': false,
            'frame_color': LTSubFunction.afFrameColorPalette.yellow//"yellow"
        },
        //'chase_green' :
        {
            'value': afmode_sq_chase_green, 'name': qsTr("chase_green"),
            'normal': false,
            'rect': false,
            'chase': true,
            'minimum': false,
            'frame_color': LTSubFunction.afFrameColorPalette.green//"green"
        },
        //'chase_red' :
        {
            'value': afmode_sq_chase_red, 'name': qsTr("chase_red"),
            'normal': false,
            'rect': false,
            'chase': true,
            'minimum': false,
            'frame_color': LTSubFunction.afFrameColorPalette.red//"red"
        },
        //'minimum_white' :
        {
            'value': afmode_sq_minimum_white, 'name': qsTr("minimum_white"),
            'normal': false,
            'rect': false,
            'chase': false,
            'minimum': true,
            'frame_color': LTSubFunction.afFrameColorPalette.white//"white"
        },
        //'minimum_green' :
        {
            'value': afmode_sq_minimum_green, 'name': qsTr("minimum_green"),
            'normal': false,
            'rect': false,
            'chase': false,
            'minimum': true,
            'frame_color': LTSubFunction.afFrameColorPalette.green//"green"
        },
        //'minimum_red' :
        {
            'value': afmode_sq_minimum_red, 'name': qsTr("minimum_red"),
            'normal': false,
            'rect': false,
            'chase': false,
            'minimum': true,
            'frame_color': LTSubFunction.afFrameColorPalette.red//"red"
        },
        //'minimum_yellow' :
        {
            'value': afmode_sq_minimum_yellow, 'name': qsTr("minimum_yellow"),
            'normal': false,
            'rect': false,
            'chase': false,
            'minimum': true,
            'frame_color': LTSubFunction.afFrameColorPalette.yellow//"yellow"
        },
    ];

    Component.onCompleted: {
    }

    function changeMode(arg) {
        LTSubFunction.console_debug.out("LTAFFrameSquare changeMode arg="+arg)
        root.sq_mode = arg
        if(arg === afmode_sq_init
                || arg === afmode_sq_normal_white
                || arg === afmode_sq_rect_white
                || arg === afmode_sq_chase_white
                || arg === afmode_sq_minimum_white
            ){
            //通常の白状態の場合は設定色を取得する
            frame_color = LTSubFunction.getAfFrameColor()
        }else{
            frame_color = afmode_sq[arg].frame_color
        }
        rect_disp.visible = afmode_sq[arg].rect
        chase_disp.visible = afmode_sq[arg].chase
        if(afmode_sq[arg].normal){
            onepoint_disp.minimum = false
            onepoint_disp.visible = true
            onepoint_disp.requestPaint()
        }else if(afmode_sq[arg].minimum){
            onepoint_disp.minimum = true
            onepoint_disp.visible = true
            onepoint_disp.requestPaint()
        }else{
            onepoint_disp.visible = false
        }
    }

    property string frame_color: LTSubFunction.afFrameColorPalette.white//"white"

    // normal, minimum
    Canvas {
        id: onepoint_disp
        x: 0
        y: 0
        width: root.width
        height: root.height
        visible: false
        property int lineSize: 4
        property real borderSize: 1.2
        property int width1: root.width / 3
        property int height1: root.height / 3
        property bool minimum: false
        property int miniLen: (width * 8 / 10 ) / 3
        property int offset: miniLen/2
        property int width2: miniLen
        property int height2: miniLen

        onPaint: {
            // 座標計算
            var left_x1 = 0
            var left_x2 = lineSize
            var left_x3 = width1
            var right_x1 = width - left_x3
            var right_x2 = width - lineSize
            var right_x3 = width
            var top_y1 = 0
            var top_y2 = lineSize
            var top_y3 = height1
            var bottom_y1 = height - top_y3
            var bottom_y2 = height - lineSize
            var bottom_y3 = height

            var ctx = onepoint_disp.getContext('2d');

            ctx.save();
            ctx.clearRect(0, 0, onepoint_disp.width, onepoint_disp.height);
            ctx.fillStyle = root.frame_color;
            ctx.globalAlpha = minimum ? 0.5 : 1.0
            ctx.lineWidth = borderSize;
            ctx.strokeStyle = "black"

            ctx.beginPath();
            //! lefttop
            ctx.moveTo(left_x1, top_y1);
            ctx.lineTo(left_x3, top_y1);
            ctx.lineTo(left_x3, top_y2);
            ctx.lineTo(left_x2, top_y2);
            ctx.lineTo(left_x2, top_y3);
            ctx.lineTo(left_x1, top_y3);
            ctx.lineTo(left_x1, top_y1);
            //! lefttop
            //! leftbottom
            ctx.moveTo(left_x1, bottom_y3);
            ctx.lineTo(left_x3, bottom_y3);
            ctx.lineTo(left_x3, bottom_y2);
            ctx.lineTo(left_x2, bottom_y2);
            ctx.lineTo(left_x2, bottom_y1);
            ctx.lineTo(left_x1, bottom_y1);
            ctx.lineTo(left_x1, bottom_y3);
            //! leftbottom
            //! righttop
            ctx.moveTo(right_x3, top_y1);
            ctx.lineTo(right_x1, top_y1);
            ctx.lineTo(right_x1, top_y2);
            ctx.lineTo(right_x2, top_y2);
            ctx.lineTo(right_x2, top_y3);
            ctx.lineTo(right_x3, top_y3);
            ctx.lineTo(right_x3, top_y1);
            //! righttop
            //! rightbottom
            ctx.moveTo(right_x3, bottom_y3);
            ctx.lineTo(right_x1, bottom_y3);
            ctx.lineTo(right_x1, bottom_y2);
            ctx.lineTo(right_x2, bottom_y2);
            ctx.lineTo(right_x2, bottom_y1);
            ctx.lineTo(right_x3, bottom_y1);
            ctx.lineTo(right_x3, bottom_y3);
            //! rightbottom
            ctx.closePath();

            ctx.fill();
            ctx.stroke();
            ctx.restore();

            // 最小表示
            if(minimum){
                var center_x = width/2 - lineSize/2
                var center_y = height/2 - lineSize/2
                var center_top = height/2 - height2 - offset
                var center_bottom = height - center_top - height2
                var center_left = width/2 - width2 - offset
                var center_right = width - center_left - width2

                ctx.save();
                ctx.fillStyle = root.frame_color;
                ctx.globalAlpha = 1.0
                ctx.lineWidth = borderSize;
                ctx.strokeStyle = "black"

                ctx.beginPath();
                ctx.rect(center_x, center_top, lineSize, height2) // top
                ctx.rect(center_x, center_bottom, lineSize, height2) // bottom
                ctx.rect(center_left, center_y, width2, lineSize) // left
                ctx.rect(center_right, center_y, width2, lineSize) // right
                ctx.closePath();

                ctx.fill();
                ctx.stroke();
                ctx.restore();
            }
        }
    }

    //rect
    Item {
        id: rect_disp
        visible: false
        Rectangle {
            id: rect_rect1
            x: 0//root.x
            y: 0//root.y
            width: root.width
            height: root.height
            color: "transparent"
            border.width: 4
            border.color: "black"
        }
        Rectangle {
            id: rect_rect2
            x: 1//root.x
            y: 1//root.y
            width: root.width - 2
            height: root.height - 2
            color: "transparent"
            border.width: 2
            border.color: root.frame_color
        }
    }

    //chase
    Item {
        id: chase_disp
        visible: false
        Rectangle {
            id: chase_lefttop_1
            x:0
            y:0
            width: root.width / 3
            height: 4
            color: root.frame_color
            border.width: 1
            border.color: "black"
        }
        Rectangle {
            id: chase_lefttop_2
            x:0
            y:0
            width: 4
            height: root.height / 3
            color: root.frame_color
            border.width: 1
            border.color: "black"
        }
        Rectangle {
            id: chase_lefttop_3
            x:1
            y:1
            color: root.frame_color
            width: root.width / 3 - 2
            height: 2
        }

        Rectangle {
            id: chase_leftbottom_1
            x:0
            y:(2*root.height)/3
            width: 4
            height: root.height / 3
            color: root.frame_color
            border.width: 1
            border.color: "black"
        }
        Rectangle {
            id: chase_leftbottom_2
            x:0
            y:root.height-4
            width: root.width/3
            height: 4
            color: root.frame_color
            border.width: 1
            border.color: "black"
        }
        Rectangle {
            id: chase_leftbottom_3
            x:1
            y:(2*root.height)/3+1
            color: root.frame_color
            width: 2
            height: root.height/3 - 2
        }

        Rectangle {
            id: chase_righttop_1
            x:(2*root.width)/3
            y:0
            width: root.width / 3
            height: 4
            color: root.frame_color
            border.width: 1
            border.color: "black"
        }
        Rectangle {
            id: chase_righttop_2
            x:root.width-4
            y:0
            width: 4
            height: root.height/3
            color: root.frame_color
            border.width: 1
            border.color: "black"
        }
        Rectangle {
            id: chase_righttop_3
            x:(2*root.width)/3+1
            y:1
            color: root.frame_color
            width: root.width/3 - 2
            height: 2
        }

        Rectangle {
            id: chase_rightbottom_1
            x:(2*root.width)/3
            y:root.height-4
            width: root.width / 3
            height: 4
            color: root.frame_color
            border.width: 1
            border.color: "black"
        }
        Rectangle {
            id: chase_rightbottom_2
            x:root.width-4
            y:(2*root.height)/3
            width: 4
            height: root.height / 3
            color: root.frame_color
            border.width: 1
            border.color: "black"
        }
        Rectangle {
            id: chase_rightbottom_3
            x:(2*root.width)/3+1
            y:root.height-3
            color: root.frame_color
            width: root.width / 3 - 2
            height: 2
        }

        Rectangle {
            id: chase_centertop
            x: root.width/2 - chase_centertop.width/2
            y: -10
            width: 4
            height: 20
            color: root.frame_color
            border.width: 1
            border.color: "black"
        }
        Rectangle {
            id: chase_centerbottom
            x: root.width/2 - chase_centerbottom.width/2
            y: root.height - 10
            width: 4
            height: 20
            color: root.frame_color
            border.width: 1
            border.color: "black"
        }
        Rectangle {
            id: chase_centerleft
            x: -10
            y: root.height/2 - chase_centerleft.height/2
            width: 20
            height: 4
            color: root.frame_color
            border.width: 1
            border.color: "black"
        }
        Rectangle {
            id: chase_centerright
            x: root.width - 10
            y: root.height/2 - chase_centerright.height/2
            width: 20
            height: 4
            color: root.frame_color
            border.width: 1
            border.color: "black"
        }
    }
}
