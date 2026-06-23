# Homebrew Release

HanaEdit is distributed through a personal Homebrew tap:

```text
webfreakjp/homebrew-hanaedit
```

## First-time tap setup

Create or clone the separate tap repository:

```sh
gh repo clone webfreakjp/homebrew-hanaedit ../homebrew-hanaedit
```

The tap repository should contain this file:

```text
Formula/hanaedit.rb
```

The formula lives in the tap repository, not in this source repository.
It contains `REPLACE_WITH_SHA256`. Replace it after publishing the matching
GitHub tag.

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

5. Replace `REPLACE_WITH_SHA256` in `../homebrew-hanaedit/Formula/hanaedit.rb`.
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
