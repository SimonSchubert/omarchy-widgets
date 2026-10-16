# APK Maker

Turn your next idea into an Android app—right from your phone.

Describe what you want, choose Claude Code, Codex or OpenCode, and let APK Maker handle the project and local build. Keep your apps together in a clean dashboard, try each update, and accept or discard changes with confidence.

- Create Kotlin and Jetpack Compose apps from a prompt.
- Start with an included offline Hello World app, built locally during first-time setup without an AI account. Tap to try its counter, then describe a change to make it your own.
- Build locally and install through ADB, or download an APK for manual installation.
- Improve existing apps with reviewed changes and recoverable project history.
- Add capabilities with the built-in skills library.
- Connect GitHub for source synchronization and pull requests.
- Prepare signed Google Play releases, review publishing requirements, and manage testing tracks.
- Protect signing credentials and create encrypted project backups.

Requires Omarchy Launcher with OWL 7 support, an installed and authenticated coding agent, internet access for setup and online services, and enough storage for the Android toolchain. Agent subscriptions, GitHub authentication and a Google Play developer account are separate where applicable. ADB installation requires a connected device; downloaded APKs require manual installation. Agent filesystem isolation depends on host support.

The optional community tester directory is configured by the user with `apk-maker set communityRepo owner/repository`; no account or directory is bundled.

Version: 2.17.2. License: MIT. Category: Development.

`widget.owl` is the standalone store artifact. `preview.png` is a fresh, unaltered launcher-rendered screenshot of the main apps screen, captured on October 16, 2026. It shows the four current apps and their reported states; it contains no account details, prompts, local paths or device information.

This update improves crash-repair synchronization, installation reporting, failed-change recovery, job reliability, release verification and encrypted backups. Compact tiles now preserve readable app labels and provide access to the full app list. Accepted changes clear the obsolete review prompt, and optional tester-directory polling no longer produces an error before configuration.

Prepared for store submission; not published automatically.

### Installer transparency

The widget contains a compressed backend so it can be installed as a single file. The store reviewer flags its base64 decoding and recursive cleanup for manual review. The installer checks the archive's SHA-256, validates shell syntax, stages a complete release, and switches the active release atomically while retaining a rollback target. Package installation during setup uses the host's package manager. Credentials, app projects, device configuration and signing keys are not included in the archive.

The main-screen preview shows this installation's app names and icons only. It does not prove that downloaded APKs have been installed or tested; those states are reported separately.
