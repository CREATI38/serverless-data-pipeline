locals {
  # General
  admin_name = "derrick"
}

module "redshift-networking" {
  source = "./modules/networking"

  admin_name = local.admin_name
}

# Creating Resources (S3, Lambda, Redshift)
module "data-pipeline-resources" {
  source            = "./modules"
  admin_name  = local.admin_name
  bucket_name       = "${local.admin_name}-dp-bucket"
  data_configuration_files_path = "../data_pipelines/data_configuration_files"

  requests_lambda_layer_file_path    = "./modules/lambda_resources/layers/requests.zip"
  pandas_lambda_layer_file_path      = "./modules/lambda_resources/layers/pandas_numpy.zip"
  lambda_function_pull_transfer_path      = "./modules/lambda_resources/functions/pull_from_transfer_server.zip"
  lambda_function_validate_file_path = "./modules/lambda_resources/functions/validate_file.zip"
  lambda_function_validate_data_path = "./modules/lambda_resources/functions/validate_data_element.zip"
  lambda_function_s3_copy_path       = "./modules/lambda_resources/functions/s3_copy_to_redshift.zip"

  
  redshift_namespace      = "${local.admin_name}-redshift"
  redshift_database_name  = "covid-recovery"
  redshift_workgroup_name = "${local.admin_name}-redshift-workgroup"
  redshift_subnet_ids     = [module.redshift-networking.subnet_1a_id,
                            module.redshift-networking.subnet_1b_id,
                            module.redshift-networking.subnet_1c_id]

}


# -------------------------------------------------------------------
# Transfer Family (SFTP) - agencies
# -------------------------------------------------------------------
module "transfer_sftp" {
  source = "./modules/transfer_sftp"

  admin_name     = local.admin_name
  transfer_bucket_name = "dp-secure-transfer"
  transfer_endpoint_type = "PUBLIC"

  users = [
    { name = "agency1", prefix = "agency1/" },
    { name = "agency2", prefix = "agency2/" },
    { name = "agency3", prefix = "agency3/" }
  ]
}





