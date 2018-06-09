const std = @import("std");
const iteratorIt = @import("iterator.zig");
const sort = std.sort.sort;

pub fn iterator(comptime BaseType: type, comptime ItType: type) type {
    return struct {
        const Self = this;
        nextIt: *ItType,
        index: usize,
        count: usize,
        buf: []BaseType,

        pub fn next(self: *Self) ?BaseType {
            if (self.count == 0) {
                // Sort
                var i: usize = 0;
                while (self.nextIt.next()) |nxt| {
                    self.buf[i] = nxt;
                    i += 1;
                }

                self.count = i;
                self.index = self.count;
            }
            if (self.index == 0) {
                return null;
            } else {
                defer self.index -= 1;
                return self.buf[self.index - 1];
            }
        }

        pub fn reset(self: *Self) void {
            // maybe just reset count??
            self.nextIt.reset();
            self.count = 0;
            self.index = 0;
        }
    };
}
