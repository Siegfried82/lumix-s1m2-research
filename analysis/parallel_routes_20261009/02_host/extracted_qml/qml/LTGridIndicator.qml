import QtQuick 2.7

import "qrc:/qml"

/*! \qmltype LTGridIndicator
    \inqmlmodule LT

    \brief
    グリッドです
 */
Item {
    id: root
    //anchors.fill: parent
    //width: parent.width
    //height: parent.height
    ///*   対角線 グリッド　　　　*/
    //Rectangle {
    //    id:diagonal_linex
    //    anchors.centerIn: parent
    //    width: parent.width*1.5;
    //    height: lvGDraw_thickness;
    //    color:lvGDraw_color
    //    rotation: deviceAdapter.lvGDraw_diagonal_rotation
    //    visible:lvGDraw_Diagonal_on_off
    //}
    //Rectangle {
    //    id:diagonal_lineｙ
    //    anchors.centerIn: parent
    //    width: parent.width*1.5;
    //    height: lvGDraw_thickness;
    //    color:lvGDraw_color
    //    rotation: -deviceAdapter.lvGDraw_diagonal_rotation
    //    visible:lvGDraw_Diagonal_on_off
    //}
    Path {
        id: path
        startX: parseInt(lvGDraw_thickness/2)-1//-3
        startY: parseInt(lvGDraw_thickness/2)-1//355
        //PathQuad { x: 359; y:220; controlX: 175; controlY:238 }
        //PathQuad { x: 711; y:355; controlX: 533; controlY:238 }
        PathLine{ x: root.width - parseInt(lvGDraw_thickness/2) + 1; y: root.height - parseInt(lvGDraw_thickness/2) + 1 }
    }

    Path {
        id: path2
        startX: parseInt(lvGDraw_thickness/2)-1//-3
        startY: root.height - parseInt(lvGDraw_thickness/2)+1//355

        //PathQuad { x: 399; y:220; controlX: 196; controlY:238 }
        //PathQuad { x: 791; y:355; controlX: 592; controlY:238 }
        PathLine{ x: root.width - parseInt(lvGDraw_thickness/2) + 1; y: parseInt(lvGDraw_thickness/2) - 1 }
    }

    PathView {
        id:pathView1
        x: 0
        y: 0
        width: root.width - parseInt(lvGDraw_thickness)
        height: root.height - parseInt(lvGDraw_thickness)
        model: root.width - parseInt(lvGDraw_thickness)
        path: path
        delegate: Rectangle {
            id: dot;
            width: parseInt(lvGDraw_thickness/1.414)+1; height: parseInt(lvGDraw_thickness/1.414)+1;
            color: lvGDraw_color;
        }
        visible:lvGDraw_Diagonal_on_off
    }

    PathView {
        id: pathView2;
        x: 0
        y: 0
        width: root.width - parseInt(lvGDraw_thickness/2)
        height: root.height - parseInt(lvGDraw_thickness/2)
        model: root.width - parseInt(lvGDraw_thickness/2)
        path: path2
        delegate: Rectangle {
            id: dot2;
            width: parseInt(lvGDraw_thickness/1.414)+1; height: parseInt(lvGDraw_thickness/1.414)+1;
            color: lvGDraw_color;
        }
        visible:lvGDraw_Diagonal_on_off
    }

    /* 対角線終わり　*/

    /* 縦線 グリッド　　*/
    Row {
        id: lvgd_horizon
        visible:lvGDraw_horizontal_on_off
        width: parent.width
        height:parent.height
        spacing: parent.width/(lvGDraw_horizontal_Num+1)-lvGDraw_thickness-(lvGDraw_thickness/lvGDraw_horizontal_Num)
        x:parent.width/(lvGDraw_horizontal_Num+1)-((lvGDraw_thickness/lvGDraw_horizontal_Num)/2)

        Repeater {
            model: lvGDraw_horizontal_Num
            onItemAdded: {
            }
            Rectangle {width: lvGDraw_thickness;height: parent.height;color:lvGDraw_color}
        }
    }

    /* 横線 グリッド　　*/
    Column {
        id: lvgd_vertical
        visible:lvGDraw_Vertical_on_off
        width: parent.width
        height:parent.height
        spacing: parent.height/(lvGDraw_Vertical_Num+1)-lvGDraw_thickness-(lvGDraw_thickness/lvGDraw_Vertical_Num)
        y:parent.height/(lvGDraw_Vertical_Num+1)-((lvGDraw_thickness/lvGDraw_Vertical_Num)/2)
        Repeater {
            model: lvGDraw_Vertical_Num
            onItemAdded: {
            }
            Rectangle { width:parent.width;height: lvGDraw_thickness;color:lvGDraw_color}
        }
    }
}
