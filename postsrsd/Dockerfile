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
        postsrsd \
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
# s6-log directives; recheck when updating S6_OVERLAY_VERSION (the postsrsd
# tests cover this).
RUN printf " + 1\n" >> /etc/s6-overlay/s6-rc.d/syslogd-log/run

# Delete the auto-generated secret to force the secret to provided at container runtime
RUN rm /etc/postsrsd.secret

# Local domain name. Addresses are rewritten to originate from this domain.
ENV SRS_DOMAIN=""

# Exclude additional domains.
# You may list domains which shall not be subjected to address rewriting.
# If a domain name starts with a dot, it matches all subdomains, but not
# the domain itself. Separate multiple domains by comma.
ENV SRS_EXCLUDE_DOMAINS=""

# First separator character after SRS0 or SRS1.
# Can be one of: -+=
ENV SRS_SEPARATOR="="

# Secret key to sign rewritten addresses.
ENV SRS_SECRET="/etc/postsrsd.secret"

# Length of hash to be used in rewritten addresses
ENV SRS_HASHLENGTH=4

# Minimum length of hash to accept when validating return addresses.
# When increasing SRS_HASHLENGTH, set this to its previous value and
# wait for the duration of SRS return address validity (21 days) before
# increading this value as well.
ENV SRS_HASHMIN=4

# Local ports for TCP list.
# These ports are used to bind the TCP list for postfix. If you change
# these, you have to modify the postfix settings accordingly.
ENV SRS_FORWARD_PORT=10001 SRS_REVERSE_PORT=10002

# Bind to this address
ENV SRS_LISTEN_ADDR=0.0.0.0

# Additional Options
# PostSRSd understands a few rarely needed extra options:
# -A     always rewrite email addresses, even from SRS_DOMAIN
# -t<n>  set connection timeout to <n> seconds (default: 1800)
ENV SRS_EXTRA_OPTIONS=""

EXPOSE $SRS_FORWARD_PORT $SRS_REVERSE_PORT

# s6-overlay v3 runs CMD with an empty environment, so with-contenv is needed
# for postsrsd -e and the shell expansions to see the SRS_* settings
CMD ["with-contenv", "sh", "-c", "exec /usr/sbin/postsrsd -e -l \"${SRS_LISTEN_ADDR}\" ${SRS_EXTRA_OPTIONS} -u postsrsd -c /var/lib/postsrsd"]
