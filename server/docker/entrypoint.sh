#!/usr/bin/env bash
set -e

if [ "$1" = 'gist-poller' ]; then
    src/manage.py gist-poller
elif [ "$1" = 'startapp' ]; then
    # src/manage.py runserver
    cd src && \
        ./manage.py collectstatic --no-input && \
        ./manage.py makemigrations && \
        ./manage.py migrate && \
        gunicorn app.wsgi:application --bind 0.0.0.0:$PORT --workers 2
else
    exec "$@"
fi