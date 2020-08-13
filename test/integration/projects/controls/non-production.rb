# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

nonprod_bu1_project_base = attribute('nonprod_bu1_project_base')
nonprod_bu1_project_floating = attribute('nonprod_bu1_project_floating')
nonprod_bu1_project_restricted = attribute('nonprod_bu1_project_restricted')

nonprod_bu2_project_base = attribute('nonprod_bu2_project_base')
nonprod_bu2_project_floating = attribute('nonprod_bu2_project_floating')
nonprod_bu2_project_restricted = attribute('nonprod_bu2_project_restricted')

control 'non-production' do
  title 'gcp step 4-projects test non-production'

  describe google_project(project: nonprod_bu1_project_floating) do
    it { should exist }
    its('lifecycle_state') { should cmp 'ACTIVE' }
  end

  describe google_project(project: nonprod_bu1_project_restricted) do
    it { should exist }
    its('lifecycle_state') { should cmp 'ACTIVE' }
  end

  describe google_project(project: nonprod_bu1_project_base) do
    it { should exist }
    its('lifecycle_state') { should cmp 'ACTIVE' }
  end

  describe google_project(project: nonprod_bu2_project_floating) do
    it { should exist }
    its('lifecycle_state') { should cmp 'ACTIVE' }
  end

  describe google_project(project: nonprod_bu2_project_restricted) do
    it { should exist }
    its('lifecycle_state') { should cmp 'ACTIVE' }
  end

  describe google_project(project: nonprod_bu2_project_base) do
    it { should exist }
    its('lifecycle_state') { should cmp 'ACTIVE' }
  end
end
