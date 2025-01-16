import argparse

def parse_arguments():

    parser = argparse.ArgumentParser(description="Servicio de Scraper con integración SQS")

    parser.add_argument("--queue_url", type=str, required=True, help="URL de la cola de SQS")
    parser.add_argument("--region_name", type=str, default="us-east-1", help="Región de AWS")

    return parser.parse_args()
