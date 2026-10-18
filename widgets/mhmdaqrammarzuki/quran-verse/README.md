# quran-verse

A verse of the day from the Qur'an, in Arabic and in your language.

A home-screen widget for [Omalauncher](https://github.com/SimonSchubert/omalauncher),
written in OWL. Tap the tile for the full verse with copy and share; tap the
language name to switch language, which switches the interface too.

## Languages

23 languages, each with its interface and its translation:

| | | | |
|---|---|---|---|
| Bahasa Indonesia | English | Melayu | Español |
| 日本語 | 中文 | 한국어 | Türkçe |
| Français | Deutsch | Русский | Italiano |
| Nederlands | Polski | हिन्दी | বাংলা |
| اردو | தமிழ் | ไทย | Kiswahili |
| Svenska | Norsk | Kurdî | |

The translation text comes from [api.alquran.cloud](https://alquran.cloud).
Every edition was checked against the API surah by surah: each one returns every
ayah it should, and none of them empty. Three of the API's editions were dropped
for failing that check — `es.cortes` truncates 36:1, `zh.majian` and `zh.jian` do
the same, and `pt.elhayek` answers 18:39 with a single dot — so Spanish uses
`es.garcia` and Chinese uses `zh.mazhonggang`.

### A note on the translations

The **translations of the Qur'an** belong to the translators and publishers named
by the API, not to the author of this widget.

The **interface wording** in each language was written for this widget, and it is
not always idiomatic. A phrase may sound stilted, or a native speaker may simply
prefer a different word. Please treat it as a first attempt and send a correction
if you can — the Tamil, Kurdish, Swahili and Urdu wording in particular.

## Requirements

`noto-fonts`, which the widget declares in `requires`. The language chips draw
Arabic, Latin, Cyrillic, Devanagari, Bengali, Tamil, Thai, Urdu, CJK and Hangul,
and all of those come from that package. No other package is needed, and the
widget runs no shell commands.

## Editing it

You are welcome to edit this however you like — fixing the translations, adding
languages, changing the layout — as long as you keep it under the MIT License and
keep the credit to the original author.

Three things in the file are worth knowing before you change it:

- **`langs`** is the whole language list. Each entry carries `code`, `label`,
  `native`, `nw`, `edition` and `t` (the interface strings). The field meanings
  are documented in a comment above the list.
- **`nw`** is the em width of one native character, and it is what lets the chips
  be measured instead of guessed. CJK and Hangul fill the em square (1.0),
  Cyrillic and Arabic are a little over half, and Devanagari and Bengali are much
  narrower than `len()` counts, because the vowel signs are counted but not
  drawn. It also decides when a verse counts as long: Kurdish spells its words
  out and runs about 2.3x the length of the Arabic it translates, more than any
  other language here, so it needs a smaller type size than its character count
  suggests. If you add a language in a new script, give it a sensible `nw` or
  its chip will clip and its verse may overflow the tile.
- **`t`** holds the interface in each language, including the headings of the two
  foldable sections at the bottom of the screen (`about`, `notes`) and the row
  titles in the list above them (`kLevel` to `kPkg`). Only those *titles* are
  translated; the values beside them name nodes, functions and files, so they
  stay English, and so does the body of the notes.

Both sections start folded and share one bordered plate, so they read as parts of
the same panel rather than two separate blocks. Each has its own open/close button.

Check a change before you publish it:

```
owl-check widget.owl
```

It prints any errors and writes a PNG of the tile and of the full screen. Note
that it renders the widget as it is currently running, so the language and which
folds are open in the preview are the ones on your phone, not the defaults
written in the file.

## Licence

MIT — Copyright (c) 2026 mhmdaqrammarzuki

This is a derivative of **"bible-verse" by Dustin Montgomery (en3r0)** from
[SimonSchubert/omarchy-widgets](https://github.com/SimonSchubert/omarchy-widgets),
which is MIT licensed, Copyright (c) 2026 Simon Schubert and contributors. The
original fetched an NIV verse a day from ourmanna.com; this rewrite fetches from
api.alquran.cloud and adds the language picker.

```
MIT License

Copyright (c) 2026 mhmdaqrammarzuki

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```