FROM jouve/poetry:1.1.12-alpine3.15.0

COPY pyproject.toml poetry.lock /srv/

WORKDIR /srv

RUN poetry export --without-hashes > /requirements.txt

FROM alpine:3.15.0

COPY --from=0 /requirements.txt /usr/share/pgadmin4/requirements.txt

RUN set -e; \
    apk add --no-cache --virtual .build-deps \
        gcc \
        g++ \
        libffi-dev \
        jpeg-dev \
        make \
        musl-dev \
        postgresql-dev \
        python3-dev \
        zlib-dev \
    ; \
    python3 -m venv /usr/share/pgadmin4; \
    /usr/share/pgadmin4/bin/pip install --no-cache pip==21.3.1 setuptools==60.3.1 wheel==0.37.1; \
    /usr/share/pgadmin4/bin/pip install --no-cache -r /usr/share/pgadmin4/requirements.txt; \
    find /usr/share/pgadmin4/lib/python3.9/site-packages/pgadmin4/docs/en_US -mindepth 1 -maxdepth 1 ! -name _build | xargs rm -rf; \
    apk add --no-cache --virtual .run-deps postgresql-client python3 ssmtp $( \
        find /usr/share/pgadmin4 -name '*.so' \
        | while read -r so; do ldd $so 2>/dev/null ; done \
        | sed -n -e 's/\t\([^ ]\+\) => \(\/usr\)\?\/lib\/.*/so:\1/p' \
        | sort -u \
    ); \
    apk del --no-cache .build-deps;

COPY entrypoint.sh /usr/bin

EXPOSE 80
EXPOSE 443
VOLUME /var/lib/pgadmin

CMD ["entrypoint.sh"]
