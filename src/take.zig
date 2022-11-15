pub fn iterator(comptime BaseType: type, comptime ItType: type, comptime amount: usize) type {
    return struct {
        nextIt: *ItType,

        const Self = @This();
        var i: usize = 0;

        pub fn next(self: *Self) ?BaseType {
            if (i >= amount) return null;

            if (self.nextIt.next()) |nxt| {
                i += 1;
                return nxt;
            }
            return null;
        }

        pub fn reset(self: *Self) void {
            self.nextIt.reset();
            i = 0;
        }

        pub fn count(_: *Self) i32 {
            return amount;
        }
    };
}
