const std = @import("std");
const assert = std.debug.assert;

// Options
const dim_x: i32 = 1920;
const dim_y: i32 = 1200;
const max_iter: u32 = 256;

pub export fn _start() callconv(.c) noreturn {
    // Output File
    const flags: u32 = 0b0000_0010_0100_0001;
    const raw_fd = std.os.linux.open("out.ppm", @bitCast(flags), 0o644);
    const fd: i32 = @bitCast(@as(u32, @intCast(raw_fd)));
    defer std.os.linux.close(fd);

    // NetPPM Header
    write(fd, std.fmt.comptimePrint("P5\n{} {}\n255\n", .{ dim_x, dim_y }));

    const dim_x_2 = dim_x / 2;
    const dim_y_2 = dim_y / 2;
    const norm: f32 = @floatFromInt(@max(dim_x_2, dim_y_2));

    // Per-Pixel Render
    for (0..dim_y) |y| {
        for (0..dim_x) |x| {
            const pos_x: i32 = @intCast(x);
            const pos_y: i32 = @intCast(y);

            const cpos_x: f32 = @floatFromInt(pos_x - dim_x_2);
            const cpos_y: f32 = @floatFromInt(pos_y - dim_y_2);
            const scale = 2.0 / norm;

            const c_re = (cpos_x * scale) - 0.5;
            const c_im = cpos_y * scale;

            var z_re: f32 = 0;
            var z_im: f32 = 0;

            var color: u8 = 0xFF;

            for (0..max_iter) |_| {
                const z_re_2 = z_re * z_re;
                const z_im_2 = z_im * z_im;
                if (z_re_2 + z_im_2 > 8) color = 0;
                const temp = z_re_2 - z_im_2 + c_re;
                z_im = 2 * z_re * z_im + c_im;
                z_re = temp;
            }

            write(fd, &.{color});
        }
    }

    std.os.linux.exit(0);
}

fn write(fd: i32, bytes: []const u8) void {
    const ptr = bytes.ptr;
    const len = bytes.len;
    assert(std.os.linux.write(fd, ptr, len) == len);
}
