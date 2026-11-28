# ollama

A full-screen app for the local Ollama server: start/stop the server, list models, chat, pull or import GGUF models, unload loaded models, and set the server's context length.

## Installing Ollama

The store's review check only accepts packages from the official Arch repositories, so `requires` declares `ollama`, the official package name in Arch `extra`. `ollama-bin` is AUR-only and cannot be declared here.

This launcher runs under Arch Linux ARM, where the official `ollama` package may not be available. In that case the install prompt's package name won't install, and you'll need Ollama available on the phone first (for example, installed through AUR with `yay`). The app itself only needs the `ollama` command; it does not bundle or download it.

To check, run `ollama --version` in a terminal. If it prints a version, the app is ready. Use the app's **start** button to launch `ollama serve`, or start it yourself; **stop** and **unload** control the server and loaded models after that.
