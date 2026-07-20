resource "aws_eip" "k3s_server" {
  instance = aws_instance.k3s_server.id
  domain   = "vpc"

  depends_on = [aws_instance.k3s_server]

  tags = {
    Name = "cloudship-k3s-server-eip"
  }
}