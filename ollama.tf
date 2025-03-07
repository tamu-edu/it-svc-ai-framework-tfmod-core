resource "kubectl_manifest" "kubernetes_ollama_deployment_pvc" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "PersistentVolumeClaim"
    metadata = {
      labels = {
        "io.kompose.service" = "ollama-claim0"
      }
      name      = "ollama-claim0"
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
  yaml_body = yamlencode({
    apiVersion = "apps/v1"
    kind       = "Deployment"
    metadata = {
      annotations = {
        "kompose.cmd"     = "kompose convert"
        "kompose.version" = "1.34.0 (HEAD)"
      }
      labels = {
        "io.kompose.service" = "ollama"
      }
      name      = "ollama"
      namespace = kubernetes_namespace.namespace.metadata[0].name
    }
    spec = {
      replicas = 1
      selector = {
        matchLabels = {
          "io.kompose.service" = "ollama"
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
            "io.kompose.service" = "ollama"
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
                  name      = "ollama-claim0"
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
              name = "ollama-claim0"
              persistentVolumeClaim = {
                claimName = "ollama-claim0"
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
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Service"
    metadata = {
      annotations = {
        "kompose.cmd"     = "kompose convert"
        "kompose.version" = "1.34.0 (HEAD)"
      }
      labels = {
        "io.kompose.service" = "ollama"
      }
      name      = "ollama"
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
        "io.kompose.service" = "ollama"
      }
    }
  })

  depends_on = [kubectl_manifest.kubernetes_ollama_deployment]
}

resource "null_resource" "ollama_fetch_models" {
  triggers = {
    models = "${join(" ", var.ollama_models)}"
  }
  provisioner "local-exec" {
    #when    = create
    command = <<-EOT
      for pod in $(kubectl get pods -n ${var.namespace} --no-headers -o custom-columns=":metadata.name" | grep "^ollama" | grep -v "pg-")
      do
        for model in ${join(" ", var.ollama_models)}
        do
          kubectl -n ${var.namespace} exec -it $pod -- ollama pull $model
        done
      done
      EOT
  }

  depends_on = [kubectl_manifest.kubernetes_ollama_service]
}
