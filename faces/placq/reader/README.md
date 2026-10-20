# Reader

A quiet EPUB, MOBI and TXT reader with a local library, saved reading progress,
adjustable typography, paper/sepia/night themes and public OPDS 1/2 catalogs.

Version 1.9 replaces the settings symbol with an outlined eight-tooth gear.

Tap the page's right half to advance, its left half to go back. The gear opens
Settings; the book button opens Library. The library scans files directly in
`~/Books` by default; choose a different folder in Settings. Book titles and
contents keep their original language. Internet access is only needed for OPDS
browsing, searching and downloads. Five public catalogs are included; custom
catalogs can be added. Authentication and DRM are not supported.

## Self-contained installation and review warning

`face.owl` includes the Python reader and its separate KindleUnpack process as
an **offline source bundle**: base64-encoded, XZ-compressed JSON mapping relative
filenames to complete UTF-8 source/notice text. It includes no bytecode, private
settings, books, tokens, or downloaded executable code. Encoding is packaging,
not encryption; the full source can be recovered using the instructions below.

The `python -c` startup command deliberately triggers the review warning about
running a widget value as code. Both the bootstrap and source bundle are fixed
literals in this reviewed face, not server responses or user inputs. This is
necessary because store folders cannot contain companion Python files. No
network access is used to install the helper code, and no root access is needed.

The bootstrap bounds decompression, checks the bundle's SHA-256, rejects unsafe
relative paths, installs atomically under
`~/.local/share/owl-reader-store/<source-sha256>/`, and verifies installed sources
before initialization. Reader state and caches live separately under
`~/.local/state/owl-reader-store/` and `~/.cache/owl-reader-store/`. These locations
are separate from a manually installed Reader, so installing this face does not
overwrite its helpers, settings, or reading progress. Removing the face does not
delete books; generated source/state/cache directories can be removed manually.

Every external runtime package is declared in `requires`; the compressed bundle
uses only Python's standard library. Package installation uses the launcher's
normal approval flow. Fonts come from `ttf-dejavu`.

## Reading and file/network behavior

- Reads EPUB/TXT/MOBI books from the selected folder. Defaults to `~/Books`.
- Stores settings, reading offsets, book statuses and page/text/metadata caches.
- Contacts public or user-selected OPDS servers only for catalog operations and
  book downloads. OPDS feeds may refer to additional hosts; HTTP and HTTPS are
  supported by the helper. Default catalog endpoints are visible in the sources.
- Downloaded files are books, not executable code. EPUB HTML/scripts are not run.
- **Delete file** requires an inline confirmation and permanently removes only
  the selected library entry and its progress/status; no recursive book deletion.
- MOBI extraction runs offline in a separate process with CPU, memory, file-size,
  descriptor and wall-time limits. Temporary extraction directories are cleaned.
- No DRM removal. No PDF, KFX, Topaz, book images, original CSS or image-only
  books. Text is reflowed into plain paragraphs. Input books are limited to 40 MB.
- Progress is coalesced after approximately one second; abrupt termination may
  lose the latest second of progress. Reflow preserves text position.

## Licenses and provenance

The face, bootstrap and Reader helpers are **MIT**. Their MIT notice is included
in the bundle as `LICENSE-reader.txt`.

The separately invoked **KindleUnpack** program is **GPL-3.0-only**, not MIT.
The combined distribution declares `MIT AND GPL-3.0-only`; this does not remove
or replace either component's terms. All bundled upstream sources and original
notices are included unchanged, together with `COPYING.txt` and the upstream
README. Original contributors include Charles M. Hannum, P. Durrant,
K. Hendricks, S. Siebert, fandrieu, DiapDealer, nickredding and tkeo.

- Upstream: https://github.com/kevinhendricks/KindleUnpack
- Pinned commit: `bf0ca6ece4e73494625e7950be3e259b6260774c`
- Original upstream archive SHA-256:
  `7df30c8e2096e31812fba99f3862e56c9b55008f71e422bef9f7eea51ddb0b6e`
- Included upstream files: unmodified `lib/*.py`, `README.md`, `COPYING.txt`.
- Reader backend modifications for this distribution: state/cache directory
  names are suffixed `-store` to isolate them from a manual installation.

## Inspect the embedded sources without executing them

Run this in this folder. It parses only the two JSON string literals and prints
the verified source mapping; it does **not** run the bootstrap or bundled code.

```sh
python - <<'PY'
import base64, hashlib, json, lzma, re
from pathlib import Path
face = Path('face.owl').read_text()
def literal(name):
    line = next(line for line in face.splitlines()
                if line.startswith('  let ' + name + ' = '))
    return json.loads(line.split(' = ', 1)[1])
bootstrap = literal('readerBootstrap')
payload = literal('readerBundle')
decoder = lzma.LZMADecompressor(memlimit=64*1024*1024)
raw = decoder.decompress(base64.b64decode(payload, validate=True),
                         max_length=2*1024*1024)
assert decoder.eof and not decoder.unused_data
expected = re.search(r'digest = "([0-9a-f]{64})"', bootstrap)[1]
assert hashlib.sha256(raw).hexdigest() == expected
print(json.dumps(json.loads(raw), indent=2, ensure_ascii=False))
PY
```

## Validation

The packaged sources pass the existing 31 Reader tests, including MOBI fixtures.
Fresh installation and repeat initialization were tested with an isolated HOME.
The face is checked with `owl-check` and the store's
`java -jar tools/owl.jar review . faces/placq/reader/face.owl`.

The preview uses a fresh, empty Reader state, with no personal library data.
Reader uses its own fixed reading palettes, not Omarchy theme colors.
