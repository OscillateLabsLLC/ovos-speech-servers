#!/usr/bin/env python3
"""Smoke-test a running OVOS STT or TTS server. Standard library only.

    smoke.py stt http://localhost:8080
    smoke.py tts http://localhost:9666
"""
import argparse
import base64
import io
import json
import sys
import time
import urllib.parse
import urllib.request
import wave
from pathlib import Path

FIXTURE = Path(__file__).resolve().parent.parent / "tests" / "fixtures" / "jfk.wav"
EXPECTED_STT_PHRASE = "ask not what your country can do for you"
TTS_SENTENCE = "The quick brown fox jumps over the lazy dog."
MIN_TTS_SECONDS = 1.0
POLL_INTERVAL_SECONDS = 5


def wait_until_ready(base_url: str, timeout: int) -> None:
    """Poll /status until it answers. The first start downloads the model."""
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        try:
            with urllib.request.urlopen(f"{base_url}/status", timeout=10) as resp:
                print(f"ready: {resp.read().decode()}")
                return
        except OSError:
            time.sleep(POLL_INTERVAL_SECONDS)
    sys.exit(f"FAIL: {base_url}/status did not answer in {timeout}s")


def normalize(text: str) -> str:
    return "".join(c for c in text.lower() if c.isalnum() or c == " ")


def check_stt(base_url: str, timeout: int) -> None:
    body = json.dumps({"audio_b64": base64.b64encode(FIXTURE.read_bytes()).decode()})
    request = urllib.request.Request(
        f"{base_url}/stt/json", data=body.encode(),
        headers={"Content-Type": "application/json"})
    started = time.monotonic()
    with urllib.request.urlopen(request, timeout=timeout) as resp:
        result = json.load(resp)
    elapsed = time.monotonic() - started
    print(f"transcript ({elapsed:.2f}s): {result['text']!r}")
    if EXPECTED_STT_PHRASE not in normalize(result["text"]):
        sys.exit(f"FAIL: transcript does not contain {EXPECTED_STT_PHRASE!r}")


def check_tts(base_url: str, timeout: int) -> None:
    url = f"{base_url}/synthesize/{urllib.parse.quote(TTS_SENTENCE)}"
    started = time.monotonic()
    with urllib.request.urlopen(url, timeout=timeout) as resp:
        audio = resp.read()
    elapsed = time.monotonic() - started
    with wave.open(io.BytesIO(audio)) as wav:
        seconds = wav.getnframes() / wav.getframerate()
        print(f"audio: {seconds:.2f}s at {wav.getframerate()} Hz, "
              f"synthesized in {elapsed:.2f}s (RTF {elapsed / seconds:.2f})")
    if seconds < MIN_TTS_SECONDS:
        sys.exit(f"FAIL: audio is {seconds:.2f}s, expected at least {MIN_TTS_SECONDS}s")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("kind", choices=["stt", "tts"])
    parser.add_argument("base_url")
    parser.add_argument("--ready-timeout", type=int, default=900,
                        help="seconds to wait for the first model download")
    parser.add_argument("--request-timeout", type=int, default=120)
    args = parser.parse_args()

    base_url = args.base_url.rstrip("/")
    wait_until_ready(base_url, args.ready_timeout)
    check = check_stt if args.kind == "stt" else check_tts
    check(base_url, args.request_timeout)
    print("PASS")


if __name__ == "__main__":
    main()
