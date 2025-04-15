const std = @import("std");
const Attempt = @import("attempt").Attempt;
const colorize = @import("colorize").colorize;
const display = @import("display").display;
const ROUND_COUNT = @import("display").ROUND_COUNT;

const io = std.io;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const out = io.getStdOut().writer();
    var buf = io.bufferedWriter(out);
    const writer = buf.writer();

    const attempts = [ROUND_COUNT]?Attempt{
        try Attempt.evaluateGuess("TRUMP", "HUMPS"),
        try Attempt.evaluateGuess("TRUMP", "PLUMP"),
        try Attempt.evaluateGuess("TRUMP", "TRUMP"),
        null,
        null,
        null,
    };

    try display(allocator, &attempts, writer);
    try buf.flush();
}
