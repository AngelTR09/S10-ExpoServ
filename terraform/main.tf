# Tarea S10: SQS + SNS. Las fuentes oficiales de cada parámetro están en el README.

terraform {
  required_version = ">= 1.8"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region

  # Etiquetas para identificar y limpiar los recursos.
  default_tags {
    tags = {
      Project = "s10-sqs-sns"
      Env     = "lab"
    }
  }
}

# 1. Cola de fallidos (DLQ)
resource "aws_sqs_queue" "solicitudes_fallidas" {
  name = "solicitudes-fallidas"

  # 14 días, el máximo; debe retener más que la cola de origen.
  message_retention_seconds = 1209600
}

# 2. Cola principal con redrive hacia la DLQ
resource "aws_sqs_queue" "solicitudes_codigo" {
  name = "solicitudes-codigo"

  # Segundos invisible tras recibirse. AWS usa 30 por defecto; 10 hace visibles los reintentos.
  visibility_timeout_seconds = 10

  # 4 días, el valor por defecto, escrito para compararlo con la DLQ.
  message_retention_seconds = 345600

  # A la tercera recepción sin borrar, el mensaje pasa a la DLQ.
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.solicitudes_fallidas.arn
    maxReceiveCount     = 3
  })
}

