#!/bin/bash

# Take the netstat output to estimate if the client is still connected to
# the RStudio server. The 'CLOSE_WAIT' state will be ignored. It
# indicates that the server has received the first FIN signal from the client
# and the connection is in the process of being closed. But that can never happen.
# For some reason there are a few connections open that do not relate the
# client that needs to be connected over the port :80 If we do not have a
# connection open from port 80, kill the server and herewith the docker container.

# For RStudio there is typically one ESTABLISHED connection (get_events HTTP 50s long request)
# and one TIME_WAIT (probably the previous get_events HTTP request)

while true; do
    sleep 240

    if [ `netstat -t | grep -v CLOSE_WAIT | grep ':80' | wc -l` -lt 2 ]
    then
        pkill nginx
        # We will create new history elements with all data that is relevant,
        # this means we can delete everything from /import/
        if [[ "$DEBUG" == "false" ]];
        then
            rm -rf /import/*;
        fi
    fi

done
