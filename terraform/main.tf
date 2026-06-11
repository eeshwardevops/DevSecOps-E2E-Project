module "network" {

  source = "./modules/network"

  cluster_name = var.cluster_name
  vpc_cidr     = var.vpc_cidr
}

module "iam" {

  source = "./modules/iam"

  cluster_name = var.cluster_name
}

module "eks" {

  source = "./modules/eks"

  cluster_name = var.cluster_name

  cluster_role_arn = module.iam.cluster_role_arn

  node_role_arn = module.iam.node_role_arn

  public_subnet_ids = module.network.public_subnet_ids

  private_subnet_ids = module.network.private_subnet_ids

  instance_type = var.instance_type

  desired_nodes = var.desired_nodes

  min_nodes = var.min_nodes

  max_nodes = var.max_nodes

  depends_on = [
    module.iam,
    module.network
  ]

}