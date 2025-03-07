# GCP service account
#resource "kubernetes_manifest" "gcp_service_account" {
#  manifest = {
#    apiVersion = "v1"
#    kind       = "ServiceAccount"
#
#    metadata = {
#      name      = "vertex"
#      namespace = kubernetes_namespace.namespace.metadata[0].name
#      annotations = {
#        "iam.gke.io/gcp-service-account" = "sa-google-vertexai@dit-cscn-perfonar-001.iam.gserviceaccount.com"
#      }
#    }
#  }
#}

resource "kubectl_manifest" "gcp_service_account" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "ServiceAccount"

    metadata = {
      name      = "vertex"
      namespace = kubernetes_namespace.namespace.metadata[0].name
      annotations = {
        "iam.gke.io/gcp-service-account" = "sa-google-vertexai@dit-cscn-perfonar-001.iam.gserviceaccount.com"
      }
    }
  })
}
