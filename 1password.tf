locals {
  one_password_namespace_secrets = {
    for field in onepassword_item.namespace_secrets_shared.section[0].field :
    "${field.id}" => field.value
  }

  aws_models_credentials = {
    (data.onepassword_item.shared_model_aws.section[0].label) = data.onepassword_item.shared_model_aws.section[0].field[0].value
    (data.onepassword_item.shared_model_aws.section[1].label) = data.onepassword_item.shared_model_aws.section[1].field[0].value
  }

  cloudflare_access_service_token = {
    cf_access_client_id = data.onepassword_item.shared_cloudflare_access_service_token.username
    cf_access_client_secret = data.onepassword_item.shared_cloudflare_access_service_token.password
  }
}

output "temp" {
  #value = local.cloudflare_access_service_token
  sensitive = true
  value = ""
}

data "onepassword_vault" "vault" {
  name = "${var.vault_prefix}-${var.environment}"
}

data "onepassword_item" "shared_secrets" {
  for_each = toset(var.shared_secrets)
  vault    = data.onepassword_vault.vault.uuid
  title    = "shared-${each.value}"
}

# Using this method because 1password will not generate passwords for each field in a section (bug)
resource "random_password" "shared_password" {
  for_each         = var.namespace_secrets_shared
  length           = 32 - length(each.value)
  special          = false
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "separate_password" {
  for_each         = var.namespace_secrets_separate
  length           = 32
  special          = false
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "onepassword_item" "namespace_secrets_shared" {
  vault    = data.onepassword_vault.vault.uuid
  title    = "${var.namespace}-secrets"
  category = "login"

  section {
    label = "${var.namespace} secrets"

    dynamic "field" {
      for_each = var.namespace_secrets_shared
      content {
        id    = field.key
        label = field.key
        type  = "CONCEALED"
        value = "${field.value}${random_password.shared_password[field.key].result}"
      }
    }
  }
}

resource "onepassword_item" "namespace_secrets_separate" {
  for_each = var.namespace_secrets_separate
  vault    = data.onepassword_vault.vault.uuid
  title    = "${var.namespace}-${each.key}"
  category = "login"

  username = each.value
  password = random_password.separate_password[each.key].result
}

data "onepassword_item" "shared_cloudflare_api_token" {
  vault = data.onepassword_vault.vault.uuid
  title = var.cloudflare_api_token_secret_name
}

data "onepassword_item" "shared_cloudflare_access_service_token" {
  vault = data.onepassword_vault.vault.uuid
  title = var.cloudflare_access_service_token.name
}

#data "onepassword_item" "it-ae-tamu-ai_connector_token" {
#  vault = data.onepassword_vault.vault.uuid
#  title = "1password it-ae-tamu-ai connector token (${var.environment})"
#}
#
#data "onepassword_item" "it-ae-tamu-ai_connector_json" {
#  vault = data.onepassword_vault.vault.uuid
#  title = "1password-it-ae-tamu-ai-token.json"
#}

data "onepassword_item" "ghcr_credentials" {
  vault = data.onepassword_vault.vault.uuid
  title = "sa-auto-ai-framework (GitHub PAT)"
}

#resource "helm_release" "onepassword_operator" {
#  name      = "${var.environment}-onepassword-operator"
#  namespace = kubernetes_namespace.namespace.metadata[0].name
#
#  repository = "https://1password.github.io/connect-helm-charts/"
#  chart      = "connect"
#
#  set {
#    name  = "operator.create"
#    value = true
#  }
#  set {
#    name  = "operator.token.value"
#    value = data.onepassword_item.it-ae-tamu-ai_connector_token.password
#  }
#  set {
#    name  = "connect.credentials_base64"
#    value = data.onepassword_item.it-ae-tamu-ai_connector_json.section[0].file[0].content_base64
#  }
#}

resource "kubectl_manifest" "secrets_mapping_onepassword_shared" {
  for_each = toset(var.shared_secrets)
  yaml_body = yamlencode({
    apiVersion = "onepassword.com/v1"
    kind       = "OnePasswordItem"

    metadata = {
      name      = each.value
      namespace = kubernetes_namespace.namespace.metadata[0].name
    }

    spec = {
      itemPath = "vaults/it-ae-svc-open-webui-${var.environment}/items/shared-${each.value}"
    }
  })

  #depends_on = [
  #  helm_release.onepassword_operator
  #]
}

### DEBUGGING
#data onepassword_item "namespace_secrets" {
#  vault    = data.onepassword_vault.vault.uuid
#  title    = "${var.namespace}-secrets"
#}
#
#output "temp" {
#  value = data.onepassword_item.namespace_secrets.section
#  sensitive = true
#}
## DEBUGGING

resource "kubectl_manifest" "secrets_mapping_onepassword_namespace_shared" {
  for_each = toset(keys(var.namespace_secrets_shared))
  yaml_body = yamlencode({
    apiVersion = "onepassword.com/v1"
    kind       = "OnePasswordItem"

    metadata = {
      name      = replace(lower(each.value), "_", "-")
      namespace = kubernetes_namespace.namespace.metadata[0].name
    }

    spec = {
      itemPath = "vaults/it-ae-svc-open-webui-${var.environment}/items/${var.namespace}-secrets"
    }
  })

  depends_on = [
    #helm_release.onepassword_operator,
    onepassword_item.namespace_secrets_shared
  ]
}

resource "kubectl_manifest" "secrets_mapping_onepassword_namespace_separate" {
  for_each = var.namespace_secrets_separate
  yaml_body = yamlencode({
    apiVersion = "onepassword.com/v1"
    kind       = "OnePasswordItem"

    metadata = {
      name      = replace(lower(each.key), "_", "-")
      namespace = kubernetes_namespace.namespace.metadata[0].name
    }

    spec = {
      itemPath = "vaults/it-ae-svc-open-webui-${var.environment}/items/${var.namespace}-${each.key}"
    }
  })

  depends_on = [
    #helm_release.onepassword_operator,
    onepassword_item.namespace_secrets_separate
  ]
}

resource "kubectl_manifest" "ghcr_credentials" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind = "Secret"
    metadata = {
      name = "ghcr-credentials"
      namespace = kubernetes_namespace.namespace.metadata[0].name
    }
    data = {
      ".dockerconfigjson" = base64encode(jsonencode({
        auths = {
          "ghcr.io" = {
            auth = base64encode("${data.onepassword_item.ghcr_credentials.username}:${data.onepassword_item.ghcr_credentials.password}")
          }
        }
      }))
    }
    type = "kubernetes.io/dockerconfigjson"
  })
}

data "onepassword_item" "shared_model_aws" {
  vault = data.onepassword_vault.vault.uuid
  title = "shared-model-aws"
}

data "onepassword_item" "shared_model_az" {
  vault = data.onepassword_vault.vault.uuid
  title = "shared-model-az"
}

data "onepassword_item" "shared_model_gcp" {
  vault = data.onepassword_vault.vault.uuid
  title = "shared-model-gcp"
}
