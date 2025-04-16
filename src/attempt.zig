const std = @import("std");
const testing = std.testing;
const ascii = std.ascii;
const Allocator = std.mem.Allocator;

pub const WORD_LENGTH = 5;

/// The valid wordlist as an iterator
pub var WORDLIST = std.mem.tokenizeAny(u8, @embedFile("./wordlist.txt"), "\r\n");

/// Error types are duplicated to differentiate actual word error and guess error.
pub const EvaluateError_Actual = error{
    NonAlphabetic,
    InvalidLength,
    IsLowercase,
    InvalidWord,
};

pub const EvaluateError_Guess = error{
    NonAlphabetic,
    InvalidLength,
    IsLowercase,
    InvalidWord,
};

/// The color to be applied to a character during evaluation
pub const Correctness = enum {
    Gray,
    Green,
    Yellow,
};

/// The struct to be used for rendering every round.
/// Contains the word guessed for that round, and the character's corresponding correctness
pub const Attempt = struct {
    word: [:0]const u8,
    correctness: [WORD_LENGTH]Correctness = .{.Gray} ** WORD_LENGTH,

    /// Helper function to create an `Attempt` struct
    pub fn new(word: [:0]const u8, correctness: [WORD_LENGTH]Correctness) Attempt {
        return Attempt{ .word = word, .correctness = correctness };
    }
};

/// An `Attempt` factory. Creates `Attempt`s using a stored `actual` word and the method `evaluate`.
/// Has two initalization methods, `Evaluator.new()` and `Evaluator.newRand()`.
pub const Evaluator = struct {
    actual: [:0]const u8,

    /// Returns an Attempt based on an `actual` word and a `guess` word.
    /// Can error on invalid `actual` or `guess`, or if allocations fail.
    pub fn evaluate(self: *const Evaluator, allocator: Allocator, guess: [:0]const u8) !*Attempt {
        // error check
        try validateWord(EvaluateError_Actual, self.actual);
        try validateWord(EvaluateError_Guess, guess);

        // Counter for all the letters in the word.
        var bag = [_]i4{0} ** 26;
        var correctness = [_]Correctness{.Gray} ** WORD_LENGTH;

        // We count all existing letters and put them into the bag.
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

            // we've already done our check for correct spot correct letter, so now
            // we check if the letter *exists* within the word using our `bag`.
            if (bag[slot] > 0) {
                correctness[i] = .Yellow;
                bag[slot] -= 1;
            }
        }

        // we create an `Attempt` on the heap. Probably suboptimal but I do not
        // have the energy to refactor this again.
        const result: *Attempt = try allocator.create(Attempt);
        result.* = Attempt.new(guess, correctness);

        return result;
    }

    /// Validates whether a word is valid or not.
    /// A valid word is all uppercase, length is same as `WORD_LENGTH`, and is alphabetic.
    fn validateWord(comptime E: anytype, word: []const u8) E!void {
        WORDLIST.reset();

        // ducktyping the error
        if (E != EvaluateError_Actual and E != EvaluateError_Guess) unreachable;

        if (word.len != WORD_LENGTH) {
            return E.InvalidLength;
        }

        for (word) |c| {
            if (!ascii.isAlphabetic(c)) return E.NonAlphabetic;
            if (ascii.isLower(c)) return E.IsLowercase;
        }

        // lastly we check if the word is in the wordlist via *LINEAR SEARCH*
        // please contact me if you have a better way of finding for a match in
        // an iterator.
        var flag: bool = false;
        var validword = WORDLIST.next();

        while (validword) |v| {
            if (std.mem.eql(u8, v, word)) {
                flag = true;
                break;
            }

            validword = WORDLIST.next();
        }

        if (!flag) {
            return E.InvalidWord;
        }
    }

    pub fn new(actual: [:0]const u8) Evaluator {
        return .{ .actual = actual };
    }

    pub fn newRand() !Evaluator {
        // hard coded because iterating for length is too much of a performance hit
        const wordlist_len: u32 = 12972;
        var word_idx = std.crypto.random.uintLessThan(u64, wordlist_len);

        while (word_idx > 0) : (word_idx -= 1) {
            _ = WORDLIST.next();
        }

        const word = WORDLIST.next().?;
        return Evaluator.new(@ptrCast(word));
    }
};

/// Helper function for unit tests
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

    attempt = try Evaluator.new("SILLY").evaluate(allocator, "WILLY");
    expected = Attempt.new("WILLY", .{.Gray} ++ .{.Green} ** 4);
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
