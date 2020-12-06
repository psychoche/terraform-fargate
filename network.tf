
data "aws_availability_zones" "available" {
}

resource "aws_vpc" "main" {
    cidr_block = "10.100.0.0/16"
}

# Create var.az_count private subnets, each in different AZ
resource "aws_subnet" "private" {
    count              = var.az_count
    cidr_block         = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
    availability_zone  = data.aws_availability_zones.available.names[count.index]
    vpc_id             = aws_vpc.main.id
}

# Create var.az_count public subnets, each in different AZ
resource "aws_subnet" "public" {
    count                   = var.az_count
    cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
    availability_zone       = data.aws_availability_zones.available.names[count.index]
    vpc_id                  = aws_vpc.main.id 
    map_public_ip_on_launch = true
}

# Internet gateway for the public subnet
resource "aws_internet_gateway" "internet_gw" {
    vpc_id = aws_vpc.main.id
}

# Route the public subnet traffic through the IGW
resource "aws_route" "internet_access" {
    route_table_id         = aws_vpc.main.main_route_table_id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id             = aws_internet_gateway.internet_gw.id
}

# Create a NAT gateway with an Elastic IP for each private subnet to get internet connectivity
resource "aws_eip" "nat_gw_eip" {
    #count      = var.az_count
    vpc        = true
    depends_on = [ aws_internet_gateway.internet_gw ]
}

resource "aws_nat_gateway" "nat_gw" {
    count         = var.az_count
    subnet_id     = element(aws_subnet.public.*.id, count.index)
    allocation_id = aws_eip.nat_gw_eip.id
}

# Create a new route table for private subnets, make it route none-local traffic through NAT gateway to the Internet
resource "aws_route_table" "private" {
    count = var.az_count
    vpc_id = aws_vpc.main.id 

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = element(aws_nat_gateway.nat_gw.*.id, count.index)
    }
}

# Explicitly associate the newly created route tables to the private subnets (so they don't default to the main route table)
resource "aws_route_table_association" "private" {
    count          = var.az_count
    subnet_id      = element(aws_subnet.private.*.id, count.index)
    route_table_id = element(aws_route_table.private.*.id, count.index)
}