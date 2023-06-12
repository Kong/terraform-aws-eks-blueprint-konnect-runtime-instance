data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "time_sleep" "this" {
  create_duration = var.create_delay_duration
  triggers = {
    cluster_endpoint  = var.cluster_endpoint
    cluster_name      = var.cluster_name
    custom            = join(",", var.create_delay_dependencies)
    oidc_provider_arn = var.oidc_provider_arn
  }
}
