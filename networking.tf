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

# We make use of the Pomerium authenticating proxy, and back it with Auth0.
# Here, we create two Auth0 applications (called "clients" in the API):
# The first will handle authentication, and the second will have a grant for the
# management API to retrieve roles, and will be used for authorization.

locals {
  auth_hostname           = "authenticate.${local.cluster_domain}"
  auth_service_url        = "https://${local.auth_hostname}/"
  management_api_audience = "https://${var.auth0_domain}/api/v2/"
}

resource "auth0_client" "oidc_authentication_client" {
  name               = "${local.cluster_domain} Cluster Authentication"
  description        = "Cluster ${local.cluster_domain} OIDC Authentication Client"
  app_type           = "regular_web"
  initiate_login_uri = local.auth_service_url
  callbacks          = ["${local.auth_service_url}oauth2/callback"]
  jwt_configuration {
    alg = "RS256"
  }
}

resource "auth0_client" "oidc_authorization_client" {
  name        = "${local.cluster_domain} Cluster Authorization"
  description = "Cluster ${local.cluster_domain} OIDC Authorization Client"
  app_type    = "non_interactive"
  jwt_configuration {
    alg = "RS256"
  }
}

resource "auth0_client_grant" "oidc_authorization_management_api_client_grant" {
  client_id = auth0_client.oidc_authorization_client.id
  audience  = local.management_api_audience
  scope     = ["read:roles", "read:role_members"]
}

# See pomerium.tf for the actual Pomerium configuration.
