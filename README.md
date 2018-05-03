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
    // Lets create our objects using lazy
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
    // In this case we didn't have to reset, as the array automatically does
    var array = it.toArray(buf);
    var i: usize = 0;
    while (i < array.len) : (i += 1) {
        if (i > 0) warn(", ");
        warn("{}", array[i]);
    }
    // Note: you could also just put all the iterators into a single line like;
    var it = lazy.enumerate(0, 100, 1).where(even).select(pow);

    // You could also just create it from an array already existing
    var array = []i32 { 1, 2, 5, };
    var it = lazy.init(array).where(even).select(pow);
    // Works with hash_map, and array_list in std
}
```

## How to use

Just import the index like `const Lazy = @import("Lazy/index.zig");` and use like `Lazy.init(...)`. When a package manager comes along it will be different :).

## 'Lazy' Iterators vs 'Arrays'

Lazy iterators effectively allow us to 'yield' which basically just formulates a state machine around your code, figuring out the next step as you go.  To initialise a lazy iterator you just call `Lazy.init(array)`, and then you can perform whatever you want to the array, then to cast it back if you wish you can either call `.toArray(buffer)` (giving a buffer), or `.toList(allocator)` (giving an allocator, returning a list).

## Difference between 'lazy' and 'evaluated' functions

An evaluated function evaluates all the values within the 'set', this means that it has to resolve each value, furthermore it will reset the 'set' before and after.  An example would be `toArray`, or `contains`.  You can view it this way; lazy and evaluated functions work in parallel, you can lazily evaluate yourself through a set then perform an evaluated call on that set, and it will disregard the state of the lazy evaluation; however once you 'evaluate' a function it will reset any lazy execution as while they are parallel they aren't inclusive.  Maybe later on we can preserve state, for now we don't.