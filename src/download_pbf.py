import os
from subprocess import check_call


def run():
    url = os.getenv("PBF_URL")
    destination_dir = os.getenv("IMPORT_DIR")
    check_call(["wget", "--no-clobber", "--directory-prefix", destination_dir, url])
