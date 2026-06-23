# Homebrew Release

HanaEdit is distributed through a personal Homebrew tap.

## First-time tap setup

Create a separate GitHub repository:

```sh
gh repo create webfreakjp/homebrew-hanaedit --public --clone
```

The tap repository should contain this file:

```text
Formula/hanaedit.rb
```

Copy the formula template from this repository:

```sh
mkdir -p ../homebrew-hanaedit/Formula
cp packaging/homebrew/hanaedit.rb ../homebrew-hanaedit/Formula/hanaedit.rb
```

The template contains `REPLACE_WITH_SHA256`. Replace it after publishing the
matching GitHub tag.

## Release a new version

1. Update `AppInfo.version`.
2. Commit the release changes.
3. Create and push a tag.

```sh
git tag v0.1.0
git push origin main --tags
```

4. Download the GitHub archive and calculate the sha256.

```sh
curl -L -o /tmp/hanaedit-v0.1.0.tar.gz \
  https://github.com/webfreakjp/hanaedit/archive/refs/tags/v0.1.0.tar.gz

shasum -a 256 /tmp/hanaedit-v0.1.0.tar.gz
```

5. Replace `REPLACE_WITH_SHA256` in the tap formula.
6. Test the formula locally.

```sh
brew install --build-from-source ../homebrew-hanaedit/Formula/hanaedit.rb
hanaedit --version
brew test ../homebrew-hanaedit/Formula/hanaedit.rb
```

7. Commit and push the tap.

```sh
cd ../homebrew-hanaedit
git add Formula/hanaedit.rb
git commit -m "Add hanaedit 0.1.0"
git push origin main
```

## Install from another Mac

```sh
brew tap webfreakjp/hanaedit
brew install hanaedit
```

Or install directly:

```sh
brew install webfreakjp/hanaedit/hanaedit
```
