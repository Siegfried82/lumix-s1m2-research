import QtQuick 2.6
import QtQuick.Window 2.3

import "qrc:/qml"
import LT 1.0 as LT
import "LTSubFunction.js" as LTSubFunction


Item {
    id: root

    /*!
        Saved window instance
     */
    property Window window
    /*!
        Window Type (type: WinList enums)
     */
    property var targetWindow

    /*!
        window default values
     */
    property int defaultX: (Screen.width-window.width)/2
    property int defaultY: (Screen.height-window.height)/2
    property int defaultWidth: 500
    property int defaultHeight: 500
    property bool defaultMaximised: false

    /*!
        For compact window
     */
    property bool compactEnable: false

    Component.onCompleted: {
        LTSubFunction.console_debug.out("WindowStateSaver: onCompleted:Name="+ Screen.name)
        LTSubFunction.console_debug.out("WindowStateSaver: onCompleted:Width="+ Screen.desktopAvailableWidth)
        LTSubFunction.console_debug.out("WindowStateSaver: onCompleted:Height="+ Screen.desktopAvailableHeight)

        var saveX = applicationSettings.winStateXForWindow(targetWindow);
        var saveY = applicationSettings.winStateYForWindow(targetWindow);
        var saveWidth = applicationSettings.winStateWidthForWindow(targetWindow);
        var saveHeight = applicationSettings.winStateHeightForWindow(targetWindow);
        var saveMaximised = applicationSettings.winStateMaximisedForWindow(targetWindow);

        if (saveX <= 0 || saveX >= Screen.desktopAvailableWidth ||
            saveY <= 0 || saveY >= Screen.desktopAvailableHeight ||
            saveWidth == 0 || saveHeight == 0)
        {
            curX = defaultX;
            curY = defaultY;
            curWidth = defaultWidth;
            curHeight = defaultHeight;
            curMaximised = defaultMaximised
        }
        else
        {
            curX = saveX;
            curY = saveY;
            curWidth = saveWidth;
            curHeight = saveHeight;
            curMaximised = saveMaximised;
        }

// 横幅がリサイズできないウインドウで設定ファイルが異常だった場合の対処 2024/08
        if (targetWindow === LT.ApplicationSettings.WinList_Main || targetWindow === LT.ApplicationSettings.WinList_Flash || targetWindow === LT.ApplicationSettings.WinList_Preference){
            curWidth = defaultWidth;            // 違えばの判定処理は無駄なので、強制的に設定
        }

        var i = 0
        if( utilities.isScaling() === true){
            for(i=0; i<Qt.application.screens.length; i++){
                if( Qt.application.screens[i].virtualX <= curX && curX < Qt.application.screens[i].virtualX + Qt.application.screens[i].width &&
                    Qt.application.screens[i].virtualY <= curY && curY < Qt.application.screens[i].virtualY + Qt.application.screens[i].height
                        ){
                    window.screen = Qt.application.screens[i];
                }
            }
        }

        try {
            window.x = prevX = curX;
            window.y = prevY = curY;
            window.width = prevWidth = curWidth;
            window.height = prevHeight = curHeight;

            if (curMaximised) {
                window.visibility = Window.Maximized;
            }
        } catch (error) {
            console.debug ("Error loading QML : ")
            for (var i = 0; i < error.qmlErrors.length; i++) {
                console.debug("lineNumber: " + error.qmlErrors[i].lineNumber)
                console.debug("columnNumber: " + error.qmlErrors[i].columnNumber)
                console.debug("fileName: " + error.qmlErrors[i].fileName)
                console.debug("message: " + error.qmlErrors[i].message)
            }
        }
    }

    /*!
        window current values
     */
    property int curX
    property int curY
    property int curWidth
    property int curHeight
    property bool curMaximised

    /*!
        window previous values
     */
    property int prevX
    property int prevY
    property int prevWidth
    property int prevHeight

    function updatePrevPos()
    {
        prevX = curX;
        curX = window.x;
        prevY = curY;
        curY = window.y;
        prevWidth = curWidth;
        curWidth = window.width;
        prevHeight = curHeight;
        curHeight = window.height;

        console.log(window.visibility + " cur:" + curX + ", " + curY + ", " + curWidth + ", " + curHeight + ", prev:" + prevX + ", " + prevY + ", " + prevWidth + ", " + prevHeight)

        if(targetWindow == LT.ApplicationSettings.WinList_Main) {
            applicationSettings.setWinStateHeightForWindow(targetWindow, curHeight);
        }
    }

    Item{
        //Windowsでのマルチモニター＋QT_SCALING_FACTOR設定時のバグ回避策
        Timer {
            id: delayUpdateTimer
            interval: 500
            running: false
            repeat: false
            onTriggered: {
                updatePrevPos()
            }
        }
    }

    Connections {
        target: window
        function onVisibilityChanged() {
            if (window.visibility == Window.Maximized)
            {
                //遅延更新待ちの場合、ここで更新しておく
                if( delayUpdateTimer.running === true ){
                    delayUpdateTimer.stop()
                    updatePrevPos()
                }

                curMaximised = true;

                curX = prevX;
                curY = prevY;
                curWidth = prevWidth;
                curHeight = prevHeight;
            }
            else if (window.visibility == Window.Windowed)
            {
                //遅延更新待ちの場合、ここで更新しておく
                if( delayUpdateTimer.running === true ){
                    delayUpdateTimer.stop()
                    updatePrevPos()
                }
                curMaximised = false;
            }
            else if (window.visibility == Window.Hidden)
            {
                //遅延更新待ちの場合、ここで更新しておく
                if( delayUpdateTimer.running === true ){
                    delayUpdateTimer.stop()
                    updatePrevPos()
                }

                applicationSettings.setWinStateXForWindow(targetWindow, curX);
                applicationSettings.setWinStateYForWindow(targetWindow, curY);
                applicationSettings.setWinStateWidthForWindow(targetWindow, curWidth);
                applicationSettings.setWinStateHeightForWindow(targetWindow, curHeight);
                applicationSettings.setWinStateMaximisedForWindow(targetWindow, curMaximised);
            }
        }

        function onXChanged() {
            //Macの場合、最大化などするためのウインドウのアニメーション中にも逐次変更通知がくる
            //このため最大化した時にノーマル時の位置、サイズが期待値と異なることになる
            //情報の更新をするタイミングを遅延させることで回避を行う
            if(utilities.isMac()){
                delayUpdateTimer.stop()
                delayUpdateTimer.start()
            }else{
                prevX = curX;
                curX = window.x;
            }
        }
        function onYChanged() {
            //Macの場合、最大化などするためのウインドウのアニメーション中にも逐次変更通知がくる
            //このため最大化した時にノーマル時の位置、サイズが期待値と異なることになる
            //情報の更新をするタイミングを遅延させることで回避を行う
            if(utilities.isMac()){
                delayUpdateTimer.stop()
                delayUpdateTimer.start()
            }else{
                prevY = curY;
                curY = window.y;
            }
        }
        function onWidthChanged() {
            //Macの場合、最大化などするためのウインドウのアニメーション中にも逐次変更通知がくる
            //このため最大化した時にノーマル時の位置、サイズが期待値と異なることになる
            //情報の更新をするタイミングを遅延させることで回避を行う
            if(utilities.isMac()){
                delayUpdateTimer.stop()
                delayUpdateTimer.start()
            }else{
                prevWidth = curWidth;
                curWidth = window.width;
            }
        }
        function onHeightChanged() {
            //Macの場合、最大化などするためのウインドウのアニメーション中にも逐次変更通知がくる
            //このため最大化した時にノーマル時の位置、サイズが期待値と異なることになる
            //情報の更新をするタイミングを遅延させることで回避を行う
            if(utilities.isMac()){
                delayUpdateTimer.stop()
                delayUpdateTimer.start()
            }else{
                prevHeight = curHeight;
                curHeight = window.height;

                if(targetWindow == LT.ApplicationSettings.WinList_Main) {
                    applicationSettings.setWinStateHeightForWindow(targetWindow, curHeight);
                }
            }
        }
// IVC >> Ver.1.9 >> start >> No.1
// IVC >> Ver.1.9 >> start >> [THRBOXV100-40]
//        onVisibleChanged: {
//            console.log("Visible changed: " + targetWindow + " " + window.visible)
//            applicationSettings.setWinStateVisibleForWindow(targetWindow, window.visible)
//        }
// IVC << Ver.1.9 << end << [THRBOXV100-40]
// IVC << Ver.1.9 << end << No.1
    }
}
