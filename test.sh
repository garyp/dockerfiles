#!/bin/bash
#
# Run the image tests.
#
# Usage: ./test.sh [image...]
#
# Runs <image>/test/run.sh for each image given, or for every image that has
# one. Extra options for `docker build` (e.g. a proxy) can be passed in
# DOCKER_BUILD_OPTS.

set -u

cd "$(dirname "$0")"

if [ $# -gt 0 ]; then
    images=("$@")
else
    images=()
    for t in */test/run.sh; do
        [ -e "$t" ] && images+=("${t%%/*}")
    done
fi

if [ ${#images[@]} -eq 0 ]; then
    echo "No tests found" >&2
    exit 1
fi

failed=()
for image in "${images[@]}"; do
    image=${image%/}
    if [ ! -x "$image/test/run.sh" ]; then
        echo "No tests found for $image" >&2
        failed+=("$image")
        continue
    fi
    echo "=== $image"
    if "$image/test/run.sh"; then
        echo "=== $image: PASS"
    else
        echo "=== $image: FAIL"
        failed+=("$image")
    fi
done

if [ ${#failed[@]} -gt 0 ]; then
    echo "Failed: ${failed[*]}" >&2
    exit 1
fi
