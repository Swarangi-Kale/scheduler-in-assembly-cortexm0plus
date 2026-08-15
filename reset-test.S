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
    movs r1, #9
    movs r2, #5
    adds r3, r1, r2
    bmi yohoo @branch if the result of previous operation raised a N (negative) flag
    b finale

    yayy:
    movs r4,r3
    b finale

    yohoo:
    subs r5, r1, r2
    b yayy

    finale:
    bl .

    .end