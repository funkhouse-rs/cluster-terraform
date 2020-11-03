resource "digitalocean_kubernetes_cluster" "funkhouse_rs_cluster" {
  name    = "funkhouse-rs-${var.do_region}-${var.cluster_purpose}"
  region  = var.do_region
  version = var.cluster_version
  tags    = ["purpose:${var.cluster_purpose}", "terraform"]

  node_pool {
    name       = "default-pool"
    size       = "s-1vcpu-2gb"
    node_count = 2
  }
}

# Install the metrics-server. Let it live in kube-system.

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://charts.helm.sh/stable"
  chart      = "metrics-server"
  namespace  = "kube-system"
}
