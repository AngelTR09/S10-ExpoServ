variable "region" {
  description = "Región de AWS donde se crea todo. Debe coincidir con la variable de entorno AWS_REGION que leen los scripts de Python."
  type        = string
  # Región de la cuenta del grupo.
  default = "us-east-2"
}

