const std = @import("std");
const iteratorIt = @import("iterator.zig");
const Vec = std.ArrayList;
const sort = std.sort.sort;

pub fn iterator(comptime BaseType: type, comptime NewType, comptime ascending: bool, comptime select: fn(BaseType) NewType, buf: []BaseType) type {
    return struct {
        const Self = this;
        nextIt: &ItType,
        
        var index: usize = 0;
        var count: usize = 0;
        var diff: usize = 0;
        var nextVal: ?BaseType = null;

        pub fn next(self: &Self) ?BaseType {
            if (index >= count) {
                diff = count;
                index = count;
                var i: usize = 0;
                if (nextVal == null) {
                    nextVal = nextIt.next();
                    if (nextVal == null) return null;
                    buf[i] = nextVal;
                    i += 1;
                }

                while (nextIt.next()) |nxt| {
                    if (nxt != nextVal) {
                        nextVal = nxt;
                        break;
                    }
                    buf[i] = nxt;
                    i += 1;
                }

                count += i;
                sort(BaseType, buf[0..i], comparer);
            }

            if (index >= count) return null;

            defer index += 1;
            return buf[index - diff];
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
