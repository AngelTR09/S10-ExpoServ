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

# 3. Tema SNS
resource "aws_sns_topic" "codigos_verificacion" {
  name = "codigos-verificacion"
}

# Queda pendiente hasta que la persona confirme el correo de AWS.
resource "aws_sns_topic_subscription" "correo" {
  topic_arn = aws_sns_topic.codigos_verificacion.arn
  protocol  = "email"
  endpoint  = var.correo_destino
}

# 4. Cola de auditoría (fan-out)
resource "aws_sqs_queue" "auditoria" {
  name = "auditoria"

  # Long polling: espera hasta 20 s en lugar de responder vacío.
  receive_wait_time_seconds = 20
}

# Solo este tema puede escribir en la cola (evita el "confused deputy").
data "aws_iam_policy_document" "sns_escribe_en_auditoria" {
  statement {
    sid       = "PermitirSoloAlTemaCodigosVerificacion"
    effect    = "Allow"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.auditoria.arn]

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.codigos_verificacion.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "auditoria" {
  queue_url = aws_sqs_queue.auditoria.id
  policy    = data.aws_iam_policy_document.sns_escribe_en_auditoria.json
}

resource "aws_sns_topic_subscription" "auditoria" {
  topic_arn = aws_sns_topic.codigos_verificacion.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.auditoria.arn

  # Entrega el texto tal cual, sin el sobre JSON de SNS (se pierde el Subject).
  raw_message_delivery = true

  # La política debe existir antes de suscribir.
  depends_on = [aws_sqs_queue_policy.auditoria]
}
