b start

.org 0x100
thumb_start:
.word 0x3701272a
.word 0x46c04770

.org 0x200
start:
ldr r10, =0x03000000
mov r1, #1
mov r2, #5
mov r3, #7
.word 0xe0824003
cmp r4, #12
bne fail

mov r1, #2
.word 0xe0050392
cmp r5, #35
bne fail

mov r1, #3
ldr r6, =0x02000000
ldr r7, =0x11223344
str r7, [r6]
ldr r8, [r6, #1]
ldr r9, =0x44112233
.word 0xe1580009
bne fail

mov r1, #4
ldr r13, =0x03007f00
mov r0, #17
mov r2, #34
.word 0xe92d0005
mov r0, #0
mov r2, #0
.word 0xe8bd0005
cmp r0, #17
bne fail
cmp r2, #34
bne fail
ldr r3, =0x03007f00
.word 0xe15d0003
bne fail

mov r1, #5
ldr r14, =arm_return + 0x08000000
ldr r6, =thumb_start + 0x08000001
.word 0xe12fff16

arm_return:
cmp r7, #43
bne fail

mov r1, #6
mov r0, #100
mov r2, #7
.word 0xe1a01002
.word 0xef000006
cmp r0, #14
bne fail
cmp r1, #2
bne fail
cmp r3, #14
bne fail

mov r1, #7
ldr r0, =copy_seed + 0x08000000
ldr r2, =0x04000001
ldr r3, =0x02000020
.word 0xe1a01003
.word 0xef00000b
ldr r4, [r3]
ldr r5, =0xa55aa55a
.word 0xe1540005
bne fail

ldr r1, =0x600d600d
str r1, [r10]
success_loop:
b success_loop

fail:
str r1, [r10]
b fail

.org 0x300
copy_seed:
.word 0xa55aa55a
