# Implementing JSON (de)serialising and tokeniser in Zig

Since this project is more about learning Zig, I will adding more 
structure to the patterns, things that might not be most optimal for a 
prod ready Json serialising library.

Look into ./CHANGELOG for better and more information about the project.

## TODO

* [ X ] Remove the `Token { .ch: []const u8}` type, since there is no need to hold those literals.They really just mark the stack structure which is handleled by the state/other tokens


## Example

`
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
`

`
>> zig  build run
nesting: 1      token: json.Token{ .object_start = void }
nesting: 1      token: json.Token{ .string = { 73, 109, 97, 103, 101 } }
nesting: 2      token: json.Token{ .object_start = void }
nesting: 2      token: json.Token{ .string = { 87, 105, 100, 116, 104 } }
nesting: 2      token: json.Token{ .number = { 56, 48, 48 } }
nesting: 2      token: json.Token{ .string = { 72, 101, 105, 103, 104, 116 } }
nesting: 2      token: json.Token{ .number = { 54, 48, 48 } }
nesting: 2      token: json.Token{ .string = { 84, 105, 116, 108, 101 } }
nesting: 2      token: json.Token{ .string = { 86, 105, 101, 119 } }
nesting: 2      token: json.Token{ .string = { 102, 114, 111, 109 } }
nesting: 2      token: json.Token{ .string = { 49, 53, 116, 104 } }
nesting: 2      token: json.Token{ .string = { 70, 108, 111, 111, 114 } }
nesting: 2      token: json.Token{ .string = { 84, 104, 117, 109, 98, 110, 97, 105, 108 } }
nesting: 3      token: json.Token{ .object_start = void }
nesting: 3      token: json.Token{ .string = { 85, 114, 108 } }
nesting: 3      token: json.Token{ .string = { 104, 116, 116, 112, 58, 47, 47, 119, 119, 119, 46, 101, 120, 97, 109, 112, 108, 101, 46, 99, 111, 109, 47, 105, 109, 97, 103, 101, 47, 52, 56, 49, 57, 56, 57, 57, 52, 51 } }
nesting: 3      token: json.Token{ .string = { 72, 101, 105, 103, 104, 116 } }
nesting: 3      token: json.Token{ .number = { 49, 50, 53 } }
nesting: 3      token: json.Token{ .string = { 87, 105, 100, 116, 104 } }
nesting: 3      token: json.Token{ .number = { 49, 48, 48 } }
nesting: 2      token: json.Token{ .object_end = void }
nesting: 2      token: json.Token{ .string = { 65, 110, 105, 109, 97, 116, 101, 100 } }
nesting: 2      token: json.Token{ .false = void }
nesting: 2      token: json.Token{ .string = { 73, 68, 115 } }
nesting: 3      token: json.Token{ .array_start = void }
nesting: 3      token: json.Token{ .number = { 49, 49, 54 } }
nesting: 3      token: json.Token{ .number = { 57, 52, 51 } }
nesting: 3      token: json.Token{ .number = { 50, 51, 52 } }
nesting: 3      token: json.Token{ .number = { 51, 56, 55, 57, 51 } }
nesting: 2      token: json.Token{ .array_end = void }
nesting: 1      token: json.Token{ .object_end = void }
nesting: 0      token: json.Token{ .object_end = void }
`
