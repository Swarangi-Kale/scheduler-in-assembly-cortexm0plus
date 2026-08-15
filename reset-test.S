    .syntax unified
    .cpu cortex-m0plus
    .thumb

    .section .vectors
vector_table:
    .word 0x20001000
    .word reset_handler
    .zero 400

    .section .text
    .align 1
    .type reset_handler, %function

reset_handler:
    movs r1, #1
    movs r2, #4
    movs r3, #0
    movs r4, #0

    push {r1,r2}

    pop {r4,r3}

    bl .

    .end