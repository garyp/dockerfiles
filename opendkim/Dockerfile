# syntax=docker/dockerfile:1

# The checksums must be updated along with S6_OVERLAY_VERSION; they're published
# as <tarball>.sha256 alongside each release.
ARG S6_OVERLAY_VERSION=3.2.3.2
ARG S6_OVERLAY_NOARCH_SHA256=5379750ed30a84bbd2e2dd74847ba6b5bd29cd0b2e3ea2ec58049b57eb2eda12
ARG S6_OVERLAY_X86_64_SHA256=e6befcc96a437a3831386ecfc51808c5d3e939dc5fe3c02ae9284599e8aa2408
ARG SYSLOGD_OVERLAY_NOARCH_SHA256=7d94a01ca36db0f7659ab90301b6b7aff6d0fc786f2271873c9b77ac27f02921

# Download stage, so the tarballs don't end up in the final image's layers
FROM scratch AS s6-overlay
ARG S6_OVERLAY_VERSION
ARG S6_OVERLAY_NOARCH_SHA256
ARG S6_OVERLAY_X86_64_SHA256
ARG SYSLOGD_OVERLAY_NOARCH_SHA256
ADD --checksum=sha256:${S6_OVERLAY_NOARCH_SHA256} \
    https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /
ADD --checksum=sha256:${S6_OVERLAY_X86_64_SHA256} \
    https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /
ADD --checksum=sha256:${SYSLOGD_OVERLAY_NOARCH_SHA256} \
    https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/syslogd-overlay-noarch.tar.xz /

FROM debian:13

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        opendkim \
        opendkim-tools \
        openssl \
        xz-utils \
        && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install s6-overlay, and syslogd-overlay (replaces socklog-overlay in s6-overlay v3)
RUN --mount=type=bind,from=s6-overlay,target=/tmp/s6-overlay \
    tar -C / -Jxpf /tmp/s6-overlay/s6-overlay-noarch.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay/s6-overlay-x86_64.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay/syslogd-overlay-noarch.tar.xz
ENTRYPOINT ["/init"]

RUN useradd --system --no-create-home --home-dir /nonexistent --shell /usr/sbin/nologin syslog && \
    useradd --system --no-create-home --home-dir /nonexistent --shell /usr/sbin/nologin sysllog
# Also forward all syslog messages to stdout. This appends a final directive
# to the upstream s6-log script, so it relies on that script ending with the
# s6-log directives; recheck when updating S6_OVERLAY_VERSION (the opendkim
# tests cover this).
RUN printf " + 1\n" >> /etc/s6-overlay/s6-rc.d/syslogd-log/run

# Fix ownership/permissions of the keys at startup
COPY fix-dkimkeys-attrs /etc/cont-init.d/01-opendkim
RUN chmod 755 /etc/cont-init.d/01-opendkim

COPY opendkim.conf opendkim.local.conf /etc/
RUN chmod 644 /etc/opendkim.conf /etc/opendkim.local.conf

EXPOSE 8891

CMD ["/usr/sbin/opendkim", "-f", "-l", "-u", "opendkim", "-p", "inet:8891", "-x", "/etc/opendkim.conf"]
