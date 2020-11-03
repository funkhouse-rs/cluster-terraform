# For reasons, cert-manager appears to hate being installed in namespaces not
# named "cert-manager," so picking my battles.

resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
    labels = {
      "k8s.funkhouse.rs/purpose" = "infrastructure"
    }
  }
}

# Cert Manager

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = kubernetes_namespace.cert_manager.metadata[0].name

  set {
    name  = "installCRDs"
    value = true
  }
}

# Cert Manager relies on ClusterIssuer CRDs, which we install with our own chart
# included in this directory.

resource "helm_release" "lets_encrypt_clusterissuers" {
  name      = "lets-encrypt-clusterissuers"
  chart     = "./charts/lets-encrypt"
  namespace = kubernetes_namespace.cert_manager.metadata[0].name

  depends_on = [helm_release.cert_manager]

  set {
    name  = "email"
    value = var.lets_encrypt_email
  }
}
