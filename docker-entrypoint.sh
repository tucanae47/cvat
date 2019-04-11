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
    ${HOME}/${MOUNT_DIR}/data \
    ${HOME}/${MOUNT_DIR}/keys
  touch ${HOME}/${MOUNT_DIR}/__init__.py
  chown -R ${USER} ${HOME}/logs
  chmod 777 ${HOME}/logs
  python3 manage.py collectstatic

  echo "Running supervisord ..."
  exec supervisord --nodaemon -c ${HOME}/supervisord.conf
else
  exec "$@"
fi
