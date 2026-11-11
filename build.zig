const std = @import("std");
const target_cfg = @import("build/target.zig");
const linker = @import("build/linker.zig");
const modules = @import("build/modules.zig");

const Ctx = modules.Ctx;

pub fn build(b: *std.Build) void {
    const arch = b.option(target_cfg.Arch, "arch", "Target architecture") orelse .x86_64;
    const bootloader = b.option(target_cfg.BootLoader, "bootloader", "Boot protocol") orelse .limine;

    const target = b.resolveTargetQuery(target_cfg.query(arch));
    const optimize = b.standardOptimizeOption(.{});

    const ctx: Ctx = .{ .b = b, .target = target, .optimize = optimize };

    const boot_mod = ctx.mod(target_cfg.entryRoot(bootloader));
    const arch_mod = ctx.mod(target_cfg.archRoot(arch));

    const limine_mod = ctx.mod("vendors/limine/limine.zig");
    boot_mod.addImport("limine", limine_mod);

    const kernel = b.addExecutable(.{
        .name = "wireframe",
        .root_module = boot_mod,
    });

    kernel.setLinkerScript(linker.generate(b, arch, bootloader));
    kernel.entry = .{ .symbol_name = "_start" };
    kernel.pie = false;
    kernel.use_llvm = true;

    b.installArtifact(kernel);

    const esp = b.addWriteFiles();
    _ = esp.addCopyFile(b.dependency("limine_bin", .{}).path("BOOTX64.EFI"), "EFI/BOOT/BOOTX64.EFI");
    _ = esp.addCopyFile(kernel.getEmittedBin(), "boot/wireframe");
    _ = esp.add("boot/limine/limine.conf",
        \\timeout: 0
        \\
        \\/Wireframe
        \\    protocol: limine
        \\    path: boot():/boot/wireframe
        \\
    );

    const qemu = b.addSystemCommand(&.{
        "qemu-system-x86_64",                                                                 "-M",           "q35",     "-m",    "256M",
        "-no-reboot",                                                                         "-no-shutdown", "-serial", "stdio", "-drive",
        "if=pflash,format=raw,readonly=on,file=/opt/homebrew/share/qemu/edk2-x86_64-code.fd", "-drive",
    });

    qemu.addPrefixedDirectoryArg("if=virtio,format=raw,readonly=on,file=fat:", esp.getDirectory());
    if (b.args) |args| qemu.addArgs(args);

    b.step("run", "Boot the kernel in QEMU via Limine").dependOn(&qemu.step);
}
