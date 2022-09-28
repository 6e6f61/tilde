const std = @import("std");
const expect = std.testing.expect;

/// Cross-platform "POSIX" tilde expansion. On Windows, $HOME is substituted for %USERPROFILE%.
/// Additionally on Windows, `out_buffer` is used to back a `FixedBufferAllocator` for the
/// WTF-16 => UTF-8 conversion, avoiding the heap.
///
/// If the supplied path does not contain a tilde, `out_buffer` will be `path` and no transformation
/// will be performed.
///
/// Paths like ~/.../ will retain their relativity; openDir can handle ..s, but not tildes.
pub fn expand(path: []const u8,
  out_buffer: *[std.fs.MAX_PATH_BYTES]u8) ![]u8
{
    if (path[0] != '~') {
        std.mem.copy(u8, out_buffer, path);
        return out_buffer[0..path.len];
    }

    const home_directory = switch (@import("builtin").os.tag) {
        .freebsd, .fuchsia, .linux, .kfreebsd, .macos, .netbsd, .openbsd, .solaris, .zos, .haiku,
        .minix, .tvos, .watchos, .hurd => std.os.getenv("HOME").?,
        .windows => blk: {
            var fba = std.heap.FixedBufferAllocator.init(out_buffer);
            var allocator = fba.allocator();
            break :blk try std.process.getEnvVarOwned(allocator, "userprofile");
        },
        else => @compileError("tilde: unsupported platform"),
    };

    std.mem.copy(u8, out_buffer, home_directory);

    for (path[1..path.len]) |char, i| {
        out_buffer[home_directory.len + i] = char;
    }

    return out_buffer[0..home_directory.len + path.len-1];
}

test "expands ~" {
    try expand_open("~");
}

test "expands ~/Code" {
    try expand_open("~/Code");
}

test "openDir can open ~/../" {
    try expand_open("~/../");
}

fn expand_open(path: []const u8) !void {
    var backing: [std.fs.MAX_PATH_BYTES]u8 = undefined;
    const expanded = try expand(path, &backing);
    std.debug.print("\nexpanded to: {s}\n", .{ expanded });
    _ = try std.fs.cwd().openDir(expanded, .{});
}
