# morph のロゴ

| ファイル | 用途 |
| --- | --- |
| [morph-logo.png](morph-logo.png) | 緑一色の横組み。READMEの標準ロゴ |
| [morph-mark.png](morph-mark.png) | アイコン・アバター向けのマーク単体 |
| [morph-logo-light.png](morph-logo-light.png) | 明るい背景用。緑のマークと濃色の文字 |

すべて透過PNG。マークは、二つの分岐をつないだ小文字のmとして、ADTの構成と再帰を表す。
画像生成によるラスター素材で、SVG原稿は含まない。縦横比を保って表示する。
READMEでは横組みを幅280pxで中央に配置する。マーク単体は小さなアイコンにも利用できる。

## 生成記録

組み込みの `image_gen` を使用。プロンプトを以下に保存する。
マークを生成し、それを参照して横組みを作り、文字色を変更して標準版を作成した。
白文字版は透過の縁にノイズが生じたため採用していない。

### マーク

```text
Use case: logo-brand.
Asset type: primary square icon for the open-source MoonBit project "morph".
Primary request: Create one distinctive, very simple OSS project logo. The project builds algorithms from algebraic data types, pattern matching and recursion. Communicate composition and branching with an abstract lowercase m monogram.
Design: a compact angular m made from two connected forked paths, three strong upright stems and two diagonal shoulders, with clear open negative spaces. Precisely balanced geometry, consistent bold stroke thickness, subtly softened corners. It should feel like a small functional-programming language or Unix developer tool emblem, calm, durable and recognizable at 24 pixels. Use a single solid deep jade/teal-green ink around #20856B; no second color.
Composition: one isolated centered mark, approximately 72% of a square canvas, ample transparent padding, straight-on view.
Background: genuinely transparent alpha.
Style: flat vector-like geometric symbol, sharp edges and professional optical balance.
Text: no text, no letters outside the monogram.
Avoid: gradients, shadows, glow, 3D, textures, mockups, badges, enclosing hexagons, generic AI brains, circuit boards, decorative nodes, animals, slogans, watermarks, or multiple alternatives. Do not imitate an existing logo. Produce a single finished icon.
```

### 明るい背景用の横組み

参照画像: `morph-mark.png`

```text
Use case: logo-brand.
Asset type: horizontal primary logo for an open-source developer library README.
Input image 1 is the approved morph monogram; use it as the identity reference and preserve its exact recognizable shape, proportions, three upright stems, two angular shoulders and jade-green color.
Create a clean horizontal lockup with this mark on the left and the exact lowercase word "morph" on the right. Spell m-o-r-p-h exactly. The wordmark should be an understated, precise, medium-bold geometric sans with open counters, slightly technical but friendly, and optically spaced. Render the wordmark in solid charcoal #20282D. Balance the icon height and wordmark height, with a comfortable gap of roughly half an icon width.
Composition: a wide canvas approximately 3:1; the full lockup centered and occupying about 82% of its width, modest transparent margins. One icon, one wordmark.
Style: crisp flat OSS identity, vector-like, no gradients, no shading or texture.
Background: truly transparent alpha; this is the light-background variant.
Only visible text: "morph". No tagline, border, shadow, mockup, watermark, decorative graphics, or extra alternatives.
```

### 緑一色の標準ロゴ

参照画像: `morph-logo-light.png`

```text
Use case: precise-object-edit.
Edit target: input image 1, the morph horizontal logo.
Make a monochrome jade-green version: change only the charcoal wordmark to exactly the same solid jade-green ink as the icon, approximately #20856B. The complete mark and all five letters are now one matching green color.
Preserve the exact lowercase word "morph", original typography, smooth edges, spacing, proportions, icon shape, horizontal composition, transparent margins and canvas size. Keep the background and letter counters truly transparent.
A crisp simple open-source developer-tool logo, flat solid green ink, no other elements, no gradients, no shadows, no texture, no white ink, no outlines and no backdrop.
```
