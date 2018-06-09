const std = @import("std");
const iteratorIt = @import("iterator.zig");
const sort = std.sort.sort;

pub fn iterator(comptime BaseType: type, comptime NewType: type, comptime ItType: type, comptime ascending: bool, comptime select: fn (BaseType) NewType) type {
    return struct {
        const Self = this;
        nextIt: *ItType,
        index: usize,
        count: usize,
        buf: []BaseType,

        pub fn next(self: *Self) ?NewType {
            if (self.count == 0) {
                // Sort
                var i: usize = 0;
                while (self.nextIt.next()) |nxt| {
                    self.buf[i] = nxt;
                    i += 1;
                }

                self.count = i;
                sort(BaseType, self.buf[0..self.count], compare);
            }

            if (self.index >= self.count) return null;

            defer self.index += 1;
            return self.buf[self.index];
        }

        pub fn reset(self: *Self) void {
            self.nextIt.reset();
        }

        fn compare(a: *const BaseType, b: *const BaseType) bool {
            if (ascending) {
                return select(*a) < select(*b);
            } else {
                return select(*a) > select(*b);
            }
        }
    };
}
