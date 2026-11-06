FROM python:3.12-slim

COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

RUN useradd --create-home --shell /usr/sbin/nologin ovos && \
    mkdir -p /home/ovos/.config/mycroft /home/ovos/.local/share /home/ovos/.cache && \
    chown -R ovos:ovos /home/ovos

COPY --chown=ovos:ovos mycroft.conf /home/ovos/.config/mycroft/mycroft.conf

USER ovos
EXPOSE 8080

ENTRYPOINT ["ovos-stt-server", "--engine", "ovos-stt-plugin-onnx-asr"]
CMD ["--host", "0.0.0.0", "--port", "8080"]
