#!/bin/bash
mkdir -p /var/log/supervisor
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf