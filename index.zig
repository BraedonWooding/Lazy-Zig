const std = @import("std");
const arrayIt = @import("src/arrayIterator.zig").iterator;
const iterator = @import("src/iterator.zig").iterator;
const TypeId = @import("builtin").TypeId;

pub fn init(obj: var) iterator(@typeOf(obj).Child, arrayIt(@typeOf(obj).Child)) {
    const BaseType = @typeOf(obj).Child;
    return iterator(BaseType, arrayIt(BaseType)) {
        .nextIt = arrayIt(BaseType).init(obj),
    };
}

test "Lazy" {
    var obj = []i32 { 0, 1, 2 };
    const result = []i32 { 0, 2 };
    var buf: [5]i32 = undefined;
    std.debug.assert(std.mem.eql(i32, init(obj[0..]).where(even).toArray(buf[0..]), result[0..]));
    // Longer format
    var it = init(obj[0..]).where(even);
    var i : usize = 0;
    while (it.next()) |nxt| {
        std.debug.assert(nxt == result[i]);
        i += 1;
    }
    std.debug.assert(i == 2);
}

fn even(val: i32) bool {
    return @rem(val, 2) == 0;
}