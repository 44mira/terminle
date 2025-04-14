const std = @import("std");
const testing = std.testing;
const ascii = std.ascii;
const Allocator = std.mem.Allocator;

const WORD_LENGTH = 5;

pub const AttemptError_Actual = error{
    NonAlphabetic,
    InvalidLength,
    IsLowercase,
};

pub const AttemptError_Guess = error{
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

    /// Returns an Attempt based on an `actual` word and a `guess` word.
    /// Can error on invalid `actual` or `guess`, or if allocations fail.
    pub fn evaluateGuess(actual: [:0]const u8, guess: [:0]const u8) !Attempt {
        // error check
        try validateWord(AttemptError_Actual, actual);
        try validateWord(AttemptError_Guess, guess);

        var bag = [_]i4{0} ** 26;
        var correctness = [_]Correctness{.Gray} ** WORD_LENGTH;

        for (actual) |a| {
            bag[a - 'A'] += 1;
        }

        // prioritize green
        for (actual, guess, 0..) |a, g, i| {
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

        return Attempt{ .word = guess, .correctness = correctness };
    }

    fn validateWord(comptime E: anytype, word: []const u8) E!void {
        if (E != AttemptError_Actual and E != AttemptError_Guess) unreachable;

        if (word.len != WORD_LENGTH) {
            return E.InvalidLength;
        }
        for (word) |c| {
            if (!ascii.isAlphabetic(c)) return E.NonAlphabetic;
            if (ascii.isLower(c)) return E.IsLowercase;
        }
    }
};

fn expectEqualAttempt(expected: *const Attempt, actual: *const Attempt) !void {
    try testing.expectEqualStrings(expected.word, actual.word);
    try testing.expectEqualSlices(Correctness, &expected.correctness, &actual.correctness);
}

test "guess evaluation check" {
    var expected: Attempt = undefined;
    var attempt: Attempt = undefined;

    attempt = try Attempt.evaluateGuess("HELLO", "HELLO");
    expected = Attempt{ .word = "HELLO", .correctness = .{.Green} ** 5 };
    try expectEqualAttempt(&expected, &attempt);

    attempt = try Attempt.evaluateGuess("HELLO", "RATTY");
    expected = Attempt{ .word = "RATTY", .correctness = .{.Gray} ** 5 };
    try expectEqualAttempt(&expected, &attempt);

    attempt = try Attempt.evaluateGuess("BOATS", "TAOSB");
    expected = Attempt{ .word = "TAOSB", .correctness = .{.Yellow} ** 5 };
    try expectEqualAttempt(&expected, &attempt);

    attempt = try Attempt.evaluateGuess("SILLY", "LILLY");
    expected = Attempt{ .word = "LILLY", .correctness = .{.Gray} ++ .{.Green} ** 4 };
    try expectEqualAttempt(&expected, &attempt);
}

test "error cases" {
    try testing.expectError(
        AttemptError_Actual.InvalidLength,
        Attempt.evaluateGuess("invalid", "irrelevant"),
    );

    try testing.expectError(
        AttemptError_Actual.NonAlphabetic,
        Attempt.evaluateGuess("12345", "irrelevant"),
    );

    try testing.expectError(
        AttemptError_Actual.IsLowercase,
        Attempt.evaluateGuess("hello", "irrelevant"),
    );

    try testing.expectError(
        AttemptError_Guess.IsLowercase,
        Attempt.evaluateGuess("HELLO", "hello"),
    );

    try testing.expectError(
        AttemptError_Guess.InvalidLength,
        Attempt.evaluateGuess("HELLO", "helloo"),
    );

    try testing.expectError(
        AttemptError_Guess.NonAlphabetic,
        Attempt.evaluateGuess("HELLO", "HI2U2"),
    );
}
