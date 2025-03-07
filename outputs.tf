output "ansible_stderr_openwebui_create_admin_users" {
  value = ansible_playbook.openwebui_create_admin_users.ansible_playbook_stderr
}

output "ansible_stdout_openwebui_create_admin_users" {
  value = ansible_playbook.openwebui_create_admin_users.ansible_playbook_stdout
}

output "ansible_stderr_openwebui_setup_models" {
  value = ansible_playbook.openwebui_setup_models.ansible_playbook_stderr
}

output "ansible_stdout_openwebui_setup_models" {
  value = ansible_playbook.openwebui_setup_models.ansible_playbook_stdout
}

output "gcp_project" {
  value = data.google_client_config.current.region
}

## temp
#output "temp" {
#  value = data.onepassword_item.it-ae-tamu-ai_connector_json
#  sensitive = true
#}
