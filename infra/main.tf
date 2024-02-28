resource "aws_s3_bucket" "input_bucket" {
  bucket = "p4-devops-input-bucket-2"
  force_destroy = true
}

resource "aws_s3_bucket" "output_bucket" {
  bucket = "p4-devops-output-bucket-2"
  force_destroy = true
}

resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "lambda_s3_cloudwatch_policy" {
  name        = "lambda_s3_cloudwatch_policy"
  description = "IAM policy for logging from a lambda to CloudWatch and accessing S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "s3:*",
        ]
        Resource = "*"
        Effect   = "Allow"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_s3_cloudwatch_policy.arn
}

resource "aws_lambda_function" "weekly_lambda" {
  function_name = "weeklyLambdaFunction"
  handler       = "lambda_function.lambda_handler"
  role          = aws_iam_role.lambda_execution_role.arn
  runtime       = "python3.12"
  timeout       = 180 # 3 minutes

  filename         = "ingest_lambda.zip"
  source_code_hash = filebase64sha256("ingest_lambda.zip")
}

resource "aws_cloudwatch_event_rule" "weekly_schedule" {
  name                = "weekly-schedule"
  schedule_expression = "cron(0 12 ? * MON *)"
}

resource "aws_cloudwatch_event_target" "invoke_weekly_lambda" {
  rule      = aws_cloudwatch_event_rule.weekly_schedule.name
  target_id = "invokeWeeklyLambda"
  arn       = aws_lambda_function.weekly_lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_weekly_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.weekly_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.weekly_schedule.arn
}

resource "aws_lambda_function" "triggered_lambda" {
  function_name = "triggeredLambdaFunction"
  handler       = "lambda_function.lambda_handler"
  role          = aws_iam_role.lambda_execution_role.arn
  runtime       = "python3.12"
  timeout       = 900 # 15 minutes
  memory_size   = 1024
  ephemeral_storage {
    size = 1024
  }

  filename         = "process_lambda.zip"
  source_code_hash = filebase64sha256("process_lambda.zip")
}

resource "aws_s3_bucket_notification" "input_bucket_notification" {
  bucket = aws_s3_bucket.input_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.triggered_lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }
}

resource "aws_lambda_permission" "allow_s3_to_call_triggered_lambda" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.triggered_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.input_bucket.arn
}
