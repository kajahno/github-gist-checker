# Infrastructure setup gist-checker

This project relies on the following techs to perform the setup:

- Google Cloud Engine
- Terraform
- Nix

## Prerequisites

- [Nixpkgs](https://nixos.org/nix/): nice way to handle packages and dependencies
- Linux (or related)
- Some configuration in the Google Cloud dashboard (covered below)

## Install dependencies

Let nix download and install everything for you (gcloud and Terraform 12):

```
$ nix-shell
```

## Configure the project in Google Cloud

Note: in this case I'm using a personal account, hence why I'm creating a project and the service account under that. If you're using a Gsuite account (business) then you can create an organisation, and a service account that can create projects.

- create a project: follow the [docs](https://cloud.google.com/resource-manager/docs/creating-managing-projects)
- make sure there's a billing account linked to the project
- create a service account and give ownership of the project: [docs here](https://cloud.google.com/iam/docs/creating-managing-service-accounts)
- Download the credentials for the service account and put into a file called `credentials.json`
- Create a storage bucket for Terraform state: this is a good practice when using Terraform (prevents several people of editing the same infrastructure through Terraform). Normally this bucket should be common for all projects, but since this is a small project there's little effort managing it.
- Make sure there is a version of the app [pushed to the Google container](../server/README.md#Publish-image) registry of the project

## Create the infrastructure using Terraform

- First initialize it (this will create a remote state file)
  ```
  [nix-shell]$ terraform init
  ```
  > Note: you might get a couple of errors related to authenticating against gcloud, just follow the messages.
- Perform a dry-run of the configuration
  ```
  [nix-shell]$ terraform plan --var-file=vars.tfvars
  ```
- Create the infrastructure
  ```
  [nix-shell]$ terraform apply --var-file=vars.tfvars
  ```
  > Note: I've seen Terraform fails often when activating gcloud APIs. If this is the case just try again.

## Make the service to be publicly accessible

- Go to the Cloud Run service page
- Select service
- Add a new member: set 'allUsers' name and 'Cloud Run > Cloud Run Invoker' as role
- Now the URL should be accesible

## Start the git-poller service

For simplicity there was used a Google Cloud container optimised image:

- An image that has Docker already installed
- An image in which you can pass a container image to it, ready to be ran

To start the service follow these:

- Go to Google Compute and ssh into the machine
- Inside there's a script in `/var/` called `container-runner.bash`. That script runs a container using the available image
  - Normally you'd want to run this script like this: `nohup bash -c container-runner.bash &`
    > Note: because that image doesnt have cron (and I couldnt find a way to install it), the script is wrapped in a while loop (waiting to be nohupped).

## Destroy infrastructure

```
[nix-shell]$ terraform destroy --var-file=vars.tfvars
```
