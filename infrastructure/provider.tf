# provider
provider "aws" {
  version = "~> 2.0"
  region = "${var.aws_region}"
}

resource "aws_instance" "dev" {
  ami = "${var.image_name}"

}
