output "region" {
  description = "Región usada; exporta el mismo valor en AWS_REGION para los scripts."
  value       = var.region
}

output "url_cola_solicitudes" {
  description = "URL de solicitudes-codigo (para los comandos aws sqs de las pruebas 2 y 5)."
  value       = aws_sqs_queue.solicitudes_codigo.url
}

output "url_cola_fallidas" {
  description = "URL de la DLQ solicitudes-fallidas (para la prueba 5)."
  value       = aws_sqs_queue.solicitudes_fallidas.url
}

