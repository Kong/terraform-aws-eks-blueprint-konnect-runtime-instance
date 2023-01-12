module "helm_addon" {
  source            = "github.com/aws-ia/terraform-aws-eks-blueprints/modules/kubernetes-addons/helm-addon"
  # source            = "../terraform-aws-eks-blueprints/modules/kubernetes-addons/helm-addon"
  manage_via_gitops = var.manage_via_gitops
  helm_config       = local.helm_config

  addon_context     = var.addon_context
  depends_on        = [kubectl_manifest.csi_secrets_store_crd]
}

# irsa 
module "irsa_kong" {
  source                            = "github.com/aws-ia/terraform-aws-eks-blueprints/modules/kubernetes-addons/helm-addon"
  # source                            = "../terraform-aws-eks-blueprints/modules/irsa"
  create_kubernetes_namespace       = false
  create_kubernetes_service_account = true
  kubernetes_namespace              = local.helm_config["namespace"]
  kubernetes_service_account        = local.helm_config["service_account"]
  irsa_iam_policies                 = concat([aws_iam_policy.iam_policy.arn], var.irsa_policies)
  eks_cluster_id                    = var.addon_context.eks_cluster_id
  eks_oidc_provider_arn             = var.addon_context.eks_oidc_provider_arn
  depends_on = [
    kubernetes_namespace_v1.kong_namespace
  ]
}

# for kong secret provider class for kong liscense

resource "kubectl_manifest" "csi_secrets_store_crd" {
  count = var.enable_secrets_store_csi_driver_provider_aws ? 1 : 0
  yaml_body = yamlencode({
    apiVersion = "secrets-store.csi.x-k8s.io/v1"
    kind       = "SecretProviderClass"
    metadata = {
      name      = local.helm_config["secret_provider_class"]
      namespace = local.helm_config["namespace"]
    }
    spec = {
      provider = "aws"
      secretObjects = [
        {
          secretName = local.helm_config["secret_provider_class"]
          type       = "kubernetes.io/tls"
        }
      ]

      parameters = {
        objects = <<-EOT
          - objectName : "${local.helm_config["cert_secret_name"]}"
            objectType : "secretsmanager"
          - objectName : "${local.helm_config["key_secret_name"]}"
            objectType : "secretsmanager"
        EOT
      }
    }
  })
  depends_on = [module.irsa_kong]
}



#creating namespace

resource "kubernetes_namespace_v1" "kong_namespace" {
  count = try(local.helm_config["create_namespace"], true) && local.helm_config["namespace"] != "kube-system" ? 1 : 0
  metadata {
    name = local.helm_config["namespace"]

    labels = {
      "app.kubernetes.io/managed-by" = "terraform-aws-eks-blueprints"
    }
  }
}