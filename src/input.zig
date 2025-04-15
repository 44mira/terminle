const std = @import("std");
const testing = std.testing;
const io = std.io;

const attempt = @import("attempt");

pub fn readInput(reader: anytype, buffer: []u8) ![]const u8 {
    const line = (try reader.readUntilDelimiterOrEof(buffer, '\n')).?;

    return line;
}

test "input tests" {
    var buffer: [10]u8 = undefined;
    var bfR = io.fixedBufferStream("HELLO\n");
    const reader = bfR.reader();

    const buf = try readInput(&reader, &buffer);
    try testing.expectEqualStrings("HELLO", buf);
}
