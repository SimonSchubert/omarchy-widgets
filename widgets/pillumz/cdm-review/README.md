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
The challenge id and poll secret survive a process restart. After a restart the face shows the
pending public code and a **Resume waiting** action; polling starts only when you resume it, so a
lost app does not silently poll in the background. Cancelling clears the challenge and its secrets.

The deployment origin is the single `let api = "https://ai.cdm.space"` declaration near the top of
`widget.owl`. Edit it only for another trusted AI Ops deployment. OWL deliberately invalidates
secrets when their written HTTPS origin changes, so pair again afterward.

A new grant is held behind `/api/native/me` verification before old content or any write is
exposed. Previously seen device IDs are treated as stale replies. Same-account recovery preserves
drafts, reading state and pending attempts; a different verified account hides old presentation
and quarantines old dispatch slots without submitting or deleting their history. `/me`, queue,
and exact-detail JSON responses must carry the current request generation and verified
account/device binding; detail responses must also name the complete current `{kind,pack,id}`.
This applies before successful data or JSON errors can affect cache, state, or UI. Unbound, late,
wrong-account/device, or wrong-item replies are ignored rather than relabelled. Ordinary network
loss or credential expiry leaves cached reading and local editing intact while writes are paused.

## Review behavior

- Ready, unparked gate/ask summaries come from `GET /api/native/review-queue`, oldest first.
  Ordinary `preparing` mail stays hidden; failed/stalled preparation appears under Problems. A
  partial pack outage is shown as partial, never as an empty/completed fleet. The first bounded
  page is native; a non-null `next_cursor` is called out with a full-app path for later pages.
- Exact gate/ask and operator-state reads supply status, complete plain body/signature text,
  subject/recipients, question/options, drafts and parking. The three snapshot-backed writers —
  `onec_receipt_create`, `onec_receipt_update`, and `onec_receipt_update_edited` — additionally
  present readable supplier/organization/warehouse/date/total fields and goods/services cards
  using the canonical input and stored `/receipt` reference names; unresolved IDs are explicit,
  and raw JSON is only an optional Copy action. Other receipt actions retain their generic ready
  preview and never call `/receipt`. Native approval of a snapshot-backed writer requires both a
  non-empty canonical `input.payload` and a non-empty saved receipt comparison context: a legacy request without that
  text is disabled here and must be resubmitted/reviewed in the full app. Missing or failing
  source attachment bytes are shown as context but never block native approval. Mail HTML,
  inline images and attachment bytes are not cached. At most six plaintext detail presentations
  are kept locally; durable per-item drafts are not evicted.
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

`owl check` and the store `owl review` pass for both artifacts. An isolated 28-case JVM fixture
runs this exact file on the stock `WidgetInstance`/Compose trigger and source scheduler at
Omalauncher 57fe9af, with a local fake HTTP server only. It covers the first pairing reply,
repeated identical pending polls, first and identical detail reads, same-item reopen, repeated
equal action replies, optimistic failure and skip/save CAS, the live-slot clear prohibition,
restored check-only slots with no replay, HTML-only mail, RNPT vs ДТ, incomplete problem lists,
full-app local-draft wording, the auth-pending recovery path, and the face artifact. Late-response
cases cover same-account re-pair, different-account read/write contamination, target switch and
reopen across exact/review/receipt/operator-state reads, old `/me` and queue auth failures, and
preservation of legitimate caches/drafts. Generic receipt actions load and approve without a
`/receipt` read; named snapshot writers still require saved comparison text, and an empty canonical
payload remains disabled even when saved context exists.

No production request, decision, send, install, notification/default/launcher change, device or
emulator rendering was performed. The JVM harness has no Recomposer frame loop, so it sends
frame-like snapshot apply notifications to settle source/trigger observers, without an unrelated
state write/restore; this is fixture scheduling, not artifact behavior. On-device
GrapheneOS/Omalauncher acceptance must still cover pairing, full-length mail,
touch/scroll/font scaling, screen-off notification landing, concurrent optimistic actions, restored
requests, CAS conflicts, offline state, attachment browser login return, and weak connectivity.
