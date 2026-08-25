# md-preview-kit デモ

このリポジトリが提供する3種類のフェンスの描画例。
対応したプレビューで開くと、以下のコードブロックがすべて図になる。

---

## 1. タイミング図（`wavedrom`）

```wavedrom
{ signal: [
  { name: "clk",  wave: "p......." },
  { name: "req",  wave: "0.1..0.." },
  { name: "ack",  wave: "0..1..0." },
  { name: "data", wave: "x.=.=.x.", data: ["D0", "D1"] }
],
  head: { text: "handshake" }
}
```

バス・グループの例:

```wavedrom
{ signal: [
  { name: "clk", wave: "P........" },
  {},
  { name: "bus", wave: "x.==.=x..", data: ["addr", "data", "data"] },
  { name: "we",  wave: "0.1...0.." }
]}
```

---

## 2. グラフ（`chart`）

```chart
{ type: "bar",
  data: {
    labels: ["Mon","Tue","Wed","Thu","Fri"],
    datasets: [{ label: "処理数", data: [12, 19, 7, 15, 9] }]
  },
  options: { plugins: { title: { display: true, text: "週次処理数" } } }
}
```

折れ線（複数系列）:

```chart
{ type: "line",
  data: {
    labels: ["0","1","2","3","4","5"],
    datasets: [
      { label: "A", data: [1,3,2,5,4,6], tension: 0.3 },
      { label: "B", data: [2,2,3,3,4,4], tension: 0.3 }
    ]
  }
}
```

---

## 3. ラダー図（`kvlist`）

KV ニーモニックをラダー図として描画する。
同じデバイスにホバーすると、図中の全出現箇所が相互にハイライトされる。

```kvlist
DEVICE:53
;MODULE:bbbb
;MODULE_TYPE:0
;SCRIPT_TYPE:
LD MR3013
OUT MR2013
;MR3012 = 1
;MR3012 = 1
LD MR3013
AND MR3014
SET MR1000
NCJ #1000
;MR3012 = 1
LD CR2002
OUT MR3012
LABEL #1000
;
;MR3012 = 0
;MR3012 = 0
LD MR3013
ANB MR3014
SET MR1000
NCJ #1001
;MR3012 = 0
LD CR2003
OUT MR3012
LABEL #1001
;
LD MR3014
@SMOV "H:1" DM8000
END
ENDH
```

---

## 4. エラー表示の確認（わざと壊した `wavedrom`）

構文エラーは、その場に赤いエラーメッセージとして表示される
（ページ全体は壊れない）。

```wavedrom
{ signal: [ { name: "broken", wave: }
```

---

## 補足

ホスト側のプレビューが標準で対応していれば、mermaid / graphviz / KaTeX なども
そのまま使える（それらはこのリポジトリの守備範囲ではない）。
