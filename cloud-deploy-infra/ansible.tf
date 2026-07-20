resource "null_resource" "ansible_provisioner" {
  depends_on = [aws_eip.k3s_server]

  provisioner "local-exec" {
    command = <<EOT
      sleep 90 && \
      echo "[master]" > ../cloud-deploy-ansible/inventory.ini && \
      echo "${aws_eip.k3s_server.public_ip}" >> ../cloud-deploy-ansible/inventory.ini && \
      echo "" >> ../cloud-deploy-ansible/inventory.ini && \
      echo "[k3s_cluster:children]" >> ../cloud-deploy-ansible/inventory.ini && \
      echo "master" >> ../cloud-deploy-ansible/inventory.ini && \
      ansible-playbook -i ../cloud-deploy-ansible/inventory.ini \
      ../cloud-deploy-ansible/playbook.yml && \
      K3S_TOKEN=$(ssh -i ~/.ssh/b_day.pem -o StrictHostKeyChecking=no \
      ubuntu@${aws_eip.k3s_server.public_ip} \
      "sudo cat /var/lib/rancher/k3s/server/node-token") && \
      printf '#!/bin/bash\nK3S_URL="https://${aws_eip.k3s_server.public_ip}:6443"\nK3S_TOKEN="%s"\nsleep 30\ncurl -sfL https://get.k3s.io | K3S_URL=$${K3S_URL} K3S_TOKEN=$${K3S_TOKEN} sh -\n' "$$K3S_TOKEN" > userdata.sh
    EOT
  }

  triggers = {
    eip = aws_eip.k3s_server.public_ip
  }
}