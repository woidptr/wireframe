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
    root: *std.Build.Module,
    boot: *std.Build.Module,
    kernel: *std.Build.Module,
    arch: *std.Build.Module,
    boot_info: *std.Build.Module,
    lib: *std.Build.Module,
};
