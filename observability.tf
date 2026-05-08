resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/enterprise-flow-logs"
  retention_in_days = 7

  tags = merge(local.common_tags, {
    Name = "/aws/vpc/enterprise-flow-logs"
  })
}

data "aws_iam_policy_document" "flow_logs_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "flow_logs_role" {
  name               = "${local.name_prefix}-flow-logs-role"
  assume_role_policy = data.aws_iam_policy_document.flow_logs_assume_role.json

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-flow-logs-role"
  })
}

data "aws_iam_policy_document" "flow_logs_write" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["${aws_cloudwatch_log_group.vpc_flow_logs.arn}:*"]
  }
}

resource "aws_iam_role_policy" "flow_logs_write" {
  name   = "${local.name_prefix}-flow-logs-write"
  role   = aws_iam_role.flow_logs_role.id
  policy = data.aws_iam_policy_document.flow_logs_write.json
}

resource "aws_flow_log" "vpc" {
  for_each = module.spoke_vpcs

  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs.arn
  log_destination_type = "cloud-watch-logs"
  iam_role_arn         = aws_iam_role.flow_logs_role.arn
  traffic_type         = "ALL"
  vpc_id               = each.value.vpc_id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-${each.key}-flow-logs"
  })
}