#!/bin/bash
set -e
echo "Entrypoint: ${1}"
if [ "$1" = "supervisord" ]; then

  # Mandatory runtime env vars
  : ${HOME:?"Must be defined. See README.md"}

  echo "Configuring ..."
  mkdir -p \
    ${HOME}/share \
    ${HOME}/media \
    ${HOME}/logs \
    ${HOME}/${MOUNT_DIR}/data \
    ${HOME}/${MOUNT_DIR}/keys\
  touch ${HOME}/${MOUNT_DIR}/__init__.py
  python3 manage.py collectstatic

  echo "Running supervisord with ${USER} user ..."
  exec supervisord --nodaemon -c ${HOME}/supervisord.conf
else
  exec "$@"
fi