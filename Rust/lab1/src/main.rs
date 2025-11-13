use std::sync::Arc;
use std::thread;
use std::time::Instant;

// data is wrapped in Arc, so threads can share it without making copies
// return i128 - safe bet in case of large sums
fn parallel_sum(data: Arc<Vec<i64>>, n_slices: usize) -> i128 {
    if data.is_empty() || n_slices == 0 {
        return 0;
    }

    let len = data.len();
    // do not make more slices than elements
    let n = n_slices.min(len);
    let base = len / n;  // minimal chunk size
    let remainder = len % n;  // firts remainder chunks get one more element

    let mut handlers = Vec::with_capacity(n);
    let mut start = 0usize;

    for i in 0..n {
        // distribute the remainder among first chunks
        let add = if i < remainder { 1 } else { 0 };
        let chunk_len = base + add;
        let end = start + chunk_len;

        let data_clone = data.clone();  // cheap arc pointer clone

        let handler = thread::spawn(move || -> i128 {
            let slice = &data_clone[start..end];

            let mut partial_sum = 0i128;
            for &v in slice.iter() {
                partial_sum += v as i128;
            }

            partial_sum
        });

        handlers.push(handler);
        start = end;
    }

    let mut total_sum = 0i128;
    for h in handlers {
        total_sum += h.join().expect("thread panicked");
    }

    total_sum
}

fn main() {
    let n_items = 2_000_000usize;
    let mut data_raw = Vec::with_capacity(n_items);
    for i in 0..n_items {
        data_raw.push((i % 1000) as i64);
    }

    let data = Arc::new(data_raw);

    // calculate optimal number of threads per system to use in program;
    // extract value from Result or default to 4
    let n_threads = thread::available_parallelism()
        .map(|n| n.get())
        .unwrap_or(4);

    let n_slices = n_threads;
    println!("Using {n_slices} threads / slices");

    let start_parallel = Instant::now();
    let total_sum = parallel_sum(Arc::clone(&data), n_slices);
    let duration_parallel = start_parallel.elapsed().as_millis();
    println!("Total sum is {total_sum}");
    println!("Elapsed time is {duration_parallel} ms");

    let start_single = Instant::now();
    // dereference each value from iter() and apply i128 conversion
    let total_sum_check: i128 = data.iter().map(|&x| x as i128).sum();
    let duration_single = start_single.elapsed().as_millis();
    println!("Total sum check is {total_sum_check}");
    println!("Elapsed time is {duration_single} ms");

    assert_eq!(total_sum, total_sum_check);
}

