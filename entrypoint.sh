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
    python3 /usr/lib/python3.8/site-packages/pgadmin4/setup.py

    export PGADMIN_SERVER_JSON_FILE=${PGADMIN_SERVER_JSON_FILE:-/pgadmin4/servers.json}
    # Pre-load any required servers
    if [ -f "${PGADMIN_SERVER_JSON_FILE}" ]; then
        # When running in Desktop mode, no user is created
        # so we have to import servers anonymously
        if [ "${PGADMIN_CONFIG_SERVER_MODE}" = "False" ]; then
            python3 /usr/lib/python3.8/site-packages/pgadmin4/setup.py --load-servers "${PGADMIN_SERVER_JSON_FILE}"
        else
            python3 /usr/lib/python3.8/site-packages/pgadmin4/setup.py --load-servers "${PGADMIN_SERVER_JSON_FILE}" --user ${PGADMIN_DEFAULT_EMAIL}
        fi
    fi
fi

exec s6-svscan /service
