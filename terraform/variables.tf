variable "region" {
  description = "Región de AWS donde se crea todo. Debe coincidir con la variable de entorno AWS_REGION que leen los scripts de Python."
  type        = string
  # Región de la cuenta del grupo.
  default = "us-east-2"
}

variable "correo_destino" {
  description = "Correo que recibe los códigos de verificación por SNS. Se pasa con TF_VAR_correo_destino o en un terraform.tfvars (ignorado por git); nunca se escribe en el código."
  type        = string

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.correo_destino))
    error_message = "correo_destino debe ser una dirección de correo válida."
  }
}
