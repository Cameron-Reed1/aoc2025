const std = @import("std");


const ParseError = error {
    InvalidInput,
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


const Range = struct {
    min: u64,
    max: u64,

    pub fn contains(self: *const Range, num: u64) bool {
        return num >= self.min and num <= self.max;
    }

    pub fn overlaps(self: *const Range, other: *const Range) bool {
        return self.contains(other.min) or self.contains(other.max) or other.contains(self.min);
    }

    pub fn extend(self: *Range, other: *const Range) void {
        self.min = @min(self.min, other.min);
        self.max = @max(self.max, other.max);
    }
};


fn part1(allocator: std.mem.Allocator, stdin: *std.Io.Reader, _: *std.Io.Writer) !u64{
    var ranges: std.ArrayListUnmanaged(Range) = .empty;
    defer ranges.deinit(allocator);

    var product_ids: std.ArrayListUnmanaged(u64) = .empty;
    defer product_ids.deinit(allocator);

    while (true) { // Read ranges
        const line = try stdin.takeDelimiter('\n') orelse return ParseError.InvalidInput;
        if (line.len == 0) break;

        const dash_idx = std.mem.indexOfScalar(u8, line, '-') orelse return ParseError.InvalidInput;
        const min = try std.fmt.parseInt(u64, line[0..dash_idx], 10);
        const max = try std.fmt.parseInt(u64, line[dash_idx + 1..line.len], 10);

        try ranges.append(allocator, .{ .min = min, .max = max });
    }

    while (true) { // Read product ids
        const line = try stdin.takeDelimiter('\n') orelse break;
        const id = try std.fmt.parseInt(u64, line, 10);
        try product_ids.append(allocator, id);
    }

    var total_fresh: u64 = 0;
    for (product_ids.items) |id| {
        for (ranges.items) |range| {
            if (range.contains(id)) {
                total_fresh += 1;
                break;
            }
        }
    }

    return total_fresh;
}


fn part2(allocator: std.mem.Allocator, stdin: *std.Io.Reader, _: *std.Io.Writer) !u64 {
    var ranges: std.ArrayListUnmanaged(Range) = .empty;
    defer ranges.deinit(allocator);

    while (true) { // Read ranges
        const line = try stdin.takeDelimiter('\n') orelse return ParseError.InvalidInput;
        if (line.len == 0) break;

        const dash_idx = std.mem.indexOfScalar(u8, line, '-') orelse return ParseError.InvalidInput;
        const min = try std.fmt.parseInt(u64, line[0..dash_idx], 10);
        const max = try std.fmt.parseInt(u64, line[dash_idx + 1..line.len], 10);

        try ranges.append(allocator, .{ .min = min, .max = max });
    }

    const len = ranges.items.len;
    for (1..len + 1) |i| {
        const idx = len - i;
        const range = &ranges.items[idx];

        for (0..idx) |j| {
            if (ranges.items[j].overlaps(range)) {
                ranges.items[j].extend(range);
                _ = ranges.orderedRemove(idx);
                break;
            }
        }
    }

    var total_fresh_ids: u64 = 0;
    for (ranges.items) |range| {
        total_fresh_ids += range.max - range.min + 1;
    }

    return total_fresh_ids;
}
