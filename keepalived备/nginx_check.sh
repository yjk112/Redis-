#!/bin/bash
if ! pgrep -x nginx > /dev/null; then
    systemctl start nginx
    sleep 2
fi
if ! pgrep -x nginx > /dev/null; then
    exit 1
fi
exit 0

