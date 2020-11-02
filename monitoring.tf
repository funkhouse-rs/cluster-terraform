resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      "k8s.funkhouse.rs/purpose" = "infrastructure"
    }
  }
}