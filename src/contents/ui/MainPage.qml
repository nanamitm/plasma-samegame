/**
 * SPDX-FileCopyrightText: (C) 2013 Digia Plc and/or its subsidiary(-ies)
 *
 * SPDX-LicenseRef: BSD-3-Clause
 */

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "samegame.js" as SameGame

Page {
    id: root
    header: null

    background: Image {
        id: background
        anchors.fill: parent
        source: "qrc:///shared/pics/background.jpg"
        fillMode: Image.PreserveAspectCrop
    }

    Item {
        id: gameCanvas
        property int score: 0
        property int blockSize: width / 8

        Component.onCompleted: console.log(width)

        anchors.fill: parent

        MouseArea {
            anchors.fill: parent
            onClicked: SameGame.handleClick(mouse.x, mouse.y)
        }
    }

    Dialog {
        id: dialog
        anchors.centerIn: parent
        z: 100
    }

    //![0]
    Dialog {
        id: nameInputDialog
        anchors.centerIn: parent
        z: 100

        onClosed: {
            if (nameInputDialog.inputText.length > 0) {
                SameGame.saveHighScore(nameInputDialog.inputText);
            }
        }
    }
    //![0]

    footer: ToolBar {
        id: toolBar
        RowLayout {
            anchors.fill: parent
            ToolButton {
                text: qsTr("New Game")
                onClicked: SameGame.startNewGame()
            }

            ToolButton {
                text: qsTr("Quit")
                onClicked: Qt.quit()
            }

            Label {
                text: qsTr("Score: ") + gameCanvas.score
            }
        }
    }
}
