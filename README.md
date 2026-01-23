# Wallpaper Hub

macOS向けの動的壁紙管理アプリケーション - Wallpaper Engineのようなアプリ

## 概要

Wallpaper Hubは、macOSで動的な壁紙を簡単に管理・設定できるネイティブアプリケーションです。画像や動画ファイルをドラッグ&ドロップで追加し、複数ディスプレイに対応した壁紙設定が可能です。

## 主要機能

- **壁紙管理**: アプリ内で壁紙コレクションを保存・管理
- **ファイル選択**: 画像・動画ファイルを簡単に追加
- **ドラッグ&ドロップ**: 直感的なファイル追加操作
- **プレビュー機能**: 壁紙を設定前にプレビュー表示
- **複数ディスプレイ対応**: 各ディスプレイごとに異なる壁紙を設定可能
- **検索機能**: 壁紙名での検索に対応
- **詳細情報表示**: 解像度、ファイルサイズなどの情報を表示

## サポートしているフォーマット

### 画像
- PNG
- JPG/JPEG
- GIF
- HEIC
- WebP

### 動画
- MP4
- MOV
- AVI
- MKV
- M4V

## システム要件

- macOS 13.0 以上
- Xcode 15.0 以上（ビルド用）

## インストール方法

### 方法1: Xcodeでビルド

1. リポジトリをクローン
   ```bash
   git clone https://github.com/yourusername/wallpaper-hub.git
   cd wallpaper-hub
   ```

2. Xcodeでプロジェクトを開く
   ```bash
   open "Wallpaper Hub/WallpaperHub.xcodeproj"
   ```

3. Xcodeで実行またはビルド
   - Product > Run (⌘R) で実行
   - Product > Archive でリリースビルド作成

### 方法2: ターミナルでビルド

```bash
cd "Wallpaper Hub"
xcodebuild -project WallpaperHub.xcodeproj -scheme WallpaperHub -configuration Release build
```

## 使い方

### 壁紙の追加

1. **ドラッグ&ドロップ**: 画像や動画ファイルをアプリウィンドウにドラッグ
2. **ファイル選択**: 左下の「+」ボタンをクリックしてファイルを選択

### 壁紙の設定

1. サイドバーから設定したい壁紙を選択
2. 詳細ビューで以下のいずれかを選択
   - **Set for All Displays**: すべてのディスプレイに設定
   - **Set for Specific Display**: 特定のディスプレイに設定

### 壁紙の削除

1. 削除したい壁紙を選択
2. 詳細ビューの「Delete Wallpaper」ボタンをクリック

## プロジェクト構成

```
Wallpaper Hub/
├── WallpaperHub.xcodeproj/    # Xcodeプロジェクトファイル
└── WallpaperHub/
    ├── WallpaperHubApp.swift   # アプリエントリーポイント
    ├── ContentView.swift        # メインビュー
    ├── Models/
    │   ├── WallpaperItem.swift      # 壁紙データモデル
    │   └── WallpaperManager.swift   # 壁紙管理ロジック
    ├── Views/
    │   ├── WallpaperDetailView.swift # 詳細表示ビュー
    │   └── DropZoneView.swift        # ドロップゾーンビュー
    ├── Assets.xcassets/         # アセット
    ├── Info.plist               # アプリ設定
    └── WallpaperHub.entitlements # サンドボックス設定
```

## 技術スタック

- **言語**: Swift 5.0
- **フレームワーク**: SwiftUI
- **アーキテクチャ**: MVVM
- **最小対応OS**: macOS 13.0
- **ビルドツール**: Xcode

## 開発ロードマップ

### 実装済み機能
- ✅ 壁紙の追加・削除
- ✅ ドラッグ&ドロップ対応
- ✅ 複数ディスプレイ対応
- ✅ 壁紙プレビュー
- ✅ 検索機能

### 今後の実装予定
- ⬜ 壁紙のオンラインアップロード/ダウンロード
- ⬜ 壁紙のカテゴリ分類
- ⬜ 自動壁紙変更（スケジュール機能）
- ⬜ 動的壁紙のカスタマイズ
- ⬜ iCloudとの同期

## ライセンス

このプロジェクトはオープンソースです。

## 貢献

プルリクエストやイシューの報告を歓迎します。

## サポート

問題が発生した場合は、GitHubのIssuesセクションで報告してください。

---

Copyright © 2026. All rights reserved.
