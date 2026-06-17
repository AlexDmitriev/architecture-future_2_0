# Example backend config for local runs.
# Copy to backend-config.hcl, fill values, then:
#   terraform init -backend-config=backend-config.hcl -reconfigure
#
# Credentials are NOT stored here — export AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY.

bucket = "terraform-state-bucket"
key    = "dev/terraform.tfstate"
region = "ru-central1"

# Yandex Object Storage example:
# endpoint                    = "https://storage.yandexcloud.net"
# skip_region_validation      = true
# skip_credentials_validation = true
# skip_metadata_api_check     = true
# skip_requesting_account_id  = true

# MinIO example:
# endpoint       = "https://minio.example.com"
# use_path_style = true
# skip_region_validation      = true
# skip_credentials_validation = true
# skip_metadata_api_check     = true
# skip_requesting_account_id  = true

# AWS S3 example: omit endpoint and skip_* options, use a real AWS region.
