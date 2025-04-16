const std = @import("std");
const io = std.io;

const input = @import("input");
const Attempt = @import("attempt").Attempt;
const Evaluator = @import("attempt").Evaluator;
const colorize = @import("colorize").colorize;
const display = @import("display");
const ROUND_COUNT = @import("display").ROUND_COUNT;
const WORD_LENGTH = @import("attempt").WORD_LENGTH;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const word = try Evaluator.newRand();

    try gameloop(allocator, word);
}

/// This is probably the worst Zig code I have ever written but it works.
fn gameloop(
    allocator: std.mem.Allocator,
    word: Evaluator,
) !void {
    // We get a `Reader` for stdin
    const reader = io.getStdIn().reader();

    // We get a `Writer` for stdout
    const out = io.getStdOut().writer();
    var bufW = io.bufferedWriter(out);
    var writer = bufW.writer();

    var guess: [:0]const u8 = undefined;
    var winFlag = false;
    var attempts: [ROUND_COUNT]?*Attempt = .{null} ** ROUND_COUNT;

    var i: u4 = 0;
    while (i < ROUND_COUNT) {
        // clear the screen using ANSI escape sequence
        try writer.writeAll("\x1b[H\x1b[2J");

        // display the previous rounds
        try display.display(allocator, &attempts, writer);
        try bufW.flush();

        // take user input
        try display.displayInputBox(writer, &bufW);
        guess = try input.readInput(allocator, reader);

        // on invalid input, just redo the loop
        attempts[i] = word.evaluate(allocator, guess) catch continue;

        if (std.meta.eql(attempts[i].?.correctness, .{.Green} ** WORD_LENGTH)) {
            winFlag = true;
            break;
        }

        if (attempts[i] != null)
            i += 1;
    }

    try writer.writeAll("\x1b[H\x1b[2J");
    try display.display(allocator, &attempts, writer);
    try bufW.flush();

    if (winFlag) {
        try writer.writeAll("\n\nYOU WIN!\n");
    } else {
        try writer.print("\n\nThe word was: {s}\n", .{word.actual});
    }
    try bufW.flush();
}
