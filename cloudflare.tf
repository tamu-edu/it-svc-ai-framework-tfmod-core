locals {
  fqdn          = "${var.name}.${var.cloudflare_domain_name}"
  lightllm_fqdn = "${var.name}-litellm.${var.cloudflare_domain_name}"
  pipelines_fqdn= "${var.name}-pipelines.${var.cloudflare_domain_name}"
  psql_fqdn     = "${var.name}-psql.${var.cloudflare_domain_name}"

  tunnel_token = base64encode(jsonencode({
    a = var.cloudflare_account_id
    t = cloudflare_zero_trust_tunnel_cloudflared.tunnel.id
    s = base64encode(local.one_password_namespace_secrets["cloudflare-tunnel-secret"])
  }))
}

data "cloudflare_zone" "zone" {
  filter = {
    account = {
      id = var.cloudflare_account_id
    }
    name = var.cloudflare_domain_name
  }
}

data "cloudflare_zero_trust_access_identity_provider" "entraid" {
  account_id           = var.cloudflare_account_id
  identity_provider_id = var.cloudflare_identity_provider_id
}

#data "cloudflare_zero_trust_access_service_token" "kubernetes_token" {
#  account_id  = var.cloudflare_account_id
#  filter = {
#    name = "Kubernetes Service Token (API access to OpenWebUI)"
#  }
#}

resource "cloudflare_zero_trust_tunnel_cloudflared" "tunnel" {
  account_id    = var.cloudflare_account_id
  name          = local.env_name
  tunnel_secret = base64encode(local.one_password_namespace_secrets["cloudflare-tunnel-secret"])
}

resource "cloudflare_dns_record" "record" {
  for_each = {
    "api"     = "-api"
    "base"    = ""
    "litellm" = "-litellm"
    #"litellm-exporter" = "-litellm-exporter"
    "pipelines" = "-pipelines"
    "psql" = "-psql"
  }
  zone_id = data.cloudflare_zone.zone.zone_id
  name    = "${var.name}${each.value}.${var.cloudflare_domain_name}"
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.tunnel.id}.cfargotunnel.com"
  proxied = true
  ttl     = var.cloudflare_dns_ttl
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "tunnel_config" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.tunnel.id

  config = {
    warp_routing = {
      enabled = true
    }
    origin_request = {
      connect_timeout          = 60
      tls_timeout              = 60
      tcp_keep_alive           = 60
      no_happy_eyeballs        = false
      keep_alive_connections   = 1024
      keep_alive_timeout       = 60
      http_host_header         = ""
      origin_server_name       = ""
      no_tls_verify            = false
      disable_chunked_encoding = false
    }

    ingress = [{
      hostname = local.fqdn
      path     = ""
      service  = "http://open-webui:80"
      origin_request = {
        connect_timeout = 120
        access = {
          required  = false
          team_name = local.env_name
          aud_tag   = [cloudflare_zero_trust_access_application.access.name]
        }
      }
      },
      {
        hostname = "${var.name}-api.${var.cloudflare_domain_name}"
        path     = "/api/v1/auths/signup"
        service  = "http_status:404"
        origin_request = {
          connect_timeout = 120
          access = {
            required  = false
            team_name = local.env_name
            aud_tag   = [cloudflare_zero_trust_access_application.access.name]
          }
        }
      },
      {
        hostname = "${var.name}-api.${var.cloudflare_domain_name}"
        path     = ""
        service  = "http://open-webui:80"
        origin_request = {
          connect_timeout = 120
          access = {
            required  = false
            team_name = local.env_name
            aud_tag   = [cloudflare_zero_trust_access_application.access.name]
          }
        }
      },
      #{
      #  hostname = "${var.name}-litellm-exporter.${var.cloudflare_domain_name}"
      #  path     = ""
      #  service  = "http://litellm-exporter:9090"
      #  origin_request = {
      #    connect_timeout = 120
      #    access = {
      #      required  = false
      #      team_name = local.env_name
      #      aud_tag   = [cloudflare_zero_trust_access_application.access.name]
      #    }
      #  }
      #},
      {
        hostname = local.lightllm_fqdn
        path     = ""
        service  = "http://litellm:4000"
        origin_request = {
          connect_timeout = 120
          access = {
            required  = false
            team_name = local.env_name
            aud_tag   = [cloudflare_zero_trust_access_application.access.name]
          }
        }
      },
      {
        hostname = local.pipelines_fqdn
        path     = ""
        service  = "http://open-webui-pipelines:9099"
        origin_request = {
          connect_timeout = 120
          access = {
            required  = false
            team_name = local.env_name
            aud_tag   = [cloudflare_zero_trust_access_application.access.name]
          }
        }
      },
      {
        hostname = local.psql_fqdn
        path     = ""
        service  = "tcp://open-webui-pg-db-rw:5432"
        origin_request = {
          connect_timeout = 120
          access = {
            required  = false
            team_name = local.env_name
            aud_tag   = [cloudflare_zero_trust_access_application.access.name]
          }
        }
      },
      {
        service = "http_status:404"
    }]
  }
}

