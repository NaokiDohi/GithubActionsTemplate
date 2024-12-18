terraform {
  required_version = "~>1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.66.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "2.4.2"
    }
    # https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
  }

  cloud {
    organization = "medurance"
    hostname     = "app.terraform.io"

    workspaces {
      name = "tatsumi-tax-rag"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-northeast-1"
  default_tags {
    tags = {
      Operator  = "naoki.dohi"
      Terraform = true
      Projects  = "TatsumiTaxRag"
    }
  }
}

provider "docker" {
  registry_auth {
    address  = module.ecr.proxy_endpoint
    username = module.ecr.user_name
    password = module.ecr.password
  }
  host = "unix:///Users/${var.username}/.docker/run/docker.sock"
}
