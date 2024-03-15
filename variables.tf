variable "oidc_provider_client_id_list" {
  type        = list(string)
  default     = ["aws.workload.identity"]
  description = "The audience value(s) to use in run identity tokens. Defaults to aws.workload.identity, but if your OIDC provider uses something different, set it here"
}

variable "tfc_organization_name" {
  type        = string
  description = "The name of your Terraform Cloud organization"
  default     = "hashi-strawb-workshop"
}
