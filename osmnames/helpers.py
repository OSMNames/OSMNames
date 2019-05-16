from multiprocessing import Process


def run_in_parallel(*fns):
    proc = []
    for fn in fns:
        p = Process(target=fn)
        p.start()
        proc.append(p)

    for p in proc:
        p.join()
        assert p.exitcode == 0
