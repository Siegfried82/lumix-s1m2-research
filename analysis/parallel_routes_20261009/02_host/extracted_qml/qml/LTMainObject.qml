import QtQml 2.2
import QtQuick 2.6
import QtQuick.Controls 2.1
import QtQuick.Window 2.3
import Qt.labs.platform 1.0

import "qrc:/qml"
import LT 1.0 as LT
import "LTMainSubFunction.js" as LTMainSubFunction
import "LTSubFunction.js" as LTSubFunction

/*! \qmltype main
    \inqmlmodule LT

    \brief
    メインオブジェクトです

    アプリケーションの各ウィンドウの表示を制御します．
 */
Item {
    id: root

    property var connectWindow: LTConnectWindow {
        Component.onCompleted: {
            console.debug("onCompleted")

        }
    }
    property QtObject mainWindow
    property QtObject liveViewWindow
    property QtObject cameraListWindow
    property QtObject flashWindow
    property QtObject previewWindow
    property QtObject preferenceWindow
    property QtObject searchCameraListWindow
    property bool disconnectFlg: false

    /*!
        能力取得エラーをチェックするかどうかのフラグ
     */
    readonly property int get_capability_err_check: 0
    /*!
        値取得エラーをチェックするかどうかのフラグ
     */
    readonly property int get_value_err_check: 0

    Component.onCompleted: {
        console.debug("mainobject onCompleted")
        connectWindow.onSearchCompleted.connect(root.searchCompleted)
        connectWindow.onClosing.connect(root.closeConnectWindow)
        deviceAdapter.isCamerasConnectedChanged.connect(root.camerasConnectedChange)
        deviceAdapter.camConnectStatusChanged.connect(root.camConnectStatusChange);
        deviceAdapter.notifyConnectErrorMessage.connect(root.notifyConnectErrorMessage)

        init_sdk()
        initWindows(false)

        searchCameraListWindow.onClosing.connect(root.closeSearchCameraListWindow)

        console.debug("mainobject onCompleted E")
    }

    /*!
        VersionUp ダイアログ
     */
    LTVersionUpDialog {
        id: versionUpDialog
        onVersionUpExec: {
            versionData.openURL();
            //Close opened windows
            LTSubFunction.console_debug.out("versionUpDialog Close opened windows")
            if ((root.searchCameraListWindow != null)&&(root.searchCameraListWindow.visible)) {
                root.searchCameraListWindow.close();
                deviceAdapter.deviceSearch.stopSearch()
            }
            if ((root.liveViewWindow != null)&&(root.liveViewWindow.visible)) {
                root.liveViewWindow.close();
            }
            // IVC >> Ver.1.9 >> start >> No.1
            if ((root.cameraListWindow != null)&&(root.cameraListWindow.visible)) {
                root.cameraListWindow.close();
            }
            // IVC << Ver.1.9 << end << No.1
            if ((root.previewWindow != null)&&(root.previewWindow.visible)) {
                root.previewWindow.close();
            }
            if ((root.preferenceWindow != null)&&(root.preferenceWindow.visible)) {
                root.preferenceWindow.close();
            }
            if ((root.flashWindow != null)&&(root.flashWindow.visible)) {
                root.flashWindow.close();
            }
            if ((root.mainWindow != null)&&(root.mainWindow.visible)) {
                root.mainWindow.close();
            }
            //root.connectWindowClose()
            deviceAdapter.adp_LMX_func_api_CloseSession();
            // IVC >> Ver.1.9 >> start >> No.1
            deviceAdapter.adp_LMX_func_api_Finish();
            // IVC << Ver.1.9 << end << No.1

// IVC >> Ver.1.9 >> start >> [THRBOXV100-61]
            // IVC >> Ver.1.9 >> start >> No.1
            //connectionEvent.checkStop();
            // IVC << Ver.1.9 << end << No.1
// IVC << Ver.1.9 << end << [THRBOXV100-61]
            //console.log("App closing: versionUpDialog");
            quitApp();
        }
    }

//    MessageDialog {
    LT.MessageBox{
        id: errorDialog
        modality: Qt.ApplicationModal
        icon: LT.StandardIcon.Critical
        visible: false
        title: "LUMIX Tether"
        standardButtons: LT.StandardButton.Close
    }

    function startSearch(){
        deviceAdapter.deviceSearch.startSearch(false)
    }

    //SDK APIを呼び出し初期設定を行う。
    function init_sdk() {
        var ret = LT.DeviceAdapter.Ternary_True;
        //SDKを初期化する。
        if(ret == LT.DeviceAdapter.Ternary_True) {
            ret = deviceAdapter.adp_LMX_func_api_Init();
        }
        //SDKにリトライカウントを設定する。
        if(ret == LT.DeviceAdapter.Ternary_True) {
            ret = deviceAdapter.adp_LMX_func_api_Set_SendCommand_RetryType_Config();
        }
        //SDKにタイムアウト値を設定する。
        if(ret == LT.DeviceAdapter.Ternary_True) {
            ret = deviceAdapter.adp_LMX_func_api_Set_SendCommand_TimeOutVal_Config();
        }
        //SDKのデバッグログ設定を行う。
        if(ret == LT.DeviceAdapter.Ternary_True) {
            ret = deviceAdapter.adp_LMX_func_api_DbgLog_Config();
        }
        //SDKにCallbackを設定する。
        if(ret == LT.DeviceAdapter.Ternary_True) {
            ret = deviceAdapter.adp_LMX_func_api_Reg_NotifyCallback();
        }
        if(ret == LT.DeviceAdapter.Ternary_True) {
            ret = flashAdapter.adp_LMX_func_api_Reg_NotifyCallback();
        }
        if(ret == LT.DeviceAdapter.Ternary_True && utilities.isMac()) {
            ret = deviceAdapter.adp_LMX_func_api_Set_Awake_Msg("LUMIXTether busy.");
        }
// IVC >> Ver.1.9 >> start >> No.1
        if(ret == LT.DeviceAdapter.Ternary_True) {
            ret = deviceAdapter.adp_LMX_func_api_ptpip_Set_SendCommand_TimeOutVal_Config(5000);
        }
        if(ret == LT.DeviceAdapter.Ternary_True) {
            ret = deviceAdapter.adp_LMX_func_api_ptpip_Set_SearchDev_TimeOutVal_Config(10000, 10000);
        }
        if(ret == LT.DeviceAdapter.Ternary_True) {
            var pcName = "LUMIXTether"
            var nameLenght = pcName.length
            ret = deviceAdapter.adp_LMX_func_api_ptpip_Set_Pc_Name(nameLenght, pcName);
        }
        if(ret == LT.DeviceAdapter.Ternary_True) {
            // We need to set a valid network to perform M-Search. If don't know, set it "null"
            // Otherwise, set it "192.168.54.10" to perform direct connect
            //var ip_add = "192.168.54.10"
            var ip_add = null
            deviceAdapter.adp_LMX_func_api_ptpip_Set_Ip_Addr(ip_add);
        }
// IVC << Ver.1.9 << end << No.1
        if(ret != LT.DeviceAdapter.Ternary_True) {
            //内部エラーが発生しました。
// IVC >> Ver.1.9 >> start >> [THRBOXV100-155]
//            if(utilities.isMac()){
                errorDialog.text = qsTr("Internal error.");
                errorDialog.visible = true;
//            } else {
//                utilities.criticalMessage(qsTr("Error"), qsTr("Internal error."));
//            }
// IVC << Ver.1.9 << end << [THRBOXV100-155]
            return false;
        }
        return true;
    }

    function searchCompleted(backgroundSearch){
        if(!backgroundSearch){
            searchCameraListWindow.visible = true
        }
    }

    function camConnectStatusChange(){
        if( deviceAdapter.camConnectStatus === LT.Utilities.CamConnectSts_Success){
            searchCameraListWindow.visible = false
            initWindows(true)
        }else if( deviceAdapter.camConnectStatus === LT.Utilities.CamConnectSts_SuccessBackground){
            searchCameraListWindow.visible = false
        }else if( deviceAdapter.camConnectStatus === LT.Utilities.CamConnectSts_Error){
            //まとめてのエラーは出さないようにする
            //errorDialog.text = qsTr("Connect camera error.");
            //errorDialog.visible = true;

            searchCameraListWindow.visible = false
            disconnectCompleted()
        }else if( deviceAdapter.camConnectStatus === LT.Utilities.CamConnectSts_GetData){
        }
    }

    function camerasConnectedChange(){
        if( deviceAdapter.isCamerasConnected === false){
            disconnectCompleted()
        }
    }

    function disconnectCompleted() {
        LTSubFunction.console_debug.out("connectionTest: mainobject disconnectcompleted")
        disconnectFlg = true

        //root.preferenceWindow.visible = false
        if(root.preferenceWindow != null) {
            root.preferenceWindow.popupClose()
        }
        if(root.mainWindow != null) {
            root.mainWindow.popupClose()
        }
        if(root.liveViewWindow != null) {
            root.liveViewWindow.popupClose()
        }
// IVC >> Ver.1.9 >> start >> No.1
        if(root.cameraListWindow != null) {
            root.cameraListWindow.popupClose();
        }
// IVC << Ver.1.9 << end << No.1
        //root.mainWindow.close();
        if(root.mainWindow != null) {
            root.closeMainView()
            root.mainWindow.visible = false
        }
// IVC >> Ver.1.9 >> start >> [THRBOXV100-155]
        errorDialog.visible = false;
//        utilities.closeMessage(qsTr("Error"));
// IVC << Ver.1.9 << end << [THRBOXV100-155]

        //デバイスの再検索
        if( deviceAdapter.deviceSearch.startSearch(false) === false )
        {
            //失敗した場合はLAN検索中の可能性あり
            //一度停止してから再検索する
            deviceAdapter.deviceSearch.stopSearch()
            deviceAdapter.deviceSearch.startSearch(false)
        }

/*
#ifdef PREVIEW_EXTERN
        //close preview app
        deviceAdapter.closePreviewApp();
#endif
*/
    }

    function initWindows(arg) {
        var date1 = new Date()
        LTSubFunction.console_debug.out("initWindows start = " + date1.getHours() + ":" + date1.getMinutes() + ":" + date1.getSeconds() + ":" + date1.getMilliseconds())
        var connectWindowComponent = null
        var mainComponent = null
        var liveViewComponent = null
        // IVC >> Ver.1.9 >> start >> No.1
        var cameraListComponent = null
        var cameraListInitFlg = false
        // IVC << Ver.1.9 << end << No.1
        var flashComponent = null
        var previewComponent = null
        var preferenceComponent = null
        var searchCameraListComponent = null
        var mainInitFlg = false
        var liveViewInitFlg = false
        var flashInitFlg = false
        var previewInitFlg = false
        var preferenceInitFlg = false
        var searchCameraListInitFlg = false

        if (mainWindow == null) {
            mainComponent = Qt.createComponent("LTMainWindow.qml")
        } else {
            mainWindow.visible = arg
        }
        if (liveViewWindow == null) {
            liveViewComponent = Qt.createComponent("LTLiveViewWindow.qml")
        } else {
            if(arg) {
                liveViewWindow.visible = applicationSettings.winStateVisibleForWindow(LT.ApplicationSettings.WinList_Live);
            } else {
                liveViewWindow.visible = false
            }
        }
        // IVC >> Ver.1.9 >> start >> No.1
        if (cameraListWindow == null) {
            if( deviceAdapter.isSupportMultiView() === false){
                cameraListComponent = Qt.createComponent("LTCameraListWindow.qml")
            }else{
                cameraListComponent = Qt.createComponent("LTCameraListWindow2.qml")
            }
        } else {
            if(arg) {
                // IVC >> Ver.1.9 >> start >> [THRBOXV100-32] No.10
                //cameraListWindow.visible = true;
                cameraListWindow.visible = applicationSettings.winStateVisibleForWindow(LT.ApplicationSettings.WinList_CamList);
                // IVC << Ver.1.9 << end << [THRBOXV100-32] No.10
                // IVC >> Ver.1.9 >> start >> [THRBOXV100-58]
                cameraListWindow.initCameraSetting();
                // IVC << Ver.1.9 << end << [THRBOXV100-58]
            } else {
                cameraListWindow.visible = false
            }
        }
        // IVC << Ver.1.9 << end << No.1
        if (flashWindow == null) {
            flashComponent = Qt.createComponent("LTFlashWindow.qml")
        } else {
            if(arg) {
                flashWindow.visible = applicationSettings.winStateVisibleForWindow(LT.ApplicationSettings.WinList_Flash);
            } else {
                flashWindow.visible = false
            }
        }
        if (previewWindow == null) {
            previewComponent = Qt.createComponent("LTPreviewWindow.qml")
        } else {
        }
        if (preferenceWindow == null) {
            preferenceComponent = Qt.createComponent("LTPreferenceWindow.qml")
        } else {
        }
        if (searchCameraListWindow == null) {
            searchCameraListComponent = Qt.createComponent("LTSearchCameraListWindow.qml")
        } else {
        }

        if((mainWindow == null) && (mainComponent != null)) {
            if (mainComponent.status == Component.Ready) {
                mainWindow = mainComponent.createObject(root);
                mainWindow.visible = false
                mainInitFlg = true
            } else {
                mainComponent.onStatusChanged = function(status) {
                    if (status == Component.Ready) {
                        mainWindow = mainComponent.createObject(root);
                        initMainWindow(arg)
                    }
                }
            }
        }
        if((liveViewWindow == null) && (liveViewComponent != null)) {
            if (liveViewComponent.status == Component.Ready) {
                liveViewWindow = liveViewComponent.createObject(root);
                liveViewWindow.visible = false
                liveViewInitFlg = true
            } else {
                liveViewComponent.onStatusChanged = function(status) {
                    if (status == Component.Ready) {
                        liveViewWindow = liveViewComponent.createObject(root);
                        initLiveViewWindow(arg)
                    }
                }
            }
        }
        if((flashWindow == null) && (flashComponent != null)) {
            if (flashComponent.status == Component.Ready) {
                flashWindow = flashComponent.createObject(root);
                flashWindow.visible = false
                flashInitFlg = true
            } else {
                flashComponent.onStatusChanged = function(status) {
                    if (status == Component.Ready) {
                        flashWindow = flashComponent.createObject(root);
                        initFlashWindow(arg)
                    }
                }
            }
        }
        // IVC >> Ver.1.9 >> start >> No.1
        if((cameraListWindow == null) && (cameraListComponent != null)) {
            if (cameraListComponent.status == Component.Ready) {
                cameraListWindow = cameraListComponent.createObject(root);
                // IVC >> Ver.1.9 >> start >> [THRBOXV100-58]
                cameraListWindow.initCameraSetting();
                // IVC << Ver.1.9 << end << [THRBOXV100-58]
                cameraListWindow.visible = false
                cameraListInitFlg = true
            } else {
                cameraListComponent.onStatusChanged.connect(function(status) {
                    if (status == Component.Ready) {
                        cameraListWindow = cameraListComponent.createObject(root);
                        // IVC >> Ver.1.9 >> start >> [THRBOXV100-58]
                        cameraListWindow.initCameraSetting();
                        // IVC << Ver.1.9 << end << [THRBOXV100-58]
                        initCameraListWindow(arg)
                    }
                });
            }
        }
        // IVC << Ver.1.9 << end << No.1
        if((previewWindow == null) && (previewComponent != null)) {
            if(previewComponent.status == Component.Ready) {
                previewWindow = previewComponent.createObject(root);
                previewWindow.visible = false
                previewInitFlg = true
            } else {
                previewComponent.onStatusChanged = function(status) {
                    if (status == Component.Ready) {
                        previewWindow = previewComponent.createObject(root);
                    }
                }
            }
        }
        if((preferenceWindow == null) && (preferenceComponent != null)) {
            if(preferenceComponent.status == Component.Ready) {
                preferenceWindow = preferenceComponent.createObject(root);
                preferenceWindow.visible = false
                preferenceInitFlg = true
            } else {
                preferenceComponent.onStatusChanged = function(status) {
                    if (status == Component.Ready) {
                        preferenceWindow = preferenceComponent.createObject(root);
                        initPreferenceWindow(arg)
                    }
                }
            }
        }
        if((searchCameraListWindow == null) && (searchCameraListComponent != null)) {
            if(searchCameraListComponent.status == Component.Ready) {
                searchCameraListWindow = searchCameraListComponent.createObject(root);
                searchCameraListWindow.visible = false
                searchCameraListInitFlg = true
            } else {
                if( searchCameraListComponent.status === Component.Error){
                    console.log( Component.errorString())
                }

                searchCameraListComponent.onStatusChanged = function(status) {
                    if (status == Component.Ready) {
                        searchCameraListWindow = searchCameraListComponent.createObject(root);
                        initSearchCameraListWindow(arg)
                    }
                }
            }
        }

        if(mainInitFlg == true) {
            initMainWindow(arg)
        }
        if(liveViewInitFlg == true) {
            initLiveViewWindow(arg)
        }
        // IVC >> Ver.1.9 >> start >> No.1
        if(cameraListInitFlg == true) {
            initCameraListWindow(arg)
        }
        // IVC << Ver.1.9 << end << No.1
        if(flashInitFlg == true) {
            initFlashWindow(arg)
        }
        if(previewInitFlg == true) {
        }
        if(preferenceInitFlg == true) {
            initPreferenceWindow(arg)
        }
        if(searchCameraListInitFlg == true){
        }

        // IVC >> Ver.1.9 >> start >> [THRBOXV100-81]
        mainWindow.initSetupTetherMode();
        liveViewWindow.initSetupTetherMode();
        // IVC << Ver.1.9 << end << [THRBOXV100-81]
        // IVC << Ver.1.9 >> start >> [THRBOXV100-113] [THRBOXV100-114]
        deviceAdapter.ptpip_enhance_security_active_password_dialog()
        // IVC << Ver.1.9 << end << [THRBOXV100-113] [THRBOXV100-114]
        var date2 = new Date()
        LTSubFunction.console_debug.out("initWindows end = " + date2.getHours() + ":" + date2.getMinutes() + ":" + date2.getSeconds() + ":" + date2.getMilliseconds())
    }
    function initMainWindow(arg) {
        mainWindow.toggleLiveView.connect(function() {
            if(liveViewWindow.visibility == Window.Minimized) {
                liveViewWindow.visibility = Window.Windowed
            }
            liveViewWindow.visible = !liveViewWindow.visible;
        });
        // IVC >> Ver.1.9 >> start >> No.1
        mainWindow.toggleCameraList.connect(function() {
            if(cameraListWindow.visibility == Window.Minimized) {
                cameraListWindow.visibility = Window.Windowed
            }
            cameraListWindow.visible = !cameraListWindow.visible;
        });
        // IVC << Ver.1.9 << end << No.1

        mainWindow.toggleFlashView.connect(function() {
            if(flashWindow.visibility == Window.Minimized) {
                flashWindow.visibility = Window.Windowed
            }
            flashWindow.visible = !flashWindow.visible;
        });

        mainWindow.togglePreviewView.connect(function() {
            if (applicationSettings.imageViewerType == LT.ApplicationSettings.ImageViewerType_Std) {
                previewWindow.visible = !previewWindow.visible;

            } else {
                //Load ImageViewer (default argument)
//                var arg = appPath + "..\\..\\..\\App\\src\\resources\\images\\picture.png";

//                utilities.loadImageViewer(applicationSettings.imageViewerUrl, arg);
            }
        });

        mainWindow.togglePreferenceView.connect(function() {
            preferenceWindow.visible = !preferenceWindow.visible;
        });

        mainWindow.changePreviewTypePopup.connect(function() {
            if (applicationSettings.imageViewerType == LT.ApplicationSettings.ImageViewerType_Std) {
                if(!previewWindow.visible) {
                    var windowflg = previewWindow.flg
                    windowflg &= ~Qt.Window
                    windowflg |= Qt.Popup
                    previewWindow.flags = windowflg
                }
            }
        });

        mainWindow.changePreviewTypeWindow.connect(function() {
            if (applicationSettings.imageViewerType == LT.ApplicationSettings.ImageViewerType_Std) {
                var windowflg = previewWindow.flg
                windowflg &= ~Qt.Popup
                windowflg |= Qt.Window
                previewWindow.flags = windowflg
            }
        });

        mainWindow.recStart.connect(function() {
            liveViewWindow.recStart()
        });

        mainWindow.recStop.connect(function() {
            liveViewWindow.recStop()
        });

// ivc >> start >> No.8
        mainWindow.recBulbStart.connect(function() {
            liveViewWindow.recBulbStart()
        });

        mainWindow.recBulbStop.connect(function() {
            liveViewWindow.recBulbStop()
        });
// ivc << end << No.8

        mainWindow.liveViewStart.connect(function() {
            //videoImageInfo.videoImageStatus = LT.VideoImageInfo.VIS_Start
            LTSubFunction.console_debug.out("mainWindow.liveViewStart call liveViewUpdate")
            liveViewWindow.liveViewUpdate(true)
        });

        mainWindow.liveViewStop.connect(function() {
            //videoImageInfo.videoImageStatus = LT.VideoImageInfo.VIS_Stop
            LTSubFunction.console_debug.out("mainWindow.liveViewStop call liveViewUpdate")
            liveViewWindow.liveViewUpdate(false)
        });

        mainWindow.afaeStart.connect(function() {
            liveViewWindow.afaeStart()
        });

        mainWindow.afaeStop.connect(function() {
            liveViewWindow.afaeStop()
        });

        mainWindow.tetherModeUpdate.connect(function(){
            //TetherModeの変更可能状態を設定
            cameraListWindow.tetherModeButtonUpdate()
        });

        mainWindow.onClosing.connect(function() {
            //videoImageInfo.videoImageStatus = LT.VideoImageInfo.VIS_Stop;
            LTSubFunction.console_debug.out("mainWindow.onClosing call liveViewUpdate")

            // IVC >> Ver.1.9 >> start >> [THRBOXV100-116]
            //liveViewWindow.liveViewUpdate(false)
            liveViewWindow.liveviewForceClose()
            // IVC << Ver.1.9 << end << [THRBOXV100-116]

            if(!disconnectFlg) {
                deviceAdapter.deviceSearch.stopSearch();
            }
// IVC >> Ver.1.9 >> start >> [THRBOXV100-61]
            // IVC >> Ver.1.9 >> start >> No.1
            //if(!disconnectFlg) {
            //    connectionEvent.checkStop();
            //}
            // IVC << Ver.1.9 << end << No.1
// IVC << Ver.1.9 << end << [THRBOXV100-61]
            if(!disconnectFlg) {
                deviceAdapter.stopCallbackThread();
                flashAdapter.stopCallbackThread();
                deviceAdapter.adp_LMX_func_api_CloseSession();
                // IVC >> Ver.1.9 >> start >> [THRBOXV100-56]
                //deviceAdapter.adp_LMX_func_api_Finish();
                // IVC << Ver.1.9 << end << [THRBOXV100-56]
            }

            //Save visible state before closing
            applicationSettings.setWinStateVisibleForWindow(LT.ApplicationSettings.WinList_Flash, flashWindow.visible);
            applicationSettings.setWinStateVisibleForWindow(LT.ApplicationSettings.WinList_Live, liveViewWindow.visible);
            // IVC >> Ver.1.9 >> start >> No.1
            applicationSettings.setWinStateVisibleForWindow(LT.ApplicationSettings.WinList_CamList, cameraListWindow.visible);
            // IVC << Ver.1.9 << end << No.1
            applicationSettings.setWinStateVisibleForWindow(LT.ApplicationSettings.WinList_Preference, preferenceWindow.visible);
            applicationSettings.setWinStateVisibleForWindow(LT.ApplicationSettings.WinList_Preview, previewWindow.visible);

/*
#ifdef PREVIEW_EXTERN
            //Close preview app
            deviceAdapter.closePreviewApp()
#endif
*/

            //Close opened windows
            if (liveViewWindow.visible) {
                liveViewWindow.close();
            }
            // IVC >> Ver.1.9 >> start >> No.1
            if (cameraListWindow.visible) {
                cameraListWindow.close();
            }
            // IVC << Ver.1.9 << end << No.1
            if (previewWindow.visible) {
                previewWindow.close();
            }
            if (preferenceWindow.visible) {
                preferenceWindow.close();
            }
            if (flashWindow.visible) {
                flashWindow.close();
            }
            if (versionUpDialog.visible) {
                versionUpDialog.close();
            }
            if (searchCameraListWindow.visible) {
                searchCameraListWindow.close();
            }
            if(!disconnectFlg) {
                //root.connectWindowClose()
                // IVC >> Ver.1.9 >> start >> [THRBOXV100-56]
                deviceAdapter.adp_LMX_func_api_Finish();
                // IVC << Ver.1.9 << end << [THRBOXV100-56]
                //Checking log condition
                if (applicationSettings.logPermission == LT.ApplicationSettings.LogPer_On) {
                    //console.log("App closing: Call send log");
                    logCollector.onRequestFinished.connect(root.quitApp);
                    logCollector.sendLog(LT.TagDef.RecSend_Auto);

                } else {
                    //Quit app
                    //console.log("App closing: Call quit");
                    quitApp();
                }
            }
            disconnectFlg = false
        });

        mainWindow.cameraValueGetComplete();
        mainWindow.compact = applicationSettings.windowSize == LT.ApplicationSettings.WindowShrinked;
        mainWindow.visible = arg;
    }

    function closeMainView() {
        //videoImageInfo.videoImageStatus = LT.VideoImageInfo.VIS_Stop;
        LTSubFunction.console_debug.out("mainWindow.onVisibleChanged")

        // IVC >> Ver.1.9 >> start >> [THRBOXV100-116]
        //liveViewWindow.liveViewUpdate(false)
        liveViewWindow.liveviewForceClose()
        // IVC << Ver.1.9 << end << [THRBOXV100-116]

        if(!disconnectFlg) {
            deviceAdapter.deviceSearch.stopSearch();
        }
// IVC >> Ver.1.9 >> start >> [THRBOXV100-61]
        // IVC >> Ver.1.9 >> start >> No.1
        //if(!disconnectFlg) {
        //    connectionEvent.checkStop();
        //}
        // IVC << Ver.1.9 << end << No.1
// IVC << Ver.1.9 << end << [THRBOXV100-61]
        if(!disconnectFlg) {
            deviceAdapter.stopCallbackThread();
            flashAdapter.stopCallbackThread();
            deviceAdapter.adp_LMX_func_api_CloseSession();
            // IVC >> Ver.1.9 >> start >> [THRBOXV100-56]
            //deviceAdapter.adp_LMX_func_api_Finish();
            // IVC << Ver.1.9 << end << [THRBOXV100-56]
        }

        //Save visible state before closing
        applicationSettings.setWinStateVisibleForWindow(LT.ApplicationSettings.WinList_Flash, flashWindow.visible);
        applicationSettings.setWinStateVisibleForWindow(LT.ApplicationSettings.WinList_Live, liveViewWindow.visible);
        // IVC >> Ver.1.9 >> start >> No.1
        applicationSettings.setWinStateVisibleForWindow(LT.ApplicationSettings.WinList_CamList, cameraListWindow.visible);
        // IVC << Ver.1.9 << end << No.1
        applicationSettings.setWinStateVisibleForWindow(LT.ApplicationSettings.WinList_Preference, preferenceWindow.visible);
        applicationSettings.setWinStateVisibleForWindow(LT.ApplicationSettings.WinList_Preview, previewWindow.visible);

        //Close opened windows
        if (liveViewWindow.visible) {
            //liveViewWindow.close();
            liveViewWindow.visible = false
        }
        // IVC >> Ver.1.9 >> start >> No.1
        if (cameraListWindow.visible) {
            cameraListWindow.close();
        }
        // IVC << Ver.1.9 << end << No.1
        if (previewWindow.visible) {
            previewWindow.close();
        }
        if (preferenceWindow.visible) {
            preferenceWindow.close();
        }
        if (flashWindow.visible) {
            flashWindow.close();
        }
        if (versionUpDialog.visible) {
            versionUpDialog.close();
        }
        if (searchCameraListWindow.visible) {
            searchCameraListWindow.close();
        }
        if(!disconnectFlg) {
            //root.connectWindowClose()
            // IVC >> Ver.1.9 >> start >> [THRBOXV100-56]
            deviceAdapter.adp_LMX_func_api_Finish();
            // IVC << Ver.1.9 << end << [THRBOXV100-56]
            //Checking log condition
            if (applicationSettings.logPermission == LT.ApplicationSettings.LogPer_On) {
                //console.log("App closing: Call send log");
                logCollector.onRequestFinished.connect(root.quitApp);
                logCollector.sendLog(LT.TagDef.RecSend_Auto);

            } else {
                //Quit app
                //console.log("App closing: Call quit");
                quitApp();
            }
        }
        disconnectFlg = false
    }

    function closeConnectWindow()
    {
        //接続中やメイン画面出てるときは無効にする
        if( mainWindow.visible
            || deviceAdapter.camConnectStatus === LT.Utilities.CamConnectSts_GetData
            || deviceAdapter.camConnectStatus === LT.Utilities.CamConnectSts_GetDataBackground
            ){
            connectWindow.close.accepted = false
            return
        }
        connectWindow.onSearchCompleted.disconnect(root.searchCompleted)
        searchCameraListWindow.close()

        if(!disconnectFlg) {
            deviceAdapter.deviceSearch.stopSearch();
            deviceAdapter.stopCallbackThread();
            flashAdapter.stopCallbackThread();
            deviceAdapter.adp_LMX_func_api_CloseSession();
        }
        deviceAdapter.adp_LMX_func_api_Finish()
        quitApp();
    }

    function closeSearchCameraListWindow()
    {
        if( mainWindow.visible ){
            //メイン画面表示中はカメラリストでの更新で表示なので非表示にだけする
            searchCameraListWindow.close.accepted = false
            searchCameraListWindow.visible = false
            return
        }

        connectWindow.onSearchCompleted.disconnect(root.searchCompleted)
        if(!disconnectFlg) {
            deviceAdapter.deviceSearch.stopSearch();
            deviceAdapter.stopCallbackThread();
            flashAdapter.stopCallbackThread();
            deviceAdapter.adp_LMX_func_api_CloseSession();
        }
        deviceAdapter.adp_LMX_func_api_Finish()

        quitApp();
    }

    function initLiveViewWindow(arg) {
        liveViewWindow.cameraValueGetComplete();
        if(arg) {
            liveViewWindow.visible = applicationSettings.winStateVisibleForWindow(LT.ApplicationSettings.WinList_Live);
        } else {
            liveViewWindow.visible = false
        }
    }

    // IVC >> Ver.1.9 >> start >> No.1
    function initCameraListWindow(arg) {
        //cameraListWindow.cameraValueGetComplete();
        if(arg) {
            cameraListWindow.visible = applicationSettings.winStateVisibleForWindow(LT.ApplicationSettings.WinList_CamList);
        } else {
            cameraListWindow.visible = false
        }
    }
    // IVC << Ver.1.9 << end << No.1

    function initFlashWindow(arg) {
        flashWindow.cameraValueGetComplete();
        if(arg) {
            flashWindow.visible = applicationSettings.winStateVisibleForWindow(LT.ApplicationSettings.WinList_Flash);
        } else {
            flashWindow.visible = false
        }
    }

    function initPreferenceWindow(arg) {
        if(arg) {
            preferenceWindow.visible = applicationSettings.winStateVisibleForWindow(LT.ApplicationSettings.WinList_Preference);
        } else {
            preferenceWindow.visible = false
        }
    }

    function initSearchCameraListWindow(arg) {
        if(arg) {
            searchCameraListWindow.visible = true
        } else {
            searchCameraListWindow.visible = false
        }
    }

    function notifyConnectErrorMessage(mode, cameraName, errCode){
        var message = ""
        message += qsTr("Connect error_msg1")
        message += "\r\n\r\n"
        message += qsTr("Connect error_msg2") + " : "
        message += cameraName
        message += "\r\n"
        message += qsTr("Connect error_msg3") + " : "
        var hexString = errCode.toString(16).toUpperCase()
        while(hexString.length < 8){
            hexString = "0" + hexString
        }
        message += "0x" + hexString
        message += "\r\n"
        if( mode === 1){
            message += "\r\n"
            message += qsTr("Connect error_msg4")
            message += "\r\n"
            message += qsTr("Connect error_msg4_1")
            message += "\r\n"
            message += qsTr("Connect error_msg4_2")
            message += "\r\n"
            message += qsTr("Connect error_msg4_3")
        }
        errorDialog.text = message
        errorDialog.visible = true
    }

    function quitApp() {
        Qt.quit();
    }
}
