pub const MemoryKind = enum {
    usable,
    reserved,
    acpi_reclaimable,
    acpi_nvs,
    bad,
    bootloader_reclaimable,
    kernel_and_modules,
    framebuffer,
};

pub const MemoryRegion = struct {
    base: u64,
    len: u64,
    kind: MemoryKind,
};

pub const Framebuffer = struct {
    address: [*]u8,
    width: u64,
    height: u64,
    pitch: u64,
    bpp: u16,
};

pub const BootInfo = struct {
    hhdm_offset: u64,
    memory_map: []const MemoryRegion,
    framebuffer: ?Framebuffer,
};
