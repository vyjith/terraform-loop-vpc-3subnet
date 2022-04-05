# -------------------------------------------------- 
#  Aws VPC creation
# -------------------------------------------------- 


resource "aws_vpc" "main" {

   cidr_block = var.vpc_cidr
   
   instance_tenancy = "default"

    enable_dns_support = true

        enable_dns_hostnames = true

    tags = {
        Name = var.project
    }

}

# -------------------------------------------------- 
# Creating Internet gateway
# -------------------------------------------------- 

resource "aws_internet_gateway" "igw" {

  vpc_id = aws_vpc.main.id

  tags = {
    Name = var.project
  }
}

# -------------------------------------------------- 
# # Aws subnet creation of public
# -------------------------------------------------- 

resource "aws_subnet" "public" {

  count = 3
 
  vpc_id     = aws_vpc.main.id

  cidr_block = cidrsubnet(var.vpc_cidr, 3, count.index)

  availability_zone = data.aws_availability_zones.subnet.names[count.index]

  map_public_ip_on_launch = true


tags = {
    Name = "${var.project}-public${count.index+1}"

  }
}


# -------------------------------------------------- 
# Creating route table for public subnet
# -------------------------------------------------- 

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

   route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

   tags = {
    Name = "${var.project}-public"
  }
}

# -------------------------------------------------- 
# Route table association of public subnet
# -------------------------------------------------- 


resource "aws_route_table_association" "public" {

  count =3 
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id

  depends_on = [
    aws_subnet.public ]
}


# -------------------------------------------------- 
# # Aws subnet creation for private
# -------------------------------------------------- 

resource "aws_subnet" "private" {

  count = 3
 
  vpc_id     = aws_vpc.main.id

  cidr_block = cidrsubnet(var.vpc_cidr, 3, "${count.index+3}")

  availability_zone = data.aws_availability_zones.subnet.names[count.index]

  map_public_ip_on_launch = false


tags = {
    Name = "${var.project}-private${count.index+1}"

  }
}
# ===============================================================================
# Creating Elastic Ip For Nat Gateway.
# ===============================================================================

resource "aws_eip" "eip" {
  vpc      = true
  tags     = {
    Name = "${var.project}-eip"
  }
}


# ===============================================================================
# Creating Elastic Ip For Nat Gateway.
# ===============================================================================

resource "aws_nat_gateway" "nat" {
    
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.public[1].id

  tags = {
    Name = "${var.project}-nat"
  }
}

# -------------------------------------------------- 
# Creating route table for private subnet
# -------------------------------------------------- 

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

   tags = {
    Name = "${var.project}-private"
  }
}
# -------------------------------------------------- 
# Route table association of private subnet
# -------------------------------------------------- 


resource "aws_route_table_association" "private" {

  count =3 
  
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id

  depends_on = [
    aws_subnet.private ]
}
