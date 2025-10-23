const std = @import("std");
const builtin = @import("builtin");

const SliceArg = struct {
    data: []const i64,  // read only in thread; passed by value, 'cause slice is just a pointer and slice len - 8 + 8 = 16 bytes of data
    out: *i128,  // to pass reference of the 'out' in thread, not its copy
};

fn slice_sum(arg: *SliceArg) void {
    var s: i128 = 0;
    for (arg.data) |v| {
        s += @as(i128, v);
    }
    arg.out.* = s;
}

fn parallel_sum(data: []const i64, n_slices: usize) !i128 {  // ! means possible error in func scope
    const allocator = std.heap.page_allocator;
    const N = data.len;

    if (n_slices == 0) return 0;

    // allocate per-slice results
    var results = try allocator.alloc(i128, n_slices);
    defer allocator.free(results);

    // allocate per-slice args
    var args = try allocator.alloc(SliceArg, n_slices);
    defer allocator.free(args);

    // allocate per-slice thread handles
    var threads = try allocator.alloc(std.Thread, n_slices);
    defer allocator.free(threads);

    const base_chunk = N / n_slices;
    var start: usize = 0;
    var spawned: usize = 0;
    while (spawned < n_slices) : (spawned += 1) {  // (.. < ..) - before each cycle; : ( .. + ..) - after each cycle and 'continue'
        const is_last = (spawned == n_slices - 1);
        const len: usize = if (is_last) N - start else base_chunk;

        args[spawned] = SliceArg {
            .data = data[start .. start + len],
            .out = &results[spawned],
        };

        threads[spawned] = try std.Thread.spawn(
            .{},  // default SpawnConfig
            slice_sum,  // function to execute
            .{ &args[spawned] }  // args for function (reference as required by the function)
        );

        start += len;
    }

    // Join threads and sum the sums results
    var total: i128 = 0;
    for (threads, 0..) |t, i| {
        t.join();
        total += results[i];
    }

    return total;
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const N: usize = 2_000_000;
    // TODO: const cpu_count = builtin.cpu.features.ints;  // Cause it works for my architecture
    const cpu_count = 16;

    const n_slices: usize = cpu_count;
    std.debug.print("Using {d} threads / slices\n", .{ n_slices });

    const data = try allocator.alloc(i64, N);
    defer allocator.free(data);  // when scope exits (deref) - free the allocated memory (.free())

    // fill with i % 1000
    for (data, 0..) |*slot, i| {  // pointer to the array and its index
        // dereference the pointer to access value (.* - access member 'dereferenced pointer value')
        // make it match i64 type of the i % 1000 result
        slot.* = @intCast(i % 1000);
    }

    const total = try parallel_sum(data, n_slices);

    std.debug.print("Total sum is {d}\n", .{total});  // .{} - anonymous struct

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

