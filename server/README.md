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

### Run local development server
* Run:
  ```
  $ make run
  ```

### Run ad-hoc command to update the list of gists
* Run:
  ```
  $ make
  ```

## Docker

### Build image

Run:
  ```
  $ make buildimage
  ```

### Run image and map to port 8000

Run:
  ```
  $ make runimage
  ```
