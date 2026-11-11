const std = @import("std");

pub const Arch = enum { x86_64 };
pub const BootLoader = enum { limine };

pub const Layout = struct {
    base: u64,
    page: u64,
    output_format: []const u8,
};

pub fn layout(arch: Arch) Layout {
    return switch (arch) {
        .x86_64 => .{
            .base = 0xffffffff80200000,
            .page = 0x1000,
            .output_format = "elf64-x86-64",
        },
    };
}

pub fn query(arch: Arch) std.Target.Query {
    return switch (arch) {
        .x86_64 => .{
            .cpu_arch = .x86_64,
            .os_tag = .freestanding,
            .abi = .none,
            .cpu_features_add = std.Target.x86.featureSet(&.{.soft_float}),
            .cpu_features_sub = std.Target.x86.featureSet(&.{
                .mmx, .sse, .sse2, .avx, .avx2, .avx512f,
            }),
        },
    };
}

pub fn archRoot(arch: Arch) []const u8 {
    return switch (arch) {
        .x86_64 => "x86_64",
    };
}

pub fn entryRoot(boot: BootLoader) []const u8 {
    return switch (boot) {
        .limine => "src/boot/limine/entry.zig",
    };
}
