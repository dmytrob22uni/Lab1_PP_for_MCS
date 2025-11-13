import threading
import os
import time
from typing import List


def parallel_sum(data: List[int], n_slices: int) -> int:
    if not data or n_slices <= 0:
        return 0

    length = len(data)
    n = min(n_slices, length)
    base = length // n
    remainder = length % n

    threads = []
    partial_sums = [0] * n

    def worker(idx: int, start: int, end: int):
        partial_sum = 0
        for i in range(start, end):
            partial_sum += data[i]
        partial_sums[idx] = partial_sum

    start = 0
    for i in range(n):
        add = 1 if i < remainder else 0
        chunk_len = base + add
        end = start + chunk_len

        t = threading.Thread(target=worker, args=(i, start, end), daemon=False)
        threads.append(t)
        t.start()

        start = end

    for t in threads:
        t.join()

    total_sum = 0
    for value in partial_sums:
        total_sum += value

    return total_sum


if __name__ == "__main__":
    n_items = 2_000_000
    data = [(i % 1000) for i in range(n_items)]

    n_threads = os.cpu_count() or 4
    n_slices = n_threads
    print("Using ", n_slices, " threads / slices")

    start_parallel = time.perf_counter()
    total = parallel_sum(data, n_slices)
    end_parallel = time.perf_counter()
    duration_parallel = (end_parallel - start_parallel) * 1000
    print("Total sum is ", total)
    print(f"Elapsed time is {duration_parallel:.0f} ms")

    start_single = time.perf_counter()
    total_check = sum(data)
    end_single = time.perf_counter()
    duration_single = (end_single - start_single) * 1000
    print("Total sum check is ", total_check)
    print(f"Elapsed time is {duration_single:.0f} ms")

    assert total == total_check

