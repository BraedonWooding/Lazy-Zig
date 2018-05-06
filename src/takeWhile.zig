const std = @import("std");

pub fn iterator(comptime BaseType: type, comptime condition: fn(BaseType) bool) type {
    return struct {
        nextIt: &ItType,

        const Self = this;
        var reachedCondition: bool = false;

        pub fn next(self: &Self) ?BaseType {
            if (reachedCondition) return null;

            if (self.nextIt.next()) |nxt| {
                if (!condition(nxt)) {
                    reachedCondition = true;
                    return null;
                }
                return nxt;
            }
            return null;
        }

        pub fn reset(self: &Self) void {
            self.nextIt.reset();
            reachedCondition = false;
        }

        pub fn count(self: &Self) usize {
            @compileError("Count not suitable on take while");
        }
    };
}