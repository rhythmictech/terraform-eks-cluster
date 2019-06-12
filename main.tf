data "aws_iam_policy_document" "worker_iam_policy_doc" {
  statement {
    sid       = "ECRDownloadAccess"
    effect    = "Allow"
    actions   = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
    ]
    resources = [
      "arn:aws:ecr:us-east-1:${var.account_id}:repository/*",
    ]
  }
  statement {
    sid       = "AllowAssumeRoles"
    effect    = "Allow"
    actions   = [
      "sts:AssumeRole",
    ]
    resources = [
      "arn:aws:iam::${var.account_id}:role/k8s-${var.cluster_name}-*",
    ]
  }
}

resource "aws_iam_role" "worker_role" {
  name = "${var.cluster_name}-worker-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_iam_policy" "worker_iam_policy" {
  name        = "${var.cluster_name}-worker-policy"
  path        = "/"
  description = "Worker IAM Policy"

  policy      = data.aws_iam_policy_document.worker_iam_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "workers_local_policy" {
  policy_arn  = aws_iam_policy.worker_iam_policy.arn
  role        = aws_iam_role.worker_role.name
}

resource "aws_iam_role_policy_attachment" "workers_eksworkernode_policy" {
  policy_arn  = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role        = aws_iam_role.worker_role.name
}

resource "aws_iam_role_policy_attachment" "workers_ekscni_policy" {
  policy_arn  = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role        = aws_iam_role.worker_role.name
}

resource "aws_iam_role_policy_attachment" "workers_ec2container_policy" {
  policy_arn  = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role        = aws_iam_role.worker_role.name
}

module "eks" {
  #source = "git::https://github.com/terraform-aws-modules/terraform-aws-eks.git"
  # following fork that's been upgraded to tf12 until this gets merged
  source                                = "git::git@github.com:a7i/terraform-aws-eks.git?ref=feature/tf12upgrade"
  cluster_name                          = var.cluster_name
  subnets                               = var.subnets
  vpc_id                                = var.vpc_id
  worker_additional_security_group_ids  = [var.worker_additional_security_group_ids]
  worker_groups                         = var.worker_groups
  worker_group_count                    = "1"
  workers_group_defaults                = {
    iam_role_id = aws_iam_role.worker_role.name
  }

  tags = merge(
    local.common_tags,
    var.additional_tags,
    map(
      "Name", var.cluster_name
    )
  )

}

data "aws_iam_policy_document" "r53_access_policy_doc" {
  statement {
    sid       = "Route53UpdateZones"
    effect    = "Allow"
    actions   = [
      "route53:ChangeResourceRecordSets",
    ]
    resources = [
      "arn:aws:route53:::hostedzone/*",
    ]
  }
  statement {
    sid       = "Route53ListZones"
    effect    = "Allow"
    actions   = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
    ]
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "r53_access_policy" {
  name_prefix = "r53_access_policy"
  path        = "/"
  description = "Route 53 Access Policy"

  policy      = data.aws_iam_policy_document.r53_access_policy_doc.json
}

resource "aws_iam_role" "r53_access_iam_role" {
  name_prefix         = "k8s-${var.cluster_name}-r53-access"
  path                = "/"
  assume_role_policy  = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
          "Sid": "",
          "Effect": "Allow",
          "Principal": {
             "Service": "ec2.amazonaws.com"
          },
          "Action": "sts:AssumeRole"
        },
        {
          "Sid": "",
          "Effect": "Allow",
          "Principal": {
            "AWS": "${aws_iam_role.worker_role.arn}"
          },
          "Action": "sts:AssumeRole"
        }
    ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "r53_access_iam_role_policy_attach" {
  role       = aws_iam_role.r53_access_iam_role.name
  policy_arn = aws_iam_policy.r53_access_policy.arn
}

