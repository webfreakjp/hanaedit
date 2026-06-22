# HanaEdit 移植メモ

## 上流 Sakura Editor の構造

上流の Sakura Editor は Windows デスクトップアプリとして作られています。

- `README.md` では Windows 向けテキストエディタとして説明されている。
- メイン実行ファイルは `add_executable(... WIN32 ...)` で定義されている。
- 入口は `sakura_core/_main/WinMain.cpp`。
- Visual Studio プロジェクトは `comctl32`、`Imm32`、`mpr`、`Shlwapi`、
  `Dwmapi` などの Windows ライブラリをリンクしている。
- ソース全体には `HWND`、`HDC`、`HINSTANCE`、`SendMessage`、
  `CreateWindow`、レジストリ、OLE、GDI、Windows resource などの参照が多い。

つまり、これは単純なクロスコンパイルではなく、OS 依存層の置き換えを伴う移植です。
移植可能なエディタ機能は活かしつつ、シェル、ビュー、描画、入力、メニュー、
ダイアログ、OS 連携は macOS ネイティブで再実装するのが現実的です。

## 移植方針

1. macOS ネイティブのエディタシェルを作る。
   - アプリ lifecycle: `NSApplication`
   - ウィンドウ: `NSWindowController`
   - テキスト編集: `NSTextView`
   - メニューとファイルダイアログ: AppKit
   - クリップボード、drag and drop、services、IME: AppKit/TextKit

2. 上流エディタの移植可能な機能を platform-neutral な interface の後ろに移す。
   - 文字コード検出と変換
   - 検索と置換
   - grep のファイル列挙
   - タイプ別設定
   - 最近使ったファイルと設定モデル
   - マクロコマンドモデル

3. Windows 依存が強い層は macOS 向けに再実装する。
   - `sakura_core/window/*`
   - `sakura_core/view/*` の描画と caret 処理
   - `sakura_core/dlg/*`
   - `sakura_core/_os/*`
   - Windows resource と `.rc` メニュー
   - Registry/profile storage
   - IME、印刷、tray、plugin、外部プロセス連携

4. 機能移植ごとに互換性テストを追加する。
   - 文字コード round trip
   - 改行コード維持
   - 検索/置換の edge case
   - grep filter
   - タイプ別 syntax/highlight fixture

## 初期ターゲット

HanaEdit の初期版では、小さくても実際に使えるエディタを先に作っています。

- テキストファイルを開く/保存する
- 可能な範囲で検出した文字コードを維持する
- LF/CRLF/CR の改行コードを維持する
- 行番号を表示する
- macOS ネイティブの検索と編集コマンドを使う

上流エディタの Win32 view stack を最初から丸ごと書き換えるのではなく、起動できる
macOS アプリ面を作ってから、移植可能な機能を段階的に移します。

## 次に移す候補

優先度が高い候補:

- 上流互換の文字コード判定ポリシーと UI
- grep dialog と file filter
- タイプ別カラー設定
- keyword/outline parser
- macro command dispatch model

後回しにした方がよい候補:

- 上流と pixel-compatible な描画
- plugin ABI 互換
- Windows macro host 互換
- 印刷挙動
- tray と multi-process control
