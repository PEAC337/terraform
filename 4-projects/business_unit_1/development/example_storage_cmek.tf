module "env_secrets" {
  source                      = "terraform-google-modules/project-factory/google"
  version                     = "~> 10.1"
  random_project_id           = "true"
  impersonate_service_account = var.terraform_service_account
  default_service_account     = "deprivilege"
  name                        = "${var.project_prefix}-${var.environment_code}-secrets"
  org_id                      = var.org_id
  billing_account             = var.billing_account
  folder_id                   = data.google_active_folder.env.name
  disable_services_on_destroy = false
  activate_apis               = ["logging.googleapis.com", "secretmanager.googleapis.com", "cloudkms.googleapis.com"]

  labels = {
    environment       = var.env
    application_name  = "env-secrets-new"
    billing_code      = "1234"
    primary_contact   = "example1"
    secondary_contact = "example2"
    business_code     = "abcd"
    env_code          = var.environment_code
  }
  budget_alert_pubsub_topic   = var.secret_project_alert_pubsub_topic
  budget_alert_spent_percents = var.secret_project_alert_spent_percents
  budget_amount = var.secret_project_budget_amount
}

resource "google_kms_key_ring" "keyring" {
  name     = "keyring-example"
  location = "global"
  project = module.env_secrets.project_id  # lives in new project completely
}
resource "google_kms_crypto_key" "key" {
  name            = "crypto-key-example"
  key_ring        = google_kms_key_ring.keyring.id
  lifecycle {
    prevent_destroy = true
  }
}

data "google_storage_project_service_account" "gcs_account" {
}

data "google_iam_policy" "admin" {
  binding {
    role = "roles/cloudkms.cryptoKeyEncrypter"

    members = [
      "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"
    ]
  }
}

resource "google_kms_crypto_key_iam_policy" "crypto_key" {
  crypto_key_id = google_kms_crypto_key.key.id
  policy_data = data.google_iam_policy.admin.policy_data
}


resource "google_storage_bucket" "bucket" {
  name                        = "cmek-encrypted-bucket"
  project                     = var.base_shared_vpc_project
  encryption {
    default_kms_key_name = google_kms_crypto_key.key.id
    }
  depends_on = [google_kms_crypto_key_iam_policy.crypto_key]
}



