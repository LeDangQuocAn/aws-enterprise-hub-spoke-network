output "transit_gateway_id" {
  description = "ID of the core Transit Gateway."
  value       = aws_ec2_transit_gateway.core.id
}

output "transit_gateway_arn" {
  description = "ARN of the core Transit Gateway."
  value       = aws_ec2_transit_gateway.core.arn
}

output "transit_gateway_owner_id" {
  description = "AWS account ID that owns the Transit Gateway."
  value       = aws_ec2_transit_gateway.core.owner_id
}

output "transit_gateway_default_route_table_association" {
  description = "Default association setting for the Transit Gateway."
  value       = aws_ec2_transit_gateway.core.default_route_table_association
}

output "transit_gateway_default_route_table_propagation" {
  description = "Default propagation setting for the Transit Gateway."
  value       = aws_ec2_transit_gateway.core.default_route_table_propagation
}
