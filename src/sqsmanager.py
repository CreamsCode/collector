import boto3
import json
import gzip
import base64

class SQSManager:
    def __init__(self, queue_url, aws_access_key_id, aws_secret_access_key, region_name="us-east-1"):
        self.queue_url = queue_url
        self.client = boto3.client(
            'sqs',
            region_name=region_name
        )

    def send_message(self, message_body):
        def send_message(self, message_body):
            # Convertir el mensaje a JSON y comprimirlo
            message_json = json.dumps(message_body).encode('utf-8')
            compressed_message = base64.b64encode(gzip.compress(message_json)).decode('utf-8')

            print(f"Compressed message size: {len(compressed_message)} bytes")
            if len(compressed_message) > 262144:
                raise ValueError("Compressed message size exceeds 256 KB limit.")

            response = self.client.send_message(
                QueueUrl=self.queue_url,
                MessageBody=compressed_message
            )
            return response
