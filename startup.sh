#!/bin/bash

sed -i "s| '\*'; # IE_CORS_ORIGIN| '${CORS_ORIGIN}';|" /proxy.conf;
sed -i "s|PROXY_PREFIX|${PROXY_PREFIX}|" /proxy.conf;
cp /proxy.conf /etc/nginx/sites-enabled/default

# The RStudio image starts as privileged user. The parent Galaxy server is
# mounting data into /import with the same permissions as the Galaxy server is
# running on. If /import is not owned by 1450 we need to create a new user with
# the same UID/GID as /import and make everything accessible to this new user.

uid=$(stat --printf %u /import)
gid=$(stat --printf %g /import)

# Fix the user + group ID, hopefully no clashes.
sed -i "s|:1450:|:$gid:|" /etc/group
sed -i "s|:1450:1450:|:$uid:$gid:|" /etc/passwd /etc/passwd-

# Correct permissions on the folder
chown $uid:$gid /import -R

# Start the server. I dont' trust their daemonization
/usr/lib/rstudio-server/bin/rserver --server-daemonize=0 &

# RStudio users don't get the system environment for some reason (I need to
# figure out a better way to fix this...). Right now we persist the environment
# in a file which galaxy.py reads which is a little bit clunky and RStudio
# specific
echo "DEBUG=$DEBUG
GALAXY_WEB_PORT=$GALAXY_WEB_PORT
CORS_ORIGIN=$CORS_ORIGIN
DOCKER_PORT=$DOCKER_PORT
API_KEY=$API_KEY
HISTORY_ID=$HISTORY_ID
REMOTE_HOST=$REMOTE_HOST
GALAXY_URL=$GALAXY_URL
" > /etc/profile.d/galaxy.sh

# Launch traffic monitor
/monitor_traffic.sh &
# And nginx in foreground mode.
nginx -g 'daemon off;'
