const std = @import("std");


pub fn main() !void {
    var stdin_buf: [1024]u8 = undefined;
    var stdout_buf: [1024]u8 = undefined;

    var stdin_reader = std.fs.File.stdin().reader(&stdin_buf);
    const stdin = &stdin_reader.interface;

    var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
    const stdout = &stdout_writer.interface;
    defer stdout.flush() catch {};


    var result: u16 = 0;
    if (std.mem.eql(u8, std.mem.span(std.os.argv[1]), "--part2")) {
        result = try part2(stdin, stdout);
    } else if (std.mem.eql(u8, std.mem.span(std.os.argv[1]), "--other-part2")) {
        result = try other_part2(stdin, stdout);
    } else {
        result = try part1(stdin, stdout);
    }

    try stdout.print("Password: {}\n", .{ result });
}


fn part1(stdin: *std.Io.Reader, _: *std.Io.Writer) !u16 {
    var position: i16 = 50;
    var zeros: u16 = 0;

    while (true) {
        const l = try stdin.takeDelimiter('\n');
        if (l) |line| {
            const right = line[0] == 'R';
            const delta = try std.fmt.parseInt(i16, line[1..line.len], 10) * @as(i8, if (right) 1 else -1);

            position = @mod(position + delta, 100);
            if (position == 0) {
                zeros += 1;
            }
        } else {
            break;
        }
    }

    return zeros;
}


fn part2(stdin: *std.Io.Reader, _: *std.Io.Writer) !u16 {
    var position: i16 = 50;
    var zeros: u16 = 0;

    while (true) {
        const l = try stdin.takeDelimiter('\n');
        if (l) |line| {
            const dir: i8 = if (line[0] == 'R') 1 else -1;
            const delta = try std.fmt.parseInt(u15, line[1..line.len], 10);

            for (0..delta) |_| {
                position = @mod(position + dir, 100);
                if (position == 0) {
                    zeros += 1;
                }
            }
        } else {
            break;
        }
    }

    return zeros;
}


fn other_part2(stdin: *std.Io.Reader, _: *std.Io.Writer) !u16 {
    var position: i16 = 50;
    var zeros: u16 = 0;

    while (true) {
        const l = try stdin.takeDelimiter('\n');
        if (l) |line| {
            const right = line[0] == 'R';
            const delta = try std.fmt.parseInt(u15, line[1..line.len], 10);

            var new_position = if (right) position + delta else position - delta;

            if (new_position <= 0 or new_position >= 100) {
                zeros += @intCast(@abs(@divFloor(new_position, 100)));
                new_position = @mod(new_position, 100);

                if (position == 0 and !right) zeros -= 1;
                if (new_position == 0 and !right) zeros += 1;
            }

            position = new_position;
        } else {
            break;
        }
    }

    return zeros;
}
