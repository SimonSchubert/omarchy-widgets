# Send Files to Linux

Transfer Android files into this phone's Linux environment using the Android
browser's file picker. Requires Python and Bash. Licensed MIT.

The default destination is the Linux home directory (`~/`); choose another folder in the app or
browse folders on the upload page. Existing files are never overwritten: name
collisions get a numbered suffix. No cloud service or Wi-Fi is needed.

## Commands and local access

The app embeds its complete Python helper in `app.owl`. Its fixed bootstrap
writes that reviewed source to `~/.cache/owl-send-files/server.py` and runs it.
OWL multiline strings preserve backslashes, so the bootstrap first removes one
layer of escaping from the embedded constant (backslashes, quotes and dollar signs).
The review tool warns about running a widget value as code because both the
bootstrap and helper are string constants passed through `sh()`. Neither comes
from the network, user input, or transfer status. The destination also uses
`sh()` and is passed as a separate argument.

The helper starts a temporary HTTP server on `127.0.0.1` at a random port, with
a newly generated secret URL for each session. It checks Host and Origin.
Anyone with that URL on the device can browse Linux folders and save files to
writable destinations; keep the upload page private. No session URL, token or
user data is included in this submission.

Uploads stream to temporary files, remove incomplete files, and use hard links
to avoid overwriting existing files. The server stops after the browser
finishes the selected batch, when stopped manually, or after five idle minutes.

`preview.png` is the screen image produced by `owl-check`. The Everforest WebP
is converted from that same image; other theme previews are not yet included.

## Version 1.3

- Fix startup: preserve OWL's actual multiline-string behavior when writing the helper.
- Default to the Linux home directory instead of Downloads, with a fresh persisted folder setting.
- Test the literal helper passed to the actual bootstrap, without pre-decoding it in the test.
