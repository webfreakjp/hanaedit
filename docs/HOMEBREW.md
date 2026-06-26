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

## リリース手順

リリース手順、zip のアップロード方法、sha256 の計算方法、Cask の検証方法は
tap リポジトリの README を参照してください。

```text
../homebrew-hanaedit/README.md
```

Cask は tap リポジトリの `Casks/hanaedit.rb` にあります。
