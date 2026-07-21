terraform {
  backend "s3" {
    bucket = "remote-state-tf001"
    key    = "021-terraform-plan/terraform.tfstate"
    region = "eu-north-1"
  }
}
