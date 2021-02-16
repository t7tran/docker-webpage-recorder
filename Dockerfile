FROM ubuntu:20.04

COPY ./rootfs /

WORKDIR /recording

RUN groupadd -g 1000 recorder && \
    useradd -u 1000 -g 1000 -m recorder && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y netcat lz4json curl pulseaudio xvfb firefox ffmpeg xdotool unzip && \
    jqversion=1.6; curl -fsSLo /usr/bin/jq https://github.com/stedolan/jq/releases/download/jq-$jqversion/jq-linux64 && chmod +x /usr/bin/jq && \
    curl -sL https://deb.nodesource.com/setup_14.x | bash - && \
    apt-get install -y nodejs && \
    npm install && \
    chmod +x /recording/*.sh /recording/*.js && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /tmp/*

USER recorder

CMD ["/recording/run.sh"]