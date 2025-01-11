import logging
from src import parse_arguments
from src import SQSManager
from src import WebScraper


def run_scraper(sqs_client):
    logging.info("Starting scraper...")
    scraper = WebScraper()
    result = scraper.start()
    if result and sqs_client:
        sqs_client.send_message(result)
        logging.info(f"Message sent to queue: {result}")


def main():
    logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

    args = parse_arguments()

    sender = SQSManager(
        queue_url=args.queue_url,
        aws_access_key_id=args.aws_access_key_id,
        aws_secret_access_key=args.aws_secret_access_key,
        region_name=args.region_name
    )

    while True:
        run_scraper(sender)


if __name__ == "__main__":
    main()
