provider "archive" {}

provider "aws" {
  version = ">=1.20"

  region = "${var.region}"
}

provider "template" {}
