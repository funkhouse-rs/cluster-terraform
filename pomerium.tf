# Configuration for Pomerium.

locals {
  auth0_idp_service_account = {
    "client_id" = auth0_client.oidc_authorization_client.client_id
    "secret"    = auth0_client.oidc_authorization_client.client_secret
  }

  pomerium_values = {

    ## The image block is necessary temporarily, because the official Pomerium
    ## images do not yet include the Auth0 providers.
    ## TODO(cfunkhouser): Remove this when the changes are promoted.
    "image" = {
      "repository" = "cfunkhouser/pomerium"
      "tag"        = "20201106"
    }
    "authenticate" = {
      "idp" = {
        "provider"       = "auth0"
        "url"            = "https://${var.auth0_domain}/"
        "clientID"       = auth0_client.oidc_authentication_client.client_id
        "clientSecret"   = auth0_client.oidc_authentication_client.client_secret
        "serviceAccount" = base64encode(jsonencode(local.auth0_idp_service_account))
      }
    }
    "forwardAuth" = {
      "enabled" : true
    }
    "config" = {
      "rootDomain" = local.cluster_domain
      "policy" = [
        {
          "from"                  = "https://${local.authdebug_hostname}"
          "to"                    = "http://ingress-debug-httpdumper.diagnostics.svc.cluster.local"
          "pass_identity_headers" = true
          "allowed_domains"       = ["funkhouse.rs"]
          "preserve_host_header"  = true
        }
      ]
    }
    "ingress" = {
      "annotations" = {
        # TODO(cfunkhouser): This is clumsy and gross, fix it.
        "cert-manager.io/cluster-issuer"               = "${helm_release.lets_encrypt_clusterissuers.name}-letsencrypt-prod"
        "kubernetes.io/ingress.class"                  = "nginx"
        "nginx.ingress.kubernetes.io/backend-protocol" = "HTTPS"
        "external-dns.alpha.kubernetes.io/hostname"    = "authenticate.${local.cluster_domain},forwardauth.${local.cluster_domain}"
      }
      "secretName" = "pomerium-ingress-tls"
    }
  }
}

resource "helm_release" "pomerium" {
  name       = "pomerium"
  repository = "https://helm.pomerium.io"
  chart      = "pomerium"
  namespace  = kubernetes_namespace.networking.metadata[0].name

  values = [
    yamlencode(local.pomerium_values)
  ]
}
