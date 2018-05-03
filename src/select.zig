const std = @import("std");

pub fn iterator(comptime BaseType: type, comptime NewType: type, comptime ItType: type, select: fn(BaseType) NewType) type {
    return struct {
        nextIt: &ItType,

        const Self = this;

        pub fn next(self: &Self) ?NewType {
            while (self.nextIt.next()) |nxt| {
                return select(nxt);
            }
            return null;
        }

        pub fn reset(self: &Self) void {
            self.nextIt.reset();
        }
    };
}