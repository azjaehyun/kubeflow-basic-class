
#output "ssh_private_key_pem" {
#  value = module.aws_key_pair.ssh_private_key_pem
#  sensitive = true
#}

#output "ssh_public_key_pem" {
#  value = module.aws_key_pair.ssh_public_key_pem
#  sensitive = true
#}


output "aws_ec2_bastion_public_ip" {
    value = module.aws_ec2_bastion.ami-public_ip
}

output "aws_ec2_bastion_private_ip" {
    value = module.aws_ec2_bastion.ami-private_ip
}
