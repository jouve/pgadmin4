#!/bin/bash -x

if [ "$(basename "$(readlink -f "$(which docker)")")" != podman ]; then
  if ! test -w /var/run/docker.sock; then
    SUDO=sudo
  else
    SUDO=
  fi
fi

if docker container inspect cache-cache-1 &>/dev/null; then
  cache=--volumes-from=cache-cache-1
else
  cache=
fi

$SUDO docker run \
  $cache \
  --volume $PWD:/srv \
  --workdir /srv \
  $(sed -n -e '/FROM /{s/FROM //; p; q }' Dockerfile | head -n1) sh -x -c 'poetry lock'
