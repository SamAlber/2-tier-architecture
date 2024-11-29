resource "aws_iam_role" "ec2_ssm_role" {
  name = "ec2-ssm-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Policy to Allow RDS to Access Parameter Store
resource "aws_iam_policy" "db_ssm_parameter" {
  name = "DBSSMParameterAccess" // IMPORTANT TO CHANGE IT IF WERE ON ONE ACCOUNT! (A policy called SSMParameterAccess already exists. Duplicate names are not allowed.) 
  /*
  Even if you remove the policy from your Terraform configuration, AWS still retains it unless it was explicitly deleted. 
  Terraform is now trying to recreate a policy with the same name, which leads to the EntityAlreadyExists error.
  */
  description = "Allows RDS to read parameters from Parameter Store"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect : "Allow",
        Action : [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ],
        Resource : [
          "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/db_username",
          "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/db_password"
        ]
      }
    ]
  })
}

/*
We added the parameters manually to the the parameter store using: 
aws ssm put-parameter \
  --name "db_username" \
  --value "<your-database-username>" \
  --type "SecureString"

aws ssm put-parameter \
  --name "db_password" \
  --value "<your-database-password>" \
  --type "SecureString"
*/

resource "aws_iam_role_policy_attachment" "attach_ssm_policy" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = aws_iam_policy.db_ssm_parameter.arn
}
