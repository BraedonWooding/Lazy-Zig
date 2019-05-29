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

pub fn hasIteratorMember(comptime objType: type) bool {
    comptime {
        if (@typeId(objType) != TypeId.Struct) {
            return false;
        }

        const count = @memberCount(objType);
        var i = 0;

        inline while (i < count) : (i += 1) {
            if (mem.eql(u8, @memberName(objType, i), "iterator")) {
                return true;
            }
        }

        return false;
    }
}

pub fn getType(comptime objType: type) type {
    comptime {
        switch (@typeInfo(objType)) {
            TypeId.Pointer => |pointer| {
                switch (pointer.size) {
                    .One, .Many, .C => {
                        return pointer.child;
                    },
                    .Slice => {
                        const BaseType = pointer.child;
                        return iterator(BaseType, arrayIt(BaseType));
                    },
                }
            },
            TypeId.Struct => |structInfo| {
                if (!hasIteratorMember(objType)) {
                    @compileError("No 'iterator' or 'Child' property found");
                }
                const it_type = @typeOf(objType.iterator);
                const return_type = it_type.next.ReturnType;
                return findTillNoChild(return_type);
            },
            else => {
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
    switch (@typeInfo(objType)) {
        TypeId.Pointer => |pointer| {
            switch (pointer.size) {
                .Slice => {
                    return it_type{ .nextIt = arrayIt(pointer.child).init(value) };
                },
                else => unreachable,
            }
        },
        TypeId.Struct => {
            if (comptime !hasIteratorMember(objType)) {
                unreachable;
            }
            return it_type{ .nextIt = value.iterator() };
        },
        else => unreachable,
    }
}
