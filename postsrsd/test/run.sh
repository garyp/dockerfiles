#!/bin/bash
#
# Tests for the postsrsd image: the SRS_* settings are read from the
# environment, addresses round-trip through the forward and reverse lookups,
# and syslog messages reach both stdout and /var/log/syslogd.

here=$(cd "$(dirname "$0")" && pwd)
. "$here/../../test/lib.sh"

image=$TEST_PREFIX/postsrsd
container=$TEST_PREFIX-postsrsd
secret=$TEST_PREFIX-postsrsd-secret

build_image "$image" "$here/.."

# query <port> <address>: send a TCP table lookup to postsrsd in the container
query() {
    docker exec "$container" bash -c \
        'exec 3<>/dev/tcp/127.0.0.1/"$1" && echo "get $2" >&3 && head -n1 <&3' \
        - "$@"
}

log "Checking that the secret must be provided at runtime"
status=0
out=$(docker run --rm -e SRS_DOMAIN=example.com "$image" 2>&1) || status=$?
[ "$status" -ne 0 ] || fail "container exited with status 0 without a secret"
assert_contains 'Cannot open file with secret: /etc/postsrsd.secret' "$out" \
    "postsrsd refuses to start without a secret"

new_volume "$secret"
docker run --rm -v "$secret":/secret --entrypoint sh "$image" -ec \
    'head -c 32 /dev/urandom | base64 > /secret/postsrsd.secret'

start_container "$container" -v "$secret":/etc/srs:ro \
    -e SRS_DOMAIN=example.com -e SRS_EXCLUDE_DOMAINS=excluded.org \
    -e SRS_SECRET=/etc/srs/postsrsd.secret -e SRS_SEPARATOR=+ \
    -e SRS_HASHLENGTH=6 -e SRS_EXTRA_OPTIONS="-A -t60" \
    -e SRS_FORWARD_PORT=11001 -e SRS_REVERSE_PORT=11002 "$image"

log "Rewriting an address"
_wait_for_match '^200 ' 20 query 11001 user@other.org ||
    fail "postsrsd did not answer the forward lookup"
fwd=$(query 11001 user@other.org)
assert_contains '^200 SRS0\+[^=]{6}=[^=]+=other\.org=user@example\.com$' "$fwd" \
    "forward lookup rewrites the address using the SRS_* settings"

rev=$(query 11002 "${fwd#200 }")
assert_eq "200 user@other.org" "$rev" "reverse lookup restores the address"

out=$(query 11001 user@example.com)
assert_contains '^200 SRS0\+[^=]+=[^=]+=example\.com=user@example\.com$' "$out" \
    "SRS_EXTRA_OPTIONS are passed to postsrsd (-A rewrites local addresses)"

out=$(query 11001 user@excluded.org)
assert_contains '^500 Domain excluded' "$out" "SRS_EXCLUDE_DOMAINS addresses are not rewritten"

wait_for_log "$container" 'postsrsd\[[0-9]+\]: srs_forward: <user@other\.org> rewritten as'
log "ok: postsrsd messages are logged to stdout via syslog"

wait_for_file "$container" /var/log/syslogd/mail/current \
    'postsrsd\[[0-9]+\]: srs_reverse: <SRS0.*> rewritten as <user@other\.org>'
log "ok: syslog messages are written to /var/log/syslogd"
