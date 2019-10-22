locals {
  app_db_name  = "gistchecker"
  service_apis = ["cloudbuild.googleapis.com", "sqladmin.googleapis.com", "run.googleapis.com", "cloudfunctions.googleapis.com", "cloudscheduler.googleapis.com", "appengine.googleapis.com"]
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
  systemd_service = <<EOT
[Unit]
Description=Start gist-poller app container
Requires=network.target
After=network.target

[Service]
ExecStart=/usr/bin/docker run --rm --name=app -e GIST_APP_DB_NAME=${local.app_db_name} -e GIST_APP_DB_USER=${google_sql_user.users.name} -e GIST_APP_DB_PASSWD=${google_sql_user.users.password} -e GIST_APP_DB_HOST=${google_sql_database_instance.postgres.public_ip_address} -e GIST_APP_DB_PORT=5432  ${data.google_container_registry_image.app.image_url} gist-poller
ExecStop=/usr/bin/docker stop app
ExecStopPost=/usr/bin/docker rm app
Restart=no

[Install]
WantedBy=multi-user.target
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

  metadata_startup_script = "echo '${local.systemd_service}' > /etc/systemd/system/cloudservice.service && systemctl daemon-reload && systemctl enable cloudservice && systemctl start cloudservice"

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }
}

resource "google_storage_bucket" "main" {
  name    = "bkt-${var.project_id}-gist-poller"
  project = "${var.project_id}"

  # depends_on = ["google_project_service.*.service[3]"]
}

resource "null_resource" "local_gcp_func" {

  triggers = {
    build_number = "${timestamp()}"
  }

  provisioner "local-exec" {
    command     = "zip -r ../cloud_func.zip index.js package.json"
    working_dir = "./app-function"
  }
}

resource "google_storage_bucket_object" "main" {
  name   = "index.zip"
  bucket = "${google_storage_bucket.main.name}"
  source = "./cloud_func.zip"

  depends_on = ["null_resource.local_gcp_func"]
}

resource "random_string" "user_token" {
  length  = 50
  upper   = true
  lower   = true
  number  = true
  special = false
}

resource "google_cloudfunctions_function" "startvm" {
  name                  = "${var.project_name}-startvm"
  description           = "Starts VM in project ${var.project_name}"
  runtime               = "nodejs10"
  project               = "${var.project_id}"
  available_memory_mb   = 128
  source_archive_bucket = "${google_storage_bucket.main.name}"
  source_archive_object = "${google_storage_bucket_object.main.name}"
  trigger_http          = true
  timeout               = 60
  entry_point           = "start_vm"
  region                = "${var.region}"                               #cloud functions are only supported in this region

  environment_variables = {
    GCP_PROJECT_NAME = "${var.project_name}"
    USER_TOKEN       = "${random_string.user_token.result}"
  }

  depends_on         = ["google_storage_bucket_object.main"]
  # depends_on = ["google_project_service.function"]
}

resource "google_cloudfunctions_function" "stopvm" {
  name                  = "${var.project_name}-stopvm"
  description           = "Stops VM in project ${var.project_name}"
  runtime               = "nodejs10"
  project               = "${var.project_id}"
  available_memory_mb   = 128
  source_archive_bucket = "${google_storage_bucket.main.name}"
  source_archive_object = "${google_storage_bucket_object.main.name}"
  trigger_http          = true
  timeout               = 60
  entry_point           = "stop_vm"
  region                = "${var.region}"                               #cloud functions are only supported in this region

  environment_variables = {
    GCP_PROJECT_NAME = "${var.project_name}"
    USER_TOKEN       = "${random_string.user_token.result}"
  }

  depends_on         = ["google_storage_bucket_object.main"]
  # depends_on = ["google_project_service.function"]
}

resource "local_file" "startvm_script" {
  filename = "startvm.bash"

  content = <<__EOF__
#!/usr/bin/env bash
echo "Starting VM in the project '${var.project_name}'"
curl -i --header "Content-Type: application/json" --request POST '${google_cloudfunctions_function.startvm.https_trigger_url}' --data '{ "userToken":"${random_string.user_token.result}" }'
__EOF__
}

resource "local_file" "stopvm_script" {
  filename = "stopvm.bash"

  content = <<__EOF__
#!/usr/bin/env bash
echo "Stopping VM in the project '${var.project_name}'"
curl -i --header "Content-Type: application/json" --request POST '${google_cloudfunctions_function.stopvm.https_trigger_url}' --data '{ "userToken":"${random_string.user_token.result}" }'
__EOF__
}

resource "google_app_engine_application" "dummy_app" {
  # Without this the scheduler doesn't work
  project     = "${var.project_id}"
  location_id = "${var.region}"
}

resource "google_cloud_scheduler_job" "autostarter" {
  name                  = "vm-autostarter"
  description           = "starts the virtual machine every 3 hours"
  project               = "${var.project_id}"
  region                = "${var.region}"
  schedule              = "* */3 * * *"
  time_zone             = "Europe/London"

  http_target {
    http_method = "POST"
    uri = "${google_cloudfunctions_function.startvm.https_trigger_url}"
    body = "${base64encode("{ \"userToken\": \"${random_string.user_token.result}\" }")}"
    headers = {
      "Content-Type" = "application/json"
    }
  }

  depends_on = ["google_app_engine_application.dummy_app"]
}

resource "google_cloud_scheduler_job" "autostopper" {
  name                  = "vm-autostopper"
  description           = "stops the virtual machine every 10th minute"
  project               = "${var.project_id}"
  region                = "${var.region}"
  schedule              = "*/10 * * * *"
  time_zone             = "Europe/London"

  http_target {
    http_method = "POST"
    uri = "${google_cloudfunctions_function.stopvm.https_trigger_url}"
    body = "${base64encode("{ \"userToken\": \"${random_string.user_token.result}\" }")}"
    headers = {
      "Content-Type" = "application/json"
    }
  }

  depends_on = ["google_app_engine_application.dummy_app"]
}
