import QtQuick 2.7

import "qrc:/qml"
import "LTSubFunction.js" as LTSubFunction

/*! \qmltype LTGuideLineIndicator
    \inqmlmodule LT

    \brief
    ガイドラインです
 */
Item {
    id: root
    //anchors.fill: parent

    property int line_horizontal1_pos:25              //5.縦１本目位置　0～99％　　　	    初期値 25
    property int line_horizontal2_pos:75              //6.縦2本目位置 0～99％	        初期値 75
    property int line_Vertical1_pos:25                //7.横１本目位置　0～99％　　　	    初期値 25
    property int line_Vertical2_pos:75                 //8.横2本目位置 0～99％	        初期値 75

    DropArea {
        id: view_droparea
        anchors.fill: parent

        MouseArea {
            id: view_mousearea
            anchors.fill: parent
        }

        visible: false

        onDropped: {
//          console.log("dropped:" + drag.x + "," + drag.y + "," + drag.source);
            view_mousearea.cursorShape = Qt.ArrowCursor
            view_mousearea.visible = false
        }
        onEntered: {
//          console.log("entered:" + drag.x + "," + drag.y);
        }
        onExited: {
//          console.log("exited:" + "," + view_droparea.drag.source);
        }
        onPositionChanged: {
//          console.log("positionChanged:" + drag.x + "," + drag.y + "," + view_droparea.drag.source);
        }
    }
    Rectangle {
        id: line1
        x: parseInt((view_droparea.width*lvGuideLine_horizontal1_pos)/100) + ((view_droparea.width*lvGuideLine_horizontal1_pos) % 100 ? 1: 0)
        y: 0
        width: lvGuideLine_thickness
        height: view_droparea.height
        visible: lvGuideLine_horizontal1_on_off
        color: lvGuideLine_color
        Drag.active: line1_dragarea.drag.active
        MouseArea {
            id: line1_dragarea
            anchors.fill: parent
            drag.target: parent
            drag.axis: Drag.XAxis
            drag.minimumX: 0
            drag.maximumX: view_droparea.width
            cursorShape:Qt.SizeHorCursor
            hoverEnabled: true

            onPressed: {
                //LTSubFunction.console_debug.out("line1 onPressed")
                view_mousearea.visible = true
                view_mousearea.cursorShape = Qt.SizeHorCursor
                 line1_percent_dsp.visible=true
            }
            onReleased:{
                //LTSubFunction.console_debug.out("line1 onReleased")
                parent.Drag.drop();
                view_mousearea.cursorShape = Qt.ArrowCursor
                view_mousearea.visible = false
                line1_percent_dsp.visible=false
                lvGuideLine_horizontal1_pos=line1.x/root.width*100
            }
            onEntered: {
                //LTSubFunction.console_debug.out("line1 onEntered")
                line1_percent_dsp.visible=true
            }
            onMouseXChanged:{
                //LTSubFunction.console_debug.out("line1 onMouseXChanged")
                line_horizontal1_pos=parseInt((line1.x*100)/root.width)
                line1_percent_dsp.visible=true
            }
            onExited: {
                //LTSubFunction.console_debug.out("line1 onExited")
                line1_percent_dsp.visible=false
            }
        }
    }
    Rectangle {
        id: line2
        x: parseInt((view_droparea.width*lvGuideLine_horizontal2_pos)/100) + ((view_droparea.width*lvGuideLine_horizontal2_pos) % 100 ? 1: 0)
        y: 0
        width: lvGuideLine_thickness
        height: view_droparea.height
        visible: lvGuideLine_horizontal2_on_off
        color: lvGuideLine_color
        Drag.active: line2_dragarea.drag.active

        MouseArea {
            id: line2_dragarea
            anchors.fill: parent
            drag.target: parent
            drag.axis: Drag.XAxis
            drag.minimumX: 0
            drag.maximumX: view_droparea.width
            cursorShape: Qt.SizeHorCursor
            hoverEnabled: true
            onPressed: {
                view_mousearea.visible = true
                view_mousearea.cursorShape = Qt.SizeHorCursor
            }
            onReleased:{
                parent.Drag.drop();
                view_mousearea.cursorShape = Qt.ArrowCursor
                view_mousearea.visible = false
                line2_percent_dsp.visible=false
                lvGuideLine_horizontal2_pos=line2.x/root.width*100
            }
            onEntered: line2_percent_dsp.visible=true
            onMouseXChanged:{
                line_horizontal2_pos=parseInt((line2.x*100)/root.width)
                line2_percent_dsp.visible=true
            }
            onExited: line2_percent_dsp.visible=false

        }
    }
    Rectangle {
        id: line3
        x: 0
        y: parseInt((view_droparea.height*lvGuideLine_Vertical1_pos)/100) + ((view_droparea.height*lvGuideLine_Vertical1_pos) % 100 ? 1: 0)
        width: view_droparea.width
        height: lvGuideLine_thickness
        visible: lvGuideLine_Vertical1_on_off
        color: lvGuideLine_color
        Drag.active: line3_dragarea.drag.active

        MouseArea {
            id: line3_dragarea
            anchors.fill: parent
            drag.target: parent
            drag.axis: Drag.YAxis
            drag.minimumY: 0
            drag.maximumY: view_droparea.height
            cursorShape: Qt.SizeVerCursor
            hoverEnabled: true
            onPressed: {
                view_mousearea.visible = true
                view_mousearea.cursorShape = Qt.SizeVerCursor
            }
            onReleased:{
                parent.Drag.drop()
                view_mousearea.cursorShape = Qt.ArrowCursor
                view_mousearea.visible = false
                line3_percent_dsp.visible=false
                lvGuideLine_Vertical1_pos=line3.y/root.height*100
            }
            onEntered: line3_percent_dsp.visible=true
            onMouseYChanged:{
                line_Vertical1_pos=parseInt((line3.y*100)/root.height)
                line3_percent_dsp.visible=true
            }
            onExited: line3_percent_dsp.visible=false

        }
    }
    Rectangle {
        id: line4
        x: 0
        y: parseInt((view_droparea.height*lvGuideLine_Vertical2_pos)/100) + ((view_droparea.height*lvGuideLine_Vertical2_pos) % 100 ? 1: 0)
        width: view_droparea.width
        height: lvGuideLine_thickness
        visible: lvGuideLine_Vertical2_on_off
        color: lvGuideLine_color
        Drag.active: line4_dragarea.drag.active

        MouseArea {
            id: line4_dragarea
            anchors.fill: parent
            drag.target: parent
            drag.axis: Drag.YAxis
            drag.minimumY: 0
            drag.maximumY: view_droparea.height
            cursorShape: Qt.SizeVerCursor
            hoverEnabled: true
            onPressed: {
                view_mousearea.visible = true
                view_mousearea.cursorShape = Qt.SizeVerCursor
            }
            onReleased:{
                parent.Drag.drop()
                view_mousearea.cursorShape = Qt.ArrowCursor
                view_mousearea.visible = false
                line4_percent_dsp.visible=false
                lvGuideLine_Vertical2_pos=line4.y/root.height*100
            }
            onEntered: line4_percent_dsp.visible=true
            onMouseYChanged:{
                line_Vertical2_pos=parseInt((line4.y*100)/root.height)
                line4_percent_dsp.visible=true
            }
            onExited: line4_percent_dsp.visible=false
        }
    }
    /*　%表示　*/
    Rectangle {
        id: line1_percent_dsp
        width: view_droparea.width*0.06
        height: width*0.5
        x:line1.x-(view_droparea.width*0.03)
        y:view_droparea.height/2
        color: "#010101"
        radius: 16
        visible: false
        LTStylishText {
            property string testwk:line_horizontal1_pos
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter

            type: text_style_gLineIndicator
            text: qsTr("<"+testwk+"%>")
            visible: true
        }
    }
    Rectangle {
        id: line2_percent_dsp
        width: view_droparea.width*0.06
        height: width*0.5
        x:line2.x-(view_droparea.width*0.03)
        y:view_droparea.height/2
        color: "#010101"
        radius: 16
        visible: false
        LTStylishText {
            property string testwk:line_horizontal2_pos
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter

            type: text_style_gLineIndicator
            text: qsTr("<"+testwk+"%>")
            visible: true
        }
    }
    Rectangle {
        id: line3_percent_dsp
        width: view_droparea.width*0.06
        height: width*0.5
        x:view_droparea.width/2
        y:line3.y-(height*0.5)
        color: "#010101"
        radius: 16
        visible: false
        LTStylishText {
            property string testwk:line_Vertical1_pos
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter

            type: text_style_gLineIndicator
            text: qsTr("<"+testwk+"%>")
            visible: true
        }
    }
    Rectangle {
        id: line4_percent_dsp
        width: view_droparea.width*0.06
        height: width*0.5
        x:view_droparea.width/2
        y:line4.y-(height*0.5)
        color: "#010101"
        radius: 16
        visible: false
        LTStylishText {
            property string testwk:line_Vertical2_pos
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter

            type: text_style_gLineIndicator
            text: qsTr("<"+testwk+"%>")
            visible: true
        }
    }

    function setguideline1Color(value)
    {
       lvGuideLine_color = value
    }
    function setguideline2Color(value)
    {
        lvGuideLine_color = value
    }
    function setguideline3Color(value)
    {
        lvGuideLine_color = value
    }
    function setguideline4Color(value)
    {
        lvGuideLine_color = value
    }
    function setguideline1Size(value)
    {
        line1.width = value
    }
    function setguideline2Size(value)
    {
        line2.width = value
    }
    function setguideline3Size(value)
    {
        line3.height = value
    }
    function setguideline4Size(value)
    {
        line4.height = value
    }


}
