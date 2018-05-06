const std = @import("std");
const TypeId = @import("builtin").TypeId;
const whereIt = @import("where.zig").iterator;
const selectIt = @import("select.zig").iterator;
const castIt = @import("cast.zig").iterator;
const orderIt = @import("order.zig").iterator;
const thenByIt = @import("thenBy.zig").iterator;

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

        pub fn count(self: &Self) i32 {
            return self.nextIt.count();
        }

        fn returnBasedOnThis(self: &Self, comptime TypeA: type, comptime TypeB: type) iterator(TypeA, TypeB) {
            return iterator(TypeA, TypeB) {
                .nextIt = TypeB {
                    .nextIt = &self.nextIt,
                },
            };
        }

        pub fn where(self: &Self, comptime filter: fn (BaseType) bool) iterator(BaseType, whereIt(BaseType, ItType, filter)) {
            return self.returnBasedOnThis(BaseType, whereIt(BaseType, ItType, filter));
        }

        fn add(a: BaseType, b: BaseType) BaseType {
            return a + b;
        }

        pub fn sum(self: &Self) ?BaseType {
            return self.aggregate(add);
        }

        fn compare(self: &Self, comptime comparer: fn(BaseType, BaseType) i32, comptime result: i32) ?BaseType {
            var maxValue : ?BaseType = null;
            self.reset();
            defer self.reset();

            while (self.next()) |nxt| {
                if (maxValue == null or comparer(nxt, maxValue) == result) {
                    maxValue = nxt;
                }
            }
            return maxValue;
        }

        pub fn max(self: &Self, comptime comparer: fn(BaseType, BaseType) i32) ?BaseType {
            return self.compare(comparer, 1);
        }

        pub fn min(self: &Self, comptime comparer: fn(BaseType, BaseType) i32) ?BaseType {
            return self.compare(comparer, -1);
        }

        pub fn reverse(self: &Self, buf: []BaseType) iterator(Type, reverseIt(BaseType, buf)) {
            return self.returnBasedOnThis(BaseType, reverseIt(BaseType, buf));
        }

        pub fn thenByDescending(self: &Self, comptime NewType: type, comptime comparerObject: fn(BaseType) NewType, buf: []BaseType) iterator(NewType, thenByIt(BaseType, NewType, false, comparerObject, buf)) {
            return self.returnBasedOnThis(BaseType, thenByIt(BaseType, NewType, false, comparerObject, buf));
        }

        pub fn thenByAscending(self: &Self, comptime NewType: type, comptime comparerObject: fn(BaseType) NewType, buf: []BaseType) iterator(NewType, thenByIt(BaseType, NewType, true, comparerObject, buf)) {
            return self.returnBasedOnThis(BaseType, thenByIt(BaseType, NewType, true, comparerObject, buf));
        }

        pub fn orderByDescending(self: &Self, comptime NewType: type, comptime comparerObject: fn(BaseType) NewType, buf: []BaseType) iterator(NewType, orderIt(BaseType, NewType, false, comparerObject, buf)) {
            return self.returnBasedOnThis(BaseType, orderIt(BaseType, NewType, false, comparerObject, buf));
        }

        pub fn orderByAscending(self: &Self, comptime NewType: type, comptime comparerObject: fn(BaseType) NewType, buf: []BaseType) iterator(NewType, orderIt(BaseType, NewType, true, comparerObject, buf)) {
            return self.returnBasedOnThis(BaseType, orderIt(BaseType, NewType, true, comparerObject, buf));
        }

        fn performTransform(self: &Self, comptime func: fn(BaseType, BaseType) BaseType, comptime average: bool) ?BaseType {
            var aggregate: ?BaseType = null;
            self.reset();
            defer self.reset();
            var cnt: usize = 0;

            while (self.next()) |nxt| {
                cnt += 1;
                if (aggregate == null) {
                    aggregate = nxt;
                } else {
                    aggregate = func(aggregate, nxt);
                }
            }
            
            if (aggregate and average) |agg| {
                return agg/cnt;
            } else {
                return aggregate;
            }
        }

        pub fn average(self: &Self, comptime func: fn(BaseType, BaseType) BaseType) ?BaseType {
            return performTransform(func, true);
        }

        pub fn aggregate(self: &Self, comptime func: fn(BaseType, BaseType) BaseType) ?BaseType {
            return performTransform(func, false);
        }

        // SelectMany?

        // Currently requires you to give a new type, since can't have 'var' return type.
        pub fn select(self: &Self, comptime NewType: type, comptime filter: fn(BaseType) NewType) iterator(NewType, selectIt(BaseType, NewType, ItType, filter)) {
            return self.returnBasedOnThis(NewType, selectIt(BaseType, NewType, ItType, filter));
        }

        pub fn cast(self: &Self, comptime NewType: type) iterator(NewType, castIt(BaseType, NewType, ItType)) {
            return self.returnBasedOnThis(NewType, castIt(BaseType, NewType, ItType));
        }

        pub fn all(self: &Self, comptime condition: fn(BaseType) bool) bool {
            self.reset();
            defer self.reset();
            while (self.next()) |nxt| {
                if (!condition(nxt)) {
                    return false;
                }
            }
            return true;
        }

        pub fn any(self: &Self, comptime condition: fn(BaseType) bool) bool {
            self.reset();
            defer self.reset();
            while (self.next()) |nxt| {
                if (condition(nxt)) {
                    return true;
                }
            }
            return false;
        }

        pub fn contains(self: &Self, value: BaseType) bool {
            self.reset();
            defer self.reset();
            while (self.next()) |nxt| {
                if (nxt == value) {
                    return true;
                }
            }
            return false;
        }

        pub fn toArray(self: &Self, buffer: []BaseType) []BaseType {
            self.reset();
            defer self.reset();
            var c: usize = 0;
            while (self.next()) |nxt| {
                buffer[c] = nxt;
                c += 1;
            }
            return buffer[0..c];
        }

        pub fn toList(self: &Self, allocator: &std.mem.Allocator) std.ArrayList(BaseType) {
            self.reset();
            defer self.reset();
            var list = std.ArrayList(BaseType).init(allocator);
            while (self.next()) |nxt| {
                list.append(nxt);
            }
            return list;
        }
    };
}