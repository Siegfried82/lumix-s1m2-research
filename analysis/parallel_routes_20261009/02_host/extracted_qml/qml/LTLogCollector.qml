import QtQuick 2.6

import "qrc:/qml"
import LT 1.0 as LT
import "LTSubFunction.js" as LTSubFunction

Item {
    id: root

///////////////////////////////////////////////////////////////////////////////
/// log function
///////////////////////////////////////////////////////////////////////////////
    /*!
        Log Tag ID
     */
    property int logMajTagID
    property int logMedTagID

    property string logWindowName: ""

    /*!
        Log enable
     */
    property bool logEnable: true

    function log(logLevel, logScrTagID, logFile, logText) {
//        LTSubFunction.console_debug.out_colletor("LOG_COLLECTOR: log", logFile, logText)
        if (logEnable) {
            var fileContent = (logWindowName.length>0) ? logWindowName + ": " + logFile : logFile;

            logCollector.writeLog(logLevel, logMajTagID, logMedTagID, logScrTagID, fileContent, logText);
        }
    }
}
