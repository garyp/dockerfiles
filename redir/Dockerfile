FROM debian:11

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        redir \
        && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

EXPOSE $SRC

USER nobody

CMD exec /usr/bin/redir -n -l info "$SRC" "$DEST"
