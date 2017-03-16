import os
from subprocess import check_call


def psql_exec(file_path, user=os.getenv('PGUSER')):
    check_call(
        [
            "psql",
            "-u {1]".format(user),
            "-f {1}".format(file_path)
        ]
    )
