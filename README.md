# Kong Helm Chart
## Introduction 

Kong Konnect is an API lifecycle management platform designed from the ground up for the cloud native era and delivered as a service. This platform lets you build modern applications better, faster, and more securely. The management plane is hosted in the cloud by Kong, while the runtime engine, Kong Gateway — Kong’s lightweight, fast, and flexible API gateway — is managed by you within your preferred network environment.



## Helm Chart
### Instructions to use the Helm Chart

See the [Kong Helm Chart](https://github.com/Kong/charts)

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.72 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.4.1 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | >= 1.14 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.10 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.72 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | >= 1.14 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.10 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_helm_addon"></a> [helm\_addon](#module\_helm\_addon) | ../terraform-aws-eks-blueprints/modules/kubernetes-addons/helm-addon | n/a |
| <a name="module_irsa_kong"></a> [irsa\_kong](#module\_irsa\_kong) | ../terraform-aws-eks-blueprints/modules/irsa | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.iam_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [kubectl_manifest.csi_secrets_store_crd](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubernetes_namespace_v1.kong_namespace](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1) | resource |
| [aws_iam_policy_document.iam_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_addon_context"></a> [addon\_context](#input\_addon\_context) | Input configuration for the addon | <pre>object({<br>    aws_caller_identity_account_id = string<br>    aws_caller_identity_arn        = string<br>    aws_eks_cluster_endpoint       = string<br>    aws_partition_id               = string<br>    aws_region_name                = string<br>    eks_cluster_id                 = string<br>    eks_oidc_issuer_url            = string<br>    eks_oidc_provider_arn          = string<br>    tags                           = map(string)<br>  })</pre> | n/a | yes |
| <a name="input_enable_secrets_store_csi_driver_provider_aws"></a> [enable\_secrets\_store\_csi\_driver\_provider\_aws](#input\_enable\_secrets\_store\_csi\_driver\_provider\_aws) | Enable AWS CSI Secrets Store Provider | `bool` | `true` | no |
| <a name="input_helm_config"></a> [helm\_config](#input\_helm\_config) | Kong Helm Configuration | `any` | `{}` | no |
| <a name="input_irsa_policies"></a> [irsa\_policies](#input\_irsa\_policies) | Additional IAM policies for a IAM role for service accounts | `list(string)` | `[]` | no |
| <a name="input_manage_via_gitops"></a> [manage\_via\_gitops](#input\_manage\_via\_gitops) | Determines if the add-on should be managed via GitOps. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_argocd_gitops_config"></a> [argocd\_gitops\_config](#output\_argocd\_gitops\_config) | Configuration used for managing the add-on with ArgoCD |
