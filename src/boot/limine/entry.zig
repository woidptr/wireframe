const limine = @import("limine");
const kernel = @import("kernel");
const arch = @import("arch");
const info = @import("boot_info");

export var start_marker: limine.RequestsStartMarker linksection(".limine_requests_start") = .{};
export var base_revision: limine.BaseRevision linksection(".limine_requests") = .{ .revision = 3 };
export var hhdm_request: limine.HhdmRequest linksection(".limine_requests") = .{};
export var memmap_request: limine.MemmapRequest linksection(".limine_requests") = .{};
export var framebuffer_request: limine.FramebufferRequest linksection(".limine_requests") = .{};
export var end_marker: limine.RequestsEndMarker linksection(".limine_requests_end") = .{};

var regions: [256]info.MemoryRegion = undefined;

export fn _start() callconv(.c) noreturn {
    if (!base_revision.isSupported()) arch.halt();

    const hhdm = hhdm_request.response orelse arch.halt();
    const memmap = memmap_request.response orelse arch.halt();

    var n: usize = 0;
    for (memmap.slice()) |e| {
        if (n == regions.len) break;
        regions[n] = .{ .base = e.base, .len = e.length, .kind = memoryKind(e.type) };
        n += 1;
    }

    const boot_info: info.BootInfo = .{
        .hhdm_offset = hhdm.offset,
        .memory_map = regions[0..n],
        .framebuffer = firstFramebuffer(),
    };

    kernel.main(&boot_info);
}

fn firstFramebuffer() ?info.Framebuffer {
    const resp = framebuffer_request.response orelse return null;
    if (resp.framebuffer_count == 0) return null;
    const fb = resp.slice()[0];
    return .{
        .address = fb.address,
        .width = fb.width,
        .height = fb.height,
        .pitch = fb.pitch,
        .bpp = fb.bpp,
    };
}

fn memoryKind(t: limine.MemmapType) info.MemoryKind {
    return switch (t) {
        .usable => .usable,
        .acpi_reclaimable => .acpi_reclaimable,
        .acpi_nvs => .acpi_nvs,
        .bad_memory => .bad,
        .bootloader_reclaimable => .bootloader_reclaimable,
        .executable_and_modules => .kernel_and_modules,
        .framebuffer => .framebuffer,
        .reserved, .reserved_mapped, _ => .reserved,
    };
}
