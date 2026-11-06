FROM python:3.12-slim

# CPU-only torch first, or pip pulls the ~2 GB CUDA build.
RUN pip install --no-cache-dir torch --index-url https://download.pytorch.org/whl/cpu

COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

RUN useradd --create-home --shell /usr/sbin/nologin ovos && \
    mkdir -p /home/ovos/.config/mycroft /home/ovos/.cache && \
    chown -R ovos:ovos /home/ovos

COPY --chown=ovos:ovos mycroft.conf /home/ovos/.config/mycroft/mycroft.conf

USER ovos
EXPOSE 9666

ENTRYPOINT ["ovos-tts-server", "--engine", "ovos-tts-plugin-kokoro"]
CMD ["--host", "0.0.0.0", "--port", "9666", "--cache"]
