#!/usr/bin/env bash
set -e

if [ "$1" = 'gist-poller' ]; then
    exec src/manage.py gist-poller
else
    exec "$@"
fi