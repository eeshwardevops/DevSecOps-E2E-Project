resource "aws_eks_cluster" "main" {

  name     = var.cluster_name
  role_arn = var.cluster_role_arn

  version = "1.29"

  vpc_config {

    subnet_ids = concat(
      var.public_subnet_ids,
      var.private_subnet_ids
    )

    endpoint_private_access = true
    endpoint_public_access  = true
  }
}

resource "aws_eks_node_group" "main" {

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-workers"

  node_role_arn = var.node_role_arn

  subnet_ids = var.private_subnet_ids

  ami_type = "AL2023_x86_64_STANDARD"

  instance_types = [var.instance_type]

  scaling_config {
    desired_size = var.desired_nodes
    min_size     = var.min_nodes
    max_size     = var.max_nodes
  }

  depends_on = [
    aws_eks_cluster.main
  ]
}




