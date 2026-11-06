# Kokoro TTS server

Runs [ovos-tts-plugin-kokoro](https://github.com/OscillateLabsLLC/ovos-tts-plugin-kokoro)
behind [ovos-tts-server](https://github.com/OpenVoiceOS/ovos-tts-server).
[Kokoro](https://huggingface.co/hexgrad/Kokoro-82M) is an 82M-parameter model
with natural voices in 9 languages. It runs on CPU. No GPU is necessary.

The default voice is `af_bella` (American English, female).

## Requirements

- CPU: x86_64 or ARM64
- RAM: about 1.5 GB for each language you use
- Disk: about 320 MB for the model and voices, in the `kokoro-cache` volume

Measured on an M3 Max (Docker, 4 vCPU): a 5-second sentence takes about
0.7 seconds (RTF 0.15). The first request after a start is slower, because
the model loads on first use.

The image installs the CPU build of PyTorch. On a GPU host, the CPU build is
still faster than real time, and the image stays about 2 GB smaller.

## Run

```bash
docker compose up -d
```

The first start downloads the model. Wait until this command answers:

```bash
curl http://localhost:9666/status
```

## Run without Docker

**Linux only**, with Python 3.10 to 3.12. Kokoro does not install on Python
3.13 or later. If your distribution's Python is newer, the script tells you how
to get a suitable one. From the repo root:

```bash
scripts/install-venv.sh tts/kokoro
~/.local/share/ovos-speech-servers/kokoro/run.sh
```

The script installs the CPU build of PyTorch. No system packages are
necessary: the Python packages include the espeak-ng library and data.

**macOS: use Docker.** The macOS wheel of `espeakng-loader` 0.2.4 looks for
its data at a path on the machine that built it. When Kokoro sends a word to
espeak (an unknown word, or any British voice), espeak cannot find its data
and stops the whole server process. The Linux wheel does not have this
problem, and the Docker image is Linux.

## Test

```bash
curl -o hello.wav "http://localhost:9666/synthesize/Hello%20from%20Kokoro"
```

## Change the voice

With Docker, edit `mycroft.conf`, uncomment the config mount in
`compose.yml`, and restart. Without Docker, edit
`~/.local/share/ovos-speech-servers/kokoro/config/mycroft/mycroft.conf` and
restart:

```json
"ovos-tts-plugin-kokoro": {
  "voice": "bm_george"
}
```

The voice ID sets the accent: `af_`/`am_` are American English, `bf_`/`bm_`
are British English. For all voices, refer to the
[plugin README](https://github.com/OscillateLabsLLC/ovos-tts-plugin-kokoro).

## Known issues

- `requirements.txt` includes only the English spaCy model. Japanese and
  Mandarin voices need the plugin's `[ja]` or `[zh]` extras. Add them to the
  `ovos-tts-plugin-kokoro` line, for example `ovos-tts-plugin-kokoro[ja]==0.4.0`.
- The `--cache` flag saves every sentence to disk, so a repeated phrase
  returns at once. With Docker, the cache is in the `kokoro-cache` volume. To
  turn it off, remove `--cache` from `CMD` in the `Dockerfile`, or from
  `SERVER_ARGS` in `engine.env` before you run the install script.

## Licenses

The Kokoro model is Apache 2.0. The OVOS packages and the plugin are
Apache 2.0.
