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

if [[ "$uid" -ne "0" ]]; then
    # Fix the user + group ID, hopefully no clashes.
    sed -i "s|:1450:|:$gid:|" /etc/group
    sed -i "s|:1450:1450:|:$uid:$gid:|" /etc/passwd /etc/passwd-
fi;

# Correct permissions on the folder
chown $uid:$gid /import -R

# Start the server. I dont' trust their daemonization
/usr/lib/rstudio-server/bin/rserver --server-daemonize=0 &

# Pass some system environment variables to RStudio environment
echo "Sys.setenv(DEBUG=\"$DEBUG\")
Sys.setenv(GALAXY_WEB_PORT=\"$GALAXY_WEB_PORT\")
Sys.setenv(CORS_ORIGIN=\"$CORS_ORIGIN\")
Sys.setenv(DOCKER_PORT=\"$DOCKER_PORT\")
Sys.setenv(API_KEY=\"$API_KEY\")
Sys.setenv(HISTORY_ID=\"$HISTORY_ID\")
Sys.setenv(REMOTE_HOST=\"$REMOTE_HOST\")
Sys.setenv(GALAXY_URL=\"$GALAXY_URL\")
" >> /usr/lib/R/etc/Rprofile.site

# Launch traffic monitor
/monitor_traffic.sh &
# And nginx in foreground mode.
nginx -g 'daemon off;'
