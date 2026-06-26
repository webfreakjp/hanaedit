# Homebrew 配布

HanaEdit の Homebrew Cask は、本体リポジトリではなく tap リポジトリで管理します。

```text
https://github.com/webfreakjp/homebrew-hanaedit
```

## インストール

Launchpad や Finder から起動したい場合:

```sh
brew tap webfreakjp/hanaedit
brew trust webfreakjp/hanaedit
brew install --cask hanaedit
```

未 notarize の配布物では、初回起動時に macOS が「壊れているため開けません」と
表示することがあります。その場合は次を実行します。

```sh
xattr -dr com.apple.quarantine /Applications/HanaEdit.app
```

## 手順書

インストール手順、リリース手順、zip のアップロード方法、sha256 の計算方法、
Cask の検証方法は tap リポジトリの手順書を参照してください。

```text
../homebrew-hanaedit/docs/INSTALL.md
../homebrew-hanaedit/docs/RELEASE.md
```

Cask は tap リポジトリの `Casks/hanaedit.rb` にあります。
