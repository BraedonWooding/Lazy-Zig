const std = @import("std");
const TypeId = @import("builtin").TypeId;
const whereIt = @import("where.zig").iterator;

pub fn iterator(comptime BaseType: type, comptime ItType: type) type {
    return struct {
        nextIt: ItType,

        const Self = this;

        pub fn next(self: &Self) ?BaseType {
            return self.nextIt.next();
        }

        pub fn where(self: &Self, comptime filter: fn (BaseType) bool) iterator(BaseType, whereIt(BaseType, ItType, filter)) {
            const whereType = whereIt(BaseType, ItType, filter);
            return iterator(BaseType, whereType) {
                .nextIt = whereType {
                    .nextIt = &self.nextIt,
                },
            };
        }

        pub fn toArray(self: &Self, buffer: []BaseType) []BaseType {
            var count: usize = 0;
            while (self.next()) |nxt| {
                buffer[count] = nxt;
                count += 1;
            }
            return buffer[0..count];
        }
    };
}