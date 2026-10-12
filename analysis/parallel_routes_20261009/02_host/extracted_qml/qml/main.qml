import QtQuick 2.6

Item {
    id: root
    /*!
        スプラッシュウィンドウ
     */
    property var splashWindow: LTSplashWindow {
        Component.onCompleted: {
            console.debug("onCompleted")
            visible = true;
            loader.source = "LTMainObject.qml"
        }
    }

    Loader{
        id: loader
        asynchronous: true
        visible: status == Loader.Ready
        onLoaded: {
            //loader.item.visible = true
            console.debug("mainloader onLoaded")
            root.splashWindow.close()
            loader.item.startSearch()
        }
    }
}
