    .syntax unified
    .cpu cortex-m0plus
    .thumb

    .section .vectors
vector_table:
    .word 0xABC0
    .word reset_handler
    .zero 400

    .section .text
    .align 1
    .type reset_handler, %function
reset_handler:
    movs r1, #0x1
    movs r2, #0x2
    adds r3, r1, r2
    bl .

    .end