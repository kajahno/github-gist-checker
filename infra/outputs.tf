output "gcr_location" {
  value = "${data.google_container_registry_image.app.image_url}"
}

output "app_status" {
  value = "${google_cloud_run_service.app.status}"
}
