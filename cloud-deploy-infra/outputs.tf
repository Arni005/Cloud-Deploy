output "k3s_server_public_ip" {
  value = aws_instance.k3s_server.public_ip
}

output "vpc_id" {
  value = aws_vpc.myvpc.id
}
