resource "kubernetes_namespace" "networking" {
  metadata {
    name = "networking"
    labels = {
      "k8s.funkhouse.rs/purpose" = "infrastructure"
    }
  }
}

# NGINX ingress controller

resource "helm_release" "ingress_nginx_controller" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = kubernetes_namespace.networking.metadata[0].name
}

# External DNS

resource "helm_release" "cloudflare_external_dns" {
  name       = "funkhouse-rs-external-dns"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "external-dns"
  namespace  = kubernetes_namespace.networking.metadata[0].name

  set {
    name  = "provider"
    value = "cloudflare"
  }

  set {
    name  = "cloudflare.apiToken"
    value = var.cloudflare_token
  }

  # Disable proxying by default. For the most part, we just want to use
  # Cloudflare for DNS.
  set {
    name  = "cloudflare.proxied"
    value = false
  }
}
