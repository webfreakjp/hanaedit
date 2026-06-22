# Sakura Editor macOS Port

このリポジトリは [sakura-editor/sakura](https://github.com/sakura-editor/sakura)
を macOS で動かすための移植トラックです。

上流の Sakura Editor は Win32 C++ アプリです。ウィンドウ、描画、IME、
クリップボード、レジストリ、リソース、メニュー、プロセス制御が Windows API
に強く依存しているため、単純に CMake やコンパイラ設定を変えて macOS 向けに
再ビルドすることはできません。

そのため、このリポジトリではまず macOS ネイティブの AppKit エディタを作り、
Sakura の移植可能な機能を段階的に移していく形にしています。

## 現在の状態

- `macos/SakuraMac` に macOS AppKit 版のエディタ土台を追加
- 新規作成、ファイルを開く、保存、名前を付けて保存、ウィンドウを閉じる
- UTF-8、UTF-8 BOM、UTF-16 LE/BE、Shift_JIS、EUC-JP、ISO-2022-JP の読み込み
- 検出した文字コードと改行コードを保存時に維持
- ネイティブの undo、cut/copy/paste、select all、検索パネル
- 行番号ルーラーと簡易ステータスバー

まだ Sakura Editor の完全互換版ではありません。今後の移植を進めるための、
最初に起動できる macOS ターゲットです。

## macOS でのビルド

Xcode または Command Line Tools を入れた macOS で実行します。

```sh
cd macos/SakuraMac
swift build
swift run SakuraMac
```

コマンドラインからファイルを開く場合:

```sh
swift run SakuraMac /path/to/file.txt
```

## 移植メモ

[docs/PORTING_SAKURA_TO_MAC.md](docs/PORTING_SAKURA_TO_MAC.md) を参照してください。
