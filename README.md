# Implementing JSON (de)serialising and tokeniser in Zig

Since this project is more about learning Zig, I will adding more 
structure to the patterns, things that might not be most optimal for a 
prod ready Json serialising library.

Look into ./CHANGELOG for better and more information about the project.

## TODO

* [X] Remove the `Token { .ch: []const u8}` type, since there is no need to hold those literals.They really just mark the stack structure which is handleled by the state/other tokens
* [X] (CORE) Implement a stack to track nesting of objects/arrays
* [ ] (CORE) Make a linked hash map, that allows accessing of JSON as a python dict style. This hashmap should be allowed to have nature nesting 
    * Key strings collected 
        * While Keys can now be collected, since there is no nesting logic to them, repetitive keys (Height in the example) get ignored
        * A JSON type should be made to hold the keys and values such that in pseudocode 
        ``` 
        > json.get("Image").get("Height") 
        > 800
        > json.get("Image").get("Thumbnail").get("Height")
        > 125

        ```

## Example

```
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
```

```
>> zig  build run
-|	json.Token{ .object_start = void }
-|	json.Token{ .string = { 73, 109, 97, 103, 101 } }
--|	json.Token{ .object_start = void }
--|	json.Token{ .string = { 87, 105, 100, 116, 104 } }
--|	json.Token{ .number = { 56, 48, 48 } }
--|	json.Token{ .string = { 72, 101, 105, 103, 104, 116 } }
--|	json.Token{ .number = { 54, 48, 48 } }
--|	json.Token{ .string = { 84, 105, 116, 108, 101 } }
--|	json.Token{ .string = { 86, 105, 101, 119 } }
--|	json.Token{ .string = { 102, 114, 111, 109 } }
--|	json.Token{ .string = { 49, 53, 116, 104 } }
--|	json.Token{ .string = { 70, 108, 111, 111, 114 } }
--|	json.Token{ .string = { 84, 104, 117, 109, 98, 110, 97, 105, 108 } }
---|	json.Token{ .object_start = void }
---|	json.Token{ .string = { 85, 114, 108 } }
---|	json.Token{ .string = { 104, 116, 116, 112, 58, 47, 47, 119, 119, 119, 46, 101, 120, 97, 109, 112, 108, 101, 46, 99, 111, 109, 47, 105, 109, 97, 103, 101, 47, 52, 56, 49, 57, 56, 57, 57, 52, 51 } }
---|	json.Token{ .string = { 72, 101, 105, 103, 104, 116 } }
---|	json.Token{ .number = { 49, 50, 53 } }
---|	json.Token{ .string = { 87, 105, 100, 116, 104 } }
---|	json.Token{ .number = { 49, 48, 48 } }
--|	json.Token{ .object_end = void }
--|	json.Token{ .string = { 65, 110, 105, 109, 97, 116, 101, 100 } }
--|	json.Token{ .false = void }
--|	json.Token{ .string = { 73, 68, 115 } }
---|	json.Token{ .array_start = void }
---|	json.Token{ .number = { 49, 49, 54 } }
---|	json.Token{ .number = { 57, 52, 51 } }
---|	json.Token{ .number = { 50, 51, 52 } }
---|	json.Token{ .number = { 51, 56, 55, 57, 51 } }
--|	json.Token{ .array_end = void }
-|	json.Token{ .object_end = void }
|	json.Token{ .object_end = void }
map: { Image, Width, Height, Title, Thumbnail, Url, Animated, IDs }
```
