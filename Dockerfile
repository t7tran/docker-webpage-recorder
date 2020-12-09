FROM ubuntu:20.04

COPY ./rootfs /

WORKDIR /recording

RUN groupadd -g 1000 recorder && \
    useradd -u 1000 -g 1000 -m recorder && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y curl pulseaudio xvfb firefox ffmpeg xdotool unzip && \
    curl -sL https://deb.nodesource.com/setup_14.x | bash - && \
    apt-get install -y nodejs && \
    npm install && \
    chmod +x /recording/*.sh /recording/*.js

USER recorder

CMD ["/recording/run.sh"]