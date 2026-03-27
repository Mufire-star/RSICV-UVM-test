int main(void)
{
    asm volatile ("addi x1,  x0, 1       ");
    asm volatile ("addi x2,  x0, 2       ");
    asm volatile ("add  x3,  x1, x2      ");
    asm volatile ("add  x4,  x3, x2      ");
    asm volatile ("sub  x5,  x4, x1      ");
    asm volatile ("or   x6,  x5, x3      ");
    asm volatile ("and  x7,  x6, x4      ");
    asm volatile ("sll  x8,  x7, x1      ");
    asm volatile ("srl  x9,  x8, x2      ");
    asm volatile ("sw   x9,  0(x0)       ");
    asm volatile ("lw   x10, 0(x0)       ");
    asm volatile ("beq  x10, x9, _skip1  ");
    asm volatile ("addi x11, x0, 11      ");
    asm volatile ("_skip1:               ");
    asm volatile ("addi x12, x0, 40      ");
    asm volatile ("jal  x13, _skip2      ");
    asm volatile ("addi x14, x0, 14      ");
    asm volatile ("_skip2:               ");
    asm volatile ("addi x15, x0, 80      ");
    asm volatile ("jalr x16, 0(x15)      ");
    asm volatile ("addi x17, x0, 17      ");
    asm volatile ("addi x18, x0, 18      ");
    asm volatile ("addi x19, x0, -1      ");
    asm volatile ("addi x0,  x0, 7       ");
    asm volatile ("sw   x19, 4(x0)       ");
    asm volatile ("lw   x20, 4(x0)       ");
    asm volatile ("bne  x20, x0, _skip3  ");
    asm volatile ("addi x21, x0, 21      ");
    asm volatile ("_skip3:               ");
    asm volatile ("jal  x0,  .           ");
    return 0;
}
