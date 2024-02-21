//! Quickly parse JSON into k,v tokens
//! For higher-level abstractions

const std = @import("std");
const Bytes = []const u8;
pub const JSON = struct {
    bytes: Bytes,
    index: usize = 0,
    line: usize = 0,
    state: State = .start,
    pub fn read(json: *JSON) []const u8 {
        const start: usize = json.index;
        while (switch (json.bytes[json.index]) {
            '0'...'9',
            'A'...'Z',
            'a'...'z',
            => true,
            else => false,
        }) {
            json.index = json.index + 1;
        }
        return json.bytes[start..json.index];
    }

    pub fn next(json: *JSON) ?Token {
        var token: Token = undefined;
        while (json.index < json.bytes.len) {
            const byte = json.bytes[json.index];
            switch (json.state) {
                .start => switch (byte) {
                    ' ', '\t', 'r', '\n' => {},
                    '{' => json.state = .key_start,
                    else => token.tag = .invalid,
                },
                .key_start => switch (byte) {
                    ':', ' ', '\t', 'r', '\n' => {},
                    '}' => token.tag = .invalid,
                    // TODO: Implement strings must begin with ''
                    else => {
                        token.bytes = json.read();
                        token.tag = .key;
                        json.state = .val_start;
                        return token;
                    },
                },
                .val_start => switch (byte) {
                    ':', ' ', '\t', 'r', '\n' => {},
                    // TODO: Add json nesting
                    // '{' => {},
                    // TODO: Add array nesting
                    // '[' => {},
                    // TODO: Add number parsing
                    // '0'..'9' => {},
                    '}' => token.tag = .invalid,
                    // TODO: Implement strings must begin with ''
                    // TODO: Implement token type of variable
                    else => {
                        token.bytes = json.read();
                        token.tag = .str_value;
                        json.state = .val_end;
                        return token;
                    },
                },
                .val_end => switch (byte) {
                    ' ', '\t', 'r', '\n' => {},
                    ',' => {
                        json.index += 1;
                        json.state = .key_start;
                        json.line += 1;
                    },
                    else => token.tag = .invalid,
                },
            }

            json.index = json.index + 1;
        }

        return .{ .tag = .eof, .bytes = json.bytes[json.bytes.len..] };
    }
};

pub const State = enum {
    start,
    key_start,
    val_start,
    val_end,
};

pub const Token = struct {
    tag: Type,
    bytes: Bytes,
    pub const Type = enum {
        key,
        str_value,
        num_value,
        null_value,
        declr,
        array,
        object,
        eof,
        invalid,
    };
};

pub fn main() !void {}

test "json" {
    const bytes =
        \\ {
        \\ x : y,
        \\ z: a,
        \\ b: c,
        \\ d: 41,
        \\ }
    ;

    var json: JSON = .{ .bytes = bytes };
    std.debug.print("\n", .{});
    while (true) {
        const token = json.next();
        if (token) |tok| {
            if (tok.tag == .eof) break;
            std.debug.print("0{d} {s}->{s}\n", .{ json.line, @tagName(tok.tag), tok.bytes });
        }
    }
}
