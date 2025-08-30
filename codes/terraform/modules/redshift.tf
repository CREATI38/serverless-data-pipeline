resource "aws_iam_role" "redshift-s3-basic-access" {
  name = "${var.admin_name}-redshift-s3-basic-access"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "redshift.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy_attachment" "redshift-s3-policy-attachment" {
  name       = "${var.admin_name}-redshift-s3-basic-permissions"
  roles      = [aws_iam_role.redshift-s3-basic-access.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_redshiftserverless_namespace" "main-data-warehouse" {
    namespace_name = var.redshift_namespace
    db_name        = var.redshift_database_name
    admin_username = "admin"
    admin_user_password = "Password1!"

    iam_roles = [aws_iam_role.redshift-s3-basic-access.arn]  # Attach the role to Redshift
}

# Specify the subnet IDs manually for the three subnets
resource "aws_redshiftserverless_workgroup" "main-workgroup" {
  workgroup_name = var.redshift_workgroup_name
  namespace_name = aws_redshiftserverless_namespace.main-data-warehouse.namespace_name
  base_capacity  = 32

  # Specify subnet IDs for the Redshift Serverless Workgroup
  subnet_ids = var.redshift_subnet_ids
  publicly_accessible = false
}
