module "website_s3_bucket" {
  source = "./Modules/aws-s3-static-website-bucket"
  bucket_name = "exambucket-0-0-001"
}
