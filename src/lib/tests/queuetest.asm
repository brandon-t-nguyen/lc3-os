.orig x3000
init
    ld r6, stack
    ; setup queue
    lea r0, myqueue
    lea r1, mybuffer
    ld  r2, queuesize
    ldi r4, _jsrr_queue_init
    jsrr r4

    ;
    and r5, r5, #0
loop
    add r4, r5, #-15
    brz end
    lea r1, tostore
    ld r3, char0
    add r3, r3, r5
    str r3, r1, #0
    lea r0, myqueue
    ldi r4, _jsrr_queue_enque
    jsrr r4
    add r5, r5, #1
    brnzp loop
end
    lea r0, myqueue
    lea r1, tostore
    ldi r4, _jsrr_queue_deque
    jsrr r4
    add r0, r0, #0
    brz term
    ld  r0, tostore
    OUT
    brnzp end
term
    HALT

char0       .fill   x30

tostore     .blkw   1
queuesize   .fill   10
myqueue     .blkw   5
mybuffer    .blkw   10
stack       .fill   x4000
_jsrr_queue_init    .fill   x2200
_jsrr_queue_enque   .fill   x2201
_jsrr_queue_deque   .fill   x2202

.end