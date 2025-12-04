const std = @import("std");


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


fn part1(allocator: std.mem.Allocator, stdin: *std.Io.Reader, _: *std.Io.Writer) !u64{
    var map: std.ArrayListUnmanaged([]bool) = .empty;
    defer {
        for (map.items) |row| {
            allocator.free(row);
        }
        map.deinit(allocator);
    }

    while (true) {
        const line = try stdin.takeDelimiter('\n') orelse break;
        var row: std.ArrayListUnmanaged(bool) = .empty;
        errdefer row.deinit(allocator);

        for (line) |c| {
            switch (c) {
                '@' => try row.append(allocator, true),
                '.' => try row.append(allocator, false),
                else => {
                    std.debug.print("Unexpected character '{c}'. Assuming empty space\n", .{ c });
                    try row.append(allocator, false);
                },
            }
        }

        try map.append(allocator, try row.toOwnedSlice(allocator));
    }

    var accessible_rolls: u64 = 0;
    for (0..map.items.len) |y| {
        for (0..map.items[0].len) |x| {
            if (!map.items[y][x]) continue;

            if (count_neighbours(map.items, x, y) < 4) {
                accessible_rolls += 1;
            }
        }
    }

    return accessible_rolls;
}


fn part2(allocator: std.mem.Allocator, stdin: *std.Io.Reader, _: *std.Io.Writer) !u64 {
    var map: std.ArrayListUnmanaged([]bool) = .empty;
    defer {
        for (map.items) |row| {
            allocator.free(row);
        }
        map.deinit(allocator);
    }

    while (true) {
        const line = try stdin.takeDelimiter('\n') orelse break;
        var row: std.ArrayListUnmanaged(bool) = .empty;
        errdefer row.deinit(allocator);

        for (line) |c| {
            switch (c) {
                '@' => try row.append(allocator, true),
                '.' => try row.append(allocator, false),
                else => {
                    std.debug.print("Unexpected character '{c}'. Assuming empty space\n", .{ c });
                    try row.append(allocator, false);
                },
            }
        }

        try map.append(allocator, try row.toOwnedSlice(allocator));
    }

    var total_accessible_rolls: u64 = 0;

    while (true) {
        var accessible_rolls: u64 = 0;
        for (0..map.items.len) |y| {
            for (0..map.items[0].len) |x| {
                if (!map.items[y][x]) continue;

                if (count_neighbours(map.items, x, y) < 4) {
                    accessible_rolls += 1;
                    map.items[y][x] = false;
                }
            }
        }

        if (accessible_rolls == 0) break;

        total_accessible_rolls += accessible_rolls;
    }

    return total_accessible_rolls;
}


fn count_neighbours(map: [][]bool, x: usize, y: usize) u8 {
    var neighbours: u8 = 0;

    const min_y = if (y == 0) 0 else y - 1;
    const min_x = if (x == 0) 0 else x - 1;
    const max_y = @min(y + 2, map.len); // Plus two because for is not inclusive for the upper bound
    const max_x = @min(x + 2, map[0].len);

    for (min_y..max_y) |y_idx| {
        for (min_x..max_x) |x_idx| {
            if (map[y_idx][x_idx]) {
                neighbours += 1;
            }
        }
    }

    if (map[y][x]) {
        neighbours -= 1;
    }

    return neighbours;
}
