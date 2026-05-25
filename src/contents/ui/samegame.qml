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
import QtCore
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
    property bool bgmEnabled:    appSettings.bgmEnabled
    property bool popEnabled:    appSettings.popEnabled
    property bool jingleEnabled: appSettings.jingleEnabled

    // 設定の永続化
    Settings {
        id: appSettings
        property bool bgmEnabled:    true
        property real bgmVolume:     0.45
        property bool popEnabled:    true   // ブロック消去音
        property real popVolume:     0.7
        property bool jingleEnabled: true   // クリア／失敗ジングル
        property real jingleVolume:  0.7
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

    // SFX — SoundEffect は WAV のみ保証のため MediaPlayer を使用
    property real popVol:    appSettings.popVolume
    property real jingleVol: appSettings.jingleVolume

    // ブロック消去音：stop() → play() で即時再生
    function playSfx(player) {
        player.stop()
        player.play()
    }

    // ジングル：BGM を止めてから再生し、終了後に BGM を再開
    function playJingle(player) {
        if (root.bgmEnabled) bgmPlayer.pause()
        player.play()
    }

    // ブロック消去音
    MediaPlayer {
        id: popSfx
        source: "qrc:/contents/ui/sounds/pop.ogg"
        audioOutput: AudioOutput { volume: root.popVol }
    }
    // スコアポップアップ用クリック音
    MediaPlayer {
        id: clickSfx
        source: "qrc:/contents/ui/sounds/click.ogg"
        audioOutput: AudioOutput { volume: root.popVol }
    }
    // クリア／失敗ジングル（再生終了時に BGM を再開）
    MediaPlayer {
        id: clearSfx
        source: "qrc:/contents/ui/sounds/clear.ogg"
        audioOutput: AudioOutput { volume: root.jingleVol }
        onPlaybackStateChanged:
            if (playbackState === MediaPlayer.StoppedState && root.bgmEnabled)
                bgmPlayer.play()
    }
    MediaPlayer {
        id: failureSfx
        source: "qrc:/contents/ui/sounds/failure.ogg"
        audioOutput: AudioOutput { volume: root.jingleVol }
        onPlaybackStateChanged:
            if (playbackState === MediaPlayer.StoppedState && root.bgmEnabled)
                bgmPlayer.play()
    }

    Timer {
        id: resizeTimer
        interval: 300
        onTriggered: if (root.gameStarted) SameGame.startNewGame()
    }

    // スコアポップアップのクリック音を少し遅らせて消去音と分離
    Timer {
        id: clickSfxTimer
        interval: 180
        onTriggered: if (root.popEnabled) playSfx(clickSfx)
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
        clickSfxTimer.restart()   // 180ms 後にクリック音を再生
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
                    if (root.popEnabled) root.playSfx(popSfx)
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

        onVisibleChanged: {
            gameOverOverlay.opacity = visible ? 0.6 : 0
            if (visible && root.jingleEnabled) {
                if (gameCanvas.score > 0) root.playJingle(clearSfx)
                else root.playJingle(failureSfx)
            }
        }

        onClosed: {
            if (nameInputDialog.inputText.length > 0) {
                SameGame.saveHighScore(nameInputDialog.inputText);
            }
        }
    }
    //![0]

    // 音声設定ポップアップ
    Controls.Popup {
        id: audioPopup
        parent: Controls.Overlay.overlay   // ウィンドウ全体を親にする
        modal: false
        focus: true
        closePolicy: Controls.Popup.CloseOnEscape | Controls.Popup.CloseOnPressOutside
        padding: 12

        // ツールバーの設定ボタンの真上（右寄せ）に表示
        x: parent.width  - width  - 4
        y: parent.height - height - toolBar.height - 4

        GridLayout {
            columns: 3
            columnSpacing: 8
            rowSpacing: 6

            // ヘッダ
            Controls.Label { text: qsTr("BGM");    font.bold: true }
            Controls.ToolButton {
                text: root.bgmEnabled ? qsTr("ON") : qsTr("OFF")
                onClicked: {
                    root.bgmEnabled = !root.bgmEnabled
                    appSettings.bgmEnabled = root.bgmEnabled
                    if (root.bgmEnabled) bgmPlayer.play()
                    else bgmPlayer.pause()
                }
            }
            Controls.Slider {
                from: 0.0; to: 1.0
                value: appSettings.bgmVolume
                stepSize: 0.05
                enabled: root.bgmEnabled
                opacity: root.bgmEnabled ? 1.0 : 0.4
                implicitWidth: 120
                onMoved: { bgmAudio.volume = value; appSettings.bgmVolume = value }
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }

            Controls.Label { text: qsTr("SE");     font.bold: true }
            Controls.ToolButton {
                text: root.popEnabled ? qsTr("ON") : qsTr("OFF")
                onClicked: {
                    root.popEnabled = !root.popEnabled
                    appSettings.popEnabled = root.popEnabled
                }
            }
            Controls.Slider {
                from: 0.0; to: 1.0
                value: appSettings.popVolume
                stepSize: 0.05
                enabled: root.popEnabled
                opacity: root.popEnabled ? 1.0 : 0.4
                implicitWidth: 120
                onMoved: { root.popVol = value; appSettings.popVolume = value }
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }

            Controls.Label { text: qsTr("Jingle"); font.bold: true }
            Controls.ToolButton {
                text: root.jingleEnabled ? qsTr("ON") : qsTr("OFF")
                onClicked: {
                    root.jingleEnabled = !root.jingleEnabled
                    appSettings.jingleEnabled = root.jingleEnabled
                }
            }
            Controls.Slider {
                from: 0.0; to: 1.0
                value: appSettings.jingleVolume
                stepSize: 0.05
                enabled: root.jingleEnabled
                opacity: root.jingleEnabled ? 1.0 : 0.4
                implicitWidth: 120
                onMoved: { root.jingleVol = value; appSettings.jingleVolume = value }
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
        }
    }

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
                id: settingsButton
                text: qsTr("⚙")
                onClicked: audioPopup.open()
            }
        }
    }
}
