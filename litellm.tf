locals {
  litellm_params = {
    "db.database"                                                    = var.litellm_db_database
    "db.deployStandalone"                                            = false
    "db.endpoint"                                                    = "litellm-pg-db-rw:5432"
    "db.secret.name"                                                 = var.litellm_db_secret_name_suffix
    "db.secret.passwordKey"                                          = "password"
    "db.secret.usernameKey"                                          = "username"
    "db.useExisting"                                                 = true
    "image.tag"                                                      = var.litellm_image_tag
    "proxy_config.general_settings.allow_requests_on_db_unavailable" = var.litellm_proxy_allow_requests_on_db_unavailable
    "proxy_config.general_settings.database_connection_pool_limit"   = var.litellm_proxy_db_connection_pool_limit
    "proxy_config.general_settings.disable_spend_logs"               = var.litellm_proxy_disable_spend_logs
    "proxy_config.general_settings.disable_error_logs"               = var.litellm_proxy_disable_error_logs
    "proxy_config.general_settings.master_key"                       = "os.environ/LITELLM_PROXY_MASTER_KEY"
    "proxy_config.general_settings.proxy_batch_write_at"             = var.litellm_proxy_batch_write_at
    "proxy_config.general_settings.store_model_in_db"                = var.litellm_proxy_store_model_in_db
    "proxy_config.litellm_settings.json_logs"                        = var.litellm_proxy_json_logs
    "proxy_config.litellm_settings.request_timeout"                  = var.litellm_proxy_request_timeout
    "proxy_config.litellm_settings.set_verbose"                      = var.litellm_proxy_set_verbose
  }
}

resource "kubectl_manifest" "litellm_db_deployment" {
  yaml_body = yamlencode({
    apiVersion = "postgresql.cnpg.io/v1"
    kind       = "Cluster"
    metadata = {
      name      = "litellm-pg-db"
      namespace = kubernetes_namespace.namespace.metadata[0].name
      labels = {
        postgresql = "litellm-pg-db"
      }
    }
    spec = {
      bootstrap = {
        initdb = {
          database = "litellm"
          owner    = "llmproxy"
          secret = {
            name = "litellm-secret"
          }
        }
      }
      instances = 3
      storage = {
        size = "10Gi"
      }
      enablePDB = contains(["dev", "staging"], var.environment) ? false : true
    }
  })

  depends_on = [
    #helm_release.cnpg,
    onepassword_item.namespace_secrets_separate
  ]
}

resource "kubectl_manifest" "litellm_config_map" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "ConfigMap"
    metadata = {
      name      = "litellm-env-configmap"
      namespace = kubernetes_namespace.namespace.metadata[0].name
    }
    data = var.litellm_env_config_map
  })

  depends_on = [kubectl_manifest.litellm_db_deployment]
}

resource "helm_release" "litellm" {
  name      = "litellm"
  namespace = kubernetes_namespace.namespace.metadata[0].name
  timeout   = 300

  repository = "oci://ghcr.io/berriai"
  chart      = "litellm-helm"
  version    = var.lightllm_helm_chart_version

  values = [yamlencode({
    environmentConfigMaps = var.litellm_environment_config_maps
    #environmentSecrets    = ["${var.namespace}-secrets"]
    environmentSecrets = [
      "litellm-master-key",
      "litellm-proxy-master-key"
    ]
    replicaCount = 2
  })]

  dynamic "set" {
    for_each = local.litellm_params
    content {
      name  = set.key
      value = set.value
    }
  }

  depends_on = [
    kubectl_manifest.litellm_config_map,
    kubectl_manifest.litellm_db_deployment,
    kubectl_manifest.secrets_mapping_onepassword_namespace_shared
  ]
}

resource "null_resource" "litellm_sleep_for_release_ready" {
  triggers = {
    last_deployment = helm_release.litellm.metadata[0].last_deployed
  }
  provisioner "local-exec" {
    command = "sleep 30"
  }

  depends_on = [helm_release.litellm]
}
