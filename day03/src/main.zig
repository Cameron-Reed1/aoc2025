const std = @import("std");


const ParseError = error {
    InvalidCharacter,
    EmptyLine,
};


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
    var total: u64 = 0;

    while (true) {
        const line = try stdin.takeDelimiter('\n') orelse break;
        for (0..line.len) |i| {
            switch (line[i]) {
                '0'...'9' => line[i] -= '0',
                else => return ParseError.InvalidCharacter,
            }
        }

        const firstIdx = indexOfMax(u8, line[0..line.len - 1]) orelse return ParseError.EmptyLine;
        const secondIdx = firstIdx + 1 + (indexOfMax(u8, line[firstIdx + 1..line.len]) orelse return ParseError.EmptyLine);

        total += (line[firstIdx] * 10) + line[secondIdx];
    }

    return total;
}


fn part2(stdin: *std.Io.Reader, _: *std.Io.Writer) !u64 {
    var total: u64 = 0;
    const num_digits = 12;

    while (true) {
        const line = try stdin.takeDelimiter('\n') orelse break;
        for (0..line.len) |i| {
            switch (line[i]) {
                '0'...'9' => line[i] -= '0',
                else => return ParseError.InvalidCharacter,
            }
        }

        var max_joltage: u64 = 0;

        var startIdx: usize = 0;
        for (0..num_digits) |i| {
            const index = startIdx + (indexOfMax(u8, line[startIdx..line.len - (num_digits - 1) + i]) orelse return ParseError.EmptyLine);
            startIdx = index + 1;

            max_joltage += line[index] * std.math.pow(u64, 10, num_digits - i);
        }

        total += max_joltage;
    }

    return total;
}


fn part2_lazy(stdin: *std.Io.Reader, _: *std.Io.Writer) !u64 {
    var total: u64 = 0;

    while (true) {
        const line = try stdin.takeDelimiter('\n') orelse break;
        for (0..line.len) |i| {
            switch (line[i]) {
                '0'...'9' => line[i] -= '0',
                else => return ParseError.InvalidCharacter,
            }
        }

        const firstIdx    =                    indexOfMax(u8, line[0..line.len - 11]) orelse return ParseError.EmptyLine;
        const secondIdx   = firstIdx    + 1 + (indexOfMax(u8, line[firstIdx    + 1..line.len - 10]) orelse return ParseError.EmptyLine);
        const thirdIdx    = secondIdx   + 1 + (indexOfMax(u8, line[secondIdx   + 1..line.len - 9]) orelse return ParseError.EmptyLine);
        const fourthIdx   = thirdIdx    + 1 + (indexOfMax(u8, line[thirdIdx    + 1..line.len - 8]) orelse return ParseError.EmptyLine);
        const fifthIdx    = fourthIdx   + 1 + (indexOfMax(u8, line[fourthIdx   + 1..line.len - 7]) orelse return ParseError.EmptyLine);
        const sixthIdx    = fifthIdx    + 1 + (indexOfMax(u8, line[fifthIdx    + 1..line.len - 6]) orelse return ParseError.EmptyLine);
        const seventhIdx  = sixthIdx    + 1 + (indexOfMax(u8, line[sixthIdx    + 1..line.len - 5]) orelse return ParseError.EmptyLine);
        const eighthIdx   = seventhIdx  + 1 + (indexOfMax(u8, line[seventhIdx  + 1..line.len - 4]) orelse return ParseError.EmptyLine);
        const ninthIdx    = eighthIdx   + 1 + (indexOfMax(u8, line[eighthIdx   + 1..line.len - 3]) orelse return ParseError.EmptyLine);
        const tenthIdx    = ninthIdx    + 1 + (indexOfMax(u8, line[ninthIdx    + 1..line.len - 2]) orelse return ParseError.EmptyLine);
        const eleventhIdx = tenthIdx    + 1 + (indexOfMax(u8, line[tenthIdx    + 1..line.len - 1]) orelse return ParseError.EmptyLine);
        const twelfthIdx  = eleventhIdx + 1 + (indexOfMax(u8, line[eleventhIdx + 1..line.len]) orelse return ParseError.EmptyLine);

        total += (@as(u64, line[firstIdx]) * 100000000000) +
            (@as(u64, line[secondIdx]) * 10000000000) +
            (@as(u64, line[thirdIdx]) * 1000000000) +
            (@as(u64, line[fourthIdx]) * 100000000) +
            (@as(u64, line[fifthIdx]) * 10000000) +
            (@as(u64, line[sixthIdx]) * 1000000) +
            (@as(u64, line[seventhIdx]) * 100000) +
            (@as(u64, line[eighthIdx]) * 10000) +
            (@as(u64, line[ninthIdx]) * 1000) +
            (@as(u64, line[tenthIdx]) * 100) +
            (@as(u64, line[eleventhIdx]) * 10) +
            @as(u64, line[twelfthIdx]);
    }

    return total;
}


fn indexOfMax(comptime T: type, slice: []T) ?usize {
    if (slice.len == 0) return null;

    var max: usize = 0;

    for (1..slice.len) |i| {
        if (slice[i] > slice[max]) {
            max = i;
        }
    }

    return max;
}
