package main

import (
	"fmt"
	"math/big"
	"runtime"
	"sync"
	"time"
)

// parallelSum calculaes sums of the elements in `data` using nSlices of goroutines.
// Returns *big.Int to avoid overflow in case of very large sums
func parallelSum(data []int64, nSlices int) *big.Int {
	if len(data) == 0 || nSlices == 0 {
		return big.NewInt(0)
	}

	dataLen := len(data)
	n := min(nSlices, dataLen)
	base := dataLen / n
	remainder := dataLen % n

	var wg sync.WaitGroup  // just declaring the value with no assignment, this var; will be zero-initialized like all the int64 to 0 and so on
	results := make(chan *big.Int, n)  // channel of type big.Int and size n; some kind of job area of operations
	
	start := 0
	for i := range n {
		add := 0
		if i < remainder {
			add = 1
		}
		chunkLen := base + add
		end := start + chunkLen

		// capture locals, so if goroutine starts after the i is incremented it won't see changed one
		s := start
		e := end

		wg.Go(func () {
			partialSum := big.NewInt(0)
			for j := s; j < e; j++ {
				partialSum.Add(partialSum, big.NewInt(data[j]))
			}
			results <- partialSum  // send partial to result channel
		})

		start = end
	}

	// run in a separate goroutine to avoid deadlock, because wg.Wait() blocks untill workers finish, but workers can't fully finish their ... <- ... when main is blocked by wg.Wait
	// our goroutines need free of waiting main to be ready to receive data from the channels
	// in some cases wg.Wait may happen before some (one or more) goroutines reaches its ... <- ... data passing through the channel state, which expects reading of itself
	go func() {
		wg.Wait()  // wait 'till all the goroutines finish
		// close the channel with results, so we can continue on main thread summing up those partial sums, otherwise loop below gonna wait forever
		// in other words close() make the channel finilized and ensuring no more data gonna pass through it, so the receiver know exactly when to stop reading
		// otherwise it is gonna wait forever and be deadlocked
		close(results)
	}()  // () at the end make the lambda start immediately, and with 'go' it starts in goroutine

	totalSum := big.NewInt(0)
	for v := range results {
		totalSum.Add(totalSum, v)
	}

	return totalSum
}

func main() {
	nItems := 2_000_000
	data := make([]int64, nItems)
	for i := range nItems {
		data[i] = int64(i % 1000)
	}

	nThreads := runtime.NumCPU()
	nSlices := nThreads
	fmt.Printf("Using %d threads / slices\n", nSlices)

	t0 := time.Now()
	totalSum := parallelSum(data, nSlices)
	fmt.Printf("Time elapsed is %dms\n", time.Duration(time.Since(t0).Milliseconds()))
	fmt.Printf("Total sum is %d\n\n", totalSum)

	totalSumCheck := big.NewInt(0)
	t1 := time.Now()
	for _, v := range data {
		totalSumCheck.Add(totalSumCheck, big.NewInt(v))
	}
	fmt.Printf("Time elapsed is %dms\n", time.Duration(time.Since(t1).Milliseconds()))
	fmt.Printf("Total sum check is %s\n", totalSumCheck.String())

	if totalSum.Cmp(totalSumCheck) != 0 {
		panic("Sums are not equal!")
	}
}

