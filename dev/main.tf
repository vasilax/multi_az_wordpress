# Configure the AWS Provider
 provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region     = "${var.aws_region}"
    }

# Create a VPC
 resource "aws_vpc" "wp_vpc" {
   cidr_block = "${var.vpc_cidr}"
    tags {
      Name = "${var.environment}-vpc"
    }
  }

# Create an internet gateway to give our public subnets access to the outside world
 resource "aws_internet_gateway" "wp_igw" {
   vpc_id = "${aws_vpc.wp_vpc.id}"
    tags {
      Name = "${var.environment}-ig"
    }
  }

# Grant the VPC internet access on its main route table
 resource "aws_route" "internet_access" {
   route_table_id         = "${aws_vpc.wp_vpc.main_route_table_id}"
   destination_cidr_block = "0.0.0.0/0"
   gateway_id             = "${aws_internet_gateway.wp_ig.id}"
  }

# Create private subnet in US East (1B) to launch RDS
 resource "aws_subnet" "rds-backend-1b" {
   vpc_id                  = "${aws_vpc.wp_vpc.id}"
   cidr_block              = "${var.rds_backend_1b}"
   availability_zone       = "us-east-1b"
   map_public_ip_on_launch = false
    tags {
          Name = "${var.environment}-rds-1b"
      }
    }
# Create private subnet in US East (1C) to launch RDS.
 resource "aws_subnet" "rds-backend-1c" {
   vpc_id                  = "${aws_vpc.wp_vpc.id}"
   cidr_block              = "${var.rds_backend_1c}"
   availability_zone       = "us-east-1c"
   map_public_ip_on_launch = false
    tags {
          Name = "${var.environment}-rds-1c"
      }
  }

# Create RDS DB Subnet group
 resource "aws_db_subnet_group" "rds_subnet_group" {
   name = "${var.environment}-rds-subnet-group"
   subnet_ids = ["${aws_subnet.rds-backend-1b.id}","${aws_subnet.rds-backend-1c.id}" ]
    tags {
          Name = "${var.environment}-rds-subnet-groups"
      }
  }

# Create public subnet in US East (1B) to launch EC2 instance
 resource "aws_subnet" "wp-us-east-1b" {
  vpc_id                  = "${aws_vpc.wp_vpc.id}"
  cidr_block              = "${var.wp_us_east_1b}"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
    tags {
        Name = "${var.environment}-us-east-1b"
     }
  }

# Create public subnet in US East (1C) to launch instance into
 resource "aws_subnet" "wp-us-east-1c" {
  vpc_id                  = "${aws_vpc.wp_vpc.id}"
  cidr_block              = "${var.wp_us_east_1c}"
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = true
    tags {
        Name = "${var.environment}-us-east-1c"
     }
  }

# A security group for the ELB so it is accessible via the web
 resource "aws_security_group" "wp_elb" {
   name        = "wp_elb"
   vpc_id      = "${aws_vpc.wp_vpc.id}"

  # HTTP access from anywhere
  ingress {
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access from anywhere
  ingress {
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  }


 # outbound internet access
  egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security group to access the instances over SSH and HTTP
 resource "aws_security_group" "wp_ssh_http" {
  name        = "wp_public_sg"
  vpc_id      = "${aws_vpc.wp_vpc.id}"

 # SSH access from anywhere
  ingress {
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  }
 # HTTP access from the VPC
  ingress {
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  }

 # outbound internet access
  egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  }
}

// Security group for RDS
 resource "aws_security_group" "wp_rds_sg" {
   name = "${var.environment}-rds-sg"
   description = "wp-${var.environment}-rds-sg"
   vpc_id = "${aws_vpc.wp_vpc.id}"
    tags {
         Name = "${var.environment}-rds-sg"
         Environment =  "${var.environment}"
  }

 // Allows traffic from the SG itself
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    self = true
  }

// allow traffic for TCP 3306
  ingress {
   from_port = 3306
   to_port = 3306
   protocol = "tcp"
   security_groups = ["${aws_security_group.wp_ssh_http.id}"]
  }

// outbound internet access
  egress {
   from_port = 0
   to_port = 0
   protocol = "-1"
   cidr_blocks = ["0.0.0.0/0"]
  }
}

