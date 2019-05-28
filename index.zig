const std = @import("std");
const arrayIt = @import("src/arrayIterator.zig").iterator;
const iterator = @import("src/iterator.zig").iterator;
const enumerateIt = @import("src/enumerate.zig").iterator;
const TypeId = @import("builtin").TypeId;
const mem = std.mem;
const info = @import("src/info.zig");

pub fn init(obj: var) info.getType(@typeOf(obj)) {
    return info.initType(@typeOf(obj), obj);
}

pub fn range(start: var, stop: @typeOf(start), step: @typeOf(start)) iterator(@typeOf(start), enumerateIt(@typeOf(start))) {
    return iterator(@typeOf(start), enumerateIt(@typeOf(start))){ .nextIt = enumerateIt(@typeOf(start)).init(start, stop, step) };
}

test "Basic Lazy" {
    var obj = []i32{ 0, 1, 2 };
    const result = []i32{ 0, 2 };
    var buf: [2]i32 = undefined;
    std.debug.assert(std.mem.eql(i32, init(obj[0..]).where(even).toArray(buf[0..]), result[0..]));
    // Longer format
    var it = init(obj[0..]).where(even);
    var i: usize = 0;
    while (it.next()) |nxt| {
        std.debug.assert(nxt == result[i]);
        i += 1;
    }
    std.debug.assert(i == 2);
    std.debug.assert(it.contains(2));
    std.debug.assert(??it.next() == 0);

    var stringBuf: [3]u8 = undefined;
    std.debug.assert(std.mem.eql(u8, init(obj[0..]).select(u8, toDigitChar).toArray(stringBuf[0..]), "012"));
}

fn pow(val: i32) i32 {
    return val * val;
}

test "Readme-Tests" {
    const warn = std.debug.warn;
    const assert = std.debug.assert;

    var it = range(i32(0), 100, 1);
    var whereIt = it.where(even);
    var selectIt = whereIt.select(i32, pow);

    var outBuf: [100]i32 = undefined;
    _ = range(i32(0), 100, 2).toArray(outBuf[0..]);
    var i: usize = 0;
    if (selectIt.next()) |next| {
        assert(next == pow(outBuf[i]));
        i += 1;
    }
    while (selectIt.next()) |next| {
        assert(next == pow(outBuf[i]));
        i += 1;
    }

    selectIt.reset();
    var buf: [100]i32 = undefined;
    var array = selectIt.toArray(buf[0..]);
    i = 0;
    while (i < array.len) : (i += 1) {
        assert(array[i] == pow(outBuf[i]));
    }
}

test "Basic Concat" {
    var obj1 = []i32{
        0,
        1,
        2,
    };
    var obj2 = []i32{
        3,
        4,
        5,
        6,
    };
    var i: i32 = 0;
    var it = init(obj1[0..]).concat(&init(obj2[0..]));
    while (it.next()) |next| {
        std.debug.assert(next == i);
        i += 1;
    }
}

test "Basic Cast" {
    var obj = []i32{ 0, 1, 2 };
    const result = []u8{ 0, 1, 2 };
    var buf: [3]u8 = undefined;
    std.debug.assert(std.mem.eql(u8, init(obj[0..]).cast(u8).toArray(buf[0..]), result[0..]));
}

fn selectManyTest(arr: []const i32) []const i32 {
    return arr;
}

test "Select Many" {
    var obj = [][]const i32{ ([]i32{ 0, 1 })[0..], ([]i32{ 2, 3 })[0..], ([]i32{ 4, 5 })[0..] };
    var i: i32 = 0;
    var it = init(obj[0..]).selectMany(i32, selectManyTest);
    while (it.next()) |next| {
        std.debug.assert(i == next);
        i += 1;
    }
}

test "Reverse" {
    var buf: [100]i32 = undefined;
    var obj = []i32{ 9, 4, 54, 23, 1 };
    var result = []i32{ 1, 23, 54, 4, 9 };
    std.debug.assert(std.mem.eql(i32, init(obj[0..]).reverse(buf[0..]).toArray(buf[25..]), result[0..]));
}

test "Sorting" {
    var buf: [100]i32 = undefined;
    var obj = []i32{ 9, 4, 54, 23, 1 };
    var result = []i32{ 1, 4, 9, 23, 54 };
    std.debug.assert(std.mem.eql(i32, init(obj[0..]).orderByAscending(i32, orderBySimple, buf[0..]).toArray(buf[25..]), result[0..]));
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

fn orderBySimple(a: i32) i32 {
    return a;
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

fn toDigitChar(val: i32) u8 {
    return @intCast(u8, val) + '0';
}

fn even(val: i32) bool {
    return @rem(val, 2) == 0;
}
