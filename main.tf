variable "cloudflare_token" {
  type        = string
  description = "CloudFlare API Token. Needed for ExternalDNS."
}

variable "cluster_purpose" {
  type        = string
  description = "Purpose for the cluster (dev, prototyping, prod, etc)."
  default     = "prototyping"
}

variable "cluster_version" {
  type        = string
  description = "DigitalOcean Kubernetes version. Possible values from `doctl kubernetes options versions`"
  default     = "1.19.3-do.0"
}

variable "do_token" {
  type        = string
  description = "DigitalOcean API Token."
}

variable "do_region" {
  type        = string
  description = "DigitalOcean Region in which to create cluster."
  default     = "nyc1"
}

terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "2.0.2"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "1.3.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "1.13.3"
    }
    # kubernetes-alpha = {
    #   source  = "hashicorp/kubernetes-alpha"
    #   version = "0.2.1"
    # }
  }
  backend "s3" {
    endpoint                    = "https://s3.us-west-002.backblazeb2.com"
    bucket                      = "funkhouse-rs-tf-state"
    key                         = "terraform.tfstate"
    region                      = "us-east-1"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
  }
}

provider "digitalocean" {
  token = var.do_token
}

provider "helm" {
  kubernetes {
    load_config_file = false
    host             = digitalocean_kubernetes_cluster.funkhouse_rs_cluster.endpoint
    token            = digitalocean_kubernetes_cluster.funkhouse_rs_cluster.kube_config[0].token
    cluster_ca_certificate = base64decode(
      digitalocean_kubernetes_cluster.funkhouse_rs_cluster.kube_config[0].cluster_ca_certificate
    )
  }
}

provider "kubernetes" {
  load_config_file = false
  host             = digitalocean_kubernetes_cluster.funkhouse_rs_cluster.endpoint
  token            = digitalocean_kubernetes_cluster.funkhouse_rs_cluster.kube_config[0].token
  cluster_ca_certificate = base64decode(
    digitalocean_kubernetes_cluster.funkhouse_rs_cluster.kube_config[0].cluster_ca_certificate
  )
}

# The following is the experimental kubernetes-alpha provider configuration,
# which appears to not work with DigitalOcean at this time.

# provider "kubernetes-alpha" {
#   host             = digitalocean_kubernetes_cluster.funkhouse_rs_cluster.endpoint
#   token            = digitalocean_kubernetes_cluster.funkhouse_rs_cluster.kube_config[0].token
#   cluster_ca_certificate = base64decode(
#     digitalocean_kubernetes_cluster.funkhouse_rs_cluster.kube_config[0].cluster_ca_certificate
#   )
# }