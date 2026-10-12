import QtQuick 2.7

import "qrc:/qml"

/*! \qmltype LTGuideLineIndicator
    \inqmlmodule LT

    \brief
    AF枠です
 */

Item {
    id: root
    anchors.fill: parent
    width: imageView.width
    height: imageView.height


//* 1点AF枠の描画          大きさ変化  位置マウス指定
//* 顔1点AF枠の描画        複数 追尾（認識場所に出現）大きさ変化あり
//* 追尾                   １つ 大きさ変化あり
//* ピンポイント虫眼鏡風拡大拡大率を変えられる
//* 225点AF枠の描画       １５＊１５の中から  １～１３＊１３  大きさ固定 位置固定
//* カスタムマルチの描画  １５＊１５から選択された矩形
    readonly property var plt: {
        "nd": "#00000000",
        "od": "#997700",
    }

    property var testdt: [200,300,100,500,8,16,28,38,48,50,40,30,28,26,24,22,
        100,100,80,110,100,90,80,70,60,50,40,30,28,26,24,128,
         128,127,126,124,120,110,98,77,82,94,80,80,88,86,84,82,
         80,78,70,64,63,62,58,54,48,38,28,16,08,4,02,0]

    property var testdt1: -50
    property var testdt2: -200
    property var testdt3: 100
    property var testdt4: 70
    property var testpace: 20

    property int dlgNumber: 0
    /**********************************************************/
    /* 1点AF枠,                                               */
    /* キャンバスに1点AF枠を描く                              */
    /**********************************************************/
    Canvas{
        id: afFrame_pos_canvas
        width: parent.width
        height: parent.height
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 0
        anchors.topMargin: 0
        visible:afFrame_pos_visible
       //      枠を１つだけ描く
        LTAFFramedisp {
            id: loadButton0
            x:deviceAdapter.afFrame_pos_X
            y:deviceAdapter.afFrame_pos_Y        }


        MouseArea {
            id: line1_dragarea
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: 0
            anchors.topMargin: 0
            x: imageView.x
            y: imageView.y
            width: imageView.width
            height: imageView.height
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            // 押した時のイベントに変更  AF枠表示
            onPressed: {
                switch(pressedButtons){
                case Qt.LeftButton:
                    deviceAdapter.afFrame_pos_X = mouseX-19
                    deviceAdapter.afFrame_pos_Y = mouseY-20
                    /* クリックされたら AF枠設定APIを呼ぶ*/
                    break;
                case Qt.RightButton:
                    break;
                case Qt.MiddleButton:
                    break;
                default:
                    break;
                }
            }

        }

    }
    /**********************************************************/
    /* 顔    最重要顔だけ枠を表示する                         */
    /* クリックされたら位置をカメラに送る                     */
    /**********************************************************/
    Canvas{
        id: afFrame_face_canvas
        width: parent.width
        height: parent.height
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 0
        anchors.topMargin: 0
        visible:afFrame_Face_visible

        //      枠を１つだけ描く
        LTAFFramedisp {
            id: loadButton1
            x:deviceAdapter.afFrame_pos_X           //枠位置は同じ変数を流用する　get時にこれにセットする
            y:deviceAdapter.afFrame_pos_Y
        }
        MouseArea {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: 0
            anchors.topMargin: 0
            x: imageView.x
            y: imageView.y
            width: imageView.width
            height: imageView.height
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            // 押した時のイベントに変更  AF枠表示
                onPressed: {
                    switch(pressedButtons){
                    case Qt.LeftButton:
                        deviceAdapter.afFrame_pos_X = mouseX-19
                        deviceAdapter.afFrame_pos_Y = mouseY-20
                        /* クリックされたら AF枠設定APIを呼ぶ*/
                        break;
                    case Qt.RightButton:
                        break;
                    case Qt.MiddleButton:
                        break;
                    default:
                        break;
                    }
                }
            }
     }
    /**********************************************************/
    /* 追尾　1枠を表示する                                    */
    /* クリックされたら位置をカメラに送る                     */
    /**********************************************************/
    Canvas{
        id: afFrame_face_canvas2
        width: parent.width
        height: parent.height
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 0
        anchors.topMargin: 0
        visible:afFrame_Tracking_visible
        //      枠を１つだけ描く
        LTAFFramedisp {
            id: loadButton2
            x:deviceAdapter.afFrame_pos_X           //枠位置は同じ変数を流用する　get時にこれにセットする
            y:deviceAdapter.afFrame_pos_Y
        }
        MouseArea {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: 0
            anchors.topMargin: 0
            x: imageView.x
            y: imageView.y
            width: imageView.width
            height: imageView.height
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            // 押した時のイベントに変更  AF枠表示
                onPressed: {
                    switch(pressedButtons){
                    case Qt.LeftButton:
                        deviceAdapter.afFrame_pos_X = mouseX-19
                        deviceAdapter.afFrame_pos_Y = mouseY-20
                        /* クリックされたら AF枠設定APIを呼ぶ*/
                        break;
                    case Qt.RightButton:
                        break;
                    case Qt.MiddleButton:
                        break;
                    default:
                        break;
                    }
                }
            }
     }
    /**********************************************************/
    /*　ピンポイントAF枠を描                                  */
    /* クリックされたら位置をカメラに送る                     */
    /**********************************************************/
    Canvas{
        id:aFM_Pinpoint
        visible:afFrame_Pinpoint_visible
        width:parent.width
        height:parent.height
        anchors.left: parent.left
        anchors.leftMargin:0
        anchors.top: parent.top
        anchors.topMargin: 0
// Rectangle {width:imageView.width;height:imageView.height;color:plt.od;border.color:("#007777")}
// Rectangle {width:parent.width;height:parent.height;color:plt.od;border.color:("#777700")}
        // 拡大表示 //
        Canvas{
            width:parent.width　　　　　　　　//アスペクト比により変更する
            height:parent.height　　　　　　//アスペクト比により変更する
            anchors.left: parent.left
            anchors.leftMargin:-((parent.width*afFrame_magnification-parent.width)/2+testdt1)
            anchors.top: parent.top
            anchors.topMargin:-((parent.height*afFrame_magnification-parent.height)/2+testdt2)
            Image {
//              width:parent.width/6
//              height:parent.height/6
                width:parent.width*afFrame_magnification　　　　　　　　//アスペクト比により変更する
                height:parent.height*afFrame_magnification　　　　　　//アスペクト比により変更する
                anchors.left: parent.left
                anchors.leftMargin:0
                anchors.top: parent.top
                anchors.topMargin: 0
                x:0
                y:0
                source: image.source
//                LTAFFramedisp {   //枠表示
//                    id: loadButton4
//                    x:deviceAdapter.afFrame_pos_X
//                    y:deviceAdapter.afFrame_pos_Y
//                }
            }
        }
        Image {
            id: pinpointimage
//            width:parent.width/6
//            height:parent.height/6
            width:240　　　　　　　　　　　　　　　　//アスペクト比により変更する
            height:180　　　　　　　　　　　　　　　//アスペクト比により変更する
            anchors.left: parent.left
            anchors.leftMargin:20
            anchors.top: parent.top
            anchors.topMargin: 20
            source: image.source
            LTAFFramedisp {   //枠表示
                id: loadButton3
                x:testdt3
                y:testdt4
            }
        }
        MouseArea {
            anchors.fill: parent
            drag.target: parent
//            drag.axis: Drag.XAxis
//            drag.axis: Drag.YAxis

//            drag.minimumX: 0
//            drag.maximumX: view_droparea.width
//            drag.minimumY: 0
//            drag.maximumY: view_droparea.height
//            onReleased: parent.Drag.drop()
//            cursorShape: Qt.OpenHandCursor
//            onPressed: {
//                view_mousearea.cursorShape = Qt.DragMoveCursor
//            }
        }
/*
        MouseArea {
            width: parent.width
            height: parent.height
            anchors.left: parent.left
            anchors.leftMargin: 0
            anchors.top: parent.top
            anchors.topMargin: 0
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton


            drag.target: parent
            drag.axis: Drag.YAxis
            drag.minimumY: 0
            drag.maximumY: view_droparea.height
            onReleased: parent.Drag.drop()

            onPressed: {
            switch(pressedButtons){
                   case Qt.LeftButton:
//                       testdt1+=10;
//                       testdt2+=10;
                        break;
                   case Qt.RightButton:
//                       testdt1-=10;
//                       testdt2-=10;
                        break;
                    case Qt.MiddleButton:
//                        testdt[3]+=10;
                        break;
                    default:
                        break;
                    }
                }
           }
*/
       /* 移動ボタン４方向　*/
        Rectangle {
            width:parent.width/20　　　　　　　　//アスペクト比により変更する
            height:parent.height/20　　　　　　//アスペクト比により変更する
            x:parent.width/2
            y:parent.height*0.02
            color: "#262626"
            border.color: "#262626"
            implicitWidth: 20
            implicitHeight: 20
            radius: 13
            LTStylishText {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter

                type: text_style_afFrameIndicator
                text: qsTr("▲")
            }
            MouseArea {
               anchors.fill: parent
               onClicked: {
                   testdt2-=testpace*afFrame_magnification
                   //拡大画面のマージン×比率＝全体画面の枠位置
                   testdt4-=pinpointimage.height/imageView.height*(testpace/afFrame_magnification)
               }
            }
        }
        Rectangle {
            width:parent.width/20　　　　　　　　//アスペクト比により変更する
            height:parent.height/20　　　　　　//アスペクト比により変更する
            x:parent.width/2
            y:parent.height-(parent.height*0.02)-(parent.height/20)
            color: "#262626"
            border.color: "#262626"
            implicitWidth: 20
            implicitHeight: 20
            radius: 13
            LTStylishText {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter

                type: text_style_afFrameIndicator
                text: qsTr("▼")
            }
            MouseArea {
               anchors.fill: parent
               onClicked: {
                   testdt2+=testpace*afFrame_magnification
                   testdt4+=pinpointimage.height/imageView.height*(testpace/afFrame_magnification)
               }
            }
        }
        Rectangle {
            width:parent.width/20　　　　　　　　//アスペクト比により変更する
            height:parent.height/20　　　　　　//アスペクト比により変更する
            x:parent.width*0.02
            y:parent.height/2
            color: "#262626"
            border.color: "#262626"
            implicitWidth: 20
            implicitHeight: 20
            radius: 13
            LTStylishText {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter

                type: text_style_afFrameIndicator
                text: qsTr("←")
            }
            MouseArea {
               anchors.fill: parent
               onClicked: {
                   testdt1-=testpace*afFrame_magnification
                   testdt3-=pinpointimage.width/imageView.width*(testpace/afFrame_magnification)
               }
            }
        }
        Rectangle {
            width:parent.width/20　　　　　　　　//アスペクト比により変更する
            height:parent.height/20　　　　　　//アスペクト比により変更する
            x:parent.width-(parent.width/20)-(parent.width*0.02)
            y:parent.height/2
            color: "#262626"
            border.color: "#262626"
            implicitWidth: 20
            implicitHeight: 20
            radius: 13
            LTStylishText {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter

                type: text_style_afFrameIndicator
                text: qsTr("→")
            }
            MouseArea {
               anchors.fill: parent
               onClicked: {
                   testdt1+=testpace*afFrame_magnification
                   testdt3+=pinpointimage.width/imageView.width*(testpace/afFrame_magnification)
               }
            }
        }
    }
    /**********************************************************/
    /*キャンバスに255点AF枠を描く                             */
    /* クリックされたら位置をカメラに送る                     */
    /**********************************************************/
    Canvas{
      id: afFrame_255point_canvas
      visible:afFrame_255point_visible
        width:(parent.width/21)*15+30      //枠の大きさは左右３枠＋１５＝２１　の中１５+スペース２×１５＝３０
        height:(parent.height/23)*15+30　　　//枠の大きさは左右３枠上下４枠＋１５＝　２３　の中１５+スペース２×１５＝３０
      x:(parent.width/21)*3-6
      y:(parent.height/23)*4-8
      MouseArea {
          id: line2_dragarea
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.verticalCenter: parent.verticalCenter
          drag.target: parent
          cursorShape: Qt.OpenHandCursor
          onPressed: {
              view_mousearea.cursorShape = Qt.DragMoveCursor
          }
      }

      /* 15*15枠描画　　*/
      Grid {
          columns: 15
          id: lvgd_horizon
          width:parent.width
          height:parent.height
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.verticalCenter: parent.verticalCenter
          spacing: 2

          Repeater {
              id: repeater
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.verticalCenter: parent.verticalCenter
              model: 225
              Rectangle {
                  width:(parent.width/15)-2;height: (parent.height/15)-2;color:("#00000000");
                  border.color: "#808080" //非選択：濃い灰色808080、選択直後：黄色997700、選択後５秒経過：薄い灰色C0C0C0
                  border.width: 2
              }
          }
      }
    }

    /**********************************************************/
    /*キャンバスに255点AF枠を描く                             */
    /* クリックされたら位置をカメラに送る                     */
    /**********************************************************/
    Canvas{
        id: afFrame_Multi_canvas
        visible:afFrame_CustomMulti_visible
        width:(parent.width/21)*15+30      //枠の大きさは左右３枠＋１５＝２１　の中１５+スペース２×１５＝３０
        height:(parent.height/23)*15+30　　　//枠の大きさは左右３枠上下４枠＋１５＝　２３　の中１５+スペース２×１５＝３０
        x:(parent.width/21)*3-6
        y:(parent.height/23)*4-8

        /* 15*15枠描画　　*/
        Grid {
            id: grid
          columns: 15
                width:parent.width
                height:parent.height
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

          Repeater {
              anchors.left: parent.left
              anchors.leftMargin: 0
              anchors.top: parent.top
              anchors.topMargin: 0
              model: [plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.od,
                      plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.od,plt.od,
                      plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.od,plt.od,plt.od,
                      plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.od,plt.od,plt.od,plt.nd,
                      plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.od,plt.od,plt.nd,plt.nd,
                      plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.od,plt.od,plt.nd,plt.nd,plt.nd,
                      plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.od,plt.od,plt.nd,plt.nd,plt.nd,plt.nd,
                      plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.od,plt.od,plt.nd,plt.nd,plt.nd,plt.nd,
                      plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.od,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,
                      plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.od,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,
                      plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,
                      plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,
                      plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,
                      plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,
                      plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd,plt.nd]
//              Rectangle {width:(parent.width-30)/15;height: (parent.height-30)/15; color:(modelData);}
              Rectangle {width:(parent.width/15)-2;height: (parent.height/15)-2;color:("#00000000");border.color:(modelData) }
          }

       }
    }

}

