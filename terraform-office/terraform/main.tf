terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "2.6.0"
    }
  }
}

provider "aws" {
  region = var.region
}


module "network" {
  source = "./network"
  region = var.region
}


module "lambda_eip_assigner" {
  source                    = "./lambda-eip-assigner"
  bastion_eip_allocation_id = module.network.bastion_eip.allocation_id
}

module "instances" {
  source  = "./instances"
  vpc_id  = module.network.vpc_id
  subnets = module.network.subnets
  eip_assigner_lambbda = {
    arn           = module.lambda_eip_assigner.arn
    function_name = module.lambda_eip_assigner.function_name
  }
}