//IAM Role Policy for EC2
 resource "aws_iam_role_policy" "iam_policy" {
    name = "iam_policy"
    role = "${aws_iam_role.iam_role.id}"
    policy = <<EOF
{
      "Version": "2012-10-17",
      "Statement": [
          {
              "Effect": "Allow",
              "Action": [
                  "s3:*"
              ],
              "Resource": [
                "arn:aws:s3:::${var.wp_bucket_name}",
                "arn:aws:s3:::${var.wp_bucket_name}/*"
              ]
          },
          {
              "Action": [
                  "s3:List*"
              ],
              "Effect": "Allow",
              "Resource": [
                  "*"
              ]
          }
      ]
  }
EOF
}

// IAM Role for ec2 to access S3 shared bucket
 resource "aws_iam_role" "iam_role" {
  name = "${var.iam_role}"
  assume_role_policy = <<EOF
{
     "Version": "2012-10-17",
     "Statement": [
       {
         "Action": "sts:AssumeRole",
         "Principal": {
         "Service": "ec2.amazonaws.com"
       },
         "Effect": "Allow",
         "Sid": ""
       }
    ]
  }
EOF
}

//IAM EC2 Instance profile
 resource "aws_iam_instance_profile" "web_instance_profile" {
   name  = "${var.environment}"
   roles = ["${var.iam_role}"]
  }

//CREATE S3 BUCKET
 resource "aws_s3_bucket" "wp_bucket" {
    bucket = "${var.wp_bucket_name}"
    acl = "private"
}

// Elastic Load Balancer
 resource "aws_elb" "wp_elb_web" {
  name                      = "wp-elb-web"
  subnets                   = ["${aws_subnet.wp-us-east-1b.id}","${aws_subnet.wp-us-east-1c.id}"]
  security_groups           = ["${aws_security_group.wp_elb.id}"]
  cross_zone_load_balancing = true

 listener {
 instance_port     = 80
 instance_protocol = "http"
 lb_port           = 80
 lb_protocol       = "http"
  }
  tags {
        Name = "${var.environment}-elb"
    }
 }

//Create a load balancer attachment
 resource "aws_elb_attachment" "elb_attachment" {
   elb      = "${aws_elb.wp_elb_web.id}"
   instance = "${aws_instance.web_us_east_1b.id}"
   instance = "${aws_instance.web_us_east_1c.id}"
 }


//create ec2 instance in US-East-1b AZ
 resource "aws_instance" "web_us_east_1b" {
  depends_on = ["aws_db_instance.wp-rds"]
  depends_on = ["aws_elb.wp_elb_web"]
     tags {
        Name = "${var.environment}-01"
    }
    connection {
      user = "ec2-user"
      private_key = "${file(var.private_key)}"
    }
      instance_type = "t2.micro"
      ami                    = "${lookup(var.aws_amis, var.aws_region)}"
      key_name               = "${var.key_name}"
      vpc_security_group_ids = ["${aws_security_group.wp_ssh_http.id}"]
      subnet_id              = "${aws_subnet.wp-us-east-1b.id}"
      iam_instance_profile   = "${aws_iam_instance_profile.web_instance_profile.id}"
          provisioner "file" {
            source = "scripts/install-1.sh"
            destination = "/tmp/install-1.sh"
          }

          provisioner "remote-exec" {
            inline = [
              "chmod u+x /tmp/*",
              "sed -i -e 's/\r$//' /tmp/install-1.sh",
              "/tmp/install-1.sh",
              "sudo sed -i 's/database_name_here/${var.wp_db_name}/g' /var/www/html/wp-config.php",
              "sudo sed -i 's/username_here/${var.wp_db_username}/g' /var/www/html/wp-config.php",
              "sudo sed -i 's/password_here/${var.wp_db_password}/g' /var/www/html/wp-config.php",
              "sudo sed -i 's/localhost/${aws_db_instance.wp-rds.address}:3306/g' /var/www/html/wp-config.php",
              ]
          }

          provisioner "file" {
            source = "scripts/install-2.sh"
            destination = "/tmp/install-2.sh"
          }

          provisioner "remote-exec" {
            inline = [
              "chmod u+x /tmp/*",
              "sed -i -e 's/\r$//' /tmp/install-2.sh",
              "/tmp/install-2.sh",
              "cd /var/www/html/",
              "wp core install --url=\"${aws_elb.wp_elb_web.dns_name}\"  --title=\"${var.wordpress_site_title}\" --admin_user=\"${var.wordpress_admin_username}\" --admin_password=\"${var.wordpress_admin_password}\" --admin_email=\"${var.wordpress_admin_email}\"",
              "wp plugin install --activate --version=1.0 amazon-web-services",
              "wp plugin install --activate --version=1.1 amazon-s3-and-cloudfront"
              ]
          }
}