//function afFramedsp(x, y, components, onOkSelected, onCancelSelected){
/*
 Canvas{
           id:aF_test
           visible:afFrame_Tracking_visible
           width:parent.width
           height:parent.height
           anchors.left: parent.left
           anchors.leftMargin:0
           anchors.top: parent.top
           anchors.topMargin: 0
           Drag.active: line1_dragarea.drag.active
           Canvas{
               visible:afFrame_Tracking_visible
               width: 40
               height: 40
               Repeater{
                   id: _repeater2
                   model:ListModel{ListElement {_x:3;_y:3;_width:1;_height:13}
                                   ListElement {_x: 3  ; _y: 25; _width: 1;_height: 13}
                                   ListElement {_x: 37 ; _y: 3 ; _width: 1;_height: 13}
                                   ListElement {_x: 37 ; _y: 25; _width: 1;_height: 13}
                                   ListElement {_x: 20 ; _y: 0 ; _width: 1;_height: 6}
                                   ListElement {_x: 20 ; _y: 34; _width: 1;_height: 6}
                                   ListElement {_x: 3  ; _y: 3 ; _width: 13;_height: 1}
                                   ListElement {_x: 25 ; _y: 3 ; _width: 13;_height: 1}
                                   ListElement {_x: 3  ; _y: 37; _width: 13;_height: 1}
                                   ListElement {_x: 25 ; _y: 37; _width: 13;_height: 1}
                                   ListElement {_x: 0  ; _y: 20; _width:  6;_height: 1}
                                   ListElement {_x: 34 ; _y: 20; _width:  6;_height: 1}}
                Rectangle {x:_x;y:_y;width:_width;height:_height;visible: true;color: "#00FF00"}
            }
        }
    }
*/
