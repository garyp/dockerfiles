#!/bin/bash
#
# Tests for the opendkim image: key permissions are fixed at startup, syslog
# messages reach both stdout and /var/log/syslogd, and messages get signed.

here=$(cd "$(dirname "$0")" && pwd)
. "$here/../../test/lib.sh"

image=$TEST_PREFIX/opendkim
container=$TEST_PREFIX-opendkim
keys=$TEST_PREFIX-opendkim-keys

build_image "$image" "$here/.."
build_image "$image-miltertest" "$here" -f "$here/miltertest.Dockerfile" \
    --build-arg BASE="$image"
on_exit docker rmi "$image-miltertest"

log "Generating a test key"
new_volume "$keys"
docker run --rm -v "$keys":/etc/dkimkeys --entrypoint sh "$image" -ec '
    cd /etc/dkimkeys
    opendkim-genkey -s test -d example.com
    echo "test._domainkey.example.com example.com:test:/etc/dkimkeys/test.private" > keytable
    echo "example.com test._domainkey.example.com" > signingtable
'

start_container "$container" -v "$keys":/etc/dkimkeys "$image"
wait_for_log "$container" 'opendkim\[[0-9]+\]: OpenDKIM Filter v[0-9.]+ starting'
log "ok: opendkim startup is logged to stdout via syslog"

perms=$(docker exec "$container" sh -c \
    'cd /etc/dkimkeys && stat -c "%n %U:%G %a" . keytable signingtable test.private test.txt')
assert_eq ". opendkim:opendkim 500
keytable opendkim:opendkim 400
signingtable opendkim:opendkim 400
test.private opendkim:opendkim 400
test.txt opendkim:opendkim 400" "$perms" "key permissions are fixed at startup"

wait_for_file "$container" /var/log/syslogd/mail/current \
    'opendkim\[[0-9]+\]: OpenDKIM Filter .* starting'
log "ok: syslog messages are written to /var/log/syslogd"

log "Signing a test message"
out=$(docker run --rm --network container:"$container" "$image-miltertest" 2>&1) ||
    fail "miltertest failed:"$'\n'"$out"
assert_contains '^DKIM-Signature: .*d=example\.com; s=test;' "$out" \
    "milter adds a DKIM-Signature header"
wait_for_log "$container" 'T1: DKIM-Signature field added \(s=test, d=example\.com\)'
log "ok: signing is logged"
