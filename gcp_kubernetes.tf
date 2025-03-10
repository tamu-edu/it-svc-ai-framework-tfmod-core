locals {
  kubernetes_cluster_name = "${var.kubernetes_cluster_prefix}-${var.environment}"
  kube_config_path = "~/.kube/config_${var.kubernetes_cluster_prefix}-${var.environment}"
}

#resource "google_container_cluster" "autopilot_cluster" {
#  name     = "${var.kubernetes_cluster_prefix}-${var.environment}"
#  location = "us-central1"
#
#  # Enable Autopilot mode
#  enable_autopilot    = true
#  deletion_protection = false
#
#  # Specify the release channel
#  release_channel {
#    channel = "REGULAR"
#  }
#
#  network    = "default"
#  subnetwork = "default"
#
#  ip_allocation_policy {
#    cluster_ipv4_cidr_block  = "/16"
#    services_ipv4_cidr_block = "/22"
#  }
#
#  maintenance_policy {
#    recurring_window {
#      start_time = "2025-01-01T06:00:00Z"
#      end_time   = "2025-02-01T11:00:00Z"
#      recurrence = "FREQ=WEEKLY;BYDAY=SA,SU"
#    }
#  }
#}
#
#
## Use a local-exec provisioner to write kubeconfig to a file
#resource "null_resource" "write_kubeconfig" {
#  triggers = {
#    cluster_name = google_container_cluster.autopilot_cluster.name
#  }
#
#  provisioner "local-exec" {
#    #when    = create
#    command = <<-EOT
#          gcloud container clusters get-credentials ${google_container_cluster.autopilot_cluster.name} \
#          --region ${data.google_client_config.current.region} \
#          --project ${data.google_client_config.current.project}
#          EOT
#  }
#
#  provisioner "local-exec" {
#    when = destroy
#    #command = "kubectl config delete-context '${self.triggers.cluster_name}'"
#    command = "kubectl config delete-context $(cat ~/.kube/config | grep '\\- name:' | grep '${self.triggers.cluster_name}' | sed -e 's/- name: //g')"
#  }
#}
#
#resource "null_resource" "kubernetes_sleep_for_gke_ready" {
#  triggers = {
#    gke_id = google_container_cluster.autopilot_cluster.id
#  }
#  provisioner "local-exec" {
#    command = "sleep 30"
#  }
#
#  depends_on = [google_container_cluster.autopilot_cluster]
#}

resource "kubernetes_namespace" "namespace" {
  metadata {
    name = var.namespace
  }
  #depends_on = [
  #  null_resource.write_kubeconfig,
  #  null_resource.kubernetes_sleep_for_gke_ready
  #]
  timeouts {
    delete = "15m"
  }
}
