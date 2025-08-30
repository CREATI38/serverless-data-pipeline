#create standardized template for s3
resource "aws_s3_bucket" "dp-pipeline-s3" {
  bucket = var.bucket_name
}



# Local folder path where data configuration files are stored
locals {
  source_folder = var.data_configuration_files_path
  files         = fileset(local.source_folder, "*")
}

# Upload each data configuration file to S3 bucket
resource "aws_s3_object" "data-configuration-files" {
    for_each = { for file in local.files : file => file }

    bucket = var.bucket_name
    key    = "data-configuration-files/${each.key}"
    source = "${local.source_folder}/${each.key}"

    depends_on = [
        aws_s3_pipeline
    ]
}

resource "aws_s3_object" "landing" {
    bucket = var.bucket_name
    key    = "1-landing-zone/"
    content = ""
    # source = "/dev/null" used on mac remove content

    depends_on = [
        aws_s3_pipeline
    ]
}

resource "aws_s3_object" "file-validated" {
    bucket = var.bucket_name
    key    = "2-file-validated-zone/"
    content = ""
    # source = "/dev/null"

    depends_on = [
        aws_s3_pipeline
    ]
}

resource "aws_s3_object" "data-element-validated" {
    bucket = var.bucket_name
    key    = "3-data-element-validated-zone/"
    content = ""
    # source = "/dev/null"

    depends_on = [
        aws_s3_pipeline
    ]
}

resource "aws_s3_object" "rejected" {
    bucket = var.bucket_name
    key    = "rejected-files/"
    content = ""
    # source = "/dev/null"

    depends_on = [
        aws_s3_pipeline
    ]
}

resource "aws_s3_object" "logs" {
    bucket = var.bucket_name
    key    = "error-reports/"
    content = ""
    # source = "/dev/null"

    depends_on = [
        aws_s3_pipeline
    ]
}
