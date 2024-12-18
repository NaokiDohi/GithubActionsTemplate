
# Taskロール
resource "aws_iam_role" "task" {
  name = "${var.service_name}-${var.env}-ecs-task-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  # ここは修正のために空リストの必要がある。
  managed_policy_arns = [
    # "arn:aws:iam::aws:policy/AmazonBedrockFullAccess"
    # "arn:aws:iam::aws:policy/AmazonRDSDataFullAccess"
  ]
}

# 最近のECSでは不要
# 訂正:コンテナ内部での復号化が不要なだけでポリシー自体は実行ロールで必要
# ただし、環境変数をSSMから持ってくる以外でSSMを使用する場合は必要。今回はRDSのSecretに対して必要。
# 今回使用するポリシーはaws_iam_role_policy.rdsにまとめて付与。
# resource "aws_iam_role_policy" "task_policy_get_env" {
#   name = "${var.service_name}-${var.env}-ecs-task-role-get-env-policy"
#   role = aws_iam_role.task.id
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = [
#           "ssm:GetParameters",
#           "secretsmanager:GetSecretValue",
#         ]
#         Effect   = "Allow"
#         Resource = "*"
#       },
#     ]
#   })
# }

resource "aws_iam_role_policy" "bedrock" {
  name = "${var.service_name}-${var.env}-ecs-task-role-bedrock-policy"
  role = aws_iam_role.task.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "BedrockAccessRoleFromECS",
        Action = [
          #   "bedrock:InvokeModel",
          #   "bedrock:ListKnowledgeBases",
          #   "bedrock:RetrieveAndGenerate"
          "bedrock:*"
        ]
        Effect = "Allow"
        Resource = [
          #   "arn:aws:bedrock:*::foundation-model/*",
          #   "arn:aws:bedrock:*::knowledge-base/*",
          "*"
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy" "rds" {
  name = "${var.service_name}-${var.env}-ecs-task-role-rds-policy"
  role = aws_iam_role.task.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Sid"    = "SecretsManagerDbCredentialsAccess",
        "Effect" = "Allow",
        "Action" = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutResourcePolicy",
          "secretsmanager:PutSecretValue",
          "secretsmanager:DeleteSecret",
          "secretsmanager:DescribeSecret",
          "secretsmanager:TagResource"
        ],
        "Resource" = [
          "*",
        ]
      },
      {
        "Sid" : "RDSDataServiceAccess",
        "Effect" : "Allow",
        "Action" : [
          "dbqms:CreateFavoriteQuery",
          "dbqms:DescribeFavoriteQueries",
          "dbqms:UpdateFavoriteQuery",
          "dbqms:DeleteFavoriteQueries",
          "dbqms:GetQueryString",
          "dbqms:CreateQueryHistory",
          "dbqms:DescribeQueryHistory",
          "dbqms:UpdateQueryHistory",
          "dbqms:DeleteQueryHistory",
          "rds-data:ExecuteSql",
          "rds-data:ExecuteStatement",
          "rds-data:BatchExecuteStatement",
          "rds-data:BeginTransaction",
          "rds-data:CommitTransaction",
          "rds-data:RollbackTransaction",
          "secretsmanager:CreateSecret",
          "secretsmanager:ListSecrets",
          "secretsmanager:GetRandomPassword",
          "tag:GetResources"
        ],
        "Resource" : "*"
      }
    ]
  })
}

# resource "aws_iam_role_policy" "s3_access" {
#   name = "${var.service_name}-${var.env}-ecs-task-role-s3-policy"
#   role = aws_iam_role.task.id
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = [
#           "s3:GetObject",
#           "s3:ListBucket"
#         ]
#         Effect   = "Allow"
#         Resource = ["*"]
#       },
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "task" {
#   role       = aws_iam_role.task.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
# }