const std = @import("std");

pub fn iterator(comptime BaseType: type, comptime amount: usize) type {
    return struct {
        nextIt: &ItType,

        const Self = this;
        var skipped: bool = false;

        pub fn next(self: &Self) ?BaseType {
            if (!skipped) {
                skipped = true;
                var i: usize = 0;
                while (i < amount) : (i += 1) {
                    if (self.nextIt.next() == null) return null;
                }
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