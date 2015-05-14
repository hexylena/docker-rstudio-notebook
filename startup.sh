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

[ $(getent group $gid) ] || groupadd -r galaxy -g $gid
useradd -u $uid -r -g $gid -d /import \
    -c "RStudio Galaxy user" \
    -p `openssl passwd -1 $NOTEBOOK_PASSWORD` galaxy
chown $uid:$gid /import -R

# Start the servers
service rstudio-server start
service nginx restart

# Persist the environment elsewhere in the FS
env > /etc/profile.d/galaxy.sh

# Chown import as that user so they can write there
chown galaxy:galaxy /import/ -R
chmod 770 /import/ -R
tail -f /var/log/nginx/*
