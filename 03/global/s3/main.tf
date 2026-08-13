provider "aws" {
  region = "us-east-2"
}

resource "aws_s3_bucket" "mybucket" {
  bucket = "bucket-ksh-0113"

  tags = {
    Name = "mybucket"
  }
}

resource "aws_dynamodb_table" "mylocks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "terraform-locks"
  }
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.mybucket.arn
}

output "dymamo_tables_name" {
  value = aws_dynamodb_table.mylocks.name
}

