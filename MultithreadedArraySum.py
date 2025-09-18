import threading
import time
import random


class ArraySumCalculator:
    def __init__(self, array, num_threads):
        self.array = array
        self.num_threads = num_threads
        self.partial_sums = [0] * num_threads
        self.threads = []
        self.lock = threading.Lock()

    def calculate_partial_sum(self, thread_id, start_index, end_index):
        """Обчислює частинну суму для певного діапазону масиву"""
        partial_sum = 0
        for i in range(start_index, end_index):
            partial_sum += self.array[i]

        # Синхронізація запису результату
        with self.lock:
            self.partial_sums[thread_id] = partial_sum
            print(f"Потік {thread_id}: обчислено суму діапазону [{start_index}:{end_index}] = {partial_sum}")

    def calculate_total_sum(self):
        """Головний метод для обчислення загальної суми"""
        array_length = len(self.array)
        chunk_size = array_length // self.num_threads

        print(f"Розділяємо масив з {array_length} елементів на {self.num_threads} частин")
        print(f"Розмір кожної частини: ~{chunk_size} елементів")

        # Створення та запуск потоків
        for i in range(self.num_threads):
            start_index = i * chunk_size
            if i == self.num_threads - 1:  # Останній потік обробляє залишок
                end_index = array_length
            else:
                end_index = (i + 1) * chunk_size

            thread = threading.Thread(
                target=self.calculate_partial_sum,
                args=(i, start_index, end_index)
            )
            self.threads.append(thread)
            thread.start()

        # Очікування завершення всіх потоків
        for thread in self.threads:
            thread.join()

        # Підсумовування результатів
        total_sum = sum(self.partial_sums)
        return total_sum


def main():
    # Створення масиву з 500000+ елементів
    array_size = 500000
    print(f"Генерація масиву з {array_size} випадкових чисел...")

    # Генерація масиву випадкових чисел від 1 до 100
    array = [random.randint(1, 100) for _ in range(array_size)]

    num_threads = 8  # Кількість потоків

    # Обчислення з використанням потоків
    print(f"\n=== Багатопотокове обчислення ({num_threads} потоків) ===")
    start_time = time.time()

    calculator = ArraySumCalculator(array, num_threads)
    multithreaded_sum = calculator.calculate_total_sum()

    multithreaded_time = time.time() - start_time

    # Обчислення без потоків для порівняння
    print("\n=== Однопотокове обчислення (для порівняння) ===")
    start_time = time.time()
    single_threaded_sum = sum(array)
    single_threaded_time = time.time() - start_time

    # Виведення результатів
    print("\n=== РЕЗУЛЬТАТИ ===")
    print(f"Розмір масиву: {len(array)} елементів")
    print(f"Кількість потоків: {num_threads}")
    print(f"Багатопотокова сума: {multithreaded_sum}")
    print(f"Однопотокова сума: {single_threaded_sum}")
    print(f"Результати збігаються: {multithreaded_sum == single_threaded_sum}")
    print(f"Час багатопотокового обчислення: {multithreaded_time:.4f} сек")
    print(f"Час однопотокового обчислення: {single_threaded_time:.4f} сек")

    if single_threaded_time > 0:
        speedup = single_threaded_time / multithreaded_time
        print(f"Прискорення: {speedup:.2f}x")


if __name__ == "__main__":
    main()
