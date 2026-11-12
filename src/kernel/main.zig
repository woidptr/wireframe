const std = @import("std");
const arch = @import("arch");
const BootInfo = @import("boot_info").BootInfo;

pub fn main(info: *const BootInfo) noreturn {
    if (info.framebuffer) |fb| {
        var i: u64 = 0;
        while (i < @min(fb.width, fb.height)) : (i += 1) {
            const px: *volatile u32 = @ptrCast(@alignCast(fb.address + i * fb.pitch + i * 4));
            px.* = 0xffffff;
        }
    }

    arch.halt();
}