resource "cloudflare_zero_trust_access_policy" "policy_sso" {
  account_id                     = var.cloudflare_account_id
  name                           = "${local.env_name}:sso"
  decision                       = "allow"
  approval_required              = false
  isolation_required             = false
  purpose_justification_required = false

  include = [{
    login_method = {
      id = data.cloudflare_zero_trust_access_identity_provider.entraid.identity_provider_id
    }
  }]
}

resource "cloudflare_zero_trust_access_policy" "policy_token" {
  account_id                     = var.cloudflare_account_id
  name                           = "${local.env_name}:token"
  decision                       = "non_identity"
  approval_required              = false
  isolation_required             = false
  purpose_justification_required = false

  include = [{
    service_token = {
      token_id = var.cloudflare_access_service_token.id
    }
  }]
}

resource "cloudflare_zero_trust_access_application" "access" {
  zone_id                    = data.cloudflare_zone.zone.zone_id
  name                       = local.env_name
  domain                     = local.fqdn
  http_only_cookie_attribute = true
  type                       = "self_hosted"
  #domain_type               = "public"
  session_duration          = "24h"
  allowed_idps              = [data.cloudflare_zero_trust_access_identity_provider.entraid.identity_provider_id]
  auto_redirect_to_identity = true

  destinations = [{
    type = "public"
    uri  = local.fqdn
  }]

  policies = [{
    id         = cloudflare_zero_trust_access_policy.policy_token.id
    precedence = 1
    decision   = "non_identity"
    },
    {
      id         = cloudflare_zero_trust_access_policy.policy_sso.id
      precedence = 2
      decision   = "allow"
  }]
}

# Create Kubernetes Secret for Cloudflare credentials
resource "kubernetes_secret" "cloudflare_credentials" {
  metadata {
    name      = "cloudflare-credentials"
    namespace = kubernetes_namespace.namespace.metadata[0].name
  }

  data = {
    TUNNEL_TOKEN = local.tunnel_token
  }
  timeouts {
    create = "5m"
  }
}

# TODO: Need to reference the above secret instead of setting it directly
resource "helm_release" "cloudflare_tunnel" {
  name      = "${var.environment}-cloudflare-tunnel"
  namespace = kubernetes_namespace.namespace.metadata[0].name

  repository = "https://cloudflare.github.io/helm-charts"
  chart      = "cloudflare-tunnel-remote"

  set {
    name  = "cloudflare.tunnel_token"
    value = local.tunnel_token
  }
}

#resource "cloudflare_ruleset" "openwebui_asset_rewrite" {
#  zone_id     = data.cloudflare_zone.zone.zone_id
#  name        = "Rewrite static assets for open-webui"
#  description = "Rewrite logos and splash images to use a custom path"
#  kind        = "zone"
#  phase       = "http_request_transform"
#
#  rules = [{
#    ref         = "url_rewrite_favicon"
#    description = "Rewrite favicon.png"
#    expression  = "(http.request.full_uri wildcard r\"https://*.dev.tamu.ai/static/favicon.png\") or (http.request.full_uri wildcard r\"https://*.dev.tamu.ai/static/logo.png\") or (http.request.full_uri wildcard r\"https://*.dev.tamu.ai/static/splash.png\")"
#    action      = "rewrite"
#    action_parameters = {
#      uri = {
#        path = {
#          expression = "wildcard_replace(http.request.uri.path, r\"/static/*\", r\"/static/tamu/$${1}\")"
#        }
#      }
#    }
#  }]
#
#  depends_on = [cloudflare_zero_trust_access_application.access]
#}
