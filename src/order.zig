const std = @import("std");
const iteratorIt = @import("iterator.zig");
const sort = std.sort.sort;

pub fn iterator(comptime BaseType: type, comptime NewType, comptime ascending: bool, comptime select: fn(BaseType) NewType, buf: []BaseType) type {
    return struct {
        const Self = this;
        nextIt: &ItType,
        
        var index: usize = 0;
        var count: usize = 0;

        pub fn next(self: &Self) ?BaseType {
            if (count == 0) {
                // Sort
                var i: usize = 0;
                while (nextIt.next()) |nxt| {
                    buf[i] = nxt;
                    i += 1;
                }

                count = i;
                sort(BaseType, buf[0..count], comparer);
            }

            if (index >= count) return null;

            defer index += 1;
            return buf[index];
        }

        pub fn reset(self: &Self) void {
            self.nextIt.reset();
        }

        fn compare(a: &const BaseType, b: &const BaseType) {
            if (ascending) {
                return select(*a) < select(*b);
            } else {
                return select(*a) > select(*b);
            }
        }
    };
}
