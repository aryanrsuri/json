## Implementing JSON (de)serialising and tokeniser in Zig

Since this project is more about learning Zig, I will adding more 
structure to the patterns, things that might not be most optimal for a 
prod ready Json serialising library.

Look into ./CHANGELOG for better and more information about the project.

## TODO

Remove the Token { .ch: []const u8} type, since there is no need to hold those literals
They really just mark the stack structure which is handleled by the state/other tokens
