terraform {
  backend "s3" {
    bucket = "remote-state-tf001"
    key    = "022-route53-hosted-zone/terraform.tfstate"
    region = "eu-north-1"
  }
}
