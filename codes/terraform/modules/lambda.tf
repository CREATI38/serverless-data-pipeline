# IAM Role for lambda 
resource "aws_iam_role" "lambda-basic-role" {
  name = "${var.admin_name}-lambda-basic-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "lambda-role-permissions" {
  name        = "${var.admin_name}-lambda-role-permissions"
  description = "Allows Lambda to access source (Transfer Family) and destination (landing zone) buckets"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # Source bucket: allow read
      {
        Effect   = "Allow",
        Action   = ["s3:GetObject"],
        Resource = "arn:aws:s3:::dp-secure-transfer/*"
      },
      {
        Effect   = "Allow",
        Action   = ["s3:ListBucket"],
        Resource = "arn:aws:s3:::dp-secure-transfer"
      },

      # Destination bucket: allow full object operations
      {
        Effect   = "Allow",
        Action   = [
          "s3:GetObject",    
          "s3:PutObject",     
          "s3:DeleteObject"  
        ],
        Resource = "arn:aws:s3:::derrick-dp-bucket/*"
      },
      {
        Effect   = "Allow",
        Action   = ["s3:ListBucket"],
        Resource = "arn:aws:s3:::derrick-dp-bucket"
      },

      # CloudWatch logs
      {
        Effect   = "Allow",
        Action   = ["logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents"],
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "lambda_role_policy_attachment" {
  role       = aws_iam_role.lambda-basic-role.name
  policy_arn = aws_iam_policy.lambda-role-permissions.arn
}

# Add Lambda Layers - requests and pandas
resource "aws_lambda_layer_version" "requests-layer" {
  layer_name          = "requests"   
  compatible_runtimes = ["python3.13"]
  compatible_architectures = ["x86_64"]      

  # Path to the zip file containing libraries
  filename = var.requests_lambda_layer_file_path
}

resource "aws_lambda_layer_version" "pandas-layer" {
  layer_name          = "pandas"   
  compatible_runtimes = ["python3.13"]
  compatible_architectures = ["x86_64"]      

  # Path to the zip file containing libraries
  filename = var.pandas_lambda_layer_file_path
}

# Create Lambda Function for **Pull Data from CFT**
# resource "aws_lambda_function" "pull-data-from-cft" {
#   function_name = "${var.admin_name}-pull-data-from-cft"
#   description   = "Lambda to pull data using CFT HTTPS API"
#   role          = aws_iam_role.lambda-basic-role.arn
#   handler       = "lambda_function.lambda_handler"
#   runtime       = "python3.13"
#   memory_size   = 128 # mb
#   timeout       = 20  # seconds

#   filename         = var.lambda_function_pull_cft_path
#   layers           = [aws_lambda_layer_version.requests-layer.arn]
#   source_code_hash = filebase64sha256(var.lambda_function_pull_cft_path)

#   depends_on = [
#     aws_lambda_layer_version.requests-layer
#   ]
# }

# # Create CloudWatch Log Group
# resource "aws_cloudwatch_log_group" "lambda-log-group-pull-data-from-cft" {
#   name              = "/aws/lambda/${aws_lambda_function.pull-data-from-cft.function_name}"
#   retention_in_days = 7
#   lifecycle {
#     prevent_destroy = false
#   }
# }


#---- new pull from transfer server part

#Create Lambda Function for **Pull Data from Transfer**
resource "aws_lambda_function" "pull-from-transfer-server" {
  function_name = "${var.admin_name}-pull-from-transfer-server"
  description   = "Lambda to pull data fron transfer server"
  role          = aws_iam_role.lambda-basic-role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.13"
  memory_size   = 128 # mb
  timeout       = 20  # seconds

  filename         = var.lambda_function_pull_transfer_path
  layers           = [aws_lambda_layer_version.requests-layer.arn]
  source_code_hash = filebase64sha256(var.lambda_function_pull_transfer_path)

  depends_on = [
    aws_lambda_layer_version.requests-layer
  ]
}

# Create CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda-log-group-pull-from-transfer-server" {
  name              = "/aws/lambda/${aws_lambda_function.pull-from-transfer-server.function_name}"
  retention_in_days = 7
  lifecycle {
    prevent_destroy = false
  }
}

#-----------------------------

# Create Lambda Function for **File Validation**
resource "aws_lambda_function" "validate-file" {
  function_name = "${var.admin_name}-validate-file"
  description   = "Lambda to validate file from Landing Zone"
  role          = aws_iam_role.lambda-basic-role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.13"
  memory_size   = 128 # mb
  timeout       = 20  # seconds

  filename         = var.lambda_function_validate_file_path
  layers           = [aws_lambda_layer_version.pandas-layer.arn]
  source_code_hash = filebase64sha256(var.lambda_function_validate_file_path)

  depends_on = [
    aws_lambda_layer_version.pandas-layer
  ]
}

# Create CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda-log-group-validate-file" {
  name              = "/aws/lambda/${aws_lambda_function.validate-file.function_name}"
  retention_in_days = 7
  lifecycle {
    prevent_destroy = false
  }
}

