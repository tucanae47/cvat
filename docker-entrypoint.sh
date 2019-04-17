#!/bin/bash
set -e

if [ "$1" = "supervisord" ]; then

  # Mandatory runtime env vars
  : ${HOME:?"Must be defined. See README.md"}

  echo "Configuring ..."
  mkdir -p \
    ${HOME}/share \
    ${HOME}/media \
    ${HOME}/logs \
    ${HOME}/data \
    ${HOME}/keys \
    ${HOME}/${MOUNT_DIR}/data \
    ${HOME}/${MOUNT_DIR}/keys \
    ${HOME}/${MOUNT_DIR}/logs 

  touch /var/log/supervisord/cvat_stdout.log
  touch /var/log/supervisord/cvat_stderr.log
  ln -sf /dev/stdout /var/log/supervisord/cvat_stdout.log 
  ln -sf /dev/stderr /var/log/supervisord/cvat_stderr.log
  chown -R ${USER}:${USER} /var/log/supervisord/cvat_stderr.log
  chown -R ${USER}:${USER} /var/log/supervisord/cvat_stdout.log
  chown -R ${USER}:${USER} /dev/stderr
  chown -R ${USER}:${USER} /dev/stdout


  chown -R ${USER}:${USER} /var/log/supervisord
  chmod -R 770 /var/log/supervisord

  touch ${HOME}/${MOUNT_DIR}/__init__.py

  touch ${HOME}/logs/cvat_server.log
  chown -R ${USER} ${HOME}/logs/cvat_server.log
  chown -R ${USER} ${HOME}/logs
  chmod 777 ${HOME}/logs
  chown -R ${USER} ${HOME}/data
  chmod 777 ${HOME}/data
  chown -R ${USER} ${HOME}/keys
  chmod 777 ${HOME}/keys

  
  touch ${HOME}/logs/cvat_server.log
  chown -R ${USER} ${HOME}/logs/cvat_server.log

  
  chown -R ${USER} ${HOME}/${MOUNT_DIR}/
  chmod 777 ${HOME}/${MOUNT_DIR}/

  chown -R ${USER} ${HOME}/${MOUNT_DIR}/logs
  chmod 777 ${HOME}/${MOUNT_DIR}/
  chown -R ${USER} ${HOME}/${MOUNT_DIR}/keys
  chmod 777 ${HOME}/${MOUNT_DIR}/
  chown -R ${USER} ${HOME}/${MOUNT_DIR}/data
  chmod 777 ${HOME}/${MOUNT_DIR}/data

  python3 manage.py collectstatic
  mkdir -p ${USER} ${HOME}/static/CACHE
  chown -R ${USER} ${HOME}/static/CACHE
  chown -R ${USER} ${HOME}/static
  chmod 777 ${HOME}/static/CACHE
  chmod 777 ${HOME}/static
  echo "Running supervisord ..."
  exec supervisord --nodaemon -c ${HOME}/supervisord.conf
else
  exec "$@"
fi
