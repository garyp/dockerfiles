FROM debian:10

# Install s6-overlay
ADD https://github.com/just-containers/s6-overlay/releases/download/v2.2.0.3/s6-overlay-amd64-installer /tmp/
RUN chmod +x /tmp/s6-overlay-amd64-installer && /tmp/s6-overlay-amd64-installer /
ENTRYPOINT ["/init"]

# Install socklog-overlay
ADD https://github.com/just-containers/socklog-overlay/releases/download/v3.1.1-1/socklog-overlay-amd64.tar.gz /tmp/
RUN tar xzf /tmp/socklog-overlay-amd64.tar.gz -C /
RUN printf "+\n1\n" > /etc/socklog.rules/forward-stdout

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        opendkim \
        opendkim-tools \
        openssl \
        && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN printf "/etc/dkimkeys true opendkim 0400 0500\n" > /etc/fix-attrs.d/01-opendkim

COPY opendkim.conf opendkim.local.conf /etc/
RUN chmod 644 /etc/opendkim.conf /etc/opendkim.local.conf

EXPOSE 8891

CMD ["/usr/sbin/opendkim", "-f", "-l", "-u", "opendkim", "-p", "inet:8891", "-x", "/etc/opendkim.conf"]
