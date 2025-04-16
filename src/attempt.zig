const std = @import("std");
const testing = std.testing;
const ascii = std.ascii;
const Allocator = std.mem.Allocator;

pub const WORD_LENGTH = 5;

const WORDLIST = @embedFile("./wordlist.txt");

pub const EvaluateError_Actual = error{
    NonAlphabetic,
    InvalidLength,
    IsLowercase,
};

pub const EvaluateError_Guess = error{
    NonAlphabetic,
    InvalidLength,
    IsLowercase,
};

pub const Correctness = enum {
    Gray,
    Green,
    Yellow,
};

pub const Attempt = struct {
    word: [:0]const u8,
    correctness: [WORD_LENGTH]Correctness = .{.Gray} ** WORD_LENGTH,

    pub fn new(word: [:0]const u8, correctness: [WORD_LENGTH]Correctness) Attempt {
        return Attempt{ .word = word, .correctness = correctness };
    }
};

pub const Evaluator = struct {
    actual: [:0]const u8,

    /// Returns an Attempt based on an `actual` word and a `guess` word.
    /// Can error on invalid `actual` or `guess`, or if allocations fail.
    pub fn evaluate(self: *const Evaluator, allocator: Allocator, guess: [:0]const u8) !*Attempt {
        // error check
        try validateWord(EvaluateError_Actual, self.actual);
        try validateWord(EvaluateError_Guess, guess);

        var bag = [_]i4{0} ** 26;
        var correctness = [_]Correctness{.Gray} ** WORD_LENGTH;

        for (self.actual) |a| {
            bag[a - 'A'] += 1;
        }

        // prioritize green
        for (self.actual, guess, 0..) |a, g, i| {
            const slot: u8 = g - 'A';

            if (a == g) {
                correctness[i] = .Green;
                bag[slot] -= 1;
            }
        }

        // yellow pass
        for (guess, 0..) |g, i| {
            const slot: u8 = g - 'A';
            if (correctness[i] == .Green) continue;
            if (bag[slot] > 0) {
                correctness[i] = .Yellow;
                bag[slot] -= 1;
            }
        }

        const result: *Attempt = try allocator.create(Attempt);
        result.* = Attempt.new(guess, correctness);

        return result;
    }

    /// Validates whether a word is valid or not.
    /// A valid word is all uppercase, length is same as `WORD_LENGTH`, and is alphabetic.
    fn validateWord(comptime E: anytype, word: []const u8) E!void {
        if (E != EvaluateError_Actual and E != EvaluateError_Guess) unreachable;

        if (word.len != WORD_LENGTH) {
            return E.InvalidLength;
        }
        for (word) |c| {
            if (!ascii.isAlphabetic(c)) return E.NonAlphabetic;
            if (ascii.isLower(c)) return E.IsLowercase;
        }
    }

    pub fn new(actual: [:0]const u8) Evaluator {
        return .{ .actual = actual };
    }

    pub fn newRand(allocator: Allocator) !Evaluator {
        // hard coded because iterating for length is too much of a performance hit
        const wordlist_len: u32 = 10657;
        var wordlist = std.mem.tokenizeScalar(u8, WORDLIST, '\n');
        var word_idx = std.crypto.random.uintLessThan(u64, wordlist_len);

        while (word_idx > 0) : (word_idx -= 1) {
            _ = wordlist.next();
        }

        const word = try std.ascii.allocUpperString(allocator, wordlist.next().?);
        return Evaluator.new(@ptrCast(word));
    }
};

fn expectEqualAttempt(expected: *const Attempt, actual: *const Attempt) !void {
    try testing.expectEqualStrings(expected.word, actual.word);
    try testing.expectEqualSlices(Correctness, &expected.correctness, &actual.correctness);
}

test "guess evaluation check" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var expected: Attempt = undefined;
    var attempt: *Attempt = undefined;

    attempt = try Evaluator.new("HELLO").evaluate(allocator, "HELLO");
    expected = Attempt.new("HELLO", .{.Green} ** 5);
    try expectEqualAttempt(&expected, attempt);

    attempt = try Evaluator.new("HELLO").evaluate(allocator, "RATTY");
    expected = Attempt.new("RATTY", .{.Gray} ** 5);
    try expectEqualAttempt(&expected, attempt);

    attempt = try Evaluator.new("BOATS").evaluate(allocator, "TAOSB");
    expected = Attempt.new("TAOSB", .{.Yellow} ** 5);
    try expectEqualAttempt(&expected, attempt);

    attempt = try Evaluator.new("SILLY").evaluate(allocator, "LILLY");
    expected = Attempt.new("LILLY", .{.Gray} ++ .{.Green} ** 4);
    try expectEqualAttempt(&expected, attempt);
}

test "error cases" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    try testing.expectError(
        EvaluateError_Actual.InvalidLength,
        Evaluator.new("invalid").evaluate(allocator, "irrelevant"),
    );

    try testing.expectError(
        EvaluateError_Actual.NonAlphabetic,
        Evaluator.new("12345").evaluate(allocator, "irrelevant"),
    );

    try testing.expectError(
        EvaluateError_Actual.IsLowercase,
        Evaluator.new("hello").evaluate(allocator, "irrelevant"),
    );

    const eval = Evaluator.new("HELLO");
    try testing.expectError(
        EvaluateError_Guess.IsLowercase,
        eval.evaluate(allocator, "hello"),
    );

    try testing.expectError(
        EvaluateError_Guess.InvalidLength,
        eval.evaluate(allocator, "helloo"),
    );

    try testing.expectError(
        EvaluateError_Guess.NonAlphabetic,
        eval.evaluate(allocator, "HI2U2"),
    );
}
