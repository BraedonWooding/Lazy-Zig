const std = @import("std");
const whereIt = @import("where.zig").iterator;
const selectIt = @import("select.zig").iterator;
const castIt = @import("cast.zig").iterator;
const orderIt = @import("order.zig").iterator;
const skipIt = @import("skip.zig").iterator;
const skipWhileIt = @import("skipWhile.zig").iterator;
const takeIt = @import("take.zig").iterator;
const takeWhileIt = @import("takeWhile.zig").iterator;
const concatIt = @import("concat.zig").iterator;
const selectManyIt = @import("selectMany.zig").iterator;
const reverseIt = @import("reverse.zig").iterator;

pub fn iterator(comptime BaseType: type, comptime ItType: type) type {
    return struct {
        nextIt: ItType,

        const Self = @This();

        pub fn next(self: *Self) ?BaseType {
            return self.nextIt.next();
        }

        pub fn reset(self: *Self) void {
            self.nextIt.reset();
        }

        pub fn count(self: *Self) i32 {
            return self.nextIt.count();
        }

        fn returnBasedOnThis(self: *Self, comptime TypeA: type, comptime TypeB: type) iterator(TypeA, TypeB) {
            return iterator(TypeA, TypeB){
                .nextIt = TypeB{ .nextIt = &self.nextIt },
            };
        }

        pub fn where(self: *Self, comptime filter: fn (BaseType) bool) iterator(BaseType, whereIt(BaseType, ItType, filter)) {
            return self.returnBasedOnThis(BaseType, whereIt(BaseType, ItType, filter));
        }

        fn add(a: BaseType, b: BaseType) BaseType {
            return a + b;
        }

        pub fn sum(self: *Self) ?BaseType {
            return self.aggregate(add);
        }

        fn compare(self: *Self, comptime comparer: fn (BaseType, BaseType) i32, comptime result: i32) ?BaseType {
            var maxValue: ?BaseType = null;
            self.reset();
            defer self.reset();

            while (self.next()) |nxt| {
                if (maxValue == null or comparer(nxt, maxValue) == result) {
                    maxValue = nxt;
                }
            }
            return maxValue;
        }

        pub fn max(self: *Self, comptime comparer: fn (BaseType, BaseType) i32) ?BaseType {
            return self.compare(comparer, 1);
        }

        pub fn min(self: *Self, comptime comparer: fn (BaseType, BaseType) i32) ?BaseType {
            return self.compare(comparer, -1);
        }

        pub fn reverse(self: *Self, buf: []BaseType) iterator(BaseType, reverseIt(BaseType, ItType)) {
            return iterator(BaseType, reverseIt(BaseType, ItType)){
                .nextIt = reverseIt(BaseType, ItType){
                    .nextIt = &self.nextIt,
                    .index = 0,
                    .count = 0,
                    .buf = buf,
                },
            };
        }

        pub fn orderByDescending(self: *Self, comptime NewType: type, comptime selectObj: fn (BaseType) NewType, buf: []BaseType) iterator(NewType, orderIt(BaseType, NewType, ItType, false, selectObj)) {
            return iterator(NewType, orderIt(BaseType, NewType, ItType, false, selectObj)){
                .nextIt = orderIt(BaseType, NewType, ItType, false, selectObj){
                    .nextIt = &self.nextIt,
                    .index = 0,
                    .count = 0,
                    .buf = buf,
                },
            };
        }

        pub fn orderByAscending(self: *Self, comptime NewType: type, comptime selectObj: fn (BaseType) NewType, buf: []BaseType) iterator(NewType, orderIt(BaseType, NewType, ItType, true, selectObj)) {
            return iterator(NewType, orderIt(BaseType, NewType, ItType, true, selectObj)){
                .nextIt = orderIt(BaseType, NewType, ItType, true, selectObj){
                    .nextIt = &self.nextIt,
                    .index = 0,
                    .count = 0,
                    .buf = buf,
                },
            };
        }

        fn performTransform(self: *Self, comptime func: fn (BaseType, BaseType) BaseType, comptime avg: bool) ?BaseType {
            var agg: ?BaseType = null;
            self.reset();
            defer self.reset();
            var cnt: usize = 0;

            while (self.next()) |nxt| {
                cnt += 1;
                if (agg == null) {
                    agg = nxt;
                } else {
                    agg = func(agg, nxt);
                }
            }

            if (agg and avg) |some_agg| {
                return some_agg / cnt;
            } else {
                return agg;
            }
        }

        pub fn average(_: *Self, comptime func: fn (BaseType, BaseType) BaseType) ?BaseType {
            return performTransform(func, true);
        }

        pub fn aggregate(_: *Self, comptime func: fn (BaseType, BaseType) BaseType) ?BaseType {
            return performTransform(func, false);
        }

        // Select many currently only supports arrays
        pub fn selectMany(self: *Self, comptime NewType: type, comptime filter: fn (BaseType) []const NewType) iterator(NewType, selectManyIt(BaseType, NewType, ItType, filter)) {
            return iterator(NewType, selectManyIt(BaseType, NewType, ItType, filter)){
                .nextIt = selectManyIt(BaseType, NewType, ItType, filter){
                    .nextIt = &self.nextIt,
                    .currentIt = null,
                },
            };
        }

        // Currently requires you to give a new type, since can't have 'var' return type.
        pub fn select(self: *Self, comptime NewType: type, comptime filter: fn (BaseType) NewType) iterator(NewType, selectIt(BaseType, NewType, ItType, filter)) {
            return self.returnBasedOnThis(NewType, selectIt(BaseType, NewType, ItType, filter));
        }

        pub fn cast(self: *Self, comptime NewType: type) iterator(NewType, castIt(BaseType, NewType, ItType)) {
            return self.returnBasedOnThis(NewType, castIt(BaseType, NewType, ItType));
        }

        pub fn all(self: *Self, comptime condition: fn (BaseType) bool) bool {
            self.reset();
            defer self.reset();
            while (self.next()) |nxt| {
                if (!condition(nxt)) {
                    return false;
                }
            }
            return true;
        }

        pub fn any(self: *Self, comptime condition: fn (BaseType) bool) bool {
            self.reset();
            defer self.reset();
            while (self.next()) |nxt| {
                if (condition(nxt)) {
                    return true;
                }
            }
            return false;
        }

        pub fn contains(self: *Self, value: BaseType) bool {
            self.reset();
            defer self.reset();
            while (self.next()) |nxt| {
                if (nxt == value) {
                    return true;
                }
            }
            return false;
        }

        pub fn take(self: *Self, comptime amount: usize) iterator(BaseType, takeIt(BaseType, amount)) {
            return self.returnBasedOnThis(BaseType, takeIt(BaseType, amount));
        }

        pub fn takeWhile(self: *Self, comptime condition: fn (BaseType) bool) iterator(BaseType, takeWhileIt(BaseType, condition)) {
            return self.returnBasedOnThis(BaseType, takeWhileIt(BaseType, condition));
        }

        pub fn skip(self: *Self, comptime amount: usize) iterator(BaseType, skipIt(BaseType, amount)) {
            return self.returnBasedOnThis(BaseType, skipIt(BaseType, amount));
        }

        pub fn skipWhile(self: *Self, comptime condition: fn (BaseType) bool) iterator(BaseType, skipWhileIt(BaseType, condition)) {
            return self.returnBasedOnThis(BaseType, skipWhileIt(BaseType, condition));
        }

        pub fn concat(self: *Self, other: *Self) iterator(BaseType, concatIt(BaseType, ItType)) {
            return iterator(BaseType, concatIt(BaseType, ItType)){
                .nextIt = concatIt(BaseType, ItType){
                    .nextIt = &self.nextIt,
                    .otherIt = &other.nextIt,
                },
            };
        }

        pub fn toArray(self: *Self, buffer: []BaseType) []BaseType {
            self.reset();
            defer self.reset();
            var c: usize = 0;
            while (self.next()) |nxt| {
                buffer[c] = nxt;
                c += 1;
            }
            return buffer[0..c];
        }

        pub fn toList(self: *Self, allocator: std.mem.Allocator) !std.ArrayList(BaseType) {
            self.reset();
            defer self.reset();
            var list = std.ArrayList(BaseType).init(allocator);
            while (self.next()) |nxt| {
                try list.append(nxt);
            }
            return list;
        }
    };
}
