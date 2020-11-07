resource "kubernetes_namespace" "diagnostics" {
  metadata {
    name = "diagnostics"
    labels = {
      "k8s.funkhouse.rs/purpose" = "diagnostics"
    }
  }
}

# The httpdumper service will help diagnose Ingress configurations.

resource "helm_release" "httpdumper" {
  name      = "ingress-debug"
  chart     = "./charts/httpdumper"
  namespace = kubernetes_namespace.diagnostics.metadata[0].name
}

# Now expose the httpdumper directly as "debug" within the cluster domain.

locals {
  debug_hostname     = "debug.${local.cluster_domain}"
  debug_service_name = "${helm_release.httpdumper.name}-httpdumper"
}

resource "kubernetes_ingress" "ingress_debug" {
  metadata {
    name      = "debug"
    namespace = kubernetes_namespace.diagnostics.metadata[0].name
    annotations = {
      "cert-manager.io/cluster-issuer" : "${helm_release.lets_encrypt_clusterissuers.name}-letsencrypt-prod"
      "external-dns.alpha.kubernetes.io/hostname" : local.debug_hostname
      "kubernetes.io/ingress.class" : "nginx"
    }
    labels = {
      "k8s.funkhouse.rs/purpose" = "diagnostics"
    }
  }
  spec {
    backend {
      service_name = local.debug_service_name
      service_port = 80
    }
    # TODO(cfunkhouser): Wire up a wildcard certificate for this ingress, so
    # the default backend can be served using TLS.
    tls {
      secret_name = "debug-secret"
      hosts       = [local.debug_hostname]
    }
    rule {
      # This is necessary to match the hostname using SNI, which will be
      # obsolete when we have wildcards.
      host = local.debug_hostname
      http {
        path {
          backend {
            service_name = local.debug_service_name
            service_port = 80
          }
          path = "/"
        }
      }
    }
  }
  depends_on = [helm_release.httpdumper]
}

locals {
  authdebug_hostname = "authdebug.${local.cluster_domain}"
}

resource "kubernetes_ingress" "ingress_authdebug" {
  metadata {
    name      = "authdebug"
    namespace = kubernetes_namespace.networking.metadata[0].name
    annotations = {
      "cert-manager.io/cluster-issuer"               = "${helm_release.lets_encrypt_clusterissuers.name}-letsencrypt-prod"
      "external-dns.alpha.kubernetes.io/hostname"    = local.authdebug_hostname
      "kubernetes.io/ingress.class"                  = "nginx"
      "nginx.ingress.kubernetes.io/backend-protocol" = "HTTPS"
    }
    labels = {
      "k8s.funkhouse.rs/purpose" = "diagnostics"
    }
  }
  spec {
    backend {
      service_name = "pomerium-proxy"
      service_port = 443
    }
    # TODO(cfunkhouser): Wire up a wildcard certificate for this ingress, so
    # the default backend can be served using TLS.
    tls {
      secret_name = "authdebug-secret"
      hosts       = [local.authdebug_hostname]
    }
    rule {
      # This is necessary to match the hostname using SNI, which will be
      # obsolete when we have wildcards.
      host = local.authdebug_hostname
      http {
        path {
          backend {
            service_name = "pomerium-proxy"
            service_port = 443
          }
          path = "/"
        }
      }
    }
  }
  depends_on = [helm_release.httpdumper, helm_release.pomerium]
}
