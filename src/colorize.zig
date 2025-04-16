//! Create colorized string using `applyColor`, a helper function for wrapping
//! characters in their corresponding ANSI escape sequences.

const std = @import("std");
const attempt = @import("attempt");

const testing = std.testing;
const Allocator = std.mem.Allocator;
const Attempt = attempt.Attempt;
const Correctness = attempt.Correctness;

/// Wrap a character in its corresponding ANSI Escape Sequence to display color.
fn applyColor(allocator: Allocator, color: Correctness, letter: u8) ![]const u8 {
    var result = std.ArrayList(u8).init(allocator);
    const writer = result.writer();

    const fmt = switch (color) {
        Correctness.Gray => "2m",
        Correctness.Green => "1;32m",
        Correctness.Yellow => "1;33m",
    };
    try writer.print("\x1b[{s} {c} \x1b[0m", .{ fmt, letter });

    return result.items;
}

/// Maps `applyColor` to a string.
fn applyColorString(allocator: Allocator, correctness: []const Correctness, word: [:0]const u8) ![:0]const u8 {
    var result = std.ArrayList(u8).init(allocator);

    for (correctness, word) |co, ch| {
        try result.appendSlice(try applyColor(allocator, co, ch));
    }

    return @ptrCast(result.items);
}

/// A specialized call to `applyColorString` that takes in an `Attempt`.
pub fn colorize(allocator: Allocator, a: *const Attempt) ![:0]const u8 {
    return applyColorString(allocator, &a.correctness, a.word);
}

test "colorize tests" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    try testing.expectEqualStrings(
        try applyColorString(allocator, &[_]Correctness{Correctness.Green} ** 5, "HELLO"),
        try colorize(allocator, &Attempt.new("HELLO", .{Correctness.Green} ** 5)),
    );

    const expected = [_]Correctness{
        Correctness.Green,
        Correctness.Yellow,
        Correctness.Yellow,
        Correctness.Yellow,
        Correctness.Green,
    };
    try testing.expectEqualStrings(
        try applyColorString(allocator, &expected, "HELLO"),
        try colorize(allocator, &Attempt.new("HELLO", expected)),
    );
}

test "applyColor tests" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    try testing.expectEqualStrings(
        "\x1b[2m A \x1b[0m",
        try applyColor(allocator, Correctness.Gray, 'A'),
    );

    try testing.expectEqualStrings(
        "\x1b[1;32m B \x1b[0m",
        try applyColor(allocator, Correctness.Green, 'B'),
    );

    try testing.expectEqualStrings(
        "\x1b[1;33m C \x1b[0m",
        try applyColor(allocator, Correctness.Yellow, 'C'),
    );

    const correctness = [_]Correctness{ Correctness.Gray, Correctness.Green, Correctness.Yellow };
    try testing.expectEqualStrings(
        "\x1b[2m A \x1b[0m\x1b[1;32m B \x1b[0m\x1b[1;33m C \x1b[0m",
        try applyColorString(allocator, @constCast(&correctness), "ABC"),
    );
}