//create ec2 instance in US-East-1b AZ
resource "aws_instance" "web_us_east_1c" {
  depends_on = ["aws_db_instance.wp-rds"]
  depends_on = ["aws_instance.web_us_east_1b"]
     tags {
        Name = "${var.environment}-02"
     }
    connection {
      user = "ec2-user"
      private_key = "${file(var.private_key)}"
    }
   instance_type = "t2.micro"
   ami                    = "${lookup(var.aws_amis, var.aws_region)}"
   key_name               = "${var.key_name}"
   vpc_security_group_ids = ["${aws_security_group.wp_ssh_http.id}"]
   subnet_id              = "${aws_subnet.wp-us-east-1c.id}"
   iam_instance_profile   = "${aws_iam_instance_profile.web_instance_profile.id}"
      provisioner "file" {
        source = "scripts/install-1.sh"
        destination = "/tmp/install-1.sh"
      }

      provisioner "remote-exec" {
        inline = [
          "chmod u+x /tmp/*",
          "sed -i -e 's/\r$//' /tmp/install-1.sh",
          "/tmp/install-1.sh",
          "sudo sed -i 's/database_name_here/${var.wp_db_name}/g' /var/www/html/wp-config.php",
          "sudo sed -i 's/username_here/${var.wp_db_username}/g' /var/www/html/wp-config.php",
          "sudo sed -i 's/password_here/${var.wp_db_password}/g' /var/www/html/wp-config.php",
          "sudo sed -i 's/localhost/${aws_db_instance.wp-rds.address}:3306/g' /var/www/html/wp-config.php"
        ]
      }
      provisioner "file" {
        source = "scripts/install-2.sh"
        destination = "/tmp/install-2.sh"
      }

      provisioner "remote-exec" {
        inline = [
          "chmod u+x /tmp/*",
          "sed -i -e 's/\r$//' /tmp/install-2.sh",
          "/tmp/install-2.sh",
          "cd /var/www/html/",
          "wp core install --url=\"${aws_elb.wp_elb_web.dns_name}\"  --title=\"test_title\" --admin_user=\"admin\" --admin_password=\"password\" --admin_email=\"vasilax@gmail.com\"",
          "wp plugin install --activate --version=1.0 amazon-web-services",
          "wp plugin install --activate --version=1.1 amazon-s3-and-cloudfront"
        ]
    }
}

// Setup the CloudFront Distribution

resource "aws_cloudfront_distribution" "cloudfront_distribution" {
 depends_on = ["aws_elb.wp_elb_web"]
  origin {
    domain_name = "${aws_elb.wp_elb_web.dns_name}"
    origin_id   = "${aws_elb.wp_elb_web.id}"

  custom_origin_config {
    http_port              = "80"
    https_port             = "443"
    origin_protocol_policy = "match-viewer"
    origin_ssl_protocols   = ["SSLv3", "TLSv1","TLSv1.1","TLSv1.2"]
  }
}
  enabled             = true
  comment             = "${var.cloudfront_description}"
  default_root_object = "index.php"
  retain_on_delete    = "true"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${aws_elb.wp_elb_web.id}"

  forwarded_values {
    query_string = false
  cookies {
   forward = "none"
    }
  }
  viewer_protocol_policy = "allow-all"
  min_ttl      = 0
  default_ttl  = 3600
  max_ttl      = 86400
  }

  price_class = "PriceClass_200"
  restrictions {
   geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE"]
  }
 }
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

//Create WP Database
resource "aws_db_instance" "wp-rds" {
  allocated_storage    = 10
  vpc_security_group_ids = ["${aws_security_group.wp_rds_sg.id}"]
  engine               = "mysql"
  identifier           = "${var.environment}"
  engine_version       = "5.6.27"
  instance_class       = "db.t1.micro"
  name                 = "${var.wp_db_name}"
  username             = "${var.wp_db_username}"
  password             = "${var.wp_db_password}"
  db_subnet_group_name = "${aws_db_subnet_group.rds_subnet_group.id}"
  parameter_group_name = "default.mysql5.6"
}
