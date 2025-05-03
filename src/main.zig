const std = @import("std");
const assert = std.debug.assert;

const Coord = struct { x: i32, y: i32 };
const Vec = struct { re: f32, im: f32 };

// Options
const dim: Coord = .{ .x = 3840, .y = 2400 };
const offset: Vec = .{ .re = -0.5, .im = 0 };
const max_iter: u32 = 1024;
const zoom: f32 = 1.0;

pub export fn _start() callconv(.c) noreturn {

    // Output File
    const flags: u32 = 0b0000_0010_0100_0001;
    const raw_fd = std.os.linux.open("out.ppm", @bitCast(flags), 0o644);
    const fd: i32 = @bitCast(@as(u32, @intCast(raw_fd)));
    defer std.os.linux.close(fd);

    // NetPPM Header
    write(fd, std.fmt.comptimePrint("P6\n{} {}\n255\n", dim));

    // Per-Pixel Render
    for (0..dim.y) |y| {
        for (0..dim.x) |x| {
            const pos: Coord = .{ .x = @intCast(x), .y = @intCast(y) };
            const iter = mandelbrot(transform(pos));

            var color: [3]u8 = .{ 0, 0, 0 };

            if (max_iter - iter > 0) {
                color = @splat(@truncate(iter * 17));
            }

            write(fd, &color);
        }
    }

    std.os.linux.exit(0);
}

fn transform(pos: Coord) Vec {
    const centered_pos_x: f32 = @floatFromInt(pos.x - dim.x / 2);
    const centered_pos_y: f32 = @floatFromInt(pos.y - dim.y / 2);
    const normalizer: f32 = @floatFromInt(@max(dim.x / 2, dim.y / 2));
    const scale = (zoom * 2) / normalizer;
    return .{
        .re = (centered_pos_x * scale) + offset.re,
        .im = (centered_pos_y * scale) + offset.im,
    };
}

fn mandelbrot(c: Vec) u32 {
    var z: Vec = c;
    for (0..max_iter) |iter| {
        const z_re_2 = z.re * z.re;
        const z_im_2 = z.im * z.im;

        if (z_re_2 + z_im_2 > 8) return iter;

        const temp = z_re_2 - z_im_2 + c.re;
        z.im = 2 * z.re * z.im + c.im;
        z.re = temp;
    }
    return max_iter;
}

fn write(fd: i32, bytes: []const u8) void {
    const ptr = bytes.ptr;
    const len = bytes.len;
    assert(std.os.linux.write(fd, ptr, len) == len);
}
