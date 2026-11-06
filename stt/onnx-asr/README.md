# onnx-asr STT server

Runs [ovos-stt-plugin-onnx-asr](https://github.com/OpenVoiceOS/ovos-stt-plugin-onnx-asr)
behind [ovos-stt-http-server](https://github.com/OpenVoiceOS/ovos-stt-http-server).
It uses [onnx-asr](https://github.com/istupakov/onnx-asr) to run speech models
with ONNX Runtime. No GPU is necessary.

The default model is NVIDIA Parakeet TDT 0.6B v2 (English), quantized to int8.
It writes punctuation and capital letters, and is the plugin's own default
model for English.

## Requirements

- CPU: x86_64 or ARM64
- RAM: about 1.6 GB while the server runs
- Disk: about 650 MB for the model, in the `onnx-asr-models` volume

Measured on an M3 Max (Docker, 4 vCPU): an 11-second clip transcribes in
0.3 seconds.

## Run

```bash
docker compose up -d
```

The first start downloads the model. Wait until this command answers:

```bash
curl http://localhost:8080/status
```

## Run without Docker

On Linux or macOS, with Python 3.10 to 3.13, from the repo root:

```bash
scripts/install-venv.sh stt/onnx-asr
~/.local/share/ovos-speech-servers/onnx-asr/run.sh
```

The config is at `~/.local/share/ovos-speech-servers/onnx-asr/config/mycroft/mycroft.conf`.
The plugin stores models in `~/.local/share/ovos_stt_plugin_onnxasr/`. If you
already run OVOS with this plugin on the same machine, the two share the
downloaded models.

## Test

```bash
curl -X POST -H "Content-Type: audio/wav" \
  --data-binary @../../tests/fixtures/jfk.wav \
  "http://localhost:8080/stt?lang=en"
```

## Change the model

With Docker, edit `mycroft.conf`, uncomment the config mount in
`compose.yml`, and restart. Without Docker, edit the installed config and
restart. For example, to use the multilingual Parakeet v3 model:

```json
"ovos-stt-plugin-onnx-asr": {
  "model": "nemo-parakeet-tdt-0.6b-v3",
  "quantization": "int8"
}
```

If you remove `model`, the plugin selects a model for the request language.
For the supported models, refer to the
[plugin README](https://github.com/OpenVoiceOS/ovos-stt-plugin-onnx-asr).

## Known issues

- `requirements.txt` pins an alpha release of `ovos-stt-http-server`. The stable
  release on PyPI (0.1.4) cannot install with this plugin and ignores the
  plugin config.
- Send ISO 639-1 language codes (`en`), not locales (`en-us`), when you call
  the server directly. OVOS clients send the language for you.
- The plugin does not declare `onnxruntime` as a dependency.
  `requirements.txt` installs it with `onnx-asr[cpu,hub]`.

## Licenses

The Parakeet models are CC-BY-4.0 (NVIDIA). onnx-asr is MIT. The OVOS packages
are Apache 2.0.
