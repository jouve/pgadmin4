#!/bin/sh

if [ ! -f /var/lib/pgadmin/pgadmin4.db ]; then
    if [ -z "${PGADMIN_DEFAULT_EMAIL}" -o -z "${PGADMIN_DEFAULT_PASSWORD}" ]; then
        echo 'You need to specify PGADMIN_DEFAULT_EMAIL and PGADMIN_DEFAULT_PASSWORD environment variables'
        exit 1
    fi

    # Set the default username and password in a
    # backwards compatible way
    export PGADMIN_SETUP_EMAIL=${PGADMIN_DEFAULT_EMAIL}
    export PGADMIN_SETUP_PASSWORD=${PGADMIN_DEFAULT_PASSWORD}

    # Initialize DB before starting Gunicorn
    # Importing pgadmin4 (from this script) is enough
    /usr/share/pgadmin4/bin/python /usr/share/pgadmin4/lib/python3.8/site-packages/pgadmin4/setup.py

    export PGADMIN_SERVER_JSON_FILE=${PGADMIN_SERVER_JSON_FILE:-/pgadmin4/servers.json}
    # Pre-load any required servers
    if [ -f "${PGADMIN_SERVER_JSON_FILE}" ]; then
        # When running in Desktop mode, no user is created
        # so we have to import servers anonymously
        if [ "${PGADMIN_CONFIG_SERVER_MODE}" = "False" ]; then
            /usr/share/pgadmin4/bin/python /usr/share/pgadmin4/lib/python3.8/site-packages/pgadmin4/setup.py --load-servers "${PGADMIN_SERVER_JSON_FILE}"
        else
            /usr/share/pgadmin4/bin/python /usr/share/pgadmin4/lib/python3.8/site-packages/pgadmin4/setup.py --load-servers "${PGADMIN_SERVER_JSON_FILE}" --user ${PGADMIN_DEFAULT_EMAIL}
        fi
    fi
fi

# Get the session timeout from the pgAdmin config. We'll use this (in seconds)
# to define the Gunicorn worker timeout
TIMEOUT=$(/usr/share/pgadmin4/bin/python3 -c 'from pgadmin4 import config; print(config.SESSION_EXPIRATION_TIME * 60 * 60 * 24)')

# NOTE: currently pgadmin can run only with 1 worker due to sessions implementation
# Using --threads to have multi-threaded single-process worker

if [ -z ${PGADMIN_ENABLE_TLS} ]; then
    : ${PGADMIN_LISTEN_PORT:=80}
    PGADMIN_CERT_AND_KEY=
else
    : ${PGADMIN_LISTEN_PORT:=443}
    PGADMIN_CERT_AND_KEY="--keyfile /certs/server.key --certfile /certs/server.cert"
fi
exec /usr/share/pgadmin4/bin/gunicorn \
    --timeout ${TIMEOUT} \
    --bind ${PGADMIN_LISTEN_ADDRESS:-[::]}:${PGADMIN_LISTEN_PORT} ${PGADMIN_CERT_AND_KEY} -w 1 \
    --threads ${GUNICORN_THREADS:-25} \
    --access-logfile ${GUNICORN_ACCESS_LOGFILE:--} \
    $tls_args \
    pgadmin4.pgAdmin4:app
