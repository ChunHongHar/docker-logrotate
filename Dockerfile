FROM debian:trixie-slim

LABEL maintainer="ChunHongHar <10622592-secant-senpai@users.noreply.gitlab.com>"

# System setting
ARG CONTAINER_UID=1000
ARG CONTAINER_GID=1000
ARG LOGROTATE_USER=logrotate
ENV LOGROTATE_USER=$LOGROTATE_USER
ARG LOGROTATE_GROUP=logrotate

RUN <<EOF
#!/bin/bash

set -euo pipefail

# create a new group for logrotate binary
groupadd -g $CONTAINER_GID $LOGROTATE_GROUP
# add a user in the logrotate group
useradd -u $CONTAINER_UID -g $CONTAINER_GID -c "" $LOGROTATE_USER

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

# Logrotate configuration
ENV LOGROTATE_CRON_EXPR= \
    LOGROTATE_LOGFILES= \
    LOGROTATE_MAXFILESIZE= \
    LOGROTATE_FILENUM= \
    LOGROTATE_OUTPUTFILE= \
    DEBUG=

COPY --chmod=755 entrypoint.sh /app/entrypoint.sh
RUN touch /var/log/cron.log

ENTRYPOINT ["/usr/bin/tini", "--", "/app/entrypoint.sh"]
CMD ["cron", "-f", "&&", "tail", "-f", "/var/log/cron.log"]
