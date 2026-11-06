# Connect a voice assistant to your server

The client configuration does not depend on the engine. Every STT server in
this repo uses the same HTTP API, and every TTS server uses the same HTTP API.
Your assistant needs one generic plugin for each:

| Server kind | Client plugin | Default port |
| :--- | :--- | :--- |
| STT | `ovos-stt-plugin-server` | 8080 |
| TTS | `ovos-tts-plugin-server` | 9666 |

Both plugins are installed by default on current OVOS and Neon images.

Replace `192.168.1.50` with the address of the machine that runs your server.

## OVOS

Edit `~/.config/mycroft/mycroft.conf`:

```json
{
  "stt": {
    "module": "ovos-stt-plugin-server",
    "ovos-stt-plugin-server": {
      "urls": ["http://192.168.1.50:8080/stt"]
    }
  },
  "tts": {
    "module": "ovos-tts-plugin-server",
    "ovos-tts-plugin-server": {
      "host": "http://192.168.1.50:9666"
    }
  }
}
```

## Neon

Edit `~/.config/neon/neon.yaml`:

```yaml
stt:
  module: ovos-stt-plugin-server
  ovos-stt-plugin-server:
    urls:
      - http://192.168.1.50:8080/stt
tts:
  module: ovos-tts-plugin-server
  ovos-tts-plugin-server:
    host: http://192.168.1.50:9666
```

## Fallback servers

The STT client tries each URL in `urls` in order. Put your own server first and
add others after it. If your server is down, the client uses the next one:

```json
"ovos-stt-plugin-server": {
  "urls": [
    "http://192.168.1.50:8080/stt",
    "http://192.168.1.51:8080/stt"
  ]
}
```

You can also add a public OVOS server as the last entry. Public servers send
your audio to a third party, so do not use one if privacy is why you run your
own server.

## Check the connection

From the assistant's machine, before you restart the assistant:

```bash
curl http://192.168.1.50:8080/status
curl http://192.168.1.50:9666/status
```

If either command times out, check the server machine's firewall for the port.
