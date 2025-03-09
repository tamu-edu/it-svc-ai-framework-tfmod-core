locals {
  openwebui_params = {
    extraEnvVars = [
      {
        name = "OPENAI_API_KEY"
        valueFrom = {
          secretKeyRef = {
            name = "litellm-proxy-master-key"
            key  = "LITELLM_PROXY_MASTER_KEY"
          }
        }
      },
      {
        name = "OPENAI_API_KEYS"
        valueFrom = {
          secretKeyRef = {
            name = "litellm-proxy-master-key"
            key  = "LITELLM_PROXY_MASTER_KEY"
          }
        }
        }, {
        name  = "FORCE_DEPLOY"
        value = "12"
      },
      {
        name  = "GLOBAL_LOG_LEVEL"
        value = "DEBUG"
      },
      {
        name  = "TASK_MODEL_EXTERNAL"
        value = "llama3.2"
      },
      {
        name  = "ENABLE_AUTOCOMPLETE_GENERATION"
        value = "false"
      },
      {
        name = "WEBUI_SECRET_KEY"
        valueFrom = {
          secretKeyRef = {
            name = "open-webui-secret"
            key  = "password"
          }
        }
      },
      {
        name  = "WEBUI_AUTH_TRUSTED_EMAIL_HEADER"
        value = "Cf-Access-Authenticated-User-Email"
      },
      {
        name  = "ENV"
        value = contains(["dev", "staging"], var.environment) ? "dev" : "prod"
      },
      {
        name  = "WEBUI_AUTH"
        value = "true"
      },
      {
        name  = "ENABLE_SIGNUP"
        value = "true"
      },
      {
        name  = "DEFAULT_USER_ROLE"
        value = "user"
      },
      {
        name  = "LITELLM_URL"
        value = "http://litellm:4000"
      },
      {
        name = "LITELLM_MASTER_KEY"
        valueFrom = {
          secretKeyRef = {
            name = "litellm-master-key"
            key  = "LITELLM_MASTER_KEY"
          }
        }
      },
      {
        name = "LITELLM_SALT_KEY"
        valueFrom = {
          secretKeyRef = {
            name = "litellm-salt-key"
            key  = "LITELLM_SALT_KEY"
          }
        }
      },
      {
        name  = "DATABASE_URL"
        value = "postgresql://${onepassword_item.namespace_secrets_separate["open-webui-secret"].username}:${onepassword_item.namespace_secrets_separate["open-webui-secret"].password}@open-webui-pg-db-rw:5432/open-webui"
      },
      {
        name  = "DEFAULT_MODELS"
        value = "gpt-4o"
      },
      {
        name  = "WEBUI_NAME"
        value = "TAMU"
      },
      {
        name  = "ENABLE_COMMUNITY_SHARING"
        value = "false"
      },
      {
        name  = "ENABLE_OLLAMA_API"
        value = "false"
      },
      {
        name  = "OLLAMA_BASE_URL"
        value = "http://ollama:7869"
      },
      {
        name  = "HOST"
        value = "0.0.0.0"
      },
      #{
      #  name  = "OPENAI_API_BASE_URL"
      #  value = "http://litellm:4000"
      #},
      #{
      #  name  = "OPENAI_API_BASE_URLS"
      #  value = "http://litellm:4000"
      #}
    ]
    extraResources = [
      {
        apiVersion = "policy/v1"
        kind       = "PodDisruptionBudget"
        metadata = {
          name = "open-webui"
          namespace = kubernetes_namespace.namespace.metadata[0].name
        }
        spec = {
          minAvailable = 2
          selector = {
            matchLabels = {
              "app.kubernetes.io/component" = "open-webui"
            }
          }
        }
      }
    ]
    image = {
      #pullPolicy = "IfNotPresent"
      pullPolicy = "Always"
      # repository = "ghcr.io/open-webui/open-webui"
      repository = split(":", docker_registry_image.openwebui_publish_container.name)[0]
      # tag        = var.openwebui_image_tag
      tag = split(":", docker_registry_image.openwebui_publish_container.name)[1]
    }
    imagePullSecrets = [
      {
        name = "ghcr-credentials"
      }
    ]
    ollama = {
      enabled = false
    }
    #ollamaUrls = [
    #  "http://ollama:7869"
    #]
    #openaiBaseApiUrl        = "http://litellm:4000"
    #openaiBaseApiUrls       = ["http://litellm:4000"]

    #openaiBaseApiUrl        = "http://open-webui-pipelines:9099"
    #openaiBaseApiUrls       = ["http://open-webui-pipelines:9099"]

    #"pipelines.extraEnvVars" = [
    persistence = {
      enabled = true
    }
    pipelines = {
      extraEnvVars = [
        {
          name  = "LITELLM_URL"
          value = "http://litellm:4000"
        },
        {
          name  = "LITELLM_BASE_URL"
          value = "http://litellm:4000"
        },
        {
          name = "LITELLM_API_KEY"
          valueFrom = {
            secretKeyRef = {
              #name = "litellm-master-key"
              name = "litellm-proxy-master-key"
              key  = "LITELLM_PROXY_MASTER_KEY"
            }
          }
        },
        {
          name  = "PIPELINES_URLS"
          value = "https://raw.githubusercontent.com/tamu-edu/it-ae-open-webui-pipelines/refs/heads/main/examples/pipelines/providers/litellm_manifold_pipeline.py"
        },
        {
          name = "PIPELINES_API_KEY"
          valueFrom = {
            secretKeyRef = {
              name = "litellm-proxy-master-key"
              key  = "LITELLM_PROXY_MASTER_KEY"
            }
          }
        }
      ],
      enabled = true
    }
    redis-cluster = {
      enabled = true
    }
    replicaCount = 4
    #serviceAccount = {
    #  enable = true
    #  name   = "vertex"
    #}
    websocket = {
      enabled = true
    }
  }
}

