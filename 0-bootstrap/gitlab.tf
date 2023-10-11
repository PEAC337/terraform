/**
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  cicd_project_id = module.gitlab_cicd.project_id

  wif_sa_cicd_project = {
    "bootstrap" = [
      "roles/iam.workloadIdentityPoolAdmin",
    ],
  }

  gl_config = {
    "bootstrap" = var.gl_repos.bootstrap,
    "org"       = var.gl_repos.organization,
    "env"       = var.gl_repos.environments,
    "net"       = var.gl_repos.networks,
    "proj"      = var.gl_repos.projects,
  }

  sa_mapping = {
    for k, v in local.gl_config : k => {
      sa_name   = google_service_account.terraform-env-sa[k].name
      attribute = "attribute.project_path/${var.gl_repos.owner}/${v}"
    }
  }

  common_vars = {
    "PROJECT_ID" : module.gitlab_cicd.project_id,
    "WIF_PROVIDER_NAME" : module.gitlab_oidc.provider_name,
    "TF_BACKEND" : module.seed_bootstrap.gcs_bucket_tfstate,
    "TF_VAR_gitlab_token" : var.gitlab_token,
  }

  vars_list = flatten([
    for k, v in local.gl_config : [
      for name, value in local.common_vars : {
        config     = k
        name       = name
        value      = value
        repository = v
      }
    ]
  ])

  sa_vars = [for k, v in local.gl_config : {
    config     = k
    name       = "SERVICE_ACCOUNT_EMAIL"
    value      = google_service_account.terraform-env-sa[k].email
    repository = v
    }
  ]

  gl_vars = { for v in concat(local.sa_vars, local.vars_list) : "${v.config}.${v.name}" => v }

}

provider "gitlab" {
  token = var.gitlab_token
}

module "gitlab_cicd" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 12.0"

  name              = "${var.project_prefix}-b-cicd-wif-gl"
  random_project_id = true
  org_id            = var.org_id
  folder_id         = google_folder.bootstrap.id
  billing_account   = var.billing_account
  activate_apis = [
    "compute.googleapis.com",
    "admin.googleapis.com",
    "iam.googleapis.com",
    "billingbudgets.googleapis.com",
    "cloudbilling.googleapis.com",
    "serviceusage.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
  ]
}

module "gitlab_oidc" {
  source = "./modules/gitlab-oidc"

  project_id  = module.gitlab_cicd.project_id
  pool_id     = "foundation-pool"
  provider_id = "foundation-gl-provider"
  sa_mapping  = local.sa_mapping
}

resource "gitlab_project_variable" "variables" {
  for_each = local.gl_vars

  project   = "${var.gl_repos.owner}/${each.value.repository}"
  key       = each.value.name
  value     = each.value.value
  protected = false
  masked    = true
}

module "cicd_project_wif_iam_member" {
  source   = "./modules/parent-iam-member"
  for_each = local.wif_sa_cicd_project

  member      = "serviceAccount:${google_service_account.terraform-env-sa[each.key].email}"
  parent_type = "project"
  parent_id   = local.cicd_project_id
  roles       = each.value
}

module "gitlab_runner" {
  source = "./modules/gitlab-runner"

  repo_owner = var.repo_owner
  #gl_token = var.gitlab_token
  gitlab_token = var.gitlab_token
}