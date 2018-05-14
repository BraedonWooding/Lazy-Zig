const std = @import("std");
const info = @import("info.zig");
const arrayIt = @import("arrayIterator.zig").iterator;

pub fn iterator(comptime BaseType: type, comptime NewType: type, comptime ItType: type, select: fn(BaseType) []const NewType) type {
    return struct {
        nextIt: &ItType,
        currentIt: ?arrayIt(NewType),
        const Self = this;

        pub fn next(self: &Self) ?NewType {
            if (self.currentIt) |it| {
                if (it.next()) |nxt| {
                    return nxt;
                } else {
                    self.currentIt = null;
                }
            }

            if (self.nextIt.next()) |nxt| {
                var val = select(nxt);
                self.currentIt = arrayIt(NewType).init(val);
                return self.next();
            }
            return null;
        }

        pub fn reset(self: &Self) void {
            self.nextIt.reset();
            self.currentIt = null;
        }

        pub fn count(self: &Self) i32 {
            @compileError("Can't use count on select many");
        }
    };
}