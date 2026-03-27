int main(void)
{
    asm volatile ("addi x1,  x0, 5      ");
    asm volatile ("addi x2,  x0, 9      ");
    asm volatile ("add  x3,  x1, x2     ");
    asm volatile ("sub  x4,  x2, x1     ");
    asm volatile ("and  x5,  x1, x2     ");
    asm volatile ("or   x6,  x1, x2     ");
    asm volatile ("xor  x22, x1, x2     ");
    asm volatile ("addi x7,  x0, 1      ");
    asm volatile ("sll  x8,  x1, x7     ");
    asm volatile ("srl  x9,  x2, x7     ");
    asm volatile ("addi x24, x0, -16    ");
    asm volatile ("sra  x25, x24, x7    ");
    asm volatile ("ori  x10, x0, 0x33   ");
    asm volatile ("sw   x3,  0(x0)      ");
    asm volatile ("lw   x11, 0(x0)      ");
    asm volatile ("beq  x11, x3, _skip1 ");
    asm volatile ("addi x12, x0, 1      ");
    asm volatile ("_skip1:              ");
    asm volatile ("bne  x4,  x5, _skip2 ");
    asm volatile ("addi x13, x0, 2      ");
    asm volatile ("_skip2:              ");
    asm volatile ("jal  x14, _jump1     ");
    asm volatile ("addi x15, x0, 3      ");
    asm volatile ("_jump1:              ");
    asm volatile ("addi x16, x0, 100    ");
    asm volatile ("jalr x17, 0(x16)     ");
    asm volatile ("addi x18, x0, 4      ");
    asm volatile ("addi x19, x0, 5      ");
    asm volatile ("addi x20, x0, 6      ");
    asm volatile ("sw   x20, 4(x0)      ");
    asm volatile ("lw   x21, 4(x0)      ");
    asm volatile ("jal  x0,  .          ");
    return 0;
}
