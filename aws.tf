resource "aws_iam_user" "litellm" {
  name = "litellm"
}

resource "aws_iam_access_key" "litellm_access_key" {
  user = aws_iam_user.litellm.name
}

resource "aws_iam_policy" "bedrock_invoke_policy" {
    name        = "bedrock-invoke-policy"
    description = "Policy to allow invocation of Bedrock models"
    policy      = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = [
                    "bedrock:InvokeModel",
                    "bedrock:InvokeModelWithResponseStream"
                ]
                Resource = "*"
            }
        ]
    })
}

resource "aws_iam_user_policy_attachment" "litellm_policy_attachment" {
  user       = aws_iam_user.litellm.name
  policy_arn = aws_iam_policy.bedrock_invoke_policy.arn
}