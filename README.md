# Samegame

A SameGame clone built with **Qt6 / QML**, playable on Windows, Linux, and Android.

Originally based on [KDE/plasma-samegame](https://github.com/KDE/plasma-samegame), rewritten to remove all KDE framework dependencies and run on pure Qt6.

![License](https://img.shields.io/badge/license-GPL--3.0-blue)
![Qt](https://img.shields.io/badge/Qt-6.4%2B-green)

---

## ゲームルール

同じ色のブロックが2つ以上隣接している箇所をクリックすると消去できます。  
まとめて消すほど高得点。全消しでボーナス500点。

| 消去数 | 得点 |
|--------|------|
| 2個 | 1点 |
| 5個 | 16点 |
| 10個 | 81点 |
| 全消し | +500点ボーナス |

---

## 機能

- **動的グリッド** — ウィンドウサイズに合わせて列数・行数が自動調整（ブロックサイズ固定48px）
- **スコアポップアップ** — クリック位置に獲得点数が浮かび上がる
- **スクリーンシェイク** — 7個以上の連鎖消去で画面が揺れる
- **スコアカウンターアニメーション** — 点数が滑らかにカウントアップ
- **ゲームオーバー演出** — 終了時に残ブロックがフェードアウト
- **ホバーハイライト** — マウスを乗せると同色の連結ブロックが光る
- **連結数バッジ** — ホバー中に消去可能なブロック数を表示
- **BGM** — ループ再生、ツールバーの `♪ ON / ♪ OFF` ボタンで切り替え可能

---

## 動作環境

| プラットフォーム | 状態 |
|---|---|
| Windows | ✅ |
| Linux | ✅ |
| Android | ✅ (Qt6 クロスビルド) |

---

## ビルド方法

### 必要なもの

- Qt 6.4 以上（以下のモジュールを含む）
  - Qt Quick / Qt Quick Controls 2
  - Qt Multimedia
  - Qt SQL
  - Qt SVG
- CMake 3.16 以上
- C++17 対応コンパイラ

### Qt Creator を使う場合（推奨）

1. Qt Creator でルートの `CMakeLists.txt` を開く
2. ビルドキットを選択して実行

### コマンドラインの場合

```bash
cmake -B build -DCMAKE_PREFIX_PATH=/path/to/Qt/6.x.x/<platform>
cmake --build build
```

Windows（MinGW）の例:

```powershell
cmake -B build -G "Ninja" `
    -DCMAKE_PREFIX_PATH="C:/Qt/6.11.1/mingw_64" `
    -DCMAKE_C_COMPILER="C:/Qt/Tools/mingw1310_64/bin/gcc.exe" `
    -DCMAKE_CXX_COMPILER="C:/Qt/Tools/mingw1310_64/bin/g++.exe"
cmake --build build
```

### Linux の追加要件

BGM 再生に GStreamer プラグインが必要です:

```bash
sudo apt install gstreamer1.0-plugins-good gstreamer1.0-plugins-bad
```

---

## プロジェクト構成

```
plasma-samegame/
├── CMakeLists.txt
├── src/
│   ├── main.cpp                        # エントリポイント
│   ├── CMakeLists.txt
│   └── contents/ui/
│       ├── samegame.qml                # メインウィンドウ・ゲームUI
│       ├── samegame.js                 # ゲームロジック
│       ├── BoomBlock.qml               # ブロックコンポーネント
│       ├── Dialog.qml                  # スコア表示・入力ダイアログ
│       ├── sounds/
│       │   └── bgm.ogg                 # BGM（CC0）
│       └── shared/pics/                # ブロック・背景画像
└── org.kde.samegame.desktop
```

---

## KDE 依存の除去について

オリジナルは KDE Frameworks（Kirigami・KI18n・KCoreAddons・KDeclarative）に依存していましたが、本フォークでは純粋な Qt6 のみで動作するよう書き直しました。

| 変更前 (KDE) | 変更後 (Qt6) |
|---|---|
| `Kirigami.ApplicationWindow` | `ApplicationWindow` |
| `Kirigami.Page` | ウィンドウに統合 |
| `KAboutData` | `QGuiApplication` 標準 API |
| `KLocalizedString` / `i18n()` | `qsTr()` |
| `KLocalizedContext` | 不要 |

---

## クレジット

- **ゲームロジック原作**: Qt Company（SameGame デモ、BSD-3-Clause）
- **KDE 版**: Sebastian Kügler, Carl Schwan（GPL-3.0）
- **BGM**: "Cozy Puzzle In-Game 1" by MintoDog（[OpenGameArt.org](https://opengameart.org/content/cozy-puzzle-in-game-1)、CC0）
- **ブロック・背景画像**: Qt Company（BSD-3-Clause）

---

## ライセンス

GPL-3.0-or-later — 詳細は [COPYING](COPYING) を参照。  
BGM は CC0（パブリックドメイン）。
