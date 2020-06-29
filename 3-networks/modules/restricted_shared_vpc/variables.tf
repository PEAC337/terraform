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

variable "org_id" {
  type        = string
  description = "Organization ID"
}

variable "project_id" {
  type        = string
  description = "Project ID for Restricted Shared VPC."
}

variable "project_number" {
  type        = number
  description = "Project number for Restricted Shared VPC. It is the project INSIDE the regular service perimeter."
}

variable "environment_code" {
  type        = string
  description = "A short form of the folder level resources (environment) within the Google Cloud organization."
}

variable "nat_region" {
  type        = string
  description = "Region used to create NAT cloud router."
}

variable "vpc_label" {
  type        = string
  description = "Label for VPC."
}

variable "bgp_asn_nat" {
  type        = number
  description = "BGP ASN for NAT cloud routes."
}

variable "subnets" {
  type = list(object({
    subnet_ip             = string,
    subnet_region         = string,
    subnet_private_access = string,
    subnet_flow_logs      = string,
    description           = string,
    bgp_asn               = list(number)
    secondary_ranges = list(object({
      range_label   = string,
      ip_cidr_range = string
    }))
  }))
  description = "The list of subnets being created. Includes the Secondary ranges that will be used in some of the subnets. If you don't have secondary ranges, inform an empty list 'secondary_ranges = []'"
  default     = []
}

variable "dns_enable_inbound_forwarding" {
  type        = bool
  description = "Toggle inbound query forwarding for VPC DNS."
  default     = true
}

variable "dns_enable_logging" {
  type        = bool
  description = "Toggle DNS logging for VPC DNS."
  default     = true
}

variable "private_service_cidr" {
  type        = string
  description = "CIDR range for private service networking. Used for Cloud SQL and other managed services."
}

variable "nat_num_addresses" {
  type        = number
  description = "Number of external IPs to reserve for Cloud NAT."
  default     = 2
}

variable "default_fw_rules_enabled" {
  type        = bool
  description = "Toggle creation of default firewall rules."
  default     = true
}

variable "policy_name" {
  type        = string
  description = "The access context policy's name."
}

variable "members" {
  type        = list(string)
  description = "An allowed list of members (users, service accounts). The signed-in identity originating the request must be a part of one of the provided members. If not specified, a request may come from any user (logged in/not logged in, etc.). Formats: user:{emailid}, serviceAccount:{emailid}"
}

variable "restricted_services" {
  type        = list(string)
  description = "List of services to restrict."
}
