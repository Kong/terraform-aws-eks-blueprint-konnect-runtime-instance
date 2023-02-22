module "helm_addon" {
  #  source            = "github.com/aws-ia/terraform-aws-eks-blueprints/modules/kubernetes-addons/helm-addon"
  source            = "../terraform-aws-eks-blueprints/modules/kubernetes-addons/helm-addon"
  manage_via_gitops = var.manage_via_gitops
  helm_config       = local.helm_config
  set_values        = local.set_values
  addon_context     = var.addon_context
  depends_on        = [kubectl_manifest.secret]
}

# irsa 
module "irsa_kong" {
  source                            = "../terraform-aws-eks-blueprints/modules/irsa"
  create_kubernetes_namespace       = false
  create_kubernetes_service_account = true
  kubernetes_namespace              = local.helm_config["namespace"]
  kubernetes_service_account        = local.helm_config["service_account"]
  irsa_iam_policies                 = [aws_iam_policy.kong_secretstore.arn]
  eks_cluster_id                    = var.addon_context.eks_cluster_id
  eks_oidc_provider_arn             = var.addon_context.eks_oidc_provider_arn
  depends_on = [
    kubernetes_namespace_v1.kong_namespace
  ]
}



resource "kubectl_manifest" "secretstore" {
  yaml_body  = <<YAML
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: ${local.secretstore_name}
  namespace: ${local.helm_config["namespace"]}
spec:
  provider:
    aws:
      service: SecretsManager
      region: ${var.addon_context.aws_region_name}
      auth:
        jwt:
          serviceAccountRef:
            name: ${local.helm_config["service_account"]}
YAML
  depends_on = [module.irsa_kong]
}


resource "kubectl_manifest" "secret" {
  count      = var.enable_external_secrets ? 1 : 0
  yaml_body  = <<YAML
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: ${local.external_secrets}
  namespace: ${local.helm_config["namespace"]}
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: ${local.secretstore_name}
    kind: SecretStore
  target:
    name: ${local.external_secrets}
    creationPolicy: Owner
    template:
      type: kubernetes.io/tls
  data:
  - secretKey: kong_cert
    remoteRef:
      key: ${local.cert_secret_name}
  - secretKey: kong_key
    remoteRef:
      key: ${local.key_secret_name}
YAML
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