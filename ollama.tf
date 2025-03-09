locals {
  ollama_models_norm = {
    for model_name, model in var.lightllm_models : model.model_name => 
      replace(replace(replace(model.model_name, ".", ""), "/", "-"), ":", "--")
    if model.custom_llm_provider == "ollama"
    }
}

resource "kubectl_manifest" "kubernetes_ollama_deployment_pvc" {
  for_each = local.ollama_models_norm
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "PersistentVolumeClaim"
    metadata = {
      labels = {
        "io.kompose.service" = "ollama-claim0-${each.value}"
      }
      name      = "ollama-claim0-${each.value}"
      namespace = kubernetes_namespace.namespace.metadata[0].name
    }
    spec = {
      accessModes = [
        "ReadWriteOnce",
      ]
      resources = {
        requests = {
          storage = "100Gi"
        }
      }
    }
  })

  #depends_on = [
  #  helm_release.cnpg
  #]
}

resource "kubectl_manifest" "kubernetes_ollama_deployment" {
  for_each = local.ollama_models_norm
  yaml_body = yamlencode({
    apiVersion = "apps/v1"
    kind       = "Deployment"
    metadata = {
      annotations = {
        "kompose.cmd"     = "kompose convert"
        "kompose.version" = "1.34.0 (HEAD)"
      }
      labels = {
        "io.kompose.service" = "ollama-${each.value}"
      }
      name      = "ollama-${each.value}"
      namespace = kubernetes_namespace.namespace.metadata[0].name
    }
    spec = {
      replicas = 1
      selector = {
        matchLabels = {
          "io.kompose.service" = "ollama-${each.value}"
        }
      }
      strategy = {
        type = "Recreate"
      }
      template = {
        metadata = {
          annotations = {
            "kompose.cmd"     = "kompose convert"
            "kompose.version" = "1.34.0 (HEAD)"
          }
          labels = {
            "io.kompose.service" = "ollama-${each.value}"
          }
        }
        spec = {
          containers = [
            {
              env = [
                {
                  name  = "OLLAMA_KEEP_ALIVE"
                  value = "5m"
                },
              ]
              image = "ollama/ollama:latest"
              name  = "ollama"
              ports = [
                {
                  containerPort = 11434
                  protocol      = "TCP"
                },
              ]
              resources = {
                limits = {
                  memory           = "32Gi"
                  "nvidia.com/gpu" = 1
                }
                requests = {
                  memory           = "32Gi"
                  "nvidia.com/gpu" = 1
                }
              }
              tty = true
              volumeMounts = [
                {
                  mountPath = "/root/.ollama"
                  name      = "ollama-claim0-${each.value}"
                },
              ]
            },
          ]
          nodeSelector = {
            "cloud.google.com/gke-accelerator"       = "nvidia-tesla-t4"
            "cloud.google.com/gke-accelerator-count" = "1"
            "cloud.google.com/gke-spot"              = "true"
          }
          restartPolicy                 = "Always"
          terminationGracePeriodSeconds = 15
          volumes = [
            {
              name = "ollama-claim0-${each.value}"
              persistentVolumeClaim = {
                claimName = "ollama-claim0-${each.value}"
              }
            },
          ]
        }
      }
    }
  })

  depends_on = [kubectl_manifest.kubernetes_ollama_deployment_pvc]
}

resource "kubectl_manifest" "kubernetes_ollama_service" {
  for_each = local.ollama_models_norm
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Service"
    metadata = {
      annotations = {
        "kompose.cmd"     = "kompose convert"
        "kompose.version" = "1.34.0 (HEAD)"
      }
      labels = {
        "io.kompose.service" = "ollama-${each.value}"
      }
      name      = "ollama-${each.value}"
      namespace = kubernetes_namespace.namespace.metadata[0].name
    }
    spec = {
      ports = [
        {
          name       = "7869"
          port       = 7869
          targetPort = 11434
        },
      ]
      selector = {
        "io.kompose.service" = "ollama-${each.value}"
      }
    }
  })

  depends_on = [kubectl_manifest.kubernetes_ollama_deployment]
}

resource "null_resource" "ollama_fetch_models" {
  for_each = local.ollama_models_norm
  triggers = {
    #models = "${join(" ", keys(local.ollama_models_norm))}"
    model = each.value
  }
  provisioner "local-exec" {
    #when    = create
    command = <<-EOT
      #for pod in $(kubectl get pods -n ${var.namespace} --no-headers -o custom-columns=":metadata.name" | grep "^ollama" | grep -v "pg-")
      for pod in $(kubectl get pods -n ${var.namespace} --no-headers -o custom-columns=":metadata.name" | grep "^ollama-${each.value}" | grep -v "pg-")
      do
        kubectl -n ${var.namespace} exec -it $pod -- ollama pull ${each.key}
      done
      EOT
  }

  depends_on = [kubectl_manifest.kubernetes_ollama_service]
}
