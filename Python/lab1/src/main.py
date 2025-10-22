import threading
import os
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

    total = parallel_sum(data, n_slices)
    print("Total sum is ", total)

    total_check = sum(data)
    print("Total sum check is ", total_check)

    assert total == total_check

