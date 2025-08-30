#create standardized template for s3
resource "aws_s3_bucket" "dp-transfer-s3"{
  bucket = var.transfer_bucket_name
}