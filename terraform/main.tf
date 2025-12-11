########################################
# DATA SOURCES & RANDOMNESS
########################################

# Who am I? (for account id in bucket names)
data "aws_caller_identity" "current" {}

# Available AZs in region (we'll pick first 3)
data "aws_availability_zones" "available" {}

# Random suffix to make S3 bucket names globally unique
resource "random_id" "bucket_suffix" {
  byte_length = 2
}

########################################
# 1. S3 BUCKETS (4 PRIVATE, VERSIONED)
########################################

resource "aws_s3_bucket" "project_buckets" {
  count = 4

  bucket = "${var.project_prefix}-${data.aws_caller_identity.current.account_id}-${random_id.bucket_suffix.hex}-${count.index + 1}"

  tags = {
    Name        = "${var.project_prefix}-bucket-${count.index + 1}"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_public_access_block" "buckets_block" {
  count  = 4
  bucket = aws_s3_bucket.project_buckets[count.index].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "buckets_versioning" {
  count  = 4
  bucket = aws_s3_bucket.project_buckets[count.index].id

  versioning_configuration {
    status = "Enabled"
  }
}

########################################
# 2. VPC + PUBLIC SUBNET + IGW + ROUTE
########################################

resource "aws_vpc" "main" {
  cidr_block           = "10.123.0.0/16" # less likely to conflict than 10.0.0.0/16
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.project_prefix}-vpc"
    Environment = var.environment
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_prefix}-igw"
  }
}

# Public subnet: first /24 from the VPC
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, 0)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.project_prefix}-public-subnet"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_prefix}-public-rt"
  }
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

########################################
# 3. EC2 SECURITY GROUP + INSTANCE
########################################

resource "aws_security_group" "ec2_sg" {
  name        = "${var.project_prefix}-ec2-sg"
  description = "Allow SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from anywhere (demo)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_prefix}-ec2-sg"
  }
}

resource "aws_instance" "web" {
  ami                         = var.ec2_ami_id
  instance_type               = var.ec2_instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true
  key_name                    = var.ec2_key_name

  depends_on = [
    aws_subnet.public,
    aws_security_group.ec2_sg,
    aws_internet_gateway.igw
  ]

  tags = {
    Name        = "${var.project_prefix}-ec2"
    Environment = var.environment
  }
}

########################################
# 4. DB SUBNETS + SUBNET GROUP
########################################

# Two /24s for DB subnets, different AZs
resource "aws_subnet" "db1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, 1)
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "${var.project_prefix}-db-subnet-1"
  }
}

resource "aws_subnet" "db2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, 2)
  availability_zone = data.aws_availability_zones.available.names[2]

  tags = {
    Name = "${var.project_prefix}-db-subnet-2"
  }
}

resource "aws_db_subnet_group" "db_subnets" {
  name = "${var.project_prefix}-db-subnet-group-${random_id.bucket_suffix.hex}"
  subnet_ids = [
    aws_subnet.db1.id,
    aws_subnet.db2.id
  ]

  depends_on = [
    aws_subnet.db1,
    aws_subnet.db2
  ]

  tags = {
    Name = "${var.project_prefix}-db-subnet-group"
  }
}

########################################
# 5. RDS SECURITY GROUP + INSTANCE
########################################

resource "aws_security_group" "db_sg" {
  name        = "${var.project_prefix}-db-sg"
  description = "Allow MySQL"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "MySQL from anywhere (demo requirement)"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_prefix}-db-sg"
  }
}

resource "aws_db_instance" "mysql" {
  identifier        = "${var.project_prefix}-mysql"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  publicly_accessible = true # as required by project
  skip_final_snapshot = true # for demo; not for production

  db_subnet_group_name   = aws_db_subnet_group.db_subnets.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  depends_on = [
    aws_db_subnet_group.db_subnets,
    aws_security_group.db_sg
  ]

  tags = {
    Name        = "${var.project_prefix}-mysql"
    Environment = var.environment
  }
}
