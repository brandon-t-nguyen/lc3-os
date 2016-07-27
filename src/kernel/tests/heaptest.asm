.orig x0200

heaptest
    ld  r6, stackstart  ; setup the stack
    ld  r5, heaptable
    ldr r4, r5, #0      ; heapInit
    jsrr r4

    ldr r4, r5, #1      ; malloc
    and r0, r0, #0
    add r0, r0, #10
    jsrr r4

    add r1, r0, #0

    and r0, r0, #0
    add r0, r0, #4
    jsrr r4


    brnzp -1


stackstart  .fill x1000
heaptable   .fill x2500

.end