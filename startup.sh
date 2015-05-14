#!/bin/bash

/etc/init.d/cron start
# Make sure time for /import/ to be mounted
sleep 3

sed -i "s| '\*'; # IE_CORS_ORIGIN| '${CORS_ORIGIN}';|" /proxy.conf;
sed -i "s/IE_PORT/${DOCKER_PORT}/" /proxy.conf;
cp /proxy.conf /etc/nginx/sites-enabled/default

# The RStudio image starts as privileged user. The parent Galaxy server is
# mounting data into /import with the same permissions as the Galaxy server is
# running on. If /import is not owned by 1450 we need to create a new user with
# the same UID/GID as /import and make everything accessible to this new user.

uid=`stat --printf %u /import`
gid=`stat --printf %g /import`

# If the group doesn't exist, add it
[ $(getent group $gid) ] || groupadd -r galaxy -g $gid
# Add the user (maybe not fault tolerant for existing UIDs)
useradd -u $uid -r -g $gid -d /import \
    -c "RStudio Galaxy user" \
    -p `openssl passwd -1 $NOTEBOOK_PASSWORD` galaxy
# Correct permissions on the folder
chown $uid:$gid /import -R

# Start the servers
service rstudio-server start
service nginx restart

# RStudio users don't get the system environment for some reason (I need to
# figure out a better way to fix this...). Right now we persist the environment
# in a file which galaxy.py reads which is a little bit clunky and RStudio
# specific
env > /etc/profile.d/galaxy.sh

chmod 770 /import/ -R
tail -f /var/log/nginx/*
