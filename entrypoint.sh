#!/bin/bash

set -eu

[[ ${DEBUG:-false} == true ]] && set -x

logrotate_logfiles="/tmp/ray/**/worker-*.out /tmp/ray/**/worker-*.err"

# Log files to rotate; separated by a space
if [ -n "${LOGROTATE_LOGFILES}" ]; then
  logrotate_logfiles="${LOGROTATE_LOGFILES}"
fi

if [ -f "/etc/logrotate.conf" ]; then
  rm -f /etc/logrotate.conf
else
  touch /etc/logrotate.conf
fi

cat >> /etc/logrotate.conf << EOF
${logrotate_logfiles}
{
  nomail
  maxsize ${LOGROTATE_MAXFILESIZE:250*1024*1024}
  missingok
  notifempty
  copytruncate
  rotate ${LOGROTATE_FILENUM:5}
  delaycompress
}
EOF

cat /etc/logrotate.conf

cron_expr="1 0 * * *"

# Set cron schedule
if [ -z "${LOGROTATE_CRON_EXPR}" ]; then
  echo "LOGROTATE_CRON_EXPR environment variable is not set. Set to default: ${cron_expr}"
else
  echo "LOGROTATE_CRON_EXPR environment variable set to ${LOGROTATE_CRON_EXPR}"
  cron_expr=${LOGROTATE_CRON_EXPR}
fi

logrotate_cronlog=""

# Log `logrotate` outputs to a file
if [ -n "${LOGROTATE_OUTPUTFILE}" ]; then
  logrotate_cronlog=" 2>&1 | tee -a "${LOGROTATE_OUTPUTFILE}
fi

logrotate_cmd="/usr/sbin/logrotate -v /etc/logrotate.conf ${logrotate_cronlog}"
echo "${cron_expr} /bin/bash -c '${logrotate_cmd}'" | crontab -u ${LOGROTATE_USER} -

exec "$@"
