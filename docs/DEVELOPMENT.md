# 開発者向けビルド手順

HanaEdit は Swift Package として構成されています。フル版の Xcode は必須ではなく、
Apple の Command Line Tools だけでビルドできます。

## ローカル環境の準備

Command Line Tools が未インストールなら、次を実行します。

```sh
xcode-select --install
```

インストール後、Swift が使えることを確認します。

```sh
swift --version
xcrun --sdk macosx --show-sdk-path
```

このパッケージは現時点では外部 SwiftPM 依存を持っていないため、Homebrew や
CocoaPods などの追加パッケージは不要です。依存を明示的に解決したい場合は、
次のコマンドを実行します。

```sh
swift package resolve
```

## Debug ビルド

```sh
swift build
```

ビルド済みバイナリを直接起動する場合:

```sh
.build/debug/HanaEdit
```

SwiftPM 経由でビルドと起動をまとめて行う場合:

```sh
swift run HanaEdit
```

コマンドラインからファイルを開く場合:

```sh
swift run HanaEdit /path/to/file.txt
```

## Release ビルド

```sh
swift build -c release
.build/release/HanaEdit
```

ファイルを指定して起動する場合:

```sh
.build/release/HanaEdit /path/to/file.txt
```

## `.app` bundle の作成

```sh
./scripts/build-app.sh
open dist/HanaEdit.app
```

リリース用 zip を作る場合:

```sh
./scripts/package-app.sh 0.1.2
```

## クリーンビルド

```sh
swift package clean
swift build
```

`xcrun` や SDK のエラーで止まる場合は、Command Line Tools の選択先を確認します。

```sh
xcode-select -p
sudo xcode-select -s /Library/Developer/CommandLineTools
```
