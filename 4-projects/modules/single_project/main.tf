/**
 * Copyright 2020 Google LLC
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
  host_network = data.google_compute_network.shared_vpc
}

module "project" {
  source                      = "terraform-google-modules/project-factory/google"
  version                     = "~> 8.1"
  random_project_id           = "true"
  impersonate_service_account = var.impersonate_service_account
  activate_apis               = var.activate_apis
  name                        = var.project_prefix
  org_id                      = var.org_id
  billing_account             = var.billing_account
  folder_id                   = var.folder_id
  skip_gcloud_download        = var.skip_gcloud_download

  shared_vpc         = local.host_network.project
  shared_vpc_subnets = local.host_network.subnetworks_self_links # Optional: To enable subnetting, to replace to "module.networking_project.subnetwork_self_link"

  vpc_service_control_attach_enabled = var.vpc_service_control_attach_enabled
  vpc_service_control_perimeter_name = var.vpc_service_control_perimeter_name

  labels = {
    environment       = var.environment
    application_name  = var.application_name
    billing_code      = var.billing_code
    primary_contact   = var.primary_contact
    secondary_contact = var.secondary_contact
    business_code     = var.business_code
    env_code          = element(split("", var.environment), 0)
    vpc_type          = var.vpc_type
  }
}

/******************************************
  Project subnets (Optional)
 *****************************************/
# module "networking_project" {
#   source = "../../modules/project_subnet"

#   default_region   = var.default_region
#   project_id       = module.project.project_id
#   application_name = var.application_name

#   enable_networking   = var.enable_networking
#   vpc_host_project_id = local.host_network.project
#   vpc_self_link       = local.host_network.self_link
#   ip_cidr_range       = var.subnet_ip_cidr_range
#   secondary_ranges    = var.subnet_secondary_ranges
# }

/******************************************
  Private DNS Management (Optional)
 *****************************************/
# module "dns" {
#   source = "../../modules/private_dns"

#   project_id            = module.project.project_id
#   enable_private_dns    = var.enable_private_dns
#   application_name      = var.application_name
#   environment           = var.environment
#   top_level_domain      = var.domain
#   shared_vpc_self_link  = local.host_network.self_link
#   shared_vpc_project_id = local.host_network.project
# }
