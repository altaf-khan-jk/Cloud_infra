output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.web.public_ip
}

output "rds_endpoint" {
  description = "RDS MySQL endpoint"
  value       = aws_db_instance.mysql.address
}

output "s3_bucket_names" {
  description = "Names of the Terraform-created S3 buckets"
  value       = [for b in aws_s3_bucket.project_buckets : b.bucket]
}
