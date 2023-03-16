output "cloud_functions" {
  value = {
    for key, value in local.cloud_functions : key =>
    merge(
      local.cloud_functions[key].outputs,
      {
        source_archive_bucket = google_storage_bucket.functions_bucket.name
        source_archive_object = google_storage_bucket_object.gke_slack_function_objects[key].name
      }
    )
  }

  description = "The bucket where functions are stored."
  sensitive   = true
}

