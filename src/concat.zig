const std = @import("std");

pub fn iterator(comptime BaseType: type, comptime ItType: type) type {
    return struct {
        nextIt: *ItType,
        otherIt: *ItType,

        const Self = @This();

        pub fn count(self: *Self) i32 {
            return self.nextIt.count() + self.otherIt.count();
        }

        pub fn next(self: *Self) ?BaseType {
            if (self.nextIt.next()) |nxt| {
                return nxt;
            } else if (self.otherIt.next()) |nxt| {
                return nxt;
            }
            return null;
        }

        pub fn reset(self: *Self) void {
            self.nextIt.reset();
        }
    };
}
