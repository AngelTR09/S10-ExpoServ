# S10: Amazon SQS vs Amazon SNS

Este proyecto despliega con Terraform una cola SQS, una cola de fallidos, un tema SNS y una cola de auditoría, y los usa con cinco scripts de Python que simulan un envío de código de verificación por correo. Sirve para ver en la práctica qué hace cada servicio y qué pasa cuando falta uno.

```
terraform/        main.tf, variables.tf, outputs.tf
src/              config.py, app.py, worker.py, auditor.py, app_directo.py, carga.py
requirements.txt
README.md
```

Los comandos parten de la carpeta raíz, la que contiene `terraform/` y `src/`. Terraform se llama con `-chdir=terraform`, así que no hace falta entrar en esa carpeta. Los scripts de Python sí se ejecutan dentro de `src/`.

Se crean tres colas (`solicitudes-codigo`, `solicitudes-fallidas` y `auditoria`) y un tema (`codigos-verificacion`).

## 1. Requisitos

Hacen falta Terraform 1.8 o superior, AWS CLI v2 y Python 3.9 o superior. Las credenciales deben tener permisos sobre SQS y SNS; en el laboratorio se usa el rol `S10-SQS-SNS` a través del perfil `s10-sqs-sns`. Las dependencias de Python se instalan con `pip install -r requirements.txt`. Para las pruebas conviene tener cuatro terminales abiertas.

## 2. Desplegar

En cada terminal se cargan estas variables:

```bash
export AWS_PROFILE=s10-sqs-sns       # perfil que asume el rol S10-SQS-SNS
export AWS_REGION=us-east-2          # misma región para Terraform y Python
export TF_VAR_region=$AWS_REGION
```

En la terminal donde corre Terraform se agrega el correo que recibirá los códigos. Queda solo en esa sesión y no se escribe en el repositorio.

```bash
export TF_VAR_correo_destino="tu_correo@ejemplo.com"

terraform -chdir=terraform init
terraform -chdir=terraform plan
terraform -chdir=terraform apply
```

El plan debe anunciar 7 recursos nuevos. Al terminar, `terraform output` muestra las URLs de las colas y el ARN del tema. Esos valores se exportan para las pruebas:

```bash
export QUEUE_URL=$(terraform -chdir=terraform output -raw url_cola_solicitudes)
export DLQ_URL=$(terraform -chdir=terraform output -raw url_cola_fallidas)
export AUDIT_URL=$(terraform -chdir=terraform output -raw url_cola_auditoria)
export TOPIC_ARN=$(terraform -chdir=terraform output -raw arn_tema)
cd src
```

Los scripts leen `QUEUE_URL`, `AUDIT_URL` y `TOPIC_ARN` del entorno, así que hay que exportarlas en cada terminal donde se vaya a correr uno. Sin ellas, `config.py` termina con `KeyError`.

Captura 1: el final de `terraform apply` (`Apply complete! Resources: 7 added`) junto con `terraform output`.

## 3. Confirmar la suscripción del correo

SNS no entrega nada a un correo que no haya confirmado. AWS manda un mensaje con el asunto "AWS Notification - Subscription Confirmation" (si no aparece, está en spam) y hay que pulsar **Confirm subscription**. Después se comprueba:

```bash
aws sns list-subscriptions-by-topic --topic-arn "$TOPIC_ARN"
```

La suscripción del correo debe mostrar un ARN completo y no `PendingConfirmation`. La de la cola aparece confirmada desde el principio, porque la cola y el tema son de la misma cuenta.

Para confirmar que Python ve la configuración:

```bash
python3 -c "import config; print(config.TOPIC_ARN)"
```

Captura 2: el correo de confirmación y la salida de `list-subscriptions-by-topic`.

Captura 3: la consola de SQS con las tres colas y, en `solicitudes-codigo`, la pestaña de cola de mensajes fallidos con la DLQ y `maxReceiveCount = 3`.

