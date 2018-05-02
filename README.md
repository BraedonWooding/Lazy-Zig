# Lazily-Zig (Lazy)
Basically Linq in Zig.

Provides just a ton of really nice LINQ like commands, these can be applied on any array.  Will also support iterators in the future.

## Example Code

Lets say you want to get all the even values in an array;
```Java
const Lazy = @import("Lazy/index.zig");
const warn = @import("std").debug.warn;

// Till lambdas exist we need to use this sadly
fn even(val: i32) bool {
    return @rem(val, 2) == 0;
}

fn pow(val: i32) i32 {
    return val * val;
}

fn main() void {
    // Lets create our objects using LIZQ
    // Enumerate goes over a range
    var it = Lazy.enumerate(0, 100, 1);
    // Next we want to do a 'where' to select what we want to
    it = it.where(even);
    // Then we want to do a 'select' to do a power operation
    it = it.select(pow);
    // Finally we want to go through each item and print them
    // like; 4, 16, ...
    if (it.next()) |next| {
        warn("{}");
    }
    for (it.next()) |next| {
        warn(", {}", next);
    }
    warn("\n");

    // Lets say we want to get an array of the options;
    // first lets reset it to the beginning;
    // NOTE: it keeps all the operations you performed on it
    // just resets the laziness.
    it.reset();
    var buf: [100]i32 = 0;
    // Lets turn it into an array
    var array = it.toArray(buf);
    var i: usize = 0;
    while (i < array.len) : (i += 1) {
        if (i > 0) warn(", ");
        warn("{}", array[i]);
    }
    // Note: you could also just put all the iterators into a single line like;
    var it = lizq.enumerate(0, 100, 1).where(even).select(pow);
}
```

## How to use

Just import the index like `const Lazy = @import("Lazy/index.zig");` and use like `Lazy.init(...)`. When a package manager comes along it will be different :).

## 'LIZQ' Iterators vs 'Arrays'

Lizq iterators effectively allow us to 'yield' which basically just formulates a state machine around your code, figuring out the next step as you go.  To initialise a lizq iterator you just call `Lazy.init(array)`, and then you can perform whatever you want to the array, then to cast it back if you wish you can either call `.toArray(buffer)` (giving a buffer), or `.toArray(allocator)` (giving an allocator).
