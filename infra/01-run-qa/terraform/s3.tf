module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "qa-bucket-ds-final-2025"
  acl    = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"
  force_destroy = true

  versioning = {
    enabled = true
  }
}