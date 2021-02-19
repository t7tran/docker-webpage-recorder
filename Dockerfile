FROM ubuntu:20.04

COPY ./rootfs /

WORKDIR /recording

RUN groupadd -g 1000 recorder && \
    useradd -u 1000 -g 1000 -m recorder && \
# Install required packages
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y locales netcat lz4json curl pulseaudio xvfb firefox ffmpeg xdotool unzip && \
# Configure locale support for all languages
    dpkg-reconfigure locales --frontend=noninteractive && \
    sed -i -e '/# aa_DJ/,${s/^# //g}' /etc/locale.gen && \
    locale-gen && \
# Install jq tool for json processing
    jqversion=1.6; curl -fsSLo /usr/bin/jq https://github.com/stedolan/jq/releases/download/jq-$jqversion/jq-linux64 && chmod +x /usr/bin/jq && \
# Install Node JS
    curl -sL https://deb.nodesource.com/setup_14.x | bash - && \
    apt-get install -y nodejs && \
# Install the OpenH264 plugin for Firefox
    mkdir -p /opt/firefox/gmp-gmpopenh264/1.8.1.1/ && \
    cd /opt/firefox/gmp-gmpopenh264/1.8.1.1/ && \
    curl -s -o openh264.zip http://ciscobinary.openh264.org/openh264-linux64-2e1774ab6dc6c43debb0b5b628bdf122a391d521.zip && \
    unzip openh264.zip && rm -f openh264.zip && \
    chown -R recorder:recorder /opt/firefox && \
# Install node packages
    npm install && \
    chmod +x /recording/*.sh /recording/*.js && \
# Clean up
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /tmp/*

USER recorder

CMD ["/recording/run.sh"]