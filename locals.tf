locals {
  name                 = "kong"
  namespace            = try(var.helm_config.namespace, "kong")
  service_account      = try(var.helm_config.service_account, "kong-sa")
  cluster_dns          = try(var.helm_config.cluster_dns, null)
  telemetry_dns        = try(var.helm_config.telemetry_dns, null)
  cert_secret_name     = try(var.helm_config.cert_secret_name, null)
  key_secret_name      = try(var.helm_config.key_secret_name, null)
  kong_external_secrets     = try(var.helm_config.kong_external_secrets, "kong-cluster-cert")
  secret_volume_length = try(length(yamldecode(var.helm_config.values[0])["secretVolumes"]), 0)
  image_tag           = try((yamldecode(var.helm_config.values[0])["image"]["tag"]), "3.2.1.0")

  eks_oidc_issuer_url  = var.eks_oidc_provider != null ? var.eks_oidc_provider : replace(data.aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer, "https://", "")
  eks_cluster_endpoint = var.eks_cluster_endpoint != null ? var.eks_cluster_endpoint : data.aws_eks_cluster.eks_cluster.endpoint
  eks_cluster_version  = var.eks_cluster_version != null ? var.eks_cluster_version : data.aws_eks_cluster.eks_cluster.version

  default_helm_config = {

    name             = local.name
    chart            = local.name
    repository       = "https://charts.konghq.com"
    version          = "2.16.5"
    namespace        = local.namespace
    create_namespace = true
    values           = local.default_helm_values

    service_account      = local.service_account
    cluster_dns          = local.cluster_dns
    telemetry_dns        = local.telemetry_dns
    cert_secret_name     = local.cert_secret_name
    key_secret_name      = local.key_secret_name
    kong_external_secrets     = local.kong_external_secrets


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
    },
    {
      name = "image.tag"
      value = local.image_tag
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
  addon_context = {
    aws_caller_identity_account_id = data.aws_caller_identity.current.account_id
    aws_caller_identity_arn        = data.aws_caller_identity.current.arn
    aws_eks_cluster_endpoint       = local.eks_cluster_endpoint
    aws_partition_id               = data.aws_partition.current.partition
    aws_region_name                = data.aws_region.current.name
    eks_cluster_id                 = data.aws_eks_cluster.eks_cluster.id
    eks_oidc_issuer_url            = local.eks_oidc_issuer_url
    eks_oidc_provider_arn          = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.eks_oidc_issuer_url}"
    tags                           = var.tags
  }
}


data "aws_kms_alias" "secret_manager" {
  name = "alias/aws/secretsmanager"
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
        "arn:aws:secretsmanager:${local.addon_context.aws_region_name}:${local.addon_context.aws_caller_identity_account_id}:secret:${local.cert_secret_name}-*",
        "arn:aws:secretsmanager:${local.addon_context.aws_region_name}:${local.addon_context.aws_caller_identity_account_id}:secret:${local.key_secret_name}-*"
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
