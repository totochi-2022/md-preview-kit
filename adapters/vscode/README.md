# md-preview-kit (VS Code)

Markdown のコードフェンスを図として描画します。**プレビューだけの拡張**で、
コードの実行や外部通信は一切しません。

| フェンス | 描かれるもの |
|---|---|
| ` ```wavedrom ` | タイミング図（WaveDrom） |
| ` ```chart ` | グラフ（Chart.js） |
| ` ```kvlist ` | ラダー図（KV ニーモニック） |

md を開いて `Ctrl+Shift+V`（または `Ctrl+K` → `V` で横に並べて表示）。

書き方の全体像は、配布物に同梱されている **`sample.md`** をこの拡張のプレビューで
開くのが早いです（基本の Markdown 記法から各図の書式まで、1ファイルにまとまっています）。

## 一緒に入れると便利な拡張（任意）

| 拡張 | 何ができるか |
|---|---|
| Markdown Preview Mermaid Support | ` ```mermaid ` のフローチャート等を描画 |
| Draw.io Integration (hediet) | `.drawio.svg` を VS Code 内で作図・編集 |

## 制約

- フェンスの設定に**関数は書けません**（プレビューの CSP がコード評価を禁じているため）。
- WSL 上のファイルを `\\wsl.localhost\...` で開くと、保存してもプレビューが自動更新
  されません（VS Code のファイル監視の制約）。Windows ローカルに置いてください。

## 変更履歴

| 版 | 変更 |
|---|---|
| 0.0.2 | 同梱の `install.bat` が VS Code を呼び出せずに失敗する不具合を修正。失敗時に手作業の手順を案内するようにした |
| 0.0.1 | 初版（wavedrom / chart / kvlist） |

MIT License / https://github.com/totochi-2022/md-preview-kit
