    @systick config registers
    .equ SYST_CSR, 0xE000E010
    .equ SYST_RVR, 0xE000E014
    .equ SYST_CVR, 0xE000E018
    .equ SYST_CALIB, 0xE000E01c
    .equ timeout,        0x00ffffff

    @ ---- RAM layout: task stacks ----
    .equ TASK1_STACK_TOP, 0x20002000
    .equ TASK2_STACK_TOP, 0x20002400
    .equ TASK3_STACK_TOP, 0x20002800

    @ ---- per-task counters (your visible proof of round-robin) ----
    .equ COUNTER1, 0x20003000
    .equ COUNTER2, 0x20003004
    .equ COUNTER3, 0x20003008

    @ ---- scheduler bookkeeping ----
    .equ CURRENT_TASK, 0x20003010   @ holds index 0/1/2
    .equ TASK_SP_0,    0x20003020   @ saved SP for task1
    .equ TASK_SP_1,    0x20003024   @ saved SP for task2, teh location where teh task's sp will be stored once it gets preempted
    .equ TASK_SP_2,    0x20003028   @ saved SP for task3

    @ ---- NVIC/SCB for triggering PendSV ----
    .equ ICSR,           0xE000ED04
    .equ ICSR_PENDSVSET, (1 << 28)
    
    .syntax unified
    .cpu cortex-m0plus
    .thumb

@//////////////////////////////////////

    .section .vectors
vector_table:
    .word 0x20001000
    .word reset_handler
.org 0x38
    .word pendsv_handler
.org 0x3c
    .word systick_handler
    .zero 400

@//////////////////////////////////////


    .section .text
    .align 1
    .type reset_handler, %function
