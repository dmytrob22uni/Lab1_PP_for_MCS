const std = @import("std");

const SliceArg = struct {
    data: []const i64,
    out: *i128,
};

fn slice_sum(arg: *SliceArg) void {
    var s: i128 = 0;
    for (arg.data) |v| {
        s += @as(i128, v);
    }
    arg.out.* = s;
}

fn parallel_sum(data: []const i64, n_slices: usize) !i128 {
    const allocator = std.heap.page_allocator;
    const N = data.len;

    if (n_slices == 0) return error.InvalidSliceCount;

    // allocate per-slice results
    var results = try allocator.alloc(i128, n_slices);
    defer allocator.free(results);

    // allocate per-slice args
    var args = try allocator.alloc(SliceArg, n_slices);
    defer allocator.free(args);

    // allocate per-slice thread handles
    var threads = try allocator.alloc(std.Thread, n_slices);
    defer allocator.free(threads);

    const base_chunk = if (n_slices > 0) N / n_slices else 0;
    var start: usize = 0;
    var spawned: usize = 0;
    while (spawned < n_slices) : (spawned += 1) {
        const is_last = (spawned == n_slices - 1);
        const len: usize = if (is_last) N - start else base_chunk;

        args[spawned] = SliceArg{
            .data = data[start .. start + len],
            .out = &results[spawned],
        };

        threads[spawned] = try std.Thread.spawn(
            .{},
            slice_sum,
            .{ &args[spawned]
        });

        start += len;
    }

    // Join threads and sum the sums results
    var total: i128 = 0;
    for (threads[0..spawned], 0..) |t, i| {
        t.join();
        total += results[i];
    }

    return total;
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const N: usize = 2_000_000;
    const cpu_count = 16;  // Cause it works for my arch

    const n_slices: usize = cpu_count; std.debug.print("Using {d}\n threads / slices", .{ n_slices });

    const data = try allocator.alloc(i64, N);
    defer allocator.free(data);

    // fill with i % 1000
    for (data, 0..) |*slot, i| {
        slot.* = @intCast(i % 1000);
    }

    // call the refactored function
    const total = try parallel_sum(data, n_slices);

    std.debug.print("Total sum is {d}\n", .{ total });

    // regular (sequential) total
    var total_check: i128 = 0;
    for (data) |v| {
        total_check += @as(i128, v);
    }

    std.debug.assert(total == total_check);
    if (total != total_check) {
        std.debug.panic("Totals differ: threaded = {d}, regular = {d}\n", .{ total, total_check });
    }

    std.debug.print("Total sum check is {d}\n", .{ total_check });
}