resource "kubectl_manifest" "openwebui_db_deployment" {
  yaml_body = yamlencode({
    apiVersion = "postgresql.cnpg.io/v1"
    kind       = "Cluster"
    metadata = {
      name      = "open-webui-pg-db"
      namespace = kubernetes_namespace.namespace.metadata[0].name
    }
    spec = {
      instances = 3
      bootstrap = {
        initdb = {
          database = "open-webui"
          owner    = "open-webui"
          secret = {
            name = "open-webui-secret"
          }
        }
      }
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

data "external" "openwebui_build_container" {
  program = ["bash", "${path.module}/utils/build_docker_image.sh"]
  query = {
    dockerfile_location = "${path.module}/docker/open-webui"
    #environment         = var.environment
    #assets_dir          = "${path.root}/../../../../../../../assets/${var.environment}/open-webui"
    assets_dir          = "${abspath(path.root)}/${var.asset_directory}/open-webui"
    new_image_name      = "ghcr.io/tamu-edu/tamu-open-webui-${var.environment}-${var.namespace}"
    openwebui_image_tag = var.openwebui_image_tag
  }
}

resource "docker_registry_image" "openwebui_publish_container" {
  name          = data.external.openwebui_build_container.result.image_name
  keep_remotely = true
  triggers = {
    image_name = data.external.openwebui_build_container.query.new_image_name
    tag        = data.external.openwebui_build_container.query.openwebui_image_tag
  }
}

# Need a dependency on the 1password/kubernetes secret
resource "helm_release" "openwebui" {
  name      = "openwebui"
  namespace = kubernetes_namespace.namespace.metadata[0].name
  timeout   = 600

  #repository = "https://helm.openwebui.com/"
  repository = "https://tamu-edu.github.io/open-webui-helm-charts/"
  chart      = "open-webui"
  #version    = var.openwebui_helm_chart_version
  version = "15.20.1"

  values = [yamlencode(local.openwebui_params)]

  wait          = true
  wait_for_jobs = true

  depends_on = [
    docker_registry_image.openwebui_publish_container,
    kubectl_manifest.ghcr_credentials,
    kubectl_manifest.openwebui_db_deployment,
    cloudflare_zero_trust_access_application.access,
    litellm_model.model
  ]
}

resource "null_resource" "openwebui_create_api_key" {
  provisioner "local-exec" {
    command = "${path.module}/utils/create_openwebui_admin_api_key.sh"
    when    = create

    environment = {
      CF_ACCESS_CLIENT_ID     = local.cloudflare_access_service_token.cf_access_client_id
      CF_ACCESS_CLIENT_SECRET = local.cloudflare_access_service_token.cf_access_client_secret
      OPENWEBUI_FQDN          = local.fqdn
      PSQL_FQDN               = local.psql_fqdn
      PSQL_USERNAME           = onepassword_item.namespace_secrets_separate["open-webui-secret"].username
      PSQL_PASSWORD           = onepassword_item.namespace_secrets_separate["open-webui-secret"].password
      PSQL_DB                 = "open-webui"
      # The username/password values can't actually be used because of Cloudflare authentication, but we set them to something
      # in order to set an API key
      OPENWEBUI_EMAIL    = "admin@admin.com"
      OPENWEBUI_PASSWORD = "M86rbeS712Fq1M9OLrhllxytprzEuJJm"
      OPENWEBUI_API_KEY  = local.one_password_namespace_secrets["open-webui-api-key"]
    }
  }

  depends_on = [
    helm_release.openwebui,
    null_resource.openwebui_sleep_for_api_ready
  ]
}

resource "null_resource" "openwebui_sleep_for_api_ready" {
  triggers = {
    last_deployment = helm_release.openwebui.metadata[0].last_deployed
  }
  provisioner "local-exec" {
    command = "sleep 30"
  }

  depends_on = [helm_release.openwebui]
}

resource "ansible_playbook" "openwebui_create_admin_users" {
  playbook   = "${path.module}/ansible/open-webui_create_admins.yaml"
  name       = "openwebui_create_admin_users"
  replayable = true

  extra_vars = {
    admin_users_string             = join(";", var.openwebui_admins)
    clouflare_access_client_id     = local.cloudflare_access_service_token.cf_access_client_id
    clouflare_access_client_secret = local.cloudflare_access_service_token.cf_access_client_secret
    open_webui_fqdn                = local.fqdn
    open_webui_api                 = "https://${local.fqdn}/api/v1"
    open_webui_api_key             = local.one_password_namespace_secrets["open-webui-api-key"]
  }

  depends_on = [
    null_resource.openwebui_create_api_key,
    null_resource.openwebui_sleep_for_api_ready
  ]
}

resource "ansible_playbook" "openwebui_set_user_default_permissions" {
  playbook   = "${path.module}/ansible/open-webui_update_user_permissions.yaml"
  name       = "openwebui_update_user_permissions"
  replayable = true

  extra_vars = {
    clouflare_access_client_id     = local.cloudflare_access_service_token.cf_access_client_id
    clouflare_access_client_secret = local.cloudflare_access_service_token.cf_access_client_secret
    open_webui_fqdn                = local.fqdn
    open_webui_api                 = "https://${local.fqdn}/api/v1"
    open_webui_api_key             = local.one_password_namespace_secrets["open-webui-api-key"]
  }

  depends_on = [
    null_resource.openwebui_create_api_key,
    ansible_playbook.openwebui_create_admin_users
  ]
}

resource "ansible_playbook" "openwebui_setup_models" {
  name       = "openwebui_setup_models"
  playbook   = "${path.module}/ansible/open-webui_setup_models.yaml"
  replayable = true
  #verbosity = 6

  extra_vars = {
    clouflare_access_client_id     = local.cloudflare_access_service_token.cf_access_client_id
    clouflare_access_client_secret = local.cloudflare_access_service_token.cf_access_client_secret
    open_webui_fqdn                = local.fqdn
    open_webui_api                 = "https://${local.fqdn}/api/v1"
    open_webui_api_key             = local.one_password_namespace_secrets["open-webui-api-key"]
    model_icons_regex = join(";", flatten([
      for expression in var.openwebui_model_logos : [
        "${expression.regex}=${expression.filename}"
      ]
    ]))
  }

  depends_on = [
    null_resource.openwebui_create_api_key,
    ansible_playbook.openwebui_create_admin_users
  ]
}
