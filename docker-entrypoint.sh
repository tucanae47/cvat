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
  chmod 777 ${HOME}/static/CACHE
  echo "Running supervisord ..."
  exec supervisord --nodaemon -c ${HOME}/supervisord.conf
else
  exec "$@"
fi
