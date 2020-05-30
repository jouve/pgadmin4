FROM alpine:3.12.0

COPY pipenv.txt /

RUN set -e; \
    apk add --no-cache python3; \
    python3 -m venv /tmp/pipenv; \
    /tmp/pipenv/bin/pip install -r /pipenv.txt

COPY Pipfile Pipfile.lock /srv/

WORKDIR /srv

RUN /tmp/pipenv/bin/pipenv lock -r > /requirements.txt

FROM alpine:3.12.0

COPY --from=0 /requirements.txt /usr/share/pgadmin4/requirements.txt

RUN set -e; \
    apk add --no-cache libffi libpq postfix python3 s6 \
                       gcc libffi-dev make musl-dev patch postgresql-dev python3-dev; \
    python3 -m venv /usr/share/pgadmin4; \
    /usr/share/pgadmin4/bin/pip install --no-cache-dir -r /usr/share/pgadmin4/requirements.txt; \
    echo -e '--- a\n+++ b\n@@ -158,7 +158,7 @@\n 		 1) exec $daemon_directory/master -i\n 		    $FATAL "cannot start-fg the master daemon"\n 		    exit 1;;\n-		 *) $daemon_directory/master -s;;\n+		 *) exec $daemon_directory/master -s;;\n 		esac\n 		;;\n 	     *) $FATAL "start-fg does not support multi_instance_directories"' | \
    patch /usr/libexec/postfix/postfix-script; \
    find /usr/share/pgadmin4/lib/python3.8/site-packages/pgadmin4/docs/en_US -mindepth 1 -maxdepth 1 ! -name _build | xargs rm -rf; \
    find -name __pycache__ | xargs rm -rf; \
    rm -rf /root/.cache /root/.local /tmp/pipenv; \
    apk del --no-cache gcc libffi-dev make musl-dev postgresql-dev python3-dev;

COPY service /service
COPY entrypoint.sh /usr/bin

EXPOSE 80
VOLUME /var/lib/pgadmin

CMD ["entrypoint.sh"]
