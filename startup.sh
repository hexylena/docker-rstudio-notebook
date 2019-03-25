#!/bin/bash


# Launch traffic monitor
/monitor_traffic.sh &
# And nginx in foreground mode.
nginx -g 'daemon off;'
