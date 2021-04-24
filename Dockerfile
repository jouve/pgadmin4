FROM jouve/poetry:1.1.6-alpine3.13.5

COPY pyproject.toml poetry.lock /srv/

WORKDIR /srv

RUN poetry export --without-hashes > /requirements.txt

FROM alpine:3.13.5

COPY --from=0 /requirements.txt /usr/share/pgadmin4/requirements.txt

RUN set -e; \
    apk add --no-cache --virtual .build-deps \
        cargo \
        gcc \
        libffi-dev \
        make \
        musl-dev \
        openssl-dev \
        postgresql-dev \
        python3-dev \
        s6 \
        ssmtp \
    ; \
    python3 -m venv /usr/share/pgadmin4; \
    /usr/share/pgadmin4/bin/pip install -r /usr/share/pgadmin4/requirements.txt; \
    find /usr/share/pgadmin4/lib/python3.8/site-packages/pgadmin4/docs/en_US -mindepth 1 -maxdepth 1 ! -name _build | xargs rm -rf; \
    apk add --no-network --virtual .run-deps $( \
        scanelf --needed --nobanner --format '%n#p' --recursive /usr/share/poetry \
        | tr ',' '\n' \
        | sed 's/^/so:/' \
        | sort -u \
    ); \
    apk del --no-cache --no-network .build-deps; \
    rm -rf /root/.cache /root/.cargo

COPY entrypoint.sh /usr/bin

EXPOSE 80
EXPOSE 443
VOLUME /var/lib/pgadmin

CMD ["entrypoint.sh"]
