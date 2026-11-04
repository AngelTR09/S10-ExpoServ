import json
from config import sqs, sns, QUEUE_URL, TOPIC_ARN

print("👂 Esperando solicitudes...")
while True:
    resp = sqs.receive_message(
        QueueUrl=QUEUE_URL,
        MaxNumberOfMessages=1,
        WaitTimeSeconds=20,              # long polling
        AttributeNames=["ApproximateReceiveCount"],
    )
    for msg in resp.get("Messages", []):
        intento = msg["Attributes"]["ApproximateReceiveCount"]
        try:
            data = json.loads(msg["Body"])
            destino, codigo = data["destino"], data["codigo"]   # falla si el cuerpo está mal formado
            sns.publish(
                TopicArn=TOPIC_ARN,
                Subject="Tu código de verificación",
                Message=f"Hola {destino}, tu código es {codigo}. Expira en 2 minutos.",
            )
            sqs.delete_message(QueueUrl=QUEUE_URL, ReceiptHandle=msg["ReceiptHandle"])
            print(f"✔ Código enviado a {destino} (intento {intento})")
        except Exception as e:
            # sin borrar: reaparece a los 10 s
            print(f"✘ Error en intento {intento}: {e}")
