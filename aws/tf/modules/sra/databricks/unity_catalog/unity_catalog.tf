// Terraform Documentation: https://registry.terraform.io/providers/databricks/databricks/latest/docs/guides/unity-catalog

// Metastore
resource "databricks_metastore" "this" {
  name          = "unity-catalog-${var.resource_prefix}"
  storage_root  = "s3://${var.uc_s3}/metastore"
  force_destroy = true
}

// Metastore Assignment
resource "databricks_metastore_assignment" "default_metastore" {
  workspace_id         = var.databricks_workspace
  metastore_id         = databricks_metastore.this.id
  default_catalog_name = "hive_metastore"
}

resource "databricks_metastore_data_access" "this" {
  metastore_id = databricks_metastore.this.id
  name         = var.uc_iam_name
  aws_iam_role {
    role_arn = var.uc_iam_arn
  }
  is_default = true
  depends_on = [
    databricks_metastore_assignment.default_metastore
  ]
}

// Storage Credential
resource "databricks_storage_credential" "external" {
  name = var.storage_credential_role_name
  aws_iam_role {
    role_arn = var.storage_credential_role_arn
  }
  depends_on = [
    databricks_metastore_assignment.default_metastore
  ]
}

// External Location
resource "databricks_external_location" "data_example" {
  name            = "external-location-example"
  url             = "s3://${var.data_bucket}/"
  credential_name = databricks_storage_credential.external.id
  skip_validation = true
  read_only       = true
  comment         = "Managed by TF"
}

// External Location Grant
resource "databricks_grants" "data_example" {
  external_location = databricks_external_location.data_example.id
  grant {
    principal  = var.data_access
    privileges = ["ALL_PRIVILEGES"]
  }
}