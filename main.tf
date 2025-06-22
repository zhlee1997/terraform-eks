# VPC and Networking
resource "aws_vpc" "vpc_inventory_prod" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_subnet" "subnet_1_inventory_prod" {
  vpc_id                  = aws_vpc.vpc_inventory_prod.id
  cidr_block              = "10.0.0.0/20"
  availability_zone       = "ap-southeast-5a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "subnet_2_inventory_prod" {
  vpc_id                  = aws_vpc.vpc_inventory_prod.id
  cidr_block              = "10.0.16.0/20"
  availability_zone       = "ap-southeast-5b"
  map_public_ip_on_launch = true
}


resource "aws_subnet" "subnet_3_inventory_prod" {
  vpc_id                  = aws_vpc.vpc_inventory_prod.id
  cidr_block              = "10.0.32.0/20"
  availability_zone       = "ap-southeast-5c"
  map_public_ip_on_launch = true
}


resource "aws_internet_gateway" "ig_inventory_prod" {
  vpc_id = aws_vpc.vpc_inventory_prod.id
}

resource "aws_route_table" "rt_inventory_prod" {
  vpc_id = aws_vpc.vpc_inventory_prod.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig_inventory_prod.id
  }

  route {
    cidr_block = "10.0.0.0/16"
    gateway_id = "local"
  }
}

resource "aws_route_table_association" "rta_subnet_1_inventory_prod" {
  subnet_id      = aws_subnet.subnet_1_inventory_prod.id
  route_table_id = aws_route_table.rt_inventory_prod.id
}

resource "aws_route_table_association" "rta_subnet_2_inventory_prod" {
  subnet_id      = aws_subnet.subnet_2_inventory_prod.id
  route_table_id = aws_route_table.rt_inventory_prod.id
}

resource "aws_route_table_association" "rta_subnet_3_inventory_prod" {
  subnet_id      = aws_subnet.subnet_3_inventory_prod.id
  route_table_id = aws_route_table.rt_inventory_prod.id
}

# EKS Cluster
module "eks_cluster" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  authentication_mode = "API_AND_CONFIG_MAP"

  cluster_name    = "my-cluster-eks"
  cluster_version = "1.32"

  cluster_endpoint_public_access = true

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  vpc_id                   = aws_vpc.vpc_inventory_prod.id
  subnet_ids               = [aws_subnet.subnet_1_inventory_prod.id, aws_subnet.subnet_2_inventory_prod.id, aws_subnet.subnet_3_inventory_prod.id]
  control_plane_subnet_ids = [aws_subnet.subnet_1_inventory_prod.id, aws_subnet.subnet_2_inventory_prod.id, aws_subnet.subnet_3_inventory_prod.id]

  eks_managed_node_groups = {
    green = {
      min_size       = 2
      max_size       = 3
      desired_size   = 2
      instance_types = ["t3.micro"]

      # Enable spot instances for cost savings
      capacity_type = "SPOT"
    }

    cluster_addons = {
      coredns            = {}
      kube-proxy         = {}
      vpc-cni            = {}
      aws-ebs-csi-driver = {}
    }

    tags = {
      Environment = "production"
      Project     = "inventory"
    }
  }
}
