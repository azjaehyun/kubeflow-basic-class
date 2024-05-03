resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits = 2048
}

resource "aws_key_pair" "this" {
  key_name    = "${local.name_prefix}-${var.context.owner}-keypair"
  public_key  = file("${path.module}/template/${var.context.owner}-keypair.pub")  ## 본인이 생성한 이름으로 변경 
}
