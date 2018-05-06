const std = @import("std");
const arrayIt = @import("src/arrayIterator.zig").iterator;
const iterator = @import("src/iterator.zig").iterator;
const TypeId = @import("builtin").TypeId;
const mem = std.mem;

const Info = enum {
    Slice,
    Iterator,
};

fn getInfo(comptime objType: type) Info {
    comptime {
        const count = @memberCount(objType);
        var i = 0;

        inline while (i < count) : (i += 1) {
            if (mem.eql(u8, @memberName(objType, i), "iterator")) {
                return Info.Iterator;
            }
        }

        return Info.Slice;
    }
}

fn getType(comptime objType: type) type {
    comptime {
        if (@typeId(objType) == TypeId.Pointer) {
            return getType(objType.Child);
        }

        if (@typeId(objType) != TypeId.Struct) {
            @compileError("Can only use slices and structs have 'iterator' function, remember to convert arrays to slices.");
        }

        switch (getInfo(objType)) {
            Info.Slice => {
                const BaseType = objType.Child;
                return iterator(BaseType, arrayIt(BaseType));
            },
            Info.Iterator => {
                const it_type = @typeOf(objType.iterator);
                const return_type = it_type.next.ReturnType;
                return findTillNoChild(return_type);
            }
        }

        @compileError("No 'iterator' or 'Child' property found");
    }
}

fn findTillNoChild(comptime Type: type) type {
    if (@typeId(Type) == TypeId.Nullable) {
        return findTillNoChild(Type.Child);
    }
    return Type;
}

fn initType(comptime objType: type, value: var) getType(objType) {
    comptime const it_type = getType(objType);
    switch (comptime getInfo(objType)) {
        Info.Slice => {
            return it_type {
                .nextIt = arrayIt(objType.Child).init(value),
            };
        },
        Info.Iterator => {
            return it_type {
                .nextIt = value.iterator(),
            };
        },
        else => {
            unreachable;
        },
    }
}

pub fn init(obj: var) getType(@typeOf(obj)) {
    return initType(@typeOf(obj), obj);
}

test "Basic Lazy" {
    var obj = []i32 { 0, 1, 2 };
    const result = []i32 { 0, 2 };
    var buf: [2]i32 = undefined;
    std.debug.assert(std.mem.eql(i32, init(obj[0..]).where(even).toArray(buf[0..]), result[0..]));
    // Longer format
    var it = init(obj[0..]).where(even);
    var i : usize = 0;
    while (it.next()) |nxt| {
        std.debug.assert(nxt == result[i]);
        i += 1;
    }
    std.debug.assert(i == 2);
    std.debug.assert(it.contains(2));
    std.debug.assert(?? it.next() == 0);

    var stringBuf: [3]u8 = undefined;
    std.debug.assert(std.mem.eql(u8, init(obj[0..]).select(u8, toDigitChar).toArray(stringBuf[0..]), "012"));
}

test "Basic Cast" {
    var obj = []i32 { 0, 1, 2 };
    const result = []u8 { 0, 1, 2 };
    var buf: [3]u8 = undefined;
    std.debug.assert(std.mem.eql(u8, init(obj[0..]).cast(u8).toArray(buf[0..]), result[0..]));
}

test "Basic Lazy_List" {
    // var list = std.ArrayList(i32).init(std.debug.global_allocator);
    // defer list.deinit();

    // try list.append(1);
    // try list.append(2);
    // try list.append(3);

    // const result = []i32 { 2 };
    // const buf: [1]i32 = undefined;
    // std.debug.assert(std.mem.eql(i32, init(list).where(even).toArray(buf[0..]), result[0..]));
}

fn toDigitChar(val: i32) u8 {
    return u8(val) + '0';
}

fn even(val: i32) bool {
    return @rem(val, 2) == 0;
}