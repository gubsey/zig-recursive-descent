const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    while (true) {
        const i = try std.io.getStdIn().reader().readUntilDelimiterAlloc(alloc, '\n', 1024);
        if (try integer(i, alloc)) |n| {
            std.debug.print("{}\n", .{n.val});
        } else {
            std.debug.print("fuck you\n", .{});
        }
    }
}

fn Sym(comptime T: type) type {
    return struct {
        str: []const u8,
        val: T,
    };
}

fn accept(s: []const u8, a: u8) !?Sym(u8) {
    errdefer std.debug.print("{} does not match {}", .{ s, a });
    if (s[0] == a) {
        return .{
            .str = s[1..],
            .val = a,
        };
    }
    return null;
}

fn digit(s: []const u8) !?Sym(u8) {
    errdefer std.debug.print("{} does not start with a digit", .{s});
    if (std.ascii.isDigit(s[0])) {
        return .{ .str = s[1..], .val = s[0] };
    }
    return null;
}

fn is_of(s: []const u8, arr: []u8) !?Sym(u8) {
    for (arr) |a| {
        if (s[0] == a) {
            return .{ .str = s[1..], .val = a };
        }
    }
    return null;
}

fn many(s: []const u8, comptime T: type, comptime f: fn ([]const u8) anyerror!?Sym(T), alloc: std.mem.Allocator) !?Sym([]T) {
    var al = std.ArrayList(T).init(alloc);
    var ns = s;
    while (ns.len > 0) {
        if (try f(ns)) |o| {
            ns = o.str;
            try al.append(o.val);
        } else {
            break;
        }
    }
    return .{ .str = ns, .val = try al.toOwnedSlice() };
}

fn many1(s: []const u8, comptime T: type, comptime f: fn ([]const u8) anyerror!?Sym(T), alloc: std.mem.Allocator) !?Sym([]T) {
    const o = try many(s, T, f, alloc) orelse return null;
    if (o.val.len == 0) {
        alloc.free(o.val);
        return null;
    }
    return o;
}

fn integer(s: []const u8, alloc: std.mem.Allocator) !?Sym(u32) {
    const o = try many1(s, u8, digit, alloc) orelse return null;
    defer alloc.free(o.val);
    const v = std.fmt.parseInt(u32, s[0..o.val.len], 10) catch return null;
    return .{ .str = o.str, .val = v };
}

test "integer" {
    const s = "123h7";
    const i = try integer(s, std.testing.allocator);
    try std.testing.expectEqual(i.?.val, 123);
    try std.testing.expectEqualStrings(i.?.str, "h7");
}
