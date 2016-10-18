variable "wp_bucket_name" {
  description = "Name of the share s3 bucket"
}
variable "aws_access_key" {
}

variable "aws_secret_key" {
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "key_name" {
    description = "Name of AWS key pair"
    }

variable "wp_db_name" {
  description = "MYSQL DB name that will be used for Wordpress Install"
}

variable "wp_db_username" {
  description = "MYSQL Username for WP DB"
  }

variable "wp_db_password" {
  description = "MYSQL Password for WP DB - Minimum 8 characters"
  }

variable "iam_role" {
  description = "IAM role for EC2 instances to access s3"
  }

variable "private_key" {
  description = "Path and filename of private key in format /path/filename.pem"
  }

variable "wordpress_admin_email" {
  description = "Email of wordpress admin"
}

variable "wordpress_admin_username" {
  description = "Wordpress Admin Username"
}

variable "wordpress_admin_password" {
  description = "Wordpress Admin Password"
}
variable "wordpress_site_title" {
  description = "Wordpress Site Title"
}

variable "cloudfront_description" {
  description = "Cloudfront Distribution Notes"
}

variable "environment" {
  description = "Name tag"
}

variable "aws_region" {
      description = "AWS region to launch servers."
        default = "us-east-1"
	}

variable "aws_amis" {
	  default = {
	      eu-west-1 = "ami-b1cf19c6"
	      us-east-1 = "ami-6869aa05"
	      us-west-1 = "ami-3f75767a"
	      us-west-2 = "ami-21f78e11"
			}
 	}
