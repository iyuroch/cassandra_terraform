provider "aws" {
  region                  = "eu-west-3"
  shared_credentials_file = "creds"
  profile                 = "default"
}

resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default"
  }
}

resource "aws_security_group" "jumpserver" {
  name        = "jumpserver"
  description = "Jump server for cassandra access"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "cassandra" {
  name        = "cassandra"
  description = "Cassandra client and internode"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = [aws_default_vpc.default.cidr_block]
  }

  ingress {
    description = "Client"
    from_port   = "9042"
    to_port     = "9042"
    protocol    = "tcp"
    cidr_blocks = [aws_default_vpc.default.cidr_block]
  }

  ingress {
    description = "Client Thrift"
    from_port   = "9160"
    to_port     = "9160"
    protocol    = "tcp"
    cidr_blocks = [aws_default_vpc.default.cidr_block]
  }

  ingress {
    description = "Client SSL"
    from_port   = "9142"
    to_port     = "9142"
    protocol    = "tcp"
    cidr_blocks = [aws_default_vpc.default.cidr_block]
  }

  ingress {
    description = "Internode with SSL"
    from_port   = "7000"
    to_port     = "7001"
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "JMX monitoring"
    from_port   = "7199"
    to_port     = "7199"
    protocol    = "tcp"
    self        = true
  }

  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "cassandra" {
  key_name   = "cassandra_test"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDEFgwu06CW1hHc1W8E9gXSikhXRW8PTl83W5wphJeA0uYzoYZ1K5HH/6yeh7I89oO9uaJnnwztIPnLRHLDp1YD/OJ+wMqkOiENep4pvOSbPudbhPy98kZc+f+0DgJjd7qvWMSjIQJztI5Hp3mZlJrGHQbFr6vScXhn6mMWfYmhZwzxkud+CRXPtnP2hMNZwE5iTtKaiwTCiQEG0Fd2FKvLXkmyg0COqbY9CqOSLUaE/J9Fk7i/kDUmJq+M2BrgHqTRlTnFHAdC43iDsG9x687+xufakWmK+1saTObzYwoysRyI8i9PNQTW05wvh4qMhVmu9BQGj2+lrOiFBv6aXKR708B1Y0u66J1PHXD8bjVKQur8O1vxRu3BoQEvGWzRjWQDZXdVvGd3K9S0+VVYQCSugP+A+lYg+XHewoWoAlt95g+Ohz8fMBk74kNiLU3H05YOAlmNJmb1JS6H1oCkfwWVt9VB+910R3SwEGcUinW+vKybzUPu8mbXq+s25vj4RBE="
}


resource "aws_instance" "jump_server" {
  ami                         = "ami-08c757228751c5335"
  associate_public_ip_address = true
  instance_type               = "t2.nano"
  key_name                    = aws_key_pair.cassandra.key_name
  vpc_security_group_ids = [
    aws_security_group.jumpserver.id
  ]
  tags = {
    Name = "JumpServer"
  }
}

resource "aws_instance" "cassandra" {
  count                       = 3
  user_data                   = file("cloud.conf")
  # does not work now
  associate_public_ip_address = true
  ami                         = "ami-08c757228751c5335"
  instance_type               = "t2.small"
  key_name                    = aws_key_pair.cassandra.key_name
  vpc_security_group_ids = [
    aws_security_group.cassandra.id
  ]
  tags = {
    Name = "Cassandra${count.index}"
  }
}

resource "aws_route53_zone" "example" {
  name = "stage.com"

  vpc {
    vpc_id = aws_default_vpc.default.id
  }

  lifecycle {
    ignore_changes = [vpc]
  }
}

resource "aws_route53_record" "cassandra_dns" {
  count   = 3
  zone_id = aws_route53_zone.example.zone_id
  name    = "cassandra${count.index}.stage.com"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.cassandra.*.private_ip[count.index]]
}

