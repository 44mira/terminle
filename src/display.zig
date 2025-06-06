//! Render ASCII boxes and previous rounds.

const std = @import("std");
const io = std.io;
const testing = std.testing;

const Attempt = @import("attempt").Attempt;
const Evaluator = @import("attempt").Evaluator;
const colorize = @import("colorize").colorize;
const Allocator = std.mem.Allocator;

const DisplayError = error{InvalidWriter};

pub const ROUND_COUNT = 6;

/// Writes the styled output into the provided `writer`.
/// The output has `ROUND_COUNT` rows, and uses an []?Attempt type to determine
/// empty rows.
///
/// `writer` is expected to be of some `io.Writer` type.
pub fn display(allocator: Allocator, attempts: []const ?*Attempt, writer: anytype) !void {
    if (!@hasDecl(@TypeOf(writer), "write") or !@hasDecl(@TypeOf(writer), "print")) {
        return DisplayError.InvalidWriter;
    }

    try writer.writeAll("┏" ++ "━" ** 17 ++ "┓\n");

    for (attempts, 1..) |a, i| {
        const round = if (a) |attempt|
            try colorize(allocator, attempt)
        else
            " " ** 15;
        try writer.print("┃ {s} ┃\n", .{round});

        if (i != ROUND_COUNT)
            try writer.writeAll("┣" ++ "━" ** 17 ++ "┫\n");
    }
    try writer.writeAll("┗" ++ "━" ** 17 ++ "┛\n");
}

/// Displays the input box and places the cursor in the appropriate spot.
pub fn displayInputBox(writer: anytype, bufW: anytype) !void {
    const bar = "═" ++ "━" ** 5 ++ "─" ** 4 ++ "┄" ** 3 ++ "┈" ** 4 ++ "\n";

    try writer.writeAll("┌" ++ bar);
    try writer.writeAll("║ \n");
    try writer.writeAll("└" ++ bar);
    try bufW.flush();

    try writer.writeAll("\x1b[2F\x1b[2C");
    try bufW.flush();
}

test "display test" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    const allocator = arena.allocator();
    var list = std.ArrayList(u8).init(allocator);
    const w = list.writer();

    const eval = Evaluator.new("TRUMP");
    const attempts = [ROUND_COUNT]?*Attempt{
        try eval.evaluate(allocator, "HUMPS"),
        try eval.evaluate(allocator, "PLUMP"),
        try eval.evaluate(allocator, "TRUMP"),
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
        try colorize(allocator, attempts[0].?),
        try colorize(allocator, attempts[1].?),
        try colorize(allocator, attempts[2].?),
    });

    try display(allocator, &attempts, w);

    try testing.expectEqualStrings(expected, list.items);
}
