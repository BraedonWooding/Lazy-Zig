const std = @import("std");

pub fn iterator(comptime BaseType: type, comptime ItType: type, filter: fn(BaseType) bool) type {
    return struct {
        nextIt: &ItType,

        const Self = this;

        pub fn next(self: &Self) ?BaseType {
            while (self.nextIt.next()) |nxt| {
                if (filter(nxt)) {
                    return nxt;
                }
            }
            return null;
        }

        pub fn reset(self: &Self) void {
            self.nextIt.reset();
        }

        pub fn count(self: &Self) i32 {
            return self.nextIt.count();
        }
    };
}