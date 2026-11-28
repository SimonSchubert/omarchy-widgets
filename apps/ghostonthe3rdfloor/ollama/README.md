# ollama

A full-screen app for the local Ollama server: start/stop the server, list models, chat, pull or import GGUF models, unload loaded models, and set the server's context length.

## Installing Ollama

Ollama isn't in the Arch Linux ARM repositories, and the store's review check only accepts packages from the official Arch repositories, so this app deliberately leaves `ollama` out of `requires`. Install the official Linux arm64 build from [ollama.com](https://ollama.com/download/linux):

```sh
curl -fsSL https://ollama.com/install.sh | sh
```

The site also offers an arm64 tarball if you prefer to unpack it yourself. AUR/`yay` won't help here. The app only needs the `ollama` command on your PATH; it does not bundle or download it. If the command is missing, the app shows a clear message and an install-guide link instead of a start button.

To check, run `ollama --version` in a terminal. If it prints a version, the app is ready. Use the app's **start** button to launch `ollama serve`, or start it yourself; **stop** and **unload** control the server and loaded models after that.
