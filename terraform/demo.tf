provider "aws" {
  region = "eu-west-2"
}

# Lambda IAM Role
resource "aws_iam_role" "lambda_role" {
  name               = "lambda_execution_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Lambda IAM Policy
resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda_policy"
  description = "Policy for Lambda function to access DynamoDB"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Effect": "Allow",
      "Action": "dynamodb:*",
      "Resource": "*"
    }
  ]
}
EOF
}

# Attach Lambda IAM Policy to IAM Role
resource "aws_iam_role_policy_attachment" "lambda_attach" {
  policy_arn = aws_iam_policy.lambda_policy.arn
  role       = aws_iam_role.lambda_role.name
}

# Lambda Function
resource "aws_lambda_function" "todo_lambda" {
  filename      = "lambda_function_payload.zip" # Path to your Lambda function code
  function_name = "todo_lambda_function"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs14.x"
}

# API Gateway HTTP API
resource "aws_apigatewayv2_api" "todo_api" {
  name          = "todo_api"
  protocol_type = "HTTP"
  target        = aws_lambda_function.todo_lambda.invoke_arn
}

# API Gateway Integration
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id            = aws_apigatewayv2_api.todo_api.id
  integration_type  = "AWS_PROXY"
  integration_uri   = aws_lambda_function.todo_lambda.invoke_arn
  integration_method = "POST"
}

# API Gateway Route
resource "aws_apigatewayv2_route" "todo_route" {
  api_id    = aws_apigatewayv2_api.todo_api.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# API Gateway Deployment
resource "aws_apigatewayv2_stage" "todo_stage" {
  api_id      = aws_apigatewayv2_api.todo_api.id
  name        = "prod"
  auto_deploy = true
}

# Output API Gateway Endpoint URL
output "api_gateway_endpoint" {
  value = aws_apigatewayv2_api.todo_api.api_endpoint
}
