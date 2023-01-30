 # <-------- IAM Node for worker node -------->

resource "aws_iam_role" "workernodes" {
  name = "eks-node-group"

  assume_role_policy = jsonencode({
   Statement = [{
    Action = "sts:AssumeRole"
    Effect = "Allow"
    Principal = {
     Service = "ec2.amazonaws.com"
    }
   }]
   Version = "2012-10-17"
  })
 }

 resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role    = aws_iam_role.workernodes.name
 }

 resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role    = aws_iam_role.workernodes.name
 }

 resource "aws_iam_role_policy_attachment" "EC2InstanceProfileForImageBuilderECRContainerBuilds" {
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"
  role    = aws_iam_role.workernodes.name
 }

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
 policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
 role    = aws_iam_role.workernodes.name
}


 # <-------- Security group for node groups -------->

resource "aws_security_group" "node-group-sg" {
  name        = "IN-Cygnet-PT-EKSnode-SG"
  description = "Security group for all nodes in the cluster"
  vpc_id      = data.aws_vpc.pt_vpc.id

  egress {
   from_port   = 0
   to_port     = 0
   protocol    = "all"
   cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
   from_port   = 0
   to_port     = 0
   protocol    = "all"
   ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
   description = "All SSH access to nodes"
   from_port   = 22
   to_port     = 22
   protocol    = "tcp"
   cidr_blocks = ["10.0.0.0/18"]
  }
  tags = {
   Name = "IN-Cygnet-PT-EKSnode-SG"
  }
}

resource "aws_security_group_rule" "node-group-sg-rule-one" {
   description = "Allow pods running extension API on port 443 to receive communication from cluster control plane"
   from_port   = 443
   to_port     = 443
   protocol    = "tcp"
   security_group_id = aws_security_group.node-group-sg.id
   source_security_group_id = aws_security_group.pt-cluster-additional-sg.id
   type = "ingress"
}

resource "aws_security_group_rule" "node-group-sg-rule-two" {
   description = "All nodes to communicate each other"
   from_port   = 0
   to_port     = 0
   protocol    = "all"
   security_group_id = aws_security_group.node-group-sg.id
   source_security_group_id = aws_security_group.node-group-sg.id
   type = "ingress"
}

resource "aws_security_group_rule" "node-group-sg-rule-three" {
   description = "Allow worker kubelets and pods to receive communication from the cluster control plane SG"
   from_port   = 1025
   to_port     = 65535
   protocol    = "tcp"
   security_group_id = aws_security_group.node-group-sg.id
   source_security_group_id = aws_security_group.pt-cluster-additional-sg.id
   type = "ingress"
 }

 resource "aws_eks_node_group" "worker-node-group" {
  cluster_name  = aws_eks_cluster.pt-eks-cluster.name
  node_group_name = "IN-Cygnet-PT-EKS-Node-CPU"
  node_role_arn  = aws_iam_role.workernodes.arn
  subnet_ids   = [var.subnet_id_1, var.subnet_id_2,var.subnet_id_3]
  capacity_type  = "ON_DEMAND"
  instance_types = ["c5a.large"]

  scaling_config {
   desired_size = 2
   max_size   = 4
   min_size   = 2
  }

  depends_on = [
   aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
   aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
   aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
 }