# Create Lambda Function for **Data Element Validation**
resource "aws_lambda_function" "validate-data-element" {
  function_name = "${var.admin_name}-validate-data-element"
  description   = "Lambda to validate data elements from File Validation Zone"
  role          = aws_iam_role.lambda-basic-role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.13"
  memory_size   = 128 # mb
  timeout       = 20  # seconds

  filename         = var.lambda_function_validate_data_path
  layers           = [aws_lambda_layer_version.pandas-layer.arn]
  source_code_hash = filebase64sha256(var.lambda_function_validate_data_path)

  depends_on = [
    aws_lambda_layer_version.pandas-layer
  ]
}

# Create CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda-log-group-validate-data-element" {
  name              = "/aws/lambda/${aws_lambda_function.validate-data-element.function_name}"
  retention_in_days = 7
  lifecycle {
    prevent_destroy = false
  }
}

# As the next Lambda Function we are going to create needs Redshift access,
# we are will store the credentials in secret Manager
resource "aws_secretsmanager_secret" "lambda-redshift-secret" {
  name        = "/lambda-redshift/${var.admin_name}/credentials"
  description = "Redshift credentials for Lambda connection"
  recovery_window_in_days = 0   # <-- immediate delete on destroy
}

resource "aws_secretsmanager_secret_version" "lambda-redshift-secret-version" {
  secret_id     = aws_secretsmanager_secret.lambda-redshift-secret.id
  secret_string = jsonencode({
    username = "lambda_user"
    password = "Password1" # Use env variables / encrypted var files for production
  })
}

# Create Lambda Function for **S3 Copy to Redshift**
resource "aws_lambda_function" "s3-copy-to-redshift" {
  function_name = "${var.admin_name}-s3-copy-to-redshift"
  description   = "Lambda to copy S3 content into Redshift"
  role          = aws_iam_role.lambda-basic-role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.13"
  memory_size   = 128 # mb
  timeout       = 20  # seconds

  filename         = var.lambda_function_s3_copy_path
  source_code_hash = filebase64sha256(var.lambda_function_s3_copy_path)

  environment {
    variables = {
      redshift_workgroup_name = var.redshift_workgroup_name
      iam_role_arn            = aws_iam_role.redshift-s3-basic-access.arn
      secret_arn              = aws_secretsmanager_secret_version.lambda-redshift-secret-version.arn
    }
  }

  depends_on = [aws_iam_role.redshift-s3-basic-access,
                aws_secretsmanager_secret_version.lambda-redshift-secret-version]
}

# Create CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda-log-group-s3-copy-to-redshift" {
  name              = "/aws/lambda/${aws_lambda_function.s3-copy-to-redshift.function_name}"
  retention_in_days = 7
  lifecycle {
    prevent_destroy = false
  }
}
