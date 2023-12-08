const std = @import("std");
const arrayIt = @import("arrayIterator.zig").iterator;
const iterator = @import("iterator.zig").iterator;

pub fn getType(comptime objType: type) type {
    comptime {
        switch (@typeInfo(objType)) {
            .Pointer => |pointer| {
                const BaseType = blk: {
                    switch (pointer.size) {
                        .One, .Many, .C => {
                            break :blk @typeInfo(pointer.child).Array.child;
                        },
                        .Slice => {
                            break :blk pointer.child;
                        },
                    }
                };
                return iterator(BaseType, arrayIt(BaseType));
            },
            .Struct => {
                if (!hasIteratorMember(objType)) {
                    @compileError("No 'iterator' or 'Child' property found");
                }
                const it_type = @TypeOf(objType.iterator);
                const return_type = @typeInfo(@TypeOf(@typeInfo(it_type).Fn.return_type.?.next)).Fn.return_type.?;

                return iterator(findTillNoChild(return_type), it_type);
            },
            else => {
                @compileError("Can only use slices and structs have 'iterator' function, remember to convert arrays to slices.");
            },
        }
        @compileError("No 'iterator' or 'Child' property found");
    }
}

pub fn initType(comptime objType: type, value: anytype) getType(objType) {
    const it_type = getType(objType);
    switch (@typeInfo(objType)) {
        .Pointer => |pointer| {
            const child = blk: {
                switch (pointer.size) {
                    .One, .Many, .C => {
                        break :blk @typeInfo(pointer.child).Array.child;
                    },
                    .Slice => {
                        break :blk pointer.child;
                    },
                }
            };
            return it_type{ .nextIt = arrayIt(child).init(value) };
        },
        .Struct => {
            if (comptime !hasIteratorMember(objType)) {
                unreachable;
            }
            return it_type{ .nextIt = value.iterator() };
        },
        else => unreachable,
    }
}

fn findTillNoChild(comptime Type: type) type {
    if (@typeInfo(Type) == .Optional) {
        return findTillNoChild(@typeInfo(Type).Optional.child);
    }
    return Type;
}

fn hasIteratorMember(comptime objType: type) bool {
    comptime {
        if (@typeInfo(objType) != .Struct) {
            return false;
        }

        inline for (@typeInfo(objType).Struct.decls) |f| {
            if (std.mem.eql(u8, f.name, "iterator")) {
                return true;
            }
        }

        return false;
    }
}
