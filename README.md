# HanaEdit

HanaEdit は macOS ネイティブの AppKit テキストエディタです。macOS で サクラエディタ風の矩形編集や grep を使いたい人に向けて、軽く起動できるテキストエディタとして育てています。

[sakura-editor/sakura](https://github.com/sakura-editor/sakura) の実装を参考にしつつ、macOS 向けの独立したエディタとして実装しています。

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
- ネイティブの undo、cut/copy/paste、select all
- 検索、置換、正規表現検索
- ディレクトリ配下 grep
- 矩形選択、矩形編集
- 行番号ルーラー、不可視文字表示、簡易ステータスバー

まだ上流エディタの完全互換版ではありません。macOS で自然に使えるエディタとして、
必要な機能を順に足しています。

## インストール

Homebrew でインストールできます。

Launchpad や Finder の「このアプリケーションで開く」から使いたい場合は、Cask 版を
インストールします。

```sh
brew tap webfreakjp/hanaedit
brew trust webfreakjp/hanaedit
brew install --cask hanaedit
```

直接インストールする場合:

```sh
brew trust webfreakjp/hanaedit
brew install --cask webfreakjp/hanaedit/hanaedit
```

`Refusing to load cask ... from untrusted tap` と表示された場合は、上の
`brew trust` を実行してから再度 `brew install` してください。

インストール後の確認:

```sh
hanaedit --version
```

現在の配布物は Apple Developer ID 署名と notarize が未対応です。Launchpad や Finder から
起動したときに「壊れているため開けません」と表示される場合は、quarantine 属性を外して
ください。

```sh
xattr -dr com.apple.quarantine /Applications/HanaEdit.app
```

今後、Developer ID 署名と notarize に対応してこの手順を不要にする予定です。

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

- 開発者向けビルド手順: [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md)
- 残タスク: [docs/TODO.md](docs/TODO.md)
- 移植メモ: [docs/PORTING_NOTES.md](docs/PORTING_NOTES.md)
- Homebrew 配布メモ: [docs/HOMEBREW.md](docs/HOMEBREW.md)
