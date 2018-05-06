const std = @import("std");

pub fn iterator(comptime BaseType: type, comptime condition: fn(BaseType) bool) type {
    return struct {
        nextIt: &ItType,

        const Self = this;
        var skipped: bool = false;

        pub fn next(self: &Self) ?BaseType {
            if (!skipped) {
                skipped = true;
                while (self.nextIt.next()) |nxt| {
                    if (!condition(nxt)) return nxt;
                }
                return null;
            }

            return self.nextIt.next();
        }

        pub fn reset(self: &Self) void {
            self.nextIt.reset();
            i = 0;
        }

        pub fn count(self: &Self) i32 {
            return amount;
        }
    };
}