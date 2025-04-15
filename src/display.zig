const std = @import("std");
const io = std.io;
const testing = std.testing;

const Attempt = @import("attempt").Attempt;
const colorize = @import("colorize").colorize;
const Allocator = std.mem.Allocator;

const DisplayError = error{InvalidWriter};

pub const ROUND_COUNT = 6;

pub fn display(allocator: Allocator, attempts: []const ?Attempt, writer: anytype) !void {
    if (!@hasDecl(@TypeOf(writer), "write") or !@hasDecl(@TypeOf(writer), "print")) {
        return DisplayError.InvalidWriter;
    }

    try writer.writeAll("┏" ++ "━" ** 17 ++ "┓\n");

    for (attempts, 1..) |a, i| {
        const round = if (a) |attempt|
            try colorize(allocator, &attempt)
        else
            " " ** 15;
        try writer.print("┃ {s} ┃\n", .{round});

        if (i != ROUND_COUNT)
            try writer.writeAll("┣" ++ "━" ** 17 ++ "┫\n");
    }
    try writer.writeAll("┗" ++ "━" ** 17 ++ "┛\n");
}

test "display test" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    var list = std.ArrayList(u8).init(allocator);
    const w = list.writer();

    const attempts = [ROUND_COUNT]?Attempt{
        try Attempt.evaluateGuess("TRUMP", "HUMPS"),
        try Attempt.evaluateGuess("TRUMP", "PLUMP"),
        try Attempt.evaluateGuess("TRUMP", "TRUMP"),
        null,
        null,
        null,
    };

    const expected = try std.fmt.allocPrint(allocator,
        \\┏━━━━━━━━━━━━━━━━━┓
        \\┃ {s} ┃
        \\┣━━━━━━━━━━━━━━━━━┫
        \\┃ {s} ┃
        \\┣━━━━━━━━━━━━━━━━━┫
        \\┃ {s} ┃
        \\┣━━━━━━━━━━━━━━━━━┫
        \\┃                 ┃
        \\┣━━━━━━━━━━━━━━━━━┫
        \\┃                 ┃
        \\┣━━━━━━━━━━━━━━━━━┫
        \\┃                 ┃
        \\┗━━━━━━━━━━━━━━━━━┛
        \\
    , .{
        try colorize(allocator, &attempts[0].?),
        try colorize(allocator, &attempts[1].?),
        try colorize(allocator, &attempts[2].?),
    });

    try display(allocator, &attempts, w);

    try testing.expectEqualStrings(expected, list.items);
}
