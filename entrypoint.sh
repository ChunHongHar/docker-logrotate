#!/bin/bash

set -e

# [[ ${DEBUG} == true ]] && set -x

cat > /etc/logrotate.conf << EOF
${LOGROTATE_LOGFILES}
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

cron_expr="0 * * * *" # Default value
if [ -z "$LOGROTATE_CRON_EXPR" ]; then
  echo "LOGROTATE_CRON_EXPR environment variable is not set. Set to default: $cron_expr"
else
  echo "LOGROTATE_CRON_EXPR environment variable set to $LOGROTATE_CRON_EXPR"
  cron_expr=$LOGROTATE_CRON_EXPR
fi

logrotate_cronlog=""

if [ -n "${LOGROTATE_LOGFILE}" ] && [ -z "${SYSLOGGER}"]; then
  logrotate_cronlog=" 2>&1 | tee -a "${LOGROTATE_LOGFILE}
else
#   if [ -n "${SYSLOGGER}" ]; then
#     logrotate_cronlog=" 2>&1 | "${syslogger_command}
#   fi
    logrotate_cronlog=">/proc/1/fd/1 2>/proc/1/fd/2"
fi

logrotate_cmd="/usr/sbin/logrotate -v /etc/logrotate.conf $logrotate_cronlog"
echo "$cron_expr $LOGROTATE_USER /bin/bash -c '$logrotate_cmd'"
echo "$cron_expr $LOGROTATE_USER /bin/bash -c '$logrotate_cmd'" | crontab -u $LOGROTATE_USER -

echo "$@"
exec "$@"
