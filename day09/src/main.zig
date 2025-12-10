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
        result = try part2(allocator, stdin);
    } else {
        result = try part1(allocator, stdin);
    }

    try stdout.print("Result: {}\n", .{ result });
}


const Position = struct {
    x: u64,
    y: u64,

    pub fn areaBetween(pos1: *const Position, pos2: *const Position) u64 {
        const x_len = @max(pos1.x, pos2.x) - @min(pos1.x, pos2.x) + 1;
        const y_len = @max(pos1.y, pos2.y) - @min(pos1.y, pos2.y) + 1;
        return x_len * y_len;
    }
};

const Range = struct {
    from: Position,
    to: Position,
};

const TileColor = enum {
    red,
    green,
    not,
};


fn part1(allocator: std.mem.Allocator, stdin: *std.Io.Reader) !u64{
    var red_tiles: std.ArrayListUnmanaged(Position) = .empty;
    defer red_tiles.deinit(allocator);

    while (true) {
        const line = try stdin.takeDelimiter('\n') orelse break;

        const index = std.mem.indexOfScalar(u8, line, ',') orelse return ParseError.InvalidInput;
        const x = try std.fmt.parseInt(u64, line[0..index], 10);
        const y = try std.fmt.parseInt(u64, line[index + 1..line.len], 10);

        try red_tiles.append(allocator, .{ .x = x, .y = y });
    }

    var areas: std.ArrayListUnmanaged(u64) = .empty;
    defer areas.deinit(allocator);

    for (0..red_tiles.items.len) |t1| {
        for (t1 + 1..red_tiles.items.len) |t2| {
            const area = Position.areaBetween(&red_tiles.items[t1], &red_tiles.items[t2]);
            try areas.append(allocator, area);
        }
    }

    return std.mem.max(u64, areas.items);
}


fn part2(allocator: std.mem.Allocator, stdin: *std.Io.Reader) !u64 {
    var red_tiles: std.ArrayListUnmanaged(Position) = .empty;
    defer red_tiles.deinit(allocator);

    while (true) {
        const line = try stdin.takeDelimiter('\n') orelse break;

        const index = std.mem.indexOfScalar(u8, line, ',') orelse return ParseError.InvalidInput;
        const x = try std.fmt.parseInt(u64, line[0..index], 10);
        const y = try std.fmt.parseInt(u64, line[index + 1..line.len], 10);

        try red_tiles.append(allocator, .{ .x = x, .y = y });
    }

    var floor_range = Range{ .from = red_tiles.items[0], .to = red_tiles.items[0] };
    for (1..red_tiles.items.len) |i| {
        const t = red_tiles.items[i];
        if (t.x < floor_range.from.x) {
            floor_range.from.x = t.x;
        } else if (t.x > floor_range.to.x) {
            floor_range.to.x = t.x;
        }

        if (t.y < floor_range.from.y) {
            floor_range.from.y = t.y;
        } else if (t.y > floor_range.to.y) {
            floor_range.to.y = t.y;
        }
    }
    const floor_width = floor_range.to.x - floor_range.from.x;
    const floor_height = floor_range.to.y - floor_range.from.y;
    const floor_area = floor_width * floor_height;

    std.debug.print("{}\n", .{floor_area});

    var floor: std.ArrayListUnmanaged(TileColor) = .empty;
    defer floor.deinit(allocator);
    try floor.appendNTimes(allocator, .not, floor_area);

    for (1..red_tiles.items.len) |i| {
        const t1 = red_tiles.items[i - 1];
        const t2 = red_tiles.items[i];

        const idx1 = getIndexFromPosition(floor_range.from, floor_width, t1);
        floor.items[idx1] = .red;
        const idx2 = getIndexFromPosition(floor_range.from, floor_width, t2);
        floor.items[idx2] = .red;

        if (t1.x == t2.x) {
            for (@min(t1.y, t2.y) + 1..@max(t1.y, t2.y)) |y| {
                const idx = getIndexFromPosition(floor_range.from, floor_width, .{ .x = t1.x, .y = y });
                floor.items[idx] = .green;
            }
        } else {
            for (@min(t1.x, t2.x) + 1..@max(t1.x, t2.x)) |x| {
                const idx = getIndexFromPosition(floor_range.from, floor_width, .{ .x = x, .y = t1.y });
                floor.items[idx] = .green;
            }
        }
    }

    for (0..floor_height) |y| {
        for (0..floor_width) |x| {
            const i = x + (y * floor_width);
            const c = floor.items[i];
            std.debug.print("{c}", .{ @as(u8, if (c == .not) ' ' else if (c == .green) 'X' else '#') });
        }
        std.debug.print("\n", .{});
    }

    var areas: std.ArrayListUnmanaged(u64) = .empty;
    defer areas.deinit(allocator);

    for (0..red_tiles.items.len) |t1| {
        outer: for (t1 + 1..red_tiles.items.len) |t2| {
            const pos1 = red_tiles.items[t1];
            const pos2 = red_tiles.items[t2];
            for (@min(pos1.y, pos2.y)..@max(pos1.y, pos2.y)) |y| {
                for (@min(pos1.x, pos2.x)..@max(pos1.x, pos2.x)) |x| {
                    const idx = getIndexFromPosition(floor_range.from, floor_width, .{ .x = x, .y = y });
                    if (floor.items[idx] == .not) continue :outer;
                }
            }
            const area = Position.areaBetween(&pos1, &pos2);
            try areas.append(allocator, area);
        }
    }

    return std.mem.max(u64, areas.items);
}

fn getIndexFromPosition(min_pos: Position, width: u64, pos: Position) usize {
    const x = pos.x - min_pos.x;
    const y = pos.y - min_pos.y;

    return x + (y * width);
}
