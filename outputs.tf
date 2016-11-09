output "elb_address" {
  value = "${aws_elb.wp_elb_web.dns_name}"
  }

output "cloudfront_distribution_dns_name" {
    value = "${aws_cloudfront_distribution.cloudfront_distribution.domain_name}"
  }

output "aws_web_us_east_1b_instance_ip" {
      value = "${aws_instance.web_us_east_1b.public_ip}"
  }

output "aws_web_us_east_1c_instance_ip" {
    value = "${aws_instance.web_us_east_1c.public_ip}"
  }
