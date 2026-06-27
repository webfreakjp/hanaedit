# リリース手順

HanaEdit のリリースは、本体リポジトリ `webfreakjp/hanaedit` と共通 tap リポジトリ
`webfreakjp/homebrew-tap` の両方を更新します。

この手順では例として `0.1.0` を使います。実際のリリースでは対象バージョンに
読み替えてください。

## バージョンアップ時に変更する箇所

本体リポジトリ `webfreakjp/hanaedit`:

- `Sources/HanaEdit/AppInfo.swift`
  - `AppInfo.version`
- `packaging/macos/Info.plist`
  - `CFBundleShortVersionString`
  - `CFBundleVersion`
- `scripts/package-app.sh`
  - `VERSION=${1:-...}` のデフォルト値
- `README.md`
  - リリース zip 作成例のバージョン

tap リポジトリ `webfreakjp/homebrew-tap`:

- `Casks/hanaedit.rb`
  - `version`
  - `sha256`

## 1. 本体リポジトリでバージョンを更新する

```sh
cd ../hanaedit
```

`Sources/HanaEdit/AppInfo.swift`:

```swift
static let version = "0.1.0"
```

`packaging/macos/Info.plist`:

```xml
<key>CFBundleShortVersionString</key>
<string>0.1.0</string>
<key>CFBundleVersion</key>
<string>0.1.0</string>
```

`scripts/package-app.sh`:

```sh
VERSION=${1:-0.1.0}
```

必要に応じて `README.md` のリリース zip 作成例も更新します。

## 2. 本体をビルドして確認する

```sh
swift build -c release
.build/release/HanaEdit --version
```

`.app` を作成して確認します。

```sh
./scripts/build-app.sh
dist/HanaEdit.app/Contents/MacOS/HanaEdit --version
codesign --verify --deep --strict --verbose=2 dist/HanaEdit.app
```

zip を作成します。

```sh
./scripts/package-app.sh 0.1.0
shasum -a 256 dist/HanaEdit-0.1.0.zip
```

ここで出力された SHA-256 を控えます。Cask の `sha256` にはこの値を入れます。

## 3. 本体リポジトリを commit / tag / push する

```sh
git add README.md Sources/HanaEdit/AppInfo.swift packaging/macos/Info.plist scripts/package-app.sh
git commit -m "Release 0.1.0"
git push origin main

git tag v0.1.0
git push origin v0.1.0
```

## 4. GitHub Release に zip をアップロードする

`gh` コマンドは不要です。GitHub の Web UI で操作します。

1. `https://github.com/webfreakjp/hanaedit/releases` を開く。
2. `Draft a new release` または既存の `v0.1.0` release の編集画面を開く。
3. tag に `v0.1.0` を指定する。
4. `dist/HanaEdit-0.1.0.zip` を添付する。
5. release を公開する。

zip を再生成した場合は SHA-256 が変わる可能性があります。アップロードした zip と
`Casks/hanaedit.rb` の `sha256` は必ず一致させてください。

## 5. tap の Cask を更新する

```sh
cd ../homebrew-tap
```

`Casks/hanaedit.rb`:

```ruby
version "0.1.0"
sha256 "..."
```

## 6. Cask をローカルで検証する

Homebrew は Cask を tap 配下から読み込むため、ローカル clone で編集した Cask を
インストール済み tap に一時反映して確認します。

```sh
mkdir -p /opt/homebrew/Library/Taps/webfreakjp/homebrew-tap/Casks
cp Casks/hanaedit.rb /opt/homebrew/Library/Taps/webfreakjp/homebrew-tap/Casks/hanaedit.rb

brew info --cask webfreakjp/tap/hanaedit
brew uninstall --cask hanaedit 2>/dev/null || true
brew install --cask webfreakjp/tap/hanaedit
hanaedit --version
open -a HanaEdit
```

未 notarize の間は、必要に応じて quarantine 属性を外します。

```sh
xattr -dr com.apple.quarantine /Applications/HanaEdit.app
open -a HanaEdit
```

## 7. tap リポジトリを commit / push する

```sh
git add Casks/hanaedit.rb
git commit -m "Update hanaedit to 0.1.0"
git push origin main
```

## 8. 別端末で更新確認する

```sh
brew update
brew info --cask webfreakjp/tap/hanaedit
brew upgrade --cask webfreakjp/tap/hanaedit
```

更新されない場合:

```sh
brew reinstall --cask webfreakjp/tap/hanaedit
```
