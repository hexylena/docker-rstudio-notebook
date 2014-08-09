#!/bin/bash

if [ `netstat -t | grep -v CLOSE_WAIT | grep ':8787' | wc -l` -lt 3 ]
then
    if [ -e "/tmp/monitor_run" ];
    then
        pkill tail
        # We will create new history elements with all data that is relevant,
        # this means we can delete everything from /import/
        # rm /import/ -rf
    fi
fi

touch /tmp/monitor_run
