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
  nonprod_host_project_id = data.google_projects.nonprod_host_project.projects[0].project_id
  prod_host_project_id    = data.google_projects.prod_host_project.projects[0].project_id
}

/******************************************
  VPC Host Projects
*****************************************/

data "google_projects" "nonprod_host_project" {
  filter = "labels.application_name=org-shared-vpc-nonprod"
}

data "google_projects" "prod_host_project" {
  filter = "labels.application_name=org-shared-vpc-prod"
}

/******************************************
 Shared VPCs
*****************************************/

module "shared_vpc_nonprod" {
  source               = "./modules/standard_shared_vpc"
  project_id           = local.nonprod_host_project_id
  default_region       = var.default_region
  network_name         = "shared-vpc-nonprod"
  private_service_cidr = "10.200.0.0/22"
  bgp_asn              = 64512
  subnets = [
    {
      subnet_name           = "example-subnet"
      subnet_ip             = "10.200.4.0/22"
      subnet_region         = var.default_region
      subnet_private_access = "true"
      subnet_flow_logs      = "false"
      description           = "Non prod example subnet."
    },
  ]
  secondary_ranges = {
    example-subnet = [
      {
        range_name    = "example-subnet-gke-pod"
        ip_cidr_range = "192.168.0.0/19"
      },
      {
        range_name    = "example-subnet-gke-svc"
        ip_cidr_range = "192.168.32.0/23"
      },
    ]
  }
}

module "shared_vpc_prod" {
  source               = "./modules/standard_shared_vpc"
  project_id           = local.prod_host_project_id
  default_region       = var.default_region
  network_name         = "shared-vpc-prod"
  private_service_cidr = "10.20.0.0/22"
  bgp_asn              = 64513
  subnets = [
    {
      subnet_name           = "example-subnet"
      subnet_ip             = "10.20.20.0/22"
      subnet_region         = var.default_region
      subnet_private_access = "true"
      subnet_flow_logs      = "false"
      description           = "Prod example subnet."
    },
  ]
  secondary_ranges = {
    example-subnet = [
      {
        range_name    = "example-subnet-gke-pod"
        ip_cidr_range = "192.168.96.0/19"
      },
      {
        range_name    = "example-subnet-gke-svc"
        ip_cidr_range = "192.168.128.0/23"
      },
    ]
  }
}
