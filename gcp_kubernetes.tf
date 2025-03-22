locals {
  kubernetes_cluster_name = "${var.kubernetes_cluster_prefix}-${var.environment}"
  kube_config_path = "~/.kube/config_${var.kubernetes_cluster_prefix}-${var.environment}"
}

resource "kubernetes_namespace" "namespace" {
  metadata {
    name = local.namespace
  }
  timeouts {
    delete = "15m"
  }
}
