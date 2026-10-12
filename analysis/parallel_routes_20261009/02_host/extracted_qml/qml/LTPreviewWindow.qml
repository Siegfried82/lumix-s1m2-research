//ndtri - add - LTPreviewWindow
import QtQuick 2.6
import QtQuick.Window 2.2
import QtQuick.Controls 2.0

import "qrc:/qml"
import LT 1.0 as LT
import "LTSubFunction.js" as LTSubFunction

/*! \qmltype LTPreviewWindow
    \inqmlmodule LT

    \brief
    Preview picture window
 */
Window {
    id: root

    LTWindowStateSaver {
        id:windowState
        window: root
        defaultWidth: 584//minimumWidth
        defaultHeight: 463//minimumHeight
        targetWindow: LT.ApplicationSettings.WinList_Preview
    }

    /*!
        signal for finishing load image
     */
    signal imageLoadCommpleted()

    flags:
        Qt.Window
      | Qt.CustomizeWindowHint
      | Qt.WindowTitleHint
      | Qt.WindowSystemMenuHint
      | Qt.WindowMinimizeButtonHint
      | Qt.WindowMaximizeButtonHint
      | Qt.WindowCloseButtonHint

    ////  ウィンドウの最小サイズと最大サイズを同じ値にして，リサイズできないようにする
    //minimumWidth: 584//Math.min(image.sourceSize.width,1080)
    //minimumHeight: 463//Math.min(image.sourceSize.height,720)
    //maximumWidth: minimumWidth
    //maximumHeight: minimumHeight

    //  ウィンドウのサイズを最小/最大サイズにする
    width: 584
    height: 463

    title: qsTr("Preview") + " " + fileName
           + (showScaleOnTitle
              ? " (x" + (scale_index >= 0 ? scale_tbl[scale_index].string : scaleString(image.scale, 2)) + ")"
              : "")
    color: "transparent"

    property string fileName: ""
    property bool showScaleOnTitle: false

    /*!
        Max~Min window size setting
     */
    //readonly property real maxWindowWidth: 1080

    //readonly property real maxWindowHeight: 720

    //readonly property real minWindowWidth: 108

    //readonly property real minWindowHeight: 72

    /*!
        各部の描画色を定義するパレットです
     */
    readonly property var palette: {
        "backgroundDark": "#07090d",
        "backgroundLight": "#292b2d",
        "foregroundDark": "#808080",
        "foregroundLight": "#c6c6c6",
        "hovered": "#434343",
        "pressed": "#5c5c5c",
        "checked": "#ffbf1f",
        "defaultColor": "#525356",
        "selectedColor": "#FFD600"
    }

    /*!
        Image loading status
     */
    property alias imgStatus: image.status

    // 現在の回転のインデックス (値は、0, 1, 2, 3)
    // 実際の回転角度は curRotationIndex * 90度
    property int curRotationIndex;

    property int mouseWheelDeltaSum: 0;  // WheelのangleDelta.yを積算
    readonly property int mouseWheelDeltaSumThresh: 50  // Wheelが反応する閾値

    // 回転を考慮した見た目の画像のサイズ
    property real realImgWidth: 0.0;
    property real realImgHeight: 0.0;

    /*
    readonly property int scale_0062:    0
    readonly property int scale_0125:    1
    readonly property int scale_0250:    2
    readonly property int scale_0500:    3
    readonly property int scale_1000:    4
    readonly property int scale_2000:    5
    readonly property int scale_3000:    6
    readonly property int scale_4000:    7
    */
    readonly property int scale_num:     8
    property int scale_index:   -1
    readonly property variant scale_tbl:
    [
        //'6.25%' :
        {'value': 1.0 / 16.0,   'string': "1/16"},
        //'12.5%' :
        {'value': 1.0 / 8.0,    'string': "1/8"},
        //'25%' :
        {'value': 1.0 / 4.0,    'string': "1/4"},
        //'50%' :
        {'value': 1.0 / 2.0,    'string': "1/2"},
        //'100%' :
        {'value': 1.0 * 1.0,    'string': "1.0"},
        //'200%' :
        {'value': 1.0 * 2.0,    'string': "2.0"},
        //'300%' :
        {'value': 1.0 * 3.0,    'string': "3.0"},
        //'400%' :
        {'value': 1.0 * 4.0,    'string': "4.0"},
    ];

    // 有効数字l桁の文字列を返す
    function scaleString(s, l) {
        var retVal = s.toString();
        var count = 0;
        for (var i = 0; i < retVal.length; i++) {
            var c = retVal.charAt(i);
            if (c === "0" || c ===".") {
                continue;
            }

            if (++count >= l) {
                break;
            }
        }

        retVal = retVal.substring(0, i + 1);
        return retVal;
    }

    // 回転後の画像のOffset
    property variant imageOffset:
    [
        {x: 0, y: 0},   //  imageOffset[0] ...   0度回転時
        {x: 0, y: 0},   //  imageOffset[1] ...  90度回転時
        {x: 0, y: 0},   //  imageOffset[2] ... 180度回転時
        {x: 0, y: 0}    //  imageOffset[3] ... 270度回転時
    ]

    /*
    readonly property string state_landscape: "landscape"
    readonly property string state_portrait: "portrait"
    function restore() {
        image.scale = fitScale
        if (image.state == state_portrait) {
            image.x = (root.width-root.height)/2
            image.y = (root.height-root.width)/2
        } else {
            image.x = 0
            image.y = 0
        }

        isZooming = false
    }
    */

    /*
    function imageLog() {
        LTSubFunction.console.debug("[PrevWin] ")
        LTSubFunction.console.debug("[PrevWin] ==================================================");

        LTSubFunction.console.debug("[PrevWin] Root {");
        LTSubFunction.console.debug("[PrevWin]   (x, y)=("+root.x+", "+root.y+")");
        LTSubFunction.console.debug("[PrevWin]   (width, height)=("+root.width+", "+root.height+")");
        LTSubFunction.console.debug("[PrevWin] }");

        LTSubFunction.console.debug("[PrevWin] Rectangle {");
        LTSubFunction.console.debug("[PrevWin]   (x, y)=("+previewBackground.x+", "+previewBackground.y+")");
        LTSubFunction.console.debug("[PrevWin]   (width, height)=("+previewBackground.width+", "+previewBackground.height+")");
        LTSubFunction.console.debug("[PrevWin] }");

        LTSubFunction.console.debug("[PrevWin] Image {");
        LTSubFunction.console.debug("[PrevWin]   (x, y)=("+image.x+", "+image.y+")");
        LTSubFunction.console.debug("[PrevWin]   (width, height)=("+image.width+", "+image.height+")");
        LTSubFunction.console.debug("[PrevWin]   (sourceSize.width, sourceSize.height)=("+image.sourceSize.width+", "+image.sourceSize.height+")");
        LTSubFunction.console.debug("[PrevWin]   (paintedWidth, paintedHeight)=("+image.paintedWidth+", "+image.paintedHeight+")");
        LTSubFunction.console.debug("[PrevWin]   (implicitWidth, implicitHeight)=("+image.implicitWidth+", "+image.implicitHeight+")");
        LTSubFunction.console.debug("[PrevWin]   rotation="+image.rotation);
        LTSubFunction.console.debug("[PrevWin]   scale="+image.scale);
        LTSubFunction.console.debug("[PrevWin]   transformOrigin(x, y)=("+image.transformOriginPoint.x+", "+image.transformOriginPoint.y+")");
        LTSubFunction.console.debug("[PrevWin] }");
    }
    */

    function realOriginalImageWidth() {
        return curRotationIndex % 2 == 0 ? image.sourceSize.width : image.sourceSize.height;
    }
    function realOriginalImageHeight() {
        return curRotationIndex % 2 == 0 ? image.sourceSize.height : image.sourceSize.width;
    }

    function realImageWidth() {
        return curRotationIndex % 2 == 0 ? image.width * image.scale : image.height * image.scale;
    }
    function realImageHeight() {
        return curRotationIndex % 2 == 0 ? image.height * image.scale : image.width * image.scale;
    }

    function loadImageSource() {
        var filePath = deviceAdapter.pcSavedFilePath
        LTSubFunction.console_debug.out("preview window filePath = " + filePath)
        var index = filePath.lastIndexOf('/')
        LTSubFunction.console_debug.out("preview window index = " + index)
        if(index - 1 <= filePath.length) {
            image.source = "image://previewCapture/" + filePath
            fileName = filePath.substring(index+1, filePath.length)
            LTSubFunction.console_debug.out("preview window fileName = " + fileName)
            root.visible = true

            // 拡張子が"JPG"の場合のみタイトルバーにScaleを表示する
            showScaleOnTitle = false;
            var dotpos = fileName.lastIndexOf('.');
            if (dotpos <= fileName.length) {
                var extStr = fileName.substring(dotpos + 1, fileName.length);
                if (extStr.toLowerCase() == "jpg" && previewImageInfo.scale == 1) {
                    showScaleOnTitle = true;
                }
            }

            // 回転後のoffsetを保存
            imageOffset[  0/90].x = 0;
            imageOffset[  0/90].y = 0;
            imageOffset[ 90/90].x = image.height;
            imageOffset[ 90/90].y = 0;
            imageOffset[180/90].x = image.width;
            imageOffset[180/90].y = image.height;
            imageOffset[270/90].x = 0;
            imageOffset[270/90].y = image.width;

            curRotationIndex = 0;
            var rotation = 0;
            switch(previewImageInfo.orientation) {
            default:
            case LT.PreviewImageInfo.ExifOrient_None: // 回転無し
                rotation = 0;
                break
            case LT.PreviewImageInfo.ExifOrient_180: // 180度回転
                rotation = 180;
                break
            case LT.PreviewImageInfo.ExifOrient_R90: // 右90度回転
                rotation = 90;
                break
            case LT.PreviewImageInfo.ExifOrient_L90: // 左90度回転
                rotation = 270;
                break
            }
//            fitScale = 1.0
//            restore()

            rotateImage(rotation);
        }
    }

    /*
      画像をWindow Sizeに合わせる
     */
    function fitImageToWindow() {
        //
        // Window Sizeに合わせてScaleを計算
        //
        // WindowとImageの横縦比を比較
        var scale
        var orgImageWidth = realOriginalImageWidth();
        var orgImageHeight = realOriginalImageHeight();
        if (root.width / root.height > orgImageWidth / orgImageHeight) {
            // Windowの方が横長 --> 縦方向でScaling
            scale = root.height / orgImageHeight;
        } else {
            // Imageの方が横長 --> 横方向でScaling
            scale = root.width / orgImageWidth;
        }
        scale_index = -1;
        resizeImage(scale, -1, -1);
    }

    /*
      画像の位置を調整する
     */
    function adjustImagePos() {
        // Windowサイズよりも画像が小さくなったら、画面中央に配置
        // Windowサイズよりも画像が大きい場合、位置を余白が出ないように調整。

        // 横方向
        if (root.width >= realImgWidth) {
            // 画像幅の方がWindow幅よりも小さい
            var x = (root.width - realImgWidth) / 2 + imageOffset[curRotationIndex].x * image.scale;
            image.x = x;

            // 移動不可
            mouseArea.drag.minimumX = x;
            mouseArea.drag.maximumX = x;
        } else {
            // 画像幅の方がWindow幅よりも大きい

            // 画像サイズ以上に移動不可
            mouseArea.drag.maximumX = imageOffset[curRotationIndex].x * image.scale;
            mouseArea.drag.minimumX = mouseArea.drag.maximumX - (realImgWidth - root.width);

            if (image.x < mouseArea.drag.minimumX) {
                // 画像がWindowよりも左に行き過ぎた場合、戻す
                image.x = mouseArea.drag.minimumX;
            } else if (image.x > mouseArea.drag.maximumX) {
                // 画像がWindowよりも右に行き過ぎた場合、戻す
                image.x = mouseArea.drag.maximumX;
            }
        }

        // 縦方向
        if (root.height >= realImgHeight) {
            // 画像の高さの方がWindowの高さよりも小さい
            var y = (root.height - realImgHeight) / 2 + imageOffset[curRotationIndex].y * image.scale;
            image.y = y;

            // 移動不可
            mouseArea.drag.minimumY = y;
            mouseArea.drag.maximumY = y;
        } else {
            // 画像の高さの方がWindowの高さよりも大きい

            // 画像サイズ以上に移動不可
            mouseArea.drag.maximumY = imageOffset[curRotationIndex].y * image.scale;
            mouseArea.drag.minimumY = mouseArea.drag.maximumY - (realImgHeight - root.height);

            if (image.y < mouseArea.drag.minimumY) {
                // 画像がWindowよりも上に行き過ぎた場合、戻す
                image.y = mouseArea.drag.minimumY;
            } else if (image.y > mouseArea.drag.maximumY) {
                // 画像がWindowよりも下に行き過ぎた場合、戻す
                image.y = mouseArea.drag.maximumY;
            }
        }
    }

    /*
      画像のresize
        winPosX ... Resizeの中心位置X(Window座標基準)
        winPosY ... Resizeの中心位置Y(Window座標基準)
     */
    function resizeImage(scale, winPosX, winPosY) {
        LTSubFunction.console_debug.out("[PrevWin] resizeImage: " + "image.scale=" + image.scale + ", scale=" + scale + ", winPos=(" + winPosX + ", " + winPosY + ")");

        // Resize中心位置をWindow座標からOrgImage座標に変換
        var mapToImagePos = previewBackground.mapToItem(image, winPosX, winPosY);
        LTSubFunction.console_debug.out("[PrevWin] resizeImage: " + "mapToImagePos=(" + mapToImagePos.x + ", " + mapToImagePos.y + ")");

        // resize
        image.scale = scale;

        realImgWidth = realImageWidth();
        realImgHeight = realImageHeight();

        if (winPosX >= 0 && winPosY >= 0) {
            // (winPosX, winPosY)を中心に拡大したように移動

            // OrgImage座標からWindow座標に戻す
            var mapFromImagePos = previewBackground.mapFromItem(image, mapToImagePos.x, mapToImagePos.y);
            LTSubFunction.console_debug.out("resizeImage: " + "mapFromImagePos=(" + mapFromImagePos.x + ", " + mapFromImagePos.y + ")");

            // 画像を移動
            // var x = winPosX - imageResizeCenterPosX;
            var diffx = mapFromImagePos.x - winPosX;
            image.x = image.x - diffx;

            // var y = winPosY - imageResizeCenterPosY;
            var diffy = mapFromImagePos.y - winPosY;
            image.y = image.y - diffy;
        }

        adjustImagePos();
    }

    /*
      画像の拡大
        winPosX ... 拡大の中心位置X(Window座標基準)
        winPosY ... 拡大の中心位置Y(Window座標基準)
        repeat  ... trueの場合、最大サイズの次は最小に戻る。
     */
    function expandImage(winPosX, winPosY, repeat) {
        var index = scale_index
        if (index < 0) {
            // Window Fit Sizeの場合、
            // scale_tblの各値から、現在のscaleに近いものを探す
            var i;
            for (i = 0; i < scale_num; i++) {
                if (scale_tbl[i].value > image.scale) {
                    break;
                }
            }
            index = i;
        } else {
            // 拡大/縮小状態の場合
            index = index + 1;
        }

        // index値のチェック
        if (index >= scale_num) {
            if (repeat) {
                // repeat==trueの場合は最小サイズに戻る
                index = 0;
            } else {
                // 最大サイズを保持
                index = scale_num - 1;
            }
        }

        scale_index = index
        var scale = scale_tbl[scale_index].value;
        resizeImage(scale, winPosX, winPosY);
    }

    /*
      画像の縮小
        winPosX ... 縮小の中心位置X(Window座標基準)
        winPosY ... 縮小の中心位置Y(Window座標基準)
        repeat  ... trueの場合、最小サイズの次は最大に戻る。
     */
    function shrinkImage(winPosX, winPosY, repeat) {
        var index = scale_index
        if (index < 0) {
            // Window Fit Sizeの場合、
            // scale_tblの各値から、現在のscaleに近いものを探す
            var i;
            for (i = scale_num - 1; i >= 0; i--) {
                if (scale_tbl[i].value < image.scale) {
                    break;
                }
            }
            index = i;
        } else {
            // 拡大/縮小状態の場合
            index = index - 1;
        }

        // index値のチェック
        if (index < 0) {
            if (repeat) {
                // repeat==trueの場合は最大サイズに戻る
                index = scale_num - 1;
            } else {
                // 最小サイズを保持
                index = 0;
            }
        }

        scale_index = index
        var scale = scale_tbl[scale_index].value;
        resizeImage(scale, winPosX, winPosY);
    }

    /*
      画像の回転
        degree ... 時計回りの回転角度(90° x n でなければならない)
     */
    function rotateImage(degree) {
        curRotationIndex = (curRotationIndex + degree / 90 + 4) % 4;
        image.rotation = 90 * curRotationIndex;
        realImgWidth = realImageWidth();
        realImgHeight = realImageHeight();

        // 回転直後はWindowにフィットさせる
        fitImageToWindow();
    }


    Component.onCompleted: {
        deviceAdapter.cameraStatusChanged.connect(root.cameraStatusSetting)
        deviceAdapter.cameraStatusCompleteNotify.connect(cameraStatusCompleteNotify)
        utilities.preferenceWindowVisibleChangedNotify.connect(root.preferenceWindowVisibleSetting);
        utilities.searchCamWindowVisibleChangedNotify.connect(root.searchCamWindowVisibleSetting);
        //Adapter connect
        deviceAdapter.pcSavedFilePathChanged.connect(root.loadImageSource);

        utilities.activateWindowNotify.connect(root.activateWindowNotify);
    }

    function cameraStatusSetting() {
        var flg = false
        //---------------------------------
        //撮影スタンバイ 　　　→0
        //動画記録中(4K/6Kフォト含む) →1
        //動画再生中（4K/6Kフォト除く） →2
        //その他処理中 →3
        //動画以外再生中 →4
        //---------------------------------
        //テザー側で、カメラの状態が{ 2, 3, 4 }の時に操作中を表示するように
        //ご対応をお願いいたします
        if((deviceAdapter.cameraStatus == LT.Utilities.CamStatus_MovRec_Others) ||
           (deviceAdapter.cameraStatus == LT.Utilities.CamStatus_Playing) ||
           (deviceAdapter.cameraStatus == LT.Utilities.CamStatus_Processing) ||
// IVC >> Ver.1.9 >> start >> [THRBOXV100-162]
           (deviceAdapter.cameraStatus == LT.Utilities.CamStatus_Menu_Displayed) ){
// IVC << Ver.1.9 << end << [THRBOXV100-162]
            LTSubFunction.console_debug.out("PreviewView::cameraStatusSetting cameraStatus " + deviceAdapter.cameraStatus)
            if(deviceAdapter.cameraStatus === LT.Utilities.CamStatus_Menu_Displayed) {
                maskpanel.mode |= maskpanel.mode_live_view_menu
                maskpanel.mode &= ~maskpanel.mode_camera
            } else {
                maskpanel.mode |= maskpanel.mode_camera
                maskpanel.mode &= ~maskpanel.mode_live_view_menu
            }
            updateMaskPanel()
        } else {
            LTSubFunction.console_debug.out("PreviewView::cameraStatusSetting cameraStatus " + deviceAdapter.cameraStatus)
        }
    }

    function cameraStatusCompleteNotify() {
        LTSubFunction.console_debug.out("PreviewView::cameraStatusCompleteNotify")
        if((deviceAdapter.cameraStatus != LT.Utilities.CamStatus_MovRec_Others) &&
           (deviceAdapter.cameraStatus != LT.Utilities.CamStatus_Playing) &&
           (deviceAdapter.cameraStatus != LT.Utilities.CamStatus_Processing) &&
// IVC >> Ver.1.9 >> start >> [THRBOXV100-162]
           (deviceAdapter.cameraStatus != LT.Utilities.CamStatus_Menu_Displayed) ){
// IVC << Ver.1.9 << end << [THRBOXV100-162]
            maskpanel.mode &= ~maskpanel.mode_camera
            maskpanel.mode &= ~maskpanel.mode_live_view_menu
            updateMaskPanel()
        }
    }

    function preferenceWindowVisibleSetting(flg) {
        LTSubFunction.console_debug.out("PreviewView::preferenceWindowVisibleSetting flg=" + flg)
        if(flg) {
            maskpanel.mode |= maskpanel.mode_pref
        } else {
            maskpanel.mode &= ~maskpanel.mode_pref
        }
        updateMaskPanel()
    }

    function searchCamWindowVisibleSetting(flg){
        if(flg) {
            maskpanel.mode |= maskpanel.mode_searchWindow
        } else {
            maskpanel.mode &= ~maskpanel.mode_searchWindow
        }
        updateMaskPanel()
    }

    function updateMaskPanel()
    {
        if(maskpanel.mode == maskpanel.mode_init )
        {
            maskpanel.visible = false
        }else{
            maskpanel.visible = true
        }
    }

    function activateWindowNotify() {
        if(root.visibility == Window.Minimized) {
            root.visibility = Window.Windowed
        }
        root.active = true
    }

    onActiveChanged: {
        //LTSubFunction.console_debug.out("PreviewView::onActiveChanged")
        if(maskpanel.visible) {
            if(root.active) {
                utilities.preferenceWindowActive()
            }
        }
    }

    onWidthChanged: {
        LTSubFunction.console_debug.out("[PrevWin] onWidthChanged");
        if (image.source == "") {
            return;
        }

        if (scale_index < 0) {
            fitImageToWindow();
        }
        adjustImagePos();

        // imageLog();
    }
    onHeightChanged: {
        LTSubFunction.console_debug.out("[PrevWin] onHeightChanged");
        if (image.source == "") {
            return;
        }

        if (scale_index < 0) {
            fitImageToWindow();
        }
        adjustImagePos();

        // imageLog();
    }

    onClosing:{
        //Qtのバグ？最大化->非表示->表示（最大状態）->通常と遷移させるとウインドウサイズが最大化のものになってしまう
        //最大化から解除された時に前の状態の位置やサイズに明示的に戻すようにする
        //MacではLTWindowStateSaver.qmlの対応では回避できない
        //×ボタンだとWindowがCloseされるので、本来再度Createする必要あり？
        //最大化時はいったんCloseせずに操作パネルのボタン操作で行われる場合のHide状態とする
        if(root.visibility == Window.Maximized){
            close.accepted = false;
            root.hide();
        }else{
            close.accepted = true;
        }
    }

    /*
        背景 - Background
     */
    Rectangle {
        id: previewBackground

        anchors.fill: parent
        color: palette.backgroundLight

        Image {
            id: image
            smooth: {
                if (scale < 1.0) {
                    // 縮小の場合のみtrue
                    true;
                } else {
                    false;
                }
            }
            fillMode: Image.PreserveAspectFit
            transformOrigin: Item.TopLeft   // 変換の原点を左上に移動
        } // End of Image(id: image)

        PinchArea {
            id: pincharea
            anchors.fill: parent
            pinch.target: image
            pinch.dragAxis: Pinch.XAndYAxis
//            pinch.minimumScale: scale_tbl[0].value
//            pinch.maximumScale: scale_tbl[scale_num-1].value

            /*
            onPinchUpdated: {
                LTSubFunction.console.debug("[PrevWin] onPinchUpdated pinch.scale =" + pinch.scale);
                LTSubFunction.console.debug("[PrevWin] onPinchUpdated pinch.scale = " + pinch.scale + ", (mouseX, mouseY) = (" + mouseArea.mouseX + ", " + mouseArea.mouseY + ")");
            }
            */

            onSmartZoom: {
                LTSubFunction.console_debug.out("[PrevWin] onSmartZoom pinch.scale = " + pinch.scale + ", (mouseX, mouseY) = (" + mouseArea.mouseX + ", " + mouseArea.mouseY + ")");

                expandImage(mouseArea.mouseX, mouseArea.mouseY, true);

            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            drag.target: image

            /*
            onMouseXChanged: {
                var winMouseX = mouseX;
                var winMouseY = mouseY;
                LTSubFunction.console.debug("[PrevWin] MouseArea.onMouseXChanged: (mouseX, mouseY)=("+winMouseX+", "+winMouseY+")");
            }
            */


            onWheel:(wheel)=> {
                var winMouseX = mouseX;
                var winMouseY = mouseY;

                LTSubFunction.console_debug.out("[PrevWin] MouseArea.onWheel: (mouseX, mouseY)=("+winMouseX+", "+winMouseY+")");
                LTSubFunction.console_debug.out("[PrevWin] MouseArea.onWheel: (angleDelta.x, angleDelta.y)=("+wheel.angleDelta.x+", "+wheel.angleDelta.y+")");

                // WheelのangleDelta.yを積算
                // (Macのマウスホイールが速すぎるため、一定以上回ってからリサイズする)
                if (wheel.angleDelta.y > 0) {
                    if (mouseWheelDeltaSum >= 0) {
                        mouseWheelDeltaSum += wheel.angleDelta.y;
                    } else {
                        // 逆回転の場合、クリア
                        mouseWheelDeltaSum = 0;
                    }
                } else if (wheel.angleDelta.y < 0) {
                    if (mouseWheelDeltaSum <= 0) {
                        mouseWheelDeltaSum += wheel.angleDelta.y
                    } else {
                        // 逆回転の場合、クリア
                        mouseWheelDeltaSum = 0;
                    }
                } else {  // wheel.angleDelta.y == 0
                    return;
                }

                LTSubFunction.console_debug.out("[PrevWin] mouseWheelDeltaSum = " + mouseWheelDeltaSum);
                if (Math.abs(mouseWheelDeltaSum) < mouseWheelDeltaSumThresh) {
                    return;
    }

                if (mouseWheelDeltaSum > 0) {
                    // 拡大
                    expandImage(winMouseX, winMouseY, false);
                } else {
                    // 縮小
                    shrinkImage(winMouseX, winMouseY, false);
                }
                mouseWheelDeltaSum = 0;
            }

            onPositionChanged: {
                // LTSubFunction.console_debug.out("[PrevWin] onPositionChanged")
                previewCtrlRectangle.visible = true;
                previewCtrlVisibleTimer.restart();
            }
        } // End of MouseArea(id: mouseArea)
    } // End of Rectangle(id: previewBackground)

	/*
    Flickable {
        id: flickable

        anchors {
            fill:parent
        }

        contentWidth: image.width
        contentHeight: image.height

//        Rectangle {
//            x:image.x
//            y:image.y
//            width: image.width
//            height: image.height
//            color: "transparent"

//            border.color: "green"
//            border.width: 5
//        }

        Image {
            id: image

            state: state_landscape
            x: 0
            y: 0
            width: root.width
            height: root.height

            fillMode: Image.PreserveAspectFit

//            antialiasing: true
//            smooth: true

            states: State {
                when: image.rotation == 90 || image.rotation == 270
                name: state_portrait

                PropertyChanges {
                    target: image
                    x: (root.width-root.height)/2
                    y: (root.height-root.width)/2
                    width: root.height
                    height: root.width
                }
            }

//            Behavior on state {
//                NumberAnimation {
//                    duration: 0
//                }
//            }

//            Behavior on scale {
//                NumberAnimation {
//                    duration: 0
//                }
//            }
//            Behavior on x {
//                NumberAnimation {
//                    duration: 0
//                }
//            }
//            Behavior on y {
//                NumberAnimation {
//                    duration: 0
//                }
//            }

        }
    }

    PinchArea {
        anchors.fill: parent
        pinch.target: image
        pinch.dragAxis: Pinch.XAndYAxis
        pinch.minimumScale: scale_tbl[0].value
        pinch.maximumScale: scale_tbl[scale_num-1].value
        onPinchStarted: {
            LTSubFunction.console_debug.out("onPinchStarted")
        }
        //onPinchChanged: {
        //    console.debug("onPinchChanged")
        //}
        onPinchUpdated: {
            //LTSubFunction.console_debug.out("onPinchUpdated pinch.scale =" + pinch.scale)

            if(isZooming) {
                //初回ズーム時は100%
                if(scale_index == -1) {
                    pinch.scale = 1.0
                    scale_index = scale_1000;
                    return
                }
                var now_index = scale_index
                for(var i=0; i<scale_num; i++) {
                    if(scale_tbl[i] <= pinch.scale) {
                        scale_index = i
                        break;
                    }
                }
                if(now_index != scale_index) {
                    LTSubFunction.console_debug.out("onPinchUpdated scale_index =" + scale_index)
                    image.scale = scale_tbl[scale_index].value;
                }
            }
        }
        onPinchFinished: {
            LTSubFunction.console_debug.out("onPinchFinished")
        }
        onSmartZoom: {
            LTSubFunction.console_debug.out("onSmartZoom pinch.scale="+pinch.scale)
            if(isZooming) {
                //初回ズーム時は100%
                if(scale_index == -1) {
                    scale_index = scale_1000;
                } else if(scale_index < scale_num-1) {
                    scale_index = scale_index + 1
                } else {
                    scale_index = 0
                }
                image.scale = fitScale*scale_tbl[scale_index].value;
            }
        }
        MouseArea {
            id:msArea

            property bool held: false

            anchors {
                fill: parent
            }

            acceptedButtons: Qt.LeftButton | Qt.RightButton
            scrollGestureEnabled: false

            drag {
                target: image
            }

            onPressAndHold: {
                //detect drag image
                isZooming = true;
            }

            onClicked: {
                if (mouse.button & Qt.RightButton) {
                    //console.log("Right Clicked");
                } else if (mouse.button & Qt.LeftButton) {
                    if (isZooming) {
                        root.restore();
                    } else {
                        //初回ズーム時は100%
                        if(scale_index == -1) {
                            scale_index = scale_1000;
                        }
                        image.scale = fitScale*scale_tbl[scale_index].value;
                        isZooming = true;
                    }
                }
            }
            onWheel: {
                if (wheel.modifiers & Qt.ControlModifier) {
                } else {
                    if(isZooming) {
                        if (wheel.angleDelta.y > 0) {
                            if(scale_index < scale_num-1) {
                                scale_index = scale_index + 1
                            }
                        } else {
                            if(0 < scale_index) {
                                scale_index = scale_index - 1
                            }
                        }
                        image.scale = fitScale*scale_tbl[scale_index].value;
                    }
                }
            }
        }
    }
    */

    Timer {
        id: previewCtrlVisibleTimer
        interval: 3000
        repeat: false

        onTriggered: {
            LTSubFunction.console_debug.out("[PrevWin] Timer.onTriggered, isOnPreviewCtrlRectangle = " + isOnPreviewCtrlRectangle);

            if (isOnPreviewCtrlRectangle > 0) {
                // マウスカーソルがpreviewCtrlRectangleの上にあった場合
                // previewCtrlRectangleを非表示にせず、タイマー再セット
                previewCtrlVisibleTimer.restart();
            } else {
                // previewCtrlRectangleを非表示にする
                previewCtrlRectangle.visible = false;
            }
        }
    }

    property int isOnPreviewCtrlRectangle: 0;

    Rectangle {
        id: previewCtrlRectangle
        transformOrigin: Item.Center
        color: "#00000000"
        visible: false

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.horizontalCenterOffset: -previewCtrlGrid.width/2
        anchors.bottom: parent.bottom
        anchors.bottomMargin: previewCtrlGrid.height

        Grid {
            id: previewCtrlGrid
            columns: 5
            rows: 1
            spacing: 0

            LTRectangleButton {
                // 左90度回転
                width: 30
                height: 30
                source: "qrc:/images/preview_left.svg"

                onClicked: {
                    rotateImage(-90);
                    // imageLog();
                }

                onEntered: {
                    isOnPreviewCtrlRectangle++;
                    // LTSubFunction.console.debug("[PrevWin] preViewCtrlLeftTurnBtn: onEntered: isOnPreviewCtrlRectangle = " + isOnPreviewCtrlRectangle);
                }
                onExited: {
                    isOnPreviewCtrlRectangle--;
                    // LTSubFunction.console.debug("[PrevWin] preViewCtrlLeftTurnBtn: onExited: isOnPreviewCtrlRectangle = " + isOnPreviewCtrlRectangle);
                }
            }
            LTRectangleButton {
                // 右90度回転
                width: 30
                height: 30
                source: "qrc:/images/preview_right.svg"

                onClicked: {
                    rotateImage(90);
                    // imageLog();
                }

                onEntered: {
                    isOnPreviewCtrlRectangle++;
                    // LTSubFunction.console.debug("[PrevWin] preViewCtrlRightTurnBtn: onEntered: isOnPreviewCtrlRectangle = " + isOnPreviewCtrlRectangle);
                }
                onExited: {
                    isOnPreviewCtrlRectangle--;
                    // LTSubFunction.console.debug("[PrevWin] preViewCtrlRightTurnBtn: onExited: isOnPreviewCtrlRectangle = " + isOnPreviewCtrlRectangle);
                }
            }
            LTRectangleButton {
                // 縮小
                width: 30
                height: 30
                source: "qrc:/images/preview_zoomout.svg"

                onClicked: {
                    shrinkImage(root.width / 2, root.height / 2);
                    // imageLog();
                }

                onEntered: {
                    isOnPreviewCtrlRectangle++;
                    // LTSubFunction.console.debug("[PrevWin] preViewCtrlShrinkImageBtn: onEntered: isOnPreviewCtrlRectangle = " + isOnPreviewCtrlRectangle);
                }
                onExited: {
                    isOnPreviewCtrlRectangle--;
                    // LTSubFunction.console.debug("[PrevWin] preViewCtrlShrinkImageBtn: onExited: isOnPreviewCtrlRectangle = " + isOnPreviewCtrlRectangle);
                }
            }
            LTRectangleButton {
                // 拡大
                width: 30
                height: 30
                source: "qrc:/images/preview_zoomin.svg"

                onClicked: {
                    expandImage(root.width / 2, root.height / 2);
                    // imageLog();
                }

                onEntered: {
                    isOnPreviewCtrlRectangle++;
                    // LTSubFunction.console.debug("[PrevWin] preViewCtrlExpandImageBtn: onEntered: isOnPreviewCtrlRectangle = " + isOnPreviewCtrlRectangle);
                }
                onExited: {
                    isOnPreviewCtrlRectangle--;
                    // LTSubFunction.console.debug("[PrevWin] preViewCtrlExpandImageBtn: onExited: isOnPreviewCtrlRectangle = " + isOnPreviewCtrlRectangle);
                }
            }
            LTRectangleButton {
                // Window Just Fit Size
                width: 30
                height: 30
                source: "qrc:/images/preview_maximize.svg"

                onClicked: {
                    fitImageToWindow();
                    // imageLog();
                }

                onEntered: {
                    isOnPreviewCtrlRectangle++;
                    // LTSubFunction.console.debug("[PrevWin] preViewCtrlJustFitImageBtn: onEntered: isOnPreviewCtrlRectangle = " + isOnPreviewCtrlRectangle);
                }
                onExited: {
                    isOnPreviewCtrlRectangle--;
                    // LTSubFunction.console.debug("[PrevWin] preViewCtrlJustFitImageBtn: onExited: isOnPreviewCtrlRectangle = " + isOnPreviewCtrlRectangle);
                }
            }
        }  // End of Grid (id = previewCtrlGrid)
    }  // End of Rectangle (id = previewCtrlRectangle)

    /*
      カメラ操作中に全てのコントロールを押せなくする。
     */
    Rectangle {
        id: maskpanel

        property int mode: mode_init //状態をビットフラグでもつ
        readonly property int mode_init: 0
        readonly property int mode_camera: 1 //再生モード
        readonly property int mode_pref: 2 //アプリの設定画面開いている
        readonly property int mode_streaming: 4 //ストリーミング中
        readonly property int mode_live_view_menu : 8 //ライブビューMENU中
        readonly property int mode_searchWindow: 16 //起動カメラウインド
        readonly property int mode_Connecting: 32 //カメラ接続中

        visible: false
        anchors {
            fill: parent
        }
        color: "#000000"
        opacity: 0.5
        MouseArea {
            anchors {
                fill: parent
            }
            hoverEnabled: true
            onClicked: {
                //root.dismiss();
            }
        }
    }
}
