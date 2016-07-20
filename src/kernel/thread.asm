.orig x0600

__JUMP_TABLE__
.fill   threadInit
.fill   threadCreate
.fill   threadYield
.fill   threadExit
.fill   threadId

threadInit
    ; function body
    ; for each thread, set it to TERM
    lea r0, _thread_array
    ld  r1, _thread_size
    ld  r3, _thread_TERM ; get a 0 for TERM
_threadInit_term_loop
    str r3, r0, #0  ; store our state
    add r0, r0, r1  ; point to next thread
    add r2, r2, #-1 ; decrement the thread counter
    brp _threadInit_term_loop

    ; setup our current thread stuff
    lea r0, _thread_array
    add r6, r0, r1  ; get to the stack of the 0th thread
    and r2, r2, #0  ; let r2 be state RUNNING
    add r2, r2, #2
    str r2, r0, #0  ; store the state
    st  r0, _p_active_thread

    ; we can now use the stack
    add r6, r6, #-1
    str r7, r6, #0

    ; initialize the queue
    lea r0, _thread_queue
    lea r1, _thread_buffer
    ld  r2, _max_thread
    ldi r3, _jsrr_q_init
    jsrr r3

    ; epilogue
    ldr r7, r6, #0
    add r6, r6, #1

    ret
    _jsrr_q_init  .fill   x2200

; stack of thread:
; TOP>>r0 (arg 0),r1,r2,r3,r4,r5,r7 (func ptr),theadExit>>BOTTOM

; threadCreate:
; inputs: r0=func pointer, r1=argument 0
; output: status: 0 = failure, 1 = success
threadCreate
    add r6, r6, #-6
    str r1, r6, #0
    str r2, r6, #1
    str r3, r6, #2
    str r4, r6, #3
    str r5, r6, #4
    str r7, r6, #5

    ; search array until we find a terminated thread
    ld  r2, _max_thread
    lea r3, _thread_array
    ld  r4, _thread_size
_threadCreate_search
    ldr r5, r3, #0  ; load the state
    brz _threadCreate_found ; if 0 (TERM), success!
    add r3, r3, r4  ; next thread
    add r2, r2, #-1
    brp _threadCreate_search
    ; if it gets here, it has failed
    and r0, r0, #0  ; return 0
    brnzp _threadCreate_return
_threadCreate_found
    ; r3 is our working pointer
    and r2, r2, #0  ; let r2 be 0 for 0 initialized stuff
    add r5, r3, r4  ; point to the end of the stack
    add r5, r5, #-8 ; let r5 be the stack pointer of the new thread
    str r1, r5, #0  ; r0 (argument)
    str r2, r5, #1  ; r1
    str r2, r5, #2  ; r2
    str r2, r5, #3  ; r3
    str r2, r5, #4  ; r4
    str r2, r5, #5  ; r5
    str r0, r5, #6  ; r7 (function pointer)
    lea r0, threadExit  ; put thread exit into the last spot
    str r0, r5, #7  ; threadExit()

    ; update the thread struct
    and r0, r0, #0
    add r0, r0, #1  ; 1 = READY
    str r0, r3, #0  ; state
    str r5, r3, #1  ; sp
    add r0, r3, #0  ; move the thread pointer for enqueue
    jsr threadEnque ; enqueue the thread, return the status of it
_threadCreate_return
    ldr r1, r6, #0
    ldr r2, r6, #1
    ldr r3, r6, #2
    ldr r4, r6, #3
    ldr r5, r6, #4
    ldr r7, r6, #5
    add r6, r6, #6
    ret

