FROM alpine:3.13.2

COPY poetry.txt /

RUN set -e; \
    apk add --no-cache python3; \
    python3 -m venv /usr/share/poetry; \
    /usr/share/poetry/bin/pip install --index-url http://192.168.0.28:3141/cyril/dev --trusted-host 192.168.0.28 -r /poetry.txt

COPY pyproject.toml poetry.lock /srv/

WORKDIR /srv

RUN /usr/share/poetry/bin/poetry export > /requirements.txt

FROM alpine:3.13.2

COPY --from=0 /requirements.txt /usr/share/pgadmin4/requirements.txt

RUN set -e; \
    apk add --no-cache libpq libstdc++ python3 s6 ssmtp; \
    python3 -m venv /usr/share/pgadmin4
RUN set -e; \
    /usr/share/pgadmin4/bin/pip install --index-url http://192.168.0.28:3141/cyril/dev --trusted-host 192.168.0.28 --no-cache-dir -r /usr/share/pgadmin4/requirements.txt; \
    find /usr/share/pgadmin4/lib/python3.8/site-packages/pgadmin4/docs/en_US -mindepth 1 -maxdepth 1 ! -name _build | xargs rm -rf; \
    find -name __pycache__ | xargs rm -rf

COPY entrypoint.sh /usr/bin

EXPOSE 80
EXPOSE 443
VOLUME /var/lib/pgadmin

CMD ["entrypoint.sh"]
