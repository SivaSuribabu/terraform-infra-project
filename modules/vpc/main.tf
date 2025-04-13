resource "aws_vpc" "demo" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "demo-vpc-${var.env_name}" }
}

resource "aws_subnet" "public" {
  count = 2
  cidr_block = "10.0.${count.index}.0/24"
  vpc_id     = aws_vpc.demo.id
  map_public_ip_on_launch = true
  availability_zone       = element(var.azs, count.index)
}

resource "aws_subnet" "private" {
  count = 2
  cidr_block = "10.0.${count.index + 2}.0/24"
  vpc_id     = aws_vpc.demo.id
  map_public_ip_on_launch = false
  availability_zone       = element(var.azs, count.index)
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.demo.id
  service_name = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = flatten([
    aws_subnet.public[*].id,
    aws_subnet.private[*].id
  ])
}