; Inputs: none
; Outputs: none
threadYield
    ; prologue
    add r6, r6, #-4
    str r7, r6, #3
    str r2, r6, #2
    str r1, r6, #1
    str r0, r6, #0

    ; dequeue a thread
    jsr threadDeque
    add r0, r0, #0              ; check if pointer is null
    brz _threadYield_return     ; if null, return
    ld  r1, _p_active_thread    ; get the active thread
    
    ld  r2, _thread_READY
    str r2, r1, #0              ; activeThreadPtr->state=READY

    add r2, r0, #0      ; move new threadptr to r2
    add r0, r1, #0      ; move the activeptr to r0
    jsr threadEnque     ; enqueue the activeptr

    ; r2=new threadptr, r1=old threadptr
    ld  r0, _thread_RUNNING
    str r0, r2, #0      ; newthread->state = RUNNING

    add r0, r1, #1      ; get the pointer to the old thread's SP
    ldr r1, r2, #1      ; get the new thread's SP
    jsr threadContextSwitch ; threadContextSwitch(&oldthread->sp,newthread->sp)

_threadYield_return
    ; epilogue
    ldr r7, r6, #3
    ldr r2, r6, #2
    ldr r1, r6, #1
    ldr r0, r6, #0
    add r6, r6, #4
    ret

threadId
    ret

threadExit
    ret

; Inputs: R0 = old esp save spot, R1 = new esp
threadContextSwitch
    ; save the current context
    add r6, r6, #-7
    str r7, r6, #6
    str r5, r6, #5
    str r4, r6, #4
    str r3, r6, #3
    str r2, r6, #2
    str r1, r6, #1
    str r0, r6, #0

    str r6, r0, #0  ; save the old esp
    add r6, r1, #0  ; set the new esp

    ; restore the new context
    ldr r7, r6, #6
    ldr r5, r6, #5
    ldr r4, r6, #4
    ldr r3, r6, #3
    ldr r2, r6, #2
    ldr r1, r6, #1
    ldr r0, r6, #0
    add r6, r6, #7

    ret

; threadEnque
; Inputs: r0=thread pointer 
; Output: r0=queue status
threadEnque
    ; local: +3: hold for enqueue
    ; prologue
    add r6, r6, #-4
    str r7, r6, #3
    str r5, r6, #2
    str r2, r6, #1
    str r1, r6, #0
    add r5, r6, #0  ; set up locals
    add r6, r6, #-1 ; allocate one local

    ; body
    str r0, r5, #-1         ; we need to store for enqueue
    lea r0, _thread_queue   ; prepare input 0
    add r1, r5, #-1         ; get pointer to our holder
    ldi r2, _jsrr_q_enque
    jsrr r2

    ; epilogue
    add r6, r5, #0  ; deallocate with FP
    ldr r7, r6, #3
    ldr r5, r6, #2
    ldr r2, r6, #1
    ldr r1, r6, #0
    add r6, r6, #4

    ret
_jsrr_q_enque .fill   x2201

; threadDeque
; Inputs: none
; Outputs: r0=threadptr, 0 if none
threadDeque
    add r6, r6, #-4
    str r7, r6, #3
    str r5, r6, #2
    str r2, r6, #1
    str r1, r6, #0
    add r5, r6, #0  ; setup FP
    add r6, r6, #-1 ; allocate for dequeue space

    ; body
    lea r0, _thread_queue   ; get our queue
    add r1, r5, #-1         ; setup our ptr
    ldi r2, _jsrr_q_deque
    jsrr r2
    add r0, r0, #0
    brz _threadDeque_return ; if it returned 0, return a 0
    ldr r0, r1, #0          ; load the threadptr from it's storage

_threadDeque_return
    add r6, r5, #0  ; deallocate using FP
    ldr r7, r6, #3
    ldr r5, r6, #2
    ldr r2, r6, #1
    ldr r1, r6, #0
    add r6, r6, #4
    ret
_jsrr_q_deque .fill   x2202

_thread_TERM    .fill 0
_thread_READY   .fill 1
_thread_RUNNING .fill 2
_thread_BLOCKED .fill 3
_p_active_thread    .blkw 1

_thread_size    .fill x0250
_max_thread     .fill 4
; storage elements for our queue
_thread_queue   .blkw 5
_thread_buffer  .blkw 4

; our thread array
_thread_array   .blkw x0250
                .blkw x0250
                .blkw x0250
                .blkw x0250


; Thread: size: x250
; state: 0=TERM, 1=READY, 2=RUNNING, 3=BLOCKED
; sp/r6
; x24E stack
THREAD_END .fill xffff
.end