# Shared helpers for the image tests. Source from <image>/test/run.sh.

set -euo pipefail

TEST_PREFIX=dockerfiles-test

_cleanup_cmds=()
_containers=()

log() {
    echo "--- $*"
}

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

# Run a command when the test exits (in reverse order of registration).
# (The ${arr[@]+...} expansions keep empty arrays working with set -u on
# bash < 4.4, e.g. macOS's /bin/bash.)
on_exit() {
    _cleanup_cmds=("$(printf '%q ' "$@")" ${_cleanup_cmds[@]+"${_cleanup_cmds[@]}"})
}

_run_cleanup() {
    local status=$1 cmd c
    if [ "$status" -ne 0 ]; then
        for c in ${_containers[@]+"${_containers[@]}"}; do
            echo "--- logs of $c:" >&2
            docker logs "$c" >&2 2>&1 || true
        done
    fi
    for cmd in ${_cleanup_cmds[@]+"${_cleanup_cmds[@]}"}; do
        eval "$cmd" >/dev/null 2>&1 || true
    done
}
trap '_run_cleanup $?' EXIT

# build_image <tag> <context dir> [docker build args...]
build_image() {
    local tag=$1 dir=$2
    shift 2
    log "Building $tag"
    # shellcheck disable=SC2086
    docker build -q ${DOCKER_BUILD_OPTS:-} -t "$tag" "$@" "$dir" >/dev/null
}

# new_volume <name>: create an empty volume that is removed on exit.
new_volume() {
    docker volume rm -f "$1" >/dev/null 2>&1 || true
    docker volume create "$1" >/dev/null
    on_exit docker volume rm -f "$1"
}

# start_container <name> [docker run args...]: run detached, removed on exit.
# On failure, the container's logs are printed before it is removed.
start_container() {
    local name=$1
    shift
    docker rm -f "$name" >/dev/null 2>&1 || true
    on_exit docker rm -f "$name"
    _containers+=("$name")
    docker run -d --name "$name" "$@" >/dev/null
}

# _wait_for_match <grep -E pattern> <timeout seconds> <command...>: retry the
# command until its output matches. The output is captured before grepping, as
# piping into grep -q can SIGPIPE the command and fail the pipeline.
_wait_for_match() {
    local pattern=$1 timeout=$2 out i
    shift 2
    for ((i = 0; i < timeout * 2; i++)); do
        out=$("$@" 2>&1) || true
        if grep -qE -- "$pattern" <<<"$out"; then
            return 0
        fi
        sleep 0.5
    done
    return 1
}

# wait_for_log <container> <grep -E pattern> [timeout seconds]
wait_for_log() {
    _wait_for_match "$2" "${3:-20}" docker logs "$1" ||
        fail "timed out waiting for /$2/ in logs of $1"
}

# wait_for_file <container> <path> <grep -E pattern> [timeout seconds]
wait_for_file() {
    _wait_for_match "$3" "${4:-20}" docker exec "$1" cat "$2" ||
        fail "timed out waiting for /$3/ in $2 in $1"
}

# assert_eq <expected> <actual> <description>
assert_eq() {
    [ "$1" = "$2" ] || fail "$3: expected '$1', got '$2'"
    log "ok: $3"
}

# assert_contains <grep -E pattern> <text> <description>
assert_contains() {
    grep -qE -- "$1" <<<"$2" || fail "$3: /$1/ not found in:"$'\n'"$2"
    log "ok: $3"
}
