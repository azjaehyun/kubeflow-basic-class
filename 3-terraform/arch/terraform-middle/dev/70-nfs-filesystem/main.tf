module "aws_nfs_file_system" {
  efs_sg_name = format("%s-%s-efs-sg", local.name_prefix,var.context.owner)  
  source  = "../../../../modules/aws/efs"
  vpc_id  = data.aws_vpc.this.id
  private_subnets  = toset(data.aws_subnets.private.ids)
  tag_name = merge(local.tags, {Name = format("%s-%s-efs", local.name_prefix,var.context.owner)})
  cidr_block = ["${var.vpc_cidr}.1.0/24","${var.vpc_cidr}.2.0/24"]
}



