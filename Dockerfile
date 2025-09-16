FROM debian:bookworm-slim

LABEL maintainer="ChunHongHar <10622592-secant-senpai@users.noreply.gitlab.com>"

# System setting
ARG CONTAINER_UID=1000
ARG CONTAINER_GID=1000
ARG LOGROTATE_USER=logrotate
ENV LOGROTATE_USER=$LOGROTATE_USER
ARG LOGROTATE_GROUP=logrotate

# Logrotate setting
ARG LOGROTATE_CRON_EXPR
ENV LOGROTATE_CRON_EXPR=$LOGROTATE_CRON_EXPR
ARG LOGROTATE_LOGFILES="/tmp/ray/**/worker-*.out /tmp/ray/**/worker-*.err"
ARG LOGROTATE_MAXFILESIZE
ARG LOGROTATE_FILENUM
ENV LOGROTATE_LOGFILES=$LOGROTATE_LOGFILES
ENV LOGROTATE_MAXFILESIZE=$LOGROTATE_MAXFILESIZE
ENV LOGROTATE_FILENUM=$LOGROTATE_FILENUM

RUN <<EOF
#!/bin/bash

set -euo pipefail

addgroup --gid $CONTAINER_GID $LOGROTATE_GROUP
adduser --uid $CONTAINER_UID --gid $CONTAINER_GID --shell /bin/bash --disabled-password --comment "" $LOGROTATE_USER

apt update -y \
    && apt --no-install-recommends install -y \
        cron \
        logrotate \
        tini \
        tzdata \
    && apt clean \
    && rm -rf /var/lib/apt/lists/* \
    && apt remove apt --autoremove -y --allow-remove-essential

which cron
rm -rf /etc/cron.*/*

EOF

COPY . /app
COPY --chmod=755 entrypoint.sh /app/entrypoint.sh

ENTRYPOINT ["/usr/bin/tini", "--", "/app/entrypoint.sh"]
CMD ["cron","-f", "-l", "2"]
