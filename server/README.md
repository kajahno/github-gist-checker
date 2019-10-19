# Github gist checker

This project aims to track a set of users' gists and display them

## Setup

### Prerequisites

* python3
* pipenv
> Note: I have used Linux Ubuntu to develop this project. However, you are welcome to try on a different OS

### Installing dependencies

* Create/enter virtual env shell (through pipenv):
  ```
  $ pipenv shell
  ```
* Install dependencies
  ```
  (github-gist-checker) $ pipenv install --dev
  ```

## Development

### Run database for local development
* Run:
  ```
  $ make startdb
  ```

### Run local development server
* Run:
  ```
  (github-gist-checker) $ src/manage.py runserver
  ```
> Note: the app will be listening on http://localhost:8000

### Run ad-hoc command to update the list of gists
* Run:
  ```
  (github-gist-checker) $ src/manage.py gist-poller
  ```

## Docker

### Build image

Builds the docker image:
  ```
  $ make build
  ```

### Run image and map to port 8000

This will start a local database, apply the migrations, and start the app

Run:
  ```
  $ make run
  ```

### Tag image

Run:
  ```
  $ make tag 0.1.0 latest ...
  ```
> Note: the image must be running before hand (run `$ make run`)

### Login to dockerhub

Run:
  ```
  $ make login
  ```

### Logout from dockerhub

Run:
  ```
  $ make logout
  ```

### Publish image

Login:
  ```
  [nix-shell] $ gcloud auth configure-docker
  ```
  > Note: see [here](../infra/README.md#Prerequisites) how to get gcloud easily
Run:
  ```
  $ make publish
  ```
> **Note**: this is configured to push the image to a Google Container registry, but it's quite easy to change to another one (such as Dockerhub).
