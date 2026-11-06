#!/usr/bin/env bash
# Install one engine's server in a Python virtual environment, without Docker.
#
#   scripts/install-venv.sh stt/onnx-asr
#
# Environment:
#   PYTHON  interpreter to use (default: the newest python3.X in the engine's range)
#   PREFIX  install root (default: ${XDG_DATA_HOME:-~/.local/share}/ovos-speech-servers)
#
# Safe to run again: it upgrades packages to the pins and keeps your config.
# It never uses sudo and writes only under PREFIX.
set -euo pipefail

TORCH_CPU_INDEX="https://download.pytorch.org/whl/cpu"

die() { echo "error: $*" >&2; exit 1; }

load_engine() {
    local repo_root engine_arg="$1"
    repo_root="$(cd "$(dirname "$0")/.." && pwd)"
    ENGINE_DIR="$repo_root/${engine_arg%/}"
    [[ -f "$ENGINE_DIR/engine.env" ]] || die "no engine.env in $ENGINE_DIR"
    # shellcheck source=/dev/null
    source "$ENGINE_DIR/engine.env"
    ENGINE_NAME="$(basename "$ENGINE_DIR")"
    INSTALL_DIR="${PREFIX:-${XDG_DATA_HOME:-$HOME/.local/share}/ovos-speech-servers}/$ENGINE_NAME"
}

check_platform() {
    local platform
    platform="$(uname -s)"
    [[ " $VENV_PLATFORMS " == *" $platform "* ]] || die "$ENGINE_NAME does not support a venv install on $platform.
  Use the Docker recipe instead. For the reason, refer to $ENGINE_DIR/engine.env"
}

python_in_range() {
    "$1" -c "import sys
lo = tuple(map(int, '$PYTHON_MIN'.split('.')))
hi = tuple(map(int, '$PYTHON_MAX'.split('.')))
sys.exit(0 if lo <= sys.version_info[:2] <= hi else 1)" 2>/dev/null
}

find_python() {
    if [[ -n "${PYTHON:-}" ]]; then
        python_in_range "$PYTHON" || die "PYTHON=$PYTHON is not Python $PYTHON_MIN to $PYTHON_MAX"
        echo "$PYTHON"; return
    fi
    local minor candidate
    for (( minor=${PYTHON_MAX#3.}; minor>=${PYTHON_MIN#3.}; minor-- )); do
        candidate="python3.$minor"
        command -v "$candidate" >/dev/null && python_in_range "$candidate" && { echo "$candidate"; return; }
    done
    command -v python3 >/dev/null && python_in_range python3 && { echo python3; return; }
    die "$ENGINE_NAME needs Python $PYTHON_MIN to $PYTHON_MAX, and none was found.
  Install one with your package manager (for example python3.12), or with uv:
    uv python install $PYTHON_MAX
    PYTHON=\"\$(uv python find $PYTHON_MAX)\" $0 $1"
}

install_packages() {
    local python="$1" pip="$INSTALL_DIR/venv/bin/pip"
    [[ -x "$pip" ]] || "$python" -m venv "$INSTALL_DIR/venv"
    "$pip" install --quiet --upgrade pip
    if [[ "$TORCH_CPU" == 1 && "$(uname -s)" == Linux ]]; then
        echo "Installing CPU-only torch..."
        "$pip" install --quiet torch --index-url "$TORCH_CPU_INDEX"
    fi
    echo "Installing $PLUGIN and $SERVER..."
    "$pip" install --quiet --upgrade -r "$ENGINE_DIR/requirements.txt"
}

install_config() {
    local config="$INSTALL_DIR/config/mycroft/mycroft.conf"
    if [[ -f "$config" ]]; then
        echo "Keeping your existing config: $config"
        return
    fi
    mkdir -p "$(dirname "$config")"
    cp "$ENGINE_DIR/mycroft.conf" "$config"
}

# The server gets its own XDG_CONFIG_HOME, so it never reads or changes the
# mycroft.conf of an OVOS install on the same machine.
write_launcher() {
    cat > "$INSTALL_DIR/run.sh" <<EOF
#!/bin/sh
export XDG_CONFIG_HOME="$INSTALL_DIR/config"
exec "$INSTALL_DIR/venv/bin/$SERVER" --engine $PLUGIN \\
    --host "\${OVOS_SERVER_HOST:-0.0.0.0}" --port "\${OVOS_SERVER_PORT:-$PORT}" $SERVER_ARGS
EOF
    chmod +x "$INSTALL_DIR/run.sh"
}

write_systemd_unit() {
    cat > "$INSTALL_DIR/ovos-$ENGINE_NAME.service" <<EOF
[Unit]
Description=OVOS $ENGINE_NAME server ($PLUGIN)
After=network-online.target

[Service]
ExecStart=$INSTALL_DIR/run.sh
Restart=on-failure

[Install]
WantedBy=default.target
EOF
}

print_next_steps() {
    cat <<EOF

Installed $ENGINE_NAME in $INSTALL_DIR
  Config: $INSTALL_DIR/config/mycroft/mycroft.conf
  Start:  $INSTALL_DIR/run.sh
The first start downloads the model. Then the server listens on port $PORT.
EOF
    if command -v systemctl >/dev/null; then
        cat <<EOF

To run it as a service for your user:
  systemctl --user enable --now $INSTALL_DIR/ovos-$ENGINE_NAME.service
To also start it at boot, before you log in:
  loginctl enable-linger \$USER
EOF
    fi
}

main() {
    [[ $# -eq 1 ]] || die "usage: $0 <kind>/<engine>, for example: $0 stt/onnx-asr"
    load_engine "$1"
    check_platform
    local python
    python="$(find_python "$1")"
    echo "Using $python ($("$python" --version))"
    mkdir -p "$INSTALL_DIR"
    install_packages "$python"
    install_config
    write_launcher
    write_systemd_unit
    print_next_steps
}

main "$@"
