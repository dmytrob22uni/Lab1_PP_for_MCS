import java.util.Random;
import java.util.concurrent.*;

public class MultithreadedArraySum {
    
    static class SumCalculatorTask implements Callable<Long> {
        private final int[] array;
        private final int startIndex;
        private final int endIndex;
        private final int threadId;
        
        public SumCalculatorTask(int[] array, int startIndex, int endIndex, int threadId) {
            this.array = array;
            this.startIndex = startIndex;
            this.endIndex = endIndex;
            this.threadId = threadId;
        }
        
        @Override
        public Long call() throws Exception {
            long partialSum = 0;
            
            for (int i = startIndex; i < endIndex; i++) {
                partialSum += array[i];
            }
            
            System.out.printf("Потік %d: обчислено суму діапазону [%d:%d] = %d%n", 
                            threadId, startIndex, endIndex, partialSum);
            
            return partialSum;
        }
    }
    
    public static long calculateSumMultithreaded(int[] array, int numThreads) 
            throws InterruptedException, ExecutionException {
        
        ExecutorService executor = Executors.newFixedThreadPool(numThreads);
        int arrayLength = array.length;
        int chunkSize = arrayLength / numThreads;
        
        System.out.printf("Розділяємо масив з %d елементів на %d частин%n", 
                         arrayLength, numThreads);
        System.out.printf("Розмір кожної частини: ~%d елементів%n", chunkSize);
        
        // Створення завдань для кожного потоку
        Future<Long>[] futures = new Future[numThreads];
        
        for (int i = 0; i < numThreads; i++) {
            int startIndex = i * chunkSize;
            int endIndex = (i == numThreads - 1) ? arrayLength : (i + 1) * chunkSize;
            
            SumCalculatorTask task = new SumCalculatorTask(array, startIndex, endIndex, i);
            futures[i] = executor.submit(task);
        }
        
        // Збирання результатів від усіх потоків
        long totalSum = 0;
        for (int i = 0; i < numThreads; i++) {
            totalSum += futures[i].get(); // Синхронне очікування результату
        }
        
        executor.shutdown();
        return totalSum;
    }
    
    public static long calculateSumSingleThreaded(int[] array) {
        long sum = 0;
        for (int value : array) {
            sum += value;
        }
        return sum;
    }
    
    public static void main(String[] args) {
        try {
            // Створення масиву з 500000+ елементів
            int arraySize = 500000;
            System.out.printf("Генерація масиву з %d випадкових чисел...%n", arraySize);
            
            Random random = new Random();
            int[] array = new int[arraySize];
            
            // Заповнення масиву випадковими числами від 1 до 100
            for (int i = 0; i < arraySize; i++) {
                array[i] = random.nextInt(100) + 1;
            }
            
            int numThreads = 8; // Кількість потоків
            
            // Багатопотокове обчислення
            System.out.printf("%n=== Багатопотокове обчислення (%d потоків) ===%n", numThreads);
            long startTime = System.nanoTime();
            
            long multithreadedSum = calculateSumMultithreaded(array, numThreads);
            
            long multithreadedTime = System.nanoTime() - startTime;
            
            // Однопотокове обчислення для порівняння
            System.out.printf("%n=== Однопотокове обчислення (для порівняння) ===%n");
            startTime = System.nanoTime();
            
            long singleThreadedSum = calculateSumSingleThreaded(array);
            
            long singleThreadedTime = System.nanoTime() - startTime;
            
            // Виведення результатів
            System.out.printf("%n=== РЕЗУЛЬТАТИ ===%n");
            System.out.printf("Розмір масиву: %d елементів%n", array.length);
            System.out.printf("Кількість потоків: %d%n", numThreads);
            System.out.printf("Багатопотокова сума: %d%n", multithreadedSum);
            System.out.printf("Однопотокова сума: %d%n", singleThreadedSum);
            System.out.printf("Результати збігаються: %b%n", 
                            multithreadedSum == singleThreadedSum);
            System.out.printf("Час багатопотокового обчислення: %.4f сек%n", 
                            multithreadedTime / 1_000_000_000.0);
            System.out.printf("Час однопотокового обчислення: %.4f сек%n", 
                            singleThreadedTime / 1_000_000_000.0);
            
            if (singleThreadedTime > 0) {
                double speedup = (double) singleThreadedTime / multithreadedTime;
                System.out.printf("Прискорення: %.2fx%n", speedup);
            }
            
        } catch (Exception e) {
            System.err.println("Помилка: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
