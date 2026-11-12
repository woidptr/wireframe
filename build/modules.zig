const std = @import("std");
const target_cfg = @import("target.zig");

const Arch = target_cfg.Arch;
const BootLoader = target_cfg.BootLoader;

pub const Ctx = struct {
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,

    pub fn mod(self: Ctx, path: []const u8) *std.Build.Module {
        return self.b.createModule(.{
            .root_source_file = self.b.path(path),
            .target = self.target,
            .optimize = self.optimize,
            .code_model = .kernel,
            .red_zone = false,
            .omit_frame_pointer = false,
            .single_threaded = true,
            .stack_check = false,
            .stack_protector = false,
            .pic = false,
            .strip = false,
        });
    }
};

pub const Graph = struct {
    boot: *std.Build.Module,
    kernel: *std.Build.Module,
    arch: *std.Build.Module,
    boot_info: *std.Build.Module,
};

pub fn graph(ctx: Ctx, arch: Arch, boot: BootLoader) Graph {
    const boot_info = ctx.mod("src/boot/info.zig");
    const arch_mod = ctx.mod(target_cfg.archRoot(arch));
    const kernel = ctx.mod("src/kernel/main.zig");
    const boot_mod = ctx.mod(target_cfg.entryRoot(boot));

    kernel.addImport("arch", arch_mod);
    kernel.addImport("boot_info", boot_info);

    boot_mod.addImport("kernel", kernel);
    boot_mod.addImport("arch", arch_mod);
    boot_mod.addImport("boot_info", boot_info);

    switch (boot) {
        .limine => boot_mod.addImport("limine", ctx.mod("vendors/limine/limine.zig")),
    }

    return .{ .boot = boot_mod, .kernel = kernel, .arch = arch_mod, .boot_info = boot_info };
}
