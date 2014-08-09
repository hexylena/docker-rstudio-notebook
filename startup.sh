#!/bin/bash

/etc/init.d/cron start
CONF_FILE="/import/conf.yaml"
# Add the user
USERNAME=$(grep 'notebook_username' ${CONF_FILE} | sed 's/notebook_username: //g')
PASSWORD=$(grep 'notebook_password' ${CONF_FILE} | sed 's/notebook_password: //g')

useradd -p `openssl passwd -1 $PASSWORD` $USERNAME -d /import/
chown $USERNAME:$USERNAME /import/ -R
# Start the server
#/usr/lib/rstudio-server/bin/rserver --server-daemonize 0
service rstudio-server start
sleep 1
curl localhost:8787/auth-public-key > /import/rserver_pub_key
chmod 777 /import/ -R
# TODO implement something useful -- is it worht the install rsyslog?
tail -f /var/log/dmesg
