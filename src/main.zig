const std = @import("std");
const io = std.io;

const Attempt = @import("attempt").Attempt;
const Evaluator = @import("attempt").Evaluator;
const colorize = @import("colorize").colorize;
const display = @import("display").display;
const ROUND_COUNT = @import("display").ROUND_COUNT;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const out = io.getStdOut().writer();
    var buf = io.bufferedWriter(out);
    const writer = buf.writer();

    const word = Evaluator.new("ASHEN");
    const attempts = [ROUND_COUNT]?Attempt{
        try word.evaluate("CRANE"),
        try word.evaluate("ANGEL"),
        try word.evaluate("ASPEN"),
        try word.evaluate("ASHEN"),
        null,
        null,
    };

    try display(allocator, &attempts, writer);
    try buf.flush();
}
