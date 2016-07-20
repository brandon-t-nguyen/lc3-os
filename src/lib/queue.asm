.orig x2200
; Queue API
; The queue utilizes an array of pointers/size 1 items to hold items
; The Queue will hold n-1 items for a buffer of size n

; Queue: size 5
; Buffer Pointer
; max # of elements
; Enque Index
; Deque Index
; Status: 0:Okay, +:Full, -:Empty

JUMP_TABLE
.fill   q_init
.fill   q_enqueue
.fill   q_dequeue

; queue init:
; Inputs:   r0=pointer to space for queue,
;           r1=buffer pointer,
;           r2=number of elements buffer can hold,
q_init
    ; prologue
    add r6, r6, #-1
    str r3, r3, #0
    
    and r3, r3, #0  ; get a zero for initial indices

    str r1, r0, #0  ; store the buffer pointer
    str r2, r0, #1  ; store the number of elements
    str r3, r0, #2  ; store the enqi of 0
    str r3, r0, #3  ; store the deqi of 0

    add r3, r3, #-1 ; get a neg for empty flag
    str r3, r0, #4  ; store neg for empty flag

    ; epilogue
    ldr r3, r3, #0
    add r6, r6, #1
    ret

; queue enque:
; Inputs:   r0=pointer to queue,
;           r1=pointer to element holder to put into
; Output:   r0=1: success, 0: failure(full)
q_enqueue
    ; prologue
    add r6, r6, #-5
    str r7, r6, #4
    str r3, r6, #3
    str r2, r6, #2
    str r1, r6, #1
    str r0, r6, #0

    ; body
    ldr r2, r0, #4  ; get the status flag
    brp _q_enqueue_full ; return immediately if full
    ldr r2, r0, #2  ; get the enqueue index
    ldr r3, r0, #0  ; get the buffer pointer
    add r2, r2, r3  ; get the pointer to where to store
    ldr r3, r1, #0  ; get the value to enqueue
    str r3, r2, #0  ; store the value
    ; update the pointer and status
    add r2, r0, #0  ; move the queue pointer to save
    ldr r0, r2, #2  ; get the enqueue index
    add r0, r0, #1  ; increment it
    ldr r1, r2, #1  ; get the max # of elements
    ldi r3, _jsrr_ind_div   ; get div pointer
    jsrr r3
    and r3, r3, #0  ; working reg for new flag
    str r1, r2, #2  ; save the enqI
    ldr r0, r2, #3  ; get the deqI
    not r0, r0
    add r0, r0, #1
    add r0, r0, r1  ; compare to see if the I at same spot
    brnp _q_enqueue_store_flag  ; branch away if not same: means it's okay
    add r3, r3, #1  ; make it 1 to say it's full
_q_enqueue_store_flag
    str r3, r2, #4  ; store status
    and r0, r0, #0  ;
    add r0, r0, #1  ;
    brnzp _q_enqueue_return;
_q_enqueue_full
    and r0, r0, #0
_q_enqueue_return
    ; epilogue
    ldr r7, r6, #4
    ldr r3, r6, #3
    ldr r2, r6, #2
    ldr r1, r6, #1
    ;ldr r0, r6, #0 return value
    add r6, r6, #5
    ret

; queue deque:
; Inputs:   r0=pointer to queue,
;           r1=pointer to element holder to store into
; Output:   r0=1: success, 0: failure, -1: empty
q_dequeue
    ; prologue
    add r6, r6, #-5
    str r7, r6, #4
    str r3, r6, #3
    str r2, r6, #2
    str r1, r6, #1
    str r0, r6, #0

    ; body
    ldr r2, r0, #4  ; get the status flag
    brn _q_enqueue_full ; return immediately if empty
    ldr r2, r0, #3  ; get the dequeue index
    ldr r3, r0, #0  ; get the buffer pointer
    add r2, r2, r3  ; get the pointer to where to load
    ldr r3, r2, #0  ; load the value
    str r3, r1, #0  ; put it into the return pointer
    ; update the pointer and status
    add r2, r0, #0  ; move the queue pointer to save
    ldr r0, r2, #3  ; get the dequeue index
    add r0, r0, #1  ; increment it
    ldr r1, r2, #1  ; get the max # of elements
    ldi r3, _jsrr_ind_div   ; get div pointer
    jsrr r3
    and r3, r3, #0  ; working reg for new flag
    str r1, r2, #3  ; save the deqI
    ldr r0, r2, #2  ; get the enqI
    not r0, r0
    add r0, r0, #1
    add r0, r0, r1  ; compare to see if the I at same spot
    brnp _q_dequeue_store_flag  ; branch away if not same: means it's okay
    add r3, r3, #-1 ; make it -1 to say it's empty
_q_dequeue_store_flag
    str r3, r2, #4  ; store status
    and r0, r0, #0  ;
    add r0, r0, #1  ;
    brnzp _q_dequeue_return;
_q_dequeue_empty
    and r0, r0, #0
_q_dequeue_return
    ; epilogue
    ldr r7, r6, #4
    ldr r3, r6, #3
    ldr r2, r6, #2
    ldr r1, r6, #1
    ;ldr r0, r6, #0 return value
    add r6, r6, #5
    ret

_jsrr_ind_div   .fill   x2008

.end