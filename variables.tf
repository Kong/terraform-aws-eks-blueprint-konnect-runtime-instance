variable "helm_config" {
  description = "Kong Helm Configuration"
  type        = any
  default     = {}
}

variable "manage_via_gitops" {
  description = "Determines if the add-on should be managed via GitOps."
  type        = bool
  default     = false
}

variable "addon_context" {
  description = "Input configuration for the addon"
  type = object({
    aws_caller_identity_account_id = string
    aws_caller_identity_arn        = string
    aws_eks_cluster_endpoint       = string
    aws_partition_id               = string
    aws_region_name                = string
    eks_cluster_id                 = string
    eks_oidc_issuer_url            = string
    eks_oidc_provider_arn          = string
    tags                           = map(string)
  })
}

variable "irsa_policies" {
  description = "Additional IAM policies for a IAM role for service accounts"
  type        = list(string)
  default     = []
}

variable "enable_secrets_store_csi_driver_provider_aws" {
  type        = bool
  default     = true
  description = "Enable AWS CSI Secrets Store Provider"
}