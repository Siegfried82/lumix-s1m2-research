import QtQuick 2.6
import QtQuick.Window 2.3

/*! \qmltype LTSplashWindow.qml
    \inqmlmodule LT

    \brief
    スプラッシュウィンドウを表示する
 */
Window {
    id: root

    flags: Qt.SplashScreen
    //modality: Qt.ApplicationModal

    x: (Screen.width - image.width) / 2
    y: (Screen.height - image.height) / 2
    width: image.width
    height: image.height

    //Windowサイズを変更できなくする
    minimumWidth: image.width
    minimumHeight: image.height
    maximumWidth: image.width
    maximumHeight: image.height

    color: "transparent"
    visible: true

    title: "LUMIX Tether"

    /*
        画像
     */
    Image {
        id: image
// IVC >> Ver.1.9 >> start >> [THRBOXV100-72]
        source: "qrc:/images/449_splash.png"
        //source: "qrc:/images/449_splash_forBOX.png"
        //source: "qrc:/images/449_splash_forMulticam.png"
// IVC << Ver.1.9 << end << [THRBOXV100-72]
    }
    /*
        Ver
     */
    Image {
        id: ver_disp
// IVC >> Ver.1.9 >> start >> [THRBOXV100-72]
        //x: 40
        //y: root.height / 2 + 15
        //x: 100
        //y: root.height / 2 + 20
        x: 80
        y: root.height / 2 + 20
// IVC << Ver.1.9 << end << [THRBOXV100-72]
        z: 30
        source: "qrc:/images/449_splash_ver.svg"
    }
    /*
        ver **.** 5つの文字を出す。
     */
    Image {
        id: ver_disp_1
        x: ver_disp.x + ver_disp.width
        y: ver_disp.y
        z: 30
        source: {
            var ver = utilities.get_APPLICATION_VERSION_NAME_STRING()
            if(ver.length < 1) {
                ver_disp_1.source = ""
            } else {
                var ch = ver.charAt(0)
                if(ch == '0') {
                    ver_disp_1.source = "qrc:/images/449_splash_0.svg"
                } else if (ch == '1') {
                    ver_disp_1.source = "qrc:/images/449_splash_1.svg"
                } else if (ch == '2') {
                    ver_disp_1.source = "qrc:/images/449_splash_2.svg"
                } else if (ch == '3') {
                    ver_disp_1.source = "qrc:/images/449_splash_3.svg"
                } else if (ch == '4') {
                    ver_disp_1.source = "qrc:/images/449_splash_4.svg"
                } else if (ch == '5') {
                    ver_disp_1.source = "qrc:/images/449_splash_5.svg"
                } else if (ch == '6') {
                    ver_disp_1.source = "qrc:/images/449_splash_6.svg"
                } else if (ch == '7') {
                    ver_disp_1.source = "qrc:/images/449_splash_7.svg"
                } else if (ch == '8') {
                    ver_disp_1.source = "qrc:/images/449_splash_8.svg"
                } else if (ch == '9') {
                    ver_disp_1.source = "qrc:/images/449_splash_9.svg"
                } else if (ch == '.') {
                    ver_disp_1.source = "qrc:/images/449_splash_dot.svg"
                }
            }
        }
    }
    Image {
        id: ver_disp_2
        x: ver_disp_1.x + ver_disp_1.width
        y: ver_disp.y
        z: 30
        source: {
            var ver = utilities.get_APPLICATION_VERSION_NAME_STRING()
            if(ver.length < 2) {
                ver_disp_2.source = ""
            } else {
                var ch = ver.charAt(1)
                if(ch == '0') {
                    ver_disp_2.source = "qrc:/images/449_splash_0.svg"
                } else if (ch == '1') {
                    ver_disp_2.source = "qrc:/images/449_splash_1.svg"
                } else if (ch == '2') {
                    ver_disp_2.source = "qrc:/images/449_splash_2.svg"
                } else if (ch == '3') {
                    ver_disp_2.source = "qrc:/images/449_splash_3.svg"
                } else if (ch == '4') {
                    ver_disp_2.source = "qrc:/images/449_splash_4.svg"
                } else if (ch == '5') {
                    ver_disp_2.source = "qrc:/images/449_splash_5.svg"
                } else if (ch == '6') {
                    ver_disp_2.source = "qrc:/images/449_splash_6.svg"
                } else if (ch == '7') {
                    ver_disp_2.source = "qrc:/images/449_splash_7.svg"
                } else if (ch == '8') {
                    ver_disp_2.source = "qrc:/images/449_splash_8.svg"
                } else if (ch == '9') {
                    ver_disp_2.source = "qrc:/images/449_splash_9.svg"
                } else if (ch == '.') {
                    ver_disp_2.source = "qrc:/images/449_splash_dot.svg"
                }
            }
        }
    }
    Image {
        id: ver_disp_3
        x: ver_disp_2.x + ver_disp_2.width
        y: ver_disp.y
        z: 30
        source: {
            var ver = utilities.get_APPLICATION_VERSION_NAME_STRING()
            if(ver.length < 3) {
                ver_disp_3.source = ""
            } else {
                var ch = ver.charAt(2)
                if(ch == '0') {
                    ver_disp_3.source = "qrc:/images/449_splash_0.svg"
                } else if (ch == '1') {
                    ver_disp_3.source = "qrc:/images/449_splash_1.svg"
                } else if (ch == '2') {
                    ver_disp_3.source = "qrc:/images/449_splash_2.svg"
                } else if (ch == '3') {
                    ver_disp_3.source = "qrc:/images/449_splash_3.svg"
                } else if (ch == '4') {
                    ver_disp_3.source = "qrc:/images/449_splash_4.svg"
                } else if (ch == '5') {
                    ver_disp_3.source = "qrc:/images/449_splash_5.svg"
                } else if (ch == '6') {
                    ver_disp_3.source = "qrc:/images/449_splash_6.svg"
                } else if (ch == '7') {
                    ver_disp_3.source = "qrc:/images/449_splash_7.svg"
                } else if (ch == '8') {
                    ver_disp_3.source = "qrc:/images/449_splash_8.svg"
                } else if (ch == '9') {
                    ver_disp_3.source = "qrc:/images/449_splash_9.svg"
                } else if (ch == '.') {
                    ver_disp_3.source = "qrc:/images/449_splash_dot.svg"
                }
            }
        }
    }
    Image {
        id: ver_disp_4
        x: ver_disp_3.x + ver_disp_3.width
        y: ver_disp.y
        z: 30
        source: {
            var ver = utilities.get_APPLICATION_VERSION_NAME_STRING()
            if(ver.length < 4) {
                ver_disp_4.source = ""
            } else {
                var ch = ver.charAt(3)
                if(ch == '0') {
                    ver_disp_4.source = "qrc:/images/449_splash_0.svg"
                } else if (ch == '1') {
                    ver_disp_4.source = "qrc:/images/449_splash_1.svg"
                } else if (ch == '2') {
                    ver_disp_4.source = "qrc:/images/449_splash_2.svg"
                } else if (ch == '3') {
                    ver_disp_4.source = "qrc:/images/449_splash_3.svg"
                } else if (ch == '4') {
                    ver_disp_4.source = "qrc:/images/449_splash_4.svg"
                } else if (ch == '5') {
                    ver_disp_4.source = "qrc:/images/449_splash_5.svg"
                } else if (ch == '6') {
                    ver_disp_4.source = "qrc:/images/449_splash_6.svg"
                } else if (ch == '7') {
                    ver_disp_4.source = "qrc:/images/449_splash_7.svg"
                } else if (ch == '8') {
                    ver_disp_4.source = "qrc:/images/449_splash_8.svg"
                } else if (ch == '9') {
                    ver_disp_4.source = "qrc:/images/449_splash_9.svg"
                } else if (ch == '.') {
                    ver_disp_4.source = "qrc:/images/449_splash_dot.svg"
                }
            }
        }
    }
    Image {
        id: ver_disp_5
        x: ver_disp_4.x + ver_disp_4.width
        y: ver_disp.y
        z: 30
        source: {
            var ver = utilities.get_APPLICATION_VERSION_NAME_STRING()
            if(ver.length < 5) {
                ver_disp_5.source = ""
            } else {
                var ch = ver.charAt(4)
                if(ch == '0') {
                    ver_disp_5.source = "qrc:/images/449_splash_0.svg"
                } else if (ch == '1') {
                    ver_disp_5.source = "qrc:/images/449_splash_1.svg"
                } else if (ch == '2') {
                    ver_disp_5.source = "qrc:/images/449_splash_2.svg"
                } else if (ch == '3') {
                    ver_disp_5.source = "qrc:/images/449_splash_3.svg"
                } else if (ch == '4') {
                    ver_disp_5.source = "qrc:/images/449_splash_4.svg"
                } else if (ch == '5') {
                    ver_disp_5.source = "qrc:/images/449_splash_5.svg"
                } else if (ch == '6') {
                    ver_disp_5.source = "qrc:/images/449_splash_6.svg"
                } else if (ch == '7') {
                    ver_disp_5.source = "qrc:/images/449_splash_7.svg"
                } else if (ch == '8') {
                    ver_disp_5.source = "qrc:/images/449_splash_8.svg"
                } else if (ch == '9') {
                    ver_disp_5.source = "qrc:/images/449_splash_9.svg"
                } else if (ch == '.') {
                    ver_disp_5.source = "qrc:/images/449_splash_dot.svg"
                }
            }
        }
    }

    property LTStylishText version_disp

    function objectStartFunc() {
        /*var comp_version_disp = Qt.createComponent("LTStylishText.qml")
        if (comp_version_disp.status == Component.Ready) {
            version_disp = comp_version_disp.createObject(root);
            version_disp.x = 40
            version_disp.y = root.height / 2 + 15
            version_disp.z = 30
            version_disp.color = "#808080"
            version_disp.font.pixelSize = 15
            version_disp.verticalAlignment = Text.AlignVCenter
            version_disp.horizontalAlignment = Text.AlignHCenter
            version_disp.text = "Ver" + utilities.get_APPLICATION_VERSION_NAME_STRING()
        }*/
    }
    function windowClose() {
        //image.source = ""
        visible = false
    }
}

