locals {
  app_db_name  = "gistchecker"
  service_apis = ["cloudbuild.googleapis.com", "sqladmin.googleapis.com", "run.googleapis.com"]
}

provider "google-beta" {
  project = "${var.project_id}"
  region  = "${var.region}"
}

resource "google_project_service" "services" {
  count                      = "${length(local.service_apis)}"
  project                    = "${var.project_id}"
  service                    = "${element(local.service_apis, count.index)}"
  disable_dependent_services = true
}

resource "random_id" "db_name_suffix" {
  byte_length = 4
}

resource "google_sql_database_instance" "postgres" {
  name             = "postgres-instance-${random_id.db_name_suffix.hex}"
  database_version = "POSTGRES_9_6"
  provider         = "google-beta"

  settings {
    tier      = "db-f1-micro"
    disk_type = "PD_HDD"

    ip_configuration {
      ipv4_enabled = true

      authorized_networks {
        name  = "public"
        value = "0.0.0.0/0"
      }
    }
  }
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "google_sql_user" "users" {
  name     = "gistcheckersqluser"
  project  = "${var.project_id}"
  instance = "${google_sql_database_instance.postgres.name}"
  password = "${random_password.password.result}"
}

resource "google_sql_database" "database" {
  name     = "${local.app_db_name}"
  instance = "${google_sql_database_instance.postgres.name}"
  project  = "${var.project_id}"
}

data "google_container_registry_image" "app" {
  name    = "gistchecker:${var.app_version}"
  project = "${var.project_id}"
}

locals {
  env_vars = {
    GIST_APP_DB_NAME = "${local.app_db_name}"
    GIST_APP_DB_USER = "${google_sql_user.users.name}"
    GIST_APP_DB_PASSWD = "${google_sql_user.users.password}"
    GIST_APP_DB_HOST = "${google_sql_database_instance.postgres.public_ip_address}"
    GIST_APP_DB_PORT = "5432"
  }
}

resource "google_cloud_run_service" "app" {
  name     = "gistchecker"
  location = "${var.region}"
  provider = "google-beta"

  metadata {
    namespace = "${var.project_id}"
  }

  spec {
    containers {
      image = "${data.google_container_registry_image.app.image_url}"

      dynamic "env" {
        for_each = local.env_vars
        content {
          name        = env.key
          value       = env.value
        }
      }

    }
  }
}

locals {
  startup_script = <<EOT
#!/usr/bin/env bash

while true; do
    docker run --rm -e GIST_APP_DB_NAME=${local.app_db_name} -e GIST_APP_DB_USER=${google_sql_user.users.name} -e GIST_APP_DB_PASSWD=${google_sql_user.users.password} -e GIST_APP_DB_HOST=${google_sql_database_instance.postgres.public_ip_address} -e GIST_APP_DB_PORT=5432  ${data.google_container_registry_image.app.image_url} gist-poller
    sleep_time_hours=3
    sleep_time_in_secs=$((sleep_time_hours*60*60))
    echo "sleeping for $sleep_time_in_secs seconds"
    sleep $sleep_time_in_secs
done
EOT
}

resource "google_compute_instance" "default" {
  name         = "gist-poller"
  machine_type = "f1-micro"
  zone         = "${var.region}-b"
  provider     = "google-beta"

  tags = ["appname", "gist-checker"]

  labels = {
    container-vm = "cos-stable-77-12371-89-0"
  }

  boot_disk {
    initialize_params {
      type  = "pd-standard"
      image = "cos-cloud/cos-stable-77-12371-89-0"
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }

  metadata = {
    google-logging-enabled    = "true"
    gce-container-declaration = "spec:\n  containers:\n    - name: gist-poller\n      image: '${data.google_container_registry_image.app.image_url}'\n      stdin: false\n      tty: false\n  restartPolicy: Always\n"
  }

  metadata_startup_script = "echo '${local.startup_script}' > /var/container-runner.bash"

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }
}
