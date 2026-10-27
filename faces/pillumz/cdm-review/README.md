# CDM review face

A standalone whole-page native CDM gate/question review for Omalauncher 0.13+ (OWL 12). It uses no
Arch Linux packages and no launcher changes. The `widgets/pillumz/cdm-review` tile provides the
same native review through the widget's full-screen `screen { }`, plus count/problem glance state.
Each installed artifact pairs independently.

Read `widgets/pillumz/cdm-review/README.md` in this repository for the shared pairing, origin,
review, offline, conflict, attachment and full-app behavior. In this face the same single origin
setting is near the top of `face.owl`:

```owl
let api = "https://ai.cdm.space"
```

Changing that trusted deployment origin deliberately invalidates OWL's origin-bound encrypted
secret and requires pairing again. Never paste tokens or cookies into either artifact.

Stock `owl.jar check` and the store reviewer pass for both artifacts. The isolated 30-case
stock-`WidgetInstance`/Compose runtime fixture primarily exercises the widget; one case runs this
face. Its shared logic is byte-identical to the generated widget logic, checked separately.
The suite uses fake HTTP and covers pairing, bound details, equal replies, optimistic/restored
slots, CAS, late-response isolation, and receipt rendering. No on-device or emulator rendering was
performed, so no preview is included; compilation is not runtime acceptance. No installation, production request/decision,
notification/default change, or launcher modification was made.
