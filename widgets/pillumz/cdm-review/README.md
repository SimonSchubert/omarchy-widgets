# CDM review

Native CDM gate/question review for Omalauncher 0.13+ (OWL 12). The tile shows ready/problem
counts and preparation failures. Tapping it opens the native full-screen review; this is not a web
shortcut and needs no Arch Linux packages or launcher changes.

The same review is also available as `faces/pillumz/cdm-review`. Each installed OWL artifact has
its own encrypted pairing and small presentation state; pair the surface(s) you actually use.

## Pair and configure

Tap **Pair this device**. The artifact starts the existing `/auth/native/start` challenge, displays
its public matching code, and opens the returned normal-browser consent URL. Confirm that code for
the intended CDM operator account in the browser. Polling returns an opaque `dt_` credential into
OWL's encrypted, origin-bound `secret` state. Never paste a token or browser cookie into the file.

The deployment origin is the single `let api = "https://ai.cdm.space"` declaration near the top of
`widget.owl`. Edit it only for another trusted AI Ops deployment. OWL deliberately invalidates
secrets when their written HTTPS origin changes, so pair again afterward.

Successful explicit re-pairing clears this artifact's local cached content and unsent local drafts
(the UI warns first); server-side drafts remain. Ordinary network loss or credential expiry leaves
cached reading and local editing intact while writes are paused. Cached content is bound to the
verified `/api/native/me` account.

## Review behavior

- Ready, unparked gate/ask summaries come from `GET /api/native/review-queue`, oldest first.
  Ordinary `preparing` mail stays hidden; failed/stalled preparation appears under Problems. A
  partial pack outage is shown as partial, never as an empty/completed fleet. The first bounded
  page is native; a non-null `next_cursor` is called out with a full-app path for later pages.
- Exact gate/ask and operator-state reads supply status, complete plain body/signature text,
  subject/recipients, question/options, drafts and parking. Receipt gates additionally present
  the complete canonical input and stored `/receipt` context as literal plaintext (record,
  source, references and warnings); a missing legacy snapshot disables native decisions and
  requires the full app. Mail HTML, inline images and attachment bytes are not cached. At most
  six plaintext detail presentations are kept locally; durable per-item drafts are not evicted.
- Approve/reject/answer/skip advance immediately. Four fixed dispatch slots retain exact item and
  input identities for late errors. A full pool visibly pauses new actions. After process restore,
  an unknown request is **check only** and is never resent automatically. Server
  first-transition-wins remains authoritative.
- Save uses operator-state revision CAS. A conflict keeps the local and server copies and requires
  an explicit choice. Resolving elsewhere retains the unsent local copy.
- Offline reading/editing works from cached plaintext. Offline actions are disabled, not queued or
  replayed. There are no custom sounds, success notifications, or background-delivery claims.
- Mail attachments and receipt originals open their existing same-origin browser-authenticated
  URLs. Browser sign-in may be required; no signed URL or bearer token is put in a URL.
  Attachment/source-document failure never gates approval.
- **Quick full app** uses `/#/review/<kind>/<pack>/<id>`; **Full app escape** and preparation
  problems use `/#/<kind>/<pack>/<id>`. Notifications and their exact full-app landing are owned by
  the AI Ops app, not by this widget or Omalauncher.

## Verification

`java -jar /home/explify/Projects/omalauncher/owl/build/cli/owl.jar check widget.owl` and the store
`owl review` pass. A temporary stock-`Host` fixture also exercised the compiled handlers for
optimistic slots, restored no-resend, pairing polls, ask/skip writes, CAS conflicts and receipt
readiness without network or a device. No device install, production request, decision, send,
launcher/default change, rendering, or on-device runtime verification was performed. On-device acceptance must cover pairing,
full-length mail, concurrent optimistic actions, restored requests, CAS conflicts, offline state,
attachment login return, accessibility, and weak connectivity.
