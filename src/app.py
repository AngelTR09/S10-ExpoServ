import json, secrets, time, uuid
from config import sqs, QUEUE_URL

EXPIRA_SEG = 120
MAX_INTENTOS = 3

def solicitar_codigo(destino):
    codigo = f"{secrets.randbelow(10**6):06d}"
    sqs.send_message(QueueUrl=QUEUE_URL, MessageBody=json.dumps({
        "id": str(uuid.uuid4()),
        "destino": destino,
        "codigo": codigo,
    }))
    print("Solicitud enviada a la cola. Revisa tu correo.")
    return codigo, time.time()

destino = input("Correo: ").strip()
codigo, creado = solicitar_codigo(destino)

intentos = 0
while intentos < MAX_INTENTOS:
    entrada = input("Ingresa el código (R = reenviar): ").strip()
    if entrada.upper() == "R":
        codigo, creado = solicitar_codigo(destino)
        continue
    if time.time() - creado > EXPIRA_SEG:
        print("Código expirado. Escribe R para pedir otro.")
        continue
    intentos += 1
    if entrada == codigo:
        print("Verificado correctamente")
        break
    print(f"Código incorrecto ({MAX_INTENTOS - intentos} intentos restantes)")
else:
    print("Demasiados intentos. Cuenta bloqueada temporalmente.")
