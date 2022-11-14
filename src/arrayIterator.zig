const std = @import("std");

pub fn iterator(comptime BaseType: type) type {
    return struct {
        state: usize,
        raw: []const BaseType,

        const Self = @This();

        pub fn init(raw: []const BaseType) Self {
            return Self{
                .state = 0,
                .raw = raw,
            };
        }

        pub fn count(self: *Self) usize {
            return self.raw.len;
        }

        pub fn reset(self: *Self) void {
            self.state = 0;
        }

        pub fn next(self: *Self) ?BaseType {
            if (self.state >= self.raw.len) return null;

            const value = self.raw[self.state];
            self.state += 1;
            return value;
        }
    };
}
