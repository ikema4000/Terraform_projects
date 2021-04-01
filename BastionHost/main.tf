provider "aws" {
    region = "us-east-2"
}

## creating a vpm with cidr 10.5.0.0/16
resource "aws_vpc" "ohio_terraform" {
    cidr_block = "10.5.0.0/16" 
    tags = {
      "Name" = "Ohio_terraform"
    }
}

# Internet Gateway
resource "aws_internet_gateway" "ohio_terra_GT" {
  vpc_id = aws_vpc.ohio_terraform.id
  tags = {
    Name = "Ohio_terra_internet_gateway"
  }
}
# Route table 
resource "aws_route_table" "ohio_terra_RT" {
  vpc_id = aws_vpc.ohio_terraform.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ohio_terra_GT.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.ohio_terra_GT.id
  }

  tags = {
    Name = "Ohio Terraform RT"
  }
  depends_on = [
    aws_internet_gateway.ohio_terra_GT
  ]
}
# creating a subnet to be made public
resource "aws_subnet" "ohio_terr_public" {
    vpc_id = aws_vpc.ohio_terraform.id
    cidr_block = "10.5.1.0/24"
    availability_zone = "us-east-2a"
    tags = {
      "Name" = "Ohio_terr_public"
    }  
}

# creatig a subnet to me made private 
resource "aws_subnet" "ohio_terr_private" {
    vpc_id = aws_vpc.ohio_terraform.id
    cidr_block = "10.5.2.0/24"
    availability_zone = "us-east-2b"
    tags = {
      "Name" = "Ohio_terr_private"
    }  
}

# route table association public subnet 
resource "aws_route_table_association" "subnet_public" {
  subnet_id      = aws_subnet.ohio_terr_public.id
  route_table_id = aws_route_table.ohio_terra_RT.id
  #making sure the subnet is created first
  depends_on = [
    aws_subnet.ohio_terr_public
  ]
}
# route table association private subnet 
resource "aws_route_table_association" "subnet_private" {
  subnet_id      = aws_subnet.ohio_terr_private.id
  route_table_id = aws_route_table.ohio_terra_RT.id
  # making sure the subnet is created first 
  depends_on = [
    aws_subnet.ohio_terr_private
  ]
}

## Creating the public Security group
resource "aws_security_group" "ohio_terra_SG" {
  name        = "allow_ssh"
  description = "Allow ssh inbound traffic on 22"
  vpc_id      = aws_vpc.ohio_terraform.id

# allowing inbound SSH traffic
  ingress {
    description = "allow ssh traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

# Allowing all traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Ohio Terra Public SG"
  }
}

# creating security group rule for the private to only allow traffic from the private
resource "aws_security_group" "ohio_terra_SG_Private" {
  name        = "allow_ssh_from_public"
  description = "Allow ssh inbound traffic on 22"
  vpc_id      = aws_vpc.ohio_terraform.id

# allowing inbound SSH traffic
  ingress {
    description = "allow ssh traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.ohio_terr_public.cidr_block]

  }

# Allowing all traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Ohio Terra Private"
  }
}

#creating an private instanceInstance 
resource "aws_instance" "my_t2" {
  ami           = "ami-05d72852800cbf29e"
  instance_type = "t2.micro"
  key_name = "ohio-key"
  subnet_id = aws_subnet.ohio_terr_private.id
  vpc_security_group_ids = [ aws_security_group.ohio_terra_SG_Private.id ]

  tags = {
    Name = "Terraform Private"
  }
}

# creating a public instance 
resource "aws_instance" "my_t2_ohio" {

  ami           = "ami-05d72852800cbf29e"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  key_name = "ohio-key"
  subnet_id = aws_subnet.ohio_terr_public.id
  vpc_security_group_ids = [ aws_security_group.ohio_terra_SG.id ]

  tags = {
    Name = "Terraform Public"
  }
}