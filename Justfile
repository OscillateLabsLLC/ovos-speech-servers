# `engine` is a recipe directory such as stt/onnx-asr or tts/kokoro.

default:
    @just --list

# Build one engine's image, e.g. `just build stt/onnx-asr`
build engine:
    docker compose -f {{engine}}/compose.yml build

# Start one engine in the background
up engine:
    docker compose -f {{engine}}/compose.yml up -d --build

# Stop one engine (keeps the model volume)
down engine:
    docker compose -f {{engine}}/compose.yml down

# Follow one engine's logs
logs engine:
    docker compose -f {{engine}}/compose.yml logs -f

# Install one engine without Docker, e.g. `just install stt/onnx-asr`
install engine:
    scripts/install-venv.sh {{engine}}

# Smoke-test a running engine, e.g. `just smoke stt http://localhost:8080`
smoke kind url:
    python3 scripts/smoke.py {{kind}} {{url}}

# Start, smoke-test, then stop one engine
test engine kind url: (up engine)
    python3 scripts/smoke.py {{kind}} {{url}} || (docker compose -f {{engine}}/compose.yml logs --tail 100; exit 1)
    just down {{engine}}
