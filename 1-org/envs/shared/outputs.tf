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

output "common_folder_display_name" {
  value       = google_folder.common.display_name
  description = "The common folder display name"
}

output "org_audit_logs_project_id" {
  value       = module.org_audit_logs.project_id
  description = "The org audit logs project ID"
}

output "org_billing_logs_project_id" {
  value       = module.org_billing_logs.project_id
  description = "The org billing logs project ID"
}

output "org_secrets_project_id" {
  value       = module.org_secrets.project_id
  description = "The org secrets project ID"
}

output "interconnect_project_id" {
  value       = module.interconnect.project_id
  description = "The interconnect project ID"
}

output "scc_notifications_project_id" {
  value       = module.scc_notifications.project_id
  description = "The SCC notifications project ID"
}

output "dns_hub_project_id" {
  value       = module.dns_hub.project_id
  description = "The DNS hub project ID"
}
