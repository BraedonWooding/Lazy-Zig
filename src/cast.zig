pub fn iterator(comptime BaseType: type, comptime NewType: type, comptime ItType: type) type {
    return struct {
        nextIt: *ItType,

        const Self = @This();

        pub fn count(self: *Self) usize {
            return self.nextIt.count();
        }

        pub fn next(self: *Self) ?NewType {
            if (self.nextIt.next()) |nxt| {
                switch (@typeInfo(BaseType)) {
                    .Int => return @intCast(nxt),
                    else => return NewType(nxt),
                }
            }
            return null;
        }

        pub fn reset(self: *Self) void {
            self.nextIt.reset();
        }
    };
}
