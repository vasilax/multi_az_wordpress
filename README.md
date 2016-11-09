# multi_az_wordpress
This terraform script creates multi AZ install of a single Wordpress site:
- VPC with IG, RT 
- Two public subnets for EC2 instances
- Two private subnets and subnet group for RDS 
- SG for ELB - HTTP and HTTPS inbound
- SG for EC2 - SSH and HTTP
- SG for RDS - Port 3306 from EC2 SG
- IAM Role Policy for EC2 instances - Allow access to the shared s3 bucket
- IAM Role for EC2 instances
- IAM Instance Profile 
- S3 Bucket
- ELB
- ELB attachement (both EC2 instances in multiple AZs)
- Two EC2 instances in US-EAST-1 (az b and c)
- two bash scripts installing and configuring wordpress on EC2 instances as well as installing additional plugins via wp-cli
- Cloudfront Distribution with custom origin (ELB)
- RDS DB


Sequence:
- Create Key Pair and download the private key locally
- After tf apply, log to wordpress admin ("/wp-admin"), and add s3 bucket name to the AWS plugin.




