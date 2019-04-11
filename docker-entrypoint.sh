#!/bin/bash
set -e
echo "Entrypoint: ${1}"
if [ "$1" = "supervisord" ]; then

  # Mandatory runtime env vars
  : ${HOME:?"Must be defined. See README.md"}

  echo "Configuring ..."
  #chown root:${USER} /dev/pts/0
  #chown root:${USER} /dev/null
  mkdir -p \
    ${HOME}/share \
    ${HOME}/media \
    ${HOME}/logs \
    ${HOME}/${MOUNT_DIR}/data \
    ${HOME}/${MOUNT_DIR}/keys
  chown -R ${USER} ${HOME}/logs
  touch ${HOME}/${MOUNT_DIR}/__init__.py
  python3 manage.py collectstatic

  echo "Running supervisord with ${USER} user ..."
  exec supervisord --nodaemon -c ${HOME}/supervisord.conf
else
  exec "$@"
fi
