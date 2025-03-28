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
  title    = "${local.namespace}-secrets"
  category = "login"

  section {
    label = "${local.namespace} secrets"

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
  title    = "${local.namespace}-${each.key}"
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

data "onepassword_item" "ghcr_credentials" {
  vault = data.onepassword_vault.vault.uuid
  title = "sa-auto-ai-framework (GitHub PAT)"
}

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
}

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
      itemPath = "vaults/it-ae-svc-open-webui-${var.environment}/items/${local.namespace}-secrets"
    }
  })

  depends_on = [
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
      itemPath = "vaults/it-ae-svc-open-webui-${var.environment}/items/${local.namespace}-${each.key}"
    }
  })

  depends_on = [
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

resource "onepassword_item" "aws_access_key" {
  vault = data.onepassword_vault.vault.uuid
  title = "aws_access_key"
  category = "login"
  username = aws_iam_access_key.litellm_access_key.id
  password = aws_iam_access_key.litellm_access_key.secret
}

resource "onepassword_item" "az_openai_key" {
  vault = data.onepassword_vault.vault.uuid
  title = "az_openai_key"
  category = "login"
  password = azurerm_cognitive_account.openai.primary_access_key
}

data "onepassword_item" "shared_model_az" {
  vault = data.onepassword_vault.vault.uuid
  title = "shared-model-az"
}

data "onepassword_item" "shared_model_gcp" {
  vault = data.onepassword_vault.vault.uuid
  title = "shared-model-gcp"
}
