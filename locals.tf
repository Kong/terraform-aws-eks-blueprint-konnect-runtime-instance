locals {

  # Threads the sleep resource into the module to make the dependency
  cluster_endpoint  = time_sleep.this.triggers["cluster_endpoint"]
  cluster_name      = time_sleep.this.triggers["cluster_name"]
  oidc_provider_arn = time_sleep.this.triggers["oidc_provider_arn"]

  name                  = try(var.kong_config.name, "kong")
  namespace             = try(var.kong_config.namespace, "kong")
  create_namespace      = try(var.kong_config.create_namespace, true)
  chart                 = "kong"
  chart_version         = try(var.kong_config.chart_version, "2.16.5")
  repository            = try(var.kong_config.repository, "https://charts.konghq.com")
  values                = try(var.kong_config.values, [])
  service_account       = try(var.kong_config.service_account, "kong-sa")
  cluster_dns           = try(var.kong_config.cluster_dns, null)
  telemetry_dns         = try(var.kong_config.telemetry_dns, null)
  cert_secret_name      = try(var.kong_config.cert_secret_name, null)
  key_secret_name       = try(var.kong_config.key_secret_name, null)
  kong_external_secrets = try(var.kong_config.kong_external_secrets, "kong-cluster-cert")
  secret_volume_length  = try(length(yamldecode(var.kong_config.values[0])["secretVolumes"]), 0)
  create_kubernetes_service_account = try(var.kong_config.create_kubernetes_service_account, true)

  create_role                   = try(var.kong_config.create_role, true)
  role_name                     = try(var.kong_config.role_name, "kong")
  role_name_use_prefix          = try(var.kong_config.role_name_use_prefix, true)
  role_path                     = try(var.kong_config.role_path, "/")
  role_permissions_boundary_arn = lookup(var.kong_config, "role_permissions_boundary_arn", null)
  role_description              = try(var.kong_config.role_description, "IRSA for external-secrets operator")
  role_policies                 = lookup(var.kong_config, "role_policies", {})
  create_policy                 = try(var.kong_config.create_policy, false)

  set_values = [
    {
      name  = "ingressController.installCRDs"
      value = false
    },
    {
      name  = "deployment.serviceAccount.create"
      value = false
    },
    {
      name  = "deployment.serviceAccount.name"
      value = local.service_account
    },
    {
      name  = "env.database"
      value = "off"
    },
    {
      name  = "env.cluster_cert"
      value = "/etc/secrets/${local.kong_external_secrets}/kong_cert"
    },
    {
      name  = "env.cluster_cert_key"
      value = "/etc/secrets/${local.kong_external_secrets}/kong_key"
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

