# Test-only image with miltertest, to drive the opendkim milter
ARG BASE
FROM ${BASE}

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        miltertest \
        && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY sign.lua /sign.lua

ENTRYPOINT ["miltertest", "-s", "/sign.lua"]
CMD []
