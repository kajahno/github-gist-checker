FROM python:3.6-slim

RUN apt-get update && \
    apt-get install -y pipenv

COPY ./docker/entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh

COPY . /app
WORKDIR /app

RUN pipenv install --deploy --system --ignore-pipfile

ENTRYPOINT ["entrypoint.sh"]
CMD ["startapp"]
