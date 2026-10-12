import QtQuick 2.0
import LT 1.0 as LT
import "LTSubFunction.js" as LTSubFunction

Item {
    id: root
    
    readonly property int lineSize: 4
    readonly property int borderSize: 1
    property int frame_x_num: 21
    property int frame_y_num: 15
    property real frame_width: ((root.width - (lineSize * 2)) / frame_x_num)
    property real frame_height: ((root.height - (lineSize * 2)) / frame_y_num)

    property bool is_disp: false
    property int outer_mode: 0
    readonly property int afmode_outer_init:      0
    readonly property int afmode_outer_ellipse:   1
    readonly property int afmode_outer_vert:      2
    readonly property int afmode_outer_hori:      3
    readonly property int afmode_outer_vert_pdaf: 4
    readonly property int afmode_outer_hori_pdaf: 5
    readonly property int afmode_outer_num:       6
    property variant afmode_outer:
    [
        //'init' :
        {
            'value': afmode_outer_init, 'name': qsTr("init"),
            'ellipse': false, 'vert': false, 'hori': false,
            'vert_pdaf': false, 'hori_pdaf': false
        },
        //'ellipse' :
        {
            'value': afmode_outer_ellipse, 'name': qsTr("ellipse"),
            'ellipse': true, 'vert': false, 'hori': false,
            'vert_pdaf': false, 'hori_pdaf': false
        },
        //'vert' :
        {
            'value': afmode_outer_vert, 'name': qsTr("vert"),
            'ellipse': false, 'vert': true, 'hori': false,
            'vert_pdaf': false, 'hori_pdaf': false
        },
        //'hori' :
        {
            'value': afmode_outer_hori, 'name': qsTr("hori"),
            'ellipse': false, 'vert': false, 'hori': true,
            'vert_pdaf': false, 'hori_pdaf': false
        },
        //'vert_pdaf' :
        {
            'value': afmode_outer_vert_pdaf, 'name': qsTr("vert_pdaf"),
            'ellipse': false, 'vert': false, 'hori': false,
            'vert_pdaf': true, 'hori_pdaf': false
        },
        //'hori_pdaf' :
        {
            'value': afmode_outer_hori_pdaf, 'name': qsTr("hori_pdaf"),
            'ellipse': false, 'vert': false, 'hori': false,
            'vert_pdaf': false, 'hori_pdaf': true
        },
    ];

    // 外枠描画リクエスト
    function requestPaint() {
        if(root.outer_mode == afmode_outer_ellipse) {
            ellipse_disp.requestPaint()
        } else if(root.outer_mode == afmode_outer_vert) {
            vert_disp.requestPaint()
        } else if(root.outer_mode == afmode_outer_hori) {
            hori_disp.requestPaint()
        } else if(root.outer_mode == afmode_outer_vert_pdaf) {
            vert_pdaf_disp.requestPaint()
        } else if(root.outer_mode == afmode_outer_hori_pdaf) {
            hori_pdaf_disp.requestPaint()
        }
    }

    function changeDisp(flg) {
        // 外枠の表示/非表示設定
        root.is_disp = flg
        changeOuterVisible()
        requestPaint()
    }

     function changeMode(arg) {
         // 外枠のモード設定
        root.outer_mode = arg
        changeOuterVisible()
        requestPaint()
    }

    function changeSize(x_num, y_num) {
        // 外枠のサイズ計算
        ellipse_disp.width = (x_num * frame_width) + (lineSize * 2)
    }

    function changeCord(frameX, frameY) {
        // 外枠表示の開始位置計算
        ellipse_disp.x = frameX * frame_width
        ellipse_disp.y = frameY * frame_height
        hori_disp.y = frameY * frame_height
        vert_disp.x = frameX * frame_width
        hori_pdaf_disp.y = (frameY * frame_height) - (frame_height/2)
        vert_pdaf_disp.x = (frameX * frame_width) - (frame_width/2)
    }

    function changeOuterVisible() {
        // AFエリア表示なし
        if(!root.is_disp) {
            ellipse_disp.visible = false
            vert_disp.visible = false
            hori_disp.visible = false
        // AFエリア表示あり
        } else {
            ellipse_disp.visible = afmode_outer[root.outer_mode].ellipse
            vert_disp.visible = afmode_outer[root.outer_mode].vert
            hori_disp.visible = afmode_outer[root.outer_mode].hori
            vert_pdaf_disp.visible = afmode_outer[root.outer_mode].vert_pdaf
            hori_pdaf_disp.visible = afmode_outer[root.outer_mode].hori_pdaf
        }
    }

    // 楕円の上下の空白サイズ計算
    function calcBlankUDEllipse() {
        return ((frame_width * 68) / 32)
    }
    // 楕円の左右の空白サイズ計算
    function calcBlankLREllipse() {
        return ((frame_height * 68) / 32)
    }
    // 縦・横の上下の空白サイズ計算
    function calcBlankUDVertHori() {
        return ((frame_width * 20) / 32)
    }
    // 縦・横の左右の空白サイズ計算
    function calcBlankLRVertHori() {
        return ((frame_height * 20) / 32)
    }

    // 楕円
    Canvas {
        id: ellipse_disp
        x: 0
        y: 0
        width: frame_width * 7 + lineSize * 2
        height: frame_height * 5 + lineSize * 2
        visible: false

        onPaint: {
            // 座標計算
            var left_x1 = 0
            var left_x2 = lineSize
            var left_x3 = lineSize + frame_width
            var left_x4 = ((width - calcBlankUDEllipse()) / 2)
            var right_x1 = width - left_x4
            var right_x2 = width - lineSize - frame_width
            var right_x3 = width - lineSize
            var right_x4 = width
            var top_y1 = 0
            var top_y2 = lineSize
            var top_y3 = lineSize + frame_height
            var top_y4 = ((height - calcBlankLREllipse()) / 2)
            var bottom_y1 = height - top_y4
            var bottom_y2 = height - lineSize - frame_height
            var bottom_y3 = height - lineSize
            var bottom_y4 = height

            var ctx = ellipse_disp.getContext('2d');
            ctx.save();
            ctx.clearRect(0, 0, ellipse_disp.width, ellipse_disp.height);
            ctx.fillStyle = LTSubFunction.getAfFrameColor()//"white";
            ctx.lineWidth = borderSize;
            ctx.strokeStyle = "black"

            ctx.beginPath();

            //! lefttop
            ctx.moveTo(left_x3, top_y1);
            ctx.lineTo(left_x4, top_y1);
            ctx.lineTo(left_x4, top_y2);
            ctx.lineTo(left_x3, top_y2);
            ctx.lineTo(left_x2, top_y3);
            ctx.lineTo(left_x2, top_y4);
            ctx.lineTo(left_x1, top_y4);
            ctx.lineTo(left_x1, top_y3);
            ctx.lineTo(left_x3, top_y1);
            //! lefttop

            //! leftbottom
            ctx.moveTo(left_x3, bottom_y4);
            ctx.lineTo(left_x4, bottom_y4);
            ctx.lineTo(left_x4, bottom_y3);
            ctx.lineTo(left_x3, bottom_y3);
            ctx.lineTo(left_x2, bottom_y2);
            ctx.lineTo(left_x2, bottom_y1);
            ctx.lineTo(left_x1, bottom_y1);
            ctx.lineTo(left_x1, bottom_y2);
            ctx.lineTo(left_x3, bottom_y4);
            //! leftbottom

            //! righttop
            ctx.moveTo(right_x2, top_y1);
            ctx.lineTo(right_x1, top_y1);
            ctx.lineTo(right_x1, top_y2);
            ctx.lineTo(right_x2, top_y2);
            ctx.lineTo(right_x3, top_y3);
            ctx.lineTo(right_x3, top_y4);
            ctx.lineTo(right_x4, top_y4);
            ctx.lineTo(right_x4, top_y3);
            ctx.lineTo(right_x2, top_y1);
            //! righttop

            //! rightbottom
            ctx.moveTo(right_x2, bottom_y4);
            ctx.lineTo(right_x1, bottom_y4);
            ctx.lineTo(right_x1, bottom_y3);
            ctx.lineTo(right_x2, bottom_y3);
            ctx.lineTo(right_x3, bottom_y2);
            ctx.lineTo(right_x3, bottom_y1);
            ctx.lineTo(right_x4, bottom_y1);
            ctx.lineTo(right_x4, bottom_y2);
            ctx.lineTo(right_x2, bottom_y4);
            //! rightbottom

            ctx.closePath();

            ctx.fill();
            ctx.stroke();
            ctx.restore();
        }
    }
    // 横
    Canvas {
        id: hori_disp
        x: 0
        y: 0
        width: root.width
        height: frame_height + lineSize * 2
        visible: false

        onPaint: {
            // 座標計算
            var left_x1 = 0
            var left_x2 = lineSize
            var left_x3 = ((width - frame_width) / 2)
            var right_x1 = width - left_x3
            var right_x2 = width - lineSize
            var right_x3 = width
            var top_y1 = 0
            var top_y2 = lineSize
            var top_y3 = ((height - calcBlankLRVertHori()) / 2)
            var bottom_y1 = height - top_y3
            var bottom_y2 = height - lineSize
            var bottom_y3 = height

            var ctx = hori_disp.getContext('2d');
            ctx.save();
            ctx.clearRect(0, 0, hori_disp.width, hori_disp.height);
            ctx.fillStyle = LTSubFunction.getAfFrameColor()//"white";
            ctx.lineWidth = borderSize;
            ctx.strokeStyle = "black"

            ctx.beginPath();

            //! lefttop
            ctx.moveTo(left_x2, top_y1);
            ctx.lineTo(left_x3, top_y1);
            ctx.lineTo(left_x3, top_y2);
            ctx.lineTo(left_x2, top_y2);
            ctx.lineTo(left_x2, top_y3);
            ctx.lineTo(left_x1, top_y3);
            ctx.lineTo(left_x1, top_y2);
            ctx.lineTo(left_x2, top_y1);
            //! lefttop

            //! leftbottom
            ctx.moveTo(left_x2, bottom_y3);
            ctx.lineTo(left_x3, bottom_y3);
            ctx.lineTo(left_x3, bottom_y2);
            ctx.lineTo(left_x2, bottom_y2);
            ctx.lineTo(left_x2, bottom_y1);
            ctx.lineTo(left_x1, bottom_y1);
            ctx.lineTo(left_x1, bottom_y2);
            ctx.lineTo(left_x2, bottom_y3);
            //! leftbottom

            //! righttop
            ctx.moveTo(right_x2, top_y1);
            ctx.lineTo(right_x1, top_y1);
            ctx.lineTo(right_x1, top_y2);
            ctx.lineTo(right_x2, top_y2);
            ctx.lineTo(right_x2, top_y3);
            ctx.lineTo(right_x3, top_y3);
            ctx.lineTo(right_x3, top_y2);
            ctx.lineTo(right_x2, top_y1);
            //! righttop

            //! rightbottom
            ctx.moveTo(right_x2, bottom_y3);
            ctx.lineTo(right_x1, bottom_y3);
            ctx.lineTo(right_x1, bottom_y2);
            ctx.lineTo(right_x2, bottom_y2);
            ctx.lineTo(right_x2, bottom_y1);
            ctx.lineTo(right_x3, bottom_y1);
            ctx.lineTo(right_x3, bottom_y2);
            ctx.lineTo(right_x2, bottom_y3);
            //! rightbottom

            ctx.closePath();

            ctx.fill();
            ctx.stroke();
            ctx.restore();
        }
    }
    // 縦
    Canvas {
        id: vert_disp
        x: 0
        y: 0
        width: frame_width + lineSize * 2
        height: root.height
        visible: false

        onPaint: {
            // 座標計算
            var left_x1 = 0
            var left_x2 = lineSize
            var left_x3 = ((width - calcBlankUDVertHori()) / 2)
            var right_x1 = width - left_x3
            var right_x2 = width - lineSize
            var right_x3 = width
            var top_y1 = 0
            var top_y2 = lineSize
            var top_y3 = ((height - frame_height) / 2)
            var bottom_y1 = height - top_y3
            var bottom_y2 = height - lineSize
            var bottom_y3 = height

            var ctx = vert_disp.getContext('2d');
            ctx.save();
            ctx.clearRect(0, 0, vert_disp.width, vert_disp.height);
            ctx.fillStyle = LTSubFunction.getAfFrameColor()//"white";
            ctx.lineWidth = borderSize;
            ctx.strokeStyle = "black"

            ctx.beginPath();

            //! lefttop
            ctx.moveTo(left_x2, top_y1);
            ctx.lineTo(left_x3, top_y1);
            ctx.lineTo(left_x3, top_y2);
            ctx.lineTo(left_x2, top_y2);
            ctx.lineTo(left_x2, top_y3);
            ctx.lineTo(left_x1, top_y3);
            ctx.lineTo(left_x1, top_y2);
            ctx.lineTo(left_x2, top_y1);
            //! lefttop

            //! leftbottom
            ctx.moveTo(left_x2, bottom_y3);
            ctx.lineTo(left_x3, bottom_y3);
            ctx.lineTo(left_x3, bottom_y2);
            ctx.lineTo(left_x2, bottom_y2);
            ctx.lineTo(left_x2, bottom_y1);
            ctx.lineTo(left_x1, bottom_y1);
            ctx.lineTo(left_x1, bottom_y2);
            ctx.lineTo(left_x2, bottom_y3);
            //! leftbottom

            //! righttop
            ctx.moveTo(right_x2, top_y1);
            ctx.lineTo(right_x1, top_y1);
            ctx.lineTo(right_x1, top_y2);
            ctx.lineTo(right_x2, top_y2);
            ctx.lineTo(right_x2, top_y3);
            ctx.lineTo(right_x3, top_y3);
            ctx.lineTo(right_x3, top_y2);
            ctx.lineTo(right_x2, top_y1);
            //! righttop

            //! rightbottom
            ctx.moveTo(right_x2, bottom_y3);
            ctx.lineTo(right_x1, bottom_y3);
            ctx.lineTo(right_x1, bottom_y2);
            ctx.lineTo(right_x2, bottom_y2);
            ctx.lineTo(right_x2, bottom_y1);
            ctx.lineTo(right_x3, bottom_y1);
            ctx.lineTo(right_x3, bottom_y2);
            ctx.lineTo(right_x2, bottom_y3);
            //! rightbottom

            ctx.closePath();

            ctx.fill();
            ctx.stroke();
            ctx.restore();
        }
    }
    // 横(PDAF用)
    Canvas {
        id: hori_pdaf_disp
        x: 0
        y: 0
        width: root.width
        height: (frame_height * 2) + (lineSize * 2)
        visible: false

        onPaint: {
            // 座標計算
            var left_x1 = 0
            var left_x2 = lineSize
            var left_x3 = ((width - frame_width) / 2)
            var right_x1 = width - left_x3
            var right_x2 = width - lineSize
            var right_x3 = width
            var top_y1 = 0
            var top_y2 = lineSize
            var top_y3 = ((height - calcBlankLRVertHori()) / 2)
            var bottom_y1 = height - top_y3
            var bottom_y2 = height - lineSize
            var bottom_y3 = height

            var ctx = hori_pdaf_disp.getContext('2d');
            ctx.save();
            ctx.clearRect(0, 0, hori_pdaf_disp.width, hori_pdaf_disp.height);
            ctx.fillStyle = LTSubFunction.getAfFrameColor()//"white";
            ctx.lineWidth = borderSize;
            ctx.strokeStyle = "black"

            ctx.beginPath();

            //! lefttop
            ctx.moveTo(left_x2, top_y1);
            ctx.lineTo(left_x3, top_y1);
            ctx.lineTo(left_x3, top_y2);
            ctx.lineTo(left_x2, top_y2);
            ctx.lineTo(left_x2, top_y3);
            ctx.lineTo(left_x1, top_y3);
            ctx.lineTo(left_x1, top_y2);
            ctx.lineTo(left_x2, top_y1);
            //! lefttop

            //! leftbottom
            ctx.moveTo(left_x2, bottom_y3);
            ctx.lineTo(left_x3, bottom_y3);
            ctx.lineTo(left_x3, bottom_y2);
            ctx.lineTo(left_x2, bottom_y2);
            ctx.lineTo(left_x2, bottom_y1);
            ctx.lineTo(left_x1, bottom_y1);
            ctx.lineTo(left_x1, bottom_y2);
            ctx.lineTo(left_x2, bottom_y3);
            //! leftbottom

            //! righttop
            ctx.moveTo(right_x2, top_y1);
            ctx.lineTo(right_x1, top_y1);
            ctx.lineTo(right_x1, top_y2);
            ctx.lineTo(right_x2, top_y2);
            ctx.lineTo(right_x2, top_y3);
            ctx.lineTo(right_x3, top_y3);
            ctx.lineTo(right_x3, top_y2);
            ctx.lineTo(right_x2, top_y1);
            //! righttop

            //! rightbottom
            ctx.moveTo(right_x2, bottom_y3);
            ctx.lineTo(right_x1, bottom_y3);
            ctx.lineTo(right_x1, bottom_y2);
            ctx.lineTo(right_x2, bottom_y2);
            ctx.lineTo(right_x2, bottom_y1);
            ctx.lineTo(right_x3, bottom_y1);
            ctx.lineTo(right_x3, bottom_y2);
            ctx.lineTo(right_x2, bottom_y3);
            //! rightbottom

            ctx.closePath();

            ctx.fill();
            ctx.stroke();
            ctx.restore();
        }
    }
    // 縦(PDAF用)
    Canvas {
        id: vert_pdaf_disp
        x: 0
        y: 0
        width: (frame_width * 2) + (lineSize * 2)
        height: root.height
        visible: false

        onPaint: {
            // 座標計算
            var left_x1 = 0
            var left_x2 = lineSize
            var left_x3 = ((width - calcBlankUDVertHori()*2) / 2)
            var right_x1 = width - left_x3
            var right_x2 = width - lineSize
            var right_x3 = width
            var top_y1 = 0
            var top_y2 = lineSize
            var top_y3 = ((height - frame_height*2) / 2)
            var bottom_y1 = height - top_y3
            var bottom_y2 = height - lineSize
            var bottom_y3 = height

            var ctx = vert_pdaf_disp.getContext('2d');
            ctx.save();
            ctx.clearRect(0, 0, vert_pdaf_disp.width, vert_pdaf_disp.height);
            ctx.fillStyle = LTSubFunction.getAfFrameColor()//"white";
            ctx.lineWidth = borderSize;
            ctx.strokeStyle = "black"

            ctx.beginPath();

            //! lefttop
            ctx.moveTo(left_x2, top_y1);
            ctx.lineTo(left_x3, top_y1);
            ctx.lineTo(left_x3, top_y2);
            ctx.lineTo(left_x2, top_y2);
            ctx.lineTo(left_x2, top_y3);
            ctx.lineTo(left_x1, top_y3);
            ctx.lineTo(left_x1, top_y2);
            ctx.lineTo(left_x2, top_y1);
            //! lefttop

            //! leftbottom
            ctx.moveTo(left_x2, bottom_y3);
            ctx.lineTo(left_x3, bottom_y3);
            ctx.lineTo(left_x3, bottom_y2);
            ctx.lineTo(left_x2, bottom_y2);
            ctx.lineTo(left_x2, bottom_y1);
            ctx.lineTo(left_x1, bottom_y1);
            ctx.lineTo(left_x1, bottom_y2);
            ctx.lineTo(left_x2, bottom_y3);
            //! leftbottom

            //! righttop
            ctx.moveTo(right_x2, top_y1);
            ctx.lineTo(right_x1, top_y1);
            ctx.lineTo(right_x1, top_y2);
            ctx.lineTo(right_x2, top_y2);
            ctx.lineTo(right_x2, top_y3);
            ctx.lineTo(right_x3, top_y3);
            ctx.lineTo(right_x3, top_y2);
            ctx.lineTo(right_x2, top_y1);
            //! righttop

            //! rightbottom
            ctx.moveTo(right_x2, bottom_y3);
            ctx.lineTo(right_x1, bottom_y3);
            ctx.lineTo(right_x1, bottom_y2);
            ctx.lineTo(right_x2, bottom_y2);
            ctx.lineTo(right_x2, bottom_y1);
            ctx.lineTo(right_x3, bottom_y1);
            ctx.lineTo(right_x3, bottom_y2);
            ctx.lineTo(right_x2, bottom_y3);
            //! rightbottom

            ctx.closePath();

            ctx.fill();
            ctx.stroke();
            ctx.restore();
        }
    }
}
