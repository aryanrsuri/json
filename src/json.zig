//! Currently this `JSON` module provides a method to (de)serialise JSON into a tree like structure
//! The idea is you feed it JSON in a file, or arguement, and it attempts to parse it into its root semantics
//!
//! Author: arysuri at proton dot me
//! Licence: MIT
const std = @import("std");

pub const Token = union(enum) {
    array_start,
    array_end,
    object_start,
    object_end,
    number: []const u8,
    string: []const u8,
    true,
    false,
    null,
};

pub const State = enum {
    object_start,
    array_start,
    value,
    post_value,
    post_object_comma,
    string,
    number,
    end_of_document,
};

pub const Scanner = struct {
    buffer: []const u8 = undefined,
    state: State = .value,
    cursor: usize = 0,
    stack: std.ArrayList(u1),
    object_key: bool = false,
    map: std.StringArrayHashMap(?*Token),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, input: []const u8) @This() {
        const stack = std.ArrayList(u1).init(allocator);
        const map = std.StringArrayHashMap(?*Token).init(allocator);
        return .{ .allocator = allocator, .buffer = input, .stack = stack, .map = map };
    }

    pub fn deinit(self: *@This()) void {
        self.stack.deinit();
        self.map.deinit();
        self.* = undefined;
    }

    fn read_scalar(self: *@This()) !Token {
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
        }
        if (std.mem.eql(u8, slice, "null")) {
            return .null;
        } else {
            return error.SyntaxError;
        }
    }

    fn read_number(self: *@This()) []const u8 {
        const value_start = self.cursor;
        while (std.ascii.isDigit(self.buffer[self.cursor])) {
            self.read();
        }
        return self.buffer[value_start..self.cursor];
    }

    fn read_value(self: *@This()) []const u8 {
        const value_start = self.cursor;
        while (true) {
            switch (self.buffer[self.cursor]) {
                33, 35...127 => self.read(),
                else => break,
            }
        }
        return self.buffer[value_start..self.cursor];
    }

    fn read(self: *@This()) void {
        if (self.cursor + 1 >= self.buffer.len) {
            self.state = .end_of_document;
        } else {
            self.cursor += 1;
        }
    }

    pub fn next(self: *@This()) !?Token {
        self.next_non_whitespace();
        var token: ?Token = null;
        try switch (self.state) {
            .value => {
                switch (self.buffer[self.cursor]) {
                    '{' => {
                        _ = try self.stack.append(0);
                        self.state = .object_start;
                        token = .object_start;
                    },
                    '[' => {
                        _ = try self.stack.append(1);
                        self.state = .array_start;
                        token = .array_start;
                    },
                    '"' => self.state = .string,
                    't', 'f', 'n' => {
                        self.state = .post_value;
                        return try self.read_scalar();
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
                    '0'...'9', 'a'...'z', 'A'...'Z', '_' => {
                        const string = self.read_value();
                        if (self.object_key) {
                            try self.map.put(string, null);
                        }
                        return .{ .string = string };
                    },
                    else => return error.SyntaxError,
                }
            },
            .post_value => {
                if (self.object_key) {
                    self.object_key = false;
                    try switch (self.buffer[self.cursor]) {
                        ':' => self.state = .value,
                        else => error.SyntaxError,
                    };
                } else {
                    switch (self.buffer[self.cursor]) {
                        ',' => {
                            switch (self.stack.getLast()) {
                                0 => self.state = .post_object_comma,
                                1 => self.state = .value,
                            }
                        },
                        '}' => {
                            if (self.stack.pop() != 0) return error.SyntaxError;
                            token = .object_end;
                        },
                        ']' => {
                            if (self.stack.pop() != 1) return error.SyntaxError;
                            token = .array_end;
                        },
                        else => return error.SyntaxError,
                    }
                }
            },
            .object_start => {
                switch (self.buffer[self.cursor]) {
                    '"' => {
                        self.object_key = true;
                        self.state = .string;
                    },
                    '}' => {
                        _ = self.stack.pop();
                        token = .object_end;
                    },
                    else => return error.SyntaxError,
                }
            },
            .array_start => {
                switch (self.buffer[self.cursor]) {
                    ']' => {
                        _ = self.stack.pop();
                        token = .array_end;
                    },
                    else => {
                        self.state = .value;
                        return token;
                    },
                }
            },
            // Solved the issue of post object comma's failing to be a object key
            // Lifted straight from: https://github.com/ziglang/zig/blob/bf588f67d8c6261105f81fd468c420d662541d2a/lib/std/json/scanner.zig#L813
            .post_object_comma => {
                switch (self.buffer[self.cursor]) {
                    '"' => {
                        self.state = .string;
                        self.object_key = true;
                    },
                    else => return error.SyntaxError,
                }
            },
            else => error.SyntaxError,
        };
        self.read();
        return token;
    }

    fn next_non_whitespace(self: *@This()) void {
        while (std.ascii.isWhitespace(self.buffer[self.cursor])) {
            self.read();
        }
    }

    pub fn debug(self: *@This()) !void {
        while (self.state != .end_of_document) {
            const ntoken = try self.next();
            if (ntoken) |token| {
                var i: usize = 0;
                while (i < self.stack.items.len) : (i += 1) {
                    std.debug.print("->", .{});
                }
                std.debug.print("\t{any}\n", .{token});
            }
        }
        std.debug.print("map: {s}\n", .{self.map.keys()});
    }
};

test "JSON Simple" {
    const scanner_test_simple =
        \\  {"key":"100","key1":200}
    ;
    const d = std.testing.allocator;
    var s = Scanner.init(d, scanner_test_simple);
    defer s.deinit();

    while (s.state != .end_of_document) {
        const next = try s.next();
        if (next) |token| {
            var i: usize = 0;
            while (i < s.stack.items.len) : (i += 1) {
                std.debug.print("->", .{});
            }
            std.debug.print("\t{any}\n", .{token});
        }
    }
    std.debug.print("map: {s}\n", .{s.map.keys()});
}

test "JSON Full" {
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
    defer s.deinit();
    _ = try s.debug();
}

test "JSON HTTP" {
    const scanner_test =
        \\ {
        \\ "data": [{
        \\  "type": "articles",
        \\ "id": "1",
        \\"attributes": {
        \\ "title": "JSON:API paints my bikeshed!",
        \\ "body": "The shortest article. Ever.",
        \\ "created": "2015-05-22T14:56:29.000Z",
        \\ "updated": "2015-05-22T14:56:28.000Z"
        \\},
        \\"relationships": {
        \\ "author": {
        \\  "data": {"id": "42", "type": "people"}
        \\ }
        \\ }
        \\}],
        \\"included": [
        \\ {
        \\  "type": "people",
        \\ "id": "42",
        \\ "attributes": {
        \\  "name": "John",
        \\ "age": 80,
        \\ "gender": "male"
        \\ }
        \\ }
        \\ ]
        \\}
    ;

    const d = std.testing.allocator;
    var s = Scanner.init(d, scanner_test);
    defer s.deinit();
    _ = try s.debug();
}
