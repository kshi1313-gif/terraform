output "myLB_url" {
  value = "http://${aws_lb.myLB.dns_name}"
}
