const std = @import("std");

pub fn iterator(comptime BaseType: type, comptime NewType: type, comptime ItType: type, select: fn (BaseType) NewType) type {
    return struct {
        nextIt: *ItType,

        const Self = @This();

        pub fn next(self: *Self) ?NewType {
            if (self.nextIt.next()) |nxt| {
                return select(nxt);
            }
            return null;
        }

        pub fn reset(self: *Self) void {
            self.nextIt.reset();
        }

        pub fn count(self: *Self) i32 {
            return self.nextIt.count();
        }
    };
}
