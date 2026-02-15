terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

provider "aws"{ 
  region = "us-east-1"
  profile = "default"
}

provider "docker" {}



resource "aws_ecs_cluster" "chatapp" {
  name = "chatapp-cluster"
}


data "aws_ecr_authorization_token" "token" {}
data "aws_caller_identity" "current" {}
