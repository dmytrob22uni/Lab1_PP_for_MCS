using System.Numerics;

int nItems = 2_000_000;
long[] data = new long[nItems];
for (int i = 0; i < nItems; i++)
{
    data[i] = (i % 1000);
}

int nThreads = Environment.ProcessorCount;
int nSlices = nThreads;
Console.WriteLine($"Using {nSlices} threads / slices");

BigInteger totalSum = ParallelSum(data, nSlices);
Console.WriteLine($"Total sum is {totalSum}");

BigInteger totalSumCheck = BigInteger.Zero;
for (int i = 0; i < data.Length; i++)
{
    totalSumCheck += data[i];
}
Console.WriteLine($"Total sum check is {totalSumCheck}");

if (totalSum != totalSumCheck)
{
    throw new Exception("Sums are not equal!");
}

static BigInteger ParallelSum(long[] data, int nSlices) {
    if (data == null || data.Length == 0 || nSlices == 0)
    {
        return BigInteger.Zero;
    }

    int len = data.Length;
    int n = Math.Min(nSlices, len);
    int baseChunk = len / n;
    int remainder = len % n;

    BigInteger[] partialSums = new BigInteger[n];
    Thread[] threads = new Thread[n];

    int start = 0;
    for (int i = 0; i < n; i++)
    {
        int add = (i < remainder) ? 1 : 0;
        int chunkLen = baseChunk + add;
        int sliceStart = start;  // capture locals for closure, 'cause loop variables in for loops are mutable and reused across iterations
        int sliceEnd = start + chunkLen;

        int index = i;  // capture locals for closure, 'cause loop variables in for loops are mutable and reused across iterations

        threads[i] = new Thread(() => {
            BigInteger localSum = BigInteger.Zero;
            for (int j = sliceStart; j < sliceEnd; j++)
            {
                localSum += data[j];
            }
            partialSums[index] = localSum;
        });
        threads[i].Start();

        start = sliceStart;
    }

    for (int i = 0; i < n; i++)
    {
        threads[i].Join();
    }

    BigInteger totalSum = BigInteger.Zero;
    for (int i = 0; i < n; i++)
    {
        totalSum += partialSums[i];
    }

    return totalSum;
}

