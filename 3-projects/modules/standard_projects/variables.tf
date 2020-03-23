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

variable project_folder_map {
    type = map(string)
}

variable org_id {
    type = string
}

variable billing_account {
    type = string
}

variable impersonate_service_account {
    type = string
}

variable project_prefix {
    type = string
}

variable cost_centre {
    type = string
}

variable application_name { 
    type = string
}

variable activate_apis {
    type = list(string)
    default = []
}

variable subnet_allocation {

}

variable enable_networking {
    type = bool
    default = true
}

variable enable_private_dns {
    type = bool
    default = true
}

variable "domain" {
 description = "The top level domain name for the organization"
}

variable "firewall_rules" {
  description = "List of project specific firewall rules, that will be scoped to supplied service accounts. Service accounts will be created."
  default     = []
  type = list(object({
    rule_name               = string
    allow_protocol          = string
    allow_ports             = list(string)
    source_service_accounts = list(string)
    target_service_accounts = list(string)
  }))
}