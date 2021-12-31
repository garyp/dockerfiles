FROM debian:11

# Install s6-overlay
ADD https://github.com/just-containers/s6-overlay/releases/download/v2.2.0.3/s6-overlay-amd64-installer /tmp/
RUN chmod +x /tmp/s6-overlay-amd64-installer && /tmp/s6-overlay-amd64-installer /
ENTRYPOINT ["/init"]

# Install socklog-overlay
ADD https://github.com/just-containers/socklog-overlay/releases/download/v3.1.2-0/socklog-overlay-amd64.tar.gz /tmp/
RUN tar xzf /tmp/socklog-overlay-amd64.tar.gz -C /
RUN printf "+\n1\n" > /etc/socklog.rules/forward-stdout

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        postsrsd \
        && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

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

CMD exec /usr/sbin/postsrsd -e -l "${SRS_LISTEN_ADDR}" ${SRS_EXTRA_OPTIONS} -u postsrsd -c /var/lib/postsrsd
