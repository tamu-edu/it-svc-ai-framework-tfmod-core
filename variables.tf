variable "asset_directory" {
  description = "Directory containing additional assets"
  type        = string
}

variable "cloudflare_account_id" {
  description = "Cloudflare account id"
  type        = string
  default     = "3f44406dadaf8b9c8e58f4586f85e167"
}

variable "cloudflare_access_service_token" {
  description = "Cloudflare access service token"
  type        = map(string)
  default = {
    name = "Cloudflare Service Token (API access to OpenWebUI)"
    id   = "7175db3e-0815-4e1c-a970-3d5827a7995c"
  }
}

variable "cloudflare_api_token_secret_name" {
  description = "Cloudflare API token secret name in 1password"
  type        = string
  default     = "shared-cloudflare-api-token"
}

variable "cloudflare_dns_ttl" {
  description = "Cloudflare DNS TTL"
  type        = number
  default     = 1
}

variable "cloudflare_domain_name" {
  description = "Cloudflare domain name"
  type        = string
}

variable "cloudflare_identity_provider_id" {
  description = "Cloudflare IDP instance id"
  type        = string
  #default     = "3f44406dadaf8b9c8e58f4586f85e167"
  default = "7216a9fe-fc3b-4d15-9bff-63154af95946"
}

variable "environment" {
  description = "Environment name"
  type        = string

  validation {
    condition     = var.environment == "dev" || var.environment == "test" || var.environment == "prod"
    error_message = "Environment must be one of dev, test, or prod"
  }
}

variable "kubernetes_cluster_prefix" {
  description = "Prefix for Kubernetes cluster name"
  type        = string
  default     = "it-svc-ai-framework"
}

#variable "litellm_admins" {
#  description = "LightLLM admins"
#  type        = list(string)
#  default = [
#    "bdd4329",
#    "joshuacook",
#    "soren"
#  ]
#}

variable "litellm_db_database" {
  description = "LightLLM database name"
  type        = string
  default     = "litellm"
}

variable "litellm_db_secret_name_suffix" {
  description = "LightLLM database secret name"
  type        = string
  default     = "litellm-secret"
}

variable "litellm_environment_config_maps" {
  description = "LightLLM environment config maps"
  type        = list(string)
  default     = ["litellm-env-configmap"]
}

variable "litellm_proxy_allow_requests_on_db_unavailable" {
  description = "Allow requests on DB unavailable"
  type        = bool
  default     = true
}

variable "litellm_proxy_db_connection_pool_limit" {
  description = "Database connection pool limit"
  type        = number
  default     = 10
}

variable "litellm_proxy_disable_spend_logs" {
  description = "Disable spend logs"
  type        = bool
  default     = false
}

variable "litellm_proxy_disable_error_logs" {
  description = "Disable error logs"
  type        = bool
  default     = false
}

variable "litellm_proxy_batch_write_at" {
  description = "Proxy batch write at"
  type        = number
  default     = 60
}

variable "litellm_proxy_store_model_in_db" {
  description = "Store model in DB"
  type        = bool
  default     = true
}

variable "litellm_proxy_json_logs" {
  description = "Enable JSON logs"
  type        = bool
  default     = true
}

variable "litellm_proxy_request_timeout" {
  description = "Request timeout"
  type        = number
  default     = 600
}

variable "litellm_proxy_set_verbose" {
  description = "Set verbose logging"
  type        = bool
  default     = false
}

variable "litellm_image_tag" {
  description = "LightLLM image tag"
  type        = string
  #default     = "main-v1.60.8"
  default = "main-v1.61.7"
}

variable "litellm_replica_count" {
  description = "Replica count"
  type        = number
  default     = 1
}

variable "litellm_env_config_map" {
  description = "LightLLM environment config map"
  type        = map(any)
  default = {
    DETAILED_DEBUG = "False"
    LITELLM_LOG    = "INFO"
    LITELLM_MODE   = "PRODUCTION"
    NUM_WORKERS    = "8"
  }
}

variable "lightllm_helm_chart_version" {
  description = "LightLLM Helm chart version"
  type        = string
  default     = "0.1.615"
}

