//ndtri - add - TemporaryCAMWindow
import QtQuick 2.6
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.1

import "qrc:/qml"
import LT 1.0 as LT

/*! \qmltype TemporaryCAMWindow
 */
ApplicationWindow {
    id: root
    /*ヒストグラムテスト用データ１*/
        property var test_no1: [0,01,02,4,8,16,28,38,48,50,40,30,28,26,24,22,
                               100,100,80,110,100,90,80,70,60,50,40,30,28,26,24,128,
                                128,127,126,124,120,110,98,77,82,94,80,80,88,86,84,82,
                                80,78,70,64,63,62,58,54,48,38,28,16,08,4,02,0,]


        property var test_no3: [128,127,128,3,4,5,6,7,8,9,10,11,12,13,14,15,
                               16,17,18,19,20,21,22,24,28,36,44,56,70,90,120,128,
                                126,124,120,110,90,80,70,60,50,40,30,28,26,24,22,16,
                                30,33,34,35,34,35,34,35,34,35,34,35,20,20,20,20,
                                0,0,0,0,0,0,5,5,5,5,5,30,28,26,24,22,
                               100,100,80,110,100,90,80,70,60,50,40,30,28,26,24,128,
                                128,127,126,124,120,110,98,77,82,94,80,80,88,86,84,82,
                                80,78,70,64,63,62,58,54,48,38,28,16,08,4,0,128,]

        property var test_no2: [
          0, 1, 2, 3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31,
         32,33,34,35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63,
         64,65,66,67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95,
         96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,
    ]

    flags:
        Qt.Window
        | Qt.CustomizeWindowHint
        | Qt.WindowTitleHint
        | Qt.WindowSystemMenuHint
        | Qt.WindowMinimizeButtonHint
    //    | Qt.WindowMaximizeButtonHint
        | Qt. WindowCloseButtonHint


    width: 360
    height: 700

    visible: false

    title: qsTr("擬似カメラ")
    color: "#aaaaaa"

    LTOptionComponentsProvider {
        id: optionComponentsProvider
    }
    LTOptionButtonPopup {
        id: optionButtonPopup
    }



    Text {
        x: 20
        y: 6
        width: 100
        height: 40
        text: qsTr("撮影モード切り替え")
        font.pixelSize: 16
    }

    LTOptionButton {
        x: 30
        y: 30
        z: -1
        width: 107
        height: 77
        type: "optionWithImage"
        target: "recordingMode"
        source:recordingModeIcon
        popup: optionButtonPopup
        componentsProvider: optionComponentsProvider
    }

    Text {
        x: 201
        y: 6
        width: 100
        height: 40
        text: qsTr("ドライブモード切替")
        font.pixelSize: 16
    }

    LTOptionButton {
        x: 210
        y: 30
        z:-1
        width: 107
        height: 77
        type: "optionWithImage"
        labelText: qsTr("Drive Mode")
        target: "driveMode"
        source:driveModeIcon
        popup: optionButtonPopup
        componentsProvider: optionComponentsProvider
    }

    Text {
        id: text3
        x: 95
        y: 385
        z:-2
        text: qsTr("カメラ角度")
        font.pixelSize: 12
    }

    Dial {
        x: 10
        y: 423
        z: -2
        width: 139
        height: 133
    }

    Slider {
        x: 70
        y: 473
        z: -2
        scale: 0.7
        rotation: 90
        value: 0.5
    }

    Button {
        id:test2botton
        x: 30
        y: 142
        z:-2
        height: 20
        text: qsTr("ヒストグラムテストデータ２")
        property int i : 0
        onClicked: {
    histNumOfVal= 128
    hist01=test_no2[0];hist02=test_no2[1];hist03=test_no2[2];hist04=test_no2[3];hist05=test_no2[4];hist06=test_no2[5];hist07=test_no2[6];hist08=test_no2[7];hist09=test_no2[8];hist10=test_no2[9];
    hist11=test_no2[10];hist12=test_no2[11];hist13=test_no2[12];hist14=test_no2[13];hist15=test_no2[14];hist16=test_no2[15];hist17=test_no2[16];hist18=test_no2[17];hist19=test_no2[18];hist20=test_no2[19];
    hist21=test_no2[20];hist22=test_no2[21];hist23=test_no2[22];hist24=test_no2[23];hist25=test_no2[24];hist26=test_no2[25];hist27=test_no2[26];hist28=test_no2[27];hist29=test_no2[28];hist30=test_no2[29];
    hist31=test_no2[30];hist32=test_no2[31];hist33=test_no2[32];hist34=test_no2[33];hist35=test_no2[34]; hist36=test_no2[35];hist37=test_no2[36];hist38=test_no2[37];hist39=test_no2[38];hist40=test_no2[39];
    hist41=test_no2[40];hist42=test_no2[41];hist43=test_no2[42];hist44=test_no2[43];hist45=test_no2[44];hist46=test_no2[45];hist47=test_no2[46];hist48=test_no2[47];hist49=test_no2[48];hist50=test_no2[49];
    hist51=test_no2[50];hist52=test_no2[51];hist53=test_no2[52];hist54=test_no2[53];hist55=test_no2[54];hist56=test_no2[55];hist57=test_no2[56];hist58=test_no2[57];hist59=test_no2[58];hist60=test_no2[59];
    hist61=test_no2[60];hist62=test_no2[61];hist63=test_no2[62];hist64=test_no2[63];hist65=test_no2[64];hist66=test_no2[65];hist67=test_no2[66];hist68=test_no2[67];hist69=test_no2[68];hist70=test_no2[69];
    hist71=test_no2[70];hist72=test_no2[71];hist73=test_no2[72];hist74=test_no2[73];hist75=test_no2[74];hist76=test_no2[75];hist77=test_no2[76];hist78=test_no2[77];hist79=test_no2[78];hist80=test_no2[79];
    hist81=test_no2[80];hist82=test_no2[81];hist83=test_no2[82];hist84=test_no2[83];hist85=test_no2[84];hist86=test_no2[85];hist87=test_no2[86];hist88=test_no2[87];hist89=test_no2[88];hist90=test_no2[89];
    hist91=test_no2[90];hist92=test_no2[91];hist93=test_no2[92];hist94=test_no2[93];hist95=test_no2[94];hist96=test_no2[95];hist97=test_no2[96];hist98=test_no2[97];hist99=test_no2[98];hist100=test_no2[99];
    hist101=test_no2[100];hist102=test_no2[101];hist103=test_no2[102];hist104=test_no2[103];hist105=test_no2[104];hist106=test_no2[105];hist107=test_no2[106];hist108=test_no2[107];hist109=test_no2[108];hist110=test_no2[109];
    hist111=test_no2[110];hist112=test_no2[111];hist113=test_no2[112];hist114=test_no2[113];hist115=test_no2[114];hist116=test_no2[115];hist117=test_no2[116];hist118=test_no2[117];hist119=test_no2[118];hist120=test_no2[119];
    hist121=test_no2[120];hist122=test_no2[121];hist123=test_no2[122];hist124=test_no2[123];hist125=test_no2[124];hist126=test_no2[125];hist127=test_no2[126];hist128=test_no2[127];



        }
    }
    Column {
        x: 30
        y: 220
        z:-2
        spacing: 5
    /* テストボタン */
        Button {height: 40; text: qsTr("テストボタン++"); onClicked: { hist75++ }}
        Button {height: 40; text: qsTr("テストボタン--"); onClicked: { hist75-- }}
       Text {property string testwk:hist75;text: qsTr(testwk); font.pixelSize: 26 }
    }
    Column {
        x: 200
        y: 110
        z:-2
        spacing: 2
    /* バッテリーテストボタン */
        Button {height: 20; text: qsTr("batteryLevel++"); onClicked: { deviceAdapter.batteryLevel++ }}
        Button {height: 20; text: qsTr("batteryLevel--"); onClicked: { deviceAdapter.batteryLevel-- }}
    /* Ternaryテストボタン */
        Button {height: 20; text: qsTr("Ternary++"); onClicked: { deviceAdapter.ternary++ }}
        Button {height: 20; text: qsTr("Ternary--"); onClicked: { deviceAdapter.ternary-- }}
    /* RecordingModeテストボタン */
        Button {height: 20; text: qsTr("RecordingMode++"); onClicked: { deviceAdapter.recordingMode++ }}
        Button {height: 20; text: qsTr("RecordingMode--"); onClicked: { deviceAdapter.recordingMode-- }}
    /* IntelligentAutoModeテストボタン */
        Button {height: 20; text: qsTr("IntelligentAutoMode++"); onClicked: { deviceAdapter.intelligentAutoMode++ }}
        Button {height: 20; text: qsTr("IntelligentAutoMode--"); onClicked: { deviceAdapter.intelligentAutoMode-- }}
    /* CreativeVideoAEテストボタン */
        Button {height: 20; text: qsTr("CreativeVideoAE++"); onClicked: { deviceAdapter.creativeVideoAE++ }}
        Button {height: 20; text: qsTr("CreativeVideoAE--"); onClicked: { deviceAdapter.creativeVideoAE-- }}
    /* Custom3Setテストボタン */
        Button {height: 20; text: qsTr("Custom3Set++"); onClicked: { deviceAdapter.custom3Set++ }}
        Button {height: 20; text: qsTr("Custom3Set--"); onClicked: { deviceAdapter.custom3Set-- }}
    /* CreativeControlFilterテストボタン */
        Button {height: 20; text: qsTr("CreativeControlFilter++"); onClicked: { deviceAdapter.creativeControlFilter++ }}
        Button {height: 20; text: qsTr("CreativeControlFilter--"); onClicked: { deviceAdapter.creativeControlFilter-- }}
    /* ShutterSpeedテストボタン */
        Button {height: 20; text: qsTr("ShutterSpeed++"); onClicked: { deviceAdapter.shutterSpeed++ }}
        Button {height: 20; text: qsTr("ShutterSpeed--"); onClicked: { deviceAdapter.shutterSpeed-- }}
    /* DriveModeテストボタン */
        Button {height: 20; text: qsTr("DriveMode++"); onClicked: { deviceAdapter.driveMode++ }}
        Button {height: 20; text: qsTr("DriveMode--"); onClicked: { deviceAdapter.driveMode-- }}
    /* aspectRatioテストボタン */
        Button {height: 20; text: qsTr("aspectRatio++"); onClicked: { deviceAdapter.af_faceinfo_face_detect_face_pos_pos_X++ }}
        Button {height: 20; text: qsTr("aspectRatio--"); onClicked: { deviceAdapter.af_faceinfo_face_detect_face_pos_pos_X-- }}
        Text {property string testwk1:deviceAdapter.af_faceinfo_face_detect_face_pos_pos_X;text: qsTr(testwk1); font.pixelSize: 20 }
    /* afframe_pos_x */
        Button {height: 20; text: qsTr("afframe_pos_x++"); onClicked: { deviceAdapter.afFrame_pos_X++ }}
        Button {height: 20; text: qsTr("afframe_pos_x--"); onClicked: { deviceAdapter.afFrame_pos_X-- }}
        Text {property string testwk2:deviceAdapter.afFrame_pos_X;text: qsTr(testwk2); font.pixelSize: 20 }
    }
}
