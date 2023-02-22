locals {
  name                 = "kong"
  service_account      = try(var.helm_config.service_account, "kong-sa")
  cluster_dns          = try(var.helm_config.cluster_dns, null)
  telemetry_dns        = try(var.helm_config.telemetry_dns, null)
  cert_secret_name     = try(var.helm_config.cert_secret_name, null)
  key_secret_name      = try(var.helm_config.key_secret_name, null)
  secretstore_name     = try(var.helm_config.secretstore_name, "kong-secretstore")
  external_secrets     = try(var.helm_config.external_secrets, "kong-external-secret")
  length_secret_volume = try(length(yamldecode(var.helm_config.values[0])["secretVolumes"]), 0)
  secret_manager_alias = try(var.helm_config.secret_manager_alias, "alias/aws/secretsmanager")

  default_helm_config = {

    name             = local.name
    chart            = local.name
    repository       = "https://charts.konghq.com"
    version          = "2.16.5"
    namespace        = local.name
    create_namespace = true
    values           = local.default_helm_values

    service_account      = local.service_account
    cluster_dns          = local.cluster_dns
    telemetry_dns        = local.telemetry_dns
    cert_secret_name     = local.cert_secret_name
    key_secret_name      = local.key_secret_name
    secretstore_name     = local.secretstore_name
    external_secrets     = local.external_secrets
    secret_manager_alias = local.secret_manager_alias


    description = "The Kong Ingress Helm Chart configuration"
  }

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
      value = "/etc/secrets/${local.external_secrets}/kong_cert"
    },
    {
      name  = "env.cluster_cert_key"
      value = "/etc/secrets/${local.external_secrets}/kong_key"
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
      name  = "secretVolumes[${local.length_secret_volume}]"
      value = local.external_secrets
    }
  ]

  default_helm_values = [templatefile("${path.module}/values.yaml", {})]

  helm_config = merge(
    local.default_helm_config,
    var.helm_config
  )

  argocd_gitops_config = {
    enable = false
  }
}

#Get Arn of KMS

data "aws_kms_alias" "secret_manager" {
  name = local.secret_manager_alias
}

#Policy for External Secrets

resource "aws_iam_policy" "kong_secretstore" {
  name_prefix = "kong_secretstore"
  policy      = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetResourcePolicy",
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
        "secretsmanager:ListSecretVersionIds"
      ],
      "Resource": [
        "arn:aws:secretsmanager:${var.addon_context.aws_region_name}:${var.addon_context.aws_caller_identity_account_id}:secret:${local.cert_secret_name}-*",
        "arn:aws:secretsmanager:${var.addon_context.aws_region_name}:${var.addon_context.aws_caller_identity_account_id}:secret:${local.key_secret_name}-*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": [
        "${data.aws_kms_alias.secret_manager.arn}"
      ]
    }
  ]
}
POLICY
}
