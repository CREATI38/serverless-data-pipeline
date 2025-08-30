# --- Transfer Family server (only one needed)
resource "aws_transfer_server" "sftp" {
  protocols              = ["SFTP"]
  identity_provider_type = "SERVICE_MANAGED"
  endpoint_type          = var.transfer_endpoint_type
  logging_role           = aws_iam_role.transfer_logging.arn

  tags = { Project = var.admin_name }
}

# --- Logging IAM role
resource "aws_iam_role" "transfer_logging" {
  name = "${var.admin_name}-tf-logging"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "transfer.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "transfer_logging" {
  name = "${var.admin_name}-tf-logging"
  role = aws_iam_role.transfer_logging.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents"],
      Resource = "*"
    }]
  })
}

# --- User IAM roles & policies
resource "aws_iam_role" "user_roles" {
  for_each = { for u in var.users : u.name => u }

  name = "${var.admin_name}-${each.key}-tf-user-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "transfer.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "user_s3" {
  for_each = { for u in var.users : u.name => u }

  name = "${var.admin_name}-${each.key}-tf-user-s3"
  role = aws_iam_role.user_roles[each.key].id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:ListBucket"],
        Resource = "arn:aws:s3:::${var.transfer_bucket_name}",
        Condition = {
          StringLike = {
            "s3:prefix": [ each.value.prefix, "${each.value.prefix}*" ]
          }
        }
      },
      {
        Effect   = "Allow",
        Action   = ["s3:GetObject","s3:PutObject","s3:DeleteObject","s3:AbortMultipartUpload"],
        Resource = "arn:aws:s3:::${var.transfer_bucket_name}/${each.value.prefix}*"
      }
    ]
  })
}

# --- Transfer Family users
resource "aws_transfer_user" "users" {
  for_each = { for u in var.users : u.name => u }

  server_id      = aws_transfer_server.sftp.id
  user_name      = each.key
  role           = aws_iam_role.user_roles[each.key].arn
  home_directory = "/${var.transfer_bucket_name}/${each.value.prefix}"

  tags = { Project = var.admin_name }
}


resource "aws_transfer_ssh_key" "agency1_key" {
  server_id = aws_transfer_server.sftp.id
  user_name = "agency1"
  body      = file("C:/Users/drkle/.ssh/id_agency1.pub")
  depends_on = [aws_transfer_user.users]  #ensures user exists first
}


resource "aws_transfer_ssh_key" "agency2_key" {
  server_id = aws_transfer_server.sftp.id
  user_name = "agency2"
  body      = file("C:/Users/drkle/.ssh/id_agency2.pub")
  depends_on = [aws_transfer_user.users]  #ensures user exists first
}



resource "aws_transfer_ssh_key" "agency3_key" {
  server_id = aws_transfer_server.sftp.id
  user_name = "agency3"
  body      = file("C:/Users/drkle/.ssh/id_agency3.pub")

  depends_on = [aws_transfer_user.users]  #ensures user exists first
}
