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

