#!/usr/bin/env python
"""Django's command-line utility for administrative tasks."""
import os
import sys


def main():
    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "app.settings")
    try:
        from django.core.management.commands.runserver import Command as runserver

        PORT = os.getenv("PORT", "8080")
        ADDR = os.getenv("ADDR", "0.0.0.0")
        runserver.default_port = PORT
        runserver.default_addr = ADDR
        from django.core.management import execute_from_command_line
        print("listening on {}:{}".format(ADDR, PORT))
    except ImportError as exc:
        raise ImportError(
            "Couldn't import Django. Are you sure it's installed and "
            "available on your PYTHONPATH environment variable? Did you "
            "forget to activate a virtual environment?"
        ) from exc
    execute_from_command_line(sys.argv)


if __name__ == "__main__":
    main()
