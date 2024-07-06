//! Currently this `JSON` module provides a method to (de)serialise JSON into a tree like structure
//! The idea is you feed it JSON in a file, or arguement, and it attempts to parse it into its root semantics
//!
//! Author: arysuri at proton dot me
//! Licence: MIT
//!
const std = @import("std");

/// Token defines the type the JSON value can take on
/// {}  or Object
/// []  or Array
/// 1   or number
/// "1" or string
/// 0b1 or true
/// 0b0 or false
///     or null

// zig fmt: off
pub const Token = union(enum) { 
    array_start, array_end, 
    object_start, object_end, 
    number: []const u8, string: []const u8,
    ch: u8,
    true, false, null, 
    end_of_document};
pub const State = enum { 
    object_start, array_start, 
    value, post_value, 
    string, end_of_document,
    number,

};
// zig fmt: on

pub const Scanner = struct {
    buffer: []const u8 = undefined,
    state: State = .value,
    cursor: usize = 0,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, input: []const u8) @This() {
        return .{ .allocator = allocator, .buffer = input };
    }

    pub fn deinit(self: *@This()) void {
        self.* = undefined;
    }

    pub fn read_boolean(self: *@This()) !Token {
        const value_start = self.cursor;
        while (std.ascii.isAlphabetic(self.buffer[self.cursor])) {
            self.read();
        }

        const slice = self.buffer[value_start..self.cursor];
        if (std.mem.eql(u8, slice, "true")) {
            return .true;
        }
        if (std.mem.eql(u8, slice, "false")) {
            return .false;
        } else {
            return error.SyntaxError;
        }
        // return switch (slice) {
        //     std.mem.eql(u8, slice, "true") => .true,
        //     std.mem.eql(u8, slice, "false") => .false,
        //     else => error.SyntaxError,
        // };
    }

    pub fn read_number(self: *@This()) []const u8 {
        const value_start = self.cursor;
        while (std.ascii.isDigit(self.buffer[self.cursor])) {
            self.read();
        }
        return self.buffer[value_start..self.cursor];
    }

    pub fn read_value(self: *@This()) []const u8 {
        const value_start = self.cursor;
        while (true) {
            switch (self.buffer[self.cursor]) {
                // More explicit u8 represntation could be used here
                33, 35...127 => self.read(),
                else => break,
            }
        }
        return self.buffer[value_start..self.cursor];
    }

    pub fn read(self: *@This()) void {
        if (self.cursor + 1 >= self.buffer.len) {
            self.state = .end_of_document;
        } else {
            self.cursor += 1;
        }
    }

    pub fn next(self: *@This()) !Token {
        self.next_non_whitespace();
        var token: Token = .{ .ch = self.buffer[self.cursor] };
        try switch (self.state) {
            // For fun, do I convert all the ASCII to its Dec representation?
            .value => {
                switch (self.buffer[self.cursor]) {
                    '{' => {
                        self.state = .object_start;
                        token = .object_start;
                    },
                    '[' => {
                        self.state = .array_start;
                        token = .array_start;
                    },
                    '"' => self.state = .string,
                    't', 'f' => {
                        self.state = .post_value;
                        return try self.read_boolean();
                    },
                    '0'...'9' => {
                        self.state = .post_value;
                        return .{ .number = self.read_number() };
                    },
                    else => return error.SyntaxError,
                }
            },
            .string => {
                switch (self.buffer[self.cursor]) {
                    '"' => self.state = .post_value,
                    '0'...'9', 'a'...'z', 'A'...'Z', '_', '-' => return .{ .string = self.read_value() },
                    else => return error.SyntaxError,
                }
            },
            .post_value => {
                switch (self.buffer[self.cursor]) {
                    ':', ',' => self.state = .value,
                    '}' => token = .object_end,
                    ']' => token = .array_end,
                    else => return error.Syntax,
                }
            },
            .object_start => {
                switch (self.buffer[self.cursor]) {
                    '"' => self.state = .string,
                    '}' => token = .object_end,
                    else => return error.SyntaxError,
                }
            },
            .array_start => {
                switch (self.buffer[self.cursor]) {
                    ']' => token = .array_end,
                    else => {
                        self.state = .value;
                        return token;
                    },
                }
            },
            else => error.SyntaxError,
        };
        self.read();
        return token;
    }

    pub fn peek(self: *@This()) u8 {
        return self.buffer[self.cursor + 1];
    }

    fn next_non_whitespace(self: *@This()) void {
        while (std.ascii.isWhitespace(self.buffer[self.cursor])) {
            self.read();
        }
    }
};

test "Json" {
    // Lifted this test from scanner_test.zig from ziglang/zig REPO
    const scanner_test =
        \\{
        \\  "Image": {
        \\      "Width":  800,
        \\      "Height": 600,
        \\      "Title":  "View from 15th Floor",
        \\      "Thumbnail": {
        \\          "Url":    "http://www.example.com/image/481989943",
        \\          "Height": 125,
        \\          "Width":  100
        \\      },
        \\      "Animated" : false,
        \\      "IDs": [116, 943, 234, 38793]
        \\    }
        \\}
    ;

    const d = std.testing.allocator;
    var s = Scanner.init(d, scanner_test);

    while (s.state != .end_of_document) {
        const v = try s.next();
        // _ = v;
        std.debug.print("Token is {any}\n", .{v});
    }
}
