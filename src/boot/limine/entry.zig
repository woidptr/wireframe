const limine = @import("limine");

export fn _start() callconv(.naked) noreturn {
    asm volatile ("1: hlt\n jmp 1b");
}
