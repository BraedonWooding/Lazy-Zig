const std = @import("std");
const arrayIt = @import("arrayIterator.zig").iterator;
const iterator = @import("iterator.zig").iterator;
const enumerateIt = @import("enumerate.zig").iterator;
const TypeId = @import("builtin").TypeId;
const mem = std.mem;

const Info = enum {
    Slice,
    Iterator,
    Other,
};

pub fn getInfo(comptime objType: type) Info {
    comptime {
        if (@typeId(objType) == TypeId.Slice) {
            return Info.Slice;
        }

        if (@typeId(objType) != TypeId.Struct) {
            return Info.Other;
        }

        const count = @memberCount(objType);
        var i = 0;

        inline while (i < count) : (i += 1) {
            if (mem.eql(u8, @memberName(objType, i), "iterator")) {
                return Info.Iterator;
            }
        }

        return Info.Other;
    }
}

pub fn getType(comptime objType: type) type {
    comptime {
        if (@typeId(objType) == TypeId.Pointer) {
            return getType(objType.Child);
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
            },
            Info.Other => {
                @compileError("Can only use slices and structs have 'iterator' function, remember to convert arrays to slices.");
            },
        }

        @compileError("No 'iterator' or 'Child' property found");
    }
}

pub fn findTillNoChild(comptime Type: type) type {
    if (@typeId(Type) == TypeId.Nullable) {
        return findTillNoChild(Type.Child);
    }
    return Type;
}

pub fn initType(comptime objType: type, value: var) getType(objType) {
    comptime const it_type = getType(objType);
    switch (comptime getInfo(objType)) {
        Info.Slice => {
            return it_type{ .nextIt = arrayIt(objType.Child).init(value) };
        },
        Info.Iterator => {
            return it_type{ .nextIt = value.iterator() };
        },
        else => {
            unreachable;
        },
    }
}
