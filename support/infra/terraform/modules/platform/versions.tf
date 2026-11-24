terraform {
  required_version = "~> 1.17.0"
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 6.73"
      configuration_aliases = [aws.us_east_1]
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
}
