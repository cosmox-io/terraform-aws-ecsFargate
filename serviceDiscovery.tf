resource "aws_service_discovery_private_dns_namespace" "example" {
  name        = var.serviceDiscoveryNameSpace
  vpc         = aws_vpc.main.id
}

resource "aws_service_discovery_service" "example" {
  name = var.service_discovery_serviceName

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.example.id
    routing_policy = var.routing_policy

    dns_records {
      ttl  = var.ttl
      type = var.sd_dns_record_type
    }
  }
}