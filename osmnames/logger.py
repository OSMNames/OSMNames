from subprocess import check_call
import logging
import datetime


def setup(name):
    formatter = logging.Formatter(fmt='%(asctime)s - %(levelname)s - %(message)s')

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


log = setup(__name__)


def logged_check_call(parameters):
    log.info("run {command}".format(command=' '.join(parameters)))
    check_call(parameters)
    log.info("finished")
