const std = @import("std");
const TypeId = @import("builtin").TypeId;
const whereIt = @import("where.zig").iterator;
const selectIt = @import("select.zig").iterator;

pub fn iterator(comptime BaseType: type, comptime ItType: type) type {
    return struct {
        nextIt: ItType,

        const Self = this;

        pub fn next(self: &Self) ?BaseType {
            return self.nextIt.next();
        }

        pub fn reset(self: &Self) void {
            self.nextIt.reset();
        }

        pub fn where(self: &Self, comptime filter: fn (BaseType) bool) iterator(BaseType, whereIt(BaseType, ItType, filter)) {
            const whereType = whereIt(BaseType, ItType, filter);
            return iterator(BaseType, whereType) {
                .nextIt = whereType {
                    .nextIt = &self.nextIt,
                },
            };
        }

        // Currently requires you to give a new type, since can't have 'var' return type.
        pub fn select(self: &Self, comptime NewType: type, comptime filter: fn(BaseType) NewType) iterator(NewType, selectIt(BaseType, NewType, ItType, filter)) {
            const selectType = selectIt(BaseType, NewType, ItType, filter);
            return iterator(NewType, selectType) {
                .nextIt = selectType {
                    .nextIt = &self.nextIt,
                },
            };
        }

        pub fn contains(self: &Self, value: BaseType) bool {
            self.reset();
            var isTrue = false;
            while (self.next()) |nxt| {
                if (nxt == value) {
                    isTrue = true;
                    break;
                }
            }
            self.reset();
            return isTrue;
        }

        pub fn toArray(self: &Self, buffer: []BaseType) []BaseType {
            self.reset();
            var count: usize = 0;
            while (self.next()) |nxt| {
                buffer[count] = nxt;
                count += 1;
            }
            self.reset();
            return buffer[0..count];
        }

        pub fn toList(self: &Self, allocator: &std.mem.Allocator) std.ArrayList(BaseType) {
            self.reset();
            var list = std.ArrayList(BaseType).init(allocator);
            while (self.next()) |nxt| {
                list.append(nxt);
            }
            self.reset();
            return list;
        }
    };
}