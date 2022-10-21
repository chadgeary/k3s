output "k3s" {
  value = <<EOT

# To fetch the kubeconfig from s3
# and open a tunnel to the k3s API
./connect.sh
EOT

}
