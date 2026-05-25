/**
 * SPDX-FileCopyrightText: (C) 2020 Carl Schwan <carl@carlschwan.eu>
 * SPDX-FileCopyrightText: (C) 2013 Digia Plc and/or its subsidiary(-ies)
 *
 * SPDX-LicenseRef: GPL-3.0-or-later
 */

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import QtMultimedia
import Qt.labs.settings 1.0
import "samegame.js" as SameGame

Controls.ApplicationWindow {
    id: root
    visible: true
    width: 480
    height: 800
    minimumWidth: gameCanvas.blockSize * 4
    minimumHeight: gameCanvas.blockSize * 4 + toolBar.height
    title: qsTr("Samegame")

    property bool gameStarted: false
    property int displayScore: 0
    property bool bgmEnabled: appSettings.bgmEnabled

    // 設定の永続化
    Settings {
        id: appSettings
        property bool bgmEnabled: true
        property real bgmVolume: 0.45
    }

    // BGM プレイヤー
    MediaPlayer {
        id: bgmPlayer
        source: "qrc:/contents/ui/sounds/bgm.ogg"
        loops: MediaPlayer.Infinite
        audioOutput: AudioOutput {
            id: bgmAudio
            volume: appSettings.bgmVolume
        }
        Component.onCompleted: if (appSettings.bgmEnabled) bgmPlayer.play()
    }

    Timer {
        id: resizeTimer
        interval: 300
        onTriggered: if (root.gameStarted) SameGame.startNewGame()
    }

    // --- 演出1: スコアカウンターアニメーション ---
    NumberAnimation {
        id: scoreCountAnim
        target: root
        property: "displayScore"
        duration: 400
        easing.type: Easing.OutCubic
    }

    // --- 演出2: スコアポップアップ ---
    Component {
        id: scorePopupComp
        Text {
            id: popup
            font.bold: true
            font.pixelSize: 24
            color: "yellow"
            style: Text.Outline
            styleColor: "black"
            z: 200

            ParallelAnimation {
                id: floatAnim
                NumberAnimation {
                    id: yAnim
                    target: popup; property: "y"
                    duration: 800; easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: popup; property: "opacity"
                    to: 0; duration: 800
                }
                onFinished: popup.destroy()
            }

            Component.onCompleted: {
                yAnim.from = popup.y
                yAnim.to   = popup.y - 80
                floatAnim.start()
            }
        }
    }

    function showScorePopup(x, y, points) {
        scorePopupComp.createObject(gameCanvas, {
            x: x - 20, y: y - 20,
            text: "+" + points
        })
    }

    // --- 演出3: スクリーンシェイク ---
    SequentialAnimation {
        id: shakeAnim
        PropertyAnimation { target: shakeTransform; property: "x"; to:  10; duration: 40 }
        PropertyAnimation { target: shakeTransform; property: "x"; to: -10; duration: 40 }
        PropertyAnimation { target: shakeTransform; property: "x"; to:   6; duration: 40 }
        PropertyAnimation { target: shakeTransform; property: "x"; to:  -6; duration: 40 }
        PropertyAnimation { target: shakeTransform; property: "x"; to:   0; duration: 40 }
    }

    Image {
        anchors.fill: parent
        source: "shared/pics/background.jpg"
        fillMode: Image.PreserveAspectCrop
    }

    Item {
        id: gameCanvas
        property int score: 0
        property int blockSize: 48

        anchors.fill: parent
        transform: Translate { id: shakeTransform }

        onWidthChanged: resizeTimer.restart()
        onHeightChanged: resizeTimer.restart()

        onScoreChanged: {
            if (score === 0) {
                scoreCountAnim.stop()
                root.displayScore = 0
            } else {
                scoreCountAnim.to = score
                scoreCountAnim.restart()
            }
        }

        // --- 演出4: ゲームオーバー時のフェードアウトオーバーレイ ---
        Rectangle {
            id: gameOverOverlay
            anchors.fill: parent
            color: "black"
            opacity: 0
            z: 50
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation { duration: 600 }
            }

            // オーバーレイ表示中はクリックを吸収する
            MouseArea { anchors.fill: parent }
        }

        // 連結数バッジ
        Rectangle {
            id: hoverBadge
            visible: false
            width: badgeText.implicitWidth + 14
            height: badgeText.implicitHeight + 8
            radius: 10
            color: "#cc000000"
            border.color: "white"
            border.width: 1
            z: 150

            Text {
                id: badgeText
                anchors.centerIn: parent
                color: "white"
                font.pixelSize: 13
                font.bold: true
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            onPositionChanged: (mouse) => {
                if (!root.gameStarted) return
                const blocks = SameGame.getConnectedBlocks(mouse.x, mouse.y)
                SameGame.clearHighlights()
                if (blocks.length >= 2) {
                    blocks.forEach(b => b.highlighted = true)
                    badgeText.text = blocks.length + " blocks"
                    // バッジがはみ出さないよう位置を調整
                    hoverBadge.x = Math.min(mouse.x + 12,
                                            gameCanvas.width  - hoverBadge.width  - 4)
                    hoverBadge.y = Math.max(mouse.y - hoverBadge.height - 8, 4)
                    hoverBadge.visible = true
                } else {
                    hoverBadge.visible = false
                }
            }

            onExited: {
                SameGame.clearHighlights()
                hoverBadge.visible = false
            }

            onClicked: (mouse) => {
                SameGame.clearHighlights()
                hoverBadge.visible = false
                const scoreBefore = gameCanvas.score
                SameGame.handleClick(mouse.x, mouse.y)
                const gained = gameCanvas.score - scoreBefore
                if (gained > 0) {
                    root.showScorePopup(mouse.x, mouse.y, gained)
                    if (gained >= 36) // 7個以上消去でシェイク
                        shakeAnim.restart()
                }
            }
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

        onVisibleChanged: gameOverOverlay.opacity = visible ? 0.6 : 0

        onClosed: {
            if (nameInputDialog.inputText.length > 0) {
                SameGame.saveHighScore(nameInputDialog.inputText);
            }
        }
    }
    //![0]

    footer: Controls.ToolBar {
        id: toolBar
        RowLayout {
            anchors.fill: parent
            Controls.ToolButton {
                text: qsTr("New Game")
                onClicked: {
                    root.gameStarted = true
                    SameGame.startNewGame()
                }
            }
            Controls.ToolButton {
                text: qsTr("Quit")
                onClicked: Qt.quit()
            }
            Controls.Label {
                Layout.fillWidth: true
                text: qsTr("Score: ") + root.displayScore
            }
            Controls.ToolButton {
                text: root.bgmEnabled ? qsTr("♪ ON") : qsTr("♪ OFF")
                onClicked: {
                    root.bgmEnabled = !root.bgmEnabled
                    appSettings.bgmEnabled = root.bgmEnabled
                    if (root.bgmEnabled) {
                        bgmPlayer.play()
                    } else {
                        bgmPlayer.pause()
                    }
                }
            }
            Controls.Slider {
                id: volumeSlider
                from: 0.0
                to: 1.0
                value: appSettings.bgmVolume
                stepSize: 0.05
                enabled: root.bgmEnabled
                opacity: root.bgmEnabled ? 1.0 : 0.4
                implicitWidth: 80
                onMoved: {
                    bgmAudio.volume = value
                    appSettings.bgmVolume = value
                }

                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
        }
    }
}
