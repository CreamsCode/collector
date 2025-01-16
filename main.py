import logging
from src import parse_arguments
from src import SQSManager
from src import WebScraper


def run_scraper(sqs_client):
    logging.info("Starting scraper...")
    scraper = WebScraper()
    result = scraper.start()

    if result:
        try:
            logging.info(f"Sending result to SQS: {result}")
            sqs_client.send_message(result)
        except Exception as e:
            logging.error(f"Failed to send message to SQS: {e}")
    else:
        logging.warning("No data processed by the scraper.")


def main():
    logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")

    args = parse_arguments()

    sender = SQSManager(
        queue_url=args.queue_url,
        region_name=args.region_name
    )

    while True:
        run_scraper(sender)


if __name__ == "__main__":
    main()
