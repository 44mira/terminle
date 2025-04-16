const std = @import("std");
const testing = std.testing;
const io = std.io;

const attempt = @import("attempt");

pub fn readInput(allocator: std.mem.Allocator, reader: anytype) ![:0]const u8 {
    const line = (try reader.readUntilDelimiterOrEofAlloc(allocator, '\n', 4096)).?;

    for (line) |*c| {
        if (std.ascii.isLower(c.*)) {
            c.* = std.ascii.toUpper(c.*);
        }
    }

    return @ptrCast(line);
}

test "input tests" {
    var buffer: [10]u8 = undefined;
    var bfR = io.fixedBufferStream("HELLO\n");
    const reader = bfR.reader();

    const buf = try readInput(&reader, &buffer);
    try testing.expectEqualStrings("HELLO", buf);
}
