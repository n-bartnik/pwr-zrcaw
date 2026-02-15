
resource "null_resource" "install_lambda_deps" {
  triggers = {
    requirements = filemd5("${path.module}/../lambda/requirements.txt")
    code         = filemd5("${path.module}/../lambda/main.py")
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"] 
    
    command = <<EOT
      rm -rf ${path.module}/../lambda/package
      mkdir -p ${path.module}/../lambda/package

      docker run --rm \
        -v ${abspath(path.module)}/../lambda:/workspace \
        -w /workspace \
        python:3.9-slim \
        pip install -r requirements.txt -t package

      cp ${path.module}/../lambda/main.py ${path.module}/../lambda/package/
    EOT
  }
}


data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/package"
  output_path = "${path.module}/../lambda/main.zip"
  
  depends_on = [null_resource.install_lambda_deps]
}

resource "aws_lambda_function" "compressor" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "chatapp-image-compressor"
  role          = var.lab_role 
  handler       = "main.lambda_handler"
  runtime       = "python3.9"
  timeout       = 60
  memory_size   = 256 

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  depends_on = [data.archive_file.lambda_zip]
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.compressor.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.chat_uploads.arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.chat_uploads.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.compressor.arn
    events              = ["s3:ObjectCreated:*"] 
  }
  
  depends_on = [aws_lambda_permission.allow_bucket]
}
