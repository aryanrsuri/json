const std = @import("std");
const Scanner = @import("json.zig").Scanner;

pub fn main() !void {
    const file =
        \\{"this": "value", "number": 100, "array": [1,2,3], "array of strings": ["1","2"]}
    ;
    // const f =
    //     \\{"this":"is", "that": 400, "things": [1,2,3]}
    // ;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var s = Scanner.init(allocator, file);
    while (s.state != .end_of_document) {
        const v = try s.next();
        std.debug.print("Token is {any}\n", .{v});
    }
}
