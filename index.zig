const std = @import("std");
const iterator = @import("src/iterator.zig").iterator;
const enumerateIt = @import("src/enumerate.zig").iterator;
const info = @import("src/info.zig");

pub fn init(obj: anytype) info.getType(@TypeOf(obj)) {
    return info.initType(@TypeOf(obj), obj);
}

pub fn range(start: anytype, stop: @TypeOf(start), step: @TypeOf(start)) iterator(@TypeOf(start), enumerateIt(@TypeOf(start))) {
    return iterator(@TypeOf(start), enumerateIt(@TypeOf(start))){ .nextIt = enumerateIt(@TypeOf(start)).init(start, stop, step) };
}

test "Basic Lazy" {
    const obj = [_]i32{ 0, 1, 2 };
    const result = [_]i32{ 0, 2 };

    var buf: [2]i32 = undefined;
    var it = blk: {
        var a = init(obj[0..]);
        break :blk a.where(even);
    };
    try std.testing.expect(std.mem.eql(i32, it.toArray(buf[0..]), result[0..]));
    // Longer format
    var i: usize = 0;
    while (it.next()) |nxt| {
        try std.testing.expect(nxt == result[i]);
        i += 1;
    }
    try std.testing.expect(i == 2);
    try std.testing.expect(it.contains(2));
    try std.testing.expect(it.next().? == 0);

    const stringResult = "012";

    var stringBuf: [3]u8 = undefined;
    const stringSlice = blk: {
        var a = init(obj[0..]);
        var b = a.select(u8, toDigitChar);
        break :blk b.toArray(stringBuf[0..]);
    };
    try std.testing.expect(std.mem.eql(u8, stringSlice, stringResult));
    try std.testing.expect(std.mem.eql(u8, &stringBuf, stringResult));
}

test "Readme-Tests" {
    var it = range(@as(i32, 0), 100, 1);
    var whereIt = it.where(even);
    var selectIt = whereIt.select(i32, pow);

    var outBuf: [100]i32 = undefined;
    _ = blk: {
        var a = range(@as(i32, 0), 100, 2);
        break :blk a.toArray(outBuf[0..]);
    };
    var i: usize = 0;
    if (selectIt.next()) |next| {
        try std.testing.expect(next == pow(outBuf[i]));
        i += 1;
    }
    while (selectIt.next()) |next| {
        try std.testing.expect(next == pow(outBuf[i]));
        i += 1;
    }

    selectIt.reset();
    var buf: [100]i32 = undefined;
    var array = selectIt.toArray(buf[0..]);
    i = 0;
    while (i < array.len) : (i += 1) {
        try std.testing.expect(array[i] == pow(outBuf[i]));
    }
}

test "Basic Concat" {
    var obj1 = [_]i32{
        0,
        1,
        2,
    };
    var obj2 = [_]i32{
        3,
        4,
        5,
        6,
    };
    var i: i32 = 0;
    var it = blk: {
        var a = init(obj1[0..]);
        var b = init(obj2[0..]);
        break :blk a.concat(&b);
    };
    while (it.next()) |next| {
        try std.testing.expect(next == i);
        i += 1;
    }
}

test "Basic Cast" {
    var obj = [_]i32{ 0, 1, 2 };
    const result = [_]u8{ 0, 1, 2 };
    var buf: [3]u8 = undefined;
    const it = blk: {
        var a = init(obj[0..]);
        var b = a.cast(u8);
        break :blk b.toArray(buf[0..]);
    };
    try std.testing.expect(std.mem.eql(u8, it, result[0..]));
}

test "Select Many" {
    var obj = [_][]const i32{ ([_]i32{ 0, 1 })[0..], ([_]i32{ 2, 3 })[0..], ([_]i32{ 4, 5 })[0..] };
    var i: i32 = 0;
    var it = blk: {
        var a = init(obj[0..]);
        break :blk a.selectMany(i32, selectManyTest);
    };
    while (it.next()) |next| {
        try std.testing.expect(i == next);
        i += 1;
    }
}

test "Reverse" {
    var buf: [100]i32 = undefined;
    var obj = [_]i32{ 9, 4, 54, 23, 1 };
    var result = [_]i32{ 1, 23, 54, 4, 9 };
    const it = blk: {
        var a = init(obj[0..]);
        var b = a.reverse(buf[0..]);
        break :blk b.toArray(buf[25..]);
    };
    try std.testing.expect(std.mem.eql(i32, it, result[0..]));
}

test "Sorting" {
    var buf: [100]i32 = undefined;
    var obj = [_]i32{ 9, 4, 54, 23, 1 };
    var result = [_]i32{ 1, 4, 9, 23, 54 };
    const it = blk: {
        var a = init(obj[0..]);
        var b = a.orderByAscending(i32, orderBySimple, buf[0..]);
        break :blk b.toArray(buf[25..]);
    };
    try std.testing.expect(std.mem.eql(i32, it, result[0..]));
}

test "Basic Lazy_List" {
    const allocator = std.testing.allocator;

    var list = std.ArrayList(i32).init(allocator);
    defer list.deinit();

    try list.append(1);
    try list.append(2);
    try list.append(3);

    const result = [_]i32{2};
    var buf: [1]i32 = undefined;
    const it = blk: {
        var a = init(list.items);
        var b = a.where(even);
        break :blk b.toArray(buf[0..]);
    };
    try std.testing.expect(std.mem.eql(i32, it, result[0..]));
}

fn even(val: i32) bool {
    return @rem(val, 2) == 0;
}

fn orderByEven(val: i32, other: i32) bool {
    const evenVal = @rem(val, 2) == 0;
    const evenOther = @rem(val, 2) == 0;
    if (evenVal) {
        if (!evenOther) return true;
        return val < other;
    } else {
        if (evenOther) return false;
        return val < other;
    }
}

fn orderBySimple(a: i32) i32 {
    return a;
}

fn pow(val: i32) i32 {
    return val * val;
}

fn selectManyTest(arr: []const i32) []const i32 {
    return arr;
}

fn toDigitChar(val: i32) u8 {
    return @intCast(u8, val) + '0';
}
