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

	wg.Wait()  // wait 'till all the goroutines finish

	close(results)  // close the channel with results

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
	d0 := time.Duration(time.Since(t0).Milliseconds())
	fmt.Printf("Time elapsed is %dms\n", d0)
	fmt.Printf("Total sum is %d\n\n", totalSum)

	totalSumCheck := big.NewInt(0)
	t1 := time.Now()
	for _, v := range data {
		totalSumCheck.Add(totalSumCheck, big.NewInt(v))
	}
	d1 := time.Duration(time.Since(t1).Milliseconds())
	fmt.Printf("Time elapsed is %dms\n", d1)
	fmt.Printf("Total sum check is %s\n", totalSumCheck.String())

	if totalSum.Cmp(totalSumCheck) != 0 {
		panic("Sums are not equal!")
	}
}