reset_handler:

    @ ---- SysTick registers configured, but NOT enabled yet ----
    ldr r0, =SYST_CSR
    ldr r1, =SYST_RVR
    ldr r2, =SYST_CVR
    ldr r3, =timeout

    str r3, [r1]

    movs r3, #0x0
    str r3, [r2]

    @ ---- build fake exception frame: task2 ----
    @ ---- build fake full frame: task2 ----
    ldr r0, =TASK2_STACK_TOP
    subs r0, r0, #64            @ 8 words R4-R11 (dummy) + 8 words hardware frame
    movs r1, #0
    str r1, [r0, #0]             @ R4 (dummy)
    str r1, [r0, #4]             @ R5
    str r1, [r0, #8]             @ R6
    str r1, [r0, #12]            @ R7
    str r1, [r0, #16]            @ R8
    str r1, [r0, #20]            @ R9
    str r1, [r0, #24]            @ R10
    str r1, [r0, #28]            @ R11

    str r1, [r0, #32]            @ R0 (hardware frame starts at +32)
    str r1, [r0, #36]            @ R1
    str r1, [r0, #40]            @ R2
    str r1, [r0, #44]            @ R3
    str r1, [r0, #48]            @ R12
    ldr r2, =task3
    str r2, [r0, #52]            @ LR
    str r2, [r0, #56]            @ PC = task2 entry
    ldr r2, =0x01000000
    str r2, [r0, #60]            @ xPSR
    ldr r2, =TASK_SP_2
    str r0, [r2]                 @ TASK_SP_2 = start of R4-R11 region

    @ ---- build fake exception frame: task3 ----
    @ ---- build fake full frame: task2 ----
    ldr r0, =TASK3_STACK_TOP
    subs r0, r0, #64            @ 8 words R4-R11 (dummy) + 8 words hardware frame
    movs r1, #0
    str r1, [r0, #0]             @ R4 (dummy)
    str r1, [r0, #4]             @ R5
    str r1, [r0, #8]             @ R6
    str r1, [r0, #12]            @ R7
    str r1, [r0, #16]            @ R8
    str r1, [r0, #20]            @ R9
    str r1, [r0, #24]            @ R10
    str r1, [r0, #28]            @ R11

    str r1, [r0, #32]            @ R0 (hardware frame starts at +32)
    str r1, [r0, #36]            @ R1
    str r1, [r0, #40]            @ R2
    str r1, [r0, #44]            @ R3
    str r1, [r0, #48]            @ R12
    ldr r2, =task2
    str r2, [r0, #52]            @ LR
    str r2, [r0, #56]            @ PC = task2 entry
    ldr r2, =0x01000000
    str r2, [r0, #60]            @ xPSR
    ldr r2, =TASK_SP_1
    str r0, [r2]                 @ TASK_SP_1 = start of R4-R11 region

    @ ---- zero the counters ----
    ldr r0, =COUNTER1
    movs r1, #0
    str r1, [r0]
    ldr r0, =COUNTER2
    str r1, [r0]
    ldr r0, =COUNTER3
    str r1, [r0]

    @ ---- current_task = 0 (task1) ----
    ldr r0, =CURRENT_TASK
    movs r1, #0
    str r1, [r0]

    @ ---- switch to PSP, launch task1 directly ----
    ldr r0, =TASK1_STACK_TOP
    ldr r2, =TASK_SP_0
    str r0, [r2]                @ record task1's SP too (nothing pushed yet, so it's just the top)

    msr psp, r0                 @ PSP = task1's stack
    movs r1, #2
    msr control, r1             @ CONTROL.SPSEL=1: thread mode now uses PSP
    isb                         @ required after changing CONTROL, per ARM

    @ ---- NOW enable SysTick, everything is ready ----
    ldr r0, =SYST_CSR
    movs r3, #0x7
    str r3, [r0]

    @ ---- launch task1 ----
    ldr r0, =task1
    bx r0                       @ jump straight into task1 — no exception return needed here


@//////////////////////////////////////
    .section .text
    .align 1
    .type systick_handler, %function
systick_handler:
    ldr r0, =ICSR
    ldr r1, =ICSR_PENDSVSET
    str r1, [r0]
    bx lr

@//////////////////////////////////////


    .section .text
    .align 1
    .type task1, %function
task1:
    ldr r0, =COUNTER1
    ldr r1, [r0]
    adds r1, r1, #1
    str r1, [r0]
    b task1

    .section .text
    .align 1
    .type task2, %function
task2:
    ldr r0, =COUNTER2
    ldr r1, [r0]
    adds r1, r1, #1
    str r1, [r0]
    b task2

    .section .text
    .align 1
    .type task3, %function
task3:
    ldr r0, =COUNTER3
    ldr r1, [r0]
    adds r1, r1, #1
    str r1, [r0]
    b task3

@//////////////////////////////////////


    .section .text
    .align 1
    .type pendsv_handler, %function
pendsv_handler:
    mrs r0, psp                 @ r0 = current task's PSP (above the auto-stacked 8 words)

    subs r0, r0, #32            @ reserve room for R4-R11
    mov r1, r8
    mov r2, r9
    mov r3, r10
    str r4, [r0, #0]
    str r5, [r0, #4]
    str r6, [r0, #8]
    str r7, [r0, #12]
    str r1, [r0, #16]           @ R8 (via r1)
    str r2, [r0, #20]           @ R9 (via r2)
    str r3, [r0, #24]           @ R10 (via r3)
    mov r1, r11
    str r1, [r0, #28]           @ R11 (via r1)

    @ ---- save updated SP into current task's slot ----
    ldr r1, =CURRENT_TASK
    ldr r2, [r1]                @ r2 = current task index
    lsls r3, r2, #2             @ r3 = index * 4
    ldr r4, =TASK_SP_0
    adds r4, r4, r3
    str r0, [r4]                @ TASK_SP_x[current] = r0

    @ ---- advance to next task, round robin mod 3 ----
    adds r2, r2, #1
    cmp r2, #3
    bne store_index
    movs r2, #0
store_index:
    str r2, [r1]                @ CURRENT_TASK = r2

    @ ---- load next task's saved SP ----
    lsls r3, r2, #2
    ldr r4, =TASK_SP_0
    adds r4, r4, r3
    ldr r0, [r4]

    @ ---- restore R4-R11 from next task's stack ----
    ldr r4, [r0, #0]
    ldr r5, [r0, #4]
    ldr r6, [r0, #8]
    ldr r7, [r0, #12]
    ldr r1, [r0, #16]
    mov r8, r1
    ldr r1, [r0, #20]
    mov r9, r1
    ldr r1, [r0, #24]
    mov r10, r1
    ldr r1, [r0, #28]
    mov r11, r1

    adds r0, r0, #32            @ skip past R4-R11 region, now points at hardware frame
    msr psp, r0                 @ PSP = next task's stack

    ldr r0, =0xFFFFFFFD         @ EXC_RETURN: Thread mode, use PSP
    bx r0                       @ hardware pops xPSR/PC/LR/R12/R3-R0 from PSP and resumes

    .end