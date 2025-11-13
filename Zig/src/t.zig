pub fn main() !void {
    const std = @import("std");
    const builtin = @import("builtin");
    std.debug.print("{any}", .{builtin.os});
    // std.debug.print("{any}", .{6});
}
