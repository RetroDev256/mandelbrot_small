const std = @import("std");
const assert = std.debug.assert;

// Options
const dim_x: i32 = 7680;
const dim_y: i32 = 4800;

// NetPPM Header
const header = std.fmt.comptimePrint(
    "P5\n{} {}\n255\n",
    .{ dim_x, dim_y },
);

// Fixed point divisor
const dim_x_2 = dim_x / 2;
const dim_y_2 = dim_y / 2;
const norm: i32 = @max(dim_x_2, dim_y_2);
const scale = std.math.floorPowerOfTwo(i32, norm / 2);

// Loop bounds
const start_y = -dim_y_2;
const start_x = -dim_x_2 - scale / 2;
const end_y = start_y + dim_y;
const end_x = start_x + dim_x;

pub export fn _start() callconv(.c) noreturn {
    write(header.ptr, header.len);

    // Per-Pixel Render
    var c_im: i32 = start_y;
    while (c_im < end_y) : (c_im += 1) {
        var c_re: i32 = start_x;
        while (c_re < end_x) : (c_re += 1) {
            var z_re: i32 = c_re;
            var z_im: i32 = c_im;
            var pixel: u8 = 0xFF;

            while (pixel != 0) : (pixel -= 1) {
                const z_re_2 = @divTrunc(z_re * z_re, scale);
                const z_im_2 = @divTrunc(z_im * z_im, scale);
                if (z_re_2 + z_im_2 > 8 * scale) break;
                const temp = z_re_2 - z_im_2 + c_re;
                z_im = @divTrunc(2 * z_re * z_im, scale) + c_im;
                z_re = temp;
            }

            write(&.{pixel}, 1);
        }
    }

    @trap();
}

noinline fn write(ptr: [*]const u8, len: usize) void {
    assert(std.os.linux.write(1, ptr, len) == len);
}
