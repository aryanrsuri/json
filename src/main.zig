const std = @import("std");
const Scanner = @import("json.zig").Scanner;

pub fn main() !void {
    const file =
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
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var scanner = Scanner.init(allocator, file);
    defer scanner.deinit();
    while (scanner.state != .end_of_document) {
        const next = try scanner.next();
        if (next) |token| {
            std.debug.print("nesting: {d}\ttoken: {any}\n", .{ scanner.stack.items.len, token });
        }
    }
}
