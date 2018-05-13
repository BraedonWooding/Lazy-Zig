const std = @import("std");
const info = @import("info");

pub fn iterator(comptime BaseType: type, comptime NewType: type, comptime ItType: type, select: fn(BaseType) []const NewType) type {
    return struct {
        nextIt: &ItType,

        var currentIt: ?ItType = null;
        const Self = this;

        pub fn next(self: &Self) ?NewType {
            if (currentIt) |it| {
                if (it.next()) |nxt| {
                    return nxt;
                } else {
                    currentIt = null;
                }
            }

            if (self.nextIt.next()) |nxt| {
                var val = select(nxt);
                comptime const typeInfo = info.getInfo(@typeOf(val));
                if (typeInfo == info.Other) { 
                    return val;
                }
                else {
                    currentIt = info.initType(@typeOf(val), val);
                    return self.next();
                }
            }
            return null;
        }

        pub fn reset(self: &Self) void {
            self.nextIt.reset();
            currentIt = null;
        }

        pub fn count(self: &Self) i32 {
            @compileError("Can't use count on select many");
        }
    };
}