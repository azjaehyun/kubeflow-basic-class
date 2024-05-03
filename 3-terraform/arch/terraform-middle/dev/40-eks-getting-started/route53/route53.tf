# 호스팅 영역 생성
resource "aws_route53_zone" "route53" {
  name = "jaehyun-test.site"
}