variable "lightllm_models" {
  description = "LightLLM models"
  type        = map(map(any))
  default = {
    "granite-code:8b" = {
      model_name          = "granite-code:8b"
      custom_llm_provider = "ollama"
      #model_api_base      = "http://ollama:7869"
      base_model          = "granite-code:8b"
      tier                = "paid"
      authentication      = "none"
    }
    #"hf.co/brittlewis12/s1-32B-GGUF:Q4_0" = {
    #  #model_name          = "hf.co/brittlewis12/s1-32B-GGUF:Q4_0"
    #  model_name          = "hf.co-brittlewis12-s1-32B-GGUF:Q4_0"
    #  custom_llm_provider = "ollama"
    #  model_api_base      = "http://ollama:7869"
    #  base_model          = "hf.co/brittlewis12/s1-32B-GGUF:Q4_0"
    #  tier                = "paid"
    #  authentication      = "none"
    #}
    "llama3.2" = {
      model_name                     = "llama3.2"
      custom_llm_provider            = "ollama"
      #model_api_base                 = "http://ollama:7869"
      base_model                     = "llama3.2"
      tier                           = "paid"
      authentication                 = "none"
      input_cost_per_million_tokens  = 1.0
      output_cost_per_million_tokens = 3.0
    }
    "Claude 3.5 Sonnet" = {
      model_name          = "Claude 3.5 Sonnet"
      custom_llm_provider = "bedrock"
      base_model          = "anthropic.claude-3-5-sonnet-20240620-v1:0"
      tier                = "paid"
      authentication      = "aws"
    }
    "Claude Instant" = {
      model_name          = "Claude Instant"
      custom_llm_provider = "bedrock"
      base_model          = "anthropic.claude-instant-v1"
      tier                = "paid"
      authentication      = "aws"
    }
    "gpt-4o" = {
      model_name          = "gpt-4o"
      custom_llm_provider = "azure"
      base_model          = "gpt-4o"
      model_api_base      = "https://azure-openai-644048.openai.azure.com"
      api_version         = "2024-08-01-preview"
      tier                = "paid"
      authentication      = "azure"
    }
    "o3-mini" = {
      model_name          = "o3-mini"
      custom_llm_provider = "azure"
      base_model          = "o3-mini"
      model_api_base      = "https://azure-openai-644048.openai.azure.com"
      api_version         = "2024-12-01-preview"
      tier                = "paid"
      authentication      = "azure"
    }
    "gpt-4o-via-cloudflare" = {
      model_name          = "gpt-4o-via-cloudflare"
      custom_llm_provider = "azure"
      base_model          = "gpt-4o"
      model_api_base      = "https://gateway.ai.cloudflare.com/v1/3f44406dadaf8b9c8e58f4586f85e167/tamu-ai-staging/azure-openai/azure-openai-644048"
      api_version         = "2024-08-01-preview"
      tier                = "paid"
      authentication      = "azure"
    }
    "o3-mini-via-cloudflare" = {
      model_name          = "o3-mini-via-cloudflare"
      custom_llm_provider = "azure"
      base_model          = "o3-mini"
      model_api_base      = "https://gateway.ai.cloudflare.com/v1/3f44406dadaf8b9c8e58f4586f85e167/tamu-ai-staging/azure-openai/azure-openai-644048"
      api_version         = "2024-12-01-preview"
      tier                = "paid"
      authentication      = "azure"
    }
  }
}

variable "namespace" {
  description = "kubernetes cluster namespace, e.g. NAMESPACE=chat (i.e., chat.dev.tamu.ai)"
  type        = string
}

variable "namespace_secrets_shared" {
  description = "Map of names of namespace secrets that are all in a single 1password vault. The value is the secret prefix."
  type        = map(any)
  default = {
    "cloudflare-tunnel-secret" = ""
    "litellm-exporter-secrets" = ""
    "LITELLM_MASTER_KEY"       = "sk-"
    "LITELLM_PROXY_MASTER_KEY" = "sk-"
    "LITELLM_SALT_KEY"         = ""
    "openai-api-key"           = ""
    "open-webui-api-key"       = "sk-"
  }
}

variable "namespace_secrets_separate" {
  description = "Map of names of namespace secrets that are in separate 1password vaults. The key is the secret name, the value is the username"
  type        = map(any)
  default = {
    open-webui-secret = "open-webui"
    litellm-secret    = "llmproxy"
  }
}

#variable "ollama_models" {
#  description = "Ollama models"
#  type        = list(string)
#  default = [
#    "llama3.2",
#    "granite-code:8b",
#    #"hf.co/brittlewis12/s1-32B-GGUF:Q4_0"
#  ]
#}

variable "openwebui_admins" {
  description = "OpenWebUI admins"
  type        = list(string)
  default = [
    "bdd4329@tamu.edu",
    "joshuacook@tamu.edu",
    "soren@tamu.edu"
  ]
}

variable "openwebui_helm_chart_version" {
  description = "OpenWebUI Helm chart version"
  type        = string
  default     = "5.17.0"
}

variable "openwebui_image_tag" {
  description = "OpenWebUI image tag"
  type        = string
  default     = "0.5.16"
}

variable "openwebui_model_logos" {
  description = "OpenWebUI model logo mappings"
  type        = list(map(string))
  default = [{
    regex    = ".*Claude.*"
    filename = "claude.png"
    },
    {
      regex    = ".*gemini.*"
      filename = "gemini.png"
    },
    {
      regex    = ".*gpt.*"
      filename = "openai.png"
    },
    {
      regex    = ".*granite.*"
      filename = "granite.png"
    },
    {
      regex    = ".*llama.*"
      filename = "llama.png"
    }
  ]
}

variable "shared_secrets" {
  description = "Shared secrets"
  type        = list(any)
  default = [
    "azure-openai-api-key",
    "google-api-key",
    "open-api-key",
  ]
}

variable "vault_prefix" {
  description = "Prefix for Vault secrets"
  type        = string
  default     = "it-ae-svc-open-webui"
}
