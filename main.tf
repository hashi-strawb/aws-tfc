terraform {
  cloud {
    organization = "hashi-strawb-workshop"

    workspaces {
      name = "bootstrap-creds"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}


module "tfc-dynamic-creds-provider" {
  source = "hashi-strawb/tfc-dynamic-creds-provider/aws"
}

# based losely on https://github.com/hashi-strawb/terraform-aws-tfc-dynamic-creds-workspace

resource "aws_iam_role" "org_role" {
  name = "tfc-${var.tfc_organization_name}"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Effect": "Allow",
     "Principal": {
       "Federated": "${module.tfc-dynamic-creds-provider.oidc_provider.arn}"
     },
     "Action": "sts:AssumeRoleWithWebIdentity",
     "Condition": {
       "StringEquals": {
         "app.terraform.io:aud": "${one(var.oidc_provider_client_id_list)}"
       },
       "StringLike": {
         "app.terraform.io:sub": "organization:${var.tfc_organization_name}:project:*:workspace:*:run_phase:*"
       }
     }
   }
 ]
}
EOF


  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess"
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "tfe_variable_set" "creds" {
  name         = "AWS Dynamic Creds"
  description  = "AWS Auth & Role details for Dynamic AWS Creds"
  organization = var.tfc_organization_name
}


resource "tfe_variable" "enable_aws_provider_auth" {
  key      = "TFC_AWS_PROVIDER_AUTH"
  value    = "true"
  category = "env"

  description = "Enable the Workload Identity integration for AWS."

  variable_set_id = tfe_variable_set.creds.id
}

resource "tfe_variable" "tfc_aws_role_arn" {
  key      = "TFC_AWS_RUN_ROLE_ARN"
  value    = aws_iam_role.org_role.arn
  category = "env"

  description = "The AWS role arn runs will use to authenticate."

  variable_set_id = tfe_variable_set.creds.id
}
