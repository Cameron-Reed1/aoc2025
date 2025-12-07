const std = @import("std");


const ParseError = error {
    InvalidInput,
    UnexpectedCharacter,
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
    x: usize,
    y: usize,

    pub fn fromIndex(index: usize, width: usize) Position {
        return .{
            .x = index % width,
            .y = @divFloor(index, width),
        };
    }

    pub fn toIndex(self: *const Position, width: usize) usize {
        return self.x + (self.y * width);
    }
};

const Beam = struct {
    pos: usize,
    timelines: u64,
};


fn part1(allocator: std.mem.Allocator, stdin: *std.Io.Reader) !u64{
    var field: std.ArrayListUnmanaged(u8) = .empty;
    defer field.deinit(allocator);
    var width: usize = 0;

    while (true) {
        const line = try stdin.takeDelimiter('\n') orelse break;
        if (width == 0) {
            width = line.len;
        } else if (line.len != width) {
            return ParseError.InvalidInput;
        }

        try field.appendSlice(allocator, line);
    }

    var beams: std.ArrayListUnmanaged(Position) = .empty;
    defer beams.deinit(allocator);

    const start_index = std.mem.indexOfScalar(u8, field.items, 'S') orelse return ParseError.InvalidInput;
    const start_pos = Position.fromIndex(start_index, width);
    try beams.append(allocator, .{ .x = start_pos.x, .y = start_pos.y + 1 });

    var splits: u64 = 0;
    while (beams.items.len != 0) {
        var beam = beams.pop() orelse unreachable;

        while (true) {
            switch (field.items[beam.toIndex(width)]) {
                '|' => break,
                '.' => {},
                '^' => {
                    if (beam.x < width - 1) {
                        try beams.append(allocator, .{ .x = beam.x + 1, .y = beam.y });
                    }
                    if (beam.x > 0) {
                        try beams.append(allocator, .{ .x = beam.x - 1, .y = beam.y });
                    }

                    splits += 1;
                    break;
                },
                else => return ParseError.UnexpectedCharacter,
            }

            field.items[beam.toIndex(width)] = '|';
            beam = .{ .x = beam.x, .y = beam.y + 1 };
            if (beam.toIndex(width) >= field.items.len) {
                break;
            }
        }
    }

    return splits;
}


fn part2(allocator: std.mem.Allocator, stdin: *std.Io.Reader) !u64 {
    var field: std.ArrayListUnmanaged(u8) = .empty;
    defer field.deinit(allocator);
    var width: usize = 0;

    while (true) {
        const line = try stdin.takeDelimiter('\n') orelse break;
        if (width == 0) {
            width = line.len;
        } else if (line.len != width) {
            return ParseError.InvalidInput;
        }

        try field.appendSlice(allocator, line);
    }

    var beams: std.ArrayListUnmanaged(Beam) = .empty;
    defer beams.deinit(allocator);

    const start_index = std.mem.indexOfScalar(u8, field.items, 'S') orelse return ParseError.InvalidInput;
    const start_pos = Position.fromIndex(start_index, width);
    try beams.append(allocator, .{ .pos = start_pos.x, .timelines = 1 });

    for (start_pos.y + 1..field.items.len / width) |y| {
        const beams_slice = try beams.toOwnedSlice(allocator);
        defer allocator.free(beams_slice);

        for (beams_slice) |beam| {
            const pos = Position{ .x = beam.pos, .y = y };
            switch (field.items[pos.toIndex(width)]) {
                '|' => merge_timelines(beams.items, beam),
                '.' => {
                    try beams.append(allocator, beam);
                    field.items[pos.toIndex(width)] = '|';
                },
                '^' => {
                    if (beam.pos > 0) {
                        const new_beam = Beam{ .pos = beam.pos - 1, .timelines = beam.timelines };

                        if (field.items[pos.toIndex(width) - 1] == '|') {
                            merge_timelines(beams.items, new_beam);
                        } else {
                            try beams.append(allocator, new_beam);
                        }
                    }

                    if (beam.pos < width - 1) {
                        const new_beam = Beam{ .pos = beam.pos + 1, .timelines = beam.timelines };

                        if (field.items[pos.toIndex(width) + 1] == '|') {
                            merge_timelines(beams.items, new_beam);
                        } else {
                            try beams.append(allocator, new_beam);
                        }
                    }
                },
                else => return ParseError.UnexpectedCharacter,
            }
        }
    }

    var timelines: u64 = 0;
    for (beams.items) |beam| {
        timelines += beam.timelines;
    }

    return timelines;
}

fn merge_timelines(beams: []Beam, beam: Beam) void {
    for (beams, 0..) |b, i| {
        if (b.pos == beam.pos) {
            beams[i].timelines += beam.timelines;
            return;
        }
    }

    unreachable;
}
