terraform {
  required_providers {
    ansible = {
      source  = "ansible/ansible"
      version = "1.3.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.1.0"
    }

    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }

    external = {
      source  = "hashicorp/external"
      version = "2.3.4"
    }

    google = {
      source  = "hashicorp/google"
      version = "6.20.0"
    }

    helm = {
      source = "hashicorp/helm"
      #version = "3.0.0-pre1"
      version = "2.17.0"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.19.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.35.1"
    }

    litellm = {
      source  = "ncecere/litellm"
      version = "0.2.2"
    }

    null = {
      source  = "hashicorp/null"
      version = "3.2.3"
    }

    onepassword = {
      source  = "1Password/onepassword"
      version = "2.1.2"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.6.3"
    }

    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.17.0"
    }
  }
}

#data "google_client_config" "current" {}

provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
}

provider "docker" {
  registry_auth {
    address = "ghcr.io"
  }
}

provider "helm" {
  kubernetes {
    config_path = local.kube_config_path
  }
}

provider "kubectl" {
  config_path = local.kube_config_path
}

provider "kubernetes" {
  config_path = local.kube_config_path
}

provider "litellm" {
  #api_base = "http://localhost:4000"
  api_base = "https://${local.lightllm_fqdn}"
  #api_key  = "sk-1234"
  api_key = local.one_password_namespace_secrets["LITELLM_PROXY_MASTER_KEY"]
}

data "google_client_config" "current" {}

locals {
  env_name = "it-svc-ai-framework:${var.environment}:${var.name}-${replace(var.cloudflare_domain_name, ".", "-")}"
  namespace = "${replace(var.name, ".", "-")}-${replace(var.cloudflare_domain_name, ".", "-")}"
}