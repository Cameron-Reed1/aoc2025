const std = @import("std");


const ParseError = error {
    UnexpectedCharacter,
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

    var stdin_buf: [4096]u8 = undefined;
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


const Problem = struct {
    operation: Operation,
    numbers: []u64,

    pub fn solve(self: *const Problem) u64 {
        var result = self.numbers[0];

        if (self.operation == .mul) {
            for (1..self.numbers.len) |i| {
                result *= self.numbers[i];
            }
        } else {
            for (1..self.numbers.len) |i| {
                result += self.numbers[i];
            }
        }

        return result;
    }
};


const Operation = enum {
    add,
    mul,
};


fn part1(allocator: std.mem.Allocator, stdin: *std.Io.Reader) !u64{
    const problems = try parseProblems(allocator, stdin);
    defer {
        for (problems) |p| {
            allocator.free(p.numbers);
        }
        allocator.free(problems);
    }

    var grand_total: u64 = 0;
    for (problems) |problem| {
        grand_total += problem.solve();
    }

    return grand_total;
}


fn part2(allocator: std.mem.Allocator, stdin: *std.Io.Reader) !u64 {
    var line_len: usize = 0;
    var text: std.ArrayListUnmanaged(u8) = .empty;
    defer text.deinit(allocator);

    while (true) {
        const line = try stdin.takeDelimiter('\n') orelse break;
        if (line_len == 0) {
            line_len = line.len;
        } else if (line.len != line_len) {
            return ParseError.InvalidInput;
        }

        try text.appendSlice(allocator, line);
    }

    const ops_line_index: usize = text.items.len - line_len;
    const height: usize = ops_line_index / line_len;

    var problems: std.ArrayListUnmanaged(Problem) = .empty;
    defer {
        for (problems.items) |problem| {
            allocator.free(problem.numbers);
        }
        problems.deinit(allocator);
    }

    var numbers: std.ArrayListUnmanaged(u64) = .empty;
    defer numbers.deinit(allocator);

    var p_start_index: usize = 0;
    for (0..line_len) |x| {
        var num_text: std.ArrayListUnmanaged(u8) = .empty;
        defer num_text.deinit(allocator);

        for (0..height) |y| {
            const c = text.items[x + (y * line_len)];
            switch (c) {
                ' ' => continue,
                '0'...'9' => try num_text.append(allocator, c),
                else => return ParseError.UnexpectedCharacter,
            }
        }

        if (num_text.items.len == 0) {
            var op: ?Operation = null;
            for (p_start_index..x) |i| {
                op = switch (text.items[ops_line_index + i]) {
                    '*' => .mul,
                    '+' => .add,
                    ' ' => continue,
                    else => return ParseError.UnexpectedCharacter,
                };
                break;
            }

            if (op == null) {
                return ParseError.InvalidInput;
            }

            const p = Problem{
                .operation = op.?,
                .numbers = try numbers.toOwnedSlice(allocator),
            };
            errdefer allocator.free(p.numbers);

            try problems.append(allocator, p);

            p_start_index = x + 1;
        } else {
            const n = try std.fmt.parseInt(u64, num_text.items, 10);
            try numbers.append(allocator, n);
        }
    }

    // I really don't like this
    var op: ?Operation = null;
    for (p_start_index..line_len) |i| {
        op = switch (text.items[ops_line_index + i]) {
            '*' => .mul,
            '+' => .add,
            ' ' => continue,
            else => return ParseError.UnexpectedCharacter,
        };
        break;
    }

    if (op == null) {
        return ParseError.InvalidInput;
    }

    const p = Problem{
        .operation = op.?,
        .numbers = try numbers.toOwnedSlice(allocator),
    };
    {
        errdefer allocator.free(p.numbers);
        try problems.append(allocator, p);
    }

    var grand_total: u64 = 0;
    for (problems.items) |problem| {
        grand_total += problem.solve();
    }

    return grand_total;
}


fn parseProblems(allocator: std.mem.Allocator, stdin: *std.Io.Reader) ![]Problem {
    var lines: std.ArrayListUnmanaged([]u64) = .empty;
    defer {
        for (lines.items) |line| {
            allocator.free(line);
        }
        lines.deinit(allocator);
    }

    const operations = blk: while (true) {
        const line = try stdin.takeDelimiter('\n') orelse return ParseError.InvalidInput;

        var nums: std.ArrayListUnmanaged(u64) = .empty;
        errdefer nums.deinit(allocator);

        var start_idx: usize = line.len;
        for (line, 0..) |c, i| {
            switch (c) {
                '0'...'9' => if (start_idx > i) { start_idx = i; },
                ' ' => {
                    if (start_idx < i) {
                        const n = try std.fmt.parseInt(u64, line[start_idx..i], 10);
                        try nums.append(allocator, n);
                        start_idx = line.len;
                    }
                },
                '*', '+' => {
                    if (start_idx < i) {
                        return ParseError.InvalidInput;
                    } else {
                        break :blk line;
                    }
                },
                else => return ParseError.UnexpectedCharacter,
            }
        }

        if (start_idx < line.len) {
            const n = try std.fmt.parseInt(u64, line[start_idx..line.len], 10);
            try nums.append(allocator, n);
        }

        const l = try nums.toOwnedSlice(allocator);
        errdefer allocator.free(l);
        try lines.append(allocator, l);
    };

    return try createProblems(allocator, operations, lines.items);
}


fn createProblems(allocator: std.mem.Allocator, operations: []const u8, numbers: [][]u64) ![]Problem {
    var idx: usize = 0;
    const problems = try allocator.alloc(Problem, numbers[0].len);
    errdefer {
        for (0..idx) |i| {
            allocator.free(problems[i].numbers);
        }
        allocator.free(problems);
    }


    for (operations) |c| {
        switch (c) {
            ' ' => continue,
            '*' => {
                var p = &problems[idx];
                p.operation = .mul;
                p.numbers = try allocator.alloc(u64, numbers.len);
                errdefer allocator.free(p.numbers);

                for (numbers, 0..) |line, i| {
                    p.numbers[i] = line[idx];
                }

                idx += 1;
            },
            '+' => {
                var p = &problems[idx];
                p.operation = .add;
                p.numbers = try allocator.alloc(u64, numbers.len);
                errdefer allocator.free(p.numbers);

                for (numbers, 0..) |line, i| {
                    p.numbers[i] = line[idx];
                }

                idx += 1;
            },
            else => return ParseError.InvalidInput,
        }
    }

    return problems;
}
