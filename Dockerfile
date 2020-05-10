FROM alpine:3.11.6

COPY Pipfile Pipfile.lock /

RUN set -e; \
    apk add --no-cache python3; \
    python3 -m venv /tmp/pipenv; \
    /tmp/pipenv/bin/pip install appdirs==1.4.3 certifi==2019.11.28 distlib==0.3.0 filelock==3.0.12 pipenv==2018.11.26 six==1.14.0 virtualenv==20.0.8 virtualenv-clone==0.5.3; \
    /tmp/pipenv/bin/pipenv lock -r > requirements.txt

FROM alpine:3.11.6

COPY --from=0 /requirements.txt /

RUN set -e; \
    apk add --no-cache libffi libpq postfix python3 s6 \
                       gcc libffi-dev make musl-dev postgresql-dev python3-dev; \
    pip3 install --no-cache-dir -r requirements.txt; \
    find /usr/lib/python3.8/site-packages/pgadmin4/docs/en_US -mindepth 1 -maxdepth 1 ! -name _build | xargs rm -rf; \
    find -name __pycache__ | xargs rm -rf; \
    rm -rf /root/.cache /root/.local /tmp/pipenv; \
    apk del --no-cache gcc libffi-dev make musl-dev postgresql-dev python3-dev

COPY service /service
COPY entrypoint.sh /usr/bin

RUN cd usr/libexec/postfix; \
    echo -e \
'--- a/postfix-script\n'\
'+++ b/postfix-script\n'\
'@@ -158,7 +158,7 @@\n'\
' 		 1) exec $daemon_directory/master -i\n'\
' 		    $FATAL "cannot start-fg the master daemon"\n'\
' 		    exit 1;;\n'\
'-		 *) $daemon_directory/master -s;;\n'\
'+		 *) exec $daemon_directory/master -s;;\n'\
' 		esac\n'\
' 		;;\n'\
' 	     *) $FATAL "start-fg does not support multi_instance_directories"' | \
    patch -p1

EXPOSE 80
VOLUME /var/lib/pgadmin

CMD ["entrypoint.sh"]
