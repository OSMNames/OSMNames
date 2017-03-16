import os
from subprocess import check_call


def psql_exec(file_path, user=os.getenv('PGUSER')):
    check_call(
        [
            "psql",
            "--username={}".format(user),
            "--file={}".format(file_path)
        ]
    )
