# 配布物の作り方（メンテナ向け）

相手（Windows ユーザー）に渡す zip を作る手順。**このページの内容は配布物に含めない**
（相手が読むのは [`vscode-setup.md`](vscode-setup.md) だけ。あちらには WSL / `sh` /
Node.js の話を一切書かない方針）。

## 必要なもの

- WSL か Linux（`sh` が動く環境）
- **Node.js**（`npx` が使えること。`vsce` は都度取得するので事前インストール不要）
- `iconv` と `python3`（WSL の標準構成にある。用途は後述）

## 1コマンド

```sh
sh adapters/vscode/build.sh
```

| 出力 | 用途 |
|---|---|
| `dist/md-preview-kit-<ver>.zip` | **相手に渡すのはこれ** |
| `adapters/vscode/md-preview-kit-<ver>.vsix` | 拡張だけ渡したいとき |

## 配布 zip の中身と、この形にしている理由

```
md-preview-kit-<ver>/
  install.bat                    ダブルクリックで導入完了（相手の作業はこれだけ）
  はじめに読む.txt                メモ帳で読める3行の案内
  INSTALL.md                     詳しい手順（= docs/vscode-setup.md）
  md-preview-kit-<ver>.vsix       拡張本体
  sample.md                      見本＋仕様書＋動作確認
  sample.drawio.svg / sample.fig.svg   sample.md が参照する図
```

- **相手側に WSL・`sh`・Node.js・Python は一切要らない。** ビルドするのは配る側だけ
- `install.bat` は `code --install-extension` を呼ぶだけ。`code` が PATH に無い場合は
  既定のインストール先（`%LOCALAPPDATA%` / `%ProgramFiles%`）も探し、見つからなければ
  日本語で手作業手順を案内して終わる
- 関連拡張（mermaid / draw.io）は `y/N` で任意インストール

## build.sh が内部でやっていること

1. **`sync.sh`** — レンダラの正本 `scripts/` を `adapters/vscode/media/` にコピー
   （`previewScripts` のパスは拡張ルート相対なので、物理的に配下へ置く必要がある）。
   併せて `sourceMappingURL` を剥がす（webview の CSP が `.map` の取得を止めるため、
   残すと Console に無関係な警告が出続ける）
2. **`LICENSE` を拡張配下にコピー** — vsix に同梱するため（正本はリポジトリルート）
3. **`npx @vscode/vsce package`** — `.vsix` を作る
4. **`install.bat` を CP932 + CRLF に変換** — 日本語 Windows の `cmd` は既定が CP932。
   UTF-8 のままだとメッセージが文字化けする。ソースは `adapters/vscode/dist-files/` に
   UTF-8 で置いてあり、変換は build 時に行う
5. **zip は `python3` の `zipfile` で作る** — `zip(1)` は日本語ファイル名に UTF-8 フラグ
   （EFS, `0x800`）を立てないため、Windows のエクスプローラで解凍すると
   `はじめに読む.txt` が文字化けする。`zipfile` は立てるので、作成後に読み直して
   フラグを検証している（立っていなければ build を失敗させる）

## 気をつける点

- **バージョンを上げる**: `adapters/vscode/package.json` の `version`。
  相手が上書きインストールしたときに新しいと分かるよう、変更したら必ず上げる
- **ラダー（`kvlist`）は別リポジトリの生成物**: `scripts/ladder.glue.js` は
  [ladder_viewer](https://github.com/totochi-2022/ladder_viewer) の `vivify-glue.sh` が
  生成する。無い状態で build すると `sync.sh` が no-op スタブを置き、**ラダーだけ無効な**
  vsix ができる（警告が出る）。ラダーを含めるなら先に
  `sh ~/work/ladder_viewer/vivify-glue.sh` を実行
- **相手向けの文言を直したいとき**は `docs/vscode-setup.md`（→ `INSTALL.md`）と
  `adapters/vscode/dist-files/` を編集する。ここ（`build-and-release.md`）は配布物に入らない
- **`sample.md` の図が切れないように**: `sample.drawio.svg` と `sample.fig.svg` は
  必ず同梱（build.sh が入れている）
- **Marketplace には出していない**。出すには publisher アカウントとトークンが必要で、
  更新も publish 作業になる。少人数に配る間は vsix 手渡しのほうが速い。
  公開したくなったら `npx @vscode/vsce publish`（`publisher` を実在のものにする）

## nvim / Vivify 側

Vivify（nvim の右プレビューペイン・ブラウザ表示）の設定は
[README の「Vivify」節](../README.md#vivify) にある。VS Code とレンダラの正本
（`scripts/`）を共有しているので、レンダラを直せば両方に効く。
