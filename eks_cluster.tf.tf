terraform {
 required_providers {
  aws = {
   source = "hashicorp/aws"
  }
 }
}

resource "aws_iam_role" "eks-iam-role" {
 name = "IN-Cygnet-PT-Cluster-Staging-eks-iam-role"
 assume_role_policy = <<EOF
 {
  "Version": "2012-10-17",
  "Statement": [
    {
     "Effect": "Allow",
     "Principal": {
      "Service": "eks.amazonaws.com"
     },
    "Action": "sts:AssumeRole"
    }
  ]
 }
EOF
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
 policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
 role    = aws_iam_role.eks-iam-role.name
}
resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly-EKS" {
 policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
 role    = aws_iam_role.eks-iam-role.name
}

# <-------- Security group for Default cluster -------->


resource "aws_security_group_rule" "sg_rule1" {
 cidr_blocks       = ["0.0.0.0/0"]
 from_port         = 0
 to_port           = 0
 protocol          = "all"
 security_group_id = data.aws_security_group.selected.id
 type              = "ingress"
}
resource "aws_security_group_rule" "sg_rule2" {
 ipv6_cidr_blocks = ["::/0"]
 from_port         = 0
 to_port           = 0
 protocol          = "all"
 security_group_id = data.aws_security_group.selected.id
 type              = "egress"
}


# <-------- Additional Security group for cluster -------->

resource "aws_security_group" "pt-cluster-additional-sg" {
  name        = "IN-Cygnet-PT-Staging-EKSCluster-Controlplane-SG"
  description = "Security group for the elastic network interface between the controlplane and the worker node"
  vpc_id      = data.aws_vpc.pt_vpc.id
  tags = {
    Name = "IN-Cygnet-PT-Staging-EKSCluster-Controlplane-SG"
   }
 }

resource "aws_security_group_rule" "pt-cluster-sg-rule-one" {
    description = "Allow the cluster controlplane to communicate with pods running extension API server on port 443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    type = "egress"
    #self = "true"
    #security_group_id = aws_security_group.node-group-sg.id
    security_group_id = aws_security_group.pt-cluster-additional-sg.id
    source_security_group_id = aws_security_group.node-group-sg.id
}
resource "aws_security_group_rule" "pt-cluster-sg-rule-two" {
    description = "Allow outgoing kubelet traffic (tcp/10250) to worker node"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    type = "egress"
    #self = "true"
    #security_group_id = aws_security_group.node-group-sg.id
    security_group_id = aws_security_group.pt-cluster-additional-sg.id
    source_security_group_id = aws_security_group.node-group-sg.id
}
resource "aws_security_group_rule" "pt-cluster-sg-rule-three" {
    description = "Allow the cluster control plane to communicate with worker kubelet and pods"
    from_port   = 1025
    to_port     = 65535
    protocol    = "tcp"
    type = "egress"
    #self = "true"
    #security_group_id = aws_security_group.node-group-sg.id
    security_group_id = aws_security_group.pt-cluster-additional-sg.id
    source_security_group_id = aws_security_group.node-group-sg.id
}
resource "aws_security_group_rule" "pt-cluster-sg-rule-four" {
  description       = "Allow pods to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  #security_group_id = aws_security_group.node-group-sg.id
  security_group_id = aws_security_group.pt-cluster-additional-sg.id
  source_security_group_id = aws_security_group.node-group-sg.id
  to_port           = 443
  #self = "true"
  type = "ingress"
 }

 # <-------- AWS EKS Cluster configuration  -------->


resource "aws_eks_cluster" "pt-eks-cluster" {
 name = "IN-Cygnet-PT-EKSCluster-Staging"
 role_arn = aws_iam_role.eks-iam-role.arn

 vpc_config {
  security_group_ids = [aws_security_group.pt-cluster-additional-sg.id]
  subnet_ids = [var.subnet_id_1, var.subnet_id_2, var.subnet_id_3]
  endpoint_private_access = false
  endpoint_public_access  = true
 }

 depends_on = [
  aws_iam_role.eks-iam-role,
 ]
}