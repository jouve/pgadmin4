FROM alpine:3.12.1

COPY poetry.txt /

RUN set -e; \
    apk add --no-cache gcc libffi-dev musl-dev openssl-dev python3-dev; \
    python3 -m venv /usr/share/poetry; \
    /usr/share/poetry/bin/pip install -c /poetry.txt pip; \
    /usr/share/poetry/bin/pip install -c /poetry.txt wheel; \
    /usr/share/poetry/bin/pip install -c /poetry.txt poetry

COPY pyproject.toml poetry.lock /srv/

WORKDIR /srv

RUN /usr/share/poetry/bin/poetry export > /requirements.txt

FROM alpine:3.12.1

COPY --from=0 /requirements.txt /usr/share/pgadmin4/requirements.txt

RUN set -e; \
    apk add --no-cache libffi libpq python3 s6 ssmtp \
                       gcc libffi-dev make musl-dev patch postgresql-dev python3-dev; \
    python3 -m venv /usr/share/pgadmin4; \
    /usr/share/pgadmin4/bin/pip install --no-cache-dir -r /usr/share/pgadmin4/requirements.txt; \
    echo
RUN \
    find /usr/share/pgadmin4/lib/python3.8/site-packages/pgadmin4/docs/en_US -mindepth 1 -maxdepth 1 ! -name _build | xargs rm -rf; \
    find -name __pycache__ | xargs rm -rf; \
    rm -rf /root/.cache /root/.local /tmp/pipenv; \
    apk del --no-cache gcc libffi-dev make musl-dev postgresql-dev python3-dev;

COPY service /service
COPY entrypoint.sh /usr/bin

EXPOSE 80
VOLUME /var/lib/pgadmin

CMD ["entrypoint.sh"]
