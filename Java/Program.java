import java.math.BigInteger;

public class Program {
    public static BigInteger parallelSum(long[] data, int nSlices) {
        if (data == null || data.length == 0 || nSlices == 0) {
            return BigInteger.ZERO;
        }

        int len = data.length;
        int n = Math.min(nSlices, len);
        int baseChunk = len / n;
        int remainder = len % n;

        BigInteger[] partialSums = new BigInteger[n];
        Thread[] threads = new Thread[n];

        int start = 0;
        for (int i = 0; i < n; i++) {
            int add = (i < remainder) ? 1 : 0;
            int chunkLen = baseChunk + add;
            int sliceStart = start;  // capture locals for closure, 'cause local variables referenced from a lambda expression must be final or effectively final
            int sliceEnd = start + chunkLen;

            int index = i;  // capture locals for closure, 'cause local variables referenced from a lambda expression must be final or effectively final

            threads[i] = new Thread(() -> {
                BigInteger localSum = BigInteger.ZERO;
                for (int j = sliceStart; j < sliceEnd; j++) {
                    localSum = localSum.add(BigInteger.valueOf(data[j]));
                }
                partialSums[index] = localSum;
            });
            threads[i].start();

            start = sliceEnd;
        }

        for (int i = 0; i < n; i++) {
            try {
                threads[i].join();
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                throw new RuntimeException("Thread is intentionally interrupted due to exception while waiting for one of the threads to finish its execution");
            }
        }

        BigInteger totalSum = BigInteger.ZERO;
        for (int i = 0; i < n; i++) {
            totalSum = totalSum.add(partialSums[i]);
        }
        
        return totalSum;
    }

    public static void main(String[] args) {
        int nItems = 2_000_000;
        long[] data = new long[nItems];
        for (int i = 0; i < nItems; i++) {
            data[i] = i % 1000;
        }

        int nThreads = Runtime.getRuntime().availableProcessors();
        int nSlices = nThreads;
        System.out.println(String.format("Using %d threads / slices", nSlices));

        BigInteger totalSum = parallelSum(data, nSlices);
        System.out.println(String.format("Total sum is %d", totalSum));

        BigInteger totalSumCheck = BigInteger.ZERO;
        for (long v : data) {
            totalSumCheck = totalSumCheck.add(BigInteger.valueOf(v));
        }
        System.out.println(String.format("Total sum check is %d", totalSumCheck));

        if (!totalSum.equals(totalSumCheck)) {
            throw new AssertionError("Sums are not equal!");
        }
    }
}

