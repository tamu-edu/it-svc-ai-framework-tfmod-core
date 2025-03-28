#
# Create a litellm API key for use by OpenWebUI for all Users
#

resource "litellm_key" "user_key" {
  models                = ["all"]
  max_budget            = 1.0
  user_id               = "open-webui-user-key"
  team_id               = litellm_team.open_webui_users.team_alias
  max_parallel_requests = 5
  metadata = {
    environment = "production"
  }
  tpm_limit              = 1000
  rpm_limit              = 60
  budget_duration        = "30d"
  allowed_cache_controls = ["no-cache", "max-age=3600"]
  soft_budget            = 80.0
  key_alias              = "open-webui-user-key"
  duration               = "30d"

  permissions = {
    can_create_keys = false
  }

  guardrails = ["content_filter", "token_limit"]
  blocked    = false

  depends_on = [
    null_resource.litellm_sleep_for_release_ready,
    helm_release.cloudflare_tunnel
  ]
}

resource "litellm_model" "model" {
  for_each = var.lightllm_models

  model_name                     = each.value.model_name
  custom_llm_provider            = each.value.custom_llm_provider
  base_model                     = each.value.base_model
  model_api_key                  = each.value.authentication == "azure" ? data.onepassword_item.az_openai_key.credential : null
  model_api_base                 = each.value.custom_llm_provider == "ollama" ? "http://ollama-${local.ollama_models_norm[each.value.model_name]}:7869" : (each.value.custom_llm_provider == "azure" ? azurerm_cognitive_account.openai.endpoint : try(each.value.model_api_base, null))
  api_version                    = try(each.value.api_version, null)
  tier                           = each.value.tier
  aws_access_key_id              = each.value.authentication == "aws" ? local.aws_models_credentials.aws_access_key_id : null
  aws_secret_access_key          = each.value.authentication == "aws" ? local.aws_models_credentials.aws_secret_access_key : null
  aws_region_name                = "us-east-1"
  input_cost_per_million_tokens  = try(each.value.input_cost_per_million_tokens, null)
  output_cost_per_million_tokens = try(each.value.output_cost_per_million_tokens, null)

  depends_on = [
    null_resource.litellm_sleep_for_release_ready,
    helm_release.cloudflare_tunnel
  ]
}
