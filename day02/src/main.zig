const std = @import("std");


const ParseError = error {
    NoDashFound,
};


pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    const allocator = gpa.allocator();
    defer {
        if (gpa.deinit() == .leak) {
            std.debug.print("Memory was leaked! D:\n", .{});
        }
    }


    var stdin_buf: [1024]u8 = undefined;
    var stdout_buf: [1024]u8 = undefined;

    var stdin_reader = std.fs.File.stdin().reader(&stdin_buf);
    const stdin = &stdin_reader.interface;

    var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
    const stdout = &stdout_writer.interface;
    defer stdout.flush() catch {};


    if (std.os.argv.len != 2) {
        std.debug.print("Usage: {s} [--part1/--part2]\n", .{ std.os.argv[0] });
        std.posix.exit(1);
    }


    var result: u64 = 0;
    if (std.mem.eql(u8, std.mem.span(std.os.argv[1]), "--part2")) {
        result = try part2(allocator, stdin, stdout);
    } else {
        result = try part1(allocator, stdin, stdout);
    }

    try stdout.print("Result: {}\n", .{ result });
}


fn part1(allocator: std.mem.Allocator, stdin: *std.Io.Reader, _: *std.Io.Writer) !u64 {
    var total: u64 = 0;

    while (true) {
        const _range = try stdin.takeDelimiter(',') orelse break;
        const range = std.mem.trim(u8, _range, &std.ascii.whitespace);
        const idx = std.mem.indexOfScalar(u8, range, '-') orelse return ParseError.NoDashFound;
        const lower_bound = try std.fmt.parseInt(u64, range[0..idx], 10);
        const upper_bound = try std.fmt.parseInt(u64, range[idx+1..range.len], 10);

        std.debug.print("Range: {}-{}\n", .{lower_bound, upper_bound});

        for (lower_bound..upper_bound + 1) |num| {
            const digits = try numToDigits(allocator, num);
            defer allocator.free(digits);

            if (isPattern(digits, 2)) {
                total += num;
            }
        }
    }

    return total;
}


fn part2(allocator: std.mem.Allocator, stdin: *std.Io.Reader, _: *std.Io.Writer) !u64 {
    var total: u64 = 0;

    while (true) {
        const _range = try stdin.takeDelimiter(',') orelse break;
        const range = std.mem.trim(u8, _range, &std.ascii.whitespace);
        const idx = std.mem.indexOfScalar(u8, range, '-') orelse return ParseError.NoDashFound;
        const lower_bound = try std.fmt.parseInt(u64, range[0..idx], 10);
        const upper_bound = try std.fmt.parseInt(u64, range[idx+1..range.len], 10);

        std.debug.print("Range: {}-{}\n", .{lower_bound, upper_bound});

        for (lower_bound..upper_bound + 1) |num| {
            const digits = try numToDigits(allocator, num);
            defer allocator.free(digits);

            if (digits.len == 1) continue;

            for (2..digits.len + 1) |g| {
                if (isPattern(digits, @intCast(g))) {
                    total += num;
                    break;
                }
            }
        }
    }

    return total;
}


fn numToDigits(allocator: std.mem.Allocator, num: u64) ![]u4 {
    const num_digits = @as(u8, @intFromFloat(@floor(@log10(@as(f64, @floatFromInt(num)))))) + 1;

    var digits = try allocator.alloc(u4, num_digits);
    errdefer allocator.free(digits);

    var mod_val: u64 = 1;
    for (1..num_digits + 1) |i| {
        const last_mod_val = mod_val;
        mod_val *= 10;
        digits[num_digits - i] = @intCast(@divFloor(@mod(num, mod_val), last_mod_val));
    }

    return digits;
}


fn isPattern(digits: []u4, groups: u8) bool {
    if (digits.len % groups != 0) return false;

    const size = digits.len / groups;

    for (1..groups) |g| {
        for (0..size) |i| {
            if (digits[i] != digits[i + (g * size)]) {
                return false;
            }
        }
    }

    return true;
}
