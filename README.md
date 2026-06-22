# HanaEdit

HanaEdit は macOS ネイティブの AppKit テキストエディタです。
[sakura-editor/sakura](https://github.com/sakura-editor/sakura) の考え方を参考にしつつ、
macOS 向けに軽く動く別アプリとして育てています。

上流の Sakura Editor は Win32 C++ アプリです。ウィンドウ、描画、IME、
クリップボード、レジストリ、リソース、メニュー、プロセス制御が Windows API
に強く依存しているため、単純に CMake やコンパイラ設定を変えて macOS 向けに
再ビルドすることはできません。

そのため、このリポジトリでは macOS ネイティブの AppKit エディタを作り、
移植しやすい機能を段階的に取り込む形にしています。

## 現在の状態

- ルート直下に macOS AppKit 版のエディタを Swift Package として配置
- 新規作成、ファイルを開く、保存、名前を付けて保存、ウィンドウを閉じる
- UTF-8、UTF-8 BOM、UTF-16 LE/BE、Shift_JIS、EUC-JP、ISO-2022-JP の読み込み
- 検出した文字コードと改行コードを保存時に維持
- ネイティブの undo、cut/copy/paste、select all、検索パネル
- 行番号ルーラーと簡易ステータスバー

まだ上流エディタの完全互換版ではありません。macOS で自然に使えるエディタとして、
必要な機能を順に足しています。

## macOS でのビルドと実行

フル版の Xcode は必須ではありません。軽量に試す場合は Apple の Command Line Tools
だけでビルドできます。

### 1. ローカル環境の準備

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

### 2. Debug ビルド

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

### 3. Release ビルド

軽量な配布物や普段使いに近い速度で試す場合は、Release ビルドを使います。

```sh
swift build -c release
.build/release/HanaEdit
```

ファイルを指定して起動する場合:

```sh
.build/release/HanaEdit /path/to/file.txt
```

### 4. クリーンビルド

```sh
swift package clean
swift build
```

`xcrun` や SDK のエラーで止まる場合は、Command Line Tools の選択先を確認します。

```sh
xcode-select -p
sudo xcode-select -s /Library/Developer/CommandLineTools
```

## 主な操作

- 検索: `Command-F`
- 置換: `Shift-Command-F`
- ディレクトリ grep: `Command-G`
- 矩形選択: `Option` を押しながらドラッグ
- 矩形範囲選択モード開始: `Option-↑/↓/←/→`
- 矩形範囲選択モード解除: `Esc`
- 行番号の表示切り替え: `Command-L`
- 空白・タブなどの不可視文字表示: `Option-Command-I`

検索、置換、grep では `Regular expression` をオンにすると正規表現検索になります。
正規表現の置換では `$1`、`$2` のようなキャプチャ参照を使えます。
ディレクトリ grep の `Exclude` には、`.build, node_modules, *.log` のような
カンマ区切りの glob パターンを指定できます。
矩形選択中に文字入力やペーストを行うと、矩形範囲の左端にある各行へ同じ文字列を
一括挿入します。

## 移植メモ

[docs/PORTING_NOTES.md](docs/PORTING_NOTES.md) を参照してください。
