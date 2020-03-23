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
    envs = ["nonprod", "prod"]
    folder_map = { for folder in google_folder.env_folders : folder.display_name => folder.name }
}

/*******************************************************************************
    Folders
*******************************************************************************/
resource "google_folder" "parent_folder" {
  display_name = var.folder_display_name
  parent       = var.parent_folder_id
}

resource "google_folder" "env_folders" {
    for_each = toset(local.envs)
    display_name = each.value
    parent       = google_folder.parent_folder.id
}
