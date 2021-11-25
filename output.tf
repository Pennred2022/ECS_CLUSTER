output "load_balance_ip" {
    value = aws_lb.default.dns_name
  
}
