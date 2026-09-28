b start

.org 0x100
irq_handler:
ldr r1, =0x04000202
mov r2, #1
strh r2, [r1]
.word 0xe12fff1e

.org 0x120
map_seed:
.word 0x00010001
oam_seed:
.word 0x02000200

.org 0x200
start:
ldr r0, =0x04000000
mov r1, #0x80
strh r1, [r0]

ldr r0, =0x05000000
ldr r1, =0x001f0000
str r1, [r0]
ldr r1, =0x7fff03e0
str r1, [r0, #4]
ldr r0, =0x05000200
ldr r1, =0x7c000000
str r1, [r0]

ldr r0, =0x06000020
ldr r1, =0x11111111
mov r2, #8
bg_tile_one:
str r1, [r0]
add r0, r0, #4
sub r2, r2, #1
cmp r2, #0
bne bg_tile_one

ldr r0, =0x06000040
ldr r1, =0x22222222
mov r2, #8
bg_tile_two:
str r1, [r0]
add r0, r0, #4
sub r2, r2, #1
cmp r2, #0
bne bg_tile_two

ldr r0, =0x06010000
ldr r1, =0x11111111
mov r2, #8
obj_tile:
str r1, [r0]
add r0, r0, #4
sub r2, r2, #1
cmp r2, #0
bne obj_tile

ldr r0, =map_seed + 0x08000000
ldr r1, =0x06008000
ldr r2, =0x01000200
.word 0xef00000c

ldr r0, =oam_seed + 0x08000000
ldr r1, =0x07000000
ldr r2, =0x01000100
.word 0xef00000c

ldr r0, =0x07000000
ldr r1, =0x00280028
str r1, [r0]
mov r1, #0
str r1, [r0, #4]

ldr r0, =0x03000000
mov r1, #0
str r1, [r0]
mov r9, #1
str r9, [r0, #4]

ldr r0, =0x040000d4
ldr r1, =0x03000004
str r1, [r0]
ldr r1, =0x06008000
str r1, [r0, #4]

ldr r0, =0x03007ffc
ldr r1, =irq_handler + 0x08000000
str r1, [r0]
ldr r0, =0x04000004
mov r1, #8
strh r1, [r0]
ldr r0, =0x04000200
mov r1, #1
strh r1, [r0]

ldr r0, =0x04000080
ldr r1, =0x00001177
strh r1, [r0]
mov r1, #2
strh r1, [r0, #2]
mov r1, #0x80
strh r1, [r0, #4]
ldr r0, =0x04000062
ldr r1, =0x0000f080
strh r1, [r0]
ldr r1, =0x00008400
strh r1, [r0, #2]

ldr r0, =0x04000008
ldr r1, =0x00001000
strh r1, [r0]
ldr r0, =0x04000000
ldr r1, =0x00001140
strh r1, [r0]

mov r6, #40
mov r8, #0

frame_loop:
.word 0xef000005
add r8, r8, #1
ldr r0, =0x03000000
str r8, [r0]
ldr r4, =0x04000130
.word 0xe1d450b0
.word 0xe3150010
.word 0x02866001
.word 0xe3150020
.word 0x02466001
ldr r7, =0x07000002
strh r6, [r7]
.word 0xe2299003
ldr r10, =0x03000004
str r9, [r10]
ldr r11, =0x040000dc
ldr r12, =0x80000001
str r12, [r11]
b frame_loop
