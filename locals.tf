locals {
  name                  = "kong-konnect"
  service_account       = try(var.helm_config.service_account, "kong-sa")
  secret_provider_class = try(var.helm_config.secret_provider_class, "kong-secret-provider-class")
  cluster_dns           = try(var.helm_config.cluster_dns, null)
  telemetry_dns         = try(var.helm_config.telemetry_dns, null)
  cert_secret_name      = try(var.helm_config.cert_secret_name, null)
  key_secret_name       = try(var.helm_config.key_secret_name, null)


  default_helm_config = {

    name             = local.name
    chart            = local.name
    repository       = "https://charts.konghq.com"
    version          = "2.13.1"
    namespace        = local.name
    create_namespace = true
    values           = local.default_helm_values

    service_account       = local.service_account
    secret_provider_class = local.secret_provider_class
    cluster_dns           = local.cluster_dns
    telemetry_dns         = local.telemetry_dns
    cert_secret_name      = local.cert_secret_name
    key_secret_name       = local.key_secret_name


    set = [
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
      }
    ]
    description = "The Kong Ingress Helm Chart configuration"
  }

  default_helm_values = [templatefile("${path.module}/values.yaml", {
    secretProviderClass = local.secret_provider_class
    clusterDns          = local.cluster_dns
    telementryDns       = local.telemetry_dns
    certSecretName      = local.cert_secret_name
    keySecretName       = local.key_secret_name

  })]

  helm_config = merge(
    local.default_helm_config,
    var.helm_config
  )



  argocd_gitops_config = {
    enable = false
  }
}


resource "aws_iam_policy" "iam_policy" {
  name        = "${var.addon_context.eks_cluster_id}-kong"
  description = "IAM Policy for Kong"
  policy      = data.aws_iam_policy_document.iam_policy.json
}

data "aws_iam_policy_document" "iam_policy" {
  statement {
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue"
    ]
    resources = [
      "arn:aws:secretsmanager:${var.addon_context.aws_region_name}:${var.addon_context.aws_caller_identity_account_id}:secret:${local.cert_secret_name}-*",
      "arn:aws:secretsmanager:${var.addon_context.aws_region_name}:${var.addon_context.aws_caller_identity_account_id}:secret:${local.key_secret_name}-*"
    ]

  }
}
