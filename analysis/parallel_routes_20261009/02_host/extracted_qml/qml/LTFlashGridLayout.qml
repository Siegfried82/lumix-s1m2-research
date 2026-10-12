//ndtri - add - LTFlashGridLayout
import QtQuick 2.6
import QtQuick.Layouts 1.1

GridLayout {

    property double colMulti: 107

    property double rowMulti: 77

    width: colMulti*columns + columnSpacing*(columns-1)
    height: rowMulti*rows + columnSpacing*(rows-1)

    function prefWidth(item) {
        return colMulti * item.Layout.columnSpan + columnSpacing * (item.Layout.columnSpan - 1)
    }
    function prefHeight(item) {
        return rowMulti * item.Layout.rowSpan + rowSpacing * (item.Layout.rowSpan - 1)
    }
}
