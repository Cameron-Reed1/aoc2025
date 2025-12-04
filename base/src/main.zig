const std = @import("std");


pub fn main() !void {
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
        result = try part2(stdin, stdout);
    } else {
        result = try part1(stdin, stdout);
    }

    try stdout.print("Result: {}\n", .{ result });
}


fn part1(stdin: *std.Io.Reader, _: *std.Io.Writer) !u64{
    _ = stdin;
    return 0;
}


fn part2(stdin: *std.Io.Reader, _: *std.Io.Writer) !u64 {
    _ = stdin;
    return 0;
}
