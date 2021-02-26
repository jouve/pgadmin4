#!/bin/bash -x

if ! test -w /var/run/docker.sock; then
  SUDO=sudo
else
  SUDO=
fi

if docker container inspect cache_cache_1 &>/dev/null; then
  cache=--volumes-from=cache_cache_1
else
  cache=
fi

$SUDO docker run \
  $cache \
  --volume $PWD:/srv \
  --workdir /srv \
  $(head -n1 Dockerfile | sed -n -e 's/FROM //p') sh -x -c "
set -e
apk add --no-cache alpine-conf
setup-apkcache /var/cache/apk
apk add --no-cache cargo gcc libffi-dev musl-dev openssl-dev python3-dev;
python3 -m venv /usr/share/poetry
/usr/share/poetry/bin/pip install --upgrade pip
/usr/share/poetry/bin/pip install wheel
/usr/share/poetry/bin/pip install poetry
/usr/share/poetry/bin/pip freeze --all > poetry.txt
/usr/share/poetry/bin/poetry lock
apk add --no-cache libffi libpq postfix python3 s6 \
                   gcc g++ krb5-dev libffi-dev make musl-dev patch postgresql-dev python3-dev;
/usr/share/poetry/bin/poetry install
"
