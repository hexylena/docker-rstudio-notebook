#!/bin/bash

/etc/init.d/cron start
USERNAME=$(grep 'notebook_username' ${CONF_FILE} | sed 's/notebook_username: //g')
PASSWORD=$(grep 'notebook_password' ${CONF_FILE} | sed 's/notebook_password: //g')
useradd -d /import/ -p $PASSWORD $USERNAME
/usr/lib/rstudio-server/bin/rserver --server-daemonize 0
