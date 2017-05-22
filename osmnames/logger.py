import logging
import datetime


def setup(name):
    formatter = logging.Formatter(fmt='%(asctime)s - %(levelname)s - %(module)s - %(message)s')

    logger = logging.getLogger(name)
    logger.setLevel(logging.DEBUG)

    stream_handler = logging.StreamHandler()
    stream_handler.setFormatter(formatter)
    logger.addHandler(stream_handler)

    timestamp = datetime.datetime.now().strftime('%Y_%m_%d-%H%M')

    file_handler = logging.FileHandler("data/logs/{}.log".format(timestamp))
    file_handler.setFormatter(formatter)
    logger.addHandler(file_handler)

    return logger
