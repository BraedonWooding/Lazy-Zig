const std = @import("std");

pub fn iterator(comptime BaseType: type) type {
    return struct {
        state: BaseType,
        start: BaseType,
        end: BaseType,
        step: BaseType,

        const Self = @This();

        pub fn init(start: BaseType, end: BaseType, step: BaseType) Self {
            return Self{
                .state = 0,
                .start = start,
                .end = end,
                .step = step,
            };
        }

        pub fn count(self: *Self) usize {
            return (self.end - self.start - 1) / 2;
        }

        pub fn reset(self: *Self) void {
            self.state = self.start;
        }

        pub fn next(self: *Self) ?BaseType {
            if (self.state >= self.end) return null;

            self.state += self.step;
            return self.state;
        }
    };
}
