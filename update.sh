#!/bin/bash -x

if ! test -w /var/run/docker.sock; then
  SUDO=sudo
else
  SUDO=
fi
$SUDO docker run -it -v $PWD:/srv -w /srv $(sed -n -e 's/FROM //p' Dockerfile) sh -c "
set -e
apk add --no-cache libffi libpq postfix python3 s6 gcc libffi-dev make musl-dev postgresql-dev python3-dev;
pip3 install --upgrade pip
pip install pipenv
pipenv lock
"
