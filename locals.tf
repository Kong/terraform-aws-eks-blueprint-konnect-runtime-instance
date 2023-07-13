locals {

  # Threads the sleep resource into the module to make the dependency
  cluster_endpoint  = time_sleep.this.triggers["cluster_endpoint"]
  cluster_name      = time_sleep.this.triggers["cluster_name"]
  oidc_provider_arn = time_sleep.this.triggers["oidc_provider_arn"]

  name                  = try(var.kong_config.name, "kong")
  namespace             = try(var.kong_config.namespace, "kong")
  create_namespace      = try(var.kong_config.create_namespace, true)
  chart                 = "kong"
  chart_version         = try(var.kong_config.chart_version, null)
  repository            = try(var.kong_config.repository, "https://charts.konghq.com")
  values                = try(var.kong_config.values, [])

  cluster_dns           = try(var.kong_config.cluster_dns, null)
  telemetry_dns         = try(var.kong_config.telemetry_dns, null)
  cert_secret_name      = try(var.kong_config.cert_secret_name, null)
  key_secret_name       = try(var.kong_config.key_secret_name, null)
  kong_external_secrets = try(var.kong_config.kong_external_secrets, "konnect-client-tls")
  tls_cert                                            = "tls.crt"
  tls_key                                             = "tls.key"
  secret_volume_length  = try(length(yamldecode(var.kong_config.values[0])["secretVolumes"]), 0)
  external_secret_service_account_name                = "external-secret-irsa"
  external_secrets_irsa_role_name                     = "external-secret-irsa"
  external_secrets_irsa_role_name_use_prefix          = true
  external_secrets_irsa_role_path                     = "/"
  external_secrets_irsa_role_permissions_boundary_arn = null
  external_secrets_irsa_role_description              = "IRSA for external-secrets operator"
  external_secrets_irsa_role_policies                 = {}


  set_values = [
    {
      name  = "ingressController.installCRDs"
      value = false
    },
    {
      name  = "deployment.serviceAccount.create"
      value = false
    },
    # {
    #   name  = "deployment.serviceAccount.name"
    #   value = local.service_account
    # },
    {
      name  = "env.database"
      value = "off"
    },
    {
      name  = "env.cluster_cert"
      value = "/etc/secrets/${local.kong_external_secrets}/${local.tls_cert}"
    },
    {
      name  = "env.cluster_cert_key"
      value = "/etc/secrets/${local.kong_external_secrets}/${local.tls_key}"
    },
    {
      name  = "env.lua_ssl_trusted_certificate"
      value = "system"
    },
    {
      name  = "env.konnect_mode"
      value = "on"
    },
    {
      name  = "env.vitals"
      value = "off"
    },
    {
      name  = "env.cluster_mtls"
      value = "pki"
    },
    {
      name  = "env.cluster_control_plane"
      value = "${local.cluster_dns}:443"
    },
    {
      name  = "env.cluster_server_name"
      value = "${local.cluster_dns}"
    },
    {
      name  = "env.cluster_telemetry_endpoint"
      value = "${local.telemetry_dns}:443"
    },
    {
      name  = "env.cluster_telemetry_server_name"
      value = "${local.telemetry_dns}"
    },
    {
      name  = "env.role"
      value = "data_plane"
    },
    {
      name  = "ingressController.enabled"
      value = false
    },
    {
      name  = "secretVolumes[${local.secret_volume_length}]"
      value = local.kong_external_secrets
    },
    {
      name  = "image.repository"
      value = "kong/kong-gateway"
    }
  ]
}

