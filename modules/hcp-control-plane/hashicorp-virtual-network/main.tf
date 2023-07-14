terraform {
  required_providers {
    hcp = {
      source = "hashicorp/hcp"
      version = "0.66.0"
    }
    aws = {
        source = "hashicorp/aws"
    }
  }
}

resource "hcp_hvn" "main" {
  hvn_id         = "${var.stack_name}-hvn"
  cloud_provider = "aws"
  region         = "us-east-1"
  cidr_block     = "172.25.16.0/20"
}

data "aws_vpc" "peer" {
  id = "${var.stack_name}-vpc"
}


resource "hcp_aws_network_peering" "hashistack" {
  hvn_id          = hcp_hvn.main.hvn_id
  peering_id      = var.stack_name
  peer_vpc_id     = aws_vpc.peer.id
  peer_account_id = aws_vpc.peer.owner_id
  peer_vpc_region = data.aws_arn.peer.region
}

resource "hcp_hvn_route" "hvn-to-aws" {
  hvn_link         = hcp_hvn.main.self_link
  hvn_route_id     = "hvn-to-aws"
  destination_cidr = aws_vpc.peer.cidr
  target_link      = hcp_aws_network_peering.hashistack.self_link
}

resource "aws_vpc_peering_connection_accepter" "peer" {
  vpc_peering_connection_id = hcp_aws_network_peering.hashistack.provider_peering_id
  auto_accept               = true
}