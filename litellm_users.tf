#
# Create a user to represent all users
#

resource "litellm_team_member" "open_webui_users" {
  team_id            = litellm_team.open_webui_users.id
  user_id            = "open-webui-users"
  user_email         = "no-reply@tamu.edu"
  role               = "user"
  max_budget_in_team = 100.0

  depends_on = [
    helm_release.litellm,
    helm_release.cloudflare_tunnel,
    cloudflare_dns_record.record
  ]
}

#
# create a team for all users
#

resource "litellm_team" "open_webui_users" {
  team_alias = "open-webui-users"
  models     = ["all"]

  metadata = {
    department = "Users"
    project    = "AI Research"
  }

  blocked         = false
  tpm_limit       = 500000
  rpm_limit       = 5000
  max_budget      = 10.0
  budget_duration = "30d"

  depends_on = [
    null_resource.litellm_sleep_for_release_ready,
    helm_release.cloudflare_tunnel,
    cloudflare_dns_record.record
  ]
}


#resource "litellm_team_member" "admin" {
#  for_each           = toset(var.litellm_admins)
#  team_id            = litellm_team.admin.id
#  user_id            = each.value
#  user_email         = "${each.value}@tamu.edu"
#  role               = "user"
#  max_budget_in_team = 200.0
#  
#  depends_on = [
#    helm_release.litellm,
#    helm_release.cloudflare_tunnel,
#    cloudflare_dns_record.record
#  ]
#}

resource "litellm_team" "admin" {
  team_alias = "admin-team"
  models     = ["all"]

  metadata = {
    department = "Administrators"
    project    = "AI Research"
  }

  blocked         = false
  tpm_limit       = 500000
  rpm_limit       = 5000
  max_budget      = 1000.0
  budget_duration = "30d"

  depends_on = [
    null_resource.litellm_sleep_for_release_ready,
    helm_release.cloudflare_tunnel,
    cloudflare_dns_record.record
  ]
}
