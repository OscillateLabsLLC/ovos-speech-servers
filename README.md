# ovos-speech-servers

[![Status: Active](https://img.shields.io/badge/status-active-brightgreen)](https://github.com/OscillateLabsLLC/.github/blob/main/SUPPORT_STATUS.md)
[![Smoke test](https://github.com/OscillateLabsLLC/ovos-speech-servers/actions/workflows/smoke.yml/badge.svg)](https://github.com/OscillateLabsLLC/ovos-speech-servers/actions/workflows/smoke.yml)

Tested recipes for self-hosted speech-to-text (STT) and text-to-speech (TTS)
servers for [OVOS](https://openvoiceos.org) and [Neon](https://neon.ai) voice
assistants.

Speech models need more compute than a Raspberry Pi has. Run the model on a
bigger machine on your network, then point your assistant at it. Each recipe
serves one engine over the standard OVOS server API, from Docker or from a
Python virtual environment. Any OVOS or Neon device can use any recipe with
the same client config.

CI installs and tests every recipe both ways each week with real audio, so a
recipe that upstream changes break fails here first.

## Pick an engine

| Engine | Kind | Hardware | venv on | Notes |
| :--- | :--- | :--- | :--- | :--- |
| [onnx-asr](stt/onnx-asr/) | STT | CPU, 2 GB RAM | Linux, macOS | NVIDIA Parakeet. Fast and accurate, with punctuation. The OVOS default STT. |
| [Kokoro](tts/kokoro/) | TTS | CPU, 2 GB RAM | Linux | Natural voices, 9 languages. Faster than real time on a modern CPU. |
| phoonnx | TTS | Raspberry Pi and up | | The OVOS default TTS. *Planned.* |
| PocketTTS | TTS | CPU | | *Planned.* |
| Audio8 | TTS | **NVIDIA or Apple GPU** | | Clones a voice from a short clip. *Planned.* |

Every engine runs in Docker on Linux and macOS. The "venv on" column shows
where the [install without Docker](#without-docker) works.

## Quick start

You need Docker with Compose. To run the onnx-asr STT server:

```bash
git clone https://github.com/OscillateLabsLLC/ovos-speech-servers
cd ovos-speech-servers/stt/onnx-asr
docker compose up -d
```

The first start downloads the model, which can take a few minutes. Then
connect your assistant to the server. Refer to [clients/](clients/).

## Without Docker

`scripts/install-venv.sh` installs a server in a Python virtual environment.
You need Python 3.10 or later. Some engines accept fewer versions; the script
finds a suitable `python3.X` on your `PATH`.

```bash
git clone https://github.com/OscillateLabsLLC/ovos-speech-servers
cd ovos-speech-servers
scripts/install-venv.sh stt/onnx-asr
~/.local/share/ovos-speech-servers/onnx-asr/run.sh
```

The script does not use `sudo` and does not install system packages. It writes
only to `~/.local/share/ovos-speech-servers/<engine>/`. Set `PREFIX` to use a
different directory, and `PYTHON` to select the interpreter.

Each server has its own config file in that directory. It does not read or
change the `mycroft.conf` of an OVOS install on the same machine.

On Linux with systemd, the script also writes a user service unit and prints
the commands to enable it. To update a server, pull this repo and run the
script again. It upgrades the packages and keeps your config.

To listen on a different port, set `OVOS_SERVER_PORT` before `run.sh`, or add
`Environment=OVOS_SERVER_PORT=9000` to the service unit.

## Test a server

With [just](https://github.com/casey/just) and Python 3:

```bash
just test stt/onnx-asr stt http://localhost:8080
just test tts/kokoro tts http://localhost:9666
```

Without `just`, start the server and run the script directly:

```bash
python3 scripts/smoke.py stt http://localhost:8080
```

The STT test sends a recording and checks the transcript. The TTS test makes a
sentence and checks that the result is valid audio.

## Layout

```
clients/                 Client config for OVOS and Neon (the same for every engine)
stt/<engine>/            Dockerfile, compose.yml, mycroft.conf, README, and:
  requirements.txt         Version pins, shared by Docker and the venv install
  engine.env               Server command, port, and Python range for the venv install
tts/<engine>/            The same, for TTS engines
scripts/install-venv.sh  Install any engine without Docker
scripts/smoke.py         Smoke test for any running server
```

To change a version, edit the engine's `requirements.txt`. Docker and the
venv install both read it.

## License

Apache 2.0. Each engine and model has its own license. Refer to the README of
each recipe.
