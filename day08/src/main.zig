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


const JunctionBox = struct {
    x: i64,
    y: i64,
    z: i64,

    circuit: ?usize = null,
};


const Distance = struct {
    dist_2: u64,
    from: usize,
    to: usize,

    pub fn lessThan(_: void, d1: Distance, d2: Distance) bool {
        return d1.dist_2 < d2.dist_2;
    }
};


fn part1(allocator: std.mem.Allocator, stdin: *std.Io.Reader) !u64{
    var boxes: std.ArrayListUnmanaged(JunctionBox) = .empty;
    defer boxes.deinit(allocator);

    while (true) {
        const line = try stdin.takeDelimiter('\n') orelse break;

        var iter = std.mem.splitScalar(u8, line, ',');
        const x_str = iter.next() orelse return ParseError.InvalidInput;
        const y_str = iter.next() orelse return ParseError.InvalidInput;
        const z_str = iter.next() orelse return ParseError.InvalidInput;
        if (iter.next() != null) return ParseError.InvalidInput;

        const x = try std.fmt.parseInt(i64, x_str, 10);
        const y = try std.fmt.parseInt(i64, y_str, 10);
        const z = try std.fmt.parseInt(i64, z_str, 10);

        try boxes.append(allocator, .{ .x = x, .y = y, .z = z });
    }

    var distances: std.ArrayListUnmanaged(Distance) = .empty;
    defer distances.deinit(allocator);

    for (0..boxes.items.len) |idx_1| {
        for (idx_1 + 1..boxes.items.len) |idx_2| {
            const dx = @abs(boxes.items[idx_1].x - boxes.items[idx_2].x);
            const dy = @abs(boxes.items[idx_1].y - boxes.items[idx_2].y);
            const dz = @abs(boxes.items[idx_1].z - boxes.items[idx_2].z);
            const dist_squared = (dx * dx) + (dy * dy) + (dz * dz);

            try distances.append(allocator, .{ .dist_2 = dist_squared, .from = idx_1, .to = idx_2 });
        }
    }

    std.mem.sort(Distance, distances.items, {}, Distance.lessThan);

    var circuits: std.ArrayListUnmanaged(std.ArrayListUnmanaged(u64)) = .empty;
    defer {
        for (circuits.items, 0..) |_, i| {
            circuits.items[i].deinit(allocator);
        }
        circuits.deinit(allocator);
    }

    for (0..1000) |i| {
        const d = distances.items[i];
        try joinBoxes(allocator, &boxes, &circuits, d.from, d.to);
    }

    std.mem.sort(std.ArrayListUnmanaged(u64), circuits.items, {}, circuitLessThan);

    var total: usize = 1;
    for (1..4) |i| {
        total *= circuits.items[circuits.items.len - i].items.len;
    }

    return total;
}


fn joinBoxes(allocator: std.mem.Allocator, boxes: *std.ArrayListUnmanaged(JunctionBox), circuits: *std.ArrayListUnmanaged(std.ArrayListUnmanaged(u64)), box1: u64, box2: u64) !void {
    if (boxes.items[box1].circuit) |c1| {
        if (boxes.items[box2].circuit) |c2| {
            if (c1 == c2) return;

            for (circuits.items[c2].items) |b| {
                boxes.items[b].circuit = c1;
            }
            try circuits.items[c1].appendSlice(allocator, circuits.items[c2].items);

            // Empty the circuit, but don't remove it because that will cause boxes to point to incorrect circuits
            circuits.items[c2].clearAndFree(allocator);
        } else {
            try circuits.items[c1].append(allocator, box2);
            boxes.items[box2].circuit = c1;
        }
    } else {
        if (boxes.items[box2].circuit) |c2| {
            try circuits.items[c2].append(allocator, box1);
            boxes.items[box1].circuit = c2;
        } else {
            var new_circuit: std.ArrayListUnmanaged(u64) = .empty;
            errdefer new_circuit.deinit(allocator);

            try new_circuit.append(allocator, box1);
            try new_circuit.append(allocator, box2);
            try circuits.append(allocator, new_circuit);

            boxes.items[box1].circuit = circuits.items.len - 1;
            boxes.items[box2].circuit = circuits.items.len - 1;
        }
    }
}

fn circuitLessThan(_: void, c1: std.ArrayListUnmanaged(u64), c2: std.ArrayListUnmanaged(u64)) bool {
    return c1.items.len < c2.items.len;
}


fn part2(allocator: std.mem.Allocator, stdin: *std.Io.Reader) !u64 {
    var boxes: std.ArrayListUnmanaged(JunctionBox) = .empty;
    defer boxes.deinit(allocator);

    while (true) {
        const line = try stdin.takeDelimiter('\n') orelse break;

        var iter = std.mem.splitScalar(u8, line, ',');
        const x_str = iter.next() orelse return ParseError.InvalidInput;
        const y_str = iter.next() orelse return ParseError.InvalidInput;
        const z_str = iter.next() orelse return ParseError.InvalidInput;
        if (iter.next() != null) return ParseError.InvalidInput;

        const x = try std.fmt.parseInt(i64, x_str, 10);
        const y = try std.fmt.parseInt(i64, y_str, 10);
        const z = try std.fmt.parseInt(i64, z_str, 10);

        try boxes.append(allocator, .{ .x = x, .y = y, .z = z });
    }

    var distances: std.ArrayListUnmanaged(Distance) = .empty;
    defer distances.deinit(allocator);

    for (0..boxes.items.len) |idx_1| {
        for (idx_1 + 1..boxes.items.len) |idx_2| {
            const dx = @abs(boxes.items[idx_1].x - boxes.items[idx_2].x);
            const dy = @abs(boxes.items[idx_1].y - boxes.items[idx_2].y);
            const dz = @abs(boxes.items[idx_1].z - boxes.items[idx_2].z);
            const dist_squared = (dx * dx) + (dy * dy) + (dz * dz);

            try distances.append(allocator, .{ .dist_2 = dist_squared, .from = idx_1, .to = idx_2 });
        }
    }

    std.mem.sort(Distance, distances.items, {}, Distance.lessThan);

    var circuits: std.ArrayListUnmanaged(std.ArrayListUnmanaged(u64)) = .empty;
    defer {
        for (circuits.items, 0..) |_, i| {
            circuits.items[i].deinit(allocator);
        }
        circuits.deinit(allocator);
    }

    var total: u64 = 0;
    outer: for (distances.items) |d| {
        try joinBoxes(allocator, &boxes, &circuits, d.from, d.to);

        const c = boxes.items[0].circuit orelse continue;
        for (boxes.items) |b| {
            if (b.circuit != c) continue :outer;
        }
        total = @abs(boxes.items[d.from].x * boxes.items[d.to].x);
        break;
    }

    return total;
}
